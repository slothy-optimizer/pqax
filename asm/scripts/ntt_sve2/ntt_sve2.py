# Copyright (c) 2021 Arm Limited
# SPDX-License-Identifier: MIT

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import sys, argparse, math, traceback

class Snippets():

    def autogen_warning():
        warning = """
///
/// This assembly code has been auto-generated.
/// Don't modify it directly.
///
"""
        yield warning

    def license():
        yield """
///
/// Copyright (c) 2021 Arm Limited
/// SPDX-License-Identifier: MIT
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE
"""

    def function_decl(func_name):
        yield f'.text'
        yield f'.type {func_name}, %function'
        yield f'.global {func_name}'

    def function_header(func_name):
        yield f"{func_name}:"

    def function_footer():
        yield 'ret'

    def save_gprs():
        yield '// Save GPRs'
        yield "sub sp, sp, #(16*5+16)"
        yield "stp x19, x20, [sp, #16*0]"
        yield "stp x19, x20, [sp, #16*0]"
        yield "stp x21, x22, [sp, #16*1]"
        yield "stp x23, x24, [sp, #16*2]"
        yield "stp x25, x26, [sp, #16*3]"
        yield "stp x27, x28, [sp, #16*4]"
        yield "str x29, [sp, #16*5]"

    def restore_gprs():

        # # TODO: Update
        yield '// Restore GPRs'
        yield "ldp x19, x20, [sp, #16*0]"
        yield "ldp x21, x22, [sp, #16*1]"
        yield "ldp x23, x24, [sp, #16*2]"
        yield "ldp x25, x26, [sp, #16*3]"
        yield "ldp x27, x28, [sp, #16*4]"
        yield "ldr x29, [sp, #16*5]"
        yield "add sp, sp, #(16*5+16)"

    def save_vregs():
        # TODO: Update
        yield '// Save SVE2 vector registers'
        yield "sub sp, sp, #(16*4)"
        yield "stp  d8,  d9, [sp, #16*0]"
        yield "stp d10, d11, [sp, #16*1]"
        yield "stp d12, d13, [sp, #16*2]"
        yield "stp d14, d15, [sp, #16*3]"

    def restore_vregs():
        # TODO: Update
        yield '// Restore SVE2 vector registers'
        yield "ldp  d8,  d9, [sp, #16*0]"
        yield "ldp d10, d11, [sp, #16*1]"
        yield "ldp d12, d13, [sp, #16*2]"
        yield "ldp d14, d15, [sp, #16*3]"
        yield "add sp, sp, #(16*4)"

class RegList():

    def __init__(self, regs):

        self._regs = regs

        self._free = []
        for r in regs:
            self._free.append(r)

        self._alloc = []

    def alloc(self,reg=None,constraint=None,lax=False):

        if constraint == None:
            constraint = lambda _: True

        if reg == None:
            reg_idx = None
            for i,r in enumerate(self._free):
                if not constraint(r):
                    continue
                reg_idx = i
            if reg_idx == None:
                if not lax or len(self._free) == 0:
                    raise Exception("No more free registers")
                print("WARNING: Have to disregard preference")
                reg_idx = len(self._free)-1
            reg = self._free.pop(reg_idx)
        else:
            if not reg in self._free:
                raise Exception(f"Register {reg} already allocated")
            if not constraint(reg):
                raise Exception(f"Register {reg} doesn't satisfy constraint")
            self._free.remove(reg)

        self._alloc.append(reg)

#        print(f"Allocated: {len(self._alloc)}")
#        print(f"Free:      {len(self._free)}")

        return reg

    def revfree(self):
        self._free.reverse()

    def free(self,reg):
        if reg not in self._regs:
            raise Exception("Invalid register")
        if not reg in self._alloc:
            raise Exception("Register not allocated")
        self._alloc.remove(reg)
        self._free.append(reg)

class Butterfly():

    def __init__(self,base,stride,block,layer,merged,load_roots=False,shuffle=False):

        self.layer = layer
        self.merged = merged
        self.block = block

        self.num_gs = merged * pow(2,merged-1)
        if shuffle:
            self.num_gs *= 2

        self.base = base
        self.stride = stride
        self.load_roots = load_roots

        self.load_idx    = 0
        self.store_idx   = 0
        self.scalar_load = None
        self.transpose   = None
        self.free_root_scalars = None

    def __getitem__(self,idx):
        return self.base + idx * self.stride

    def __repr__(self):
        return f"[{self.layer}:{self.block}]: {[self[i] for i in range(0,4)]}]"

class NTT():

    def __init__(self,size,modulus,root,schedules=[0,0], layers=[3,3], bitwidth=32):

        self.size = size
        self.bitwidth = bitwidth
        self.R = 2**bitwidth
        self.vector_bitlen = 128
        self.vector_bytelen = self.vector_bitlen // 8
        self.elements_per_vector = self.vector_bitlen // self.bitwidth

        self.interleave_twiddles = True

        # Determine layer at which NTT requires intra-vector shuffling
        self.shuffle_boundary = int(math.log(self.size,2) - math.log(self.elements_per_vector, 2))

        if self.bitwidth == 64:
            self.data_prefix = "dword"
            self.vector_suffix = "d"
            self.element_size = 8
        elif self.bitwidth == 32:
            self.data_prefix = "word"
            self.vector_suffix = "s"
            self.element_size = 4
        elif self.bitwidth == 16:
            self.data_prefix = "half"
            self.vector_suffix = "h"
            self.element_size = 2

        self.root    = root
        self.modulus = modulus

        self.data = {}
        self._src = 0

        # Alignment for arrays of twiddle factors
        self.root_align  = 64
        self.root_offset = 0 # 32

        # Layer configuration
        last_layer = 0
        self.layers = []
        for l in layers:
            self.layers.append((last_layer,l))
            last_layer += l

        # Schedule configuration
        self.schedules = []
        for s in schedules:
            if s[:3] == "z2_":
                self.schedules.append((2,int(s[3:])))
            elif s[:3] == "z4_":
                self.schedules.append((4,int(s[3:])))
            else:
                self.schedules.append((1,int(s)))

        if len(self.schedules) != len(self.layers):
            raise Exception("Bad configuration")

        # We only support
        # - not crossing the shuffle boundary
        # - crossing it by exactly 2 layers
        self.check_layer_config()

        # Whether to use growing immediate offsets or
        # post-increment loads for the twiddles.
        self.increment_root_ptr = False # Immediate offsets
        # self.increment_root_ptr = True # Post-increment
        # self.multi_access_strategy = 0 # Only relevant if increment_root_ptr == True

        vregs = list(range(4,8)) + list(range(8,16)) + list(range(0,4)) + list(range(16,32))
        # vregs = list(range(0,32))
        self.vregs = RegList(vregs)
        self.gprs  = RegList(list(range(0,18)))

        if self.modulus % 2 == 0:
            raise Exception("Modulus must be odd")
        if pow(root, 2*size, modulus) != 1:
            raise Exception(f"{root} is not a primitive {2*size}-th root of unity modulo {modulus}")
        if pow(root, size, modulus) == 1:
            raise Exception(f"{root} is not a primitive {2*size}-th root of unity modulo {modulus}")

        def is_power_of_2(n):
            if n == 1:
                return True
            if n % 2 == 1:
                raise False
            return is_power_of_2(n//2)
        if not is_power_of_2(size) or size <= 4:
            raise Exception(f"NTT size must be a power of 2, but {size} isn't")

        self.inv_mod = pow(self.modulus, -1, self.R)

        self.log2size = int(math.log(size,2))

    def check_layer_config(self):
        for (base_layer, num_merge) in self.layers:
            end_layer = base_layer + num_merge
            if end_layer > self.shuffle_boundary and end_layer != self.shuffle_boundary + 2:
                raise Exception("Unsupported layer configuration")

    def prepare_constants(self):
        self.modulus_vector = self.vregs.alloc(constraint=self.zreg_lane_hi,lax=True)

    def free_constants(self):
        self.vregs.free(self.modulus_vector)

    def root_of_unity_for_block(self,layer,block):

        def reverse_bit(num,width):
            result = 0
            while width > 0:
                result = (result << 1) + (num & 1)
                num >>= 1
                width -= 1
            return result

        log = reverse_bit(pow(2,layer) + block, self.log2size)
        root = pow(self.root, log, self.modulus)

        def res_even_frac(c,n):
            res = c % n
            if res >= n // 2:
                res -= n // 2
            if res % 2 != 0:
                if res < 0:
                    res += n
                else:
                    res -= n
            return res

        def even_frac(c,n):
            res  = res_even_frac(c,n)
            return (c - res)//n

        root_twisted = even_frac(root * self.R, self.modulus) % self.R
        root_twisted = root_twisted // 2

        return log, root, root_twisted

    def generate_constants(self):

        prefix = self.data_prefix

        yield "modulus:"
        yield f".{prefix} {-self.modulus}"
        yield f".{prefix} {-self.modulus}"
        yield f".{prefix} {-self.modulus}"
        yield f".{prefix} {-self.modulus}"

        root_asm = []
        root_twisted_asm = []

        def append_root(layer,block):
            nonlocal root_asm, root_twisted_asm
            if layer == None:
                root, root_twisted = 0,0
            else:
                _, root, root_twisted = self.root_of_unity_for_block(layer,block)
            new_asm_root  = f".{prefix} {root} // Layer {layer}, block {block}"
            new_asm_twist = f".{prefix} {root_twisted} // Layer {layer}, block {block}"
            root_asm.append(new_asm_root)
            root_twisted_asm.append(new_asm_twist)

        def roots_for_merged_layers(start_layer, num_layers):

            for block in range(0, pow(2,start_layer)):

                start_len = len(root_asm)

                for layer in range(0,num_layers):
                    cur_layer = start_layer + layer

                    # TODO: Document
                    if cur_layer >= self.shuffle_boundary and self.bitwidth == 16:
                        multiply = 2
                    else:
                        multiply = 1

                    roots_in_layer = pow(2,layer)
                    idx_seq = list(range(0,roots_in_layer))

                    # TODO: Document
                    if self.shuffle_boundary < cur_layer:
                        idx_seq = idx_seq[::2] + idx_seq[1::2]

                    if roots_in_layer == self.elements_per_vector:
                        # Add padding
                        append_root(None,None)
                    for idx in idx_seq:
                        for _ in range(0,multiply):
                            append_root(start_layer + layer,
                                        roots_in_layer * block + idx)

                end_len = len(root_asm)
                mod = (end_len - start_len) % self.elements_per_vector

                if mod != 0:
                    for _ in range(self.elements_per_vector - mod):
                        append_root(None,None)

                end_len = len(root_asm)
                mod = (end_len - start_len) % self.elements_per_vector
                if mod != 0:
                    raise Exception("Something went wrong")

                vectors_emitted = (end_len - start_len)//self.elements_per_vector
                self.vector_storage_per_block_at_layer[start_layer] = vectors_emitted

        self.root_offset_for_layer = {}
        self.vector_storage_per_block_at_layer = {}

        # Build twiddle factors for given layer configuration
        for base,merged in self.layers:
            self.root_offset_for_layer[base] = len(root_asm) * self.element_size
            roots_for_merged_layers(base, merged)

        align_log2 = int(math.log(self.root_align,2))
        align_offset = self.root_offset // (self.bitwidth//8)

        if not self.interleave_twiddles:
            yield f".align {align_log2}"
            yield "roots:"
            yield from root_asm
            yield f".align {align_log2}"
            yield "roots_twisted:"
            yield from root_twisted_asm

        else:

            def chunks(lst,size):
                for i in range(0,len(lst),size):
                    yield lst[i:i+size]

            root_blocks         = list(chunks(root_asm,self.elements_per_vector))
            root_twisted_blocks = list(chunks(root_twisted_asm,self.elements_per_vector))

            roots = zip(root_blocks,root_twisted_blocks)
            roots = [ e for p in roots for b in p for e in b]

            yield f".align {align_log2}"
            for _ in range(0,align_offset):
                yield f".{self.data_prefix} 0"
            yield "roots_merged:"
            yield from roots

    def init_constants(self):

        modulus_base = self.gprs.alloc()
        yield f"ldr x{modulus_base}, modulus_addr"
        yield f"ldr q{self.modulus_vector}, [x{modulus_base}]"
        self.gprs.free(modulus_base)

        self.ptrue = "P0"
        yield f"ptrue {self.ptrue}.{self.vector_suffix}"

        if not self.interleave_twiddles:
            self.ptr_roots = self.gprs.alloc()
            yield f"ldr x{self.ptr_roots}, roots_addr"
            self.ptr_roots_twisted = self.gprs.alloc()
            yield f"ldr x{self.ptr_roots_twisted}, roots_twisted_addr"
        else:
            self.ptr_roots_merged = self.gprs.alloc()
            yield f"ldr x{self.ptr_roots_merged}, roots_merged_addr"

        self.roots = None

    def get_data(self,index):
        if not index in self.data.keys():
            raise Exception(f"Data at index {index} hasn't been loaded")
        return self.data[index]

    def load_data(self,index,reg=None):
        if index in self.data.keys():
            # Data has already been loaded
            return iter([])

        self.data[index] = self.vregs.alloc(reg,constraint=self.zreg_lane_hi,lax=True)
        yield f"ldr q{self.data[index]}, [x{self._src}, #{self.element_size*index}]"

    def release_data(self,index):
        if index not in self.data.keys():
            raise Exception(f"Data at index {index} hasn't been loaded")

        self.vregs.free(self.data[index])
        del self.data[index]

    def store_data(self,index,release=True):
        if index not in self.data.keys():
            raise Exception(f"Data at index {index} hasn't been loaded")

        yield f"str q{self.data[index]}, [x{self._src}, #{self.element_size*index}]"

        if release:
            self.release_data(index)

    def ct_butterfly_single(self, butterfly, i, j, root_index):

        root = butterfly.root(root_index)
        root_lane = butterfly.root_lane(root_index)
        root_twisted = butterfly.root_twisted(root_index)
        root_twisted_lane = butterfly.root_twisted_lane(root_index)

        if root == None:
            raise Exception(f"Invalid root, index {root_index}")
        if root_twisted == None:
            raise Exception(f"Invalid twisted root, index {root_index}")

        modulus      = self.modulus_vector

        suf = self.vector_suffix

        # A lane value of None means that we don't want lane-indexing
        if root_lane != None:
            root_name = f"{root}.{suf}[{root_lane}]"
        else:
            root_name = f"{root}.{suf}"

        # A lane value of None means that we don't want lane-indexing
        if root_twisted_lane != None:
            root_twisted_name = f"{root_twisted}.{suf}[{root_twisted_lane}]"
        else:
            root_twisted_name = f"{root_twisted}.{suf}"

        tmp = self.vregs.alloc(constraint=self.zreg_lane_hi,lax=True)
        yield f"sqrdmulh z{tmp}.{suf}, " \
            f"z{self.get_data(butterfly[j])}.{suf}, " \
            f"z{root_twisted_name}"

        yield f"mul      z{self.get_data(butterfly[j])}.{suf}, "\
            f"z{self.get_data(butterfly[j])}.{suf}," \
            f"z{root_name}"

        self.vregs.free(tmp)
        yield f"mla      z{self.get_data(butterfly[j])}.{suf}, {self.ptrue}/M, z{tmp}.{suf}, "\
            f"z{modulus}.{suf}"

        tmp = self.vregs.alloc(constraint=self.zreg_lane_hi,lax=True)
        a = self.get_data(butterfly[i])
        b = self.get_data(butterfly[j])

        self.data[butterfly[j]] = tmp
        yield f"sub      z{tmp}.{suf}, z{a}.{suf}, z{b}.{suf}"

        # Make sure i is still allocated
        assert a == self.get_data(butterfly[i])

        self.vregs.free(b)
        yield f"add      z{a}.{suf}, z{a}.{suf}, z{b}.{suf}"


    def copy_root_scalars(self,dst,src):
        dst.root_vecs = src.root_vecs
        dst.root_twisted_vecs = src.root_twisted_vecs
        dst.root  = src.root
        dst.root_lane  = src.root_lane
        dst.root_twisted  = src.root_twisted
        dst.root_twisted_lane  = src.root_twisted_lane

    def load_input(self,butterfly, first=False):
        if butterfly == None:
            return iter([])

        if butterfly.load_idx >= pow(2,butterfly.merged):
            raise Exception("Too many loads")

        if not first:
            load_order = butterfly.load_order
        else:
            load_order = butterfly.load_order_first

        yield from self.load_data(butterfly[load_order[butterfly.load_idx]])
        butterfly.load_idx += 1

    def store_input(self,butterfly,last=False):
        if butterfly == None:
            return iter([])

        if butterfly.store_idx >= pow(2,butterfly.merged):
            raise Exception("Too many late stores")

        if not last:
            store_order = butterfly.store_order
        else:
            store_order = butterfly.store_order_last
            if butterfly.store_idx >= len(store_order):
                return iter([])

        yield from self.store_data(butterfly[store_order[butterfly.store_idx]])
        butterfly.store_idx += 1

    def transpose4(self,idx):

        # Need four temporaries for the transposition
        t = [ None for _ in range(0,4) ]

        t[0] = self.vregs.alloc(constraint=self.zreg_lane_hi,lax=True)
        yield f"trn1 z{t[0]}.S, z{idx(0)}.S, z{idx(1)}.S"
        t[1] = self.vregs.alloc(constraint=self.zreg_lane_hi,lax=True)
        yield f"trn2 z{t[1]}.S, z{idx(0)}.S, z{idx(1)}.S"
        t[2] = self.vregs.alloc(constraint=self.zreg_lane_hi,lax=True)
        yield f"trn1 z{t[2]}.S, z{idx(2)}.S, z{idx(3)}.S"
        t[3] = self.vregs.alloc(constraint=self.zreg_lane_hi,lax=True)
        yield f"trn2 z{t[3]}.S, z{idx(2)}.S, z{idx(3)}.S"

        yield f"trn2 z{idx(2)}.d, z{t[0]}.d, z{t[2]}.d"
        yield f"trn2 z{idx(3)}.d, z{t[1]}.d, z{t[3]}.d"

        # Do this here and not after the yield
        self.vregs.free(t[0])
        self.vregs.free(t[2])
        yield f"trn1 z{idx(0)}.d, z{t[0]}.d, z{t[2]}.d"

        # Do this here and not after the yield
        self.vregs.free(t[1])
        self.vregs.free(t[3])
        yield f"trn1 z{idx(1)}.d, z{t[1]}.d, z{t[3]}.d"

    def zreg_lane_lo(self,r):
        if self.bitwidth == 32:
            return (r in range(0,8))
        else:
            return (r in range(0,16))

    def zreg_lane_hi(self,r):
        return not self.zreg_lane_lo(r)

    def load_root_scalars(self,butterfly):

        if butterfly == None or butterfly.load_roots == False:
            return iter([])

        def gen():

            root_vec_storage = self.vector_storage_per_block_at_layer[butterfly.layer]
            root_storage_byte = self.vector_bytelen * root_vec_storage

            r =  [ None for _ in range(0, root_vec_storage) ]
            rt = [ None for _ in range(0, root_vec_storage) ]

            butterfly.root_vecs = r
            butterfly.root_twisted_vecs = rt

            order = butterfly.root_load_order

            if self.increment_root_ptr:
                assert(self.interleave_twiddles == False)
                if self.multi_access_strategy == 0:
                    for i in range(0,root_vec_storage):
                        r[order[i]] = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        yield f"ldr q{r[order[i]]},  [x{self.ptr_roots}],         #+{self.vector_bytelen}"
                        rt[order[i]] = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        yield f"ldr q{rt[order[i]]}, [x{self.ptr_roots_twisted}], #+{self.vector_bytelen}"
                elif self.multi_access_strategy == 1:
                    for i in range(0,root_vec_storage,2):
                        rt[order[i]]   = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        rt[i+1] = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        yield f"ldp q{rt[order[i]]}, q{rt[i+1]}, [x{self.ptr_roots_twisted}], #+{2*self.vector_bytelen}"
                        r[order[i]]   = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        r[order[i+1]] = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        yield f"ldp q{r[order[i]]},  q{r[i+1]}, [x{self.ptr_roots}],          #+{2*self.vector_bytelen}"
            else:

                offset_base = self.root_offset_for_layer[butterfly.layer]
                offset_base += root_storage_byte * butterfly.block

                for i in range(0,root_vec_storage):

                    offset = offset_base + order[i] * self.vector_bytelen
                    if not self.interleave_twiddles:
                        r[order[i]] = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        yield f"ldr q{r[order[i]]},  [x{self.ptr_roots},         #+{offset}]"
                        rt[order[i]] = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        yield f"ldr q{rt[order[i]]}, [x{self.ptr_roots_twisted}, #+{offset}]"
                    else:
                        r[order[i]] = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        yield f"ldr q{r[order[i]]},  [x{self.ptr_roots_merged}, #+{2*offset+0}]"
                        rt[order[i]] = self.vregs.alloc(constraint=self.zreg_lane_lo)
                        yield f"ldr q{rt[order[i]]}, [x{self.ptr_roots_merged}, #+{2*offset+self.vector_bytelen}]"

        if butterfly.scalar_load == None:
            butterfly.scalar_load = gen()

        return butterfly.scalar_load

    def get_transpose(self,butterfly):

        def butterfly_accessor(idx):
            return self.get_data(butterfly[idx])

        if butterfly == None:
            return iter([])

        if butterfly.transpose == None:
            butterfly.transpose = self.transpose4(butterfly_accessor)

        while True:
            n = next(butterfly.transpose,None)
            if n == None:
                break
            else:
                yield n

    def progress_arithmetic(self,butterfly,idx):
        if butterfly == None:
            return iter([])

        yield next(butterfly.gs[idx])

    def get_schedule_triple_no_transpose(self, idx):

        if self.bitwidth == 32:
            default = { "load_order":  [7,6,4,5,3,2,0,1],
                        "store_order": [0,1,2,3,6,7,4,5],
                        "numbering":   list(zip([3,2,0,1, 1,0,5,4, 0,2,6,4],
                                                [7,6,4,5, 3,2,7,6, 1,3,7,5],
                                                [0,0,0,0, 1,1,2,2, 3,4,6,5])),
                        "twiddles":    { 0: (0,0),
                                         1: (0,1),
                                         2: (0,2),
                                         3: (1,0),
                                         4: (1,1),
                                         5: (1,2),
                                         6: (1,3) },
                        "root_load_order": list(range(0,10)),
                        "schedule": None,
            }
        elif self.bitwidth == 64:
            default = { "load_order":  [7,6,4,5,3,2,0,1],
                        "store_order": [0,1,2,3,6,7,4,5],
                        "numbering":   list(zip([3,2,0,1, 1,0,5,4, 0,2,6,4],
                                                [7,6,4,5, 3,2,7,6, 1,3,7,5],
                                                [0,0,0,0, 1,1,2,2, 3,4,6,5])),
                        "twiddles":    { 0: (0,0),
                                         1: (1,0),
                                         2: (1,1),
                                         3: (2,0),
                                         4: (2,1),
                                         5: (3,0),
                                         6: (3,1) },
                        "root_load_order": list(range(0,10)),
                        "schedule": None,
            }

        modifications = {

           # INDEX 0
           # Trivial implementation, no interleaving whatsoever
           0: { "schedule":
                ["m",  "l", "l", "l", "l", "l", "l", "l", "l",
                  0, 0, 0, 0, 0,
                  1, 1, 1, 1, 1,
                  2, 2, 2, 2, 2,
                  3, 3, 3, 3, 3,
                  4, 4, 4, 4, 4, "lre",
                  5, 5, 5, 5, 5,
                  6, 6, 6, 6, 6,
                  7, 7, 7, 7, 7,
                  8, 8, 8, 8, 8,      "s", "s",
                  9, 9, 9, 9, 9,      "s", "s",
                  10, 10, 10, 10, 10, "s", "s",
                  11, 11, 11, 11, 11, "s", "s", "fr" ] },

           # INDEX 1
           # - No early loads, few late stores
           # - suitable for two inputs
           # - Lots of spacing between all GS components
           1: { "schedule":
             ["m",  "l", "l", 0,  -2, -1,  0, -2, "sl", "sl",
                  "l", "l", 1,  -1,  0,  1, -1, "sl", "sl", "frl",
                  "l", "l", 2,   0,  1,  2,  0,
                  "l", "l", 3,   1,  2,  3,  1,
                            4,   2,  3,  4,  2,
                            5,   3,  4,  5,  3,
                            6,   4,  5,  6,  4, "lre",
                            7,   5,  6,  7,  5,
                            8,   6,  7,  8,  6,
                            9,   7,  8,  9,  7,
                            10,  8,  9, 10,  8, "s", "s",
                            11,  9, 10, 11,  9, "s", "s" ] },

           # INDEX 2
           # - Late-store, but only few early loads
           # - GS blocks (mul,mul),(mul),(add,sub)
           2: { "schedule":
             ["m", 0,        0,  "l",  -1, -2, -2,
                 1,  "sl", 1,  "l",   0, -1, -1, "frl",
                 2,  "sl", 2,  "l",   1,  0,  0,
                 3,  "sl", 3,  "l",   2,  1,  1,
                 4,  "sl", 4,  "l",   3,  2,  2,
                 5,  "sl", 5,  "l",   4,  3,  3,
                 6,  "sl", 6,         5,  4,  4,
                 7,  "sl", 7,         6,  5,  5, "lres",
                 8,  "sl", 8,         7,  6,  6, "lres",
                 9,        9,         8,  7,  7, "lre",
                 10,       10, "le",  9,  8,  8,
                 11,       11, "le", 10,  9,  9 ] },

           # INDEX 3
           # - Extensive pre-loading and late-storing
           # - GS blocks (mul,mul),(mul),(add,sub)
           3 : { "schedule":
             ["m", 0,        0,        -1, -2, -2,
                 1,        1,         0, -1, -1, "frl",
                 2,        2,  "le",  1,  0,  0,
                 3,        3,  "le",  2,  1,  1,
                 4,  "sl", 4,  "le",  3,  2,  2,
                 5,  "sl", 5,  "le",  4,  3,  3,
                 6,  "sl", 6,  "le",  5,  4,  4, "lre",
                 7,  "sl", 7,  "le",  6,  5,  5,
                 8,  "sl", 8,  "le",  7,  6,  6,
                 9,  "sl", 9,  "le",  8,  7,  7,
                 10, "sl", 10,        9,  8,  8,
                 11, "sl", 11,       10,  9,  9 ] },

           # INDEX 4
           # - Extensive pre-loading and late-storing
           # - GS blocks (mul), (mul) (mul),(add,sub)
           4 : { "schedule":
             ["m", 0,               -1,                 0, -2, -2,
                 1,                0,                 1, -1, -1, "frl",
                 2,                1,  "le",  2,  0,  0,
                 3,                2,  "le",  3,  1,  1,
                 4,  "sl", 3,  "le",  4,  2,  2,
                 5,  "sl", 4,  "le",  5,  3,  3,
                 6,  "sl", 5,  "le",  6,  4,  4, "lre",
                 7,  "sl", 6,  "le",  7,  5,  5,
                 8,  "sl", 7,  "le",  8,  6,  6,
                 9,  "sl", 8,  "le",  9,  7,  7,
                 10, "sl", 9,                10,  8,  8,
                 11, "sl", 10,               11,  9,  9 ] },

           # INDEX 5
           # - Extensive pre-loading and late-storing
           # - GS blocks (mul),(mul,mul),(add,sub)
           5 : { "schedule":
             ["m", 0,              -1, -1, -2, -2,
                 1,               0,  0, -1, -1, "frl",
                 2,        "le",  1,  1,  0,  0,
                 3,        "le",  2,  2,  1,  1,
                 4,  "sl", "le",  3,  3,  2,  2,
                 5,  "sl", "le",  4,  4,  3,  3,
                 6,  "sl", "le",  5,  5,  4,  4, "lre",
                 7,  "sl", "le",  6,  6,  5,  5,
                 8,  "sl", "le",  7,  7,  6,  6,
                 9,  "sl", "le",  8,  8,  7,  7,
                 10, "sl",        9,  9,  8,  8,
                 11, "sl",       10, 10,  9,  9 ] },

           # INDEX 6
           # - No early loads, few late stores
           # - suitable for two inputs
           # - GS blocks (mul,mul),(mul),(add), (sub)
           6 : { "schedule":
             ["m",  "l", "l", 0,  0, -2, -1,  -2, "sl", "sl",
                  "l", "l", 1,  1, -1,  0,  -1, "sl", "sl", "frl",
                  "l", "l", 2,  2,  0,  1,   0,
                  "l", "l", 3,  3,  1,  2,   1,
                            4,  4,  2,  3,   2,
                            5,  5,  3,  4,   3,
                            6,  6,  4,  5,   4, "lre",
                            7,  7,  5,  6,   5,
                            8,  8,  6,  7,   6,
                            9,  9,  7,  8,   7,
                            10, 10, 8,  9,   8, "s", "s",
                            11, 11, 9, 10,   9, "s", "s" ] },

           # INDEX 7
           # - No early loads, few late stores
           # - suitable for two inputs
           # - GS blocks (mul,mul),(mul),(add), (sub)
           # - scattered stores
           7 : { "schedule":
             ["m",  "l", "l", 0, 0, "sl", -2, -1,  -2, "sl",
                  "l", "l", 1,    "sl", 1, -1,  0,  -1, "sl", "frl",
                  "l", "l", 2,    "sl", 2,  0,  1,   0,
                  "l", "l", 3, 3,       1,  2,   1,
                            4, 4,       2,  3,   2,
                            5, 5,       3,  4,   3,
                            6, 6,       4,  5,   4, "lre",
                            7, 7,       5,  6,   5,
                            8, 8,       6,  7,   6,
                            9, 9,       7,  8,   7,
                            10, 10,     8,  9,   8, "s",
                            11, 11, "s", 9, 10,   9, "s" ] },

           # INDEX 8
           # - No early loads, few late stores
           # - suitable for two inputs
           # - GS blocks (mul,mul),(mul),(add), (sub)
           # - stores after muls only, trying to avoid them going
           #   multiply-capable SIMD units
           8 : { "schedule":
             ["m",  "l", "l", 0, "sl", 0, "sl", -2, -1,  -2,
                  "l", "l", 1, "sl", 1, "sl", -1,  0,  -1, "frl",
                  "l", "l", 2, "sl", 2, "sl", 0,  1,   0,
                  "l", "l", 3, 3,  1,  2,   1,
                            4, 4,  2,  3,   2,
                            5, 5,  3,  4,   3,
                            6, 6,  4,  5,   4, "lre",
                            7, 7,  5,  6,   5,
                            8, 8,  6,  7,   6,
                            9, 9,  7,  8,   7,
                            10, 10, 8,  9,   8,
                            11, "s", 11, "s", 9, 10, 9 ] },

           # INDEX 9
           # - No early loads, few late stores
           # - suitable for two inputs
           # - GS blocks (mul,mul),(mul),(add), (sub)
           # - stores after muls only, trying to avoid them going
           #   multiply-capable SIMD units
           9 : { "schedule":
                 ["m",  "l", "l", 0, "sl", 0, -2, -1, "sl",  -2,
                  "l", "l", 1, "sl", 1, -1,  0, "sl",  -1, "frl",
                  "l", "l", 2, "sl", 2,  0,  1, "sl",  0,
                  "l", "l", 3, 3,  1,  2,   1,
                                  4, 4,  2,  3,   2,
                                  5, 5,  3,  4,   3,
                                  6, 6,  4,  5,   4, "lre",
                                  7, 7,  5,  6,   5,
                                  8, 8,  6,  7,   6,
                                  9, 9,  7,  8,   7,
                                  10, 10, 8,  9,   8,
                                  11, "s", 11, 9, 10, "s", 9 ] },

           # INDEX 10
           # - No early loads, few late stores
           # - suitable for two inputs
           # - GS blocks (mul,mul),(mul),(add), (sub)
           # - stores after muls only, trying to avoid them going
           #   multiply-capable SIMD units
           10 : { "schedule":
             ["m",  "l", "l", 0, "sl", 0, "sl", -1, -2,  -2,
                  "l", "l", 1, "sl", 1, "sl",  0, -1,  -1, "frl",
                  "l", "l", 2, "sl", 2, "sl",   1,  0,  0,
                  "l", "l", 3, 3,   2,  1,   1,
                            4, 4,   3,  2,   2,
                            5, 5,   4,  3,   3,
                            6, 6,   5,  4,   4, "lre",
                            7, 7,   6,  5,   5,
                            8, 8,   7,  6,   6,
                            9, 9,   8,  7,   7,
                            10, 10, 9,  8,   8,
                            11, "s", 11, "s", 10, 9, 9 ] },

           # INDEX 11
           # - No early loads, few late stores
           # - suitable for two inputs
           # - GS blocks (mul,mul),(mul),(add), (sub)
           # - stores after muls only, trying to avoid them going
           #   multiply-capable SIMD units
           11 : { "schedule":
                ["m",  0, "sl", 0, "sl", -1, "l", -2, "l", -2,
                  1, "sl", 1, "sl",  0, "l", -1, "l", -1, "frl",
                  2, "sl", 2, "sl",  1, "l",  0, "l", 0,
                  3, 3,   1,  2,   1,
                  4, 4,   2,  3,   2,
                  5, 5,   3,  4,   3,
                  6, 6,   4,  5,   4, "lre",
                  7, 7,   5,  6,   5,
                  8, 8,   6,  7,   6,
                  9, 9,   7,  8,   7,
                  10, 10, 8,  9,   8,
                  11, "s", 11, "s", 10, 9, "le", "le", 9 ] },

        }

        modification = modifications[idx]

        for k,v in modification.items():
            if not k in default.keys():
                raise Exception(f"Invalid modification: {k}")

        dic = { **default, **modification }

        dic["load_order_first"] = dic.get("load_order_first", dic["load_order"])
        dic["store_order_last"] = dic.get("store_order_last", dic["store_order"])

        return dic

    def get_schedule_double_no_transpose_zipped(self, idx):

        load_order_default           = [2,3,0,1]
        store_order_default          = [0,1,2,3]
        butterfly_numbering_default  = list(zip([0,1,0,2],
                                                [2,3,1,3],
                                                [0,0,1,2]))
        twiddle_numbering_default    = { 0: (0,0),
                                         1: (0,1),
                                         2: (0,2) }
        root_load_order_default = list(range(0,10)) # Identity

        schedules = [

           # INDEX 0
           # Trivial implementation, no interleaving whatsoever
           [ None, None, None, None,
             (0, "m"), (0, "l"), (0, "l"), (0, "l"), (0, "l"),
             (0, 0), (0, 0), (0, 0), (0, 0), (0, 0),
             (0, 1), (0, 1), (0, 1), (0, 1), (0, 1), (0,"lre"),
             (0, 2), (0, 2), (0, 2), (0, 2), (0, 2),
             (0, 3), (0, 3), (0, 3), (0, 3), (0, 3),
             (0,"s"), (0,"s"), (0,"s"), (0,"s"), (0,"frl"),
             (1, "m"), (1, "l"), (1, "l"), (1, "l"), (1, "l"),
             (1, 0), (1, 0), (1, 0), (1, 0), (1, 0),
             (1, 1), (1, 1), (1, 1), (1, 1), (1, 1), (1,"lre"),
             (1, 2), (1, 2), (1, 2), (1, 2), (1, 2),
             (1, 3), (1, 3), (1, 3), (1, 3), (1, 3),
             (1,"s"), (1,"s"), (1,"s"), (1,"s"), (1,"frl") ]
        ]

        load_order, store_order, numbering, twiddles, root_order, schedule = schedules[idx]

        if load_order == None:
            load_order = load_order_default
        if store_order == None:
            store_order = store_order_default
        if numbering == None:
            numbering = butterfly_numbering_default
        if twiddles == None:
            twiddles = twiddle_numbering_default
        if root_order == None:
            root_order = root_load_order_default

        return load_order, store_order, numbering, twiddles, root_order, schedule

    def get_schedule_double_no_transpose_quad_zipped(self, idx):

        default = { "load_order":  [2,3,0,1],
                    "store_order": [0,1,2,3],
                    "numbering":   list(zip([0,1,0,2],
                                            [2,3,1,3],
                                            [0,0,1,2])),
                    "twiddles":    { 0: (0,0),
                                     1: (0,1),
                                     2: (0,2) },
                    "root_load_order": list(range(0,10)),
                    "schedule": None }

        modifications = {

           # INDEX 0
           # Trivial implementation, no interleaving whatsoever
           0 : { "schedule":
             [ (0, "m"), (0, "l"), (0, "l"), (0, "l"), (0, "l"),
             (0, 0), (0, 0), (0, 0), (0, 0), (0, 0),
             (0, 1), (0, 1), (0, 1), (0, 1), (0, 1), (0,"lre"),
             (0, 2), (0, 2), (0, 2), (0, 2), (0, 2),
             (0, 3), (0, 3), (0, 3), (0, 3), (0, 3),
             (0,"s"), (0,"s"), (0,"s"), (0,"s"), (0,"frl"),

             (1, "m"), (1, "l"), (1, "l"), (1, "l"), (1, "l"),
             (1, 0), (1, 0), (1, 0), (1, 0), (1, 0),
             (1, 1), (1, 1), (1, 1), (1, 1), (1, 1), (1,"lre"),
             (1, 2), (1, 2), (1, 2), (1, 2), (1, 2),
             (1, 3), (1, 3), (1, 3), (1, 3), (1, 3),
             (1,"s"), (1,"s"), (1,"s"), (1,"s"), (1,"frl"),

             (2, "m"), (2, "l"), (2, "l"), (2, "l"), (2, "l"),
             (2, 0), (2, 0), (2, 0), (2, 0), (2, 0),
             (2, 1), (2, 1), (2, 1), (2, 1), (2, 1), (2,"lre"),
             (2, 2), (2, 2), (2, 2), (2, 2), (2, 2),
             (2, 3), (2, 3), (2, 3), (2, 3), (2, 3),
             (2,"s"), (2,"s"), (2,"s"), (2,"s"), (2,"frl"),

             (3, "m"), (3, "l"), (3, "l"), (3, "l"), (3, "l"),
             (3, 0), (3, 0), (3, 0), (3, 0), (3, 0),
             (3, 1), (3, 1), (3, 1), (3, 1), (3, 1), (3,"lre"),
             (3, 2), (3, 2), (3, 2), (3, 2), (3, 2),
             (3, 3), (3, 3), (3, 3), (3, 3), (3, 3),
             (3,"s"), (3,"s"), (3,"s"), (3,"s"), (3,"frl") ] },

           # INDEX 1
           # Interleaved arithmetic
           1 : { "schedule": [
            (0,"m"), (0,"l"), (0,"l"), (0,"l"), (0,"l"),
            (1,"m"), (1,"l"), (1,"l"), (1,"l"), (1,"l"),
            (2,"m"), (2,"l"), (2,"l"), (2,"l"), (2,"l"),
            (3,"m"), (3,"l"), (3,"l"), (3,"l"), (3,"l"),

            (0,"lrs"), (0,"lrs"),
            (1,"lrs"), (1,"lrs"),
            (2,"lrs"), (2,"lrs"),
            (3,"lrs"), (3,"lrs"),

            (0,0), (0,0),
            (0,1), (0,1), (0,0),
            (1,0), (1,0), (0,1), (0,0), (0,0),
            (1,1), (1,1), (1,0), (0,1), (0,1),
            (0,2), (0,2), (1,1), (1,0), (1,0),
            (0,3), (0,3), (0,2), (1,1), (1,1),
            (1,2), (1,2), (0,3), (0,2), (0,2), (0, "frs"), (0, "frs"),
            (1,3), (1,3), (1,2), (0,3), (0,3),
            (2,0), (2,0), (1,3), (1,2), (1,2), (1, "frs"), (1, "frs"),
            (2,1), (2,1), (2,0), (1,3), (1,3),
            (3,0), (3,0), (2,1), (2,0), (2,0),
            (3,1), (3,1), (3,0), (2,1), (2,1),
            (2,2), (2,2), (3,1), (3,0), (3,0),
            (2,3), (2,3), (2,2), (3,1), (3,1),
            (3,2), (3,2), (2,3), (2,2), (2,2), (2, "frs"), (2, "frs"),
            (3,3), (3,3), (3,2), (2,3), (2,3),
                          (3,3), (3,2), (3,2), (3, "frs"), (3, "frs"),
                                 (3,3), (3,3),

            (0, "s"), (0, "s"), (0, "s"), (0, "s"),
            (1, "s"), (1, "s"), (1, "s"), (1, "s"),
            (2, "s"), (2, "s"), (2, "s"), (2, "s"),
            (3, "s"), (3, "s"), (3, "s"), (3, "s") ] },

           # INDEX 2
           # Butterfly-wise interleaving
           2 : { "schedule": [
             (0, "l"), (0, "l"), (0, "l"),
             (1, "l"), (1, "l"), (1, "l"),
             (2, "l"), (2, "l"), (2, "l"),
             (3, "l"), (3, "l"), (3, "l"),
             (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, "l"),
             (1, 0), (1, 0), (1, 0), (1, 0), (1, 0), (1, "l"),
             (2, 0), (2, 0), (2, 0), (2, 0), (2, 0), (2, "l"),
             (3, 0), (3, 0), (3, 0), (3, 0), (3, 0), (3, "l"),
             (0, 1), (0, 1), (0, 1), (0, 1), (0, 1),
             (1, 1), (1, 1), (1, 1), (1, 1), (1, 1),
             (2, 1), (2, 1), (2, 1), (2, 1), (2, 1),
             (3, 1), (3, 1), (3, 1), (3, 1), (3, 1),
             (0, 2), (0, 2), (0, 2), (0, 2), (0, 2),
             (1, 2), (1, 2), (1, 2), (1, 2), (1, 2), (0, "s"), (0, "s"),
             (2, 2), (2, 2), (2, 2), (2, 2), (2, 2), (1, "s"), (1, "s"),
             (3, 2), (3, 2), (3, 2), (3, 2), (3, 2), (2, "s"), (2, "s"),
             (0, 3), (0, 3), (0, 3), (0, 3), (0, 3), (3, "s"), (3, "s"),
                                                     (0,"fr"), (0,"lre"),
             (1, 3), (1, 3), (1, 3), (1, 3), (1, 3), (1,"fr"), (1,"lre"),
             (2, 3), (2, 3), (2, 3), (2, 3), (2, 3), (2,"fr"), (2,"lre"),
             (3, 3), (3, 3), (3, 3), (3, 3), (3, 3), (3,"fr"), (3,"lre"),
             (0,"s"), (0,"s"),
             (1,"s"), (1,"s"),
             (2,"s"), (2,"s"),
             (3,"s"), (3,"s"),
            ] },

           # INDEX 3
           # Butterfly-wise interleaving
           3: { "schedule": [
             (0, "l"), (0, "l"), (0, "l"),
             (1, "l"), (1, "l"), (1, "l"),
             (2, "l"), (2, "l"), (2, "l"),
             (3, "l"), (3, "l"), (3, "l"),

             (0, 0), (1, 0), (2, 0), (3, 0), (0, "sl"),
             (0, 0), (1, 0), (2, 0), (3, 0), (1, "sl"),
             (0, 0), (1, 0), (2, 0), (3, 0), (2, "sl"),
             (0, 0), (1, 0), (2, 0), (3, 0), (3, "sl"),
             (0, 0), (1, 0), (2, 0), (3, 0),

             (0, "l"),
             (1, "l"),
             (2, "l"),
             (3, "l"),

             (0, 1), (1, 1), (2, 1), (3, 1),
             (0, 1), (1, 1), (2, 1), (3, 1),
             (0, 1), (1, 1), (2, 1), (3, 1),
             (0, 1), (1, 1), (2, 1), (3, 1),
             (0, 1), (1, 1), (2, 1), (3, 1),

             (0, 2), (1, 2), (2, 2), (3, 2),
             (0, 2), (1, 2), (2, 2), (3, 2),
             (0, 2), (1, 2), (2, 2), (3, 2),
             (0, 2), (1, 2), (2, 2), (3, 2),
             (0, 2), (1, 2), (2, 2), (3, 2),

             (0, 3), (1, 3), (2, 3), (3, 3), (0,"s"), (0,"s"),
             (0, 3), (1, 3), (2, 3), (3, 3), (1,"s"), (1,"s"),
                                             (0, "fr"),
                                             (1, "fr"),
                                             (2, "fr"),
                                             (3, "fr"),
                                             (0,"lre"),
                                             (1,"lre"),
             (0, 3), (1, 3), (2, 3), (3, 3), (2,"s"), (2,"s"),
                                             (2,"lre"),
             (0, 3), (1, 3), (2, 3), (3, 3), (3,"s"), (3,"s"),
                                             (3,"lre"),
             (0, 3), (1, 3), (2, 3), (3, 3),

             (0, "s"),
             (1, "s"),
             (2, "s"),
             (3, "s"),
            ] },

           # INDEX 4
           # Careful scheduling of arithmetic instructions,
           # tailored to microarchitectures like Cortex-X1:
           # - 4 SIMD units
           # - 2 of them multiply capable
           # - Multiply latency 4, but 1-cycle fwd for MUL-MLA
           # Note the asymmetry between 0-3 and 4-7, leveraging
           # the fast fwd from MUL to MLA.
           4 : { "store_order": [1,0,3,2],
                 "schedule":
             [

                 (0,"lrs"), (0,"lrs"),
                 (0,"l"),
                 (0,0),                              (2,-2), (2,"sl"),
                 (0,0),                              (2,-2), (2,"sl"),
                         (0,"l"),
                         (0,1),                      (2,-1),
                         (0,1),                      (2,-1), (2,"sl"), (2,"sl"),
                                 (1,"lrs"), (1,"lrs"),
                                 (1,"l"),
                                 (1,0),              (3,-2),
                                 (1,0),              (3,-2), (3,"sl"), (3,"sl"),
                                         (1,"l"),
                                         (1,1),      (3,-1),
                                         (1,1),      (3,-1), (3,"sl"), (3,"sl"),
                 (2,"l"),
                 (2,"lrs"), (2,"lrs"),
                 (0,0),
                 (2,0),
                         (2,"l"),
                         (0,1),
                         (2,1),
                                 (3,"l"),
                                 (3,"lrs"), (3,"lrs"),
                                 (1,0),
                                 (3,0),
                                         (3,"l"),
                                         (1,1),
                                         (3,1),

                 (2,"l"),                            (0,"l"),
                 (2,0),                              (0,0),
                 (2,1),                              (0,0),
                         (2,"l"),                    (0,"l"),
                         (2,0),                      (0,1),
                         (2,1),                      (0,1),
                                 (3,"l"),            (1,"l"),
                                 (3,0),              (1,0),
                                 (3,1),              (1,0),
                                         (3,"l"),    (1,"l"),
                                         (3,0),      (1,1),
                                         (3,1),      (1,1),

                 (0,2),
                 (0,2),
                         (0,3),                      (2,0),
                         (0,3),                      (2,0),
                         (0,"frs"),
                         (0,"frs"),
                                 (1,2),              (2,1),
                                 (1,2),              (2,1),
                                         (1,3),      (3,0),
                                         (1,3),      (3,0),
                                         (1,"frs"),
                                         (1,"frs"),
                 (0,2),                              (3,1),
                 (2,2),                              (3,1),
                         (0,3),
                         (2,3),
                                 (1,2),
                                 (3,2),
                                         (1,3),
                                         (3,3),

                 (2,2),                              (0,2),
                 (2,3),                              (0,2), (0,"s"), (0,"s"),
                         (2,2),                      (0,3),
                         (2,3),                      (0,3), (0,"s"), (0,"s"),
                         (2,"frs"),
                         (2,"frs"),
                                 (3,2),              (1,2),
                                 (3,3),              (1,2), (1,"s"), (1,"s"),
                                         (3,2),      (1,3),
                                         (3,3),      (1,3), (1,"s"), (1,"s"),
                                         (3,"frs"),
                                         (3,"frs"),

             ] },

           # INDEX 5
           # Variation of 4 which tries to have blocks
           # 2 multiply + 1 add/sub + 1 str
           # This combination can in principle keep all SIMD units busy
           5 : { "store_order": [1,0,3,2],
                 "schedule": [

                 (0,0),                              (2,-2),
                 (0,0),                              (2,"sl"),
                         (0,"l"),
                         (0,1),                      (2,-2),
                         (0,1),                      (2,"sl"),
                                 (1,"lrs"),
                                 (1,"lrs"),
                                 (1,"l"),
                                 (1,0),              (2,-1),
                                 (1,0),              (2,"sl"),
                                         (1,"l"),
                                         (1,1),      (2,-1),
                                         (1,1),      (2,"sl"),
                 (2,"lrs"),
                 (2,"lrs"),
                 (0,0),                              (3,-2),
                 (2,0),                              (3,"sl"),
                         (2,"l"),
                         (0,1),                      (3,-2),
                         (2,1),                      (3,"sl"),
                                 (3,"lrs"),
                                 (3,"lrs"),
                                 (1,0),              (3,-1),
                                 (3,0),              (3,"sl"),
                                         (3,"l"),
                                         (1,1),      (3,-1),
                                         (3,1),      (3,"sl"),

                 (2,"l"),                            (0,"l"),
                 (2,0),                              (0,0),
                 (2,1),                              (0,0),
                         (2,"l"),                    (0,"l"),
                         (2,0),                      (0,1),
                         (2,1),                      (0,1),
                                 (3,"l"),            (1,"l"),
                                 (3,0),              (1,0),
                                 (3,1),              (1,0),
                                         (3,"l"),    (1,"l"),
                                         (3,0),
                                         (3,1),      (1,1),

                 (0,2),
                 (0,2),                              (1,1),
                         (0,3),                      (2,0),
                         (0,3),                      (2,0),
                         (0,"frs"),
                         (0,"frs"),
                                 (1,2),              (2,1),
                                 (1,2),              (2,1),
                                         (1,3),      (3,0),
                                         (1,3),      (3,0),
                                         (1,"frs"),
                                         (1,"frs"),
                 (0,2),                              (3,1), (3,"le"),
                 (2,2),                              (3,1),
                         (0,3),                      (2,"le"),
                         (2,3),
                                 (1,2),              (0,"le"),
                                 (3,2),
                                         (1,3),      (0,"lres"),
                                         (3,3),      (0,"lres"),

                 (2,2),                              (0,2), (0,"s"),
                 (2,3),                              (0,2), (0,"s"),
                         (2,2),                      (0,3), (0,"s"),
                         (2,3),                      (0,3), (0,"s"),
                         (2,"frs"),
                         (2,"frs"),
                                 (3,2),              (1,2), (1,"s"),
                                 (3,3),              (1,2), (1,"s"),
                                         (3,2),      (1,3), (1,"s"),
                                         (3,3),      (1,3), (1,"s"),
                                         (3,"frs"),
                                         (3,"frs"),
             ] },

           # INDEX 6
           # Variation of 5
           6 : { "store_order": [1,0,3,2],
                 "schedule": [

                 (0,0),                              (2,-2),
                 (0,0),                              (2,"sl"),
                         (0,"l"),
                         (0,1),                      (2,-2),
                         (0,1),                      (2,"sl"),
                                 (1,"lrs"),
                                 (1,"lrs"),
                                 (1,"l"),
                                 (1,0),              (2,-1),
                                 (1,0),              (2,"sl"),
                                         (1,"l"),
                                         (1,1),      (2,-1),
                                         (1,1),      (2,"sl"),
                 (2,"lrs"),
                 (2,"lrs"),
                 (0,0),                              (3,-2),
                 (2,0),                              (3,"sl"),
                         (2,"l"),
                         (0,1),                      (3,-2),
                         (2,1),                      (3,"sl"),
                                 (3,"lrs"),
                                 (3,"lrs"),
                                 (1,0),              (3,-1),
                                 (3,0),              (3,"sl"),
                                         (3,"l"),
                                         (1,1),      (3,-1),
                                         (3,1),      (3,"sl"), (0,"l"),

                 (2,"l"),
                 (2,0),                              (0,0), (0,"l"),
                 (2,1),                              (0,0),
                         (2,"l"),
                         (2,0),                      (0,1), (1,"l"),
                         (2,1),                      (0,1),
                                 (3,"l"),
                                 (3,0),              (1,0), (1,"l"),
                                 (3,1),              (1,0),
                                         (3,"l"),
                                         (3,0),      (1,1),
                                         (3,1),      (1,1),

                 (0,2),
                 (0,2),
                         (0,3),                      (2,0),
                         (0,3),                      (2,0),
                         (0,"frs"),
                         (0,"frs"),
                                 (1,2),              (2,1),
                                 (1,2),              (2,1),
                                         (1,3),      (3,0),
                                         (1,3),      (3,0),
                                         (1,"frs"),
                                         (1,"frs"),
                 (0,2),                              (3,1), (3,"le"),
                 (2,2),                              (3,1),
                         (0,3),                      (2,"le"),
                         (2,3),                      (0,2), # This isn't ready yet, but at least
                                                            # we keep the balance of mul/add/str
                                                            # instructions and don't have a
                                                            # bottleneck at the end
                                 (1,2),              (0,"le"),
                                 (3,2),              (0,2), (0,"s"),
                                         (1,3),      (0,"lres"), (0,"lres"),
                                         (3,3),      (0,3), (0,"s"),

                 (2,2),                              (0,3),
                 (2,3),                              (0,"s"),
                         (2,2),                      (1,2),
                         (2,3),                      (0,"s"),
                         (2,"frs"),
                         (2,"frs"),
                                 (3,2),              (1,"s"),
                                 (3,3),              (1,2), (1,"s"),
                                         (3,2),      (1,3), (1,"s"),
                                         (3,3),      (1,3), (1,"s"),
                                         (3,"frs"),
                                         (3,"frs"),

             ] },

           # INDEX 7
           # Variation of 6
           7 : { "store_order": [1,0,3,2],
                 "schedule": [

                 (0,0),                              (2,-2),
                 (0,0),                              (2,"sl"),
                         (0,"l"),
                         (0,1),                      (2,-2),
                         (0,1),                      (2,"sl"),
                                 (1,"lrs"),
                                 (1,"lrs"),
                                 (1,"l"),
                                 (1,0),              (2,-1),
                                 (1,0),              (2,"sl"),
                                         (1,"l"),
                                         (1,1),      (2,-1),
                                         (1,1),      (2,"sl"),
                 (2,"lrs"),
                 (2,"lrs"),
                 (0,0),                              (3,-2),
                 (2,0),                              (3,"sl"),
                         (2,"l"),
                         (0,1),                      (3,-2),
                         (2,1),                      (3,"sl"),
                                 (3,"lrs"),
                                 (3,"lrs"),
                                 (1,0),              (3,-1),
                                 (3,0),              (3,"sl"),
                                         (3,"l"),
                                         (1,1),      (3,-1),
                                         (3,1),      (3,"sl"), (0,"l"),

                 (2,"l"),
                 (2,0),                              (0,0), (0,"l"),
                 (2,1),                              (0,0),
                         (2,"l"),
                         (2,0),                      (0,1), (1,"l"),
                         (2,1),                      (0,1),
                                 (3,"l"),
                                 (3,0),              (1,0), (1,"l"),
                                 (3,1),              (1,0),
                                         (3,"l"),
                                         (3,0),
                                         (3,1),      (1,1),

                 (0,2),                              (1,1),
                 (0,2),
                         (0,3),                      (2,0),
                         (0,3),                      (2,0),
                         (0,"frs"),
                         (0,"frs"),
                                 (1,2),              (2,1),
                                 (1,2),              (2,1),
                                         (1,3),      (3,0),
                                         (1,3),      (3,0),
                                         (1,"frs"),
                                         (1,"frs"),
                 (0,2),                              (3,1), (3,"le"),
                 (2,2),                              (3,1),
                         (0,3),                      (2,"le"),
                         (2,3),                      (0,2), # This isn't ready yet, but at least
                                                            # we keep the balance of mul/add/str
                                                            # instructions and don't have a
                                                            # bottleneck at the end
                                 (1,2),              (0,"le"),
                                 (3,2),              (0,2), (0,"s"),
                                         (1,3),      (0,"lres"), (0,"lres"),
                                         (3,3),      (0,3), (0,"s"),

                 (2,2),                              (0,3),
                 (2,3),                              (0,"s"),
                         (2,2),                      (1,2),
                         (2,3),                      (0,"s"),
                         (2,"frs"),
                         (2,"frs"),
                                 (3,2),              (1,"s"),
                                 (3,3),              (1,2), (1,"s"),
                                         (3,2),      (1,3), (1,"s"),
                                         (3,3),      (1,3), (1,"s"),
                                         (3,"frs"),
                                         (3,"frs"),

             ] },

           # INDEX 8
           # Variation of 7, experimentally removing consecutive loads
           8 : { "store_order": [1,0,3,2],
                 "schedule":
                 [

                 (0,0),                              (2,-2),
                 (0,0),                              (2,"sl"),
                         (0,"l"),
                         (0,1),                      (2,-2), (1,"lrs"),
                         (0,1),                      (2,"sl"),
                                 (1,"lrs"),
                                 (1,"l"),
                                 (1,0),              (2,-1),
                                 (1,0),              (2,"sl"),
                                         (1,"l"),
                                         (1,1),      (2,-1),
                                         (1,1),      (2,"sl"),
                 (2,"lrs"),
                 (0,0),                              (3,-2), (2,"lrs"),
                 (2,0),                              (3,"sl"),
                         (2,"l"),
                         (0,1),                      (3,-2),
                         (2,1),                      (3,"sl"),
                                 (3,"lrs"),
                                 (1,0),              (3,-1), (3,"lrs"),
                                 (3,0),              (3,"sl"),
                                         (3,"l"),
                                         (1,1),      (3,-1),
                                         (3,1),      (3,"sl"), (0,"l"),

                 (2,"l"),
                 (2,0),                              (0,0), (0,"l"),
                 (2,1),                              (0,0),
                         (2,"l"),
                         (2,0),                      (0,1), (1,"l"),
                         (2,1),                      (0,1),
                                 (3,"l"),
                                 (3,0),              (1,0), (1,"l"),
                                 (3,1),              (1,0),
                                         (3,"l"),
                                         (3,0),
                                         (3,1),      (1,1),

                 (0,2),                              (1,1),
                 (0,2),
                         (0,3),                      (2,0),
                         (0,3),                      (2,0),
                         (0,"frs"),
                         (0,"frs"),
                                 (1,2),              (2,1),
                                 (1,2),              (2,1),
                                         (1,3),      (3,0),
                                         (1,3),      (3,0),
                                         (1,"frs"),
                                         (1,"frs"),
                 (0,2),                              (3,1), (3,"le"),
                 (2,2),                              (3,1),
                         (0,3),                      (2,"le"),
                         (2,3),                      (0,2), # This isn't ready yet, but at least
                                                            # we keep the balance of mul/add/str
                                                            # instructions and don't have a
                                                            # bottleneck at the end
                                 (1,2),              (0,"le"),
                                 (3,2),              (0,2), (0,"s"),
                                         (1,3),      (0,"lres"),
                                         (3,3),      (0,3), (0,"s"),

                 (2,2),                              (0,3), (0,"lres"),
                 (2,3),                              (0,"s"),
                         (2,2),                      (1,2),
                         (2,3),                      (0,"s"),
                         (2,"frs"),
                         (2,"frs"),
                                 (3,2),              (1,"s"),
                                 (3,3),              (1,2), (1,"s"),
                                         (3,2),      (1,3), (1,"s"),
                                         (3,3),      (1,3), (1,"s"),
                                         (3,"frs"),
                                         (3,"frs"),

             ] },

           # INDEX 9
           9 : { "store_order": [1,0,3,2],
                 "schedule": [

                 (0,0),                              (2,-2),
                 (0,0),                              (2,"sl"),
                         (0,"l"),
                         (0,1),                      (2,-2),
                         (0,1),                      (2,"sl"),
                                 (1,"lrs"),
                                 (1,"lrs"),
                                 (1,"l"),
                                 (1,0),              (2,-1),
                                 (1,0),              (2,"sl"),
                                         (1,"l"),
                                         (1,1),      (2,-1),
                                         (1,1),      (2,"sl"),
                 (2,"lrs"),
                 (2,"lrs"),
                 (0,0),                              (3,-2),
                 (2,0),                              (3,"sl"),
                         (2,"l"),
                         (0,1),                      (3,-2),
                         (2,1),                      (3,"sl"),
                                 (3,"lrs"),
                                 (3,"lrs"),
                                 (1,0),              (3,-1),
                                 (3,0),              (3,"sl"),
                                         (3,"l"),
                                         (1,1),      (3,-1),
                                         (3,1),      (3,"sl"), (0,"l"),

                 (2,"l"),
                 (2,0),                              (0,0), (0,"l"),
                 (2,1),                              (0,0),
                         (2,"l"),
                         (2,0),                      (0,1), (1,"l"),
                         (2,1),                      (0,1),
                                 (3,"l"),
                                 (3,0),              (1,0), (1,"l"),
                                 (3,1),              (1,0),
                                         (3,"l"),
                                         (3,0),      "nop",
                                         (3,1),      (1,1),

                 (0,2),                              (1,1),
                 (0,2),                              "nop",
                         (0,3),                      (2,0),
                         (0,3),                      (2,0),
                         (0,"frs"),
                         (0,"frs"),
                                 (1,2),              (2,1),
                                 (1,2),              (2,1),
                                         (1,3),      (3,0),
                                         (1,3),      (3,0),
                                         (1,"frs"),
                                         (1,"frs"),
                 (0,2),                              (3,1), (3,"le"),
                 (2,2),                              (3,1),
                         (0,3),                      (2,"le"),
                         (2,3),                      (0,2), # This isn't ready yet, but at least
                                                            # we keep the balance of mul/add/str
                                                            # instructions and don't have a
                                                            # bottleneck at the end
                                 (1,2),              (0,"le"),
                                 (3,2),              (0,2), (0,"s"),
                                         (1,3),      (0,"lres"), (0,"lres"),
                                         (3,3),      (0,3), (0,"s"),

                 (2,2),                              (0,3),
                 (2,3),                              (0,"s"),
                         (2,2),                      (1,2),
                         (2,3),                      (0,"s"),
                         (2,"frs"),
                         (2,"frs"),
                                 (3,2),              (1,"s"),
                                 (3,3),              (1,2), (1,"s"),
                                         (3,2),      (1,3), (1,"s"),
                                         (3,3),      (1,3), (1,"s"),
                                         (3,"frs"),
                                         (3,"frs"),

             ] },

           # INDEX 10
           # Based on 7, pairing mul ops, making sure we never have two add/sub/str
           # between blocks of two muls
           10 : { "store_order": [1,0,3,2],
                  "schedule":
             [
                 (0,0), (0,0),                         (1,-1),                  (0,"l"),
                                                       (1,"sl"),                (1,"lrs"),

                         (0,1),  (0,1),                (2,-2),                  (1,"lrs"),
                                                       (2,"sl"),                (1,"l"),
                                 (1,0), (1,0),         (2,-2),
                                                       (2,"sl"),                (1,"l"),

                                         (1,1), (1,1), (2,-1),                  (2,"lrs"),
                                                       (2,"sl"),                (2,"lrs"),
                 (0,0), (2,0),                         (2,-1),                  (2,"l"),
                                                       (2,"sl"),
                         (0,1), (2,1),                 (3,-2),                  (3,"lrs"),
                                                       (3,"sl"),                (3,"lrs"),
                                 (1,0), (3,0),         (3,-2),
                                                       (3,"sl"),                (3,"l"),
                                         (1,1), (3,1), (3,-1),                  (0,"l"),
                                                       (3,"sl"),

                 (2,"l"),
                 (2,0), (2,1),                         (3,-1),                  (0,"l"),
                                                       (3,"sl"),                (2,"l"),
                         (2,0), (2,1),                 (0,0),                   (1,"l"),
                                                       (0,0),                   (3,"l"),
                                 (3,0), (3,1),         (0,1),                   (1,"l"),
                                                       (0,1),                   (3,"l"),
                                         (3,0), (3,1), (1,0),
                                                       (1,0),

                 (0,2), (0,2),                         (1,1),
                                                       (1,1),
                         (0,3), (0,3),                 (2,0),                   (0,"frs"),
                                                       (2,0),                   (0,"frs"),
                                 (1,2), (1,2),         (2,1),
                                                       (2,1),
                                         (1,3), (1,3), (3,0),                   (1,"frs"),
                                                       (3,0),                   (1,"frs"),

                 (0,2), (2,2),                         (3,1),                   (3,"le"),
                                                       (3,1),
                         (0,3), (2,3),                 (0,2),                   (2,"le"),
                                                       (0,"s"),
                                 (1,2), (3,2),         (0,2),                   (0,"le"),
                                                       (0,"s"),
                                         (1,3), (3,3), (0,3),                   (0,"lres"),
                                                       (0,"s"),

                 (2,2), (2,3),                         (0,3),
                                                       (0,"s"),                 (0,"lres"),
                         (2,2), (2,3),                 (1,2),                   (2,"frs"),
                                                       (1,"s"),                 (2,"frs"),
                                 (3,2), (3,3),         (1,2),
                                                       (1,"s"),
                                         (3,2), (3,3), (1,3),                   (3,"frs"),
                                                       (1,"s"),                 (3,"frs"),

             ] },

           # INDEX 11
           # Based on 10, trying to find a better spacing for LDRs
           # Note: - #LDRs per iteration is 4*(4+2)=24
           #       - _Exactly_ matches the number of cycles spent on multiplications
           #       - So we can arrange code in a way that every mul-block has precisely
           #         one LDR in it. That's what we're experimenting with here...
           11 : { "store_order": [1,0,3,2],
                  "schedule":
             [
                 (0,0), (0,0),                         (1,-1),                  (3,"l"),
                                                       (1,"sl"),
                         (0,1),  (0,1),                (2,-2),                  (3,"l"),
                                                       (2,"sl"),
                                 (1,0), (1,0),         (2,-2),                  (2,"lrs"),
                                                       (2,"sl"),
                                         (1,1), (1,1), (2,-1),                  (2,"lrs"),
                                                       (2,"sl"),
                 (0,0), (2,0),                         (2,-1),                  (3,"lrs"),
                                                       (2,"sl"),
                         (0,1), (2,1),                 (3,-2),                  (3,"lrs"),
                                                       (3,"sl"),
                                 (1,0), (3,0),         (3,-2),                  (0,"l"),
                                                       (3,"sl"),
                                         (1,1), (3,1), (3,-1),                  (0,"l"),
                                                       (3,"sl"),
                 (2,0), (2,1),                         (3,-1),                  (1,"l"),
                                                       (3,"sl"),
                         (2,0), (2,1),                 (0,0),                   (1,"l"),
                                                       (0,0),
                                 (3,0), (3,1),         (0,1),                   (2,"l"),
                                                       (0,1),
                                         (3,0), (3,1), (1,0),                   (2,"l"),
                                                       (1,0),

                 (0,2), (0,2),                         (1,1),                   (3,"l"),
                                                       (1,1),
                         (0,3), (0,3),                 (2,0),                   (3,"l"),    (0,"frs"),
                                                       (2,0),                               (0,"frs"),
                                 (1,2), (1,2),         (2,1),                   (0,"le"),
                                                       (2,1),
                                         (1,3), (1,3), (3,0),                   (0,"le"),   (1,"frs"),
                                                       (3,0),                               (1,"frs"),

                 (0,2), (2,2),                         (3,1),                   (1,"le"),
                                                       (3,1),
                         (0,3), (2,3),                 (0,2),                   (1,"le"),
                                                       (0,"s"),
                                 (1,2), (3,2),         (0,2),                   (0,"lres"),
                                                       (0,"s"),
                                         (1,3), (3,3), (0,3),                   (0,"lres"),
                                                       (0,"s"),

                 (2,2), (2,3),                         (0,3),                   (1,"lres"),
                                                       (0,"s"),
                         (2,2), (2,3),                 (1,2),                   (1,"lres"), (2,"frs"),
                                                       (1,"s"),                             (2,"frs"),
                                 (3,2), (3,3),         (1,2),                   (2,"le"),
                                                       (1,"s"),
                                         (3,2), (3,3), (1,3),                   (2,"le"),   (3,"frs"),
                                                       (1,"s"),                             (3,"frs"),

             ] },

           # INDEX 12
           # Based on 11, but using a different load/store order
           12 : { "load_order":  [3,2,1,0],
                  "store_order": [3,2,1,0],
                  "numbering": list(zip(
                      [1,0,2,0],
                      [3,2,3,1],
                      [0,0,2,1])),
                  "schedule":
             [
                 (0,0), (0,0),                         (1,-1),                  (3,"l"),
                                                       (1,"sl"),
                         (0,1),  (0,1),                (2,-2),                  (3,"l"),
                                                       (2,"sl"),
                                 (1,0), (1,0),         (2,-2),                  (2,"lrs"),
                                                       (2,"sl"),
                                         (1,1), (1,1), (2,-1),                  (2,"lrs"),
                                                       (2,"sl"),
                 (0,0), (2,0),                         (2,-1),                  (3,"lrs"),
                                                       (2,"sl"),
                         (0,1), (2,1),                 (3,-2),                  (3,"lrs"),
                                                       (3,"sl"),
                                 (1,0), (3,0),         (3,-2),                  (0,"l"),
                                                       (3,"sl"),
                                         (1,1), (3,1), (3,-1),                  (0,"l"),
                                                       (3,"sl"),
                 (2,0), (2,1),                         (3,-1),                  (1,"l"),
                                                       (3,"sl"),
                         (2,0), (2,1),                 (0,0),                   (1,"l"),
                                                       (0,0),
                                 (3,0), (3,1),         (0,1),                   (2,"l"),
                                                       (0,1),
                                         (3,0), (3,1), (1,0),                   (2,"l"),
                                                       (1,0),

                 (0,2), (0,2),                         (1,1),                   (3,"l"),
                                                       (1,1),
                         (0,3), (0,3),                 (2,0),                   (3,"l"),    (0,"frs"),
                                                       (2,0),                               (0,"frs"),
                                 (1,2), (1,2),         (2,1),                   (0,"le"),
                                                       (2,1),
                                         (1,3), (1,3), (3,0),                   (0,"le"),   (1,"frs"),
                                                       (3,0),                               (1,"frs"),

                 (0,2), (2,2),                         (3,1),                   (1,"le"),
                                                       (3,1),
                         (0,3), (2,3),                 (0,2),                   (1,"le"),
                                                       (0,"s"),
                                 (1,2), (3,2),         (0,2),                   (0,"lres"),
                                                       (0,"s"),
                                         (1,3), (3,3), (0,3),                   (0,"lres"),
                                                       (0,"s"),

                 (2,2), (2,3),                         (0,3),                   (1,"lres"),
                                                       (0,"s"),
                         (2,2), (2,3),                 (1,2),                   (1,"lres"), (2,"frs"),
                                                       (1,"s"),                             (2,"frs"),
                                 (3,2), (3,3),         (1,2),                   (2,"le"),
                                                       (1,"s"),
                                         (3,2), (3,3), (1,3),                   (2,"le"),   (3,"frs"),
                                                       (1,"s"),                             (3,"frs"),

             ] },

           # INDEX 13
           # Based on 11, shifting the whole add/sub/store block up by two places
           13 : { "store_order": [1,0,3,2],
                  "schedule":
             [
                 (0,0), (0,0),                          (2,-2),                 (3,"l"),
                                                        (2,"sl"),
                         (0,1),  (0,1),                 (2,-2),                 (3,"l"),
                                                        (2,"sl"),
                                 (1,0), (1,0),          (2,-1),                 (2,"lrs"),
                                                        (2,"sl"),
                                         (1,1), (1,1),  (2,-1),                 (2,"lrs"),
                                                        (2,"sl"),

                 (0,0), (2,0),                          (3,-2),                 (3,"lrs"),
                                                        (3,"sl"),
                         (0,1), (2,1),                  (3,-2),                 (3,"lrs"),
                                                        (3,"sl"),
                                 (1,0), (3,0),          (3,-1),                 (0,"l"),
                                                        (3,"sl"),
                                         (1,1), (3,1),  (3,-1),                 (0,"l"),
                                                        (3,"sl"),

                 (2,0), (2,1),                          (0,0),                  (1,"l"),
                                                        (0,0),
                         (2,0), (2,1),                  (0,1),                  (1,"l"),
                                                        (0,1),
                                 (3,0), (3,1),          (1,0),                  (2,"l"),
                                                        (1,0),
                                         (3,0), (3,1),  (1,1),                  (2,"l"),
                                                        (1,1),

                 (0,2), (0,2),                          (2,0),                  (3,"l"),
                                                        (2,0),
                         (0,3), (0,3),                  (2,1),                  (3,"l"),    (0,"frs"),
                                                        (2,1),                              (0,"frs"),
                                 (1,2), (1,2),          (3,0),                  (0,"le"),
                                                        (3,0),
                                         (1,3), (1,3),  (3,1),                  (0,"le"),   (1,"frs"),
                                                        (3,1),                              (1,"frs"),

                 (0,2), (2,2),                          (0,2),                  (1,"le"),
                                                        (0,"s"),
                         (0,3), (2,3),                  (0,2),                  (1,"le"),
                                                        (0,"s"),
                                 (1,2), (3,2),          (0,3),                  (0,"lres"),
                                                        (0,"s"),
                                         (1,3), (3,3),  (0,3),                  (0,"lres"),
                                                        (0,"s"),

                 (2,2), (2,3),                          (1,2),                  (1,"lres"),
                                                        (1,"s"),
                         (2,2), (2,3),                  (1,2),                  (1,"lres"), (2,"frs"),
                                                        (1,"s"),                            (2,"frs"),
                                 (3,2), (3,3),          (1,3),                  (2,"le"),
                                                        (1,"s"),
                                         (3,2), (3,3),  (1,3),                  (2,"le"),   (3,"frs"),
                                                        (1,"s"),                            (3,"frs"),

             ] },

           # INDEX 14
           # Merge of 12+13: Shifted add/sub/str's and modified load/store order
           14 : { "load_order":  [3,2,1,0],
                  "store_order": [3,2,1,0],
                  "numbering": list(zip(
                      [1,0,2,0],
                      [3,2,3,1],
                      [0,0,2,1])),
                  "schedule":
             [
                 (0,0), (0,0),                          (2,-2),                 (3,"l"),
                                                        (2,"sl"),
                         (0,1),  (0,1),                 (2,-2),                 (3,"l"),
                                                        (2,"sl"),
                                 (1,0), (1,0),          (2,-1),                 (2,"lrs"),
                                                        (2,"sl"),
                                         (1,1), (1,1),  (2,-1),                 (2,"lrs"),
                                                        (2,"sl"),

                 (0,0), (2,0),                          (3,-2),                 (3,"lrs"),
                                                        (3,"sl"),
                         (0,1), (2,1),                  (3,-2),                 (3,"lrs"),
                                                        (3,"sl"),
                                 (1,0), (3,0),          (3,-1),                 (0,"l"),
                                                        (3,"sl"),
                                         (1,1), (3,1),  (3,-1),                 (0,"l"),
                                                        (3,"sl"),

                 (2,0), (2,1),                          (0,0),                  (1,"l"),
                                                        (0,0),
                         (2,0), (2,1),                  (0,1),                  (1,"l"),
                                                        (0,1),
                                 (3,0), (3,1),          (1,0),                  (2,"l"),
                                                        (1,0),
                                         (3,0), (3,1),  (1,1),                  (2,"l"),
                                                        (1,1),

                 (0,2), (0,2),                          (2,0),                  (3,"l"),
                                                        (2,0),
                         (0,3), (0,3),                  (2,1),                  (3,"l"),    (0,"frs"),
                                                        (2,1),                              (0,"frs"),
                                 (1,2), (1,2),          (3,0),                  (0,"le"),
                                                        (3,0),
                                         (1,3), (1,3),  (3,1),                  (0,"le"),   (1,"frs"),
                                                        (3,1),                              (1,"frs"),

                 (0,2), (2,2),                          (0,2),                  (1,"le"),
                                                        (0,"s"),
                         (0,3), (2,3),                  (0,2),                  (1,"le"),
                                                        (0,"s"),
                                 (1,2), (3,2),          (0,3),                  (0,"lres"),
                                                        (0,"s"),
                                         (1,3), (3,3),  (0,3),                  (0,"lres"),
                                                        (0,"s"),

                 (2,2), (2,3),                          (1,2),                  (1,"lres"),
                                                        (1,"s"),
                         (2,2), (2,3),                  (1,2),                  (1,"lres"), (2,"frs"),
                                                        (1,"s"),                            (2,"frs"),
                                 (3,2), (3,3),          (1,3),                  (2,"le"),
                                                        (1,"s"),
                                         (3,2), (3,3),  (1,3),                  (2,"le"),   (3,"frs"),
                                                        (1,"s"),                            (3,"frs"),

             ] },

           # INDEX 15
           # Based on 11, moving add/sub/str's down by two places, and changing load/store order
           # Moving down the add/sub/str's reduces pressure on the corresponding SIMD unit because
           # the last add/sub/str's are farther away from their producers.
           15 : { "load_order":  [3,2,1,0],
                  "store_order": [3,2,1,0],
                  "numbering": list(zip(
                      [1,0,2,0],
                      [3,2,3,1],
                      [0,0,2,1])),
                  "schedule":
             [
                 (0,0), (0,0),                         (1,-1),         (3,"l"),
                                                       (1,"sl"),
                         (0,1),  (0,1),                (1,-1),         (3,"l"),
                                                       (1,"sl"),
                                 (1,0), (1,0),         (2,-2),         (2,"lrs"),
                                                       (2,"sl"),
                                         (1,1), (1,1), (2,-2),         (2,"lrs"),
                                                       (2,"sl"),
                 (0,0), (2,0),                         (2,-1),         (3,"lrs"),
                                                       (2,"sl"),
                         (0,1), (2,1),                 (2,-1),         (3,"lrs"),
                                                       (2,"sl"),
                                 (1,0), (3,0),         (3,-2),         (0,"l"),
                                                       (3,"sl"),
                                         (1,1), (3,1), (3,-2),         (0,"l"),
                                                       (3,"sl"),
                 (2,0), (2,1),                         (3,-1),         (1,"l"),
                                                       (3,"sl"),
                         (2,0), (2,1),                 (3,-1),         (1,"l"),
                                                       (3,"sl"),
                                 (3,0), (3,1),         (0,0),          (2,"l"),
                                                       (0,0),
                                         (3,0), (3,1), (0,1),          (2,"l"),
                                                       (0,1),
                 (0,2), (0,2),                         (1,0),          (3,"l"),
                                                       (1,0),
                         (0,3), (0,3),                 (1,1),          (3,"l"),             (0,"frs"),
                                                       (1,1),                               (0,"frs"),
                                 (1,2), (1,2),         (2,0),          (0,"le"),
                                                       (2,0),
                                         (1,3), (1,3), (2,1),          (0,"le"),            (1,"frs"),
                                                       (2,1),                               (1,"frs"),
                 (0,2), (2,2),                         (3,0),          (1,"le"),
                                                       (3,0),
                         (0,3), (2,3),                 (3,1),          (1,"le"),
                                                       (3,1),
                                 (1,2), (3,2),         (0,2),          (0,"lres"),
                                                       (0,"s"),
                                         (1,3), (3,3), (0,2),          (0,"lres"),
                                                       (0,"s"),
                 (2,2), (2,3),                         (0,3),          (1,"lres"),
                                                       (0,"s"),
                         (2,2), (2,3),                 (0,3),          (1,"lres"),          (2,"frs"),
                                                       (0,"s"),                             (2,"frs"),
                                 (3,2), (3,3),         (1,2),          (2,"le"),
                                                       (1,"s"),
                                         (3,2), (3,3), (1,2),          (2,"le"),            (3,"frs"),
                                                       (1,"s"),                             (3,"frs"),

             ] },

           # INDEX 16
           # Deliberately bad, bunch lots of MULs
           16 : { "schedule":
             [ (0, "m"), (0, "l"), (0, "l"), (0, "l"), (0, "l"), (0,"lre"),
             (0, 0), (0, 0), (0, 0),
             (0, 1), (0, 1), (0, 1),
             (0, 0), (0, 0),
             (0, 1), (0, 1),
             (0, 2), (0, 2), (0, 2),
             (0, 3), (0, 3), (0, 3),
             (0, 2), (0, 2),
             (0, 3), (0, 3),
             (0,"s"), (0,"s"), (0,"s"), (0,"s"), (0,"frl"),

             (1, "m"), (1, "l"), (1, "l"), (1, "l"), (1, "l"), (1,"lre"),
             (1, 0), (1, 0), (1, 0),
             (1, 1), (1, 1), (1, 1),
             (1, 0), (1, 0),
             (1, 1), (1, 1),
             (1, 2), (1, 2), (1, 2),
             (1, 3), (1, 3), (1, 3),
             (1, 2), (1, 2),
             (1, 3), (1, 3),
             (1,"s"), (1,"s"), (1,"s"), (1,"s"), (1,"frl"),

             (2, "m"), (2, "l"), (2, "l"), (2, "l"), (2, "l"), (2,"lre"),
             (2, 0), (2, 0), (2, 0),
             (2, 1), (2, 1), (2, 1),
             (2, 0), (2, 0),
             (2, 1), (2, 1),
             (2, 2), (2, 2), (2, 2),
             (2, 3), (2, 3), (2, 3),
             (2, 2), (2, 2),
             (2, 3), (2, 3),
             (2,"s"), (2,"s"), (2,"s"), (2,"s"), (2,"frl"),

             (3, "m"), (3, "l"), (3, "l"), (3, "l"), (3, "l"), (3,"lre"),
             (3, 0), (3, 0), (3, 0),
             (3, 1), (3, 1), (3, 1),
             (3, 0), (3, 0),
             (3, 1), (3, 1),
             (3, 2), (3, 2), (3, 2),
             (3, 3), (3, 3), (3, 3),
             (3, 2), (3, 2),
             (3, 3), (3, 3),
             (3,"s"), (3,"s"), (3,"s"), (3,"s"), (3,"frl") ] },
        }

        modification = modifications[idx]

        for k,v in modification.items():
            if not k in default.keys():
                raise Exception(f"Invalid modification: {k}")

        dic = { **default, **modification }

        dic["load_order_first"] = dic.get("load_order_first", dic["load_order"])
        dic["store_order_last"] = dic.get("store_order_last", dic["store_order"])

        return dic

    def get_schedule_double_no_transpose(self, idx):

        load_order_default           = [2,3,0,1]
        store_order_default          = [0,1,2,3]
        butterfly_numbering_default  = list(zip([0,1,0,2],
                                                [2,3,1,3],
                                                [0,0,1,2]))
        twiddle_numbering_default    = { 0: (0,0),
                                         1: (0,1),
                                         2: (0,2) }
        root_load_order_default = list(range(0,10)) # Identity

        schedules = [

           # INDEX 0
           # Trivial implementation, no interleaving whatsoever
           (None, None, None, None, None,
            ["m", "frl",
             "l", "l", "l", "l",
             0, 0, 0, 0, 0,
             1, 1, 1, 1, 1, "lre",
             2, 2, 2, 2, 2,
             3, 3, 3, 3, 3, "s", "s", "s", "s" ])
        ]

        load_order, store_order, numbering, twiddles, root_order, schedule = schedules[idx]

        if load_order == None:
            load_order = load_order_default
        if store_order == None:
            store_order = store_order_default
        if numbering == None:
            numbering = butterfly_numbering_default
        if twiddles == None:
            twiddles = twiddle_numbering_default
        if root_order == None:
            root_order = root_load_order_default

        return load_order, store_order, numbering, twiddles, root_order, schedule

    def get_schedule_quad_transpose(self, idx):

        load_order_default           = [2,3,0,1]
        store_order_default          = [0,1,2,3]
        butterfly_numbering_default  = \
            list(zip([0,1,0,2, 0,1,0,2],
                     [2,3,1,3, 2,3,1,3],
                     [0,0,1,2, 3,3,4,5]))
        twiddle_numbering_default    = { 0: (0,0),
                                         1: (0,1),
                                         2: (0,2),
                                         3: (1,None),
                                         4: (2,None),
                                         5: (3,None) }
        root_load_order_default = list(range(0,10)) # Identity

        schedules = [

           # INDEX 0
           # Trivial implementation, no interleaving whatsoever
           ( None, None, None, None, None, # All defaults
             ["m", "frl", "l", "l", "l", "l",
              0, 0, 0, 0, 0,
              1, 1, 1, 1, 1,
              2, 2, 2, 2, 2,
              3, 3, 3, 3, 3,
              "t",
              4, 4, 4, 4, 4,
              5, 5, 5, 5, 5,
              6, 6, 6, 6, 6,
              7, 7, 7, 7, 7,
              "s", "s", "s", "s", "lre" ] )
        ]

        load_order, store_order, numbering, twiddles, root_order, schedule = schedules[idx]

        if load_order == None:
            load_order = load_order_default
        if store_order == None:
            store_order = store_order_default
        if numbering == None:
            numbering = butterfly_numbering_default
        if twiddles == None:
            twiddles = twiddle_numbering_default
        if root_order == None:
            root_order = root_load_order_default

        return load_order, store_order, numbering, twiddles, root_order, schedule

    def get_schedule_quad_transpose_zipped(self, idx):

        load_order_default           = [2,3,0,1]
        store_order_default          = [0,1,2,3]
        butterfly_numbering_default  = \
            list(zip([0,1,0,2, 0,1,0,2],
                     [2,3,1,3, 2,3,1,3],
                     [0,0,1,2, 3,3,4,5]))
        twiddle_numbering_default    = { 0: (0,0),
                                         1: (0,1),
                                         2: (0,2),
                                         3: (1,None),
                                         4: (2,None),
                                         5: (3,None) }
        root_load_order_default = list(range(0,10)) # Identity

        schedules = [

           # INDEX 0
           # Trivial implementation, no interleaving whatsoever
           ( None, None, None, None, None, # All defaults
             [(0,"m"), (0,"lr"), (0,"l"), (0,"l"), (0,"l"), (0,"l"),
            (0, 0), (0, 0), (0, 0), (0, 0), (0, 0),
            (0, 1), (0, 1), (0, 1), (0, 1), (0, 1),
            (0, 2), (0, 2), (0, 2), (0, 2), (0, 2),
            (0, 3), (0, 3), (0, 3), (0, 3), (0, 3),
            (0, "t"),
            (0, 4), (0, 4), (0, 4), (0, 4), (0, 4),
            (0, 5), (0, 5), (0, 5), (0, 5), (0, 5),
            (0, 6), (0, 6), (0, 6), (0, 6), (0, 6),
            (0, 7), (0, 7), (0, 7), (0, 7), (0, 7),
            (0, "s"), (0,"s"), (0,"s"), (0,"s"), (0,"fr"),

            (1,"m"), (1,"lr"), (1,"l"), (1,"l"), (1,"l"), (1,"l"),
            (1, 0), (1, 0), (1, 0), (1, 0), (1, 0),
            (1, 1), (1, 1), (1, 1), (1, 1), (1, 1),
            (1, 2), (1, 2), (1, 2), (1, 2), (1, 2),
            (1, 3), (1, 3), (1, 3), (1, 3), (1, 3),
            (1, "t"),
            (1, 4), (1, 4), (1, 4), (1, 4), (1, 4),
            (1, 5), (1, 5), (1, 5), (1, 5), (1, 5),
            (1, 6), (1, 6), (1, 6), (1, 6), (1, 6),
            (1, 7), (1, 7), (1, 7), (1, 7), (1, 7),
            (1, "s"), (1,"s"), (1,"s"), (1,"s"), (1,"fr")] ),

           # INDEX 1
           # Zipped together two trivial implementations
           ( None, None, None, None, None, # All defaults
             [(0,"m"), (0,"lr"), (0,"l"), (0,"l"), (0,"l"), (0,"l"),
            (1,"m"), (1,"lr"), (1,"l"), (1,"l"), (1,"l"), (1,"l"),

            (0,0),(0,0),(0,0),(0,0),(0,0),
            (1,0),(1,0),(1,0),(1,0),(1,0),

            (0,1),(0,1),(0,1),(0,1),(0,1),
            (1,1),(1,1),(1,1),(1,1),(1,1),

            (0,2),(0,2),(0,2),(0,2),(0,2),
            (1,2),(1,2),(1,2),(1,2),(1,2),

            (0,3),(0,3),(0,3),(0,3),(0,3),
            (1,3),(1,3),(1,3),(1,3),(1,3),

            (0,"t"),
            (1,"t"),

            (0,4),(0,4),(0,4),(0,4),(0,4),
            (1,4),(1,4),(1,4),(1,4),(1,4),

            (0,5),(0,5),(0,5),(0,5),(0,5),
            (1,5),(1,5),(1,5),(1,5),(1,5),

            (0,6),(0,6),(0,6),(0,6),(0,6),
            (1,6),(1,6),(1,6),(1,6),(1,6),

            (0,7),(0,7),(0,7),(0,7),(0,7),
            (1,7),(1,7),(1,7),(1,7),(1,7),

            (0,"s"),(0,"s"),(0,"s"),(0,"s"),(0,"fr"),
            (1,"s"),(1,"s"),(1,"s"),(1,"s"),(1,"fr")] ),

           # INDEX 2
           # Zipped together slightly different, but still at butterfly granularity
           ( None, None, None, None, None, # All defaults
             [(0,"m"), (0,"lr"), (0,"l"), (0,"l"), (0,"l"), (0,"l"),
            (1,"m"), (1,"lr"), (1,"l"), (1,"l"), (1,"l"), (1,"l"),

            (0,0),(0,0),(0,0),(0,0),(0,0),
            (0,1),(0,1),(0,1),(0,1),(0,1),

            (1,0),(1,0),(1,0),(1,0),(1,0),
            (1,1),(1,1),(1,1),(1,1),(1,1),

            (0,2),(0,2),(0,2),(0,2),(0,2),
            (0,3),(0,3),(0,3),(0,3),(0,3),

            (1,2),(1,2),(1,2),(1,2),(1,2),
            (1,3),(1,3),(1,3),(1,3),(1,3),

            (0,"t"),
            (1,"t"),

            (0,4),(0,4),(0,4),(0,4),(0,4),
            (0,5),(0,5),(0,5),(0,5),(0,5),

            (1,4),(1,4),(1,4),(1,4),(1,4),
            (1,5),(1,5),(1,5),(1,5),(1,5),

            (0,6),(0,6),(0,6),(0,6),(0,6),
            (0,7),(0,7),(0,7),(0,7),(0,7),

            (1,6),(1,6),(1,6),(1,6),(1,6),
            (1,7),(1,7),(1,7),(1,7),(1,7),

            (0,"s"),(0,"s"),(0,"s"),(0,"s"),(0,"fr"),
            (1,"s"),(1,"s"),(1,"s"),(1,"s"),(1,"fr")] ),

           # INDEX 3
           # Interleave some loads
           ( None, None, None, None, None, # All defaults
             [(0,"m"), (0,"lrs"), (0,"lrs"), (0,"l"), (0,"l"),
            (1,"m"), (1,"lrs"), (1,"lrs"),

            (0,0), (1,"l"), (0,0), (1,"l"), (0,0),(0,0),(0,0),
            (0,1), (1,"l"), (0,1), (1,"l"), (0,1),(0,1),(0,1),

            (1,0),(1,0),(1,0),(1,0),(1,0),
            (1,1),(1,1),(1,1),(1,1),(1,1),

            (0,2),(0,2),(0,2),(0,2),(0,2),
            (0,3),(0,3),(0,3),(0,3),(0,3),

            (1,2),(1,2),(1,2),(1,2),(1,2),
            (1,3),(1,3),(1,3),(1,3),(1,3),

            (0,"t"), (0,"lrs"), (0,"lrs"),
            (1,"t"), (1,"lrs"), (1,"lrs"),

            (0,4),(0,4),(0,4),(0,4),(0,4),
            (0,5),(0,5),(0,5),(0,5),(0,5),

            (1,4),(1,4),(1,4),(1,4),(1,4), (0,"lrs"), (0,"lrs"),
            (1,5),(1,5),(1,5),(1,5),(1,5), (0,"lrs"), (0,"lrs"),

            (0,6),(0,6),(0,6),(0,6),(0,6), (1,"lrs"), (1,"lrs"),
            (0,7),(0,7),(0,7),(0,7),(0,7), (1,"lrs"), (1,"lrs"),

            (1,6), (0, "le"), (1,6), (1,6),(1,6),(1,6),
            (1,7), (0, "le"), (1,7), (1,7),(1,7),(1,7),

            (0,"s"),(0,"s"), (0,"s"),(0,"s"), (0,"fr"),
            (1,"s"),(1,"s"),(1,"s"),(1,"s"),(1,"fr")] ),

           # INDEX 4
           # Interleave loads + transposition
           ( None, None, None, None, None, # All defaults
             [(0,"m"), (0,"lrs"), (0,"lrs"), (0,"l"), (0,"l"),
            (1,"m"), (1,"lrs"), (1,"lrs"),

            (0,0), (1,"l"), (0,0), (1,"l"), (0,0),(0,0),(0,0),
            (0,1), (1,"l"), (0,1), (1,"l"), (0,1),(0,1),(0,1),

            (1,0),(1,0),(1,0),(1,0),(1,0),
            (1,1),(1,1),(1,1),(1,1),(1,1),

            (0,2),(0,2),(0,2),(0,2),(0,2),
            (0,3),(0,3),(0,3),(0,3),(0,3),

            (1,2), (1,2), (1,2),
            (1,2), (0,"ts"), (0,"ts"),
            (1,2), (0,"ts"), (0,"ts"),
            (1,3), (0,"lrs"), (1,3), (0,"lrs"),
            (1,3), (0,"ts"), (0,"ts"),
            (1,3), (0,"ts"), (0,"ts"),
            (1,3),


            (0,4), (0,4),
            (0,4), (1, "ts"), (1, "ts"),
            (0,4), (1, "ts"), (1, "ts"),
            (0,4), (1, "ts"), (1, "ts"),
            (0,5), (1, "ts"), (1, "ts"),
            (1,"lrs"), (1,"lrs"), (0,5),(0,5),(0,5),(0,5),

            (1,4),(1,4),(1,4),(1,4),(1,4), (0,"lrs"), (0,"lrs"),
            (1,5),(1,5),(1,5),(1,5),(1,5), (0,"lrs"), (0,"lrs"),

            (0,6),(0,6),(0,6),(0,6),(0,6), (1,"lrs"), (1,"lrs"),
            (0,7),(0,7),(0,7),(0,7),(0,7), (1,"lrs"), (1,"lrs"),

            (1,6), (0, "le"), (1,6), (1,6),(1,6),(1,6),
            (1,7), (0, "le"), (1,7), (1,7),(1,7),(1,7),

            (0,"s"),(0,"s"), (0,"s"),(0,"s"), (0,"fr"),
              (1,"s"),(1,"s"),(1,"s"),(1,"s"),(1,"fr")] ),

           # INDEX 5
           # Interleave arithmetic only
           ( None, None, None, None, None, # All defaults
             [(0,"m"), (0,"lrs"), (0,"lrs"), (0,"l"), (0,"l"),
            (1,"m"), (1,"lrs"), (1,"lrs"),

            (0,0), (1,"l"), (0,0), (1,"l"),
            (0,1), (1,"l"), (0,1), (1,"l"), (0,0),
            (1,0),          (1,0),          (0,1), (0,0), (0,0),
            (1,1),          (1,1),          (1,0), (0,1), (0,1),
            (0,2),          (0,2),          (1,1), (1,0), (1,0),
            (0,3),          (0,3),          (0,2), (1,1), (1,1),
            (1,2),          (1,2),          (0,3), (0,2), (0,2),
            (1,3),          (1,3),          (1,2), (0,3), (0,3),
            (0, "t"), (0, "lrs"), (0, "lrs"),
            (0,4),          (0,4),          (1,3), (1,2), (1,2),
            (0,5),          (0,5),          (0,4), (1,3), (1,3),
            (1, "t"), (1, "lrs"), (1, "lrs"),
            (1,4),
            (0,"lrs"), (0,"lrs"),
                            (1,4),          (0,5), (0,4), (0,4),
            (1,5), (0,"lrs"), (0,"lrs"), (1,5), (1,4), (0,5), (0,5),
            (0,6), (1,"lrs"), (1,"lrs"), (0,6), (1,5), (1,4), (1,4),
            (0,7), (1,"lrs"), (1,"lrs"), (0,7), (0,6), (1,5), (1,5),
            (1,6), (0, "le"), (1,6), (0,7), (0,6), (0,6),
            (1,7), (0, "le"), (1,7), (1,6), (0,7), (0,7),
                                      (1,7), (1,6), (1,6),
                                      (1,7), (1,7),

            (0,"s"),(0,"s"), (0,"s"),(0,"s"), (0,"fr"),
            (1,"s"),(1,"s"),(1,"s"),(1,"s"),(1,"fr")] ),

        ]

        load_order, store_order, numbering, twiddles, root_order, schedule = schedules[idx]

        if load_order == None:
            load_order = load_order_default
        if store_order == None:
            store_order = store_order_default
        if numbering == None:
            numbering = butterfly_numbering_default
        if twiddles == None:
            twiddles = twiddle_numbering_default
        if root_order == None:
            root_order = root_load_order_default

        return load_order, store_order, numbering, twiddles, root_order, schedule

    def get_schedule_quad_transpose_quad_zipped(self, idx):

        load_order_default           = [2,3,0,1]
        store_order_default          = [0,1,2,3]
        butterfly_numbering_default  = \
            list(zip([0,1,0,2, 0,1,0,2],
                     [2,3,1,3, 2,3,1,3],
                     [0,0,1,2, 3,3,4,5]))
        twiddle_numbering_default    = { 0: (0,0),
                                         1: (0,1),
                                         2: (0,2),
                                         3: (1,None),
                                         4: (2,None),
                                         5: (3,None) }
        root_load_order_default = list(range(0,10)) # Identity

        schedules = [

           # INDEX 0
           # Trivial implementation, no interleaving whatsoever
           ( None, None, None, None, None, # All defaults
             [(0,"m"), (0,"lr"), (0,"l"), (0,"l"), (0,"l"), (0,"l"),
            (0, 0), (0, 0), (0, 0), (0, 0), (0, 0),
            (0, 1), (0, 1), (0, 1), (0, 1), (0, 1),
            (0, 2), (0, 2), (0, 2), (0, 2), (0, 2),
            (0, 3), (0, 3), (0, 3), (0, 3), (0, 3),
            (0, "t"),
            (0, 4), (0, 4), (0, 4), (0, 4), (0, 4),
            (0, 5), (0, 5), (0, 5), (0, 5), (0, 5),
            (0, 6), (0, 6), (0, 6), (0, 6), (0, 6),
            (0, 7), (0, 7), (0, 7), (0, 7), (0, 7),
            (0, "s"), (0,"s"), (0,"s"), (0,"s"), (0,"fr"),

            (1,"m"), (1,"lr"), (1,"l"), (1,"l"), (1,"l"), (1,"l"),
            (1, 0), (1, 0), (1, 0), (1, 0), (1, 0),
            (1, 1), (1, 1), (1, 1), (1, 1), (1, 1),
            (1, 2), (1, 2), (1, 2), (1, 2), (1, 2),
            (1, 3), (1, 3), (1, 3), (1, 3), (1, 3),
            (1, "t"),
            (1, 4), (1, 4), (1, 4), (1, 4), (1, 4),
            (1, 5), (1, 5), (1, 5), (1, 5), (1, 5),
            (1, 6), (1, 6), (1, 6), (1, 6), (1, 6),
            (1, 7), (1, 7), (1, 7), (1, 7), (1, 7),
            (1, "s"), (1,"s"), (1,"s"), (1,"s"), (1,"fr"),

            (2,"m"), (2,"lr"), (2,"l"), (2,"l"), (2,"l"), (2,"l"),
            (2, 0), (2, 0), (2, 0), (2, 0), (2, 0),
            (2, 1), (2, 1), (2, 1), (2, 1), (2, 1),
            (2, 2), (2, 2), (2, 2), (2, 2), (2, 2),
            (2, 3), (2, 3), (2, 3), (2, 3), (2, 3),
            (2, "t"),
            (2, 4), (2, 4), (2, 4), (2, 4), (2, 4),
            (2, 5), (2, 5), (2, 5), (2, 5), (2, 5),
            (2, 6), (2, 6), (2, 6), (2, 6), (2, 6),
            (2, 7), (2, 7), (2, 7), (2, 7), (2, 7),
            (2, "s"), (2,"s"), (2,"s"), (2,"s"), (2,"fr"),

            (3,"m"), (3,"lr"), (3,"l"), (3,"l"), (3,"l"), (3,"l"),
            (3, 0), (3, 0), (3, 0), (3, 0), (3, 0),
            (3, 1), (3, 1), (3, 1), (3, 1), (3, 1),
            (3, 2), (3, 2), (3, 2), (3, 2), (3, 2),
            (3, 3), (3, 3), (3, 3), (3, 3), (3, 3),
            (3, "t"),
            (3, 4), (3, 4), (3, 4), (3, 4), (3, 4),
            (3, 5), (3, 5), (3, 5), (3, 5), (3, 5),
            (3, 6), (3, 6), (3, 6), (3, 6), (3, 6),
            (3, 7), (3, 7), (3, 7), (3, 7), (3, 7),
            (3, "s"), (3,"s"), (3,"s"), (3,"s"), (3,"fr")] ),

           # INDEX 1
           # Interleave pre- and post-transpose arithmetic
           ( None, None, None, None, None, # All defaults
             [(0,"m"), (0,"l"), (0,"l"), (0,"l"), (0,"l"),
            (1,"m"), (1,"l"), (1,"l"), (1,"l"), (1,"l"),
            (2,"m"), (2,"l"), (2,"l"), (2,"l"), (2,"l"),
            (3,"m"), (3,"l"), (3,"l"), (3,"l"), (3,"l"),

            (0,"lrs"), (0,"lrs"),
            (1,"lrs"), (1,"lrs"),
            (2,"lrs"), (2,"lrs"),
            (3,"lrs"), (3,"lrs"),

            (0,0), (0,0),
            (0,1), (0,1), (0,0),
            (1,0), (1,0), (0,1), (0,0), (0,0),
            (1,1), (1,1), (1,0), (0,1), (0,1),
            (0,2), (0,2), (1,1), (1,0), (1,0),
            (0,3), (0,3), (0,2), (1,1), (1,1),
            (1,2), (1,2), (0,3), (0,2), (0,2), (0, "frs"), (0, "frs"),
            (1,3), (1,3), (1,2), (0,3), (0,3),
            (2,0), (2,0), (1,3), (1,2), (1,2), (1, "frs"), (1, "frs"),
            (2,1), (2,1), (2,0), (1,3), (1,3),
            (3,0), (3,0), (2,1), (2,0), (2,0),
            (3,1), (3,1), (3,0), (2,1), (2,1),
            (2,2), (2,2), (3,1), (3,0), (3,0),
            (2,3), (2,3), (2,2), (3,1), (3,1),
            (3,2), (3,2), (2,3), (2,2), (2,2), (2, "frs"), (2, "frs"),
            (3,3), (3,3), (3,2), (2,3), (2,3),
                          (3,3), (3,2), (3,2), (3, "frs"), (3, "frs"),
                                 (3,3), (3,3),

            (0, "t"),
            (1, "t"),
            (2, "t"),
            (3, "t"),

            (0, "lrs"), (0, "lrs"),
            (0, 4), (0, 4),
            (0, 5), (0, 5),
            (0, "frs"), (0, "frs"),
                            (0, 4),
            (1, "lrs"), (1, "lrs"),
            (1, 4), (1, 4), (0, 5), (0, 4), (0, 4),
            (1, 5), (1, 5),
            (1, "frs"), (1, "frs"),
                            (1, 4), (0, 5), (0, 5),
            (0, "lrs"), (0, "lrs"),
            (0, 6), (0, 6),
            (0, "frs"), (0, "frs"),
                            (1, 5), (1, 4), (1, 4),
            (0, "lrs"), (0, "lrs"),
            (0, 7), (0, 7),
            (0, "frs"), (0, "frs"),
                            (0, 6), (1, 5), (1, 5),
            (1, "lrs"), (1, "lrs"),
            (1, 6), (1, 6),
            (1, "frs"), (1, "frs"),
                            (0, 7), (0, 6), (0, 6),
            (1, "lrs"), (1, "lrs"),
            (1, 7), (1, 7),
            (1, "frs"), (1, "frs"),
                            (1, 6), (0, 7), (0, 7),
                            (1, 7), (1, 6), (1, 6),
                                    (1, 7), (1, 7),

            (0, "s"), (0,"s"), (0,"s"), (0,"s"),
            (1, "s"), (1,"s"), (1,"s"), (1,"s"),

            (2, "lrs"), (2, "lrs"),
            (2, 4), (2, 4),
            (2, 5), (2, 5),
            (2, "frs"), (2, "frs"),
                            (2, 4),
            (3, "lrs"), (3, "lrs"),
            (3, 4), (3, 4), (2, 5), (2, 4), (2, 4),
            (3, 5), (3, 5),
            (3, "frs"), (3, "frs"),
                            (3, 4), (2, 5), (2, 5),
            (2, "lrs"), (2, "lrs"),
            (2, 6), (2, 6),
            (2, "frs"), (2, "frs"),
                            (3, 5), (3, 4), (3, 4),
            (2, "lrs"), (2, "lrs"),
            (2, 7), (2, 7),
            (2, "frs"), (2, "frs"),
                            (2, 6), (3, 5), (3, 5),
            (3, "lrs"), (3, "lrs"),
            (3, 6), (3, 6),
            (3, "frs"), (3, "frs"),
                            (2, 7), (2, 6), (2, 6),
            (3, "lrs"), (3, "lrs"),
            (3, 7), (3, 7),
            (3, "frs"), (3, "frs"),
                            (3, 6), (2, 7), (2, 7),
                            (3, 7), (3, 6), (3, 6),
                                    (3, 7), (3, 7),

            (2, "s"), (2,"s"), (2,"s"), (2,"s"),
            (3, "s"), (3,"s"), (3,"s"), (3,"s") ] ),

           # INDEX 2
           # Interleave pre- and post-transpose arithmetic, and transpose
           ( None, None, None, None, None, # All defaults
             [(0,"m"), (0,"l"), (0,"l"), (0,"l"), (0,"l"),
            (1,"m"), (1,"l"), (1,"l"), (1,"l"), (1,"l"),
            (2,"m"), (2,"l"), (2,"l"), (2,"l"), (2,"l"),
            (3,"m"), (3,"l"), (3,"l"), (3,"l"), (3,"l"),

            (0,"lrs"), (0,"lrs"),
            (1,"lrs"), (1,"lrs"),
            (2,"lrs"), (2,"lrs"),
            (3,"lrs"), (3,"lrs"),

            (0,0), (0,0),
            (0,1), (0,1), (0,0),
            (1,0), (1,0), (0,1), (0,0), (0,0),
            (1,1), (1,1), (1,0), (0,1), (0,1),
            (0,2), (0,2), (1,1), (1,0), (1,0),
            (0,3), (0,3), (0,2), (1,1), (1,1),
            (1,2), (1,2), (0,3), (0,2), (0,2), (0, "frs"), (0, "frs"),
            (1,3), (1,3), (1,2), (0,3), (0,3),
            (2,0), (2,0),
            (0, "ts"),
            (0, "ts"),
                          (1,3), (1,2), (1,2), (1, "frs"), (1, "frs"),
            (2,1), (2,1),
            (0, "ts"),
            (0, "ts"),
                          (2,0), (1,3), (1,3),
            (3,0), (3,0),
            (0, "ts"),
            (0, "ts"),
                          (2,1), (2,0), (2,0),
            (3,1), (3,1),
            (0, "ts"),
            (0, "ts"),
                          (3,0), (2,1), (2,1),
            (2,2), (2,2),
            (1, "ts"),
            (1, "ts"),
                          (3,1), (3,0), (3,0),
            (2,3), (2,3),
            (1, "ts"),
            (1, "ts"),
                          (2,2), (3,1), (3,1),
            (3,2), (3,2),
            (1, "ts"),
            (1, "ts"),
                          (2,3), (2,2), (2,2), (2, "frs"), (2, "frs"),
            (3,3), (3,3),
            (1, "ts"),
            (1, "ts"),
                          (3,2), (2,3), (2,3),
                          (3,3), (3,2), (3,2), (3, "frs"), (3, "frs"),
                                 (3,3), (3,3),

            (0, "lrs"), (0, "lrs"),
            (0, 4), (0, 4),
            (2, "ts"),
            (2, "ts"),
            (0, 5), (0, 5),
            (2, "ts"),
            (2, "ts"),
            (0, "frs"), (0, "frs"),
                            (0, 4),
            (1, "lrs"), (1, "lrs"),
            (1, 4), (1, 4),
            (2, "ts"),
            (2, "ts"),
                            (0, 5), (0, 4), (0, 4),
            (1, 5), (1, 5),
            (1, "frs"), (1, "frs"),
            (2, "ts"),
            (2, "ts"),
                            (1, 4), (0, 5), (0, 5),
            (0, "lrs"), (0, "lrs"),
            (0, 6), (0, 6),
            (0, "frs"), (0, "frs"),
            (3, "ts"),
            (3, "ts"),
                            (1, 5), (1, 4), (1, 4),
            (0, "lrs"), (0, "lrs"),
            (0, 7), (0, 7),
            (0, "frs"), (0, "frs"),
            (3, "ts"),
            (3, "ts"),
                            (0, 6), (1, 5), (1, 5),
            (1, "lrs"), (1, "lrs"),
            (1, 6), (1, 6),
            (1, "frs"), (1, "frs"),
            (3, "ts"),
            (3, "ts"),
                            (0, 7), (0, 6), (0, 6),
            (1, "lrs"), (1, "lrs"),
            (1, 7), (1, 7),
            (1, "frs"), (1, "frs"),
            (3, "ts"),
            (3, "ts"),
                            (1, 6), (0, 7), (0, 7),
                            (1, 7), (1, 6), (1, 6),
                                    (1, 7), (1, 7),

            (0, "s"), (0,"s"), (0,"s"), (0,"s"),
            (1, "s"), (1,"s"), (1,"s"), (1,"s"),

            (2, "lrs"), (2, "lrs"),
            (2, 4), (2, 4),
            (2, 5), (2, 5),
            (2, "frs"), (2, "frs"),
                            (2, 4),
            (3, "lrs"), (3, "lrs"),
            (3, 4), (3, 4), (2, 5), (2, 4), (2, 4),
            (3, 5), (3, 5),
            (3, "frs"), (3, "frs"),
                            (3, 4), (2, 5), (2, 5),
            (2, "lrs"), (2, "lrs"),
            (2, 6), (2, 6),
            (2, "frs"), (2, "frs"),
                            (3, 5), (3, 4), (3, 4),
            (2, "lrs"), (2, "lrs"),
            (2, 7), (2, 7),
            (2, "frs"), (2, "frs"),
                            (2, 6), (3, 5), (3, 5),
            (3, "lrs"), (3, "lrs"),
            (3, 6), (3, 6),
            (3, "frs"), (3, "frs"),
                            (2, 7), (2, 6), (2, 6),
            (3, "lrs"), (3, "lrs"),
            (3, 7), (3, 7),
            (3, "frs"), (3, "frs"),
                            (3, 6), (2, 7), (2, 7),
                            (3, 7), (3, 6), (3, 6),
                                    (3, 7), (3, 7),

            (2, "s"), (2,"s"), (2,"s"), (2,"s"),
            (3, "s"), (3,"s"), (3,"s"), (3,"s") ] ),

           # INDEX 3
           # Interleave pre- and post-transpose arithmetic, and transpose
           # And loads + stores
           ( None, None, None, None, None, # All defaults
             [(0,"m"),
            (1,"m"),

            (0,0), (0,0),
            (0,1), (0,1),
                                                          (2, "sl"),
                                                          (2, "sl"),
                                                          (2, "sl"),
                                                          (2, "sl"),
                          (0,0),
                                                          (0, "l"),
            (1,0),
                                                          (0, "l"),
                   (1,0),
                                                          (3, "sl"),
                                                          (3, "sl"),
                                                          (3, "sl"),
                                                          (3, "sl"),
                          (0,1),
                                 (0,0), (0,0),
            (1,1),
                                                          (2,"l"),
                   (1,1),
                                                          (2,"l"),
                          (1,0),
                                                          (1,"l"),
                                 (0,1), (0,1),
            (0,2),
                                                          (2,"l"),
                   (0,2),
                                                          (2,"l"),
                          (1,1),
                                                          (1,"l"),
                                 (1,0), (1,0),
            (0,3),
                                                          (2,"lrs"),
                   (0,3),
                                                          (2,"lrs"),
                          (0,2),
                                 (1,1),
                                        (1,1),
            (1,2),
                                                          (3,"l"),
                   (1,2),
                                                          (3,"l"),
                          (0,3), (0,2), (0,2),
                                                          (0, "frs"),
                                                          (0, "frs"),
            (1,3),
                                                          (3,"l"),
                   (1,3),
                                                          (3,"l"),
                          (1,2), (0,3), (0,3),
            (2,0),
                                                          (3,"lrs"),
                   (2,0),
                                                          (3,"lrs"),
                                                          (0, "ts"),
                                                          (0, "ts"),
                          (1,3), (1,2), (1,2),
                                                          (1, "frs"),
                                                          (1, "frs"),
            (2,1), (2,1),
                                                          (0, "ts"),
                                                          (0, "ts"),
                          (2,0), (1,3), (1,3),
            (3,0), (3,0),
                                                          (0, "ts"),
                                                          (0, "ts"),
                          (2,1), (2,0), (2,0),
            (3,1), (3,1),
                                                          (0, "ts"),
                                                          (0, "ts"),
                          (3,0), (2,1), (2,1),
            (2,2), (2,2),
                                                          (1, "ts"),
                                                          (1, "ts"),
                          (3,1), (3,0), (3,0),
            (2,3), (2,3),
                                                          (1, "ts"),
                                                          (1, "ts"),
                          (2,2), (3,1), (3,1),
            (3,2), (3,2),
                                                          (1, "ts"),
                                                          (1, "ts"),
                          (2,3), (2,2), (2,2),
                                                          (2, "frs"),
                                                          (2, "frs"),
            (3,3), (3,3),
                                                          (1, "ts"),
                                                          (1, "ts"),
                          (3,2), (2,3), (2,3),
                          (3,3), (3,2), (3,2),
                                                          (3, "frs"),
                                                          (3, "frs"),
                                 (3,3), (3,3),

                                                          (0, "lrs"),
                                                          (0, "lrs"),
            (0, 4), (0, 4),
                                                          (2, "ts"),
                                                          (2, "ts"),
            (0, 5), (0, 5),
                                                          (0, "frs"),
                                                          (0, "frs"),
                                                          (2, "ts"),
                                                          (2, "ts"),
                            (0, 4),
                                                          (1, "lrs"),
                                                          (1, "lrs"),
            (1, 4), (1, 4),
                                                          (2, "ts"),
                                                          (2, "ts"),
                            (0, 5), (0, 4), (0, 4),
            (1, 5), (1, 5),
                                                          (1, "frs"),
                                                          (1, "frs"),
                                                          (2, "ts"),
                                                          (2, "ts"),
                            (1, 4), (0, 5), (0, 5),
                                                          (0, "lrs"),
                                                          (0, "lrs"),
            (0, 6), (0, 6),
                                                          (0, "frs"),
                                                          (0, "frs"),
                                                          (3, "ts"),
                                                          (3, "ts"),
                            (1, 5), (1, 4), (1, 4),
                                                          (0, "lrs"),
                                                          (0, "lrs"),
            (0, 7), (0, 7),
                                                          (0, "frs"),
                                                          (0, "frs"),
                                                          (3, "ts"),
                                                          (3, "ts"),
                            (0, 6), (1, 5), (1, 5),
                                                          (1, "lrs"),
                                                          (1, "lrs"),
            (1, 6), (1, 6),
                                                          (1, "frs"),
                                                          (1, "frs"),
                                                          (3, "ts"),
                                                          (3, "ts"),
                            (0, 7), (0, 6), (0, 6),
                                                          (1, "lrs"),
                                                          (1, "lrs"),
            (1, 7), (1, 7),
                                                          (1, "frs"),
                                                          (1, "frs"),
                                                          (3, "ts"),
                                                          (3, "ts"),
                            (1, 6), (0, 7), (0, 7),
                            (1, 7), (1, 6), (1, 6),
                                    (1, 7), (1, 7),

            #########################################################

                                                          (2, "lrs"),
                                                          (2, "lrs"),
            (2, 4), (2, 4),
                                                          (0, "s"),
            (2, 5),
                                                          (0, "s"),
                    (2, 5),
                                                          (2, "frs"),
                                                          (2, "frs"),
                                                          (0, "s"),
                            (2, 4),
                                                          (3, "lrs"),
                                                          (3, "lrs"),
            (3, 4),
                                                          (1, "s"),
                    (3, 4),
                                                          (0, "s"),
                            (2, 5),
                                                          (1, "s"),
                                    (2, 4), (2, 4),
            (3, 5), (3, 5),
                                                          (3, "frs"),
                                                          (3, "frs"),
                                                          (1, "s"),
                            (3, 4), (2, 5), (2, 5),
                                                          (2, "lrs"),
                                                          (2, "lrs"),
            (2, 6), (2, 6),
                                                          (2, "frs"),
                                                          (2, "frs"),
                                                          (1, "s"),
                            (3, 5), (3, 4), (3, 4),
                                                          (2, "lrs"),
                                                          (2, "lrs"),
            (2, 7), (2, 7),
                                                          (2, "frs"),
                                                          (2, "frs"),
                            (2, 6), (3, 5), (3, 5),
                                                          (3, "lrs"),
                                                          (3, "lrs"),
            (3, 6), (3, 6),
                                                          (3, "frs"),
                                                          (3, "frs"),
                            (2, 7), (2, 6), (2, 6),
                                                          (3, "lrs"),
                                                          (3, "lrs"),
            (3, 7), (3, 7),
                                                          (3, "frs"),
                                                          (3, "frs"),
                                                          (0, "le"),
                            (3, 6),
                                                          (0, "le"),
                                    (2, 7),
                                                          (0, "lres"),
                                            (2, 7),
                                                          (0, "lres"),
                            (3, 7),
                                                          (1,"lres"),
                                    (3, 6),
                                                          (1, "le"),
                                            (3, 6),
                                                          (1,"lres"),
                                    (3, 7),
                                                          (1, "le"),
                                            (3, 7),

            ] ),

           # INDEX 4
           # Interleave pre- and post-transpose arithmetic, and transpose
           # And loads + stores
           ( None, None, None, None, None, # All defaults
             [(0,0), (0,0), (3, -1), (3, -2), (3, -2),
            (0,1), (0,1),
                                                          (2, "sl"),
                                                          (2, "sl"),
                                                          (2, "sl"),
                                                          (2, "sl"),
                          (0,0), (3,-1), (3,-1),
                                                          (0, "l"),
            (1,0),
                                                          (0, "l"),
                   (1,0),
                                                          (3, "sl"),
                                                          (3, "sl"),
                                                          (3, "sl"),
                                                          (3, "sl"),
                          (0,1),
                                 (0,0), (0,0),
            (1,1),
                                                          (2,"l"),
                   (1,1),
                                                          (2,"l"),
                          (1,0),
                                                          (1,"l"),
                                 (0,1), (0,1),
            (0,2),
                                                          (2,"l"),
                   (0,2),
                                                          (2,"l"),
                          (1,1),
                                                          (1,"l"),
                                 (1,0), (1,0),
            (0,3),
                                                          (2,"lrs"),
                   (0,3),
                                                          (2,"lrs"),
                          (0,2),
                                 (1,1),
                                        (1,1),
            (1,2),
                                                          (3,"l"),
                   (1,2),
                                                          (3,"l"),
                          (0,3), (0,2), (0,2),
                                                          (0, "frs"),
                                                          (0, "frs"),
            (1,3),
                                                          (3,"l"),
                   (1,3),
                                                          (3,"l"),
                          (1,2), (0,3), (0,3),
            (2,0),
                                                          (3,"lrs"),
                   (2,0),
                                                          (3,"lrs"),
                                                          (0, "ts"),
                                                          (0, "ts"),
                          (1,3), (1,2), (1,2),
                                                          (1, "frs"),
                                                          (1, "frs"),
            (2,1), (2,1),
                                                          (0, "ts"),
                                                          (0, "ts"),
                          (2,0), (1,3), (1,3),
            (3,0), (3,0),
                                                          (0, "ts"),
                                                          (0, "ts"),
                          (2,1), (2,0), (2,0),
            (3,1), (3,1),
                                                          (0, "ts"),
                                                          (0, "ts"),
                          (3,0), (2,1), (2,1),
            (2,2), (2,2),
                                                          (1, "ts"),
                                                          (1, "ts"),
                          (3,1), (3,0), (3,0),
            (2,3), (2,3),
                                                          (1, "ts"),
                                                          (1, "ts"),
                                                          (0, "lrs"),
                                                          (0, "lrs"),
                          (2,2), (3,1), (3,1),
            (3,2), (3,2),
                                                          (1, "ts"),
                                                          (1, "ts"),
                          (2,3), (2,2), (2,2),
                                                          (2, "frs"),
                                                          (2, "frs"),
            (3,3), (3,3),
                                                          (1, "ts"),
                                                          (1, "ts"),
                          (3,2), (2,3), (2,3),
            (0,4), (0,4), (3,3), (3,2), (3,2),
                                                          (3, "frs"),
                                                          (3, "frs"),
                                                          (1, "lrs"),
                                                          (1, "lrs"),
            (0,5), (0,5),
                                                          (2, "ts"),
                                                          (2, "ts"),

                          (0,4), (3,3), (3,3),

                                                          (0, "frs"),
                                                          (0, "frs"),
                                                          (0, "lrs"),
                                                          (0, "lrs"),
                                                          (2, "ts"),
                                                          (2, "ts"),

            (1, 4), (1, 4),
                                                          (2, "ts"),
                                                          (2, "ts"),
                                                          (0, "lrs"),
                                                          (0, "lrs"),
                            (0, 5), (0, 4), (0, 4),
            (1, 5), (1, 5),
                                                          (1, "frs"),
                                                          (1, "frs"),
                                                          (2, "ts"),
                                                          (2, "ts"),
                                                          (1, "lrs"),
                                                          (1, "lrs"),
                            (1, 4), (0, 5), (0, 5),
            (0, 6), (0, 6),
                                                          (0, "frs"),
                                                          (0, "frs"),
                                                          (3, "ts"),
                                                          (3, "ts"),
                                                          (1, "lrs"),
                                                          (1, "lrs"),
                            (1, 5), (1, 4), (1, 4),
            (0, 7), (0, 7),
                                                          (0, "frs"),
                                                          (0, "frs"),
                                                          (3, "ts"),
                                                          (3, "ts"),
                            (0, 6), (1, 5), (1, 5),
            (1, 6), (1, 6),
                                                          (2, "lrs"),
                                                          (2, "lrs"),
                                                          (1, "frs"),
                                                          (1, "frs"),
                                                          (3, "ts"),
                                                          (3, "ts"),
                            (0, 7), (0, 6), (0, 6),
            (1, 7), (1, 7),
                                                          (1, "frs"),
                                                          (1, "frs"),
                                                          (3, "ts"),
                                                          (3, "ts"),
                            (1, 6), (0, 7), (0, 7),
            (2, 4),
                                                          (3, "lrs"),
                                                          (3, "lrs"),
                    (2, 4),
                                                          (0, "s"),
                                                          (0, "s"),
                            (1, 7), (1, 6), (1, 6),
            (2, 5), (2, 5),
                                                          (2, "frs"),
                                                          (2, "frs"),
                                                          (0, "s"),
                            (2, 4), (1, 7), (1, 7),
                                                          (2, "lrs"),
                                                          (2, "lrs"),
            (3, 4),
                                                          (1, "s"),
                    (3, 4),
                                                          (0, "s"),
                            (2, 5),
                                                          (1, "s"),
                                    (2, 4), (2, 4),
                                                          (2, "lrs"),
                                                          (2, "lrs"),
            (3, 5), (3, 5),
                                                          (3, "frs"),
                                                          (3, "frs"),
                                                          (1, "s"),
                            (3, 4), (2, 5), (2, 5),
                                                          (3, "lrs"),
                                                          (3, "lrs"),
            (2, 6), (2, 6),
                                                          (2, "frs"),
                                                          (2, "frs"),
                                                          (3, "lrs"),
                                                          (3, "lrs"),
                                                          (1, "s"),
                            (3, 5), (3, 4), (3, 4),
            (2, 7), (2, 7),
                                                          (2, "frs"),
                                                          (2, "frs"),
                            (2, 6), (3, 5), (3, 5),
            (3, 6), (3, 6),
                                                          (3, "frs"),
                                                          (3, "frs"),
                                                          (0, "le"),
                            (2, 7),
                                                          (0, "le"),
                                    (2, 6), (2, 6),
            (3, 7),
                                                          (0, "lres"),
                     (3, 7),
                                                          (3, "frs"),
                                                          (3, "frs"),
                                                          (0, "lres"),
                            (3, 6),
                                                          (1,"lres"),
                                    (2, 7),
                                                          (1, "le"),
                                            (2, 7),
                                                          (1,"lres"),
                                                          (1, "le"),

             ]),
        ]

        load_order, store_order, numbering, twiddles, root_order, schedule = schedules[idx]

        if load_order == None:
            load_order = load_order_default
        if store_order == None:
            store_order = store_order_default
        if numbering == None:
            numbering = butterfly_numbering_default
        if twiddles == None:
            twiddles = twiddle_numbering_default
        if root_order == None:
            root_order = root_load_order_default

        return load_order, store_order, numbering, twiddles, root_order, schedule

    def get_schedule_quad_no_transpose(self, idx):

        def add(n):
            def _add(x):
                if isinstance(x,int):
                    return x + n
                else:
                    return x
            return _add

        butterfly_numbering_default  = \
            list(zip(
                [0, 1, 2, 3, 4, 5, 6, 7, 0,1,2,3, 8, 9,10,11, 0,1,4,5, 8, 9,12,13, 0,2,4, 6, 8,10,12,14],
                [8, 9,10,11,12,13,14,15, 4,5,6,7,12,13,14,15, 2,3,6,7,10,11,14,15, 1,3,5, 7, 9,11,13,15],
                [0, 0, 0, 0, 0, 0, 0, 0, 1,1,1,1, 2, 2, 2, 2, 3,3,4,4, 5, 5, 6, 6, 7,8,9,10,11,12,13,14]))


        default = {
            "load_order":  [12,13,14,15,4,5,6,7,8,9,10,11,0,1,2,3],
            "store_order": list(range(0,16)),
            "numbering":  butterfly_numbering_default[4:8]   + butterfly_numbering_default[0:4]   + \
                          butterfly_numbering_default[10:12] + butterfly_numbering_default[8:10]  + \
                          butterfly_numbering_default[14:16] + butterfly_numbering_default[12:14] + \
                          butterfly_numbering_default[16:32],
            "twiddles":  { 0:  (0,0),
                           1:  (0,1),
                           2:  (0,2),
                           3:  (1,0),
                           4:  (1,1),
                           5:  (1,2),
                           6:  (1,3),
                           7:  (2,0),
                           8:  (2,1),
                           9:  (2,2),
                           10: (2,3),
                           11: (3,0),
                           12: (3,1),
                           13: (3,2),
                           14: (3,3) },
            "root_load_order": list(range(0,10)),
            "schedule": None }

        modifications = {

           # INDEX 0
           # Trivial implementation, no interleaving whatsoever
           0 : { "schedule":
             ["m", "frl", "l", "l", "l", "l",
              "l", "l", "l", "l",
              "l", "l", "l", "l",
              "l", "l", "l", "l",

              0, 0, 0, 0, 0,
              1, 1, 1, 1, 1,
              2, 2, 2, 2, 2,
              3, 3, 3, 3, 3,
              4, 4, 4, 4, 4,
              5, 5, 5, 5, 5,
              6, 6, 6, 6, 6,
              7, 7, 7, 7, 7,

              8,  8,  8,  8,  8,
              9,  9,  9,  9,  9,
              10, 10, 10, 10, 10,
              11, 11, 11, 11, 11,
              12, 12, 12, 12, 12,
              13, 13, 13, 13, 13,
              14, 14, 14, 14, 14,
              15, 15, 15, 15, 15,

              16, 16, 16, 16, 16,
              17, 17, 17, 17, 17,
              18, 18, 18, 18, 18,
              19, 19, 19, 19, 19,
              20, 20, 20, 20, 20,
              21, 21, 21, 21, 21,
              22, 22, 22, 22, 22,
              23, 23, 23, 23, 23,

              24, 24, 24, 24, 24,
              25, 25, 25, 25, 25,
              26, 26, 26, 26, 26, "lre",
              27, 27, 27, 27, 27,
              28, 28, 28, 28, 28,
              29, 29, 29, 29, 29,
              30, 30, 30, 30, 30,
              31, 31, 31, 31, 31,

              "s", "s", "s", "s",
              "s", "s", "s", "s",
              "s", "s", "s", "s",
              "s", "s", "s", "s" ] },

           # INDEX 1
           # First interleaving attempt: Arithmetic only
           # Space out arithmetic operations to account
           # for A72/N1 latencies of multiplications.
           1 : { "schedule":
             ["m",  "l", "l", "l", "l",
             "l", "l", "l", "l",
             "l", "l", "l", "l",
             "l", "l", "l", "l",

             0,  0,
             1,  1,  0,
             2,  2,  1, 0, 0,
             3,  3,  2, 1, 1,
             4,  4,  3, 2, 2,
             5,  5,  4, 3, 3,
             6,  6,  5, 4, 4,
             7,  7,  6, 5, 5,

             8,  8,  7, 6,  6,
             9,  9,  8, 7,  7,
             10, 10, 9, 8,  8,
             11, 11,10, 9,  9,
             12, 12,11,10, 10,
             13, 13,12,11, 11,

             14, 14,13,12, 12,
             15, 15,14,13, 13,

             16, 16,15,14, 14,
             17, 17,16,15, 15,
             18, 18,17,16, 16,
             19, 19,18,17, 17,

             20, 20,19,18, 18,
             21, 21,20,19, 19,
             22, 22,21,20, 20,
             23, 23,22,21, 21,

             24, 24,23,22, 22,
             25, 25,24,23, 23, "lre",
             26, 26,25,24, 24,
             27, 27,26,25, 25,

             28, 28,27,26, 26,
             29, 29,28,27, 27,
             30, 30,29,28, 28,
             31, 31,30,29, 29,
                    31,30, 30,
                       31, 31,

             "s", "s", "s", "s",
             "s", "s", "s", "s",
             "s", "s", "s", "s",
             "s", "s", "s", "s", "frl" ] },

           # INDEX 2
           # TODO: Document
           2 : { "schedule":
             ["m",  0, "sl", "l", 0, "l", -1, -2, -2, "sl",
              1, "sl", "l", 1, "l", 0, -1, -1,  "sl",
              2, "sl", 2, "l", 1, 0, 0,   "sl",
              3, "sl", 3, "l", 2, 1, 1,
              4, "l", 4, 3, 2, 2,
              5, "l", 5, 4, 3, 3,
              6,  6,  5, 4, 4,
              7,  7,  6, 5, 5,

              8,  8,  7, 6,  6,
              9,  9,  8, 7,  7,
              10, 10, 9, 8,  8,
              11, 11,10, 9,  9,
              12, 12,11,10, 10,
              13, 13,12,11, 11,

              14, 14,13,12, 12,
              15, 15,14,13, 13,

              16, 16,15,14, 14,
              17, 17,16,15, 15,
              18, 18,17,16, 16,
              19, 19,18,17, 17,

              20, 20,19,18, 18,
              21, 21,20,19, 19,
              22, 22,21,20, 20,
              23, 23,22,21, 21,

              24, 24,23,22, 22, "lre",
              25, 25,24,23, 23,
              26, 26,25,24, 24,
              27,          27,               26,               25, 25, "s",
              28, "s", 28, "le", 27, "le", 26, 26, "s",
              29, "s", 29, "le", 28, "le", 27, 27, "s",
              30, "s", 30, "le", 29, "le", 28, 28, "s",
              31, "s", 31, "frl", "le", 30, "le", 29, 29, "s" ] },

           # INDEX 3
           # TODO: Document
           3 : { "schedule":
             ["m",  0, "sl", "l", 0, "l", -2, -1, -2, "sl",
              1, "sl", "l", 1, "l", -1, 0, -1,  "sl",
              2, "sl", 2, "l", 0, 1, 0,   "sl",
              3, "sl", 3, "l", 1, 2, 1,
              4, "l", 4, 2, 3, 2,
              5, "l", 5, 3, 4, 3,
              6,  6,  4, 5, 4,
              7,  7,  5, 6, 5,

              8,  8,  6, 7,  6,
              9,  9,  7, 8,  7,
              10, 10, 8, 9,  8,
              11, 11, 9,10,  9,
              12, 12,10,11, 10,
              13, 13,11,12, 11,

              14, 14,12,13, 12,
              15, 15,13,14, 13,

              16, 16,14,15, 14,
              17, 17,15,16, 15,
              18, 18,16,17, 16,
              19, 19,17,18, 17,

              20, 20,18,19, 18,
              21, 21,19,20, 19,
              22, 22,20,21, 20,
              23, 23,21,22, 21,

              24, 24,22,23, 22, "lre",
              25, 25,23,24, 23,
              26, 26,24,25, 24,
              27,          27,               25,               26, 25, "s",
              28, "s", 28, "le", 26, "le", 27, 26, "s",
              29, "s", 29, "le", 27, "le", 28, 27, "s",
              30, "s", 30, "le", 28, "le", 29, 28, "s",
              31, "s", 31, "frl", "le", 29, "le", 30, 29, "s" ] },

           # INDEX 4
           4 : { "schedule":
             ["m", "frl",
              "l", "l", "l", "l",
              "l", "l", "l", "l",
              "l", "l", "l", "l",
              "l", "l", "l", "l",

              "lr",

              0, 1, 2, 3,
              0, 1, 2, 3,
              0, 1, 2, 3,
              0, 1, 2, 3,
              0, 1, 2, 3,

              4, 5, 6, 7,
              4, 5, 6, 7,
              4, 5, 6, 7,
              4, 5, 6, 7,
              4, 5, 6, 7,

              8+0, 8+1, 8+2, 8+3,
              8+0, 8+1, 8+2, 8+3,
              8+0, 8+1, 8+2, 8+3,
              8+0, 8+1, 8+2, 8+3,
              8+0, 8+1, 8+2, 8+3,

              8+4, 8+5, 8+6, 8+7,
              8+4, 8+5, 8+6, 8+7,
              8+4, 8+5, 8+6, 8+7,
              8+4, 8+5, 8+6, 8+7,
              8+4, 8+5, 8+6, 8+7,

              16+0, 16+1, 16+2, 16+3,
              16+0, 16+1, 16+2, 16+3,
              16+0, 16+1, 16+2, 16+3,
              16+0, 16+1, 16+2, 16+3,
              16+0, 16+1, 16+2, 16+3,

              16+4, 16+5, 16+6, 16+7,
              16+4, 16+5, 16+6, 16+7,
              16+4, 16+5, 16+6, 16+7,
              16+4, 16+5, 16+6, 16+7,
              16+4, 16+5, 16+6, 16+7,

              24+0, 24+1, 24+2, 24+3,
              24+0, 24+1, 24+2, 24+3,
              24+0, 24+1, 24+2, 24+3,
              24+0, 24+1, 24+2, 24+3,
              24+0, 24+1, 24+2, 24+3,

              24+4, 24+5, 24+6, 24+7,
              24+4, 24+5, 24+6, 24+7,
              24+4, 24+5, 24+6, 24+7,
              24+4, 24+5, 24+6, 24+7,
              24+4, 24+5, 24+6, 24+7,

              "s", "s", "s", "s",
              "s", "s", "s", "s",
              "s", "s", "s", "s",
              "s", "s", "s", "s" ] },

           # INDEX 5
           5 : { "schedule":
             ["m", "frl",
              "l", "l", "l", "l",
              "l", "l", "l", "l",
              "l", "l", "l", "l",
              "l", "l", "l", "l",

              "lr",

              0, 0, 1, 1, 2, 2, 3, 3,
              0, 1, 2, 3,
              4, 4, 5, 5, 6, 6, 7, 7,
              4, 5, 6, 7,
              0, 0, 1, 1, 2, 2, 3, 3,
              4, 4, 5, 5, 6, 6, 7, 7,

              8+0, 8+0, 8+1, 8+1, 8+2, 8+2, 8+3, 8+3,
              8+0, 8+1, 8+2, 8+3,
              8+4, 8+4, 8+5, 8+5, 8+6, 8+6, 8+7, 8+7,
              8+4, 8+5, 8+6, 8+7,
              8+0, 8+0, 8+1, 8+1, 8+2, 8+2, 8+3, 8+3,
              8+4, 8+4, 8+5, 8+5, 8+6, 8+6, 8+7, 8+7,

              16+0, 16+0, 16+1, 16+1, 16+2, 16+2, 16+3, 16+3,
              16+0, 16+1, 16+2, 16+3,
              16+4, 16+4, 16+5, 16+5, 16+6, 16+6, 16+7, 16+7,
              16+4, 16+5, 16+6, 16+7,
              16+0, 16+0, 16+1, 16+1, 16+2, 16+2, 16+3, 16+3,
              16+4, 16+4, 16+5, 16+5, 16+6, 16+6, 16+7, 16+7,

              24+0, 24+0, 24+1, 24+1, 24+2, 24+2, 24+3, 24+3,
              24+0, 24+1, 24+2, 24+3,
              24+4, 24+4, 24+5, 24+5, 24+6, 24+6, 24+7, 24+7,
              24+4, 24+5, 24+6, 24+7,
              24+0, 24+0, 24+1, 24+1, 24+2, 24+2, 24+3, 24+3,
              24+4, 24+4, 24+5, 24+5, 24+6, 24+6, 24+7, 24+7,

              "s", "s", "s", "s",
              "s", "s", "s", "s",
              "s", "s", "s", "s",
              "s", "s", "s", "s" ] },

           # INDEX 6
           # A totally messy manual attempt to interleave
           6 : { "schedule":
             ["m", "frl",
                  "lr"] +

                  [0, "l", "l", 0, -1, -1, "sl", "sl", "l", "l", 1, "l", 1, "l", 2, "l", 2, "l", 3, 3,
                   0, 1, 2, 3,
                   4, 4, 0, 0, 5, 5, 1, 1, 6, 6, 2, 2, 7, 7,
                   4, 3, 5, 3, 6, 7] +

            list(map(add(8),
                  [0, 0, -4, -4, 1, 1, -3, -3, 2, 2, -2, -2, 3, 3,
                   0, -1, -1, 1, 2, 3,
                   4, 4, 0, 0, 5, 5, 1, 1, 6, 6, 2, 2, 7, 7,
                   4, 3, 5, 3, 6, 7])) +
            list(map(add(16),
                  [0, 0, -4, -4, 1, 1, -3, -3, 2, 2, -2, -2, 3, 3,
                   0, -1, -1, 1, 2, 3,
                   4, 4, 0, 0, 5, 5, 1, 1, 6, 6, 2, 2, 7, 7,
                   4, 3, 5, 3, 6, 7])) +
            list(map(add(24),
                  [0, 0, -4, -4, 1, 1, -3, -3, 2, 2, -2, -2, 3, 3,
                   0, -1, -1, 1, 2, 3,
                   4, 4, 0, 0, "s", "s", 5, 5, "le", "le", 1, 1, "s", "s", 6, 6, "le", "le", 2, 2, "s", "s", 7, 7,
                   "le", "le", 4, 3, 5, 3, "s", "s", 6, "le", "le", 7])) +

                   [28,28,29,29,30,30] +

                  ["s", "s", "s", "s",
                  "s", "s" ] },

           # INDEX 7
           # Careful manual interleaving, accounting for latencies
           # and usage of vector pipes for vector stores
           7 : { "load_order":  [14, 15, 12,13, 8,9,10, 6, 11,7,4,5,0,1,2,3],
                 "store_order": [4,5,6,7,2,3,0,1,8,9,10,11,12,13,14,15],
                 "numbering":   list(zip(
                     [6,  7,  4, 5, 0,1, 2, 3, 2,3,0,1,10,11, 8, 9, 4,5,0,1, 8, 9,12,13, 4,6,2,0, 8,10,12,14],
                     [14, 15, 12,13,8,9,10,11, 6,7,4,5,14,15,12,13, 6,7,2,3,10,11,14,15, 5,7,3,1, 9,11,13,15],
                     [0, 0, 0, 0, 0, 0, 0, 0,  1,1,1,1, 2, 2, 2, 2, 4,4,3,3, 5, 5, 6, 6, 9,10,8,7,11,12,13,14])),
                 "schedule":
             ["m", "frl",
              "lr",

              "l",
              0, 0,                              -5 , "sl",
              "l",
                    1, 1,                        -5 , "sl",
              "l",
                          2, 2,                  -4 , -4,
              "l",
                                3, 3,            -3 , -3,
              0, 1,                              -2 , "sl",
                    2, 3,                        -2 , "sl",
              "l",
              4, 4,                              -1 , "sl",
              "l",
                    5, 5,                        -1 , "sl",
              "l",
              "l",
                          6, 6,                   0 , 0,
              "l",
              "l",
                                7, 7,             1 , 1,
              "l",
              4, 5,                               2 , "sl",
                    6, 7,                         2 , "sl",
              "l",
              8, 8,                               3 , "sl",
                    9, 9,                         3 , "sl",
              "l",
                          10, 10,                 4 , 4,
              "l",
                                11, 11,           5 , 5,
              "l",
              8, 9,                               6 , "sl",
                    10, 11,                       6 , "sl",
              "l",
              12,12,                              7 , "sl",
                    13,13,                        7 , "sl",
                          14,14,                  8 , 8,
                                15,15,            9 , 9,
              12,13,                              10,
                    14,15,                        10,
              16, 16,                             11,
                   17,17,                         11,
                          18,18,                  12, 12,
                                19, 19,           13, 13,
              16, 17,                             14,
                    18, 19,                       14,
              20, 20,                             15,
                    21,21,                        15,
                          22,22,                  16, 16,
                                23,23,            17, 17,
              20,21,                              18,
                    22,23,                        18,
              24,24,                              19,
                    25,25,                        19,
                          26,26,                  20, 20,
                                27,27,            21, 21,
              24,25,                              22,
                    26,27,                        22,
              28,28,                              23,
                    29,29,                        23,
                          30,30,                  24,24,
                                31,31,            25,25,
              28,29,                              26, "s", # S(8)        # 15 old
                    30,31,                        26, "s", # S(8)        # 14 old
             ] },

           # INDEX 8
           # The same as 7, but exploring a slightly different interleaving within each line
           # which avoids consecutive multiplication operations.
           8 : { "load_order":   [14, 15, 12,13, 8,9,10, 6, 11,7,4,5,0,1,2,3], # Load order
                  "store_order": [4,5,6,7,2,3,0,1,8,9,10,11,12,13,14,15], # Default store order
                  "numbering": list(zip(
                      [6,  7,  4, 5, 0,1, 2, 3, 2,3,0,1,10,11, 8, 9, 4,5,0,1, 8, 9,12,13, 4,6,2,0, 8,10,12,14],
                      [14, 15, 12,13,8,9,10,11, 6,7,4,5,14,15,12,13, 6,7,2,3,10,11,14,15, 5,7,3,1, 9,11,13,15],
                      [0, 0, 0, 0, 0, 0, 0, 0,  1,1,1,1, 2, 2, 2, 2, 4,4,3,3, 5, 5, 6, 6, 9,10,8,7,11,12,13,14])),
                 "schedule": ["m", "frl",
              "lr",

              "l",
              0,                             -5 ,  0,  "sl",
              "l",
                    1,                       -5 ,  1,  "sl",
              "l",
                          2,                 -4 ,  2,  -4,
              "l",
                                3,           -3 ,  3,  -3,
              0,                             -2 ,  1,  "sl",
                    2,                       -2 ,  3,  "sl",
              "l",
              4,                             -1 ,  4,  "sl",
              "l",
                    5,                       -1 ,  5,  "sl",
              "l",
              "l",
                          6,                  0 ,  6,  0,
              "l",
              "l",
                                7,            1 ,  7,  1,
              "l",
              4,                              2 ,  5,  "sl",
                    6,                        2 ,  7,  "sl",
              "l",
              8,                              3 ,  8,  "sl",
                    9,                        3 ,  9,  "sl",
              "l",
                          10,                4 ,  10,  4,
              "l",
                                11,          5 ,  11,  5,
              "l",
              8,                              6 ,  9,  "sl",
                    10,                      6 ,  11,  "sl",
              "l",
              12,                             7 , 12,  "sl",
                    13,                       7 , 13,  "sl",
                          14,                 8 , 14,  8,
                                15,           9 , 15,  9,
              12,                             10, 13,
                    14,                       10, 15,
              16,                            11,  16,
                   17,                        11, 17,
                          18,                 12, 18,  12,
                                19,          13,  19,  13,
              16,                            14,  17,
                    18,                      14,  19,
              20,                            15,  20,
                    21,                       15, 21,
                          22,                 16, 22,  16,
                                23,           17, 23,  17,
              20,                             18, 21,
                    22,                       18, 23,
              24,                             19, 24,
                    25,                       19, 25,
                          26,                 20, 26,  20,
                                27,           21, 27,  21,
              24,                             22, 25,
                    26,                       22, 27,
              28,                             23, 28,
                    29,                       23, 29,
                          30,                 24, 30, 24,
                                31,           25, 31, 25,
              28,                             26, 29,  "s", # S(8)        # 15 old
                    30,                       26, 31,  "s", # S(8)        # 14 old
             ] },

           # INDEX 9
           # The same as 7, but experimenting whether avoiding ST-LD pairs makes
           # any tangible difference
           9 : { "load_order":   [14, 15, 12,13, 8,9,10, 6, 11,7,4,5,0,1,2,3], # Load order
                  "store_order": [4,5,6,7,2,3,0,1,8,9,10,11,12,13,14,15], # Default store order
                  "numbering": list(zip(
                [6,  7,  4, 5, 0,1, 2, 3, 2,3,0,1,10,11, 8, 9, 4,5,0,1, 8, 9,12,13, 4,6,2,0, 8,10,12,14],
                [14, 15, 12,13,8,9,10,11, 6,7,4,5,14,15,12,13, 6,7,2,3,10,11,14,15, 5,7,3,1, 9,11,13,15],
                [0, 0, 0, 0, 0, 0, 0, 0,  1,1,1,1, 2, 2, 2, 2, 4,4,3,3, 5, 5, 6, 6, 9,10,8,7,11,12,13,14])),
                 "schedule":
             ["m", "frl",
              "lr",

              "l",
              0, 0,                             "sl",  -5 ,
              "l",
                    1, 1,                       "sl",  -5 ,
              "l",
                          2, 2,                  -4 , -4,
              "l",
                                3, 3,            -3 , -3,
              0, 1,                             "sl",  -2 ,
                    2, 3,                       "sl",  -2 ,
              "l",
              4, 4,                             "sl",  -1 ,
              "l",
                    5, 5,                       "sl",  -1 ,
              "l",
              "l",
                          6, 6,                   0 , 0,
              "l",
              "l",
                                7, 7,             1 , 1,
              "l",
              4, 5,                             "sl",   2 ,
                    6, 7,                       "sl",   2 ,
              "l",
              8, 8,                             "sl",   3 ,
                    9, 9,                       "sl",   3 ,
              "l",
                          10, 10,                 4 , 4,
              "l",
                                11, 11,           5 , 5,
              "l",
              8, 9,                             "sl",   6 ,
                    10, 11,                     "sl",   6 ,
              "l",
              12,12,                            "sl",   7 ,
                    13,13,                      "sl",   7 ,
                          14,14,                  8 , 8,
                                15,15,            9 , 9,
              12,13,                              10,
                    14,15,                        10,
              16, 16,                             11,
                   17,17,                         11,
                          18,18,                  12, 12,
                                19, 19,           13, 13,
              16, 17,                             14,
                    18, 19,                       14,
              20, 20,                             15,
                    21,21,                        15,
                          22,22,                  16, 16,
                                23,23,            17, 17,
              20,21,                              18,
                    22,23,                        18,
              24,24,                              19,
                    25,25,                        19,
                          26,26,                  20, 20,
                                27,27,            21, 21,
              24,25,                              22,
                    26,27,                        22,
              28,28,                              23,
                    29,29,                        23,
                          30,30,                  24,24,
                                31,31,            25,25,
              28,29,                              26, "s", # S(8)        # 15 old
                    30,31,                        26, "s", # S(8)        # 14 old
             ] },

           # INDEX 10
           # Same as 7, but inserting some nops to always have blocks of
           # four instructions with two multiplies
           10 : {  "load_order": [14, 15, 12,13, 8,9,10, 6, 11,7,4,5,0,1,2,3], # Load order
                   "store_order": [4,5,6,7,2,3,0,1,8,9,10,11,12,13,14,15], # Default store order
                    "numbering": list(zip(
                [6,  7,  4, 5, 0,1, 2, 3, 2,3,0,1,10,11, 8, 9, 4,5,0,1, 8, 9,12,13, 4,6,2,0, 8,10,12,14],
                [14, 15, 12,13,8,9,10,11, 6,7,4,5,14,15,12,13, 6,7,2,3,10,11,14,15, 5,7,3,1, 9,11,13,15],
                [0, 0, 0, 0, 0, 0, 0, 0,  1,1,1,1, 2, 2, 2, 2, 4,4,3,3, 5, 5, 6, 6, 9,10,8,7,11,12,13,14])),
                   "schedule": ["m", "frl",
              "lr",

              "l",
              0, 0,                              -5 , "sl",
              "l",
                    1, 1,                        -5 , "sl",
              "l",
                          2, 2,                  -4 , -4,
              "l",
                                3, 3,            -3 , -3,
              0, 1,                              -2 , "sl",
                    2, 3,                        -2 , "sl",
              "l",
              4, 4,                              -1 , "sl",
              "l",
                    5, 5,                        -1 , "sl",
              "l",
              "l",
                          6, 6,                   0 , 0,
              "l",
              "l",
                                7, 7,             1 , 1,
              "l",
              4, 5,                               2 , "sl",
                    6, 7,                         2 , "sl",
              "l",
              8, 8,                               3 , "sl",
                    9, 9,                         3 , "sl",
              "l",
                          10, 10,                 4 , 4,
              "l",
                                11, 11,           5 , 5,
              "l",
              8, 9,                               6 , "sl",
                    10, 11,                       6 , "sl",
              "l",
              12,12,                              7 , "sl",
                    13,13,                        7 , "sl",
                          14,14,                  8 , 8,
                                15,15,            9 , 9,
              12,13,                              10, "nop",
                    14,15,                        10, "nop",
              16, 16,                             11, "nop",
                   17,17,                         11, "nop",
                          18,18,                  12, 12,
                                19, 19,           13, 13,
              16, 17,                             14, "nop",
                    18, 19,                       14, "nop",
              20, 20,                             15, "nop",
                    21,21,                        15, "nop",
                          22,22,                  16, 16,
                                23,23,            17, 17,
              20,21,                              18, "nop",
                    22,23,                        18, "nop",
              24,24,                              19, "nop",
                    25,25,                        19, "nop",
                          26,26,                  20, 20,
                                27,27,            21, 21,
              24,25,                              22, "nop",
                    26,27,                        22, "nop",
              28,28,                              23, "nop",
                    29,29,                        23, "nop",
                          30,30,                  24,24,
                                31,31,            25,25,
              28,29,                              26, "s", # S(8)        # 15 old
                    30,31,                        26, "s", # S(8)        # 14 old
             ] },

           # INDEX 11
           # Careful manual interleaving, accounting for latencies
           # and usage of vector pipes for vector stores
           11 : { "load_order": [14, 15, 12,13, 8,9,10, 11, 6,7,4,5,0,1,2,3], # Load order
                  "store_order": [5,4,7,6,3,2,1,0,9,8,11,10,13,12,15,14],
                  "numbering": list(zip(
                [6,  7,  4, 5, 0,1, 2, 3, 2,3,0,1,10,11, 8, 9, 4,5,0,1, 8, 9,12,13, 4,6,2,0, 8,10,12,14],
                [14, 15, 12,13,8,9,10,11, 6,7,4,5,14,15,12,13, 6,7,2,3,10,11,14,15, 5,7,3,1, 9,11,13,15],
                [0, 0, 0, 0, 0, 0, 0, 0,  1,1,1,1, 2, 2, 2, 2, 4,4,3,3, 5, 5, 6, 6, 9,10,8,7,11,12,13,14])),
                  "schedule":
             ["m", "frl",

              "l",
              "lrs",
              "lrs",
              0,
              0,
                    "l",
                    1,                          -4, "sl",
                    1,                          -4, "sl",
                          "l",
                          2,                    -3, "sl",
                          2,                    -3, "sl",
                                "l",
                                3,              -2, "sl",
                                3,              -2, "sl",

              "l",
              0,                                -1, "sl",
              4,                                -1, "sl",
                    "l",
                    1,
                    5,
                          "l",
                          2,
                          6,
                                "l",
                                3,
                                7,

              "l",                              "l",
              4,                                0,
              5,                                0,
                    "l",                        "l",
                    4,                          1,
                    5,                          1,
                         "l",                   "l",
                          6,                    2,
                          7,                    2,
                               "l",             "l",
                                6,              3,
                                7,              3,
              8+0,
              8+0,
                    8+1,                        4,
                    8+1,                        4,
                          8+2,                  5,
                          8+2,                  5,
                                8+3,            6,
                                8+3,            6,

              8+0,                              7,
              8+4,                              7,
                    8+1,
                    8+5,
                          8+2,
                          8+6,
                                8+3,
                                8+7,
              "lrs",
              "lrs",
              8+4,                             8,
              8+5,                             8,
                    8+4,                       9,
                    8+5,                       9,
                          8+6,                 10,
                          8+7,                 10,
                                8+6,           11,
                                8+7,           11,
              "frs",
              "frs",
              16+0,
              16+0,
                    16+1,                      12,
                    16+1,                      12,
                          16+2,                13,
                          16+2,                13,
                                16+3,          14,
                                16+3,          14,

              "lrs",
              "lrs",
              16+0,                            15,
              16+4,                            15,
                    16+1,
                    16+5,
                          16+2,
                          16+6,
                                16+3,
                                16+7,
              "lrs",
              "lrs",
              16+4,                            16,
              16+5,                            16,
                    16+4,                      17,
                    16+5,                      17,
                          16+6,                18,
                          16+7,                18,
                                16+6,          19,
                                16+7,          19,
              "frs",
              "frs",
              24+0,
              24+0,
                    24+1,                      20,
                    24+1,                      20,
                          24+2,                21,
                          24+2,                21,
                                24+3,          22,
                                24+3,          22,

              24+0,                            23,
              24+4,                            23,
                    24+1,
                    24+5,
                          24+2,
                          24+6,
                                24+3,
                                24+7,
              24+4,                            24, "s",
              24+5,                            24, "s",
                    24+4,                      25, "s",
                    24+5,                      25, "s",
                          24+6,                26, "s",
                          24+7,                26, "s",
                                24+6,          27, "s",
                                24+7,          27, "s",
             ] },

           # INDEX 12
           # Variant of 11, avoiding blocks with 2x mul, 2x add, 2x str
           12 : { "load_order": [14, 15, 12,13, 8,9,10, 11, 6,7,4,5,0,1,2,3], # Load order
             "store_order": [5,4,7,6,3,2,1,0,9,8,11,10,13,12,15,14],
             "numbering": list(zip(
                [6,  7,  4, 5, 0,1, 2, 3, 2,3,0,1,10,11, 8, 9, 4,5,0,1, 8, 9,12,13, 4,6,2,0, 8,10,12,14],
                [14, 15, 12,13,8,9,10,11, 6,7,4,5,14,15,12,13, 6,7,2,3,10,11,14,15, 5,7,3,1, 9,11,13,15],
                [0, 0, 0, 0, 0, 0, 0, 0,  1,1,1,1, 2, 2, 2, 2, 4,4,3,3, 5, 5, 6, 6, 9,10,8,7,11,12,13,14])),
             "schedule": ["m", "frl",

              "l",
              "lrs",
              "lrs",
              0,                                "sl",
              0,                                "sl",
                    "l",
                    1,                          -4, "sl",
                    1,                          -4,
                          "l",
                          2,                    -3, "sl",
                          2,                    -3,
                                "l",
                                3,              -2, "sl",
                                3,              -2,

              "l",
              0,                                -1, "sl",
              4,                                -1,
                    "l",
                    1,                          "sl",
                    5,
                          "l",
                          2,                    "sl",
                          6,
                                "l",
                                3,              "sl",
                                7,

              "l",                              "l",
              4,                                0, "sl",
              5,                                0,
                    "l",                        "l",
                    4,                          1,
                    5,                          1,
                         "l",                   "l",
                          6,                    2,
                          7,                    2,
                               "l",             "l",
                                6,              3,
                                7,              3,
              8+0,
              8+0,
                    8+1,                        4,
                    8+1,                        4,
                          8+2,                  5,
                          8+2,                  5,
                                8+3,            6,
                                8+3,            6,

              8+0,                              7,
              8+4,                              7,
                    8+1,
                    8+5,
                          8+2,
                          8+6,
                                8+3,
                                8+7,
              "lrs",
              "lrs",
              8+4,                             8,
              8+5,                             8,
                    8+4,                       9,
                    8+5,                       9,
                          8+6,                 10,
                          8+7,                 10,
                                8+6,           11,
                                8+7,           11,
              "frs",
              "frs",
              16+0,
              16+0,
                    16+1,                      12,
                    16+1,                      12,
                          16+2,                13,
                          16+2,                13,
                                16+3,          14,
                                16+3,          14,

              "lrs",
              "lrs",
              16+0,                            15,
              16+4,                            15,
                    16+1,
                    16+5,
                          16+2,
                          16+6,
                                16+3,
                                16+7,
              "lrs",
              "lrs",
              16+4,                            16,
              16+5,                            16,
                    16+4,                      17,
                    16+5,                      17,
                          16+6,                18,
                          16+7,                18,
                                16+6,          19,
                                16+7,          19,
              "frs",
              "frs",
              24+0,
              24+0,
                    24+1,                      20,
                    24+1,                      20,
                          24+2,                21,
                          24+2,                21,
                                24+3,          22,
                                24+3,          22,
              "frs",
              "frs",

              24+0,                            23,
              24+4,                            23,
                    24+1,                      24,
                    24+5,                      24,
                          24+2,                25,
                          24+6,                25,
                                24+3,          26,
                                24+7,          26,

              24+4,                            27,
              24+5,                            27,
                    24+4,                      "s",
                    24+5,                      "s",
                          24+6,                "s",
                          24+7,                "s",
                                24+6,          "s",
                                24+7,          "s",
             ] },

           # INDEX 13
           13 : { "load_order": [14, 15, 12,13, 8,9,10, 11, 6,7,4,5,0,1,2,3], # Load order
               "store_order": [5,4,7,6,3,2,1,0,9,8,11,10,13,12,15,14],
               "numbering": list(zip(
                [6,  7,  4, 5, 0,1, 2, 3, 2,3,0,1,10,11, 8, 9, 4,5,0,1, 8, 9,12,13, 4,6,2,0, 8,10,12,14],
                [14, 15, 12,13,8,9,10,11, 6,7,4,5,14,15,12,13, 6,7,2,3,10,11,14,15, 5,7,3,1, 9,11,13,15],
                [0, 0, 0, 0, 0, 0, 0, 0,  1,1,1,1, 2, 2, 2, 2, 4,4,3,3, 5, 5, 6, 6, 9,10,8,7,11,12,13,14])),
             "schedule": ["m", "frl",

              "l",
              "lrs",
              0,                                "sl",
              0,                                "sl",
                    "l",
                    1,                          -4, "sl",
                    1,                          -4,
                          "l",
                          2,                    -3, "sl",
                          2,                    -3,
                                "l",
                                3,              -2, "sl",
                                3,              -2,

              "l",
              0,                                -1, "sl",
              4,                                -1,
                    "l",
                    1,                          "sl",
                    5,
                          "l",
                          2,                    "sl",
                          6,
                                "l",
                                3,              "sl",
                                7,

              "l",                              "l",
              4,                                0, "sl",
              5,                                0,
                    "l",                        "l",
                    4,                          1,
                    5,                          1,
                         "l",                   "l",
                          6,                    2,
                          7,                    2,
                               "l",             "l",
                                6,              3,
                                7,              3,
              8+0,
              8+0,
                    8+1,                        4,
                    8+1,                        4,
                          8+2,                  5,
                          8+2,                  5,
                                8+3,            6,
                                8+3,            6,

              "lrs",
              8+0,                              7,
              8+4,                              7,
                   "lrs",
                    8+1,
                    8+5,
                          8+2,
                          8+6,
                                8+3,
                                8+7,
              8+4,                             8,
              8+5,                             8,
                    8+4,                       9,
                    8+5,                       9,
                          8+6,                 10,
                          8+7,                 10,
                                8+6,           11,
                                8+7,           11,
              "frs",
              "frs",
              16+0,
              16+0,
                    16+1,                      12,
                    16+1,                      12,
                          16+2,                13,
                          16+2,                13,
                                16+3,          14,
                                16+3,          14,

              "lrs",
              16+0,                            15,
              16+4,                            15,
                    16+1,
                    16+5,
                         "lrs",
                          16+2,
                          16+6,
                                "lrs",
                                16+3,
                                16+7,
              "lrs",
              16+4,                            16,
              16+5,                            16,
                    16+4,                      17,
                    16+5,                      17,
                          16+6,                18,
                          16+7,                18,
                                16+6,          19,
                                16+7,          19,
              "frs",
              "frs",
              24+0,
              24+0,
                    24+1,                      20,
                    24+1,                      20,
                          24+2,                21,
                          24+2,                21,
                                24+3,          22,
                                24+3,          22,
              "frs",
              "frs",

              24+0,                            23,
              24+4,                            23,
                    24+1,                      24,
                    24+5,                      24,
                          24+2,                25,
                          24+6,                25,
                                24+3,          26,
                                24+7,          26,

              "lre",
              24+4,                            27,
              24+5,                            27,
                    24+4,                      "s",
                    24+5,                      "s",
                          24+6,                "s",
                          24+7,                "s",
                                24+6,          "s",
                                24+7,          "s",
             ] },

           # INDEX 14
           # Variant of 12, insert some NOPs
           14 : { "load_order": [14, 15, 12,13, 8,9,10, 11, 6,7,4,5,0,1,2,3], # Load order
                  "store_order": [5,4,7,6,3,2,1,0,9,8,11,10,13,12,15,14],
                  "numbering": list(zip(
                      [6,  7,  4, 5, 0,1, 2, 3, 2,3,0,1,10,11, 8, 9, 4,5,0,1, 8, 9,12,13, 6,4,2,0, 8,10,12,14],
                      [14, 15, 12,13,8,9,10,11, 6,7,4,5,14,15,12,13, 6,7,2,3,10,11,14,15, 7,5,3,1, 9,11,13,15],
                      [0, 0, 0, 0, 0, 0, 0, 0,  1,1,1,1, 2, 2, 2, 2, 4,4,3,3, 5, 5, 6, 6, 10,9,8,7,11,12,13,14])),
                  "schedule":
             ["m", "frl",
              "l",
              "lrs",
              "lrs",
              0,                                "sl",
              0,                                "sl",
                    "l",
                    1,                          -4, "sl",
                    1,                          -4,
                          "l",
                          2,                    -3, "sl",
                          2,                    -3,
                                "l",
                                3,              -2, "sl",
                                3,              -2,

              "l",
              0,                                -1, "sl",
              4,                                -1,
                    "l",
                    1,                          "sl",
                    5,                          "nop",
                          "l",
                          2,                    "sl",
                          6,                    "nop",
                                "l",
                                3,              "sl",
                                7,              "nop",

              "l",                              "l",
              4,                                0, "sl",
              5,                                0,
                    "l",                        "l",
                    4,                          1,
                    5,                          1,
                         "l",                   "l",
                          6,                    2,
                          7,                    2,
                               "l",             "l",
                                6,              3,
                                7,              3,
              8+0,                              "nop",
              8+0,                              "nop",
                    8+1,                        4,
                    8+1,                        4,
                          8+2,                  5,
                          8+2,                  5,
                                8+3,            6,
                                8+3,            6,

              8+0,                              7,
              8+4,                              7,
                    8+1,                        "nop",
                    8+5,                        "nop",
                          8+2,                  "nop",
                          8+6,                  "nop",
                                8+3,            "nop",
                                8+7,            "nop",
              "lrs",
              "lrs",
              8+4,                             8,
              8+5,                             8,
                    8+4,                       9,
                    8+5,                       9,
                          8+6,                 10,
                          8+7,                 10,
                                8+6,           11,
                                8+7,           11,
              "frs",
              "frs",
              16+0,                            "nop",
              16+0,                            "nop",
                    16+1,                      12,
                    16+1,                      12,
                          16+2,                13,
                          16+2,                13,
                                16+3,          14,
                                16+3,          14,

              "lrs",
              "lrs",
              16+0,                            15,
              16+4,                            15,
                    16+1,                      "nop",
                    16+5,                      "nop",
                          16+2,                "nop",
                          16+6,                "nop",
                                16+3,          "nop",
                                16+7,          "nop",
              "lrs",
              "lrs",
              16+4,                            16,
              16+5,                            16,
                    16+4,                      17,
                    16+5,                      17,
                          16+6,                18,
                          16+7,                18,
                                16+6,          19,
                                16+7,          19,
              "frs",
              "frs",
              24+0,                            "nop",
              24+0,                            "nop",
                    24+1,                      20,
                    24+1,                      20,
                          24+2,                21,
                          24+2,                21,
                                24+3,          22,
                                24+3,          22,
              "frs",
              "frs",

              24+0,                            23,
              24+4,                            23,
                    24+1,                      24,
                    24+5,                      24,
                          24+2,                25,
                          24+6,                25,
                                24+3,          26,
                                24+7,          26,

              24+4,                            27,
              24+5,                            27,
                    24+4,                      "s",
                    24+5,                      "s",
                          24+6,                "s",
                          24+7,                "s",
                                24+6,          "s",
                                24+7,          "s",
             ] },

           # INDEX 15
           # Different butterfly ordering
           15 : { "load_order":  [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "store_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "numbering":   list(zip(
              [ 7,  6,  5,  4,  3,  2, 1, 0, 11,10, 9, 8,3,2,1,0, 13,12, 9, 8,5,4,1,0, 14, 12, 10, 8, 6, 4, 2, 0],
              [15, 14, 13, 12, 11, 10, 9, 8, 15,14,13,12,7,6,5,4, 15,14,11,10,7,6,3,2, 15, 13, 11, 9, 7, 5, 3, 1],
              [ 0,  0,  0,  0,  0,  0, 0, 0,  2, 2, 2, 2,1,1,1,1,  6, 6, 5, 5,4,4,3,3, 14, 13, 12,11,10, 9, 8, 7])),
            "root_load_order": [0,1,3,2], # Root load order
            "schedule":
             ["m", "frl",

              "l",
              "lrs",
              "lrs",
              0,                                "sl",
              0,                                "sl",
                    "l",
                    1,                          -4, "sl",
                    1,                          -4,
                          "l",
                          2,                    -3, "sl",
                          2,                    -3,
                                "l",
                                3,              -2, "sl",
                                3,              -2,

              "l",
              0,                                -1, "sl",
              4,                                -1,
                    "l",
                    1,                          "sl",
                    5,                          "nop",
                          "l",
                          2,                    "sl",
                          6,                    "nop",
                                "l",
                                3,              "sl",
                                7,              "nop",

              "l",                              "l",
              4,                                0, "sl",
              5,                                0,
                    "l",                        "l",
                    4,                          1,
                    5,                          1,
                         "l",                   "l",
                          6,                    2,
                          7,                    2,
                               "l",             "l",
                                6,              3,
                                7,              3,
              8+0,                              "nop",
              8+0,                              "nop",
                    8+1,                        4,
                    8+1,                        4,
                          8+2,                  5,
                          8+2,                  5,
                                8+3,            6,
                                8+3,            6,

              8+0,                              7,
              8+4,                              7,
                    8+1,                        "nop",
                    8+5,                        "nop",
                          8+2,                  "nop",
                          8+6,                  "nop",
                                8+3,            "nop",
                                8+7,            "nop",
              "lrs",
              "lrs",
              8+4,                             8,
              8+5,                             8,
                    8+4,                       9,
                    8+5,                       9,
                          8+6,                 10,
                          8+7,                 10,
                                8+6,           11,
                                8+7,           11,
              "frs",
              "frs",
              16+0,                            "nop",
              16+0,                            "nop",
                    16+1,                      12,
                    16+1,                      12,
                          16+2,                13,
                          16+2,                13,
                                16+3,          14,
                                16+3,          14,

              "lrs",
              "lrs",
              16+0,                            15,
              16+4,                            15,
                    16+1,                      "nop",
                    16+5,                      "nop",
                          16+2,                "nop",
                          16+6,                "nop",
                                16+3,          "nop",
                                16+7,          "nop",
              "lrs",
              "lrs",
              16+4,                            16,
              16+5,                            16,
                    16+4,                      17,
                    16+5,                      17,
                          16+6,                18,
                          16+7,                18,
                                16+6,          19,
                                16+7,          19,
              "frs",
              "frs",
              24+0,                            "nop",
              24+0,                            "nop",
                    24+1,                      20,
                    24+1,                      20,
                          24+2,                21,
                          24+2,                21,
                                24+3,          22,
                                24+3,          22,
              "frs",
              "frs",

              24+0,                            23,
              24+4,                            23,
                    24+1,                      24,
                    24+5,                      24,
                          24+2,                25,
                          24+6,                25,
                                24+3,          26,
                                24+7,          26,

              24+4,                            27,
              24+5,                            27,
                    24+4,                      "s",
                    24+5,                      "s",
                          24+6,                "s",
                          24+7,                "s",
                                24+6,          "s",
                                24+7,          "s",
             ] },

           # INDEX 16
           # Different butterfly ordering
           16 : { "load_order":  [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "store_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "numbering":   list(zip(
              [ 7,  6,  5,  4,  3,  2, 1, 0, 11,10,3,2, 9, 8,1,0, 13, 9,5,1,12, 8,4,0, 14, 12, 10, 8, 6, 4, 2, 0],
              [15, 14, 13, 12, 11, 10, 9, 8, 15,14,7,6,13,12,5,4, 15,11,7,3,14,10,6,2, 15, 13, 11, 9, 7, 5, 3, 1],
              [ 0,  0,  0,  0,  0,  0, 0, 0,  2, 2,1,1, 2, 2,1,1,  6, 5,4,3, 6, 5,4,3, 14, 13, 12,11,10, 9, 8, 7])),
                  "root_load_order": [0,1,3,2], # Root load order
                  "schedule":
             ["m", "frl",

              "l",
              "lrs",
              "lrs",
              0,                                "sl",
              0,                                "sl",
                    "l",
                    1,                          -4, "sl",
                    1,                          -4,
                          "l",
                          2,                    -3, "sl",
                          2,                    -3,
                                "l",
                                3,              -2, "sl",
                                3,              -2,

              "l",
              0,                                -1, "sl",
              4,                                -1,
                    "l",
                    1,                          "sl",
                    5,                          "nop",
                          "l",
                          2,                    "sl",
                          6,                    "nop",
                                "l",
                                3,              "nop",
                                7,              "sl",

              "l",                              "l",
              4,                                0, "sl",
              5,                                0,
                    "l",                        "l",
                    4,                          1,
                    5,                          1,
                         "l",                   "l",
                          6,                    2,
                          7,                    2,
                               "l",             "l",
                                6,              3,
                                7,              3,
              8+0,                              "nop",
              8+0,                              "nop",
                    8+1,                        4,
                    8+1,                        4,
                          8+2,                  5,
                          8+2,                  5,
                                8+3,            6,
                                8+3,            6,

              8+0,                              7,
              8+4,                              7,
                    8+1,                        "nop",
                    8+5,                        "nop",
                          8+2,                  "nop",
                          8+6,                  "nop",
                                8+3,            "nop",
                                8+7,            "nop",
              "lrs",
              "lrs",
              8+4,                             8,
              8+5,                             8,
                    8+4,                       9,
                    8+5,                       9,
                          8+6,                 10,
                          8+7,                 10,
                                8+6,           11,
                                8+7,           11,
              "frs",
              "frs",
              16+0,                            "nop",
              16+0,                            "nop",
                    16+1,                      12,
                    16+1,                      12,
                          16+2,                13,
                          16+2,                13,
                                16+3,          14,
                                16+3,          14,

              "lrs",
              "lrs",
              16+0,                            15,
              16+4,                            15,
                    16+1,                      "nop",
                    16+5,                      "nop",
                          16+2,                "nop",
                          16+6,                "nop",
                                16+3,          "nop",
                                16+7,          "nop",
              "lrs",
              "lrs",
              16+4,                            16,
              16+5,                            16,
                    16+4,                      17,
                    16+5,                      17,
                          16+6,                18,
                          16+7,                18,
                                16+6,          19,
                                16+7,          19,
              "frs",
              "frs",
              24+0,                            "nop",
              24+0,                            "nop",
                    24+1,                      20,
                    24+1,                      20,
                          24+2,                21,
                          24+2,                21,
                                24+3,          22,
                                24+3,          22,
              "frs",
              "frs",

              24+0,                            23,
              24+4,                            23,
                    24+1,                      24,
                    24+5,                      24,
                          24+2,                25,
                          24+6,                25,
                                24+3,          26,
                                24+7,          26,

              24+4,                            27,
              24+5,                            27,
                    24+4,                      "s",
                    24+5,                      "s",
                          24+6,                "s",
                          24+7,                "s",
                                24+6,          "s",
                                24+7,          "s",
             ] },

           # INDEX 17
           # Different butterfly ordering, space out non-MUL ops
           17 : { "load_order":  [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "store_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "numbering": list(zip(
              [ 7,  6,  5,  4,  3,  2, 1, 0, 11,10,3,2, 9, 8,1,0, 13, 9,5,1,12, 8,4,0, 14, 12, 10, 8, 6, 4, 2, 0],
              [15, 14, 13, 12, 11, 10, 9, 8, 15,14,7,6,13,12,5,4, 15,11,7,3,14,10,6,2, 15, 13, 11, 9, 7, 5, 3, 1],
              [ 0,  0,  0,  0,  0,  0, 0, 0,  2, 2,1,1, 2, 2,1,1,  6, 5,4,3, 6, 5,4,3, 14, 13, 12,11,10, 9, 8, 7])),
            "root_load_order": [0,1,3,2], # Root load order
            "schedule": ["m", "frl",

              "l",
              0,                                "sl",
              0,                                -4,
                    "l",
                    1,                          "sl",
                    1,                          -4,
                          "l",
                          2,                    "sl",
                          2,                    -3,
                                "l",
                                3,              "sl",
                                3,              -3,

              "l",
              0,                                "sl",
              4,                                -2,
                    "l",
                    1,                          "sl",
                    5,                          -2,
                          "l",
                          2,                    "sl",
                          6,                    -1,
                                "l",
                                3,              "sl",
                                7,              -1,

              "l",                              "l",
              4,                                0,
              5,                                0,
                    "l",                        "l",
                    4,                          1,
                    5,                          1,
                         "l",                   "l",
                          6,                    2,
                          7,                    2,
                               "l",             "l",
                                6,              3,
                                7,              3,
              8+0,                              "nop",
              8+0,                              "nop",
                    8+1,                        4,
                    8+1,                        4,
                          8+2,                  5,
                          8+2,                  5,
                                8+3,            6,
                                8+3,            6,

              8+0,                              7,
              8+4,                              7,
                    8+1,                        "sl",
                    8+5,                        "nop",
                          8+2,                  "sl",
                          8+6,                  "nop",
                                8+3,            "nop",
                                8+7,            "nop",
              "lrs",
              "lrs",
              8+4,                             8,
              8+5,                             8,
                    8+4,                       9,
                    8+5,                       9,
                          8+6,                 10,
                          8+7,                 10,
                                8+6,           11,
                                8+7,           11,
              "frs",
              "frs",
              16+0,                            "nop",
              16+0,                            "nop",
                    16+1,                      12,
                    16+1,                      12,
                          16+2,                13,
                          16+2,                13,
                                16+3,          14,
                                16+3,          14,

              "lrs",
              "lrs",
              16+0,                            15,
              16+4,                            15,
                    16+1,                      "nop",
                    16+5,                      "nop",
                          16+2,                "nop",
                          16+6,                "nop",
                                16+3,          "nop",
                                16+7,          "nop",
              "lrs",
              "lrs",
              16+4,                            16,
              16+5,                            16,
                    16+4,                      17,
                    16+5,                      17,
                          16+6,                18,
                          16+7,                18,
                                16+6,          19,
                                16+7,          19,
              "frs",
              "frs",
              24+0,                            "nop",
              24+0,                            "nop",
                    24+1,                      20,
                    24+1,                      20,
                          24+2,                21,
                          24+2,                21,
                                24+3,          22,
                                24+3,          22,
              "frs",
              "frs",

              24+0,                            23,
              24+4,                            23,
                    24+1,                      24,
                    24+5,                      24,
                          24+2,                25,
                          24+6,                25,
                                24+3,          26,
                                24+7,          26,

              24+4,                            27, "lres",
              24+5,                            27, "lres",
                    24+4,                      "s",
                    24+5,                      "s",
                          24+6,                "s",
                          24+7,                "s",
                                24+6,          "s",
                                24+7,          "s",
             ] },

           # INDEX 18
           # Based on 17, change interleaving to always have 2x MULs next to each other
           18 : { "load_order":  [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "store_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "numbering": list(zip(
              [ 7,  6,  5,  4,  3,  2, 1, 0, 11,10,3,2, 9, 8,1,0, 13, 9,5,1,12, 8,4,0, 14, 12, 10, 8, 6, 4, 2, 0],
              [15, 14, 13, 12, 11, 10, 9, 8, 15,14,7,6,13,12,5,4, 15,11,7,3,14,10,6,2, 15, 13, 11, 9, 7, 5, 3, 1],
              [ 0,  0,  0,  0,  0,  0, 0, 0,  2, 2,1,1, 2, 2,1,1,  6, 5,4,3, 6, 5,4,3, 14, 13, 12,11,10, 9, 8, 7])),
              "root_load_order": [0,1,3,2], # Root load order
              "schedule": ["m", "frl",

              "l",
              0,0,                            "sl",
                                              -4,
                    "l",
                    1,1,                      "sl",
                                              -4,
                          "l",
                          2,2,                "sl",
                                              -3,
                                "l",
                                3,3,          "sl",
                                              -3,

              "l",
              4,0,                            "sl",
                                              -2,
                    "l",
                    5,1,                      "sl",
                                              -2,
                          "l",
                          6,2,                "sl",
                                              -1,
                                "l",
                                7,3,          "sl",
                                              -1,

              "l",                            "l",
              5,4,                            0,
                                              0,
                    "l",                      "l",
                    5,4,                      1,
                                              1,
                         "l",                 "l",
                          7,6,                2,
                                              2,
                               "l",           "l",
                                7,6,          3,
                                              3,
              8+0,8+0,                      4,
                                            "nop",
                    8+1,8+1,                4,
                                            "nop",
                          8+2,8+2,          5,
                                            5,
                                8+3,8+3,    6,
                                            6,

              8+4,8+0,                      7,
                                            "sl",
                    8+5,8+1,                7,
                                            "nop",
                          8+6,8+2,          "sl",
                                            "nop",
                                8+7,8+3,    "nop",
                                            "nop",
              "lrs",
              "lrs",
              8+5,8+4,                      8,
                                            8,
                    8+5,8+4,                9,
                                            9,
                          8+7,8+6,          10,
                                            10,
                                8+7,8+6,    11,
                                            11,
              "frs",
              "frs",
              16+0,16+0,                    "nop",
                                            "nop",
                    16+1,16+1,              12,
                                            12,
                          16+2,16+2,        13,
                                            13,
                                16+3,16+3,  14,
                                            14,

              "lrs",
              "lrs",
              16+4,16+0,                    15,
                                            15,
                    16+5,16+1,              "nop",
                                            "nop",
                          16+6,16+2,        "nop",
                                            "nop",
                                16+7,16+3,  "nop",
                                            "nop",
              "lrs",
              "lrs",
              16+5,16+4,                    16,
                                            16,
                    16+5,16+4,              17,
                                            17,
                          16+7,16+6,        18,
                                            18,
                                16+7,16+6,  19,
                                            19,
              "frs",
              "frs",
              24+0,24+0,                    "nop",
                                            "nop",
                    24+1,24+1,              20,
                                            20,
                          24+2,24+2,        21,
                                            21,
                                24+3,24+3,  22,
                                            22,
              "frs",
              "frs",

              24+4,24+0,                    23,
                                            23,
                    24+5,24+1,              24,
                                            "s",
                          24+6,24+2,        24,
                                            "s",
                                24+7,24+3,  25,
                                            "s",

              24+5,24+4,                    25, "lres",
                                            26, "lres",
                    24+5,24+4,              26,
                                            "s",
                          24+7,24+6,        27,
                                            "s",
                                24+7,24+6,  27,
                                            "s",

              # 24+4,24+0,                    23,
              #                               23,
              #       24+5,24+1,              24,
              #                               "s",
              #             24+6,24+2,        24,
              #                               "s",
              #                   24+7,24+3,  25,
              #                               "s",

              # 24+5,24+4,                    25,  "lres",
              #                               "s", "lres",
              #       24+5,24+4,              26,
              #                               "s",
              #             24+7,24+6,        27,
              #                               "s",
              #                   24+7,24+6,  27,
              #                               "nop",

             ] },

           # INDEX 19
           # Based on 18, but minor changes wrt placement of nop's.
           19 : { "load_order":  [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "store_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "numbering": list(zip(
              [ 7,  6,  5,  4,  3,  2, 1, 0, 11,10,3,2, 9, 8,1,0, 13, 9,5,1,12, 8,4,0, 14, 12, 10, 8, 6, 4, 2, 0],
              [15, 14, 13, 12, 11, 10, 9, 8, 15,14,7,6,13,12,5,4, 15,11,7,3,14,10,6,2, 15, 13, 11, 9, 7, 5, 3, 1],
              [ 0,  0,  0,  0,  0,  0, 0, 0,  2, 2,1,1, 2, 2,1,1,  6, 5,4,3, 6, 5,4,3, 14, 13, 12,11,10, 9, 8, 7])),
              "root_load_order": [0,1,3,2], # Root load order
              "schedule": ["m", "frl",

              "l",
              0,0,                            "sl",
                                              -4,
                    "l",
                    1,1,                      "sl",
                                              -4,
                          "l",
                          2,2,                "sl",
                                              -3,
                                "l",
                                3,3,          "sl",
                                              -3,

              "l",
              4,0,                            "sl",
                                              -2,
                    "l",
                    5,1,                      "sl",
                                              -2,
                          "l",
                          6,2,                "sl",
                                              -1,
                                "l",
                                7,3,          "sl",
                                              -1,

              "l",                            "l",
              5,4,                            0,
                                              0,
                    "l",                      "l",
                    5,4,                      1,
                                              1,
                         "l",                 "l",
                          7,6,                2,
                                              2,
                               "l",           "l",
                                7,6,          3,
                                              3,
              8+0,8+0,                      4,
                                            "nop",
                    8+1,8+1,                4,
                                            "nop",
                          8+2,8+2,          5,
                                            5,
                                8+3,8+3,    6,
                                            6,

              8+4,8+0,                      7,
                                            "sl",
                    8+5,8+1,                7,
                                            "nop",
                          8+6,8+2,          "sl",
                                            "nop",
                                8+7,8+3,    "nop",
                                            "nop",
              "lrs",
              "lrs",
              8+5,8+4,                      8,
                                            8,
                    8+5,8+4,                9,
                                            9,
                          8+7,8+6,          10,
                                            10,
                                8+7,8+6,    11,
                                            11,
              "frs",
              "frs",
              16+0,16+0,                    12,
                                            12,
                    16+1,16+1,              13,
                                            13,
                          16+2,16+2,        14,
                                            14,
                                16+3,16+3,  15,
                                            15,

              "lrs",
              "lrs",
              16+4,16+0,                    "nop",
                                            "nop",
                    16+5,16+1,              "nop",
                                            "nop",
                          16+6,16+2,        "nop",
                                            "nop",
                                16+7,16+3,  "nop",
                                            "nop",
              "lrs",
              "lrs",
              16+5,16+4,                    16,
                                            16,
                    16+5,16+4,              17,
                                            17,
                          16+7,16+6,        18,
                                            18,
                                16+7,16+6,  19,
                                            19,
              "frs",
              "frs",
              24+0,24+0,                    20,
                                            20,
                    24+1,24+1,              21,
                                            21,
                          24+2,24+2,        22,
                                            22,
                                24+3,24+3,  23,
                                            23,
              "frs",
              "frs",

              24+4,24+0,                    "nop",
                                            "nop",
                    24+5,24+1,              24,
                                            "s",
                          24+6,24+2,        24,
                                            "s",
                                24+7,24+3,  25,
                                            "s",

              24+5,24+4,                    25, "lres",
                                            26, "lres",
                    24+5,24+4,              26,
                                            "s",
                          24+7,24+6,        27,
                                            "s",
                                24+7,24+6,  27,
                                            "s",

             ] },

           # INDEX 20
           # Based on 19, trying to balance issue queues a bit better
           # by extending the overlapping of iterations. This takes off
           # pressure from the add/sub issue queue, but increases load
           # load of the mul issue queues
           20 : { "load_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "store_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "numbering": list(zip(
              [ 7,  6,  5,  4,  3,  2, 1, 0, 11,10,3,2, 9, 8,1,0, 13, 9,5,1,12, 8,4,0, 14, 12, 10, 8, 6, 4, 2, 0],
              [15, 14, 13, 12, 11, 10, 9, 8, 15,14,7,6,13,12,5,4, 15,11,7,3,14,10,6,2, 15, 13, 11, 9, 7, 5, 3, 1],
              [ 0,  0,  0,  0,  0,  0, 0, 0,  2, 2,1,1, 2, 2,1,1,  6, 5,4,3, 6, 5,4,3, 14, 13, 12,11,10, 9, 8, 7])),
                  "root_load_order": [0,1,3,2], # Root load order
                  "schedule":
             ["m", "frl",

              "l",
              0,0,                            -6,
                                              "sl",
                    "l",
                    1,1,                      -5,
                                              "sl",
                          "l",
                          2,2,                -5,
                                              "sl",
                                "l",
                                3,3,          "sl",
                                              -4,

              "l",
              4,0,                            "sl",
                                              -4,
                    "l",
                    5,1,                      "sl",
                                              -3,
                          "l",
                          6,2,                "sl",
                                              -3,
                                "l",
                                7,3,          "sl",
                                              -2,

              "l",                            "l",
              5,4,                            "sl",
                                              -2,
                    "l",                      "l",
                    5,4,                      "sl",
                                              -1,
                         "l",                 "l",
                          7,6,                "sl",
                                              -1,
                               "l",           "l",
                                7,6,          0,
                                              0,
              8+0,8+0,                      1,
                                            1,
                    8+1,8+1,                2,
                                            2,
                          8+2,8+2,          3,
                                            3,
                                8+3,8+3,    4,
                                            4,

              8+4,8+0,                      5,
                                            5,
                    8+5,8+1,                6,
                                            6,
                          8+6,8+2,          7,
                                            "sl",
                                8+7,8+3,    7,
                                            "sl",
              "lrs",
              "lrs",
              8+5,8+4,                      8,
                                            8,
                    8+5,8+4,                9,
                                            9,
                          8+7,8+6,          10,
                                            10,
                                8+7,8+6,    11,
                                            11,
              "frs",
              "frs",
              16+0,16+0,                    12,
                                            12,
                    16+1,16+1,              13,
                                            13,
                          16+2,16+2,        14,
                                            14,
                                16+3,16+3,  15,
                                            15,

              "lrs",
              "lrs",
              16+4,16+0,                    "nop",
                                            "nop",
                    16+5,16+1,              "nop",
                                            "nop",
                          16+6,16+2,        "nop",
                                            "nop",
                                16+7,16+3,  "nop",
                                            "nop",
              "lrs",
              "lrs",
              16+5,16+4,                    16,
                                            16,
                    16+5,16+4,              17,
                                            17,
                          16+7,16+6,        18,
                                            18,
                                16+7,16+6,  19,
                                            19,
              "frs",
              "frs",
              24+0,24+0,                    20,
                                            20,
                    24+1,24+1,              21,
                                            21,
                          24+2,24+2,        22,
                                            22,
                                24+3,24+3,  23,
                                            23,
              "frs",
              "frs",

              24+4,24+0,                    "nop",
                                            "nop",
                    24+5,24+1,              "nop",
                                            "nop",
                          24+6,24+2,        "nop",
                                            "nop",
                                24+7,24+3,  "nop",
                                            "nop",
              24+5,24+4,                    24,
                                            "s",
                    24+5,24+4,              24,
                                            "s",
                          24+7,24+6,        25,
                                            "s",
                                24+7,24+6,  25, "lres",
                                            26, "lres",

             ] },

           # INDEX 21
           # Based on 20, swapping some ADD/SUB and late stores
           21 : { "load_order":  [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "store_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
                  "numbering":  list(zip(
              [ 7,  6,  5,  4,  3,  2, 1, 0, 11,10,3,2, 9, 8,1,0, 13, 9,5,1,12, 8,4,0, 14, 12, 10, 8, 6, 4, 2, 0],
              [15, 14, 13, 12, 11, 10, 9, 8, 15,14,7,6,13,12,5,4, 15,11,7,3,14,10,6,2, 15, 13, 11, 9, 7, 5, 3, 1],
              [ 0,  0,  0,  0,  0,  0, 0, 0,  2, 2,1,1, 2, 2,1,1,  6, 5,4,3, 6, 5,4,3, 14, 13, 12,11,10, 9, 8, 7])),
                  "root_load_order": [0,1,3,2], # Root load order
                  "schedule":
             ["m", "frl",

              "l",
              0,0,                            -6,
                                              "sl",
                    "l",
                    1,1,                      -5,
                                              "sl",
                          "l",
                          2,2,                -5,
                                              "sl",
                                "l",
                                3,3,          "sl",
                                              -4,

              "l",
              4,0,                            -4,
                                              "sl",
                    "l",
                    5,1,                      -3,
                                              "sl",
                          "l",
                          6,2,                -3,
                                              "sl",
                                "l",
                                7,3,          -2,
                                              "sl",

              "l",                            "l",
              5,4,                            -2,
                                              "sl",
                    "l",                      "l",
                    5,4,                      -1,
                                              "sl",
                         "l",                 "l",
                          7,6,                -1,
                                              "sl",
                               "l",           "l",
                                7,6,          0,
                                              0,
              8+0,8+0,                      1,
                                            1,
                    8+1,8+1,                2,
                                            2,
                          8+2,8+2,          3,
                                            3,
                                8+3,8+3,    4,
                                            4,

              8+4,8+0,                      5,
                                            5,
                    8+5,8+1,                6,
                                            6,
                          8+6,8+2,          "sl",
                                            7,
                                8+7,8+3,    "sl",
                                            7,
              "lrs",
              "lrs",
              8+5,8+4,                      8,
                                            8,
                    8+5,8+4,                9,
                                            9,
                          8+7,8+6,          10,
                                            10,
                                8+7,8+6,    11,
                                            11,
              "frs",
              "frs",
              16+0,16+0,                    12,
                                            12,
                    16+1,16+1,              13,
                                            13,
                          16+2,16+2,        14,
                                            14,
                                16+3,16+3,  15,
                                            15,

              "lrs",
              "lrs",
              16+4,16+0,                    "nop",
                                            "nop",
                    16+5,16+1,              "nop",
                                            "nop",
                          16+6,16+2,        "nop",
                                            "nop",
                                16+7,16+3,  "nop",
                                            "nop",
              "lrs",
              "lrs",
              16+5,16+4,                    16,
                                            16,
                    16+5,16+4,              17,
                                            17,
                          16+7,16+6,        18,
                                            18,
                                16+7,16+6,  19,
                                            19,
              "frs",
              "frs",
              24+0,24+0,                    20,
                                            20,
                    24+1,24+1,              21,
                                            21,
                          24+2,24+2,        22,
                                            22,
                                24+3,24+3,  23,
                                            23,
              "frs",
              "frs",

              24+4,24+0,                    "nop",
                                            "nop",
                    24+5,24+1,              "nop",
                                            "nop",
                          24+6,24+2,        "nop",
                                            "nop",
                                24+7,24+3,  "nop",
                                            "nop",
              24+5,24+4,                    24,
                                            "s",
                    24+5,24+4,              24,
                                            "s",
                          24+7,24+6,        25,
                                            "s",
                                24+7,24+6,  25, "lres",
                                            26, "lres",

             ] },

           # INDEX 22
           # Omit some late stores to smoothen transition
           # to next layers.
           22 : {
             "load_order":  [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
             "store_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
             "store_order_last": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4],
             "numbering":   list(zip(
              [ 7,  6,  5,  4,  3,  2, 1, 0, 11,10,3,2, 9, 8,1,0, 13, 9,5,1,12, 8,4,0, 14, 12, 10, 8, 6, 4, 2, 0],
              [15, 14, 13, 12, 11, 10, 9, 8, 15,14,7,6,13,12,5,4, 15,11,7,3,14,10,6,2, 15, 13, 11, 9, 7, 5, 3, 1],
              [ 0,  0,  0,  0,  0,  0, 0, 0,  2, 2,1,1, 2, 2,1,1,  6, 5,4,3, 6, 5,4,3, 14, 13, 12,11,10, 9, 8, 7])),

             "root_load_order": [0,1,3,2], # Root load order

             "schedule":
               ["m", "frl",
              "l",
              0,0,                            -6,
                                              "sl",
                    "l",
                    1,1,                      -5,
                                              "sl",
                          "l",
                          2,2,                -5,
                                              "sl",
                                "l",
                                3,3,          -4,
                                              "sl",

              "l",
              4,0,                            -4,
                                              "sl",
                    "l",
                    5,1,                      -3,
                                              "sl",
                          "l",
                          6,2,                -3,
                                              "sl",
                                "l",
                                7,3,          -2,
                                              "sl",

              "l",                            -2,
              5,4,                            "l",
                                              "sl",
                    "l",                      "l",
                    5,4,                      "sl",
                                              -1,
                         "l",                 "l",
                          7,6,                "sl",
                                              -1,
                               "l",           "l",
                                7,6,          0,
                                              0,
              8+0,8+0,                      1,
                                            1,
                    8+1,8+1,                2,
                                            2,
                          8+2,8+2,          3,
                                            3,
                                8+3,8+3,    4,
                                            4,

              8+4,8+0,                      5,
                                            5,
                    8+5,8+1,                6,
                                            6,
                          8+6,8+2,          7,
                                            "sl",
                                8+7,8+3,    7,
                                            "sl",
              "lrs",
              "lrs",
              8+5,8+4,                      8,
                                            8,
                    8+5,8+4,                9,
                                            9,
                          8+7,8+6,          10,
                                            10,
                                8+7,8+6,    11,
                                            11,
              "frs",
              "frs",
              16+0,16+0,                    12,
                                            12,
                    16+1,16+1,              13,
                                            13,
                          16+2,16+2,        14,
                                            14,
                                16+3,16+3,  15,
                                            15,

              "lrs",
              "lrs",
              16+4,16+0,                    "nop",
                                            "nop",
                    16+5,16+1,              "nop",
                                            "nop",
                          16+6,16+2,        "nop",
                                            "nop",
                                16+7,16+3,  "nop",
                                            "nop",
              "lrs",
              "lrs",
              16+5,16+4,                    16,
                                            16,
                    16+5,16+4,              17,
                                            17,
                          16+7,16+6,        18,
                                            18,
                                16+7,16+6,  19,
                                            19,
              "frs",
              "frs",
              24+0,24+0,                    20,
                                            20,
                    24+1,24+1,              21,
                                            21,
                          24+2,24+2,        22,
                                            22,
                                24+3,24+3,  23,
                                            23,
              "frs",
              "frs",

              24+4,24+0,                    "nop",
                                            "nop",
                    24+5,24+1,              "nop",
                                            "nop",
                          24+6,24+2,        "nop",
                                            "nop",
                                24+7,24+3,  "nop",
                                            "nop",
              24+5,24+4,                    24,
                                            "s",
                    24+5,24+4,              24,
                                            "s",
                          24+7,24+6,        25,
                                            "s",
                                24+7,24+6,  25, "lres",
                                            26, "lres",

             ] },

           # INDEX 23
           # Omit some late stores to smoothen transition
           # to next layers.
           23 : {
             "load_order":  [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
             "store_order": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4,3,2,1,0],
             "store_order_last": [15, 14, 13,12, 11, 10, 9, 8, 7,6,5,4],
             "numbering":   list(zip(
              [ 7,  6,  5,  4,  3,  2, 1, 0, 11,10,3,2, 9, 8,1,0, 13, 9,5,1,12, 8,4,0, 14, 12, 10, 8, 6, 4, 2, 0],
              [15, 14, 13, 12, 11, 10, 9, 8, 15,14,7,6,13,12,5,4, 15,11,7,3,14,10,6,2, 15, 13, 11, 9, 7, 5, 3, 1],
              [ 0,  0,  0,  0,  0,  0, 0, 0,  2, 2,1,1, 2, 2,1,1,  6, 5,4,3, 6, 5,4,3, 14, 13, 12,11,10, 9, 8, 7])),

             "root_load_order": [0,1,3,2], # Root load order

             "schedule":
               ["m", "frl",
              "l",
              0,0,                            -6,
                                              "sl",
                    "l",
                    1,1,                      -5,
                                              "sl",
                          "l",
                          2,2,                -5,
                                              "sl",
                                "l",
                                3,3,          -4,
                                              "sl",

              "l",
              4,0,                            -4,
                                              "sl",
                    "l",
                    5,1,                      -3,
                                              "sl",
                          "l",
                          6,2,                -3,
                                              "sl",
                                "l",
                                7,3,          -2,
                                              "sl",

              "l",                            "l",
              5,4,                            -2,
                                              "sl",
                    "l",                      "l",
                    5,4,                      "sl",
                                              -1,
                         "l",                 "l",
                          7,6,                "sl",
                                              -1,
                               "l",           "l",
                                7,6,          0,
                                              0,
              8+0,8+0,                      1,
                                            1,
                    8+1,8+1,                2,
                                            2,
                          8+2,8+2,          3,
                                            3,
                                8+3,8+3,    4,
                                            4,

              8+4,8+0,                      5,
                                            5,
                    8+5,8+1,                6,
                                            6,
                          8+6,8+2,          7,
                                            "sl",
                                8+7,8+3,    7,
                                            "sl",
              "lrs",
              "lrs",
              8+5,8+4,                      8,
                                            8,
                    8+5,8+4,                9,
                                            9,
                          8+7,8+6,          10,
                                            10,
                                8+7,8+6,    11,
                                            11,
              "frs",
              "frs",
              16+0,16+0,                    12,
                                            12,
                    16+1,16+1,              13,
                                            13,
                          16+2,16+2,        14,
                                            14,
                                16+3,16+3,  15,
                                            15,

              "lrs",
              "lrs",
              16+4,16+0,                    "nop",
                                            "nop",
                    16+5,16+1,              "nop",
                                            "nop",
                          16+6,16+2,        "nop",
                                            "nop",
                                16+7,16+3,  "nop",
                                            "nop",
              "lrs",
              "lrs",
              16+5,16+4,                    16,
                                            16,
                    16+5,16+4,              17,
                                            17,
                          16+7,16+6,        18,
                                            18,
                                16+7,16+6,  19,
                                            19,
              "frs",
              "frs",
              24+0,24+0,                    20,
                                            20,
                    24+1,24+1,              21,
                                            21,
                          24+2,24+2,        22,
                                            22,
                                24+3,24+3,  23,
                                            23,
              "frs",
              "frs",

              24+4,24+0,                    "nop",
                                            "nop",
                    24+5,24+1,              "nop",
                                            "nop",
                          24+6,24+2,        "nop",
                                            "nop",
                                24+7,24+3,  "nop",
                                            "nop",
               24+5,24+4,                   24,
                                            "s",
                    24+5,24+4,              24,
                                            "s",
                          24+7,24+6,        25,
                                            "s",
                                24+7,24+6,  25, "lres",
                                            26, "lres",

             ] },

           # INDEX 24
           # Deliberately bad, bunch lots of MULs
           24 : { "schedule":
             ["m", "frl", "l", "l", "l", "l",
              "l", "l", "l", "l",
              "l", "l", "l", "l",
              "l", "l", "l", "l",

              0, 0, 0,
              1, 1, 1,
              2, 2, 2,
              3, 3, 3,
              4, 4, 4,
              5, 5, 5,
              6, 6, 6,
              7, 7, 7,
              0, 0,
              1, 1,
              2, 2,
              3, 3,
              4, 4,
              5, 5,
              6, 6,
              7, 7,

              8,  8,  8,
              9,  9,  9,
              10, 10, 10,
              11, 11, 11,
              12, 12, 12,
              13, 13, 13,
              14, 14, 14,
              15, 15, 15,
              8,  8,
              9,  9,
              10, 10,
              11, 11,
              12, 12,
              13, 13,
              14, 14,
              15, 15,


              16, 16, 16,
              17, 17, 17,
              18, 18, 18,
              19, 19, 19,
              20, 20, 20,
              21, 21, 21,
              22, 22, 22,
              23, 23, 23,
              16, 16,
              17, 17,
              18, 18,
              19, 19,
              20, 20,
              21, 21,
              22, 22,
              23, 23,

              24, 24, 24,
              25, 25, 25,
              26, 26, 26,
              27, 27, 27,
              28, 28, 28,
              29, 29, 29,
              30, 30, 30,
              31, 31, 31,
              24, 24,
              25, 25,
              26, 26,
              27, 27,
              28, 28,
              29, 29,
              30, 30,
              31, 31,

              "lre",

              "s", "s", "s", "s",
              "s", "s", "s", "s",
              "s", "s", "s", "s",
              "s", "s", "s", "s" ] },

        }

        modification = modifications[idx]

        # for k,v in modification.items():
        #     if not k in default.keys():
        #         raise Exception(f"Invalid modification: {k}")

        dic = { **default, **modification }

        dic["load_order_first"] = dic.get("load_order_first", dic["load_order"])
        dic["store_order_last"] = dic.get("store_order_last", dic["store_order"])

        return dic

    def run_schedule(self, ct_schedule,
                     last_butterfly_arr, butterfly_arr, next_butterfly_arr):

        # Process the operation array
        for op in ct_schedule:

#            print(f"OP: {op}")

            if not isinstance(op,tuple):
                op = (0,op)

            idx = op[0]
            op  = op[1]

            if last_butterfly_arr != None:
                last_butterfly = last_butterfly_arr[idx]
            else:
                last_butterfly = None

            if butterfly_arr != None:
                butterfly = butterfly_arr[idx]
            else:
                butterfly = None

            if next_butterfly_arr != None:
                next_butterfly = next_butterfly_arr[idx]
            else:
                next_butterfly = None

            # Progress one of the GS butterflies
            if isinstance(op,int):
                idx = op
                # Operation for current block of butterflies
                if butterfly != None and idx >= 0 and idx < butterfly.num_gs:
                    yield from self.progress_arithmetic(butterfly,idx)
                # Operation for last butterfly
                if last_butterfly != None and idx < 0:
                    idx += last_butterfly.num_gs
                    yield from self.progress_arithmetic(last_butterfly,idx)
            # Non GS operations (memory + transpose)
            elif isinstance(op,str):
                if op == "fnop":
                    if butterfly != None and last_butterfly == None:
                        yield "nop"
                elif op == "nop":
                    if butterfly != None:
                        yield "nop"
                elif op == "s":      # Store
                    yield from self.store_input(butterfly, last=(next_butterfly==None))
                elif op == "sl":   # Store late
                    yield from self.store_input(last_butterfly, last=(butterfly==None))
                elif op == "l":    # Load
                    yield from self.load_input(butterfly, first=(last_butterfly==None))
                elif op == "le":   # Load early
                    yield from self.load_input(next_butterfly)
                elif op == "t":    # Transpose
                    yield from self.get_transpose(butterfly)
                elif op == "ts":   # Transpose single
                    n = next(self.get_transpose(butterfly),None)
                    if n != None:
                        yield n
                elif op == "lr":   # Load root
                    yield from self.load_root_scalars(butterfly)
                elif op == "lrs":  # Load root single
                    n = next(self.load_root_scalars(butterfly),None)
                    if n != None:
                        yield n
                elif op == "lre":  # Load roots early
                    yield from self.load_root_scalars(next_butterfly)
                elif op == "lres": # Load roots early single
                    n = next(self.load_root_scalars(next_butterfly),None)
                    if n != None:
                        yield n
                elif op == "frl":  # Free roots late
                    if butterfly == None or butterfly.load_roots:
                        list(self.free_root_scalars(last_butterfly))
                elif op == "fr":   # Free roots
                    if next_butterfly == None or next_butterfly.load_roots:
                        list(self.free_root_scalars(butterfly))
                elif op == "frs":  # Free roots single
                    if next_butterfly == None or next_butterfly.load_roots:
                        next(self.free_root_scalars(butterfly),None)
                elif op == "m":    # Move roots
                    if butterfly != None and not butterfly.load_roots:
                        self.copy_root_scalars(butterfly, last_butterfly)
                else:
                    raise Exception("Unknown operation")


    def free_root_scalars(self,butterfly):

        if butterfly == None:
            return iter([])

        if butterfly.root_vecs == None:
            return iter([])

        def free_roots():

            l = len(butterfly.root_vecs)

            order = butterfly.root_load_order

            for i in range(0,l):
                self.vregs.free(butterfly.root_vecs[order[i]])
                butterfly.root_vecs[order[i]] = None
                yield
                self.vregs.free(butterfly.root_twisted_vecs[order[i]])
                butterfly.root_twisted_vecs[order[i]] = None
                yield

            butterfly.root_vecs = None
            butterfly.root_twisted_vecs = None

            butterfly.root = None
            butterfly.root_lane = None
            butterfly.root_twisted = None
            butterfly.root_twisted_lane = None

        if butterfly.free_root_scalars == None:
            butterfly.free_root_scalars = free_roots()

        return butterfly.free_root_scalars

    def make_twiddle_accessors(self,butterfly,root_to_vec_idx_lane):

        def find_root(idx):
            return butterfly.root_vecs[root_to_vec_idx_lane[idx][0]]
        def find_root_twisted(idx):
            return butterfly.root_twisted_vecs[root_to_vec_idx_lane[idx][0]]
        def find_lane(idx):
            return root_to_vec_idx_lane[idx][1]

        butterfly.root = find_root
        butterfly.root_twisted = find_root_twisted
        butterfly.root_lane         = find_lane
        butterfly.root_twisted_lane = find_lane

    def get_butterfly_list(self, layer_start, merged_layers):

        shuffle = False

        if layer_start + merged_layers > self.shuffle_boundary:
            merged_layers = self.shuffle_boundary - layer_start
            shuffle = True

        num_blocks = pow(2,layer_start)
        block_size = self.size // num_blocks
        vectors_per_butterfly = pow(2,merged_layers)
        elements_per_butterfly = self.elements_per_vector * vectors_per_butterfly
        butterflies_per_block = block_size // elements_per_butterfly

        block_stride = block_size // vectors_per_butterfly

        for block in range(0,num_blocks):
            block_base = block * block_size
            idxs = list(range(0,butterflies_per_block))
            # idxs = idxs[1::2] + idxs[0::2]
            idxs = idxs[len(idxs)//2:] + idxs[:len(idxs)//2]
            for i, idx in enumerate(idxs):
                butterfly_base = block_base + idx * self.elements_per_vector
                yield Butterfly(layer=layer_start,
                                merged=merged_layers,
                                block=block,
                                shuffle=shuffle,
                                base=butterfly_base,
                                stride=block_stride,
                                load_roots=(i==0))

    def do_butterflies(self,schedule,butterflies,zip_type=1):

        if zip_type == 2:
            half = len(butterflies) // 2
            butterflies = list(zip(butterflies[:half],butterflies[half:]))
        elif zip_type == 4:
            quarter = len(butterflies) // 4
            butterflies = list(zip(butterflies[0::4],
                                   butterflies[1::4],
                                   butterflies[2::4],
                                   butterflies[3::4]))
            # butterflies = list(zip(butterflies[0*quarter:1*quarter],
            #                        butterflies[1*quarter:2*quarter],
            #                        butterflies[2*quarter:3*quarter],
            #                        butterflies[3*quarter:4*quarter]))
        else:
            butterflies = [[b] for b in butterflies]

        def get_butterfly(idx):
            if idx < 0:
                return None
            if idx >= len(butterflies):
                return None
            return butterflies[idx]

        for i in range(-1,len(butterflies)+1):
            cur_butterfly  = get_butterfly(i)
            last_butterfly = get_butterfly(i-1)
            next_butterfly = get_butterfly(i+1)
            yield from self.run_schedule(schedule,
                                         last_butterfly,
                                         cur_butterfly,
                                         next_butterfly)

    def attach_butterfly_info_old(self,
                              butterflies,
                              load_order, load_order_first,
                              store_order, store_order_last,
                              numbering, twiddles,
                              root_load_order):

        dic = { "load_order":       load_order,
                "load_order_first": load_order_first,
                "store_order":      store_order,
                "store_order_last": store_order_last,
                "numbering":        numbering,
                "root_load_order":  root_load_order,
                "twiddles":         twiddles }

        self.attach_butterfly_info(butterflies,dic)

    def attach_butterfly_info(self,
                              butterflies,
                              dic):
        for b in butterflies:
            b.load_order       = dic["load_order"]
            b.load_order_first = dic["load_order_first"]
            b.store_order      = dic["store_order"]
            b.store_order_last = dic["store_order_last"]
            b.root_load_order  = dic["root_load_order"]
            gs = []
            for i,j,r in dic["numbering"]:
                gs.append(self.ct_butterfly_single(b,i,j,r))
            b.gs = gs
            self.make_twiddle_accessors(b, dic["twiddles"])

    def core(self):

        yield from self.init_constants()

        for (base,merge),(zipped,schedule_idx) in zip(self.layers,self.schedules):

            butterflies = list(self.get_butterfly_list(base,merge))

            schedules = {
                (0,3,1): self.get_schedule_triple_no_transpose,
                (3,3,1): self.get_schedule_triple_no_transpose,
                (0,4,1): self.get_schedule_quad_no_transpose,
                (4,2,1): self.get_schedule_double_no_transpose,
                (4,2,2): self.get_schedule_double_no_transpose_zipped,
                (4,2,4): self.get_schedule_double_no_transpose_quad_zipped,
                (4,4,1): self.get_schedule_quad_transpose,
                (4,4,2): self.get_schedule_quad_transpose_zipped,
                (4,4,4): self.get_schedule_quad_transpose_quad_zipped }

            sched_func = schedules[(base,merge,zipped)]

            s = sched_func(schedule_idx)

            if not type(s) is dict:
                load_order, store_order, numbering, twiddles, root_load_order, schedule = s
                load_order_first = load_order
                store_order_last = store_order
                sched_func(schedule_idx)
                self.attach_butterfly_info_old(butterflies, load_order, load_order_first,
                                               store_order, store_order_last, numbering, twiddles, root_load_order)
                yield from self.do_butterflies(schedule,butterflies,zip_type=zipped)
            else:
                self.attach_butterfly_info(butterflies, s)
                yield from self.do_butterflies(s["schedule"],butterflies,zip_type=zipped)

            self.vregs.revfree()

    def standalone(self,funcname):

        # Preamble
        yield from Snippets.license()
        yield from Snippets.autogen_warning()
        yield from self.generate_constants()
        yield from Snippets.function_decl(funcname)

        yield "modulus_addr: .quad modulus"

        if not self.interleave_twiddles:
            yield "roots_addr: .quad roots"
            yield "roots_twisted_addr: .quad roots_twisted"
        else:
            yield "roots_merged_addr: .quad roots_merged"

        yield from Snippets.function_header(funcname)
        yield from Snippets.save_gprs() # Not necessary
        yield from Snippets.save_vregs()

        self.gprs.alloc(self._src)

        self.prepare_constants()

        # Actual code
        yield from self.core()

        # Wrapup
        self.free_constants()

        self.gprs.free(self._src)

        yield from Snippets.restore_vregs()
        yield from Snippets.restore_gprs() # Not necessary
        yield from Snippets.function_footer()

    def get_code(self):
        gen = self.standalone()
        for line in gen:
            print(line)

def main(argv):

    outfile = None
    degree  = None

    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--out",    type=str, default=None)
    parser.add_argument("--schedule", type=str, default="0,0")
    parser.add_argument("--layers", type=str, default="3,3")
    parser.add_argument("--bitwidth", type=int, default=32)
    parser.add_argument("size",     type=int)
    parser.add_argument("modulus",  type=int)
    parser.add_argument("root",     type=int)
    parser.add_argument("symbol",   type=str)

    args = parser.parse_args()

    code_all       = []
    code_essential = []

    line_count = 0;

    args.layers = list(map(int,args.layers.split(',')))
    args.schedule = list(args.schedule.split(','))

    ntt = NTT(args.size,
              args.modulus,
              args.root,
              layers=args.layers,
              schedules=args.schedule,
              bitwidth=args.bitwidth)
    code_gen = ntt.standalone(args.symbol)

    for line in code_gen:
        code_all.append(line)

    def is_code_line(line):
        if len(line) < 2:
            return False
        if line[0:2] == '//':
            return False
        return True

    code_essential = filter(is_code_line, code_all)
    line_count_total = len(list(code_all))
    line_count_essential = len(list(code_essential))

    code_all.append(f'')
    code_all.append(f'// Line count:        {line_count_total}')
    code_all.append(f'// Instruction count: {line_count_essential}')

    code_all_str = "\n".join(code_all)

    if not args.out == None:
        f = open(args.out,"w")
        f.write(code_all_str)
        f.close()
    else:
        print(code_all_str)

if __name__ == "__main__":
   main(sys.argv[1:])
