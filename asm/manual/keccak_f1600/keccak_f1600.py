## MIT License
##
## Copyright (c) 2021 Arm Limited
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
##

##
## Author: Hanno Becker <hanno.becker@arm.com>
##

#------------------------------------------------#
#                 Miscellaneous                  #
#------------------------------------------------#

def rev_dict(d):
    return { v:k for k,v in d.items() }

#------------------------------------------------#
#    Data from the Keccak-f1600 specification    #
#------------------------------------------------#

# Keccak-f1600 state indices
idxs = [(x,y) for x in range(0,5) for y in range(0,5)]

# Permutation
perm = {}
for x,y in idxs:
    xp,yp = y, (2*x+3*y) % 5
    perm[xp,yp] = (x,y)
perm_inv = rev_dict(perm)

# Rotation offsets
rot = [
    [  0,      1,    62,    28,    27 ],
    [  36,    44,     6,    55,    20 ],
    [  3,     10,    43,    25,    39 ],
    [  41,    45,    15,    21,     8 ],
    [  18,     2,    61,    56,    14 ] ]

#------------------------------------------------#
#        Helper for register allocations         #
#------------------------------------------------#

v84a = False
delay_rotation = True

if v84a:
    num_registers = 32
else:
    num_registers = 31

# Helper to manage the available registers
class RegList():
    def __init__(self, regs):
        self._orig_regs = regs
        regs.reverse()
        self._regs = regs
        self._free = []
        for r in regs:
            self._free.append(r)
        self._alloc = []
    def alloc(self,reg=None):
        if reg == None:
            assert len(self._free) > 0
            reg = self._free.pop()
        else:
            assert reg in self._free
            self._free.remove(reg)
        self._alloc.append(reg)
        return reg
    def free(self,reg):
        assert reg in self._regs
        assert reg in self._alloc
        self._alloc.remove(reg)
        self._free.append(reg)
    def reset(self):
        self.__init__(self._orig_regs)

regs = RegList(list(range(0,num_registers)))

#------------------------------------------------#
#                 Actual work                    #
#------------------------------------------------#

# How to label the Keccak-f1600 state in the code
def label(x,y):
    y_label = "bgkms"
    x_label = "aeiou"
    return f"{y_label[y]}{x_label[x]}"

def lbl_A(x,y,q=False):
    if q == False or not v84a:
        return f"A{label(x,y)}"
    else:
        return f"A{label(x,y)}q"
def lbl_B(x,y):
    return f"A{label(x,y)}_"
def lbl_C(x):
    return f"C{x}"
def lbl_D(x):
    return f"E{x}"

def eor5(d,s0,s1,s2,s3,s4,
         s0_rot=0,s1_rot=0,s2_rot=0,s3_rot=0,s4_rot=0):
    s = [s0,s1,s2,s3,s4]
    srot = [s0_rot,s1_rot,s2_rot,s3_rot,s4_rot]
    if v84a:
        assert s0_rot == 0
        assert s1_rot == 0
        assert s2_rot == 0
        assert s3_rot == 0
        assert s4_rot == 0
        yield f"eor3 {d}.16b, {s0}.16b, {s1}.16b, {s2}.16b"
        yield f"eor3 {d}.16b, {d}.16b, {s3}.16b,  {s4}.16b"
    else:
        rots = [ (i,srot[i]) for i in range(0,5) ]
        rots.sort(key=lambda x:x[1])
        print(f"// EOR5: {s}, {rots}")
        # cur = s[rots[4][0]]
        # for i in [4,3,2,1]:
        #     print(f"// Current delayed rotations: {rots[i][1]}, {rots[i-1][1]}")
        #     r = (64 - (rots[i][1] - rots[i-1][1]))%64
        #     if r != 0:
        #         yield f"eor {d}, {s[rots[i-1][0]]}, {cur}, ROR #{r}"
        #     else:
        #         yield f"eor {d}, {s[rots[i-1][0]]}, {cur}"
        #     cur = d
        cur = s[rots[0][0]]
        for i in [1,2,3,4]:
            r = (64 - (rots[i][1] - rots[0][1]))%64
            yield f"eor {d}, {cur}, {s[rots[i][0]]}, ROR #{r}"
            cur = d
        if rots[0][1] != 0:
            yield f"ror {cur}, {cur}, {(64-rots[0][1])%64}"
        # yield f"eor {d}, {s0}, {s1}"
        # yield f"eor {d}, {d},  {s2}"
        # yield f"eor {d}, {d},  {s3}"
        # yield f"eor {d}, {d},  {s4}"

def eor_and_rol(d,s0,s1,imm,rot=0):
    if imm == 0:
        if v84a:
            yield f"eor {d}.16b, {s0}.16b, {s1}.16b"
        else:
            yield f"eor {d}, {s0}, {s1}"
    else:
        if v84a:
            yield f"xar {d}.2d, {s0}.2d, {s1}.2d, #{(64-imm)%64}"
        else:
            if not delay_rotation:
                yield f"eor {d}, {s0}, {s1}"
                yield f"ror {d}, {d}, #{64-imm}"
            else:
                if rot == 0:
                    yield f"eor {d}, {s0}, {s1}"
                else:
                    yield f"eor {d}, {s0}, {s1}, ROR #{(64-rot)%64}"

def bitwise_clear_and_xor(d,s0,s1,s2,tmp=None,bic_rot=0,eor_rot=0, eor_rot2=0):
    bic_rot  = (64-bic_rot)  % 64
    eor_rot  = (64-eor_rot)  % 64
    eor_rot2 = (64-eor_rot2) % 64
    if v84a:
        yield f"bcax {d}.16b, {s0}.16b, {s1}.16b, {s2}.16b"
    else:
        assert tmp != None
        if bic_rot == 0:
            yield f"bic {tmp}, {s1}, {s2}"
        else:
            yield f"bic {tmp}, {s1}, {s2}, ROR #{bic_rot}"
        if eor_rot != 0:
            yield f"eor {d}, {tmp},  {s0}, ROR #{eor_rot}"
        elif eor_rot2 != 0:
            yield f"eor {d}, {s0}, {tmp}, ROR #{eor_rot2}"
        else:
            yield f"eor {d}, {tmp},  {s0}"


def rax1(d,s0,s1):
    if v84a:
        yield f"rax1 {d}.2d, {s0}.2d, {s1}.2d"
    else:
        yield f"eor {d}, {s0}, {s1}, ROR #63"

def alloc_state():
    global s_stable
    global s_stable_rev

    if not v84a:
        regs.alloc(0) # Don't use x0

    # Allocate locations for Keccak-f1600 state
    # at the beginning and end of each round
    s_stable = {}
    for x,y in idxs:
        # Not necessary, but fix allocation for ease of reading
        # loc = 5*y+x
        s_stable[x,y] = regs.alloc()
    s_stable_rev = rev_dict(s_stable)

    if not v84a:
        regs.free(0) # Don't use x0

def load_input():
    if v84a:
        simd_width = 2
    else:
        simd_width = 1

    for y,x in idxs:
        idx = 5*y+x
        yield f"ldr {lbl_A(x,y,q=True)}, [input_addr, #({simd_width}*8*{idx})]"

def store_input():
    if v84a:
        simd_width = 2
    else:
        simd_width = 1

    for y,x in idxs:
        idx = 5*y+x
        yield f"str {lbl_A(x,y,q=True)}, [input_addr, #({simd_width}*8*{idx})]"



delayed_rotations = {}
delayed_rotations_alt = {}
for x,y in idxs:
    delayed_rotations[x,y]     = 0
    delayed_rotations_alt[x,y] = 0

def generate_round():
    global c
    global d
    global s_tmp
    global delayed_rotations
    global delayed_rotations_alt

    # SPECIFICATION:
    # C[x] = A[x,0] xor A[x,1] xor A[x,2] xor A[x,3] xor A[x,4],   for x in 0..4

    c = {}
    for x in range(0,5):
        c[x] = regs.alloc()
    yield ""

    for x in range(0,5):
        yield from eor5(f"{lbl_C(x)}",
                        f"{lbl_A(x,0)}",
                        f"{lbl_A(x,1)}",
                        f"{lbl_A(x,2)}",
                        f"{lbl_A(x,3)}",
                        f"{lbl_A(x,4)}",
                        s0_rot = delayed_rotations[x,0],
                        s1_rot = delayed_rotations[x,1],
                        s2_rot = delayed_rotations[x,2],
                        s3_rot = delayed_rotations[x,3],
                        s4_rot = delayed_rotations[x,4])

    yield ""

    # SPECIFICATION:
    # D[x] = C[x-1] xor rot(C[x+1],1), for x in 0..4

    # Overlap D[] and C[] except for one register, to keep
    # the total # of registers for C[], D[] down to 6
    # (we already allocate 25 for the state)
    d = {}
    for x in range(0,5):
        if x == 1:
            d[x] = regs.alloc()
        else:
            d[x] = c[(x-1)%5]
    yield ""

    x_order = [1,3,0,2,4]
    for x in x_order:
        xm = (x-1)%5
        xp = (x+1)%5
        yield from rax1(lbl_D(x),lbl_C(xm),lbl_C(xp))

    regs.free(c[0])
    # SPECIFICATION:
    # A[x,y] = A[x,y] xor D[x],             for (x,y) in (0..4,0..4)
    # B[y,2*x+3*y] = rot(A[x,y], r[x,y]),   for (x,y) in (0..4,0..4)

    # Compute rho and pi steps into temporary state, making sure to overwrite
    # stable state only after it has been used. Consequently, we start with
    # one of the two temporary states which uses a fresh register

    yield ""

    # Order of rows for xi-step
    row_order     = {0:1,1:2,2:3,3:4,4:0}
    # Where to start each row in the xi-step
    order_bases   = [(0,1) for _ in range(0,5)]
    row_order_rev = rev_dict(row_order)
    last_row = row_order[4]

    # Assign registers for temporary Keccak-f1600 state
    s_tmp = {}
    for x,y in idxs:
        if x in order_bases[y]:
            if x == order_bases[y][0]:
                idx=0
            else:
                idx=1
            row_idx = row_order_rev[y]
            if row_idx == 4:
                s_tmp[x,y] = None # Allocation later
            else:
                next_y = row_order[row_idx+1]
                s_tmp[x,y] = s_stable[order_bases[next_y][idx],next_y]
        else:
            s_tmp[x,y] = s_stable[x,y]

    loc = regs.alloc()
    x = order_bases[last_row][0]
    s_tmp[x, last_row] = loc
    s_tmp_rev = rev_dict(s_tmp)
    total = 0

    while loc in s_tmp_rev.keys():
        xp,yp = s_tmp_rev[loc]
        x,y = perm[xp,yp]
        yield from eor_and_rol(f"{lbl_B(xp,yp)}",
                               f"{lbl_D(x)}",
                               f"{lbl_A(x,y)}",rot[y][x],
                               rot=delayed_rotations[x,y])
        loc = s_stable[x,y]
        total += 1
    # The row order and order base is experimentally chosen in such a way
    # that we have only two chains, one of length 24 and one of length 1.
    # This means that after processing the length 24 chain, 4 out of 5 d[i]
    # temporaries are not needed anymore, so we can use one of them for the
    # second temporary state.
    # This is only strictly necessary for the scalar case, where we have 31 registers.
    assert total == 24

    yield ""

    xp = order_bases[last_row][1]
    yp = last_row
    # Confirm again that this is a length 1 chain
    x,y=perm[xp,yp]
    # We can now free all but one D[x]
    assert s_stable[x,y] not in s_tmp_rev.keys()
    for i in [ i for i in range(0,5) if i != x ]:
        regs.free(d[i])
    loc = regs.alloc()
    s_tmp[xp,yp] = loc
    s_tmp_rev = rev_dict(s_tmp)
    yield from eor_and_rol(f"{lbl_B(xp,yp)}",
                           f"{lbl_D(x)}",
                           f"{lbl_A(x,y)}",
                           rot[y][x],
                           rot=delayed_rotations[x,y])
    regs.free(d[x])

    yield ""
    yield "// xi step"

    # xi-step
    #
    # SPECIFICATION:
    # A[x,y] = B[x,y] xor ((not B[x+1,y]) and B[x+2,y]),  for (x,y) in (0..4,0..4)
    #
    # We compute this in a specific order of rows, and order within row

    if not v84a:
        global tmp
        tmp = regs.alloc()

    for row in range(0,5):
        y = row_order[row]
        yield f"// Row {y}"
        base_x = order_bases[y][0]
        for offset in range(0,5):
            x  = (base_x + offset) % 5
            xp  = (x+1)%5
            xpp = (x+2)%5

            if delay_rotation:
                xr  ,yr   = perm[x  ,y]
                xpr ,ypr  = perm[xp ,y]
                xppr,yppr = perm[xpp,y]
                r   = rot[yr]  [xr]
                rp  = rot[ypr] [xpr]
                rpp = rot[yppr][xppr]

                # We're looking at an expression of the form
                # (A <<< x) XOR (not(B <<< y) AND (C <<< z))
                # and want to write it as a composition of
                # XOR-with-ROT, BIC-with-ROT and ROT.
                # There are two possibilities:
                # 1) (A XOR (not (B <<< (y-z)) AND C) <<< (z-x)) <<< x
                # or
                # 2) ((not (B <<< (y-z) AND C)) XOR (A <<< (x-z))) <<< z
                #
                # If z is zero, we go for 2). Otherwiswe, we go for 1)

                if r != 0:
                    yield from bitwise_clear_and_xor(f"{lbl_A(x,y)}",
                                             f"{lbl_B(x,y)}",
                                             f"{lbl_B(xpp,y)}",
                                             f"{lbl_B(xp,y)}",
                                             tmp="tmp",
                                             bic_rot=rp-rpp,
                                             eor_rot=r-rpp)
                    delayed_rotations[x,y] = rpp
                    delayed_rotations_alt[x,y] = r
                else:
                    yield from bitwise_clear_and_xor(f"{lbl_A(x,y)}",
                                             f"{lbl_B(x,y)}",
                                             f"{lbl_B(xpp,y)}",
                                             f"{lbl_B(xp,y)}",
                                             tmp="tmp",
                                             bic_rot=rp-rpp,
                                             eor_rot2=rpp)
                    delayed_rotations[x,y] = r
                    delayed_rotations_alt[x,y] = rpp

            else:
                yield from bitwise_clear_and_xor(f"{lbl_A(x,y)}",
                                             f"{lbl_B(x,y)}",
                                             f"{lbl_B(xpp,y)}",
                                             f"{lbl_B(xp,y)}",
                                             tmp="tmp")

    yield ""

    for x,y in idxs:
        yield f"// Shift for {lbl_A(x,y)}: {delayed_rotations[x,y]} (alt {delayed_rotations_alt[x,y]})"


    if not v84a:
        regs.free(tmp)

    # iota step
    yield "// iota step"
    yield "# FILL IN"
    yield f"eor {lbl_A(0,0)}, {lbl_A(0,0)}, CONSTANT"

def print_allocations():

    for y,x in idxs:
        if v84a:
            yield f"{lbl_A(x,y)}     .req v{s_stable[x,y]}"
        else:
            yield f"{lbl_A(x,y)}     .req x{s_stable[x,y]}"
    for y,x in idxs:
        if v84a:
            yield f"{lbl_A(x,y,q=True)}    .req q{s_stable[x,y]}"

    yield ""

    # Print  allocations
    for y,x in idxs:
        if v84a:
            yield f"{lbl_B(x,y)} .req v{s_tmp[x,y]}"
        else:
            yield f"{lbl_B(x,y)} .req x{s_tmp[x,y]}"
    yield ""

    for x in range(0,5):
        if v84a:
            yield f"{lbl_C(x)} .req v{c[x]}"
            yield f"{lbl_D(x)} .req v{d[x]}"
        else:
            yield f"{lbl_C(x)} .req x{c[x]}"
            yield f"{lbl_D(x)} .req x{d[x]}"

    if not v84a:
        yield ""
        yield f"tmp .req {tmp}"

def codegen():
    alloc_state()
    yield from generate_round()
    yield "//////////////////////////////////////////////////////////"
    regs.reset()
    yield from generate_round()
    yield "//////////////////////////////////////////////////////////"
    yield from store_input()
    yield "//////////////////////////////////////////////////////////"
    yield from load_input()
    yield "//////////////////////////////////////////////////////////"
    yield from print_allocations()

for line in codegen():
    print(line)
