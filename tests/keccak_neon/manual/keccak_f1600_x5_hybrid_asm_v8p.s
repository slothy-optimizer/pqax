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
round_constants_vec:
    .quad 0x0000000000000001
    .quad 0x0000000000000001
    .quad 0x0000000000008082
    .quad 0x0000000000008082
    .quad 0x800000000000808a
    .quad 0x800000000000808a
    .quad 0x8000000080008000
    .quad 0x8000000080008000
    .quad 0x000000000000808b
    .quad 0x000000000000808b
    .quad 0x0000000080000001
    .quad 0x0000000080000001
    .quad 0x8000000080008081
    .quad 0x8000000080008081
    .quad 0x8000000000008009
    .quad 0x8000000000008009
    .quad 0x000000000000008a
    .quad 0x000000000000008a
    .quad 0x0000000000000088
    .quad 0x0000000000000088
    .quad 0x0000000080008009
    .quad 0x0000000080008009
    .quad 0x000000008000000a
    .quad 0x000000008000000a
    .quad 0x000000008000808b
    .quad 0x000000008000808b
    .quad 0x800000000000008b
    .quad 0x800000000000008b
    .quad 0x8000000000008089
    .quad 0x8000000000008089
    .quad 0x8000000000008003
    .quad 0x8000000000008003
    .quad 0x8000000000008002
    .quad 0x8000000000008002
    .quad 0x8000000000000080
    .quad 0x8000000000000080
    .quad 0x000000000000800a
    .quad 0x000000000000800a
    .quad 0x800000008000000a
    .quad 0x800000008000000a
    .quad 0x8000000080008081
    .quad 0x8000000080008081
    .quad 0x8000000000008080
    .quad 0x8000000000008080
    .quad 0x0000000080000001
    .quad 0x0000000080000001
    .quad 0x8000000080008008
    .quad 0x8000000080008008
/****************** REGISTER ALLOCATIONS *******************/

    input_addr     .req x0
    const_addr     .req x29
    count          .req w27
    out_count      .req w27
    cur_const      .req x26

    /* Mapping of Kecck-f1600 SIMD state to vector registers
     * at the beginning and end of each round. */

   /* Mapping of Kecck-f1600 state to vector registers
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
    C0 .req v27
    C1 .req v28
    C2 .req v29
    C3 .req v30
    C4 .req v31

    C0q .req q27
    C1q .req q28
    C2q .req q29
    C3q .req q30
    C4q .req q31

    /* A_[y,2*x+3*y] = rot(A[x,y]) */
    vBba .req v25 // fresh
    vBbe .req v26 // fresh
    vBbi .req vAbi
    vBbo .req vAbo
    vBbu .req vAbu
    vBga .req vAka
    vBge .req vAke
    vBgi .req vAgi
    vBgo .req vAgo
    vBgu .req vAgu
    vBka .req vAma
    vBke .req vAme
    vBki .req vAki
    vBko .req vAko
    vBku .req vAku
    vBma .req vAsa
    vBme .req vAse
    vBmi .req vAmi
    vBmo .req vAmo
    vBmu .req vAmu
    vBsa .req vAba
    vBse .req vAbe
    vBsi .req vAsi
    vBso .req vAso
    vBsu .req vAsu

    vBbaq .req q25 // fresh
    vBbeq .req q26 // fresh
    vBbiq .req vAbiq
    vBboq .req vAboq
    vBbuq .req vAbuq
    vBgaq .req vAkaq
    vBgeq .req vAkeq
    vBgiq .req vAgiq
    vBgoq .req vAgoq
    vBguq .req vAguq
    vBkaq .req vAmaq
    vBkeq .req vAmeq
    vBkiq .req vAkiq
    vBkoq .req vAkoq
    vBkuq .req vAkuq
    vBmaq .req vAsaq
    vBmeq .req vAseq
    vBmiq .req vAmiq
    vBmoq .req vAmoq
    vBmuq .req vAmuq
    vBsaq .req vAbaq
    vBseq .req vAbeq
    vBsiq .req vAsiq
    vBsoq .req vAsoq
    vBsuq .req vAsuq

    /* E[x] = C[x-1] xor rot(C[x+1],1), for x in 0..4 */
    E0 .req C4
    E1 .req C0
    E2 .req vBbe // fresh
    E3 .req C2
    E4 .req C3

    E0q .req C4q
    E1q .req C0q
    E2q .req vBbeq // fresh
    E3q .req C2q
    E4q .req C3q

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

.macro eor2 d s0 s1
    eor \d\().16b, \s0\().16b, \s1\().16b
.endm

.macro eor3_m1 d s0 s1 s2
    eor2 \d, \s0, \s1
    eor2 \d, \d,  \s2
.endm

.macro rax1_m1 d s0 s1
   shl vvtmp.2d, \s1\().2d, #1
   sri vvtmp.2d, \s1\().2d, #63
   eor \d\().16b, vvtmp.16b, \s0\().16b
.endm

 .macro xar_m1 d s0 s1 imm
   // Special cases where we can replace SHLs by ADDs
   .if \imm == 63
     eor \s0\().16b, \s0\().16b, \s1\().16b
     add \d\().2d, \s0\().2d, \s0\().2d
     sri \d\().2d, \s0\().2d, #(63)
   .else
     eor \s0\().16b, \s0\().16b, \s1\().16b
     shl \d\().2d, \s0\().2d, #(64-\imm)
     sri \d\().2d, \s0\().2d, #(\imm)
   .endif
.endm

.macro bcax_m1 d s0 s1 s2
    bic vvtmp.16b, \s1\().16b, \s2\().16b
    eor \d\().16b, vvtmp.16b, \s0\().16b
.endm

.macro load_input_vector
    ldp vAbaq, vAbeq, [input_addr, #(16*0)]
    ldp vAbiq, vAboq, [input_addr, #(16*2)]
    ldp vAbuq, vAgaq, [input_addr, #(16*4)]
    ldp vAgeq, vAgiq, [input_addr, #(16*6)]
    ldp vAgoq, vAguq, [input_addr, #(16*8)]
    ldp vAkaq, vAkeq, [input_addr, #(16*10)]
    ldp vAkiq, vAkoq, [input_addr, #(16*12)]
    ldp vAkuq, vAmaq, [input_addr, #(16*14)]
    ldp vAmeq, vAmiq, [input_addr, #(16*16)]
    ldp vAmoq, vAmuq, [input_addr, #(16*18)]
    ldp vAsaq, vAseq, [input_addr, #(16*20)]
    ldp vAsiq, vAsoq, [input_addr, #(16*22)]
    ldr vAsuq, [input_addr, #(16*24)]

    // ldr vAbaq, [input_addr, #(16*0)]
    // ldr vAbeq, [input_addr, #(16*1)]
    // ldr vAbiq, [input_addr, #(16*2)]
    // ldr vAboq, [input_addr, #(16*3)]
    // ldr vAbuq, [input_addr, #(16*4)]
    // ldr vAgaq, [input_addr, #(16*5)]
    // ldr vAgeq, [input_addr, #(16*6)]
    // ldr vAgiq, [input_addr, #(16*7)]
    // ldr vAgoq, [input_addr, #(16*8)]
    // ldr vAguq, [input_addr, #(16*9)]
    // ldr vAkaq, [input_addr, #(16*10)]
    // ldr vAkeq, [input_addr, #(16*11)]
    // ldr vAkiq, [input_addr, #(16*12)]
    // ldr vAkoq, [input_addr, #(16*13)]
    // ldr vAkuq, [input_addr, #(16*14)]
    // ldr vAmaq, [input_addr, #(16*15)]
    // ldr vAmeq, [input_addr, #(16*16)]
    // ldr vAmiq, [input_addr, #(16*17)]
    // ldr vAmoq, [input_addr, #(16*18)]
    // ldr vAmuq, [input_addr, #(16*19)]
    // ldr vAsaq, [input_addr, #(16*20)]
    // ldr vAseq, [input_addr, #(16*21)]
    // ldr vAsiq, [input_addr, #(16*22)]
    // ldr vAsoq, [input_addr, #(16*23)]
    // ldr vAsuq, [input_addr, #(16*24)]
.endm

.macro store_input_vector
    stp vAbaq, vAbeq, [input_addr, #(16*0)]
    stp vAbiq, vAboq, [input_addr, #(16*2)]
    stp vAbuq, vAgaq, [input_addr, #(16*4)]
    stp vAgeq, vAgiq, [input_addr, #(16*6)]
    stp vAgoq, vAguq, [input_addr, #(16*8)]
    stp vAkaq, vAkeq, [input_addr, #(16*10)]
    stp vAkiq, vAkoq, [input_addr, #(16*12)]
    stp vAkuq, vAmaq, [input_addr, #(16*14)]
    stp vAmeq, vAmiq, [input_addr, #(16*16)]
    stp vAmoq, vAmuq, [input_addr, #(16*18)]
    stp vAsaq, vAseq, [input_addr, #(16*20)]
    stp vAsiq, vAsoq, [input_addr, #(16*22)]
    str vAsuq, [input_addr, #(16*24)]

    // str vAbaq, [input_addr, #(16*0)]
    // str vAbeq, [input_addr, #(16*1)]
    // str vAbiq, [input_addr, #(16*2)]
    // str vAboq, [input_addr, #(16*3)]
    // str vAbuq, [input_addr, #(16*4)]
    // str vAgaq, [input_addr, #(16*5)]
    // str vAgeq, [input_addr, #(16*6)]
    // str vAgiq, [input_addr, #(16*7)]
    // str vAgoq, [input_addr, #(16*8)]
    // str vAguq, [input_addr, #(16*9)]
    // str vAkaq, [input_addr, #(16*10)]
    // str vAkeq, [input_addr, #(16*11)]
    // str vAkiq, [input_addr, #(16*12)]
    // str vAkoq, [input_addr, #(16*13)]
    // str vAkuq, [input_addr, #(16*14)]
    // str vAmaq, [input_addr, #(16*15)]
    // str vAmeq, [input_addr, #(16*16)]
    // str vAmiq, [input_addr, #(16*17)]
    // str vAmoq, [input_addr, #(16*18)]
    // str vAmuq, [input_addr, #(16*19)]
    // str vAsaq, [input_addr, #(16*20)]
    // str vAseq, [input_addr, #(16*21)]
    // str vAsiq, [input_addr, #(16*22)]
    // str vAsoq, [input_addr, #(16*23)]
    // str vAsuq, [input_addr, #(16*24)]
.endm

.macro load_input_scalar
    ldp s_Aba, sAbe, [input_addr,8*0 ]
    ldp sAbi, sAbo, [input_addr,8*2 ]
    ldp sAbu, sAga, [input_addr,8*4 ]
    ldp sAge, sAgi, [input_addr,8*6 ]
    ldp sAgo, sAgu, [input_addr,8*8 ]
    ldp sAka, sAke, [input_addr,8*10]
    ldp sAki, sAko, [input_addr,8*12]
    ldp sAku, sAma, [input_addr,8*14]
    ldp sAme, sAmi, [input_addr,8*16]
    ldp sAmo, sAmu, [input_addr,8*18]
    ldp sAsa, sAse, [input_addr,8*20]
    ldp sAsi, sAso, [input_addr,8*22]
    ldr sAsu,  [input_addr,8*24]
.endm

.macro store_input_scalar
    stp s_Aba, sAbe, [input_addr,8*0 ]
    stp sAbi, sAbo, [input_addr,8*2 ]
    stp sAbu, sAga, [input_addr,8*4 ]
    stp sAge, sAgi, [input_addr,8*6 ]
    stp sAgo, sAgu, [input_addr,8*8 ]
    stp sAka, sAke, [input_addr,8*10]
    stp sAki, sAko, [input_addr,8*12]
    stp sAku, sAma, [input_addr,8*14]
    stp sAme, sAmi, [input_addr,8*16]
    stp sAmo, sAmu, [input_addr,8*18]
    stp sAsa, sAse, [input_addr,8*20]
    stp sAsi, sAso, [input_addr,8*22]
    str sAsu,  [input_addr,8*24]
.endm


#define STACK_SIZE             (4*16 + 12*8 + 6*8 + 16*1)
#define STACK_BASE_VREGS       (0)
#define STACK_BASE_GPRS        (4*16)
#define STACK_BASE_TMP_GPRS    (4*16 + 12*8)
#define STACK_BASE_TMP_VREGS   (4*16 + 12*8 + 6*8)
#define STACK_OFFSET_INPUT     (0*8)
#define STACK_OFFSET_CONST     (1*8)
#define STACK_OFFSET_COUNT     (2*8)
#define STACK_OFFSET_COUNT_OUT (3*8)
#define STACK_OFFSET_CUR_INPUT (4*8)

#define vAga_offset 0

#define save(name) \
    str name ## q, [sp, #(STACK_BASE_TMP_VREGS + 16 * name ## _offset)]
#define restore(name) \
    ldr name ## q, [sp, #(STACK_BASE_TMP_VREGS + 16 * name ## _offset)]


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
eor sC0, sAma, sAsa                             SEP
eor sC1, sAme, sAse                             SEP      eor3_m1 C1,vAbe,vAge,vAke
eor sC2, sAmi, sAsi                             SEP
eor sC3, sAmo, sAso                             SEP
eor sC4, sAmu, sAsu                             SEP
eor sC0, sAka, sC0                              SEP      eor3_m1 C3,vAbo,vAgo,vAko
eor sC1, sAke, sC1                              SEP
eor sC2, sAki, sC2                              SEP
eor sC3, sAko, sC3                              SEP
eor sC4, sAku, sC4                              SEP      eor3_m1 C0,vAba,vAga,vAka
eor sC0, sAga, sC0                              SEP
eor sC1, sAge, sC1                              SEP
eor sC2, sAgi, sC2                              SEP
eor sC3, sAgo, sC3                              SEP      eor3_m1 C2,vAbi,vAgi,vAki
eor sC4, sAgu, sC4                              SEP
eor sC0, s_Aba, sC0                             SEP
eor sC1, sAbe, sC1                              SEP
eor sC2, sAbi, sC2                              SEP      eor3_m1 C4,vAbu,vAgu,vAku
eor sC3, sAbo, sC3                              SEP
eor sC4, sAbu, sC4                              SEP
eor sE1, sC0, sC2, ROR #63                      SEP
eor sE3, sC2, sC4, ROR #63                      SEP      eor3_m1 C1, C1,vAme, vAse
eor sE0, sC4, sC1, ROR #63                      SEP
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP
eor s_Aba_, s_Aba, sE0                          SEP      eor3_m1 C3, C3,vAmo, vAso
eor sAsa_, sAbi, sE2                            SEP
eor sAbi_, sAki, sE2                            SEP
eor sAki_, sAko, sE3                            SEP
eor sAko_, sAmu, sE4                            SEP      eor3_m1 C0, C0,vAma, vAsa
eor sAmu_, sAso, sE3                            SEP
eor sAso_, sAma, sE0                            SEP
eor sAka_, sAbe, sE1                            SEP
eor sAse_, sAgo, sE3                            SEP      eor3_m1 C2, C2,vAmi, vAsi
eor sAgo_, sAme, sE1                            SEP
eor sAke_, sAgi, sE2                            SEP
eor sAgi_, sAka, sE0                            SEP
eor sAga_, sAbo, sE3                            SEP      eor3_m1 C4, C4,vAmu, vAsu
eor sAbo_, sAmo, sE3                            SEP
eor sAmo_, sAmi, sE2                            SEP      vvtmp .req vBba
eor sAmi_, sAke, sE1                            SEP
eor sAge_, sAgu, sE4                            SEP      rax1_m1 E2, C1, C3
eor sAgu_, sAsi, sE2                            SEP
eor sAsi_, sAku, sE4                            SEP
eor sAku_, sAsa, sE0                            SEP
eor sAma_, sAbu, sE4                            SEP      rax1_m1 E4, C3, C0
eor sAbu_, sAsu, sE4                            SEP
eor sAsu_, sAse, sE1                            SEP
eor sAme_, sAga, sE0                            SEP
eor sAbe_, sAge, sE1                            SEP      rax1_m1 E1, C0, C2
load_constant_ptr                               SEP
bic tmp, sAgi_, sAge_, ROR #47                  SEP
eor sAga, tmp,  sAga_, ROR #39                  SEP
bic tmp, sAgo_, sAgi_, ROR #42                  SEP      rax1_m1 E3, C2, C4
eor sAge, tmp,  sAge_, ROR #25                  SEP
bic tmp, sAgu_, sAgo_, ROR #16                  SEP
eor sAgi, tmp,  sAgi_, ROR #58                  SEP
bic tmp, sAga_, sAgu_, ROR #31                  SEP      rax1_m1 E0, C4, C1
eor sAgo, tmp,  sAgo_, ROR #47                  SEP
bic tmp, sAge_, sAga_, ROR #56                  SEP      .unreq vvtmp
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP      vvtmp .req C1
eor sAka, tmp,  sAka_, ROR #24                  SEP
bic tmp, sAko_, sAki_, ROR #47                  SEP      vvtmpq .req C1q
eor sAke, tmp,  sAke_, ROR #2                   SEP
bic tmp, sAku_, sAko_, ROR #10                  SEP      eor vBba.16b, vAba.16b, E0.16b
eor sAki, tmp,  sAki_, ROR #57                  SEP
bic tmp, sAka_, sAku_, ROR #47                  SEP      xar_m1 vBsa, vAbi, E2, 2
eor sAko, tmp,  sAko_, ROR #57                  SEP
bic tmp, sAke_, sAka_, ROR #5                   SEP
eor sAku, tmp,  sAku_, ROR #52                  SEP
bic tmp, sAmi_, sAme_, ROR #38                  SEP      xar_m1 vBbi, vAki, E2, 21
eor sAma, tmp,  sAma_, ROR #47                  SEP
bic tmp, sAmo_, sAmi_, ROR #5                   SEP
eor sAme, tmp,  sAme_, ROR #43                  SEP
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      xar_m1 vBki, vAko, E3, 39
eor sAmi, tmp,  sAmi_, ROR #46                  SEP
ldr cur_const, [const_addr]                     SEP
mov count, #1                                   SEP
bic tmp, sAma_, sAmu_, ROR #35                  SEP      xar_m1 vBko, vAmu, E4, 56
eor sAmo, tmp,  sAmo_, ROR #12                  SEP
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP
bic tmp, sAsi_, sAse_, ROR #48                  SEP      xar_m1 vBmu, vAso, E3, 8
eor sAsa, tmp,  sAsa_, ROR #41                  SEP
bic tmp, sAso_, sAsi_, ROR #2                   SEP
eor sAse, tmp,  sAse_, ROR #50                  SEP
bic tmp, sAsu_, sAso_, ROR #25                  SEP      xar_m1 vBso, vAma, E0, 23
eor sAsi, tmp,  sAsi_, ROR #27                  SEP
bic tmp, sAsa_, sAsu_, ROR #60                  SEP
eor sAso, tmp,  sAso_, ROR #21                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP      xar_m1 vBka, vAbe, E1, 63
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      xar_m1 vBse, vAgo, E3, 9
eor sAbe, tmp,  sAbe_, ROR #41                  SEP
bic tmp, sAbu_, sAbo_, ROR #57                  SEP
eor sAbi, tmp,  sAbi_, ROR #35                  SEP
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP      xar_m1 vBgo, vAme, E1, 19
eor sAbo, tmp,  sAbo_, ROR #43                  SEP
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
eor sAbu, tmp,  sAbu_, ROR #30                  SEP
eor s_Aba, s_Aba, cur_const                     SEP      xar_m1 vBke, vAgi, E2, 58
save count, STACK_OFFSET_COUNT                  SEP
eor sC0, sAka, sAsa, ROR #50                    SEP
eor sC1, sAse, sAge, ROR #60                    SEP
eor sC2, sAmi, sAgi, ROR #59                    SEP      xar_m1 vBgi, vAka, E0, 61
eor sC3, sAgo, sAso, ROR #30                    SEP
eor sC4, sAbu, sAsu, ROR #53                    SEP
eor sC0, sAma, sC0, ROR #49                     SEP
eor sC1, sAbe, sC1, ROR #44                     SEP      xar_m1 vBga, vAbo, E3, 36
eor sC2, sAki, sC2, ROR #26                     SEP
eor sC3, sAmo, sC3, ROR #63                     SEP
eor sC4, sAmu, sC4, ROR #56                     SEP
eor sC0, sAga, sC0, ROR #57                     SEP      xar_m1 vBbo, vAmo, E3, 43
eor sC1, sAme, sC1, ROR #58                     SEP
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP
eor sC4, sAgu, sC4, ROR #48                     SEP      xar_m1 vBmo, vAmi, E2, 49
eor sC0, s_Aba, sC0, ROR #61                    SEP
eor sC1, sAke, sC1, ROR #57                     SEP
eor sC2, sAsi, sC2, ROR #52                     SEP
eor sC3, sAbo, sC3, ROR #63                     SEP
eor sC4, sAku, sC4, ROR #50                     SEP      xar_m1 vBmi, vAke, E1, 54
ror sC1, sC1, 56                                SEP
ror sC4, sC4, 58                                SEP
ror sC2, sC2, 62                                SEP
eor sE1, sC0, sC2, ROR #63                      SEP      xar_m1 vBge, vAgu, E4, 44
eor sE3, sC2, sC4, ROR #63                      SEP
eor sE0, sC4, sC1, ROR #63                      SEP      mov E3.16b, vAga.16b
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor s_Aba_, sE0, s_Aba                          SEP
eor sAsa_, sE2, sAbi, ROR #50                   SEP
eor sAbi_, sE2, sAki, ROR #46                   SEP      xar_m1 vBgu, vAsi, E2, 3
eor sAki_, sE3, sAko, ROR #63                   SEP
eor sAko_, sE4, sAmu, ROR #28                   SEP
eor sAmu_, sE3, sAso, ROR #2                    SEP
eor sAso_, sE0, sAma, ROR #54                   SEP      xar_m1 vBsi, vAku, E4, 25
eor sAka_, sE1, sAbe, ROR #43                   SEP
eor sAse_, sE3, sAgo, ROR #36                   SEP
eor sAgo_, sE1, sAme, ROR #49                   SEP
eor sAke_, sE2, sAgi, ROR #3                    SEP      xar_m1 vBku, vAsa, E0, 46
eor sAgi_, sE0, sAka, ROR #39                   SEP
eor sAga_, sE3, sAbo                            SEP
eor sAbo_, sE3, sAmo, ROR #37                   SEP
eor sAmo_, sE2, sAmi, ROR #8                    SEP
eor sAmi_, sE1, sAke, ROR #56                   SEP
eor sAge_, sE4, sAgu, ROR #44                   SEP
eor sAgu_, sE2, sAsi, ROR #62                   SEP      xar_m1 vBma, vAbu, E4, 37
eor sAsi_, sE4, sAku, ROR #58                   SEP
eor sAku_, sE0, sAsa, ROR #25                   SEP
eor sAma_, sE4, sAbu, ROR #20                   SEP
eor sAbu_, sE4, sAsu, ROR #9                    SEP
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP
eor sAbe_, sE1, sAge, ROR #19                   SEP      xar_m1 vBbu, vAsu, E4, 50
load_constant_ptr                               SEP
restore count, STACK_OFFSET_COUNT               SEP
bic tmp, sAgi_, sAge_, ROR #47                  SEP
eor sAga, tmp,  sAga_, ROR #39                  SEP
bic tmp, sAgo_, sAgi_, ROR #42                  SEP      xar_m1 vBsu, vAse, E1, 62
eor sAge, tmp,  sAge_, ROR #25                  SEP
bic tmp, sAgu_, sAgo_, ROR #16                  SEP
eor sAgi, tmp,  sAgi_, ROR #58                  SEP
bic tmp, sAga_, sAgu_, ROR #31                  SEP
eor sAgo, tmp,  sAgo_, ROR #47                  SEP
bic tmp, sAge_, sAga_, ROR #56                  SEP
eor sAgu, tmp,  sAgu_, ROR #23                  SEP      xar_m1 vBme, E3, E0, 28
bic tmp, sAki_, sAke_, ROR #19                  SEP
eor sAka, tmp,  sAka_, ROR #24                  SEP
bic tmp, sAko_, sAki_, ROR #47                  SEP
eor sAke, tmp,  sAke_, ROR #2                   SEP
bic tmp, sAku_, sAko_, ROR #10                  SEP
eor sAki, tmp,  sAki_, ROR #57                  SEP      xar_m1 vBbe, vAge, E1, 20
bic tmp, sAka_, sAku_, ROR #47                  SEP
eor sAko, tmp,  sAko_, ROR #57                  SEP
bic tmp, sAke_, sAka_, ROR #5                   SEP
eor sAku, tmp,  sAku_, ROR #52                  SEP
bic tmp, sAmi_, sAme_, ROR #38                  SEP
eor sAma, tmp,  sAma_, ROR #47                  SEP      bcax_m1 vAge, vBge, vBgo, vBgi
bic tmp, sAmo_, sAmi_, ROR #5                   SEP
eor sAme, tmp,  sAme_, ROR #43                  SEP
bic tmp, sAmu_, sAmo_, ROR #41                  SEP
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      bcax_m1 vAgi, vBgi, vBgu, vBgo
bic tmp, sAma_, sAmu_, ROR #35                  SEP
eor sAmo, tmp,  sAmo_, ROR #12                  SEP
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
bic tmp, sAsi_, sAse_, ROR #48                  SEP
ldr cur_const, [const_addr, count, UXTW #3]     SEP
eor sAsa, tmp,  sAsa_, ROR #41                  SEP
bic tmp, sAso_, sAsi_, ROR #2                   SEP      bcax_m1 vAgu, vBgu, vBge, vBga
eor sAse, tmp,  sAse_, ROR #50                  SEP
bic tmp, sAsu_, sAso_, ROR #25                  SEP
eor sAsi, tmp,  sAsi_, ROR #27                  SEP
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sAso, tmp,  sAso_, ROR #21                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      bcax_m1 vAke, vBke, vBko, vBki
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP      .unreq vvtmp
bic tmp, sAbo_, sAbi_, ROR #42                  SEP
eor sAbe, tmp,  sAbe_, ROR #41                  SEP      .unreq vvtmpq
bic tmp, sAbu_, sAbo_, ROR #57                  SEP      eor2    C0,  vAka, vAga
eor sAbi, tmp,  sAbi_, ROR #35                  SEP      vvtmp  .req vAga
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP      save(vAga)
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      vvtmpq .req vAgaq
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP      bcax_m1 vAki, vBki, vBku, vBko
eor sAbu, tmp,  sAbu_, ROR #30                  SEP
add count, count, #1                            SEP
eor s_Aba, s_Aba, cur_const                     SEP
                                                SEP
save count, STACK_OFFSET_COUNT                  SEP      bcax_m1 vAko, vBko, vBka, vBku
eor sC0, sAka, sAsa, ROR #50                    SEP
eor sC1, sAse, sAge, ROR #60                    SEP
eor sC2, sAmi, sAgi, ROR #59                    SEP
eor sC3, sAgo, sAso, ROR #30                    SEP      eor2    C1,  vAke, vAge
eor sC4, sAbu, sAsu, ROR #53                    SEP
eor sC0, sAma, sC0, ROR #49                     SEP      bcax_m1 vAku, vBku, vBke, vBka
eor sC1, sAbe, sC1, ROR #44                     SEP
eor sC2, sAki, sC2, ROR #26                     SEP
eor sC3, sAmo, sC3, ROR #63                     SEP
eor sC4, sAmu, sC4, ROR #56                     SEP      eor2    C2,  vAki, vAgi
eor sC0, sAga, sC0, ROR #57                     SEP
eor sC1, sAme, sC1, ROR #58                     SEP      bcax_m1 vAma, vBma, vBmi, vBme
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP
eor sC4, sAgu, sC4, ROR #48                     SEP
eor sC0, s_Aba, sC0, ROR #61                    SEP      eor2    C3,  vAko, vAgo
eor sC1, sAke, sC1, ROR #57                     SEP
eor sC2, sAsi, sC2, ROR #52                     SEP      bcax_m1 vAme, vBme, vBmo, vBmi
eor sC3, sAbo, sC3, ROR #63                     SEP
eor sC4, sAku, sC4, ROR #50                     SEP
ror sC1, sC1, 56                                SEP
ror sC4, sC4, 58                                SEP      eor2    C4,  vAku, vAgu
ror sC2, sC2, 62                                SEP
eor sE1, sC0, sC2, ROR #63                      SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
eor sE3, sC2, sC4, ROR #63                      SEP
eor sE0, sC4, sC1, ROR #63                      SEP
eor sE2, sC1, sC3, ROR #63                      SEP      eor2    C0,  C0,  vAma
eor sE4, sC3, sC0, ROR #63                      SEP
eor s_Aba_, sE0, s_Aba                          SEP      bcax_m1 vAmo, vBmo, vBma, vBmu
eor sAsa_, sE2, sAbi, ROR #50                   SEP
eor sAbi_, sE2, sAki, ROR #46                   SEP
eor sAki_, sE3, sAko, ROR #63                   SEP
eor sAko_, sE4, sAmu, ROR #28                   SEP      eor2    C1,  C1,  vAme
eor sAmu_, sE3, sAso, ROR #2                    SEP
eor sAso_, sE0, sAma, ROR #54                   SEP      bcax_m1 vAmu, vBmu, vBme, vBma
eor sAka_, sE1, sAbe, ROR #43                   SEP
eor sAse_, sE3, sAgo, ROR #36                   SEP
eor sAgo_, sE1, sAme, ROR #49                   SEP      eor2    C2,  C2,  vAmi
eor sAke_, sE2, sAgi, ROR #3                    SEP
eor sAgi_, sE0, sAka, ROR #39                   SEP      bcax_m1 vAsa, vBsa, vBsi, vBse
eor sAga_, sE3, sAbo                            SEP
eor sAbo_, sE3, sAmo, ROR #37                   SEP      eor2    C3,  C3,  vAmo
eor sAmo_, sE2, sAmi, ROR #8                    SEP
eor sAmi_, sE1, sAke, ROR #56                   SEP      bcax_m1 vAse, vBse, vBso, vBsi
eor sAge_, sE4, sAgu, ROR #44                   SEP
eor sAgu_, sE2, sAsi, ROR #62                   SEP
eor sAsi_, sE4, sAku, ROR #58                   SEP
eor sAku_, sE0, sAsa, ROR #25                   SEP      eor2    C4,  C4,  vAmu
eor sAma_, sE4, sAbu, ROR #20                   SEP
eor sAbu_, sE4, sAsu, ROR #9                    SEP      bcax_m1 vAsi, vBsi, vBsu, vBso
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP
eor sAbe_, sE1, sAge, ROR #19                   SEP
load_constant_ptr                               SEP      eor2    C0,  C0,  vAsa
restore count, STACK_OFFSET_COUNT               SEP
bic tmp, sAgi_, sAge_, ROR #47                  SEP      bcax_m1 vAso, vBso, vBsa, vBsu
eor sAga, tmp,  sAga_, ROR #39                  SEP
bic tmp, sAgo_, sAgi_, ROR #42                  SEP
eor sAge, tmp,  sAge_, ROR #25                  SEP
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      eor2    C1,  C1,  vAse
eor sAgi, tmp,  sAgi_, ROR #58                  SEP
bic tmp, sAga_, sAgu_, ROR #31                  SEP      bcax_m1 vAsu, vBsu, vBse, vBsa
eor sAgo, tmp,  sAgo_, ROR #47                  SEP
bic tmp, sAge_, sAga_, ROR #56                  SEP
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP      eor2    C2,  C2,  vAsi
eor sAka, tmp,  sAka_, ROR #24                  SEP
bic tmp, sAko_, sAki_, ROR #47                  SEP      eor2    C3,  C3,  vAso
eor sAke, tmp,  sAke_, ROR #2                   SEP
bic tmp, sAku_, sAko_, ROR #10                  SEP      bcax_m1 vAba, vBba, vBbi, vBbe
eor sAki, tmp,  sAki_, ROR #57                  SEP
bic tmp, sAka_, sAku_, ROR #47                  SEP
eor sAko, tmp,  sAko_, ROR #57                  SEP
bic tmp, sAke_, sAka_, ROR #5                   SEP      bcax_m1 vAbe, vBbe, vBbo, vBbi
eor sAku, tmp,  sAku_, ROR #52                  SEP
bic tmp, sAmi_, sAme_, ROR #38                  SEP
eor sAma, tmp,  sAma_, ROR #47                  SEP
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      eor2    C1,  C1,  vAbe
eor sAme, tmp,  sAme_, ROR #43                  SEP      restore x26, STACK_OFFSET_CONST
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      ldr vvtmpq, [x26], #16
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      save x26, STACK_OFFSET_CONST
bic tmp, sAma_, sAmu_, ROR #35                  SEP
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      eor vAba.16b, vAba.16b, vvtmp.16b
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      eor2    C4,  C4,  vAsu
bic tmp, sAsi_, sAse_, ROR #48                  SEP
ldr cur_const, [const_addr, count, UXTW #3]     SEP      bcax_m1 vAbi, vBbi, vBbu, vBbo
eor sAsa, tmp,  sAsa_, ROR #41                  SEP
bic tmp, sAso_, sAsi_, ROR #2                   SEP
eor sAse, tmp,  sAse_, ROR #50                  SEP
bic tmp, sAsu_, sAso_, ROR #25                  SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
eor sAsi, tmp,  sAsi_, ROR #27                  SEP
bic tmp, sAsa_, sAsu_, ROR #60                  SEP
eor sAso, tmp,  sAso_, ROR #21                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP      eor2    C3,  C3,  vAbo
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      eor2    C2,  C2,  vAbi
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      eor2    C0,  C0,  vAba
eor sAbe, tmp,  sAbe_, ROR #41                  SEP
bic tmp, sAbu_, sAbo_, ROR #57                  SEP      bcax_m1 vAbu, vBbu, vBbe, vBba
eor sAbi, tmp,  sAbi_, ROR #35                  SEP
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP
eor sAbo, tmp,  sAbo_, ROR #43                  SEP
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP      eor2    C4,  C4,  vAbu
eor sAbu, tmp,  sAbu_, ROR #30                  SEP
add count, count, #1                            SEP      restore(vAga)
eor s_Aba, s_Aba, cur_const                     SEP
                                                         .unreq vvtmp

                                                         .unreq vvtmpq
.endm

.macro  hybrid_round_noninitial
                                    SEP      vvtmp .req vBba
save count, STACK_OFFSET_COUNT      SEP      rax1_m1 E2, C1, C3
eor sC0, sAka, sAsa, ROR #50        SEP
eor sC1, sAse, sAge, ROR #60        SEP
eor sC2, sAmi, sAgi, ROR #59        SEP
eor sC3, sAgo, sAso, ROR #30        SEP
eor sC4, sAbu, sAsu, ROR #53        SEP
eor sC0, sAma, sC0, ROR #49         SEP      rax1_m1 E4, C3, C0
eor sC1, sAbe, sC1, ROR #44         SEP
eor sC2, sAki, sC2, ROR #26         SEP
eor sC3, sAmo, sC3, ROR #63         SEP
eor sC4, sAmu, sC4, ROR #56         SEP
eor sC0, sAga, sC0, ROR #57         SEP
eor sC1, sAme, sC1, ROR #58         SEP      rax1_m1 E1, C0, C2
eor sC2, sAbi, sC2, ROR #60         SEP
eor sC3, sAko, sC3, ROR #38         SEP
eor sC4, sAgu, sC4, ROR #48         SEP
eor sC0, s_Aba, sC0, ROR #61        SEP
eor sC1, sAke, sC1, ROR #57         SEP
eor sC2, sAsi, sC2, ROR #52         SEP      rax1_m1 E3, C2, C4
eor sC3, sAbo, sC3, ROR #63         SEP
eor sC4, sAku, sC4, ROR #50         SEP
ror sC1, sC1, 56                    SEP
ror sC4, sC4, 58                    SEP
ror sC2, sC2, 62                    SEP
eor sE1, sC0, sC2, ROR #63          SEP      rax1_m1 E0, C4, C1
eor sE3, sC2, sC4, ROR #63          SEP
eor sE0, sC4, sC1, ROR #63          SEP      .unreq vvtmp
eor sE2, sC1, sC3, ROR #63          SEP      vvtmp .req C1
eor sE4, sC3, sC0, ROR #63          SEP      vvtmpq .req C1q
eor s_Aba_, sE0, s_Aba              SEP
eor sAsa_, sE2, sAbi, ROR #50       SEP      eor vBba.16b, vAba.16b, E0.16b
eor sAbi_, sE2, sAki, ROR #46       SEP
eor sAki_, sE3, sAko, ROR #63       SEP      xar_m1 vBsa, vAbi, E2, 2
eor sAko_, sE4, sAmu, ROR #28       SEP
eor sAmu_, sE3, sAso, ROR #2        SEP
eor sAso_, sE0, sAma, ROR #54       SEP
eor sAka_, sE1, sAbe, ROR #43       SEP
eor sAse_, sE3, sAgo, ROR #36       SEP
eor sAgo_, sE1, sAme, ROR #49       SEP      xar_m1 vBbi, vAki, E2, 21
eor sAke_, sE2, sAgi, ROR #3        SEP
eor sAgi_, sE0, sAka, ROR #39       SEP
eor sAga_, sE3, sAbo                SEP
eor sAbo_, sE3, sAmo, ROR #37       SEP
eor sAmo_, sE2, sAmi, ROR #8        SEP
eor sAmi_, sE1, sAke, ROR #56       SEP      xar_m1 vBki, vAko, E3, 39
eor sAge_, sE4, sAgu, ROR #44       SEP
eor sAgu_, sE2, sAsi, ROR #62       SEP
eor sAsi_, sE4, sAku, ROR #58       SEP
eor sAku_, sE0, sAsa, ROR #25       SEP
eor sAma_, sE4, sAbu, ROR #20       SEP
eor sAbu_, sE4, sAsu, ROR #9        SEP      xar_m1 vBko, vAmu, E4, 56
eor sAsu_, sE1, sAse, ROR #23       SEP
eor sAme_, sE0, sAga, ROR #61       SEP
eor sAbe_, sE1, sAge, ROR #19       SEP
load_constant_ptr                   SEP
restore count, STACK_OFFSET_COUNT   SEP
bic tmp, sAgi_, sAge_, ROR #47      SEP      xar_m1 vBmu, vAso, E3, 8
eor sAga, tmp,  sAga_, ROR #39      SEP
bic tmp, sAgo_, sAgi_, ROR #42      SEP
eor sAge, tmp,  sAge_, ROR #25      SEP
bic tmp, sAgu_, sAgo_, ROR #16      SEP
eor sAgi, tmp,  sAgi_, ROR #58      SEP
bic tmp, sAga_, sAgu_, ROR #31      SEP      xar_m1 vBso, vAma, E0, 23
eor sAgo, tmp,  sAgo_, ROR #47      SEP
bic tmp, sAge_, sAga_, ROR #56      SEP
eor sAgu, tmp,  sAgu_, ROR #23      SEP
bic tmp, sAki_, sAke_, ROR #19      SEP
eor sAka, tmp,  sAka_, ROR #24      SEP
bic tmp, sAko_, sAki_, ROR #47      SEP      xar_m1 vBka, vAbe, E1, 63
eor sAke, tmp,  sAke_, ROR #2       SEP
bic tmp, sAku_, sAko_, ROR #10      SEP
eor sAki, tmp,  sAki_, ROR #57      SEP
bic tmp, sAka_, sAku_, ROR #47      SEP
eor sAko, tmp,  sAko_, ROR #57      SEP
bic tmp, sAke_, sAka_, ROR #5       SEP      xar_m1 vBse, vAgo, E3, 9
eor sAku, tmp,  sAku_, ROR #52      SEP
bic tmp, sAmi_, sAme_, ROR #38      SEP
eor sAma, tmp,  sAma_, ROR #47      SEP
bic tmp, sAmo_, sAmi_, ROR #5       SEP
eor sAme, tmp,  sAme_, ROR #43      SEP      xar_m1 vBgo, vAme, E1, 19
bic tmp, sAmu_, sAmo_, ROR #41      SEP
eor sAmi, tmp,  sAmi_, ROR #46      SEP
bic tmp, sAma_, sAmu_, ROR #35      SEP
ldr cur_const, [const_addr, count, UXTW #3]
add count, count, #1                SEP      xar_m1 vBke, vAgi, E2, 58
eor sAmo, tmp,  sAmo_, ROR #12      SEP
bic tmp, sAme_, sAma_, ROR #9       SEP
eor sAmu, tmp,  sAmu_, ROR #44      SEP
bic tmp, sAsi_, sAse_, ROR #48      SEP
eor sAsa, tmp,  sAsa_, ROR #41      SEP      xar_m1 vBgi, vAka, E0, 61
bic tmp, sAso_, sAsi_, ROR #2       SEP
eor sAse, tmp,  sAse_, ROR #50      SEP
bic tmp, sAsu_, sAso_, ROR #25      SEP
eor sAsi, tmp,  sAsi_, ROR #27      SEP
bic tmp, sAsa_, sAsu_, ROR #60      SEP
eor sAso, tmp,  sAso_, ROR #21      SEP      xar_m1 vBga, vAbo, E3, 36
bic tmp, sAse_, sAsa_, ROR #57      SEP
eor sAsu, tmp,  sAsu_, ROR #53      SEP
bic tmp, sAbi_, sAbe_, ROR #63      SEP
eor s_Aba, s_Aba_, tmp,  ROR #21    SEP
bic tmp, sAbo_, sAbi_, ROR #42      SEP
eor sAbe, tmp,  sAbe_, ROR #41      SEP      xar_m1 vBbo, vAmo, E3, 43
bic tmp, sAbu_, sAbo_, ROR #57      SEP
eor sAbi, tmp,  sAbi_, ROR #35      SEP
bic tmp, s_Aba_, sAbu_, ROR #50     SEP
eor sAbo, tmp,  sAbo_, ROR #43      SEP
bic tmp, sAbe_, s_Aba_, ROR #44     SEP
eor sAbu, tmp,  sAbu_, ROR #30      SEP      xar_m1 vBmo, vAmi, E2, 49
eor s_Aba, s_Aba, cur_const         SEP
save count, STACK_OFFSET_COUNT      SEP
eor sC0, sAka, sAsa, ROR #50        SEP
eor sC1, sAse, sAge, ROR #60        SEP
eor sC2, sAmi, sAgi, ROR #59        SEP
eor sC3, sAgo, sAso, ROR #30        SEP      xar_m1 vBmi, vAke, E1, 54
eor sC4, sAbu, sAsu, ROR #53        SEP
eor sC0, sAma, sC0, ROR #49         SEP
eor sC1, sAbe, sC1, ROR #44         SEP
eor sC2, sAki, sC2, ROR #26         SEP
eor sC3, sAmo, sC3, ROR #63         SEP
eor sC4, sAmu, sC4, ROR #56         SEP
eor sC0, sAga, sC0, ROR #57         SEP      xar_m1 vBge, vAgu, E4, 44
eor sC1, sAme, sC1, ROR #58         SEP
eor sC2, sAbi, sC2, ROR #60         SEP
eor sC3, sAko, sC3, ROR #38         SEP
eor sC4, sAgu, sC4, ROR #48         SEP
eor sC0, s_Aba, sC0, ROR #61        SEP
eor sC1, sAke, sC1, ROR #57         SEP      mov E3.16b, vAga.16b
eor sC2, sAsi, sC2, ROR #52         SEP
eor sC3, sAbo, sC3, ROR #63         SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor sC4, sAku, sC4, ROR #50         SEP
ror sC1, sC1, 56                    SEP
ror sC4, sC4, 58                    SEP
ror sC2, sC2, 62                    SEP      xar_m1 vBgu, vAsi, E2, 3
eor sE1, sC0, sC2, ROR #63          SEP
eor sE3, sC2, sC4, ROR #63          SEP
eor sE0, sC4, sC1, ROR #63          SEP
eor sE2, sC1, sC3, ROR #63          SEP
eor sE4, sC3, sC0, ROR #63          SEP
eor s_Aba_, sE0, s_Aba              SEP      xar_m1 vBsi, vAku, E4, 25
eor sAsa_, sE2, sAbi, ROR #50       SEP
eor sAbi_, sE2, sAki, ROR #46       SEP
eor sAki_, sE3, sAko, ROR #63       SEP
eor sAko_, sE4, sAmu, ROR #28       SEP
eor sAmu_, sE3, sAso, ROR #2        SEP
eor sAso_, sE0, sAma, ROR #54       SEP      xar_m1 vBku, vAsa, E0, 46
eor sAka_, sE1, sAbe, ROR #43       SEP
eor sAse_, sE3, sAgo, ROR #36       SEP
eor sAgo_, sE1, sAme, ROR #49       SEP
eor sAke_, sE2, sAgi, ROR #3        SEP
eor sAgi_, sE0, sAka, ROR #39       SEP
eor sAga_, sE3, sAbo                SEP      xar_m1 vBma, vAbu, E4, 37
eor sAbo_, sE3, sAmo, ROR #37       SEP
eor sAmo_, sE2, sAmi, ROR #8        SEP
eor sAmi_, sE1, sAke, ROR #56       SEP
eor sAge_, sE4, sAgu, ROR #44       SEP
eor sAgu_, sE2, sAsi, ROR #62       SEP      xar_m1 vBbu, vAsu, E4, 50
eor sAsi_, sE4, sAku, ROR #58       SEP
eor sAku_, sE0, sAsa, ROR #25       SEP
eor sAma_, sE4, sAbu, ROR #20       SEP
eor sAbu_, sE4, sAsu, ROR #9        SEP
eor sAsu_, sE1, sAse, ROR #23       SEP      xar_m1 vBsu, vAse, E1, 62
eor sAme_, sE0, sAga, ROR #61       SEP
eor sAbe_, sE1, sAge, ROR #19       SEP
load_constant_ptr                   SEP
restore count, STACK_OFFSET_COUNT   SEP
bic tmp, sAgi_, sAge_, ROR #47      SEP
eor sAga, tmp,  sAga_, ROR #39      SEP      xar_m1 vBme, E3, E0, 28
bic tmp, sAgo_, sAgi_, ROR #42      SEP
eor sAge, tmp,  sAge_, ROR #25      SEP
bic tmp, sAgu_, sAgo_, ROR #16      SEP
eor sAgi, tmp,  sAgi_, ROR #58      SEP
bic tmp, sAga_, sAgu_, ROR #31      SEP
eor sAgo, tmp,  sAgo_, ROR #47      SEP      xar_m1 vBbe, vAge, E1, 20
bic tmp, sAge_, sAga_, ROR #56      SEP
eor sAgu, tmp,  sAgu_, ROR #23      SEP
bic tmp, sAki_, sAke_, ROR #19      SEP
eor sAka, tmp,  sAka_, ROR #24      SEP
bic tmp, sAko_, sAki_, ROR #47      SEP      bcax_m1 vAge, vBge, vBgo, vBgi
eor sAke, tmp,  sAke_, ROR #2       SEP
bic tmp, sAku_, sAko_, ROR #10      SEP
eor sAki, tmp,  sAki_, ROR #57      SEP
bic tmp, sAka_, sAku_, ROR #47      SEP      bcax_m1 vAgi, vBgi, vBgu, vBgo
eor sAko, tmp,  sAko_, ROR #57      SEP
bic tmp, sAke_, sAka_, ROR #5       SEP
eor sAku, tmp,  sAku_, ROR #52      SEP
bic tmp, sAmi_, sAme_, ROR #38      SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
eor sAma, tmp,  sAma_, ROR #47      SEP
bic tmp, sAmo_, sAmi_, ROR #5       SEP
eor sAme, tmp,  sAme_, ROR #43      SEP
bic tmp, sAmu_, sAmo_, ROR #41      SEP      bcax_m1 vAgu, vBgu, vBge, vBga
eor sAmi, tmp,  sAmi_, ROR #46      SEP
bic tmp, sAma_, sAmu_, ROR #35      SEP
ldr cur_const, [const_addr, count, UXTW #3]
add count, count, #1                SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sAmo, tmp,  sAmo_, ROR #12      SEP
bic tmp, sAme_, sAma_, ROR #9       SEP
eor sAmu, tmp,  sAmu_, ROR #44      SEP
bic tmp, sAsi_, sAse_, ROR #48      SEP      bcax_m1 vAke, vBke, vBko, vBki
eor sAsa, tmp,  sAsa_, ROR #41      SEP      .unreq vvtmp
bic tmp, sAso_, sAsi_, ROR #2       SEP      .unreq vvtmpq
eor sAse, tmp,  sAse_, ROR #50      SEP
bic tmp, sAsu_, sAso_, ROR #25      SEP      eor2    C0,  vAka, vAga
eor sAsi, tmp,  sAsi_, ROR #27      SEP      save(vAga)
bic tmp, sAsa_, sAsu_, ROR #60      SEP      vvtmp .req vAga
eor sAso, tmp,  sAso_, ROR #21      SEP      vvtmpq .req vAgaq
bic tmp, sAse_, sAsa_, ROR #57      SEP      bcax_m1 vAki, vBki, vBku, vBko
eor sAsu, tmp,  sAsu_, ROR #53      SEP
bic tmp, sAbi_, sAbe_, ROR #63      SEP
eor s_Aba, s_Aba_, tmp,  ROR #21    SEP
bic tmp, sAbo_, sAbi_, ROR #42      SEP      bcax_m1 vAko, vBko, vBka, vBku
eor sAbe, tmp,  sAbe_, ROR #41      SEP
bic tmp, sAbu_, sAbo_, ROR #57      SEP
eor sAbi, tmp,  sAbi_, ROR #35      SEP
bic tmp, s_Aba_, sAbu_, ROR #50     SEP      eor2    C1,  vAke, vAge
eor sAbo, tmp,  sAbo_, ROR #43      SEP
bic tmp, sAbe_, s_Aba_, ROR #44     SEP      bcax_m1 vAku, vBku, vBke, vBka
eor sAbu, tmp,  sAbu_, ROR #30      SEP
eor s_Aba, s_Aba, cur_const         SEP
                                    SEP
save count, STACK_OFFSET_COUNT      SEP
eor sC0, sAka, sAsa, ROR #50        SEP
eor sC1, sAse, sAge, ROR #60        SEP      eor2    C2,  vAki, vAgi
eor sC2, sAmi, sAgi, ROR #59        SEP
eor sC3, sAgo, sAso, ROR #30        SEP      bcax_m1 vAma, vBma, vBmi, vBme
eor sC4, sAbu, sAsu, ROR #53        SEP
eor sC0, sAma, sC0, ROR #49         SEP
eor sC1, sAbe, sC1, ROR #44         SEP
eor sC2, sAki, sC2, ROR #26         SEP      eor2    C3,  vAko, vAgo
eor sC3, sAmo, sC3, ROR #63         SEP
eor sC4, sAmu, sC4, ROR #56         SEP      bcax_m1 vAme, vBme, vBmo, vBmi
eor sC0, sAga, sC0, ROR #57         SEP
eor sC1, sAme, sC1, ROR #58         SEP
eor sC2, sAbi, sC2, ROR #60         SEP
eor sC3, sAko, sC3, ROR #38         SEP      eor2    C4,  vAku, vAgu
eor sC4, sAgu, sC4, ROR #48         SEP
eor sC0, s_Aba, sC0, ROR #61        SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
eor sC1, sAke, sC1, ROR #57         SEP
eor sC2, sAsi, sC2, ROR #52         SEP
eor sC3, sAbo, sC3, ROR #63         SEP
eor sC4, sAku, sC4, ROR #50         SEP      eor2    C0,  C0,  vAma
ror sC1, sC1, 56                    SEP
ror sC4, sC4, 58                    SEP      bcax_m1 vAmo, vBmo, vBma, vBmu
ror sC2, sC2, 62                    SEP
eor sE1, sC0, sC2, ROR #63          SEP
eor sE3, sC2, sC4, ROR #63          SEP
eor sE0, sC4, sC1, ROR #63          SEP      eor2    C1,  C1,  vAme
eor sE2, sC1, sC3, ROR #63          SEP
eor sE4, sC3, sC0, ROR #63          SEP      bcax_m1 vAmu, vBmu, vBme, vBma
eor s_Aba_, sE0, s_Aba              SEP
eor sAsa_, sE2, sAbi, ROR #50       SEP
eor sAbi_, sE2, sAki, ROR #46       SEP
eor sAki_, sE3, sAko, ROR #63       SEP      eor2    C2,  C2,  vAmi
eor sAko_, sE4, sAmu, ROR #28       SEP
eor sAmu_, sE3, sAso, ROR #2        SEP      bcax_m1 vAsa, vBsa, vBsi, vBse
eor sAso_, sE0, sAma, ROR #54       SEP
eor sAka_, sE1, sAbe, ROR #43       SEP
eor sAse_, sE3, sAgo, ROR #36       SEP
eor sAgo_, sE1, sAme, ROR #49       SEP      eor2    C3,  C3,  vAmo
eor sAke_, sE2, sAgi, ROR #3        SEP
eor sAgi_, sE0, sAka, ROR #39       SEP      bcax_m1 vAse, vBse, vBso, vBsi
eor sAga_, sE3, sAbo                SEP
eor sAbo_, sE3, sAmo, ROR #37       SEP
eor sAmo_, sE2, sAmi, ROR #8        SEP
eor sAmi_, sE1, sAke, ROR #56       SEP      eor2    C4,  C4,  vAmu
eor sAge_, sE4, sAgu, ROR #44       SEP
eor sAgu_, sE2, sAsi, ROR #62       SEP      bcax_m1 vAsi, vBsi, vBsu, vBso
eor sAsi_, sE4, sAku, ROR #58       SEP
eor sAku_, sE0, sAsa, ROR #25       SEP
eor sAma_, sE4, sAbu, ROR #20       SEP
eor sAbu_, sE4, sAsu, ROR #9        SEP      eor2    C0,  C0,  vAsa
eor sAsu_, sE1, sAse, ROR #23       SEP
eor sAme_, sE0, sAga, ROR #61       SEP      bcax_m1 vAso, vBso, vBsa, vBsu
eor sAbe_, sE1, sAge, ROR #19       SEP
load_constant_ptr                   SEP
restore count, STACK_OFFSET_COUNT   SEP
bic tmp, sAgi_, sAge_, ROR #47      SEP
eor sAga, tmp,  sAga_, ROR #39      SEP
bic tmp, sAgo_, sAgi_, ROR #42      SEP      eor2    C1,  C1,  vAse
eor sAge, tmp,  sAge_, ROR #25      SEP
bic tmp, sAgu_, sAgo_, ROR #16      SEP      bcax_m1 vAsu, vBsu, vBse, vBsa
eor sAgi, tmp,  sAgi_, ROR #58      SEP
bic tmp, sAga_, sAgu_, ROR #31      SEP
eor sAgo, tmp,  sAgo_, ROR #47      SEP
bic tmp, sAge_, sAga_, ROR #56      SEP      eor2    C2,  C2,  vAsi
eor sAgu, tmp,  sAgu_, ROR #23      SEP
bic tmp, sAki_, sAke_, ROR #19      SEP      eor2    C3,  C3,  vAso
eor sAka, tmp,  sAka_, ROR #24      SEP
bic tmp, sAko_, sAki_, ROR #47      SEP      bcax_m1 vAba, vBba, vBbi, vBbe
eor sAke, tmp,  sAke_, ROR #2       SEP
bic tmp, sAku_, sAko_, ROR #10      SEP
eor sAki, tmp,  sAki_, ROR #57      SEP
bic tmp, sAka_, sAku_, ROR #47      SEP      bcax_m1 vAbe, vBbe, vBbo, vBbi
eor sAko, tmp,  sAko_, ROR #57      SEP
bic tmp, sAke_, sAka_, ROR #5       SEP
eor sAku, tmp,  sAku_, ROR #52      SEP
bic tmp, sAmi_, sAme_, ROR #38      SEP      eor2    C1,  C1,  vAbe
eor sAma, tmp,  sAma_, ROR #47      SEP
bic tmp, sAmo_, sAmi_, ROR #5       SEP      restore x26, STACK_OFFSET_CONST
eor sAme, tmp,  sAme_, ROR #43      SEP      ldr vvtmpq, [x26], #16
bic tmp, sAmu_, sAmo_, ROR #41      SEP      save x26, STACK_OFFSET_CONST
eor sAmi, tmp,  sAmi_, ROR #46      SEP
bic tmp, sAma_, sAmu_, ROR #35      SEP      eor vAba.16b, vAba.16b, vvtmp.16b
ldr cur_const, [const_addr, count, UXTW #3]
add count, count, #1                SEP
eor sAmo, tmp,  sAmo_, ROR #12      SEP      eor2    C4,  C4,  vAsu
bic tmp, sAme_, sAma_, ROR #9       SEP
eor sAmu, tmp,  sAmu_, ROR #44      SEP      bcax_m1 vAbi, vBbi, vBbu, vBbo
bic tmp, sAsi_, sAse_, ROR #48      SEP
eor sAsa, tmp,  sAsa_, ROR #41      SEP
bic tmp, sAso_, sAsi_, ROR #2       SEP
eor sAse, tmp,  sAse_, ROR #50      SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
bic tmp, sAsu_, sAso_, ROR #25      SEP
eor sAsi, tmp,  sAsi_, ROR #27      SEP
bic tmp, sAsa_, sAsu_, ROR #60      SEP
eor sAso, tmp,  sAso_, ROR #21      SEP      eor2    C3,  C3,  vAbo
bic tmp, sAse_, sAsa_, ROR #57      SEP
eor sAsu, tmp,  sAsu_, ROR #53      SEP      eor2    C2,  C2,  vAbi
bic tmp, sAbi_, sAbe_, ROR #63      SEP
eor s_Aba, s_Aba_, tmp,  ROR #21    SEP      eor2    C0,  C0,  vAba
bic tmp, sAbo_, sAbi_, ROR #42      SEP
eor sAbe, tmp,  sAbe_, ROR #41      SEP      bcax_m1 vAbu, vBbu, vBbe, vBba
bic tmp, sAbu_, sAbo_, ROR #57      SEP
eor sAbi, tmp,  sAbi_, ROR #35      SEP
bic tmp, s_Aba_, sAbu_, ROR #50     SEP
eor sAbo, tmp,  sAbo_, ROR #43      SEP      eor2    C4,  C4,  vAbu
bic tmp, sAbe_, s_Aba_, ROR #44     SEP
eor sAbu, tmp,  sAbu_, ROR #30      SEP      restore(vAga)
eor s_Aba, s_Aba, cur_const         SEP      .unreq vvtmp
                                             .unreq vvtmpq

.endm


.macro final_rotate
ror sAga, sAga,(64-3)                           SEP
ror sAka, sAka,(64-25)                          SEP
ror sAma, sAma,(64-10)                          SEP
ror sAsa, sAsa,(64-39)                          SEP
ror sAbe, sAbe,(64-21)                          SEP
ror sAge, sAge,(64-45)                          SEP
ror sAke, sAke,(64-8)                           SEP
ror sAme, sAme,(64-15)                          SEP
ror sAse, sAse,(64-41)                          SEP
ror sAbi, sAbi,(64-14)                          SEP
ror sAgi, sAgi,(64-61)                          SEP
ror sAki, sAki,(64-18)                          SEP
ror sAmi, sAmi,(64-56)                          SEP
ror sAsi, sAsi,(64-2)                           SEP
ror sAgo, sAgo,(64-28)                          SEP
ror sAko, sAko,(64-1)                           SEP
ror sAmo, sAmo,(64-27)                          SEP
ror sAso, sAso,(64-62)                          SEP
ror sAbu, sAbu,(64-44)                          SEP
ror sAgu, sAgu,(64-20)                          SEP
ror sAku, sAku,(64-6)                           SEP
ror sAmu, sAmu,(64-36)                          SEP
ror sAsu, sAsu,(64-55)                          SEP
.endm

#define KECCAK_F1600_ROUNDS 24

.global keccak_f1600_x5_hybrid_asm_v8p
.global _keccak_f1600_x5_hybrid_asm_v8p
.text
.align 4

keccak_f1600_x5_hybrid_asm_v8p:
_keccak_f1600_x5_hybrid_asm_v8p:
    alloc_stack
    save_gprs
    save_vregs

    save input_addr, STACK_OFFSET_INPUT

    ASM_LOAD(const_addr,round_constants_vec)
    save const_addr, STACK_OFFSET_CONST

    load_input_vector

    add input_addr, input_addr, #(2*8*25)
    save input_addr, STACK_OFFSET_CUR_INPUT

    mov out_count, #0
outer_loop:
    save out_count, STACK_OFFSET_COUNT_OUT

    load_input_scalar
    save input_addr, STACK_OFFSET_CUR_INPUT

    hybrid_round_initial
inner_loop:
    hybrid_round_noninitial
    cmp count, #(KECCAK_F1600_ROUNDS-3)
    ble inner_loop
    final_rotate

    restore input_addr, STACK_OFFSET_CUR_INPUT
    store_input_scalar
    add input_addr, input_addr, #(8*25)

    restore out_count, STACK_OFFSET_COUNT_OUT
    add out_count, out_count, #1
    cmp out_count, #3
    blt outer_loop

    restore input_addr, STACK_OFFSET_INPUT
    store_input_vector

    restore_vregs
    restore_gprs
    free_stack

    ret
