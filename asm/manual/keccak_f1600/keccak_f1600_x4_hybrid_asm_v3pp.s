/*
 * Copyright (c) 2021-2022 Arm Limited
 * Copyright (c) 2022 Matthias Kannwischer
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 */

//
// Author: Hanno Becker <hanno.becker@arm.com>
// Author: Matthias Kannwischer <matthias@kannwischer.eu>
//

#include "macros.s"

/********************** CONSTANTS *************************/
    .data
    .align(8)
round_constants:
    .quad 0x0000000000000001
    .quad 0x0000000000008082
    .quad 0x800000000000808a
    .quad 0x8000000080008000
    .quad 0x000000000000808b
    .quad 0x0000000080000001
    .quad 0x8000000080008081
    .quad 0x8000000000008009
    .quad 0x000000000000008a
    .quad 0x0000000000000088
    .quad 0x0000000080008009
    .quad 0x000000008000000a
    .quad 0x000000008000808b
    .quad 0x800000000000008b
    .quad 0x8000000000008089
    .quad 0x8000000000008003
    .quad 0x8000000000008002
    .quad 0x8000000000000080
    .quad 0x000000000000800a
    .quad 0x800000008000000a
    .quad 0x8000000080008081
    .quad 0x8000000000008080
    .quad 0x0000000080000001
    .quad 0x8000000080008008

/****************** REGISTER ALLOCATIONS *******************/

    input_addr     .req x0
    const_addr     .req x29
    count          .req w27
    out_count      .req w27
    cur_const      .req x26

    /* Mapping of Kecck-f1600 SIMD state to vector registers
     * at the beginning and end of each round. */

    vAba     .req v0
    vAbe     .req v1
    vAbi     .req v2
    vAbo     .req v3
    vAbu     .req v4
    vAga     .req v5
    vAge     .req v6
    vAgi     .req v7
    vAgo     .req v8
    vAgu     .req v9
    vAka     .req v10
    vAke     .req v11
    vAki     .req v12
    vAko     .req v13
    vAku     .req v14
    vAma     .req v15
    vAme     .req v16
    vAmi     .req v17
    vAmo     .req v18
    vAmu     .req v19
    vAsa     .req v20
    vAse     .req v21
    vAsi     .req v22
    vAso     .req v23
    vAsu     .req v24

    /* q-form of the above mapping */
    vAbaq    .req q0
    vAbeq    .req q1
    vAbiq    .req q2
    vAboq    .req q3
    vAbuq    .req q4
    vAgaq    .req q5
    vAgeq    .req q6
    vAgiq    .req q7
    vAgoq    .req q8
    vAguq    .req q9
    vAkaq    .req q10
    vAkeq    .req q11
    vAkiq    .req q12
    vAkoq    .req q13
    vAkuq    .req q14
    vAmaq    .req q15
    vAmeq    .req q16
    vAmiq    .req q17
    vAmoq    .req q18
    vAmuq    .req q19
    vAsaq    .req q20
    vAseq    .req q21
    vAsiq    .req q22
    vAsoq    .req q23
    vAsuq    .req q24

    /* C[x] = A[x,0] xor A[x,1] xor A[x,2] xor A[x,3] xor A[x,4],   for x in 0..4 */
    C0 .req v30
    C1 .req v29
    C2 .req v28
    C3 .req v27
    C4 .req v26

    /* E[x] = C[x-1] xor rot(C[x+1],1), for x in 0..4 */
    E0 .req v26
    E1 .req v25
    E2 .req v29
    E3 .req v28
    E4 .req v27

    /* A_[y,2*x+3*y] = rot(A[x,y]) */
    vAbi_ .req v2
    vAbo_ .req v3
    vAbu_ .req v4
    vAga_ .req v10
    vAge_ .req v11
    vAgi_ .req v7
    vAgo_ .req v8
    vAgu_ .req v9
    vAka_ .req v15
    vAke_ .req v16
    vAki_ .req v12
    vAko_ .req v13
    vAku_ .req v14
    vAma_ .req v20
    vAme_ .req v21
    vAmi_ .req v17
    vAmo_ .req v18
    vAmu_ .req v19
    vAsa_ .req v0
    vAse_ .req v1
    vAsi_ .req v22
    vAso_ .req v23
    vAsu_ .req v24
    vAba_ .req v30
    vAbe_ .req v27

    /* Unused temporary */
    vtmp .req v31

    /* Mapping of Kecck-f1600 state to scalar registers
     * at the beginning and end of each round. */
    s_Aba     .req x1
    sAbe     .req x6
    sAbi     .req x11
    sAbo     .req x16
    sAbu     .req x21
    sAga     .req x2
    sAge     .req x7
    sAgi     .req x12
    sAgo     .req x17
    sAgu     .req x22
    sAka     .req x3
    sAke     .req x8
    sAki     .req x13
    sAko     .req x18
    sAku     .req x23
    sAma     .req x4
    sAme     .req x9
    sAmi     .req x14
    sAmo     .req x19
    sAmu     .req x24
    sAsa     .req x5
    sAse     .req x10
    sAsi     .req x15
    sAso     .req x20
    sAsu     .req x25

    /* sA_[y,2*x+3*y] = rot(A[x,y]) */
    s_Aba_ .req x0
    sAbe_ .req x28
    sAbi_ .req x11
    sAbo_ .req x16
    sAbu_ .req x21
    sAga_ .req x3
    sAge_ .req x8
    sAgi_ .req x12
    sAgo_ .req x17
    sAgu_ .req x22
    sAka_ .req x4
    sAke_ .req x9
    sAki_ .req x13
    sAko_ .req x18
    sAku_ .req x23
    sAma_ .req x5
    sAme_ .req x10
    sAmi_ .req x14
    sAmo_ .req x19
    sAmu_ .req x24
    sAsa_ .req x1
    sAse_ .req x6
    sAsi_ .req x15
    sAso_ .req x20
    sAsu_ .req x25

    /* sC[x] = sA[x,0] xor sA[x,1] xor sA[x,2] xor sA[x,3] xor sA[x,4],   for x in 0..4 */
    /* sE[x] = sC[x-1] xor rot(C[x+1],1), for x in 0..4 */
    sC0 .req x0
    sE0 .req x29
    sC1 .req x26
    sE1 .req x30
    sC2 .req x27
    sE2 .req x26
    sC3 .req x28
    sE3 .req x27
    sC4 .req x29
    sE4 .req x28

    tmp .req x30

/************************ MACROS ****************************/

/* Macros using v8.4-A SHA-3 instructions */


.macro eor3_m1 d s0 s1 s2
	eor \d\().16b, \s0\().16b, \s1\().16b
	eor \d\().16b, \d\().16b,  \s2\().16b
.endm

.macro rax1_m1 d s0 s1
   add vtmp.2d, \s1\().2d, \s1\().2d
   sri vtmp.2d, \s1\().2d, #63
   eor \d\().16b, vtmp.16b, \s0\().16b
.endm

.macro xar_m1 d s0 s1 imm
   eor vtmp.16b, \s0\().16b, \s1\().16b
   shl \d\().2d, vtmp.2d, #(64-\imm)
   sri \d\().2d, vtmp.2d, #(\imm)
.endm

.macro bcax_m1 d s0 s1 s2
    bic vtmp.16b, \s1\().16b, \s2\().16b
    eor \d\().16b, vtmp.16b, \s0\().16b
.endm

.macro eor3_m0 d s0 s1 s2
    eor3 \d\().16b, \s0\().16b, \s1\().16b, \s2\().16b
.endm

.macro rax1_m0 d s0 s1
    rax1 \d\().2d, \s0\().2d, \s1\().2d
.endm

.macro xar_m0 d s0 s1 imm
    xar \d\().2d, \s0\().2d, \s1\().2d, #\imm
.endm

.macro bcax_m0 d s0 s1 s2
    bcax \d\().16b, \s0\().16b, \s1\().16b, \s2\().16b
.endm


.macro load_input_vector
    ldr vAbaq, [input_addr, #(32*0)]
    ldr vAbeq, [input_addr, #(32*0+32)]
    ldr vAbiq, [input_addr, #(32*2)]
    ldr vAboq, [input_addr, #(32*2+32)]
    ldr vAbuq, [input_addr, #(32*4)]
    ldr vAgaq, [input_addr, #(32*4+32)]
    ldr vAgeq, [input_addr, #(32*6)]
    ldr vAgiq, [input_addr, #(32*6+32)]
    ldr vAgoq, [input_addr, #(32*8)]
    ldr vAguq, [input_addr, #(32*8+32)]
    ldr vAkaq, [input_addr, #(32*10)]
    ldr vAkeq, [input_addr, #(32*10+32)]
    ldr vAkiq, [input_addr, #(32*12)]
    ldr vAkoq, [input_addr, #(32*12+32)]
    ldr vAkuq, [input_addr, #(32*14)]
    ldr vAmaq, [input_addr, #(32*14+32)]
    ldr vAmeq, [input_addr, #(32*16)]
    ldr vAmiq, [input_addr, #(32*16+32)]
    ldr vAmoq, [input_addr, #(32*18)]
    ldr vAmuq, [input_addr, #(32*18+32)]
    ldr vAsaq, [input_addr, #(32*20)]
    ldr vAseq, [input_addr, #(32*20+32)]
    ldr vAsiq, [input_addr, #(32*22)]
    ldr vAsoq, [input_addr, #(32*22+32)]
    ldr vAsuq, [input_addr, #(32*24)]
.endm

.macro store_input_vector
    str vAbaq, [input_addr, #(32*0)]
    str vAbeq, [input_addr, #(32*0+32)]
    str vAbiq, [input_addr, #(32*2)]
    str vAboq, [input_addr, #(32*2+32)]
    str vAbuq, [input_addr, #(32*4)]
    str vAgaq, [input_addr, #(32*4+32)]
    str vAgeq, [input_addr, #(32*6)]
    str vAgiq, [input_addr, #(32*6+32)]
    str vAgoq, [input_addr, #(32*8)]
    str vAguq, [input_addr, #(32*8+32)]
    str vAkaq, [input_addr, #(32*10)]
    str vAkeq, [input_addr, #(32*10+32)]
    str vAkiq, [input_addr, #(32*12)]
    str vAkoq, [input_addr, #(32*12+32)]
    str vAkuq, [input_addr, #(32*14)]
    str vAmaq, [input_addr, #(32*14+32)]
    str vAmeq, [input_addr, #(32*16)]
    str vAmiq, [input_addr, #(32*16+32)]
    str vAmoq, [input_addr, #(32*18)]
    str vAmuq, [input_addr, #(32*18+32)]
    str vAsaq, [input_addr, #(32*20)]
    str vAseq, [input_addr, #(32*20+32)]
    str vAsiq, [input_addr, #(32*22)]
    str vAsoq, [input_addr, #(32*22+32)]
    str vAsuq, [input_addr, #(32*24)]
.endm

.macro store_input_scalar
    str s_Aba,[input_addr, 32*0 ]
    str sAbe, [input_addr, 32*1 ]
    str sAbi, [input_addr, 32*2 ]
    str sAbo, [input_addr, 32*3 ]
    str sAbu, [input_addr, 32*4 ]
    str sAga, [input_addr, 32*5 ]
    str sAge, [input_addr, 32*6 ]
    str sAgi, [input_addr, 32*7 ]
    str sAgo, [input_addr, 32*8 ]
    str sAgu, [input_addr, 32*9 ]
    str sAka, [input_addr, 32*10]
    str sAke, [input_addr, 32*11]
    str sAki, [input_addr, 32*12]
    str sAko, [input_addr, 32*13]
    str sAku, [input_addr, 32*14]
    str sAma, [input_addr, 32*15]
    str sAme, [input_addr, 32*16]
    str sAmi, [input_addr, 32*17]
    str sAmo, [input_addr, 32*18]
    str sAmu, [input_addr, 32*19]
    str sAsa, [input_addr, 32*20]
    str sAse, [input_addr, 32*21]
    str sAsi, [input_addr, 32*22]
    str sAso, [input_addr, 32*23]
    str sAsu, [input_addr, 32*24]
.endm

.macro load_input_scalar
    ldr s_Aba,[input_addr, 32*0 ]
    ldr sAbe, [input_addr, 32*1 ]
    ldr sAbi, [input_addr, 32*2 ]
    ldr sAbo, [input_addr, 32*3 ]
    ldr sAbu, [input_addr, 32*4 ]
    ldr sAga, [input_addr, 32*5 ]
    ldr sAge, [input_addr, 32*6 ]
    ldr sAgi, [input_addr, 32*7 ]
    ldr sAgo, [input_addr, 32*8 ]
    ldr sAgu, [input_addr, 32*9 ]
    ldr sAka, [input_addr, 32*10]
    ldr sAke, [input_addr, 32*11]
    ldr sAki, [input_addr, 32*12]
    ldr sAko, [input_addr, 32*13]
    ldr sAku, [input_addr, 32*14]
    ldr sAma, [input_addr, 32*15]
    ldr sAme, [input_addr, 32*16]
    ldr sAmi, [input_addr, 32*17]
    ldr sAmo, [input_addr, 32*18]
    ldr sAmu, [input_addr, 32*19]
    ldr sAsa, [input_addr, 32*20]
    ldr sAse, [input_addr, 32*21]
    ldr sAsi, [input_addr, 32*22]
    ldr sAso, [input_addr, 32*23]
    ldr sAsu, [input_addr, 32*24]
.endm

#define STACK_SIZE             (4*16 + 12*8 + 6*8)
#define STACK_BASE_VREGS       (0)
#define STACK_BASE_GPRS        (4*16)
#define STACK_BASE_TMP_GPRS    (4*16 + 12*8)
#define STACK_OFFSET_INPUT     (0*8)
#define STACK_OFFSET_CONST     (1*8)
#define STACK_OFFSET_COUNT     (2*8)
#define STACK_OFFSET_COUNT_OUT (3*8)
#define STACK_OFFSET_CUR_INPUT (4*8)

.macro save_gprs
    stp x19, x20, [sp, #(STACK_BASE_GPRS + 16*0)]
    stp x21, x22, [sp, #(STACK_BASE_GPRS + 16*1)]
    stp x23, x24, [sp, #(STACK_BASE_GPRS + 16*2)]
    stp x25, x26, [sp, #(STACK_BASE_GPRS + 16*3)]
    stp x27, x28, [sp, #(STACK_BASE_GPRS + 16*4)]
    stp x29, x30, [sp, #(STACK_BASE_GPRS + 16*5)]
.endm

.macro restore_gprs
    ldp x19, x20, [sp, #(STACK_BASE_GPRS + 16*0)]
    ldp x21, x22, [sp, #(STACK_BASE_GPRS + 16*1)]
    ldp x23, x24, [sp, #(STACK_BASE_GPRS + 16*2)]
    ldp x25, x26, [sp, #(STACK_BASE_GPRS + 16*3)]
    ldp x27, x28, [sp, #(STACK_BASE_GPRS + 16*4)]
    ldp x29, x30, [sp, #(STACK_BASE_GPRS + 16*5)]
.endm

.macro save_vregs
    stp d8,  d9,  [sp,#(STACK_BASE_VREGS+0*16)]
    stp d10, d11, [sp,#(STACK_BASE_VREGS+1*16)]
    stp d12, d13, [sp,#(STACK_BASE_VREGS+2*16)]
    stp d14, d15, [sp,#(STACK_BASE_VREGS+3*16)]
.endm

.macro restore_vregs
    ldp d14, d15, [sp,#(STACK_BASE_VREGS+3*16)]
    ldp d12, d13, [sp,#(STACK_BASE_VREGS+2*16)]
    ldp d10, d11, [sp,#(STACK_BASE_VREGS+1*16)]
    ldp d8,  d9,  [sp,#(STACK_BASE_VREGS+0*16)]
.endm

.macro alloc_stack
    sub sp, sp, #(STACK_SIZE)
.endm

.macro free_stack
    add sp, sp, #(STACK_SIZE)
.endm

.macro eor5 dst, src0, src1, src2, src3, src4
    eor \dst, \src0, \src1
    eor \dst, \dst,  \src2
    eor \dst, \dst,  \src3
    eor \dst, \dst,  \src4
.endm

.macro xor_rol dst, src1, src0, imm
    eor \dst, \src0, \src1, ROR  #(64-\imm)
.endm

.macro bic_rol dst, src1, src0, imm
    bic \dst, \src0, \src1, ROR  #(64-\imm)
.endm

.macro rotate dst, src, imm
    ror \dst, \src, #(64-\imm)
.endm

.macro save reg, offset
    str \reg, [sp, #(STACK_BASE_TMP_GPRS + \offset)]
.endm

.macro restore reg, offset
    ldr \reg, [sp, #(STACK_BASE_TMP_GPRS + \offset)]
.endm

.macro hybrid_round_initial

   eor sC0, sAma, sAsa                              SEP       eor3_m1 C0, vAba, vAga, vAka
   eor sC1, sAme, sAse                              SEP
   eor sC2, sAmi, sAsi                              SEP
   eor sC3, sAmo, sAso                              SEP       eor3_m1 C0, C0, vAma,  vAsa
   eor sC4, sAmu, sAsu                              SEP
   eor sC0, sAka, sC0                               SEP
   eor sC1, sAke, sC1                               SEP       eor3_m1 C1, vAbe, vAge, vAke
   eor sC2, sAki, sC2                               SEP
   eor sC3, sAko, sC3                               SEP
   eor sC4, sAku, sC4                               SEP       eor3_m1 C1, C1, vAme,  vAse
   eor sC0, sAga, sC0                               SEP
   eor sC1, sAge, sC1                               SEP
   eor sC2, sAgi, sC2                               SEP       eor3_m1 C2, vAbi, vAgi, vAki
   eor sC3, sAgo, sC3                               SEP
   eor sC4, sAgu, sC4                               SEP
   eor sC0, s_Aba, sC0                              SEP       eor3_m1 C2, C2, vAmi,  vAsi
   eor sC1, sAbe, sC1                               SEP
   eor sC2, sAbi, sC2                               SEP
   eor sC3, sAbo, sC3                               SEP       eor3_m1 C3, vAbo, vAgo, vAko
   eor sC4, sAbu, sC4                               SEP
                                                    SEP
   eor sE1, sC0, sC2, ROR #63                       SEP       eor3_m1 C3, C3, vAmo,  vAso
   eor sE3, sC2, sC4, ROR #63                       SEP
   eor sE0, sC4, sC1, ROR #63                       SEP
   eor sE2, sC1, sC3, ROR #63                       SEP       eor3_m1 C4, vAbu, vAgu, vAku
   eor sE4, sC3, sC0, ROR #63                       SEP
                                                    SEP
   eor s_Aba_, s_Aba, sE0                           SEP       eor3_m1 C4, C4, vAmu,  vAsu
   eor sAsa_, sAbi, sE2                             SEP
   eor sAbi_, sAki, sE2                             SEP
   eor sAki_, sAko, sE3                             SEP       rax1_m1 E1, C0, C2
   eor sAko_, sAmu, sE4                             SEP
   eor sAmu_, sAso, sE3                             SEP
   eor sAso_, sAma, sE0                             SEP
   eor sAka_, sAbe, sE1                             SEP       rax1_m1 E3, C2, C4
   eor sAse_, sAgo, sE3                             SEP
   eor sAgo_, sAme, sE1                             SEP
   eor sAke_, sAgi, sE2                             SEP
   eor sAgi_, sAka, sE0                             SEP       rax1_m1 E0, C4, C1
   eor sAga_, sAbo, sE3                             SEP
   eor sAbo_, sAmo, sE3                             SEP
   eor sAmo_, sAmi, sE2                             SEP
   eor sAmi_, sAke, sE1                             SEP       rax1_m1 E2, C1, C3
   eor sAge_, sAgu, sE4                             SEP
   eor sAgu_, sAsi, sE2                             SEP
   eor sAsi_, sAku, sE4                             SEP
   eor sAku_, sAsa, sE0                             SEP       rax1_m1 E4, C3, C0
   eor sAma_, sAbu, sE4                             SEP
   eor sAbu_, sAsu, sE4                             SEP
   eor sAsu_, sAse, sE1                             SEP
   eor sAme_, sAga, sE0                             SEP       eor vAba_.16b, vAba.16b, E0.16b
   eor sAbe_, sAge, sE1                             SEP
                                                    SEP
   load_constant_ptr                                SEP       xar_m1 vAsa_, vAbi, E2, 2
                                                    SEP
   bic tmp, sAgi_, sAge_, ROR #47                   SEP
   eor sAga, tmp,  sAga_, ROR #39                   SEP
   bic tmp, sAgo_, sAgi_, ROR #42                   SEP       xar_m1 vAbi_, vAki, E2, 21
   eor sAge, tmp,  sAge_, ROR #25                   SEP
   bic tmp, sAgu_, sAgo_, ROR #16                   SEP
   eor sAgi, tmp,  sAgi_, ROR #58                   SEP
   bic tmp, sAga_, sAgu_, ROR #31                   SEP       xar_m1 vAki_, vAko, E3, 39
   eor sAgo, tmp,  sAgo_, ROR #47                   SEP
   bic tmp, sAge_, sAga_, ROR #56                   SEP
   eor sAgu, tmp,  sAgu_, ROR #23                   SEP       xar_m1 vAko_, vAmu, E4, 56
   bic tmp, sAki_, sAke_, ROR #19                   SEP
   eor sAka, tmp,  sAka_, ROR #24                   SEP
   bic tmp, sAko_, sAki_, ROR #47                   SEP
   eor sAke, tmp,  sAke_, ROR #2                    SEP       xar_m1 vAmu_, vAso, E3, 8
   bic tmp, sAku_, sAko_, ROR #10                   SEP
   eor sAki, tmp,  sAki_, ROR #57                   SEP
   bic tmp, sAka_, sAku_, ROR #47                   SEP       xar_m1 vAso_, vAma, E0, 23
   eor sAko, tmp,  sAko_, ROR #57                   SEP
   bic tmp, sAke_, sAka_, ROR #5                    SEP
   eor sAku, tmp,  sAku_, ROR #52                   SEP
   bic tmp, sAmi_, sAme_, ROR #38                   SEP       xar_m1 vAka_, vAbe, E1, 63
   eor sAma, tmp,  sAma_, ROR #47                   SEP
   bic tmp, sAmo_, sAmi_, ROR #5                    SEP
   eor sAme, tmp,  sAme_, ROR #43                   SEP       xar_m1 vAse_, vAgo, E3, 9
   bic tmp, sAmu_, sAmo_, ROR #41                   SEP
   eor sAmi, tmp,  sAmi_, ROR #46                   SEP
                                                    SEP
   ldr cur_const, [const_addr]                      SEP
   mov count, #1                                    SEP       xar_m1 vAgo_, vAme, E1, 19
                                                    SEP
   bic tmp, sAma_, sAmu_, ROR #35                   SEP
   eor sAmo, tmp,  sAmo_, ROR #12                   SEP
   bic tmp, sAme_, sAma_, ROR #9                    SEP       xar_m1 vAke_, vAgi, E2, 58
   eor sAmu, tmp,  sAmu_, ROR #44                   SEP
   bic tmp, sAsi_, sAse_, ROR #48                   SEP
   eor sAsa, tmp,  sAsa_, ROR #41                   SEP       xar_m1 vAgi_, vAka, E0, 61
   bic tmp, sAso_, sAsi_, ROR #2                    SEP
   eor sAse, tmp,  sAse_, ROR #50                   SEP
   bic tmp, sAsu_, sAso_, ROR #25                   SEP
   eor sAsi, tmp,  sAsi_, ROR #27                   SEP       xar_m1 vAga_, vAbo, E3, 36
   bic tmp, sAsa_, sAsu_, ROR #60                   SEP
   eor sAso, tmp,  sAso_, ROR #21                   SEP
   bic tmp, sAse_, sAsa_, ROR #57                   SEP       xar_m1 vAbo_, vAmo, E3, 43
   eor sAsu, tmp,  sAsu_, ROR #53                   SEP
   bic tmp, sAbi_, sAbe_, ROR #63                   SEP
   eor s_Aba, s_Aba_, tmp,  ROR #21                 SEP
   bic tmp, sAbo_, sAbi_, ROR #42                   SEP       xar_m1 vAmo_, vAmi, E2, 49
   eor sAbe, tmp,  sAbe_, ROR #41                   SEP
   bic tmp, sAbu_, sAbo_, ROR #57                   SEP
   eor sAbi, tmp,  sAbi_, ROR #35                   SEP       xar_m1 vAmi_, vAke, E1, 54
   bic tmp, s_Aba_, sAbu_, ROR #50                  SEP
   eor sAbo, tmp,  sAbo_, ROR #43                   SEP
   bic tmp, sAbe_, s_Aba_, ROR #44                  SEP
   eor sAbu, tmp,  sAbu_, ROR #30                   SEP       xar_m1 vAge_, vAgu, E4, 44
                                                    SEP
   eor s_Aba, s_Aba, cur_const                      SEP
                                                    SEP       xar_m1 vAgu_, vAsi, E2, 3
   save count, STACK_OFFSET_COUNT                   SEP
                                                    SEP
   eor sC0, sAka, sAsa, ROR #50                     SEP
   eor sC1, sAse, sAge, ROR #60                     SEP
   eor sC2, sAmi, sAgi, ROR #59                     SEP       xar_m1 vAsi_, vAku, E4, 25
   eor sC3, sAgo, sAso, ROR #30                     SEP
   eor sC4, sAbu, sAsu, ROR #53                     SEP
   eor sC0, sAma, sC0, ROR #49                      SEP       xar_m1 vAku_, vAsa, E0, 46
   eor sC1, sAbe, sC1, ROR #44                      SEP
   eor sC2, sAki, sC2, ROR #26                      SEP
   eor sC3, sAmo, sC3, ROR #63                      SEP
   eor sC4, sAmu, sC4, ROR #56                      SEP       xar_m1 vAma_, vAbu, E4, 37
   eor sC0, sAga, sC0, ROR #57                      SEP
   eor sC1, sAme, sC1, ROR #58                      SEP
   eor sC2, sAbi, sC2, ROR #60                      SEP       xar_m1 vAbu_, vAsu, E4, 50
   eor sC3, sAko, sC3, ROR #38                      SEP
   eor sC4, sAgu, sC4, ROR #48                      SEP
   eor sC0, s_Aba, sC0, ROR #61                     SEP
   eor sC1, sAke, sC1, ROR #57                      SEP       xar_m1 vAsu_, vAse, E1, 62
   eor sC2, sAsi, sC2, ROR #52                      SEP
   eor sC3, sAbo, sC3, ROR #63                      SEP
   eor sC4, sAku, sC4, ROR #50                      SEP       xar_m1 vAme_, vAga, E0, 28
   ror sC1, sC1, 56                                 SEP
   ror sC4, sC4, 58                                 SEP
   ror sC2, sC2, 62                                 SEP       xar_m1 vAbe_, vAge, E1, 20
                                                    SEP
   eor sE1, sC0, sC2, ROR #63                       SEP
   eor sE3, sC2, sC4, ROR #63                       SEP
   eor sE0, sC4, sC1, ROR #63                       SEP       bcax_m1 vAga, vAga_, vAgi_, vAge_
   eor sE2, sC1, sC3, ROR #63                       SEP
   eor sE4, sC3, sC0, ROR #63                       SEP
                                                    SEP       bcax_m1 vAge, vAge_, vAgo_, vAgi_
   eor s_Aba_, sE0, s_Aba                           SEP
   eor sAsa_, sE2, sAbi, ROR #50                    SEP
   eor sAbi_, sE2, sAki, ROR #46                    SEP       bcax_m1 vAgi, vAgi_, vAgu_, vAgo_
   eor sAki_, sE3, sAko, ROR #63                    SEP
   eor sAko_, sE4, sAmu, ROR #28                    SEP
   eor sAmu_, sE3, sAso, ROR #2                     SEP       bcax_m1 vAgo, vAgo_, vAga_, vAgu_
   eor sAso_, sE0, sAma, ROR #54                    SEP
   eor sAka_, sE1, sAbe, ROR #43                    SEP
   eor sAse_, sE3, sAgo, ROR #36                    SEP       bcax_m1 vAgu, vAgu_, vAge_, vAga_
   eor sAgo_, sE1, sAme, ROR #49                    SEP
   eor sAke_, sE2, sAgi, ROR #3                     SEP
   eor sAgi_, sE0, sAka, ROR #39                    SEP       bcax_m1 vAka, vAka_, vAki_, vAke_
   eor sAga_, sE3, sAbo                             SEP
   eor sAbo_, sE3, sAmo, ROR #37                    SEP
   eor sAmo_, sE2, sAmi, ROR #8                     SEP       bcax_m1 vAke, vAke_, vAko_, vAki_
   eor sAmi_, sE1, sAke, ROR #56                    SEP
   eor sAge_, sE4, sAgu, ROR #44                    SEP
   eor sAgu_, sE2, sAsi, ROR #62                    SEP       bcax_m1 vAki, vAki_, vAku_, vAko_
   eor sAsi_, sE4, sAku, ROR #58                    SEP
   eor sAku_, sE0, sAsa, ROR #25                    SEP
   eor sAma_, sE4, sAbu, ROR #20                    SEP       bcax_m1 vAko, vAko_, vAka_, vAku_
   eor sAbu_, sE4, sAsu, ROR #9                     SEP
   eor sAsu_, sE1, sAse, ROR #23                    SEP
   eor sAme_, sE0, sAga, ROR #61                    SEP       bcax_m1 vAku, vAku_, vAke_, vAka_
   eor sAbe_, sE1, sAge, ROR #19                    SEP
                                                    SEP
   load_constant_ptr                                SEP       bcax_m1 vAma, vAma_, vAmi_, vAme_
   restore count, STACK_OFFSET_COUNT                SEP
                                                    SEP
   bic tmp, sAgi_, sAge_, ROR #47                   SEP       restore x26, STACK_OFFSET_CONST
   eor sAga, tmp,  sAga_, ROR #39                   SEP
   bic tmp, sAgo_, sAgi_, ROR #42                   SEP
   eor sAge, tmp,  sAge_, ROR #25                   SEP       bcax_m1 vAme, vAme_, vAmo_, vAmi_
   bic tmp, sAgu_, sAgo_, ROR #16                   SEP
   eor sAgi, tmp,  sAgi_, ROR #58                   SEP       ld1r {v28.2d}, [x26], #8
   bic tmp, sAga_, sAgu_, ROR #31                   SEP
   eor sAgo, tmp,  sAgo_, ROR #47                   SEP
   bic tmp, sAge_, sAga_, ROR #56                   SEP       bcax_m1 vAmi, vAmi_, vAmu_, vAmo_
   eor sAgu, tmp,  sAgu_, ROR #23                   SEP
   bic tmp, sAki_, sAke_, ROR #19                   SEP       save x26, STACK_OFFSET_CONST
   eor sAka, tmp,  sAka_, ROR #24                   SEP
   bic tmp, sAko_, sAki_, ROR #47                   SEP
   eor sAke, tmp,  sAke_, ROR #2                    SEP       bcax_m1 vAmo, vAmo_, vAma_, vAmu_
   bic tmp, sAku_, sAko_, ROR #10                   SEP
   eor sAki, tmp,  sAki_, ROR #57                   SEP
   bic tmp, sAka_, sAku_, ROR #47                   SEP       bcax_m1 vAmu, vAmu_, vAme_, vAma_
   eor sAko, tmp,  sAko_, ROR #57                   SEP
   bic tmp, sAke_, sAka_, ROR #5                    SEP
   eor sAku, tmp,  sAku_, ROR #52                   SEP       bcax_m1 vAsa, vAsa_, vAsi_, vAse_
   bic tmp, sAmi_, sAme_, ROR #38                   SEP
   eor sAma, tmp,  sAma_, ROR #47                   SEP
   bic tmp, sAmo_, sAmi_, ROR #5                    SEP       bcax_m1 vAse, vAse_, vAso_, vAsi_
   eor sAme, tmp,  sAme_, ROR #43                   SEP
   bic tmp, sAmu_, sAmo_, ROR #41                   SEP
   eor sAmi, tmp,  sAmi_, ROR #46                   SEP       bcax_m1 vAsi, vAsi_, vAsu_, vAso_
   bic tmp, sAma_, sAmu_, ROR #35                   SEP
                                                    SEP
   ldr cur_const, [const_addr, count, UXTW #3]      SEP       bcax_m1 vAso, vAso_, vAsa_, vAsu_
                                                    SEP
   eor sAmo, tmp,  sAmo_, ROR #12                   SEP
   bic tmp, sAme_, sAma_, ROR #9                    SEP       bcax_m1 vAsu, vAsu_, vAse_, vAsa_
   eor sAmu, tmp,  sAmu_, ROR #44                   SEP
   bic tmp, sAsi_, sAse_, ROR #48                   SEP
   eor sAsa, tmp,  sAsa_, ROR #41                   SEP       bcax_m1 vAba, vAba_, vAbi_, vAbe_
   bic tmp, sAso_, sAsi_, ROR #2                    SEP
   eor sAse, tmp,  sAse_, ROR #50                   SEP
   bic tmp, sAsu_, sAso_, ROR #25                   SEP       bcax_m1 vAbe, vAbe_, vAbo_, vAbi_
   eor sAsi, tmp,  sAsi_, ROR #27                   SEP
   bic tmp, sAsa_, sAsu_, ROR #60                   SEP
   eor sAso, tmp,  sAso_, ROR #21                   SEP       bcax_m1 vAbi, vAbi_, vAbu_, vAbo_
   bic tmp, sAse_, sAsa_, ROR #57                   SEP
   eor sAsu, tmp,  sAsu_, ROR #53                   SEP
   bic tmp, sAbi_, sAbe_, ROR #63                   SEP       bcax_m1 vAbo, vAbo_, vAba_, vAbu_
   eor s_Aba, s_Aba_, tmp,  ROR #21                 SEP
   bic tmp, sAbo_, sAbi_, ROR #42                   SEP
   eor sAbe, tmp,  sAbe_, ROR #41                   SEP       bcax_m1 vAbu, vAbu_, vAbe_, vAba_
   bic tmp, sAbu_, sAbo_, ROR #57                   SEP
   eor sAbi, tmp,  sAbi_, ROR #35                   SEP
   bic tmp, s_Aba_, sAbu_, ROR #50                  SEP
   eor sAbo, tmp,  sAbo_, ROR #43                   SEP       eor vAba.16b, vAba.16b, v28.16b
   bic tmp, sAbe_, s_Aba_, ROR #44                  SEP
   eor sAbu, tmp,  sAbu_, ROR #30                   SEP
                                                    SEP
   add count, count, #1                             SEP
                                                    SEP
   eor s_Aba, s_Aba, cur_const                      SEP
                                                    SEP
.endm

.macro  hybrid_round_noninitial
    save count, STACK_OFFSET_COUNT                  SEP       eor3_m1 C0, vAba, vAga, vAka
                                                    SEP
    eor sC0, sAka, sAsa, ROR #50                    SEP
    eor sC1, sAse, sAge, ROR #60                    SEP       eor3_m1 C0, C0, vAma,  vAsa
    eor sC2, sAmi, sAgi, ROR #59                    SEP
    eor sC3, sAgo, sAso, ROR #30                    SEP
    eor sC4, sAbu, sAsu, ROR #53                    SEP       eor3_m1 C1, vAbe, vAge, vAke
    eor sC0, sAma, sC0, ROR #49                     SEP
    eor sC1, sAbe, sC1, ROR #44                     SEP
    eor sC2, sAki, sC2, ROR #26                     SEP       eor3_m1 C1, C1, vAme,  vAse
    eor sC3, sAmo, sC3, ROR #63                     SEP
    eor sC4, sAmu, sC4, ROR #56                     SEP
    eor sC0, sAga, sC0, ROR #57                     SEP       eor3_m1 C2, vAbi, vAgi, vAki
    eor sC1, sAme, sC1, ROR #58                     SEP
    eor sC2, sAbi, sC2, ROR #60                     SEP
    eor sC3, sAko, sC3, ROR #38                     SEP       eor3_m1 C2, C2, vAmi,  vAsi
    eor sC4, sAgu, sC4, ROR #48                     SEP
    eor sC0, s_Aba, sC0, ROR #61                    SEP
    eor sC1, sAke, sC1, ROR #57                     SEP       eor3_m1 C3, vAbo, vAgo, vAko
    eor sC2, sAsi, sC2, ROR #52                     SEP
    eor sC3, sAbo, sC3, ROR #63                     SEP
    eor sC4, sAku, sC4, ROR #50                     SEP       eor3_m1 C3, C3, vAmo,  vAso
    ror sC1, sC1, 56                                SEP
    ror sC4, sC4, 58                                SEP
    ror sC2, sC2, 62                                SEP       eor3_m1 C4, vAbu, vAgu, vAku
                                                    SEP
    eor sE1, sC0, sC2, ROR #63                      SEP
    eor sE3, sC2, sC4, ROR #63                      SEP       eor3_m1 C4, C4, vAmu,  vAsu
    eor sE0, sC4, sC1, ROR #63                      SEP
    eor sE2, sC1, sC3, ROR #63                      SEP
    eor sE4, sC3, sC0, ROR #63                      SEP       rax1_m1 E1, C0, C2
                                                    SEP
    eor s_Aba_, sE0, s_Aba                          SEP
    eor sAsa_, sE2, sAbi, ROR #50                   SEP
    eor sAbi_, sE2, sAki, ROR #46                   SEP       rax1_m1 E3, C2, C4
    eor sAki_, sE3, sAko, ROR #63                   SEP
    eor sAko_, sE4, sAmu, ROR #28                   SEP
    eor sAmu_, sE3, sAso, ROR #2                    SEP
    eor sAso_, sE0, sAma, ROR #54                   SEP       rax1_m1 E0, C4, C1
    eor sAka_, sE1, sAbe, ROR #43                   SEP
    eor sAse_, sE3, sAgo, ROR #36                   SEP
    eor sAgo_, sE1, sAme, ROR #49                   SEP
    eor sAke_, sE2, sAgi, ROR #3                    SEP       rax1_m1 E2, C1, C3
    eor sAgi_, sE0, sAka, ROR #39                   SEP
    eor sAga_, sE3, sAbo                            SEP
    eor sAbo_, sE3, sAmo, ROR #37                   SEP
    eor sAmo_, sE2, sAmi, ROR #8                    SEP       rax1_m1 E4, C3, C0
    eor sAmi_, sE1, sAke, ROR #56                   SEP
    eor sAge_, sE4, sAgu, ROR #44                   SEP
    eor sAgu_, sE2, sAsi, ROR #62                   SEP
    eor sAsi_, sE4, sAku, ROR #58                   SEP       eor vAba_.16b, vAba.16b, E0.16b
    eor sAku_, sE0, sAsa, ROR #25                   SEP
    eor sAma_, sE4, sAbu, ROR #20                   SEP
    eor sAbu_, sE4, sAsu, ROR #9                    SEP       xar_m1 vAsa_, vAbi, E2, 2
    eor sAsu_, sE1, sAse, ROR #23                   SEP
    eor sAme_, sE0, sAga, ROR #61                   SEP
    eor sAbe_, sE1, sAge, ROR #19                   SEP
                                                    SEP       xar_m1 vAbi_, vAki, E2, 21
    load_constant_ptr                               SEP
    restore count, STACK_OFFSET_COUNT               SEP
                                                    SEP
    bic tmp, sAgi_, sAge_, ROR #47                  SEP       xar_m1 vAki_, vAko, E3, 39
    eor sAga, tmp,  sAga_, ROR #39                  SEP
    bic tmp, sAgo_, sAgi_, ROR #42                  SEP
    eor sAge, tmp,  sAge_, ROR #25                  SEP       xar_m1 vAko_, vAmu, E4, 56
    bic tmp, sAgu_, sAgo_, ROR #16                  SEP
    eor sAgi, tmp,  sAgi_, ROR #58                  SEP
    bic tmp, sAga_, sAgu_, ROR #31                  SEP
    eor sAgo, tmp,  sAgo_, ROR #47                  SEP       xar_m1 vAmu_, vAso, E3, 8
    bic tmp, sAge_, sAga_, ROR #56                  SEP
    eor sAgu, tmp,  sAgu_, ROR #23                  SEP
    bic tmp, sAki_, sAke_, ROR #19                  SEP
    eor sAka, tmp,  sAka_, ROR #24                  SEP       xar_m1 vAso_, vAma, E0, 23
    bic tmp, sAko_, sAki_, ROR #47                  SEP
    eor sAke, tmp,  sAke_, ROR #2                   SEP
    bic tmp, sAku_, sAko_, ROR #10                  SEP
    eor sAki, tmp,  sAki_, ROR #57                  SEP       xar_m1 vAka_, vAbe, E1, 63
    bic tmp, sAka_, sAku_, ROR #47                  SEP
    eor sAko, tmp,  sAko_, ROR #57                  SEP
    bic tmp, sAke_, sAka_, ROR #5                   SEP       xar_m1 vAse_, vAgo, E3, 9
    eor sAku, tmp,  sAku_, ROR #52                  SEP
    bic tmp, sAmi_, sAme_, ROR #38                  SEP
    eor sAma, tmp,  sAma_, ROR #47                  SEP
    bic tmp, sAmo_, sAmi_, ROR #5                   SEP
    eor sAme, tmp,  sAme_, ROR #43                  SEP       xar_m1 vAgo_, vAme, E1, 19
    bic tmp, sAmu_, sAmo_, ROR #41                  SEP
    eor sAmi, tmp,  sAmi_, ROR #46                  SEP
    bic tmp, sAma_, sAmu_, ROR #35                  SEP
                                                    SEP       xar_m1 vAke_, vAgi, E2, 58
    ldr cur_const, [const_addr, count, UXTW #3]     SEP
    add count, count, #1                            SEP
                                                    SEP
    eor sAmo, tmp,  sAmo_, ROR #12                  SEP
    bic tmp, sAme_, sAma_, ROR #9                   SEP       xar_m1 vAgi_, vAka, E0, 61
    eor sAmu, tmp,  sAmu_, ROR #44                  SEP
    bic tmp, sAsi_, sAse_, ROR #48                  SEP
    eor sAsa, tmp,  sAsa_, ROR #41                  SEP
    bic tmp, sAso_, sAsi_, ROR #2                   SEP       xar_m1 vAga_, vAbo, E3, 36
    eor sAse, tmp,  sAse_, ROR #50                  SEP
    bic tmp, sAsu_, sAso_, ROR #25                  SEP
    eor sAsi, tmp,  sAsi_, ROR #27                  SEP
    bic tmp, sAsa_, sAsu_, ROR #60                  SEP       xar_m1 vAbo_, vAmo, E3, 43
    eor sAso, tmp,  sAso_, ROR #21                  SEP
    bic tmp, sAse_, sAsa_, ROR #57                  SEP
    eor sAsu, tmp,  sAsu_, ROR #53                  SEP
    bic tmp, sAbi_, sAbe_, ROR #63                  SEP       xar_m1 vAmo_, vAmi, E2, 49
    eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
    bic tmp, sAbo_, sAbi_, ROR #42                  SEP
    eor sAbe, tmp,  sAbe_, ROR #41                  SEP
    bic tmp, sAbu_, sAbo_, ROR #57                  SEP       xar_m1 vAmi_, vAke, E1, 54
    eor sAbi, tmp,  sAbi_, ROR #35                  SEP
    bic tmp, s_Aba_, sAbu_, ROR #50                 SEP
    eor sAbo, tmp,  sAbo_, ROR #43                  SEP
    bic tmp, sAbe_, s_Aba_, ROR #44                 SEP       xar_m1 vAge_, vAgu, E4, 44
    eor sAbu, tmp,  sAbu_, ROR #30                  SEP
                                                    SEP
    eor s_Aba, s_Aba, cur_const                     SEP       xar_m1 vAgu_, vAsi, E2, 3
    save count, STACK_OFFSET_COUNT                  SEP
                                                    SEP
    eor sC0, sAka, sAsa, ROR #50                    SEP
    eor sC1, sAse, sAge, ROR #60                    SEP
    eor sC2, sAmi, sAgi, ROR #59                    SEP       xar_m1 vAsi_, vAku, E4, 25
    eor sC3, sAgo, sAso, ROR #30                    SEP
    eor sC4, sAbu, sAsu, ROR #53                    SEP
    eor sC0, sAma, sC0, ROR #49                     SEP       xar_m1 vAku_, vAsa, E0, 46
    eor sC1, sAbe, sC1, ROR #44                     SEP
    eor sC2, sAki, sC2, ROR #26                     SEP
    eor sC3, sAmo, sC3, ROR #63                     SEP
    eor sC4, sAmu, sC4, ROR #56                     SEP       xar_m1 vAma_, vAbu, E4, 37
    eor sC0, sAga, sC0, ROR #57                     SEP
    eor sC1, sAme, sC1, ROR #58                     SEP
    eor sC2, sAbi, sC2, ROR #60                     SEP
    eor sC3, sAko, sC3, ROR #38                     SEP       xar_m1 vAbu_, vAsu, E4, 50
    eor sC4, sAgu, sC4, ROR #48                     SEP
    eor sC0, s_Aba, sC0, ROR #61                    SEP
    eor sC1, sAke, sC1, ROR #57                     SEP
    eor sC2, sAsi, sC2, ROR #52                     SEP       xar_m1 vAsu_, vAse, E1, 62
    eor sC3, sAbo, sC3, ROR #63                     SEP
    eor sC4, sAku, sC4, ROR #50                     SEP
    ror sC1, sC1, 56                                SEP       xar_m1 vAme_, vAga, E0, 28
    ror sC4, sC4, 58                                SEP
    ror sC2, sC2, 62                                SEP
                                                    SEP       xar_m1 vAbe_, vAge, E1, 20
    eor sE1, sC0, sC2, ROR #63                      SEP
    eor sE3, sC2, sC4, ROR #63                      SEP
    eor sE0, sC4, sC1, ROR #63                      SEP
    eor sE2, sC1, sC3, ROR #63                      SEP       bcax_m1 vAga, vAga_, vAgi_, vAge_
    eor sE4, sC3, sC0, ROR #63                      SEP
                                                    SEP
    eor s_Aba_, sE0, s_Aba                          SEP       bcax_m1 vAge, vAge_, vAgo_, vAgi_
    eor sAsa_, sE2, sAbi, ROR #50                   SEP
    eor sAbi_, sE2, sAki, ROR #46                   SEP
    eor sAki_, sE3, sAko, ROR #63                   SEP       bcax_m1 vAgi, vAgi_, vAgu_, vAgo_
    eor sAko_, sE4, sAmu, ROR #28                   SEP
    eor sAmu_, sE3, sAso, ROR #2                    SEP
    eor sAso_, sE0, sAma, ROR #54                   SEP       bcax_m1 vAgo, vAgo_, vAga_, vAgu_
    eor sAka_, sE1, sAbe, ROR #43                   SEP
    eor sAse_, sE3, sAgo, ROR #36                   SEP
    eor sAgo_, sE1, sAme, ROR #49                   SEP       bcax_m1 vAgu, vAgu_, vAge_, vAga_
    eor sAke_, sE2, sAgi, ROR #3                    SEP
    eor sAgi_, sE0, sAka, ROR #39                   SEP
    eor sAga_, sE3, sAbo                            SEP       bcax_m1 vAka, vAka_, vAki_, vAke_
    eor sAbo_, sE3, sAmo, ROR #37                   SEP
    eor sAmo_, sE2, sAmi, ROR #8                    SEP
    eor sAmi_, sE1, sAke, ROR #56                   SEP       bcax_m1 vAke, vAke_, vAko_, vAki_
    eor sAge_, sE4, sAgu, ROR #44                   SEP
    eor sAgu_, sE2, sAsi, ROR #62                   SEP
    eor sAsi_, sE4, sAku, ROR #58                   SEP       bcax_m1 vAki, vAki_, vAku_, vAko_
    eor sAku_, sE0, sAsa, ROR #25                   SEP
    eor sAma_, sE4, sAbu, ROR #20                   SEP
    eor sAbu_, sE4, sAsu, ROR #9                    SEP       bcax_m1 vAko, vAko_, vAka_, vAku_
    eor sAsu_, sE1, sAse, ROR #23                   SEP
    eor sAme_, sE0, sAga, ROR #61                   SEP
    eor sAbe_, sE1, sAge, ROR #19                   SEP       bcax_m1 vAku, vAku_, vAke_, vAka_
                                                    SEP
    load_constant_ptr                               SEP
    restore count, STACK_OFFSET_COUNT               SEP       bcax_m1 vAma, vAma_, vAmi_, vAme_
                                                    SEP
    bic tmp, sAgi_, sAge_, ROR #47                  SEP
    eor sAga, tmp,  sAga_, ROR #39                  SEP       restore x26, STACK_OFFSET_CONST
    bic tmp, sAgo_, sAgi_, ROR #42                  SEP
    eor sAge, tmp,  sAge_, ROR #25                  SEP
    bic tmp, sAgu_, sAgo_, ROR #16                  SEP       bcax_m1 vAme, vAme_, vAmo_, vAmi_
    eor sAgi, tmp,  sAgi_, ROR #58                  SEP
    bic tmp, sAga_, sAgu_, ROR #31                  SEP       ld1r {v28.2d}, [x26], #8
    eor sAgo, tmp,  sAgo_, ROR #47                  SEP
    bic tmp, sAge_, sAga_, ROR #56                  SEP
    eor sAgu, tmp,  sAgu_, ROR #23                  SEP       bcax_m1 vAmi, vAmi_, vAmu_, vAmo_
    bic tmp, sAki_, sAke_, ROR #19                  SEP
    eor sAka, tmp,  sAka_, ROR #24                  SEP       save x26, STACK_OFFSET_CONST
    bic tmp, sAko_, sAki_, ROR #47                  SEP
    eor sAke, tmp,  sAke_, ROR #2                   SEP
    bic tmp, sAku_, sAko_, ROR #10                  SEP       bcax_m1 vAmo, vAmo_, vAma_, vAmu_
    eor sAki, tmp,  sAki_, ROR #57                  SEP
    bic tmp, sAka_, sAku_, ROR #47                  SEP
    eor sAko, tmp,  sAko_, ROR #57                  SEP       bcax_m1 vAmu, vAmu_, vAme_, vAma_
    bic tmp, sAke_, sAka_, ROR #5                   SEP
    eor sAku, tmp,  sAku_, ROR #52                  SEP
    bic tmp, sAmi_, sAme_, ROR #38                  SEP       bcax_m1 vAsa, vAsa_, vAsi_, vAse_
    eor sAma, tmp,  sAma_, ROR #47                  SEP
    bic tmp, sAmo_, sAmi_, ROR #5                   SEP
    eor sAme, tmp,  sAme_, ROR #43                  SEP       bcax_m1 vAse, vAse_, vAso_, vAsi_
    bic tmp, sAmu_, sAmo_, ROR #41                  SEP
    eor sAmi, tmp,  sAmi_, ROR #46                  SEP
    bic tmp, sAma_, sAmu_, ROR #35                  SEP       bcax_m1 vAsi, vAsi_, vAsu_, vAso_
                                                    SEP
    ldr cur_const, [const_addr, count, UXTW #3]     SEP
    add count, count, #1                            SEP       bcax_m1 vAso, vAso_, vAsa_, vAsu_
                                                    SEP
    eor sAmo, tmp,  sAmo_, ROR #12                  SEP
    bic tmp, sAme_, sAma_, ROR #9                   SEP       bcax_m1 vAsu, vAsu_, vAse_, vAsa_
    eor sAmu, tmp,  sAmu_, ROR #44                  SEP
    bic tmp, sAsi_, sAse_, ROR #48                  SEP
    eor sAsa, tmp,  sAsa_, ROR #41                  SEP       bcax_m1 vAba, vAba_, vAbi_, vAbe_
    bic tmp, sAso_, sAsi_, ROR #2                   SEP
    eor sAse, tmp,  sAse_, ROR #50                  SEP
    bic tmp, sAsu_, sAso_, ROR #25                  SEP       bcax_m1 vAbe, vAbe_, vAbo_, vAbi_
    eor sAsi, tmp,  sAsi_, ROR #27                  SEP
    bic tmp, sAsa_, sAsu_, ROR #60                  SEP
    eor sAso, tmp,  sAso_, ROR #21                  SEP       bcax_m1 vAbi, vAbi_, vAbu_, vAbo_
    bic tmp, sAse_, sAsa_, ROR #57                  SEP
    eor sAsu, tmp,  sAsu_, ROR #53                  SEP
    bic tmp, sAbi_, sAbe_, ROR #63                  SEP       bcax_m1 vAbo, vAbo_, vAba_, vAbu_
    eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
    bic tmp, sAbo_, sAbi_, ROR #42                  SEP
    eor sAbe, tmp,  sAbe_, ROR #41                  SEP       bcax_m1 vAbu, vAbu_, vAbe_, vAba_
    bic tmp, sAbu_, sAbo_, ROR #57                  SEP
    eor sAbi, tmp,  sAbi_, ROR #35                  SEP
    bic tmp, s_Aba_, sAbu_, ROR #50                 SEP
    eor sAbo, tmp,  sAbo_, ROR #43                  SEP       eor vAba.16b, vAba.16b, v28.16b
    bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
    eor sAbu, tmp,  sAbu_, ROR #30                  SEP
                                                    SEP
    eor s_Aba, s_Aba, cur_const                     SEP

.endm

.macro final_rotate
    ror sAga, sAga,#(64-3)
    ror sAka, sAka,#(64-25)
    ror sAma, sAma,#(64-10)
    ror sAsa, sAsa,#(64-39)
    ror sAbe, sAbe,#(64-21)
    ror sAge, sAge,#(64-45)
    ror sAke, sAke,#(64-8)
    ror sAme, sAme,#(64-15)
    ror sAse, sAse,#(64-41)
    ror sAbi, sAbi,#(64-14)
    ror sAgi, sAgi,#(64-61)
    ror sAki, sAki,#(64-18)
    ror sAmi, sAmi,#(64-56)
    ror sAsi, sAsi,#(64-2)
    ror sAgo, sAgo,#(64-28)
    ror sAko, sAko,#(64-1)
    ror sAmo, sAmo,#(64-27)
    ror sAso, sAso,#(64-62)
    ror sAbu, sAbu,#(64-44)
    ror sAgu, sAgu,#(64-20)
    ror sAku, sAku,#(64-6)
    ror sAmu, sAmu,#(64-36)
    ror sAsu, sAsu,#(64-55)
.endm

#define KECCAK_F1600_ROUNDS 24

.global keccak_f1600_x4_hybrid_asm_v3pp
.global _keccak_f1600_x4_hybrid_asm_v3pp
.text
.align 4

keccak_f1600_x4_hybrid_asm_v3pp:
_keccak_f1600_x4_hybrid_asm_v3pp:
    alloc_stack
    save_gprs
    save_vregs
    save input_addr, STACK_OFFSET_INPUT

    ASM_LOAD(const_addr,round_constants)
    save const_addr, STACK_OFFSET_CONST

    load_input_vector

    add input_addr, input_addr, #16

    mov out_count, #0
outer_loop:
    save out_count, STACK_OFFSET_COUNT_OUT

    load_input_scalar
    save input_addr, STACK_OFFSET_CUR_INPUT

    hybrid_round_initial
1:
    hybrid_round_noninitial
    cmp count, #(KECCAK_F1600_ROUNDS)
    blt 1b

    final_rotate
    restore input_addr, STACK_OFFSET_CUR_INPUT
    store_input_scalar
    add input_addr, input_addr, #8

    restore out_count, STACK_OFFSET_COUNT_OUT
    add out_count, out_count, #1
    cmp out_count, #2
    blt outer_loop

    restore input_addr, STACK_OFFSET_INPUT
    store_input_vector

    restore_vregs
    restore_gprs
    free_stack
    ret
