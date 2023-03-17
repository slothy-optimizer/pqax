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
#if defined(__ARM_FEATURE_SHA3)

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
    const_addr     .req x26
    cur_const      .req x26
    count          .req w27

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

    /* A_[y,2*x+3*y] = rot(A[x,y]) */
    s_Aba_ .req x30
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

    /* C[x] = A[x,0] xor A[x,1] xor A[x,2] xor A[x,3] xor A[x,4],   for x in 0..4 */
    /* E[x] = C[x-1] xor rot(C[x+1],1), for x in 0..4 */
    sC0 .req x30
    sE0 .req x29
    sC1 .req x26
    sE1 .req x0
    sC2 .req x27
    sE2 .req x26
    sC3 .req x28
    sE3 .req x27
    sC4 .req x29
    sE4 .req x28

    tmp .req x0

/************************ MACROS ****************************/

/* Macros using v8.4-A SHA-3 instructions */


.macro eor2 d s0 s1
    eor \d\().16b, \s0\().16b, \s1\().16b
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

.macro rax1_m1 d s0 s1
   xar_m0 tmp, vzr, \s1, 63
   eor \d\().16b, \s0\().16b, tmp.16b
.endm

.macro bcax_m0 d s0 s1 s2
    bcax \d\().16b, \s0\().16b, \s1\().16b, \s2\().16b
.endm

.macro load_input_vector num idx
    ldr vAbaq, [input_addr, #(16*(\num*0+\idx))]
    ldr vAbeq, [input_addr, #(16*(\num*1+\idx))]
    ldr vAbiq, [input_addr, #(16*(\num*2+\idx))]
    ldr vAboq, [input_addr, #(16*(\num*3+\idx))]
    ldr vAbuq, [input_addr, #(16*(\num*4+\idx))]
    ldr vAgaq, [input_addr, #(16*(\num*5+\idx))]
    ldr vAgeq, [input_addr, #(16*(\num*6+\idx))]
    ldr vAgiq, [input_addr, #(16*(\num*7+\idx))]
    ldr vAgoq, [input_addr, #(16*(\num*8+\idx))]
    ldr vAguq, [input_addr, #(16*(\num*9+\idx))]
    ldr vAkaq, [input_addr, #(16*(\num*10+\idx))]
    ldr vAkeq, [input_addr, #(16*(\num*11+\idx))]
    ldr vAkiq, [input_addr, #(16*(\num*12+\idx))]
    ldr vAkoq, [input_addr, #(16*(\num*13+\idx))]
    ldr vAkuq, [input_addr, #(16*(\num*14+\idx))]
    ldr vAmaq, [input_addr, #(16*(\num*15+\idx))]
    ldr vAmeq, [input_addr, #(16*(\num*16+\idx))]
    ldr vAmiq, [input_addr, #(16*(\num*17+\idx))]
    ldr vAmoq, [input_addr, #(16*(\num*18+\idx))]
    ldr vAmuq, [input_addr, #(16*(\num*19+\idx))]
    ldr vAsaq, [input_addr, #(16*(\num*20+\idx))]
    ldr vAseq, [input_addr, #(16*(\num*21+\idx))]
    ldr vAsiq, [input_addr, #(16*(\num*22+\idx))]
    ldr vAsoq, [input_addr, #(16*(\num*23+\idx))]
    ldr vAsuq, [input_addr, #(16*(\num*24+\idx))]
.endm

.macro store_input_vector num idx
    str vAbaq, [input_addr, #(16*(\num*0+\idx))]
    str vAbeq, [input_addr, #(16*(\num*1+\idx))]
    str vAbiq, [input_addr, #(16*(\num*2+\idx))]
    str vAboq, [input_addr, #(16*(\num*3+\idx))]
    str vAbuq, [input_addr, #(16*(\num*4+\idx))]
    str vAgaq, [input_addr, #(16*(\num*5+\idx))]
    str vAgeq, [input_addr, #(16*(\num*6+\idx))]
    str vAgiq, [input_addr, #(16*(\num*7+\idx))]
    str vAgoq, [input_addr, #(16*(\num*8+\idx))]
    str vAguq, [input_addr, #(16*(\num*9+\idx))]
    str vAkaq, [input_addr, #(16*(\num*10+\idx))]
    str vAkeq, [input_addr, #(16*(\num*11+\idx))]
    str vAkiq, [input_addr, #(16*(\num*12+\idx))]
    str vAkoq, [input_addr, #(16*(\num*13+\idx))]
    str vAkuq, [input_addr, #(16*(\num*14+\idx))]
    str vAmaq, [input_addr, #(16*(\num*15+\idx))]
    str vAmeq, [input_addr, #(16*(\num*16+\idx))]
    str vAmiq, [input_addr, #(16*(\num*17+\idx))]
    str vAmoq, [input_addr, #(16*(\num*18+\idx))]
    str vAmuq, [input_addr, #(16*(\num*19+\idx))]
    str vAsaq, [input_addr, #(16*(\num*20+\idx))]
    str vAseq, [input_addr, #(16*(\num*21+\idx))]
    str vAsiq, [input_addr, #(16*(\num*22+\idx))]
    str vAsoq, [input_addr, #(16*(\num*23+\idx))]
    str vAsuq, [input_addr, #(16*(\num*24+\idx))]
.endm

.macro store_input_scalar num idx
    str s_Aba, [input_addr, 8*(\num*(0)  +\idx)]
    str sAbe, [input_addr, 8*(\num*(0+1) +\idx)]
    str sAbi, [input_addr, 8*(\num*(2)+   \idx)]
    str sAbo, [input_addr, 8*(\num*(2+1) +\idx)]
    str sAbu, [input_addr, 8*(\num*(4)+   \idx)]
    str sAga, [input_addr, 8*(\num*(4+1) +\idx)]
    str sAge, [input_addr, 8*(\num*(6)+   \idx)]
    str sAgi, [input_addr, 8*(\num*(6+1) +\idx)]
    str sAgo, [input_addr, 8*(\num*(8)+   \idx)]
    str sAgu, [input_addr, 8*(\num*(8+1) +\idx)]
    str sAka, [input_addr, 8*(\num*(10)  +\idx)]
    str sAke, [input_addr, 8*(\num*(10+1)+\idx)]
    str sAki, [input_addr, 8*(\num*(12)  +\idx)]
    str sAko, [input_addr, 8*(\num*(12+1)+\idx)]
    str sAku, [input_addr, 8*(\num*(14)  +\idx)]
    str sAma, [input_addr, 8*(\num*(14+1)+\idx)]
    str sAme, [input_addr, 8*(\num*(16)  +\idx)]
    str sAmi, [input_addr, 8*(\num*(16+1)+\idx)]
    str sAmo, [input_addr, 8*(\num*(18)  +\idx)]
    str sAmu, [input_addr, 8*(\num*(18+1)+\idx)]
    str sAsa, [input_addr, 8*(\num*(20)  +\idx)]
    str sAse, [input_addr, 8*(\num*(20+1)+\idx)]
    str sAsi, [input_addr, 8*(\num*(22)  +\idx)]
    str sAso, [input_addr, 8*(\num*(22+1)+\idx)]
    str sAsu, [input_addr, 8*(\num*(24)  +\idx)]
.endm

.macro load_input_scalar num idx
    ldr s_Aba, [input_addr, 8*(\num*(0)  +\idx)]
    ldr sAbe, [input_addr, 8*(\num*(0+1) +\idx)]
    ldr sAbi, [input_addr, 8*(\num*(2)+   \idx)]
    ldr sAbo, [input_addr, 8*(\num*(2+1) +\idx)]
    ldr sAbu, [input_addr, 8*(\num*(4)+   \idx)]
    ldr sAga, [input_addr, 8*(\num*(4+1) +\idx)]
    ldr sAge, [input_addr, 8*(\num*(6)+   \idx)]
    ldr sAgi, [input_addr, 8*(\num*(6+1) +\idx)]
    ldr sAgo, [input_addr, 8*(\num*(8)+   \idx)]
    ldr sAgu, [input_addr, 8*(\num*(8+1) +\idx)]
    ldr sAka, [input_addr, 8*(\num*(10)  +\idx)]
    ldr sAke, [input_addr, 8*(\num*(10+1)+\idx)]
    ldr sAki, [input_addr, 8*(\num*(12)  +\idx)]
    ldr sAko, [input_addr, 8*(\num*(12+1)+\idx)]
    ldr sAku, [input_addr, 8*(\num*(14)  +\idx)]
    ldr sAma, [input_addr, 8*(\num*(14+1)+\idx)]
    ldr sAme, [input_addr, 8*(\num*(16)  +\idx)]
    ldr sAmi, [input_addr, 8*(\num*(16+1)+\idx)]
    ldr sAmo, [input_addr, 8*(\num*(18)  +\idx)]
    ldr sAmu, [input_addr, 8*(\num*(18+1)+\idx)]
    ldr sAsa, [input_addr, 8*(\num*(20)  +\idx)]
    ldr sAse, [input_addr, 8*(\num*(20+1)+\idx)]
    ldr sAsi, [input_addr, 8*(\num*(22)  +\idx)]
    ldr sAso, [input_addr, 8*(\num*(22+1)+\idx)]
    ldr sAsu, [input_addr, 8*(\num*(24)  +\idx)]
.endm

#define STACK_SIZE (8*8 + 16*6 + 4*8  + 16*5) // VREGS (8*8), GPRs (16*6), count (8), const (8), input (8), padding (8)
#define STACK_BASE_GPRS  (4*8)
#define STACK_BASE_VREGS (4*8+16*6)
#define STACK_BASE_TMP (8*8 + 16*6 + 4*8)
#define STACK_OFFSET_INPUT (0*8)
#define STACK_OFFSET_CONST (1*8)
#define STACK_OFFSET_COUNT (2*8)
#define STACK_OFFSET_INPUT_SCALAR (3*8)

#define vAga_offset 0
#define vAge_offset 1
#define vAgi_offset 2
#define vAgo_offset 3
#define vAgu_offset 4

#define save(name) \
    str name ## q, [sp, #(STACK_BASE_TMP + 16 * name ## _offset)]
#define restore(name) \
    ldr name ## q, [sp, #(STACK_BASE_TMP + 16 * name ## _offset)]


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
    str \reg, [sp, #\offset]
.endm

.macro restore reg, offset
    ldr \reg, [sp, #\offset]
.endm

.macro hybrid_round_initial
eor sC0, sAma, sAsa                             SEP
eor sC1, sAme, sAse                             SEP      eor3_m0 C0, vAba, vAga, vAka
eor sC2, sAmi, sAsi                             SEP      eor3_m0 C1, vAbe, vAge, vAke
eor sC3, sAmo, sAso                             SEP      eor3_m0 C2, vAbi, vAgi, vAki
eor sC4, sAmu, sAsu                             SEP      eor3_m0 C3, vAbo, vAgo, vAko
eor sC0, sAka, sC0                              SEP      eor3_m0 C4, vAbu, vAgu, vAku
eor sC1, sAke, sC1                              SEP      save(vAga)
eor sC2, sAki, sC2                              SEP
eor sC3, sAko, sC3                              SEP      vzr .req vAga
eor sC4, sAku, sC4                              SEP      eor vzr.16b, vzr.16b, vzr.16b
eor sC0, sAga, sC0                              SEP      save(vAge)
eor sC1, sAge, sC1                              SEP      save(vAgi)
eor sC2, sAgi, sC2                              SEP      save(vAgo)
eor sC3, sAgo, sC3                              SEP      save(vAgu)
eor sC4, sAgu, sC4                              SEP
eor sC0, s_Aba, sC0                             SEP      C0r .req vAge
eor sC1, sAbe, sC1                              SEP      C1r .req vAgi
eor sC2, sAbi, sC2                              SEP      C2r .req vAgo
eor sC3, sAbo, sC3                              SEP      C3r .req vAgu
eor sC4, sAbu, sC4                              SEP      C4r .req v31
eor sE1, sC0, sC2, ROR #63                      SEP      eor3_m0 C0, C0, vAma,  vAsa
eor sE3, sC2, sC4, ROR #63                      SEP
eor sE0, sC4, sC1, ROR #63                      SEP      eor3_m0 C1, C1, vAme,  vAse
eor sE2, sC1, sC3, ROR #63                      SEP      eor3_m0 C2, C2, vAmi,  vAsi
eor sE4, sC3, sC0, ROR #63                      SEP      eor3_m0 C3, C3, vAmo,  vAso
eor s_Aba_, s_Aba, sE0                          SEP      eor3_m0 C4, C4, vAmu,  vAsu
eor sAsa_, sAbi, sE2                            SEP      xar_m0 C2r, vzr, C2, 63
eor sAbi_, sAki, sE2                            SEP
eor sAki_, sAko, sE3                            SEP      xar_m0 C4r, vzr, C4, 63
eor sAko_, sAmu, sE4                            SEP      xar_m0 C1r, vzr, C1, 63
eor sAmu_, sAso, sE3                            SEP      xar_m0 C3r, vzr, C3, 63
eor sAso_, sAma, sE0                            SEP      xar_m0 C0r, vzr, C0, 63
eor sAka_, sAbe, sE1                            SEP      eor2   E1, C0, C2r
eor sAse_, sAgo, sE3                            SEP      restore(vAgo)
eor sAgo_, sAme, sE1                            SEP
eor sAke_, sAgi, sE2                            SEP      eor2   E3, C2, C4r
eor sAgi_, sAka, sE0                            SEP      restore(vAga)
eor sAga_, sAbo, sE3                            SEP      eor2   E0, C4, C1r
eor sAbo_, sAmo, sE3                            SEP      restore(vAgi)
eor sAmo_, sAmi, sE2                            SEP      eor2   E2, C1, C3r
eor sAmi_, sAke, sE1                            SEP      restore(vAgu)
eor sAge_, sAgu, sE4                            SEP
eor sAgu_, sAsi, sE2                            SEP      eor2   E4, C3, C0r
eor sAsi_, sAku, sE4                            SEP      restore(vAge)
eor sAku_, sAsa, sE0                            SEP      eor vAba_.16b, vAba.16b, E0.16b
eor sAma_, sAbu, sE4                            SEP      xar_m0 vAsa_, vAbi, E2, 2
eor sAbu_, sAsu, sE4                            SEP      xar_m0 vAbi_, vAki, E2, 21
eor sAsu_, sAse, sE1                            SEP
eor sAme_, sAga, sE0                            SEP      xar_m0 vAki_, vAko, E3, 39
eor sAbe_, sAge, sE1                            SEP      xar_m0 vAko_, vAmu, E4, 56
load_constant_ptr                               SEP      xar_m0 vAmu_, vAso, E3, 8
tmp0 .req x0                                    SEP      xar_m0 vAso_, vAma, E0, 23
tmp1 .req x29                                   SEP      xar_m0 vAka_, vAbe, E1, 63
bic tmp0, sAgi_, sAge_, ROR #47                 SEP      xar_m0 vAse_, vAgo, E3, 9
bic tmp1, sAgo_, sAgi_, ROR #42                 SEP
eor sAga, tmp0,  sAga_, ROR #39                 SEP      xar_m0 vAgo_, vAme, E1, 19
bic tmp0, sAgu_, sAgo_, ROR #16                 SEP      xar_m0 vAke_, vAgi, E2, 58
eor sAge, tmp1,  sAge_, ROR #25                 SEP      xar_m0 vAgi_, vAka, E0, 61
bic tmp1, sAga_, sAgu_, ROR #31                 SEP      xar_m0 vAga_, vAbo, E3, 36
eor sAgi, tmp0,  sAgi_, ROR #58                 SEP      xar_m0 vAbo_, vAmo, E3, 43
bic tmp0, sAge_, sAga_, ROR #56                 SEP      xar_m0 vAmo_, vAmi, E2, 49
eor sAgo, tmp1,  sAgo_, ROR #47                 SEP
bic tmp1, sAki_, sAke_, ROR #19                 SEP      xar_m0 vAmi_, vAke, E1, 54
eor sAgu, tmp0,  sAgu_, ROR #23                 SEP      xar_m0 vAge_, vAgu, E4, 44
bic tmp0, sAko_, sAki_, ROR #47                 SEP      xar_m0 vAgu_, vAsi, E2, 3
eor sAka, tmp1,  sAka_, ROR #24                 SEP      xar_m0 vAsi_, vAku, E4, 25
bic tmp1, sAku_, sAko_, ROR #10                 SEP      xar_m0 vAku_, vAsa, E0, 46
eor sAke, tmp0,  sAke_, ROR #2                  SEP
bic tmp0, sAka_, sAku_, ROR #47                 SEP      xar_m0 vAma_, vAbu, E4, 37
eor sAki, tmp1,  sAki_, ROR #57                 SEP      xar_m0 vAbu_, vAsu, E4, 50
bic tmp1, sAke_, sAka_, ROR #5                  SEP      xar_m0 vAsu_, vAse, E1, 62
eor sAko, tmp0,  sAko_, ROR #57                 SEP      xar_m0 vAme_, vAga, E0, 28
bic tmp0, sAmi_, sAme_, ROR #38                 SEP      xar_m0 vAbe_, vAge, E1, 20
eor sAku, tmp1,  sAku_, ROR #52                 SEP      restore x27, STACK_OFFSET_CONST
bic tmp1, sAmo_, sAmi_, ROR #5                  SEP
eor sAma, tmp0,  sAma_, ROR #47                 SEP      ldr q31, [x27], #16
bic tmp0, sAmu_, sAmo_, ROR #41                 SEP      save x27, STACK_OFFSET_CONST
eor sAme, tmp1,  sAme_, ROR #43                 SEP      bcax_m0 vAga, vAga_, vAgi_, vAge_
bic tmp1, sAma_, sAmu_, ROR #35                 SEP      bcax_m0 vAge, vAge_, vAgo_, vAgi_
eor sAmi, tmp0,  sAmi_, ROR #46                 SEP      bcax_m0 vAgi, vAgi_, vAgu_, vAgo_
bic tmp0, sAme_, sAma_, ROR #9                  SEP      bcax_m0 vAgo, vAgo_, vAga_, vAgu_
ldr cur_const, [const_addr]                     SEP
eor sAmo, tmp1,  sAmo_, ROR #12                 SEP      bcax_m0 vAgu, vAgu_, vAge_, vAga_
bic tmp1, sAsi_, sAse_, ROR #48                 SEP      bcax_m0 vAka, vAka_, vAki_, vAke_
eor sAmu, tmp0,  sAmu_, ROR #44                 SEP      bcax_m0 vAke, vAke_, vAko_, vAki_
bic tmp0, sAso_, sAsi_, ROR #2                  SEP      bcax_m0 vAki, vAki_, vAku_, vAko_
eor sAsa, tmp1,  sAsa_, ROR #41                 SEP      bcax_m0 vAko, vAko_, vAka_, vAku_
bic tmp1, sAsu_, sAso_, ROR #25                 SEP
eor sAse, tmp0,  sAse_, ROR #50                 SEP      bcax_m0 vAku, vAku_, vAke_, vAka_
bic tmp0, sAsa_, sAsu_, ROR #60                 SEP      bcax_m0 vAma, vAma_, vAmi_, vAme_
eor sAsi, tmp1,  sAsi_, ROR #27                 SEP      bcax_m0 vAme, vAme_, vAmo_, vAmi_
bic tmp1, sAse_, sAsa_, ROR #57                 SEP      bcax_m0 vAmi, vAmi_, vAmu_, vAmo_
eor sAso, tmp0,  sAso_, ROR #21                 SEP      bcax_m0 vAmo, vAmo_, vAma_, vAmu_
mov count, #1                                   SEP      bcax_m0 vAmu, vAmu_, vAme_, vAma_
bic tmp0, sAbi_, sAbe_, ROR #63                 SEP
eor sAsu, tmp1,  sAsu_, ROR #53                 SEP      bcax_m0 vAsa, vAsa_, vAsi_, vAse_
bic tmp1, sAbo_, sAbi_, ROR #42                 SEP      bcax_m0 vAse, vAse_, vAso_, vAsi_
eor s_Aba, s_Aba_, tmp0,  ROR #21               SEP      bcax_m0 vAsi, vAsi_, vAsu_, vAso_
bic tmp0, sAbu_, sAbo_, ROR #57                 SEP      bcax_m0 vAso, vAso_, vAsa_, vAsu_
eor sAbe, tmp1,  sAbe_, ROR #41                 SEP      bcax_m0 vAsu, vAsu_, vAse_, vAsa_
bic tmp1, s_Aba_, sAbu_, ROR #50                SEP      bcax_m0 vAba, vAba_, vAbi_, vAbe_
eor sAbi, tmp0,  sAbi_, ROR #35                 SEP
bic tmp0, sAbe_, s_Aba_, ROR #44                SEP      bcax_m0 vAbe, vAbe_, vAbo_, vAbi_
eor sAbo, tmp1,  sAbo_, ROR #43                 SEP      bcax_m0 vAbi, vAbi_, vAbu_, vAbo_
eor sAbu, tmp0,  sAbu_, ROR #30                 SEP      bcax_m0 vAbo, vAbo_, vAba_, vAbu_
eor s_Aba, s_Aba, cur_const                     SEP      bcax_m0 vAbu, vAbu_, vAbe_, vAba_
save count, STACK_OFFSET_COUNT                  SEP      eor vAba.16b, vAba.16b, v31.16b
.endm

.macro  hybrid_round_noninitial
eor sC2, sAsi, sAbi, ROR #52                    SEP
eor sC0, s_Aba, sAga, ROR #61                   SEP      eor3_m0 C0, vAba, vAga, vAka
eor sC4, sAku, sAgu, ROR #50                    SEP      eor3_m0 C1, vAbe, vAge, vAke
eor sC1, sAke, sAme, ROR #57                    SEP      eor3_m0 C2, vAbi, vAgi, vAki
eor sC3, sAbo, sAko, ROR #63                    SEP      eor3_m0 C3, vAbo, vAgo, vAko
eor sC2, sC2, sAki, ROR #48                     SEP      eor3_m0 C4, vAbu, vAgu, vAku
eor sC0, sC0, sAma, ROR #54                     SEP
eor sC4, sC4, sAmu, ROR #34                     SEP      save(vAga)
eor sC1, sC1, sAbe, ROR #51                     SEP      vzr .req vAga
eor sC3, sC3, sAmo, ROR #37                     SEP      eor vzr.16b, vzr.16b, vzr.16b
eor sC2, sC2, sAmi, ROR #10                     SEP      save(vAge)
eor sC0, sC0, sAka, ROR #39                     SEP      save(vAgi)
eor sC4, sC4, sAbu, ROR #26                     SEP
eor sC1, sC1, sAse, ROR #31                     SEP      save(vAgo)
eor sC3, sC3, sAgo, ROR #36                     SEP      save(vAgu)
eor sC2, sC2, sAgi, ROR #5                      SEP      C0r .req vAge
eor sC0, sC0, sAsa, ROR #25                     SEP      C1r .req vAgi
eor sC4, sC4, sAsu, ROR #15                     SEP
eor sC1, sC1, sAge, ROR #27                     SEP      C2r .req vAgo
eor sC3, sC3, sAso, ROR #2                      SEP      C3r .req vAgu
eor sE1, sC0, sC2, ROR #61                      SEP      C4r .req v31
ror sC2, sC2, 62                                SEP      eor3_m0 C0, C0, vAma,  vAsa
eor sE3, sC2, sC4, ROR #57                      SEP      eor3_m0 C1, C1, vAme,  vAse
ror sC4, sC4, 58                                SEP
eor sE0, sC4, sC1, ROR #55                      SEP      eor3_m0 C2, C2, vAmi,  vAsi
ror sC1, sC1, 56                                SEP      eor3_m0 C3, C3, vAmo,  vAso
eor sE2, sC1, sC3, ROR #63                      SEP      eor3_m0 C4, C4, vAmu,  vAsu
eor sE4, sC3, sC0, ROR #63                      SEP      xar_m0 C2r, vzr, C2, 63
eor s_Aba_, sE0, s_Aba                          SEP
eor sAsa_, sE2, sAbi, ROR #50                   SEP      xar_m0 C4r, vzr, C4, 63
eor sAbi_, sE2, sAki, ROR #46                   SEP      xar_m0 C1r, vzr, C1, 63
eor sAki_, sE3, sAko, ROR #63                   SEP      xar_m0 C3r, vzr, C3, 63
eor sAko_, sE4, sAmu, ROR #28                   SEP      xar_m0 C0r, vzr, C0, 63
eor sAmu_, sE3, sAso, ROR #2                    SEP      eor2   E1, C0, C2r
eor sAso_, sE0, sAma, ROR #54                   SEP
eor sAka_, sE1, sAbe, ROR #43                   SEP      restore(vAgo)
eor sAse_, sE3, sAgo, ROR #36                   SEP      eor2   E3, C2, C4r
eor sAgo_, sE1, sAme, ROR #49                   SEP      restore(vAga)
eor sAke_, sE2, sAgi, ROR #3                    SEP      eor2   E0, C4, C1r
eor sAgi_, sE0, sAka, ROR #39                   SEP
eor sAga_, sE3, sAbo                            SEP      restore(vAgi)
eor sAbo_, sE3, sAmo, ROR #37                   SEP      eor2   E2, C1, C3r
eor sAmo_, sE2, sAmi, ROR #8                    SEP      restore(vAgu)
eor sAmi_, sE1, sAke, ROR #56                   SEP      eor2   E4, C3, C0r
eor sAge_, sE4, sAgu, ROR #44                   SEP      restore(vAge)
eor sAgu_, sE2, sAsi, ROR #62                   SEP
eor sAsi_, sE4, sAku, ROR #58                   SEP      eor vAba_.16b, vAba.16b, E0.16b
eor sAku_, sE0, sAsa, ROR #25                   SEP      xar_m0 vAsa_, vAbi, E2, 2
eor sAma_, sE4, sAbu, ROR #20                   SEP      xar_m0 vAbi_, vAki, E2, 21
eor sAbu_, sE4, sAsu, ROR #9                    SEP      xar_m0 vAki_, vAko, E3, 39
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP      xar_m0 vAko_, vAmu, E4, 56
eor sAbe_, sE1, sAge, ROR #19                   SEP      xar_m0 vAmu_, vAso, E3, 8
load_constant_ptr                               SEP      xar_m0 vAso_, vAma, E0, 23
restore count, STACK_OFFSET_COUNT               SEP      xar_m0 vAka_, vAbe, E1, 63
tmp0 .req x0                                    SEP      xar_m0 vAse_, vAgo, E3, 9
tmp1 .req x29                                   SEP
bic tmp0, sAgi_, sAge_, ROR #47                 SEP      xar_m0 vAgo_, vAme, E1, 19
bic tmp1, sAgo_, sAgi_, ROR #42                 SEP      xar_m0 vAke_, vAgi, E2, 58
eor sAga, tmp0,  sAga_, ROR #39                 SEP      xar_m0 vAgi_, vAka, E0, 61
bic tmp0, sAgu_, sAgo_, ROR #16                 SEP      xar_m0 vAga_, vAbo, E3, 36
eor sAge, tmp1,  sAge_, ROR #25                 SEP      xar_m0 vAbo_, vAmo, E3, 43
bic tmp1, sAga_, sAgu_, ROR #31                 SEP
eor sAgi, tmp0,  sAgi_, ROR #58                 SEP      xar_m0 vAmo_, vAmi, E2, 49
bic tmp0, sAge_, sAga_, ROR #56                 SEP      xar_m0 vAmi_, vAke, E1, 54
eor sAgo, tmp1,  sAgo_, ROR #47                 SEP      xar_m0 vAge_, vAgu, E4, 44
bic tmp1, sAki_, sAke_, ROR #19                 SEP      xar_m0 vAgu_, vAsi, E2, 3
eor sAgu, tmp0,  sAgu_, ROR #23                 SEP
bic tmp0, sAko_, sAki_, ROR #47                 SEP      xar_m0 vAsi_, vAku, E4, 25
eor sAka, tmp1,  sAka_, ROR #24                 SEP      xar_m0 vAku_, vAsa, E0, 46
bic tmp1, sAku_, sAko_, ROR #10                 SEP      xar_m0 vAma_, vAbu, E4, 37
eor sAke, tmp0,  sAke_, ROR #2                  SEP      xar_m0 vAbu_, vAsu, E4, 50
bic tmp0, sAka_, sAku_, ROR #47                 SEP      xar_m0 vAsu_, vAse, E1, 62
eor sAki, tmp1,  sAki_, ROR #57                 SEP
bic tmp1, sAke_, sAka_, ROR #5                  SEP      xar_m0 vAme_, vAga, E0, 28
eor sAko, tmp0,  sAko_, ROR #57                 SEP      xar_m0 vAbe_, vAge, E1, 20
bic tmp0, sAmi_, sAme_, ROR #38                 SEP      
eor sAku, tmp1,  sAku_, ROR #52                 SEP      
bic tmp1, sAmo_, sAmi_, ROR #5                  SEP
eor sAma, tmp0,  sAma_, ROR #47                 SEP      
bic tmp0, sAmu_, sAmo_, ROR #41                 SEP      bcax_m0 vAga, vAga_, vAgi_, vAge_
eor sAme, tmp1,  sAme_, ROR #43                 SEP      bcax_m0 vAge, vAge_, vAgo_, vAgi_
bic tmp1, sAma_, sAmu_, ROR #35                 SEP      bcax_m0 vAgi, vAgi_, vAgu_, vAgo_
eor sAmi, tmp0,  sAmi_, ROR #46                 SEP      bcax_m0 vAgo, vAgo_, vAga_, vAgu_
bic tmp0, sAme_, sAma_, ROR #9                  SEP
ldr cur_const, [const_addr, count, UXTW #3]     SEP      bcax_m0 vAgu, vAgu_, vAge_, vAga_
eor sAmo, tmp1,  sAmo_, ROR #12                 SEP      bcax_m0 vAka, vAka_, vAki_, vAke_
bic tmp1, sAsi_, sAse_, ROR #48                 SEP      bcax_m0 vAke, vAke_, vAko_, vAki_
eor sAmu, tmp0,  sAmu_, ROR #44                 SEP      bcax_m0 vAki, vAki_, vAku_, vAko_
bic tmp0, sAso_, sAsi_, ROR #2                  SEP
eor sAsa, tmp1,  sAsa_, ROR #41                 SEP      bcax_m0 vAko, vAko_, vAka_, vAku_
bic tmp1, sAsu_, sAso_, ROR #25                 SEP      bcax_m0 vAku, vAku_, vAke_, vAka_
eor sAse, tmp0,  sAse_, ROR #50                 SEP      bcax_m0 vAma, vAma_, vAmi_, vAme_
bic tmp0, sAsa_, sAsu_, ROR #60                 SEP      bcax_m0 vAme, vAme_, vAmo_, vAmi_
eor sAsi, tmp1,  sAsi_, ROR #27                 SEP      bcax_m0 vAmi, vAmi_, vAmu_, vAmo_
bic tmp1, sAse_, sAsa_, ROR #57                 SEP
eor sAso, tmp0,  sAso_, ROR #21                 SEP      bcax_m0 vAmo, vAmo_, vAma_, vAmu_
bic tmp0, sAbi_, sAbe_, ROR #63                 SEP      bcax_m0 vAmu, vAmu_, vAme_, vAma_
add count, count, #1                            SEP      bcax_m0 vAsa, vAsa_, vAsi_, vAse_
save count, STACK_OFFSET_COUNT                  SEP      bcax_m0 vAse, vAse_, vAso_, vAsi_
//TODO: schedule this better                    SEP
restore x27, STACK_OFFSET_CONST                 SEP
ldr q31, [x27], #16                             SEP
save x27, STACK_OFFSET_CONST                    SEP
eor sAsu, tmp1,  sAsu_, ROR #53                 SEP
bic tmp1, sAbo_, sAbi_, ROR #42                 SEP      bcax_m0 vAsi, vAsi_, vAsu_, vAso_
eor s_Aba, s_Aba_, tmp0,  ROR #21               SEP      bcax_m0 vAso, vAso_, vAsa_, vAsu_
bic tmp0, sAbu_, sAbo_, ROR #57                 SEP      bcax_m0 vAsu, vAsu_, vAse_, vAsa_
eor sAbe, tmp1,  sAbe_, ROR #41                 SEP      bcax_m0 vAba, vAba_, vAbi_, vAbe_
bic tmp1, s_Aba_, sAbu_, ROR #50                SEP      bcax_m0 vAbe, vAbe_, vAbo_, vAbi_
eor sAbi, tmp0,  sAbi_, ROR #35                 SEP
bic tmp0, sAbe_, s_Aba_, ROR #44                SEP      bcax_m0 vAbi, vAbi_, vAbu_, vAbo_
eor sAbo, tmp1,  sAbo_, ROR #43                 SEP      bcax_m0 vAbo, vAbo_, vAba_, vAbu_
eor sAbu, tmp0,  sAbu_, ROR #30                 SEP      bcax_m0 vAbu, vAbu_, vAbe_, vAba_
eor s_Aba, s_Aba, cur_const                     SEP      eor vAba.16b, vAba.16b, v31.16b
.endm


.macro  hybrid_round_final
eor sC2, sAsi, sAbi, ROR #52                    SEP
eor sC0, s_Aba, sAga, ROR #61                   SEP      eor3_m0 C0, vAba, vAga, vAka
eor sC4, sAku, sAgu, ROR #50                    SEP      eor3_m0 C1, vAbe, vAge, vAke
eor sC1, sAke, sAme, ROR #57                    SEP      eor3_m0 C2, vAbi, vAgi, vAki
eor sC3, sAbo, sAko, ROR #63                    SEP
eor sC2, sC2, sAki, ROR #48                     SEP      eor3_m0 C3, vAbo, vAgo, vAko
eor sC0, sC0, sAma, ROR #54                     SEP      eor3_m0 C4, vAbu, vAgu, vAku
eor sC4, sC4, sAmu, ROR #34                     SEP
eor sC1, sC1, sAbe, ROR #51                     SEP      save(vAga)
eor sC3, sC3, sAmo, ROR #37                     SEP      vzr .req vAga
eor sC2, sC2, sAmi, ROR #10                     SEP
eor sC0, sC0, sAka, ROR #39                     SEP      eor vzr.16b, vzr.16b, vzr.16b
eor sC4, sC4, sAbu, ROR #26                     SEP      save(vAge)
eor sC1, sC1, sAse, ROR #31                     SEP
eor sC3, sC3, sAgo, ROR #36                     SEP      save(vAgi)
eor sC2, sC2, sAgi, ROR #5                      SEP      save(vAgo)
eor sC0, sC0, sAsa, ROR #25                     SEP
eor sC4, sC4, sAsu, ROR #15                     SEP      save(vAgu)
eor sC1, sC1, sAge, ROR #27                     SEP      C0r .req vAge
eor sC3, sC3, sAso, ROR #2                      SEP
eor sE1, sC0, sC2, ROR #61                      SEP      C1r .req vAgi
ror sC2, sC2, 62                                SEP      C2r .req vAgo
eor sE3, sC2, sC4, ROR #57                      SEP
ror sC4, sC4, 58                                SEP      C3r .req vAgu
eor sE0, sC4, sC1, ROR #55                      SEP      C4r .req v31
ror sC1, sC1, 56                                SEP
eor sE2, sC1, sC3, ROR #63                      SEP      eor3_m0 C0, C0, vAma,  vAsa
eor sE4, sC3, sC0, ROR #63                      SEP      eor3_m0 C1, C1, vAme,  vAse
eor s_Aba_, sE0, s_Aba                          SEP      eor3_m0 C2, C2, vAmi,  vAsi
eor sAsa_, sE2, sAbi, ROR #50                   SEP
eor sAbi_, sE2, sAki, ROR #46                   SEP      eor3_m0 C3, C3, vAmo,  vAso
eor sAki_, sE3, sAko, ROR #63                   SEP      eor3_m0 C4, C4, vAmu,  vAsu
eor sAko_, sE4, sAmu, ROR #28                   SEP
eor sAmu_, sE3, sAso, ROR #2                    SEP      xar_m0 C2r, vzr, C2, 63
eor sAso_, sE0, sAma, ROR #54                   SEP      xar_m0 C4r, vzr, C4, 63
eor sAka_, sE1, sAbe, ROR #43                   SEP
eor sAse_, sE3, sAgo, ROR #36                   SEP      xar_m0 C1r, vzr, C1, 63
eor sAgo_, sE1, sAme, ROR #49                   SEP      xar_m0 C3r, vzr, C3, 63
eor sAke_, sE2, sAgi, ROR #3                    SEP
eor sAgi_, sE0, sAka, ROR #39                   SEP      xar_m0 C0r, vzr, C0, 63
eor sAga_, sE3, sAbo                            SEP      eor2   E1, C0, C2r
eor sAbo_, sE3, sAmo, ROR #37                   SEP
eor sAmo_, sE2, sAmi, ROR #8                    SEP      restore(vAgo)
eor sAmi_, sE1, sAke, ROR #56                   SEP      eor2   E3, C2, C4r
eor sAge_, sE4, sAgu, ROR #44                   SEP
eor sAgu_, sE2, sAsi, ROR #62                   SEP      restore(vAga)
eor sAsi_, sE4, sAku, ROR #58                   SEP      eor2   E0, C4, C1r
eor sAku_, sE0, sAsa, ROR #25                   SEP
eor sAma_, sE4, sAbu, ROR #20                   SEP      restore(vAgi)
eor sAbu_, sE4, sAsu, ROR #9                    SEP      eor2   E2, C1, C3r
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP      restore(vAgu)
eor sAbe_, sE1, sAge, ROR #19                   SEP      eor2   E4, C3, C0r
load_constant_ptr                               SEP
tmp0 .req x0                                    SEP      restore(vAge)
tmp1 .req x29                                   SEP      eor vAba_.16b, vAba.16b, E0.16b
bic tmp0, sAgi_, sAge_, ROR #47                 SEP      xar_m0 vAsa_, vAbi, E2, 2
bic tmp1, sAgo_, sAgi_, ROR #42                 SEP
eor sAga, tmp0,  sAga_, ROR #39                 SEP      xar_m0 vAbi_, vAki, E2, 21
bic tmp0, sAgu_, sAgo_, ROR #16                 SEP      xar_m0 vAki_, vAko, E3, 39
eor sAge, tmp1,  sAge_, ROR #25                 SEP
bic tmp1, sAga_, sAgu_, ROR #31                 SEP      xar_m0 vAko_, vAmu, E4, 56
restore count, STACK_OFFSET_COUNT               SEP      xar_m0 vAmu_, vAso, E3, 8
eor sAgi, tmp0,  sAgi_, ROR #58                 SEP
bic tmp0, sAge_, sAga_, ROR #56                 SEP      xar_m0 vAso_, vAma, E0, 23
eor sAgo, tmp1,  sAgo_, ROR #47                 SEP      xar_m0 vAka_, vAbe, E1, 63
bic tmp1, sAki_, sAke_, ROR #19                 SEP
eor sAgu, tmp0,  sAgu_, ROR #23                 SEP      xar_m0 vAse_, vAgo, E3, 9
bic tmp0, sAko_, sAki_, ROR #47                 SEP      xar_m0 vAgo_, vAme, E1, 19
eor sAka, tmp1,  sAka_, ROR #24                 SEP
bic tmp1, sAku_, sAko_, ROR #10                 SEP      xar_m0 vAke_, vAgi, E2, 58
eor sAke, tmp0,  sAke_, ROR #2                  SEP      xar_m0 vAgi_, vAka, E0, 61
bic tmp0, sAka_, sAku_, ROR #47                 SEP
eor sAki, tmp1,  sAki_, ROR #57                 SEP      xar_m0 vAga_, vAbo, E3, 36
bic tmp1, sAke_, sAka_, ROR #5                  SEP      xar_m0 vAbo_, vAmo, E3, 43
eor sAko, tmp0,  sAko_, ROR #57                 SEP
bic tmp0, sAmi_, sAme_, ROR #38                 SEP      xar_m0 vAmo_, vAmi, E2, 49
eor sAku, tmp1,  sAku_, ROR #52                 SEP      xar_m0 vAmi_, vAke, E1, 54
bic tmp1, sAmo_, sAmi_, ROR #5                  SEP
eor sAma, tmp0,  sAma_, ROR #47                 SEP      xar_m0 vAge_, vAgu, E4, 44
bic tmp0, sAmu_, sAmo_, ROR #41                 SEP      xar_m0 vAgu_, vAsi, E2, 3
eor sAme, tmp1,  sAme_, ROR #43                 SEP      xar_m0 vAsi_, vAku, E4, 25
bic tmp1, sAma_, sAmu_, ROR #35                 SEP
eor sAmi, tmp0,  sAmi_, ROR #46                 SEP      xar_m0 vAku_, vAsa, E0, 46
bic tmp0, sAme_, sAma_, ROR #9                  SEP      xar_m0 vAma_, vAbu, E4, 37
ldr cur_const, [const_addr, count, UXTW #3]     SEP
eor sAmo, tmp1,  sAmo_, ROR #12                 SEP      xar_m0 vAbu_, vAsu, E4, 50
bic tmp1, sAsi_, sAse_, ROR #48                 SEP      xar_m0 vAsu_, vAse, E1, 62
eor sAmu, tmp0,  sAmu_, ROR #44                 SEP
bic tmp0, sAso_, sAsi_, ROR #2                  SEP      xar_m0 vAme_, vAga, E0, 28
eor sAsa, tmp1,  sAsa_, ROR #41                 SEP      xar_m0 vAbe_, vAge, E1, 20
bic tmp1, sAsu_, sAso_, ROR #25                 SEP
eor sAse, tmp0,  sAse_, ROR #50                 SEP      restore x27, STACK_OFFSET_CONST
bic tmp0, sAsa_, sAsu_, ROR #60                 SEP      ldr q31, [x27], #16
eor sAsi, tmp1,  sAsi_, ROR #27                 SEP
bic tmp1, sAse_, sAsa_, ROR #57                 SEP      save x27, STACK_OFFSET_CONST
eor sAso, tmp0,  sAso_, ROR #21                 SEP      bcax_m0 vAga, vAga_, vAgi_, vAge_
bic tmp0, sAbi_, sAbe_, ROR #63                 SEP
add count, count, #1                            SEP      bcax_m0 vAge, vAge_, vAgo_, vAgi_
save count, STACK_OFFSET_COUNT                  SEP      bcax_m0 vAgi, vAgi_, vAgu_, vAgo_
eor sAsu, tmp1,  sAsu_, ROR #53                 SEP
bic tmp1, sAbo_, sAbi_, ROR #42                 SEP      bcax_m0 vAgo, vAgo_, vAga_, vAgu_
eor s_Aba, s_Aba_, tmp0,  ROR #21               SEP      bcax_m0 vAgu, vAgu_, vAge_, vAga_
bic tmp0, sAbu_, sAbo_, ROR #57                 SEP
eor sAbe, tmp1,  sAbe_, ROR #41                 SEP      bcax_m0 vAka, vAka_, vAki_, vAke_
bic tmp1, s_Aba_, sAbu_, ROR #50                SEP      bcax_m0 vAke, vAke_, vAko_, vAki_
eor sAbi, tmp0,  sAbi_, ROR #35                 SEP
bic tmp0, sAbe_, s_Aba_, ROR #44                SEP      bcax_m0 vAki, vAki_, vAku_, vAko_
eor sAbo, tmp1,  sAbo_, ROR #43                 SEP      bcax_m0 vAko, vAko_, vAka_, vAku_
eor sAbu, tmp0,  sAbu_, ROR #30                 SEP      bcax_m0 vAku, vAku_, vAke_, vAka_
eor s_Aba, s_Aba, cur_const                     SEP
ror sAga, sAga,(64-3)                           SEP      bcax_m0 vAma, vAma_, vAmi_, vAme_
ror sAbu, sAbu,(64-44)                          SEP      bcax_m0 vAme, vAme_, vAmo_, vAmi_
ror sAka, sAka,(64-25)                          SEP
ror sAke, sAke,(64-8)                           SEP      bcax_m0 vAmi, vAmi_, vAmu_, vAmo_
ror sAma, sAma,(64-10)                          SEP      bcax_m0 vAmo, vAmo_, vAma_, vAmu_
ror sAku, sAku,(64-6)                           SEP
ror sAsa, sAsa,(64-39)                          SEP      bcax_m0 vAmu, vAmu_, vAme_, vAma_
ror sAse, sAse,(64-41)                          SEP      bcax_m0 vAsa, vAsa_, vAsi_, vAse_
ror sAbe, sAbe,(64-21)                          SEP
ror sAge, sAge,(64-45)                          SEP      bcax_m0 vAse, vAse_, vAso_, vAsi_
ror sAgi, sAgi,(64-61)                          SEP      bcax_m0 vAsi, vAsi_, vAsu_, vAso_
ror sAme, sAme,(64-15)                          SEP
ror sAmi, sAmi,(64-56)                          SEP      bcax_m0 vAso, vAso_, vAsa_, vAsu_
ror sAbi, sAbi,(64-14)                          SEP      bcax_m0 vAsu, vAsu_, vAse_, vAsa_
ror sAki, sAki,(64-18)                          SEP
ror sAko, sAko,(64-1)                           SEP      bcax_m0 vAba, vAba_, vAbi_, vAbe_
ror sAsi, sAsi,(64-2)                           SEP      bcax_m0 vAbe, vAbe_, vAbo_, vAbi_
ror sAso, sAso,(64-62)                          SEP
ror sAgo, sAgo,(64-28)                          SEP      bcax_m0 vAbi, vAbi_, vAbu_, vAbo_
ror sAgu, sAgu,(64-20)                          SEP      bcax_m0 vAbo, vAbo_, vAba_, vAbu_
ror sAmo, sAmo,(64-27)                          SEP
ror sAmu, sAmu,(64-36)                          SEP      bcax_m0 vAbu, vAbu_, vAbe_, vAba_
ror sAsu, sAsu,(64-55)                          SEP      eor vAba.16b, vAba.16b, v31.16b
.endm



#define KECCAK_F1600_ROUNDS 24

.global keccak_f1600_x3_hybrid_asm_v7
.global _keccak_f1600_x3_hybrid_asm_v7
.text
.align 4

keccak_f1600_x3_hybrid_asm_v7:
_keccak_f1600_x3_hybrid_asm_v7:
    alloc_stack
    save_gprs
    save_vregs
    save input_addr, STACK_OFFSET_INPUT


     ASM_LOAD(const_addr,round_constants_vec)

     save const_addr, STACK_OFFSET_CONST
     load_input_vector 1,0

     add input_addr, input_addr, #400
     load_input_scalar 1,0
     hybrid_round_initial
 loop_0:
     hybrid_round_noninitial
     restore count, STACK_OFFSET_COUNT
     cmp count, #(KECCAK_F1600_ROUNDS-2)
     ble loop_0

     hybrid_round_final

     restore input_addr, STACK_OFFSET_INPUT
     store_input_vector 1,0
     add input_addr, input_addr, #400
     store_input_scalar 1,0

    restore_vregs
    restore_gprs
    free_stack


    ret
#endif