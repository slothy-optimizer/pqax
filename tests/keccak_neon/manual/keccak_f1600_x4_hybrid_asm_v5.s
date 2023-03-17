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

/* Macros using v8.4-A SHA-3 instructions */

.macro eor3_m1_0 d s0 s1 s2
    eor \d\().16b, \s0\().16b, \s1\().16b
.endm

.macro eor2 d s0 s1
    eor \d\().16b, \s0\().16b, \s1\().16b
.endm

.macro eor3_m1_1 d s0 s1 s2
    eor \d\().16b, \d\().16b,  \s2\().16b
.endm


.macro eor3_m1 d s0 s1 s2
    eor3_m1_0 \d, \s0, \s1, \s2
    eor3_m1_1 \d, \s0, \s1, \s2
.endm

.macro rax1_m1 d s0 s1
   // Use add instead of SHL #1
   add vvtmp.2d, \s1\().2d, \s1\().2d
   sri vvtmp.2d, \s1\().2d, #63
   eor \d\().16b, vvtmp.16b, \s0\().16b
.endm

 .macro xar_m1 d s0 s1 imm
   // Special cases where we can replace SHLs by ADDs
   .if \imm == 63
     eor \s0\().16b, \s0\().16b, \s1\().16b
     add \d\().2d, \s0\().2d, \s0\().2d
     sri \d\().2d, \s0\().2d, #(63)
   .elseif \imm == 62
     eor \s0\().16b, \s0\().16b, \s1\().16b
     add \d\().2d, \s0\().2d, \s0\().2d
     add \d\().2d, \d\().2d,  \d\().2d
     sri \d\().2d, \s0\().2d, #(62)
   .else
     eor \s0\().16b, \s0\().16b, \s1\().16b
     shl \d\().2d, \s0\().2d, #(64-\imm)
     sri \d\().2d, \s0\().2d, #(\imm)
   .endif
.endm

 .macro xar_m1_0 d s0 s1 imm
   // Special cases where we can replace SHLs by ADDs
   .if \imm == 63
     eor \s0\().16b, \s0\().16b, \s1\().16b
   .elseif \imm == 62
     eor \s0\().16b, \s0\().16b, \s1\().16b
   .else
     eor \s0\().16b, \s0\().16b, \s1\().16b
   .endif
.endm

 .macro xar_m1_1 d s0 s1 imm
   // Special cases where we can replace SHLs by ADDs
   .if \imm == 63
     add \d\().2d, \s0\().2d, \s0\().2d
     sri \d\().2d, \s0\().2d, #(63)
   .elseif \imm == 62
     add \d\().2d, \s0\().2d, \s0\().2d
     add \d\().2d, \d\().2d,  \d\().2d
     sri \d\().2d, \s0\().2d, #(62)
   .else
     shl \d\().2d, \s0\().2d, #(64-\imm)
     sri \d\().2d, \s0\().2d, #(\imm)
   .endif
.endm

.macro bcax_m1 d s0 s1 s2
    bic vvtmp.16b, \s1\().16b, \s2\().16b
    eor \d\().16b, vvtmp.16b, \s0\().16b
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

#define STACK_SIZE (8*8 + 16*6 + 3*8 + 8 + 16*34) // VREGS (8*8), GPRs (16*6), count (8), const (8), input (8), padding (8)
#define STACK_BASE_GPRS  (3*8+8)
#define STACK_BASE_VREGS (3*8+8+16*6)
#define STACK_BASE_TMP (8*8 + 16*6 + 3*8 + 8)
#define STACK_OFFSET_INPUT (0*8)
#define STACK_OFFSET_CONST (1*8)
#define STACK_OFFSET_COUNT (2*8)

#define vAga_offset 0
#define E0_offset  1
#define E1_offset  2
#define E2_offset  3
#define E3_offset  4
#define E4_offset  5
#define Ame_offset  7
#define Agi_offset  8
#define Aka_offset  9
#define Abo_offset  10
#define Amo_offset  11
#define Ami_offset  12
#define Ake_offset  13
#define Agu_offset  14
#define Asi_offset  15
#define Aku_offset  16
#define Asa_offset  17
#define Abu_offset  18
#define Asu_offset  19
#define Ase_offset  20
//#define Aga_offset  21
#define Age_offset  22
#define vBgo_offset 23
#define vBke_offset 24
#define vBgi_offset 25
#define vBga_offset 26
#define vBbo_offset 27
#define vBmo_offset 28
#define vBmi_offset 29
#define vBge_offset 30

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
eor sC0, sAma, sAsa                             SEP      eor3_m1_0 C1,vAbe,vAge,vAke
eor sC1, sAme, sAse                             SEP
eor sC2, sAmi, sAsi                             SEP      eor3_m1_0 C3,vAbo,vAgo,vAko
eor sC3, sAmo, sAso                             SEP
eor sC4, sAmu, sAsu                             SEP      eor3_m1_0 C0,vAba,vAga,vAka
eor sC0, sAka, sC0                              SEP
eor sC1, sAke, sC1                              SEP      eor3_m1_0 C2,vAbi,vAgi,vAki
eor sC2, sAki, sC2                              SEP
eor sC3, sAko, sC3                              SEP      eor3_m1_0 C4,vAbu,vAgu,vAku
eor sC4, sAku, sC4                              SEP
eor sC0, sAga, sC0                              SEP      eor3_m1_1 C1,vAbe,vAge,vAke
eor sC1, sAge, sC1                              SEP      eor3_m1_1 C3,vAbo,vAgo,vAko
eor sC2, sAgi, sC2                              SEP
eor sC3, sAgo, sC3                              SEP      eor3_m1_1 C0,vAba,vAga,vAka
eor sC4, sAgu, sC4                              SEP
eor sC0, s_Aba, sC0                             SEP      eor3_m1_1 C2,vAbi,vAgi,vAki
eor sC1, sAbe, sC1                              SEP
eor sC2, sAbi, sC2                              SEP      eor3_m1_1 C4,vAbu,vAgu,vAku
eor sC3, sAbo, sC3                              SEP
eor sC4, sAbu, sC4                              SEP      eor3_m1_0 C1, C1,vAme, vAse
eor sE1, sC0, sC2, ROR #63                      SEP      eor3_m1_0 C3, C3,vAmo, vAso
eor sE3, sC2, sC4, ROR #63                      SEP
eor sE0, sC4, sC1, ROR #63                      SEP      eor3_m1_0 C0, C0,vAma, vAsa
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP      eor3_m1_0 C2, C2,vAmi, vAsi
eor s_Aba_, s_Aba, sE0                          SEP
eor sAsa_, sAbi, sE2                            SEP      eor3_m1_0 C4, C4,vAmu, vAsu
eor sAbi_, sAki, sE2                            SEP
eor sAki_, sAko, sE3                            SEP      eor3_m1_1 C1, C1,vAme, vAse
eor sAko_, sAmu, sE4                            SEP      eor3_m1_1 C3, C3,vAmo, vAso
eor sAmu_, sAso, sE3                            SEP
eor sAso_, sAma, sE0                            SEP      eor3_m1_1 C0, C0,vAma, vAsa
eor sAka_, sAbe, sE1                            SEP
eor sAse_, sAgo, sE3                            SEP      eor3_m1_1 C2, C2,vAmi, vAsi
eor sAgo_, sAme, sE1                            SEP
eor sAke_, sAgi, sE2                            SEP      eor3_m1_1 C4, C4,vAmu, vAsu
eor sAgi_, sAka, sE0                            SEP
eor sAga_, sAbo, sE3                            SEP      vvtmp .req vBba
eor sAbo_, sAmo, sE3                            SEP      rax1_m1 E2, C1, C3
eor sAmo_, sAmi, sE2                            SEP
eor sAmi_, sAke, sE1                            SEP      rax1_m1 E4, C3, C0
eor sAge_, sAgu, sE4                            SEP
eor sAgu_, sAsi, sE2                            SEP      rax1_m1 E1, C0, C2
eor sAsi_, sAku, sE4                            SEP
eor sAku_, sAsa, sE0                            SEP      rax1_m1 E3, C2, C4
eor sAma_, sAbu, sE4                            SEP
eor sAbu_, sAsu, sE4                            SEP      str vAgiq, [sp, #(STACK_BASE_TMP + 16*32)]
eor sAsu_, sAse, sE1                            SEP      rax1_m1 E0, C4, C1
eor sAme_, sAga, sE0                            SEP
eor sAbe_, sAge, sE1                            SEP      /* 25x XAR, 75 in total */
load_constant_ptr                               SEP
bic tmp, sAgi_, sAge_, ROR #47                  SEP      .unreq vvtmp
eor sAga, tmp,  sAga_, ROR #39                  SEP
bic tmp, sAgo_, sAgi_, ROR #42                  SEP      vvtmp .req C1
eor sAge, tmp,  sAge_, ROR #25                  SEP
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      vvtmpq .req C1q
eor sAgi, tmp,  sAgi_, ROR #58                  SEP      xar_m1 vBgi, vAka, E0, 61
bic tmp, sAga_, sAgu_, ROR #31                  SEP
eor sAgo, tmp,  sAgo_, ROR #47                  SEP      xar_m1 vBga, vAbo, E3, 36
bic tmp, sAge_, sAga_, ROR #56                  SEP
eor sAgu, tmp,  sAgu_, ROR #23                  SEP      str vAgaq, [sp, #(STACK_BASE_TMP + 16 * 30)]
bic tmp, sAki_, sAke_, ROR #19                  SEP
eor sAka, tmp,  sAka_, ROR #24                  SEP      xar_m1 vBbo, vAmo, E3, 43
bic tmp, sAko_, sAki_, ROR #47                  SEP
eor sAke, tmp,  sAke_, ROR #2                   SEP      xar_m1 vBmo, vAmi, E2, 49
bic tmp, sAku_, sAko_, ROR #10                  SEP      str vAgeq, [sp, #(STACK_BASE_TMP + 16 * 31)]
eor sAki, tmp,  sAki_, ROR #57                  SEP
bic tmp, sAka_, sAku_, ROR #47                  SEP      xar_m1 vBmi, vAke, E1, 54
eor sAko, tmp,  sAko_, ROR #57                  SEP
bic tmp, sAke_, sAka_, ROR #5                   SEP      xar_m1 vBge, vAgu, E4, 44
eor sAku, tmp,  sAku_, ROR #52                  SEP
bic tmp, sAmi_, sAme_, ROR #38                  SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor sAma, tmp,  sAma_, ROR #47                  SEP
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      eor vBba.16b, vAba.16b, E0.16b
eor sAme, tmp,  sAme_, ROR #43                  SEP
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      xar_m1 vBsa, vAbi, E2, 2
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      xar_m1 vBbi, vAki, E2, 21
ldr cur_const, [const_addr]                     SEP
mov count, #1                                   SEP      xar_m1 vBki, vAko, E3, 39
bic tmp, sAma_, sAmu_, ROR #35                  SEP
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      xar_m1 vBko, vAmu, E4, 56
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      xar_m1 vBmu, vAso, E3, 8
bic tmp, sAsi_, sAse_, ROR #48                  SEP
eor sAsa, tmp,  sAsa_, ROR #41                  SEP      xar_m1 vBso, vAma, E0, 23
bic tmp, sAso_, sAsi_, ROR #2                   SEP      xar_m1 vBka, vAbe, E1, 63
eor sAse, tmp,  sAse_, ROR #50                  SEP
bic tmp, sAsu_, sAso_, ROR #25                  SEP      xar_m1 vBse, vAgo, E3, 9
eor sAsi, tmp,  sAsi_, ROR #27                  SEP
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      xar_m1 vBgo, vAme, E1, 19
eor sAso, tmp,  sAso_, ROR #21                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP      bcax_m1 vAge, vBge, vBgo, vBgi
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      ldr vvtmpq, [sp, #(STACK_BASE_TMP + 16*32)]
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP      xar_m1 vBke, vvtmp, E2, 58
bic tmp, sAbo_, sAbi_, ROR #42                  SEP
eor sAbe, tmp,  sAbe_, ROR #41                  SEP      xar_m1 vBgu, vAsi, E2, 3
bic tmp, sAbu_, sAbo_, ROR #57                  SEP
eor sAbi, tmp,  sAbi_, ROR #35                  SEP      bcax_m1 vAgi, vBgi, vBgu, vBgo
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      xar_m1 vBsi, vAku, E4, 25
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      xar_m1 vBku, vAsa, E0, 46
eor s_Aba, s_Aba, cur_const                     SEP      xar_m1 vBma, vAbu, E4, 37
save count, STACK_OFFSET_COUNT                  SEP
eor sC0, sAka, sAsa, ROR #50                    SEP      xar_m1 vBbu, vAsu, E4, 50
eor sC1, sAse, sAge, ROR #60                    SEP
eor sC2, sAmi, sAgi, ROR #59                    SEP      xar_m1 vBsu, vAse, E1, 62
eor sC3, sAgo, sAso, ROR #30                    SEP
eor sC4, sAbu, sAsu, ROR #53                    SEP      ldp vvtmpq, E3q, [sp, #(STACK_BASE_TMP + 16*30)]
eor sC0, sAma, sC0, ROR #49                     SEP
eor sC1, sAbe, sC1, ROR #44                     SEP      xar_m1 vBme, vvtmp, E0, 28
eor sC2, sAki, sC2, ROR #26                     SEP      xar_m1 vBbe, E3,  E1, 20
eor sC3, sAmo, sC3, ROR #63                     SEP
eor sC4, sAmu, sC4, ROR #56                     SEP      /* 25x BCAX, 50 in total */
eor sC0, sAga, sC0, ROR #57                     SEP
eor sC1, sAme, sC1, ROR #58                     SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP      bcax_m1 vAgu, vBgu, vBge, vBga
eor sC4, sAgu, sC4, ROR #48                     SEP
eor sC0, s_Aba, sC0, ROR #61                    SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sC1, sAke, sC1, ROR #57                     SEP      bcax_m1 vAke, vBke, vBko, vBki
eor sC2, sAsi, sC2, ROR #52                     SEP
eor sC3, sAbo, sC3, ROR #63                     SEP      .unreq vvtmp
eor sC4, sAku, sC4, ROR #50                     SEP
ror sC1, sC1, 56                                SEP      .unreq vvtmpq
ror sC4, sC4, 58                                SEP
ror sC2, sC2, 62                                SEP      eor2    C0,  vAka, vAga
eor sE1, sC0, sC2, ROR #63                      SEP
eor sE3, sC2, sC4, ROR #63                      SEP      save(vAga)
eor sE0, sC4, sC1, ROR #63                      SEP      vvtmp .req vAga
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP      vvtmpq .req vAgaq
eor s_Aba_, sE0, s_Aba                          SEP
eor sAsa_, sE2, sAbi, ROR #50                   SEP      bcax_m1 vAki, vBki, vBku, vBko
eor sAbi_, sE2, sAki, ROR #46                   SEP
eor sAki_, sE3, sAko, ROR #63                   SEP      bcax_m1 vAko, vBko, vBka, vBku
eor sAko_, sE4, sAmu, ROR #28                   SEP
eor sAmu_, sE3, sAso, ROR #2                    SEP      eor2    C1,  vAke, vAge
eor sAso_, sE0, sAma, ROR #54                   SEP      bcax_m1 vAku, vBku, vBke, vBka
eor sAka_, sE1, sAbe, ROR #43                   SEP
eor sAse_, sE3, sAgo, ROR #36                   SEP      eor2    C2,  vAki, vAgi
eor sAgo_, sE1, sAme, ROR #49                   SEP
eor sAke_, sE2, sAgi, ROR #3                    SEP      bcax_m1 vAma, vBma, vBmi, vBme
eor sAgi_, sE0, sAka, ROR #39                   SEP
eor sAga_, sE3, sAbo                            SEP      eor2    C3,  vAko, vAgo
eor sAbo_, sE3, sAmo, ROR #37                   SEP
eor sAmo_, sE2, sAmi, ROR #8                    SEP      bcax_m1 vAme, vBme, vBmo, vBmi
eor sAmi_, sE1, sAke, ROR #56                   SEP
eor sAge_, sE4, sAgu, ROR #44                   SEP      eor2    C4,  vAku, vAgu
eor sAgu_, sE2, sAsi, ROR #62                   SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
eor sAsi_, sE4, sAku, ROR #58                   SEP
eor sAku_, sE0, sAsa, ROR #25                   SEP      eor2    C0,  C0,  vAma
eor sAma_, sE4, sAbu, ROR #20                   SEP
eor sAbu_, sE4, sAsu, ROR #9                    SEP      bcax_m1 vAmo, vBmo, vBma, vBmu
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP      eor2    C1,  C1,  vAme
eor sAbe_, sE1, sAge, ROR #19                   SEP
load_constant_ptr                               SEP      bcax_m1 vAmu, vBmu, vBme, vBma
restore count, STACK_OFFSET_COUNT               SEP      eor2    C2,  C2,  vAmi
bic tmp, sAgi_, sAge_, ROR #47                  SEP
eor sAga, tmp,  sAga_, ROR #39                  SEP      bcax_m1 vAsa, vBsa, vBsi, vBse
bic tmp, sAgo_, sAgi_, ROR #42                  SEP
eor sAge, tmp,  sAge_, ROR #25                  SEP      eor2    C3,  C3,  vAmo
bic tmp, sAgu_, sAgo_, ROR #16                  SEP
eor sAgi, tmp,  sAgi_, ROR #58                  SEP      bcax_m1 vAse, vBse, vBso, vBsi
bic tmp, sAga_, sAgu_, ROR #31                  SEP
eor sAgo, tmp,  sAgo_, ROR #47                  SEP      eor2    C4,  C4,  vAmu
bic tmp, sAge_, sAga_, ROR #56                  SEP      bcax_m1 vAsi, vBsi, vBsu, vBso
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP      eor2    C0,  C0,  vAsa
eor sAka, tmp,  sAka_, ROR #24                  SEP
bic tmp, sAko_, sAki_, ROR #47                  SEP      bcax_m1 vAso, vBso, vBsa, vBsu
eor sAke, tmp,  sAke_, ROR #2                   SEP
bic tmp, sAku_, sAko_, ROR #10                  SEP      eor2    C1,  C1,  vAse
eor sAki, tmp,  sAki_, ROR #57                  SEP
bic tmp, sAka_, sAku_, ROR #47                  SEP      bcax_m1 vAsu, vBsu, vBse, vBsa
eor sAko, tmp,  sAko_, ROR #57                  SEP      eor2    C2,  C2,  vAsi
bic tmp, sAke_, sAka_, ROR #5                   SEP
eor sAku, tmp,  sAku_, ROR #52                  SEP      eor2    C3,  C3,  vAso
bic tmp, sAmi_, sAme_, ROR #38                  SEP
eor sAma, tmp,  sAma_, ROR #47                  SEP      bcax_m1 vAba, vBba, vBbi, vBbe
bic tmp, sAmo_, sAmi_, ROR #5                   SEP
eor sAme, tmp,  sAme_, ROR #43                  SEP      bcax_m1 vAbe, vBbe, vBbo, vBbi
bic tmp, sAmu_, sAmo_, ROR #41                  SEP
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      eor2    C1,  C1,  vAbe
bic tmp, sAma_, sAmu_, ROR #35                  SEP      restore x26, STACK_OFFSET_CONST
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      ldr vvtmpq, [x26], #16
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      save x26, STACK_OFFSET_CONST
bic tmp, sAsi_, sAse_, ROR #48                  SEP
ldr cur_const, [const_addr, count, UXTW #3]     SEP
eor sAsa, tmp,  sAsa_, ROR #41                  SEP      eor vAba.16b, vAba.16b, vvtmp.16b
bic tmp, sAso_, sAsi_, ROR #2                   SEP
eor sAse, tmp,  sAse_, ROR #50                  SEP      eor2    C4,  C4,  vAsu
bic tmp, sAsu_, sAso_, ROR #25                  SEP      bcax_m1 vAbi, vBbi, vBbu, vBbo
eor sAsi, tmp,  sAsi_, ROR #27                  SEP
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
eor sAso, tmp,  sAso_, ROR #21                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP      eor2    C3,  C3,  vAbo
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      eor2    C2,  C2,  vAbi
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      eor2    C0,  C0,  vAba
eor sAbe, tmp,  sAbe_, ROR #41                  SEP      bcax_m1 vAbu, vBbu, vBbe, vBba
bic tmp, sAbu_, sAbo_, ROR #57                  SEP
eor sAbi, tmp,  sAbi_, ROR #35                  SEP      eor2    C4,  C4,  vAbu
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      restore(vAga)
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      .unreq vvtmp
add count, count, #1                            SEP
eor s_Aba, s_Aba, cur_const                     SEP      .unreq vvtmpq
.endm


.macro  hybrid_round_noninitial
save count, STACK_OFFSET_COUNT                  SEP
eor sC0, sAka, sAsa, ROR #50                    SEP      vvtmp .req vBba
eor sC1, sAse, sAge, ROR #60                    SEP      rax1_m1 E2, C1, C3
eor sC2, sAmi, sAgi, ROR #59                    SEP      rax1_m1 E4, C3, C0
eor sC3, sAgo, sAso, ROR #30                    SEP
eor sC4, sAbu, sAsu, ROR #53                    SEP
eor sC0, sAma, sC0, ROR #49                     SEP
eor sC1, sAbe, sC1, ROR #44                     SEP      rax1_m1 E1, C0, C2
eor sC2, sAki, sC2, ROR #26                     SEP
eor sC3, sAmo, sC3, ROR #63                     SEP
eor sC4, sAmu, sC4, ROR #56                     SEP      rax1_m1 E3, C2, C4
eor sC0, sAga, sC0, ROR #57                     SEP
eor sC1, sAme, sC1, ROR #58                     SEP      str vAgiq, [sp, #(STACK_BASE_TMP + 16*32)]
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP      rax1_m1 E0, C4, C1
eor sC4, sAgu, sC4, ROR #48                     SEP
eor sC0, s_Aba, sC0, ROR #61                    SEP      .unreq vvtmp
eor sC1, sAke, sC1, ROR #57                     SEP
eor sC2, sAsi, sC2, ROR #52                     SEP
eor sC3, sAbo, sC3, ROR #63                     SEP      vvtmp .req C1
eor sC4, sAku, sC4, ROR #50                     SEP
ror sC1, sC1, 56                                SEP      vvtmpq .req C1q
ror sC4, sC4, 58                                SEP
ror sC2, sC2, 62                                SEP      xar_m1 vBgi, vAka, E0, 61
eor sE1, sC0, sC2, ROR #63                      SEP
eor sE3, sC2, sC4, ROR #63                      SEP      xar_m1 vBga, vAbo, E3, 36
eor sE0, sC4, sC1, ROR #63                      SEP
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP      str vAgaq, [sp, #(STACK_BASE_TMP + 16 * 30)]
eor s_Aba_, sE0, s_Aba                          SEP
eor sAsa_, sE2, sAbi, ROR #50                   SEP      xar_m1 vBbo, vAmo, E3, 43
eor sAbi_, sE2, sAki, ROR #46                   SEP
eor sAki_, sE3, sAko, ROR #63                   SEP      xar_m1 vBmo, vAmi, E2, 49
eor sAko_, sE4, sAmu, ROR #28                   SEP
eor sAmu_, sE3, sAso, ROR #2                    SEP
eor sAso_, sE0, sAma, ROR #54                   SEP      str vAgeq, [sp, #(STACK_BASE_TMP + 16 * 31)]
eor sAka_, sE1, sAbe, ROR #43                   SEP
eor sAse_, sE3, sAgo, ROR #36                   SEP      xar_m1 vBmi, vAke, E1, 54
eor sAgo_, sE1, sAme, ROR #49                   SEP
eor sAke_, sE2, sAgi, ROR #3                    SEP      xar_m1 vBge, vAgu, E4, 44
eor sAgi_, sE0, sAka, ROR #39                   SEP
eor sAga_, sE3, sAbo                            SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor sAbo_, sE3, sAmo, ROR #37                   SEP
eor sAmo_, sE2, sAmi, ROR #8                    SEP
eor sAmi_, sE1, sAke, ROR #56                   SEP      eor vBba.16b, vAba.16b, E0.16b
eor sAge_, sE4, sAgu, ROR #44                   SEP
eor sAgu_, sE2, sAsi, ROR #62                   SEP      xar_m1 vBsa, vAbi, E2, 2
eor sAsi_, sE4, sAku, ROR #58                   SEP
eor sAku_, sE0, sAsa, ROR #25                   SEP      xar_m1 vBbi, vAki, E2, 21
eor sAma_, sE4, sAbu, ROR #20                   SEP
eor sAbu_, sE4, sAsu, ROR #9                    SEP      xar_m1 vBki, vAko, E3, 39
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP
eor sAbe_, sE1, sAge, ROR #19                   SEP      xar_m1 vBko, vAmu, E4, 56
load_constant_ptr                               SEP
restore count, STACK_OFFSET_COUNT               SEP      xar_m1 vBmu, vAso, E3, 8
bic tmp, sAgi_, sAge_, ROR #47                  SEP
eor sAga, tmp,  sAga_, ROR #39                  SEP      xar_m1 vBso, vAma, E0, 23
bic tmp, sAgo_, sAgi_, ROR #42                  SEP
eor sAge, tmp,  sAge_, ROR #25                  SEP
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      xar_m1 vBka, vAbe, E1, 63
eor sAgi, tmp,  sAgi_, ROR #58                  SEP
bic tmp, sAga_, sAgu_, ROR #31                  SEP      xar_m1 vBse, vAgo, E3, 9
eor sAgo, tmp,  sAgo_, ROR #47                  SEP
bic tmp, sAge_, sAga_, ROR #56                  SEP      xar_m1 vBgo, vAme, E1, 19
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP      bcax_m1 vAge, vBge, vBgo, vBgi
eor sAka, tmp,  sAka_, ROR #24                  SEP
bic tmp, sAko_, sAki_, ROR #47                  SEP
eor sAke, tmp,  sAke_, ROR #2                   SEP      ldr vvtmpq, [sp, #(STACK_BASE_TMP + 16*32)]
bic tmp, sAku_, sAko_, ROR #10                  SEP
eor sAki, tmp,  sAki_, ROR #57                  SEP      xar_m1 vBke, vvtmp, E2, 58
bic tmp, sAka_, sAku_, ROR #47                  SEP
eor sAko, tmp,  sAko_, ROR #57                  SEP      xar_m1 vBgu, vAsi, E2, 3
bic tmp, sAke_, sAka_, ROR #5                   SEP
eor sAku, tmp,  sAku_, ROR #52                  SEP      bcax_m1 vAgi, vBgi, vBgu, vBgo
bic tmp, sAmi_, sAme_, ROR #38                  SEP
eor sAma, tmp,  sAma_, ROR #47                  SEP
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      xar_m1 vBsi, vAku, E4, 25
eor sAme, tmp,  sAme_, ROR #43                  SEP
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      xar_m1 vBku, vAsa, E0, 46
eor sAmi, tmp,  sAmi_, ROR #46                  SEP
bic tmp, sAma_, sAmu_, ROR #35                  SEP      xar_m1 vBma, vAbu, E4, 37
ldr cur_const, [const_addr, count, UXTW #3]     SEP
add count, count, #1                            SEP
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      xar_m1 vBbu, vAsu, E4, 50
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      xar_m1 vBsu, vAse, E1, 62
bic tmp, sAsi_, sAse_, ROR #48                  SEP
eor sAsa, tmp,  sAsa_, ROR #41                  SEP      ldp vvtmpq, E3q, [sp, #(STACK_BASE_TMP + 16*30)]
bic tmp, sAso_, sAsi_, ROR #2                   SEP
eor sAse, tmp,  sAse_, ROR #50                  SEP      xar_m1 vBme, vvtmp, E0, 28
bic tmp, sAsu_, sAso_, ROR #25                  SEP
eor sAsi, tmp,  sAsi_, ROR #27                  SEP
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      xar_m1 vBbe, E3,  E1, 20
eor sAso, tmp,  sAso_, ROR #21                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      bcax_m1 vAgu, vBgu, vBge, vBga
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sAbe, tmp,  sAbe_, ROR #41                  SEP
bic tmp, sAbu_, sAbo_, ROR #57                  SEP
eor sAbi, tmp,  sAbi_, ROR #35                  SEP      bcax_m1 vAke, vBke, vBko, vBki
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      .unreq vvtmp
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      .unreq vvtmpq
eor s_Aba, s_Aba, cur_const                     SEP
save count, STACK_OFFSET_COUNT                  SEP
eor sC0, sAka, sAsa, ROR #50                    SEP      eor2    C0,  vAka, vAga
eor sC1, sAse, sAge, ROR #60                    SEP
eor sC2, sAmi, sAgi, ROR #59                    SEP      save(vAga)
eor sC3, sAgo, sAso, ROR #30                    SEP
eor sC4, sAbu, sAsu, ROR #53                    SEP      vvtmp .req vAga
eor sC0, sAma, sC0, ROR #49                     SEP
eor sC1, sAbe, sC1, ROR #44                     SEP      vvtmpq .req vAgaq
eor sC2, sAki, sC2, ROR #26                     SEP
eor sC3, sAmo, sC3, ROR #63                     SEP
eor sC4, sAmu, sC4, ROR #56                     SEP      bcax_m1 vAki, vBki, vBku, vBko
eor sC0, sAga, sC0, ROR #57                     SEP
eor sC1, sAme, sC1, ROR #58                     SEP      bcax_m1 vAko, vBko, vBka, vBku
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP      eor2    C1,  vAke, vAge
eor sC4, sAgu, sC4, ROR #48                     SEP
eor sC0, s_Aba, sC0, ROR #61                    SEP      bcax_m1 vAku, vBku, vBke, vBka
eor sC1, sAke, sC1, ROR #57                     SEP
eor sC2, sAsi, sC2, ROR #52                     SEP
eor sC3, sAbo, sC3, ROR #63                     SEP      eor2    C2,  vAki, vAgi
eor sC4, sAku, sC4, ROR #50                     SEP
ror sC1, sC1, 56                                SEP      bcax_m1 vAma, vBma, vBmi, vBme
ror sC4, sC4, 58                                SEP
ror sC2, sC2, 62                                SEP      eor2    C3,  vAko, vAgo
eor sE1, sC0, sC2, ROR #63                      SEP
eor sE3, sC2, sC4, ROR #63                      SEP      bcax_m1 vAme, vBme, vBmo, vBmi
eor sE0, sC4, sC1, ROR #63                      SEP
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP      eor2    C4,  vAku, vAgu
eor s_Aba_, sE0, s_Aba                          SEP
eor sAsa_, sE2, sAbi, ROR #50                   SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
eor sAbi_, sE2, sAki, ROR #46                   SEP
eor sAki_, sE3, sAko, ROR #63                   SEP      eor2    C0,  C0,  vAma
eor sAko_, sE4, sAmu, ROR #28                   SEP
eor sAmu_, sE3, sAso, ROR #2                    SEP
eor sAso_, sE0, sAma, ROR #54                   SEP      bcax_m1 vAmo, vBmo, vBma, vBmu
eor sAka_, sE1, sAbe, ROR #43                   SEP
eor sAse_, sE3, sAgo, ROR #36                   SEP      eor2    C1,  C1,  vAme
eor sAgo_, sE1, sAme, ROR #49                   SEP
eor sAke_, sE2, sAgi, ROR #3                    SEP      bcax_m1 vAmu, vBmu, vBme, vBma
eor sAgi_, sE0, sAka, ROR #39                   SEP
eor sAga_, sE3, sAbo                            SEP      eor2    C2,  C2,  vAmi
eor sAbo_, sE3, sAmo, ROR #37                   SEP
eor sAmo_, sE2, sAmi, ROR #8                    SEP
eor sAmi_, sE1, sAke, ROR #56                   SEP      bcax_m1 vAsa, vBsa, vBsi, vBse
eor sAge_, sE4, sAgu, ROR #44                   SEP
eor sAgu_, sE2, sAsi, ROR #62                   SEP      eor2    C3,  C3,  vAmo
eor sAsi_, sE4, sAku, ROR #58                   SEP
eor sAku_, sE0, sAsa, ROR #25                   SEP      bcax_m1 vAse, vBse, vBso, vBsi
eor sAma_, sE4, sAbu, ROR #20                   SEP
eor sAbu_, sE4, sAsu, ROR #9                    SEP      eor2    C4,  C4,  vAmu
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP
eor sAbe_, sE1, sAge, ROR #19                   SEP      bcax_m1 vAsi, vBsi, vBsu, vBso
load_constant_ptr                               SEP
restore count, STACK_OFFSET_COUNT               SEP      eor2    C0,  C0,  vAsa
bic tmp, sAgi_, sAge_, ROR #47                  SEP
eor sAga, tmp,  sAga_, ROR #39                  SEP      bcax_m1 vAso, vBso, vBsa, vBsu
bic tmp, sAgo_, sAgi_, ROR #42                  SEP
eor sAge, tmp,  sAge_, ROR #25                  SEP
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      eor2    C1,  C1,  vAse
eor sAgi, tmp,  sAgi_, ROR #58                  SEP
bic tmp, sAga_, sAgu_, ROR #31                  SEP      bcax_m1 vAsu, vBsu, vBse, vBsa
eor sAgo, tmp,  sAgo_, ROR #47                  SEP
bic tmp, sAge_, sAga_, ROR #56                  SEP      eor2    C2,  C2,  vAsi
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP      eor2    C3,  C3,  vAso
eor sAka, tmp,  sAka_, ROR #24                  SEP
bic tmp, sAko_, sAki_, ROR #47                  SEP
eor sAke, tmp,  sAke_, ROR #2                   SEP      bcax_m1 vAba, vBba, vBbi, vBbe
bic tmp, sAku_, sAko_, ROR #10                  SEP
eor sAki, tmp,  sAki_, ROR #57                  SEP      bcax_m1 vAbe, vBbe, vBbo, vBbi
bic tmp, sAka_, sAku_, ROR #47                  SEP
eor sAko, tmp,  sAko_, ROR #57                  SEP      eor2    C1,  C1,  vAbe
bic tmp, sAke_, sAka_, ROR #5                   SEP
eor sAku, tmp,  sAku_, ROR #52                  SEP      restore x26, STACK_OFFSET_CONST
bic tmp, sAmi_, sAme_, ROR #38                  SEP
eor sAma, tmp,  sAma_, ROR #47                  SEP
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      ldr vvtmpq, [x26], #16
eor sAme, tmp,  sAme_, ROR #43                  SEP
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      save x26, STACK_OFFSET_CONST
eor sAmi, tmp,  sAmi_, ROR #46                  SEP
bic tmp, sAma_, sAmu_, ROR #35                  SEP      eor vAba.16b, vAba.16b, vvtmp.16b
ldr cur_const, [const_addr, count, UXTW #3]     SEP
add count, count, #1                            SEP
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      eor2    C4,  C4,  vAsu
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      bcax_m1 vAbi, vBbi, vBbu, vBbo
bic tmp, sAsi_, sAse_, ROR #48                  SEP
eor sAsa, tmp,  sAsa_, ROR #41                  SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
bic tmp, sAso_, sAsi_, ROR #2                   SEP
eor sAse, tmp,  sAse_, ROR #50                  SEP      eor2    C3,  C3,  vAbo
bic tmp, sAsu_, sAso_, ROR #25                  SEP
eor sAsi, tmp,  sAsi_, ROR #27                  SEP
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      eor2    C2,  C2,  vAbi
eor sAso, tmp,  sAso_, ROR #21                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP      eor2    C0,  C0,  vAba
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      bcax_m1 vAbu, vBbu, vBbe, vBba
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      eor2    C4,  C4,  vAbu
eor sAbe, tmp,  sAbe_, ROR #41                  SEP
bic tmp, sAbu_, sAbo_, ROR #57                  SEP
eor sAbi, tmp,  sAbi_, ROR #35                  SEP      restore(vAga)
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      .unreq vvtmp
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      .unreq vvtmpq
eor s_Aba, s_Aba, cur_const                     SEP
.endm
.macro  hybrid_round_final
                                                SEP      vvtmp .req vBba
save count, STACK_OFFSET_COUNT                  SEP      rax1_m1 E2, C1, C3
eor sC0, sAka, sAsa, ROR #50                    SEP
eor sC1, sAse, sAge, ROR #60                    SEP      rax1_m1 E4, C3, C0
eor sC2, sAmi, sAgi, ROR #59                    SEP
eor sC3, sAgo, sAso, ROR #30                    SEP      rax1_m1 E1, C0, C2
eor sC4, sAbu, sAsu, ROR #53                    SEP
eor sC0, sAma, sC0, ROR #49                     SEP
eor sC1, sAbe, sC1, ROR #44                     SEP
eor sC2, sAki, sC2, ROR #26                     SEP
eor sC3, sAmo, sC3, ROR #63                     SEP
eor sC4, sAmu, sC4, ROR #56                     SEP
eor sC0, sAga, sC0, ROR #57                     SEP
eor sC1, sAme, sC1, ROR #58                     SEP
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP      rax1_m1 E3, C2, C4
eor sC4, sAgu, sC4, ROR #48                     SEP
eor sC0, s_Aba, sC0, ROR #61                    SEP
eor sC1, sAke, sC1, ROR #57                     SEP
eor sC2, sAsi, sC2, ROR #52                     SEP      str vAgiq, [sp, #(STACK_BASE_TMP + 16*32)]
eor sC3, sAbo, sC3, ROR #63                     SEP
eor sC4, sAku, sC4, ROR #50                     SEP
ror sC1, sC1, 56                                SEP      rax1_m1 E0, C4, C1
ror sC4, sC4, 58                                SEP
ror sC2, sC2, 62                                SEP
eor sE1, sC0, sC2, ROR #63                      SEP
eor sE3, sC2, sC4, ROR #63                      SEP      .unreq vvtmp
eor sE0, sC4, sC1, ROR #63                      SEP
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP      vvtmp .req C1
eor s_Aba_, sE0, s_Aba                          SEP
eor sAsa_, sE2, sAbi, ROR #50                   SEP
eor sAbi_, sE2, sAki, ROR #46                   SEP      vvtmpq .req C1q
eor sAki_, sE3, sAko, ROR #63                   SEP
eor sAko_, sE4, sAmu, ROR #28                   SEP
eor sAmu_, sE3, sAso, ROR #2                    SEP
eor sAso_, sE0, sAma, ROR #54                   SEP      xar_m1 vBgi, vAka, E0, 61
eor sAka_, sE1, sAbe, ROR #43                   SEP
eor sAse_, sE3, sAgo, ROR #36                   SEP
eor sAgo_, sE1, sAme, ROR #49                   SEP      xar_m1 vBga, vAbo, E3, 36
eor sAke_, sE2, sAgi, ROR #3                    SEP
eor sAgi_, sE0, sAka, ROR #39                   SEP
eor sAga_, sE3, sAbo                            SEP
eor sAbo_, sE3, sAmo, ROR #37                   SEP      str vAgaq, [sp, #(STACK_BASE_TMP + 16 * 30)]
eor sAmo_, sE2, sAmi, ROR #8                    SEP
eor sAmi_, sE1, sAke, ROR #56                   SEP
eor sAge_, sE4, sAgu, ROR #44                   SEP      xar_m1 vBbo, vAmo, E3, 43
eor sAgu_, sE2, sAsi, ROR #62                   SEP
eor sAsi_, sE4, sAku, ROR #58                   SEP
eor sAku_, sE0, sAsa, ROR #25                   SEP
eor sAma_, sE4, sAbu, ROR #20                   SEP      xar_m1 vBmo, vAmi, E2, 49
eor sAbu_, sE4, sAsu, ROR #9                    SEP
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP      str vAgeq, [sp, #(STACK_BASE_TMP + 16 * 31)]
eor sAbe_, sE1, sAge, ROR #19                   SEP
load_constant_ptr                               SEP
restore count, STACK_OFFSET_COUNT               SEP
bic tmp, sAgi_, sAge_, ROR #47                  SEP      xar_m1 vBmi, vAke, E1, 54
eor sAga, tmp,  sAga_, ROR #39                  SEP
bic tmp, sAgo_, sAgi_, ROR #42                  SEP
eor sAge, tmp,  sAge_, ROR #25                  SEP      xar_m1 vBge, vAgu, E4, 44
bic tmp, sAgu_, sAgo_, ROR #16                  SEP
eor sAgi, tmp,  sAgi_, ROR #58                  SEP
bic tmp, sAga_, sAgu_, ROR #31                  SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor sAgo, tmp,  sAgo_, ROR #47                  SEP
bic tmp, sAge_, sAga_, ROR #56                  SEP
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP      eor vBba.16b, vAba.16b, E0.16b
eor sAka, tmp,  sAka_, ROR #24                  SEP
bic tmp, sAko_, sAki_, ROR #47                  SEP
eor sAke, tmp,  sAke_, ROR #2                   SEP      xar_m1 vBsa, vAbi, E2, 2
bic tmp, sAku_, sAko_, ROR #10                  SEP
eor sAki, tmp,  sAki_, ROR #57                  SEP
bic tmp, sAka_, sAku_, ROR #47                  SEP
eor sAko, tmp,  sAko_, ROR #57                  SEP      xar_m1 vBbi, vAki, E2, 21
bic tmp, sAke_, sAka_, ROR #5                   SEP
eor sAku, tmp,  sAku_, ROR #52                  SEP
bic tmp, sAmi_, sAme_, ROR #38                  SEP      xar_m1 vBki, vAko, E3, 39
eor sAma, tmp,  sAma_, ROR #47                  SEP
bic tmp, sAmo_, sAmi_, ROR #5                   SEP
eor sAme, tmp,  sAme_, ROR #43                  SEP
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      xar_m1 vBko, vAmu, E4, 56
eor sAmi, tmp,  sAmi_, ROR #46                  SEP
bic tmp, sAma_, sAmu_, ROR #35                  SEP
ldr cur_const, [const_addr, count, UXTW #3]     SEP      xar_m1 vBmu, vAso, E3, 8
add count, count, #1                            SEP
eor sAmo, tmp,  sAmo_, ROR #12                  SEP
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      xar_m1 vBso, vAma, E0, 23
bic tmp, sAsi_, sAse_, ROR #48                  SEP
eor sAsa, tmp,  sAsa_, ROR #41                  SEP
bic tmp, sAso_, sAsi_, ROR #2                   SEP      xar_m1 vBka, vAbe, E1, 63
eor sAse, tmp,  sAse_, ROR #50                  SEP
bic tmp, sAsu_, sAso_, ROR #25                  SEP
eor sAsi, tmp,  sAsi_, ROR #27                  SEP      xar_m1 vBse, vAgo, E3, 9
bic tmp, sAsa_, sAsu_, ROR #60                  SEP
eor sAso, tmp,  sAso_, ROR #21                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP
eor sAsu, tmp,  sAsu_, ROR #53                  SEP      xar_m1 vBgo, vAme, E1, 19
bic tmp, sAbi_, sAbe_, ROR #63                  SEP
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      bcax_m1 vAge, vBge, vBgo, vBgi
eor sAbe, tmp,  sAbe_, ROR #41                  SEP
bic tmp, sAbu_, sAbo_, ROR #57                  SEP
eor sAbi, tmp,  sAbi_, ROR #35                  SEP
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP      ldr vvtmpq, [sp, #(STACK_BASE_TMP + 16*32)]
eor sAbo, tmp,  sAbo_, ROR #43                  SEP
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      xar_m1 vBke, vvtmp, E2, 58
eor s_Aba, s_Aba, cur_const                     SEP
save count, STACK_OFFSET_COUNT                  SEP
eor sC0, sAka, sAsa, ROR #50                    SEP
eor sC1, sAse, sAge, ROR #60                    SEP      xar_m1 vBgu, vAsi, E2, 3
eor sC2, sAmi, sAgi, ROR #59                    SEP
eor sC3, sAgo, sAso, ROR #30                    SEP
eor sC4, sAbu, sAsu, ROR #53                    SEP      bcax_m1 vAgi, vBgi, vBgu, vBgo
eor sC0, sAma, sC0, ROR #49                     SEP
eor sC1, sAbe, sC1, ROR #44                     SEP
eor sC2, sAki, sC2, ROR #26                     SEP
eor sC3, sAmo, sC3, ROR #63                     SEP      xar_m1 vBsi, vAku, E4, 25
eor sC4, sAmu, sC4, ROR #56                     SEP
eor sC0, sAga, sC0, ROR #57                     SEP
eor sC1, sAme, sC1, ROR #58                     SEP      xar_m1 vBku, vAsa, E0, 46
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP
eor sC4, sAgu, sC4, ROR #48                     SEP      xar_m1 vBma, vAbu, E4, 37
eor sC0, s_Aba, sC0, ROR #61                    SEP
eor sC1, sAke, sC1, ROR #57                     SEP
eor sC2, sAsi, sC2, ROR #52                     SEP
eor sC3, sAbo, sC3, ROR #63                     SEP      xar_m1 vBbu, vAsu, E4, 50
eor sC4, sAku, sC4, ROR #50                     SEP
ror sC1, sC1, 56                                SEP
ror sC4, sC4, 58                                SEP      xar_m1 vBsu, vAse, E1, 62
ror sC2, sC2, 62                                SEP
eor sE1, sC0, sC2, ROR #63                      SEP
eor sE3, sC2, sC4, ROR #63                      SEP
eor sE0, sC4, sC1, ROR #63                      SEP      ldp vvtmpq, E3q, [sp, #(STACK_BASE_TMP + 16*30)]
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP
eor s_Aba_, sE0, s_Aba                          SEP      xar_m1 vBme, vvtmp, E0, 28
eor sAsa_, sE2, sAbi, ROR #50                   SEP
eor sAbi_, sE2, sAki, ROR #46                   SEP
eor sAki_, sE3, sAko, ROR #63                   SEP
eor sAko_, sE4, sAmu, ROR #28                   SEP      xar_m1 vBbe, E3,  E1, 20
eor sAmu_, sE3, sAso, ROR #2                    SEP
eor sAso_, sE0, sAma, ROR #54                   SEP
eor sAka_, sE1, sAbe, ROR #43                   SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
eor sAse_, sE3, sAgo, ROR #36                   SEP
eor sAgo_, sE1, sAme, ROR #49                   SEP
eor sAke_, sE2, sAgi, ROR #3                    SEP
eor sAgi_, sE0, sAka, ROR #39                   SEP      bcax_m1 vAgu, vBgu, vBge, vBga
eor sAga_, sE3, sAbo                            SEP
eor sAbo_, sE3, sAmo, ROR #37                   SEP
eor sAmo_, sE2, sAmi, ROR #8                    SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sAmi_, sE1, sAke, ROR #56                   SEP
eor sAge_, sE4, sAgu, ROR #44                   SEP
eor sAgu_, sE2, sAsi, ROR #62                   SEP      bcax_m1 vAke, vBke, vBko, vBki
eor sAsi_, sE4, sAku, ROR #58                   SEP
eor sAku_, sE0, sAsa, ROR #25                   SEP
eor sAma_, sE4, sAbu, ROR #20                   SEP
eor sAbu_, sE4, sAsu, ROR #9                    SEP      bcax_m1 vAki, vBki, vBku, vBko
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP
eor sAbe_, sE1, sAge, ROR #19                   SEP      bcax_m1 vAko, vBko, vBka, vBku
load_constant_ptr                               SEP
restore count, STACK_OFFSET_COUNT               SEP
bic tmp, sAgi_, sAge_, ROR #47                  SEP
eor sAga, tmp,  sAga_, ROR #39                  SEP      bcax_m1 vAku, vBku, vBke, vBka
bic tmp, sAgo_, sAgi_, ROR #42                  SEP
eor sAge, tmp,  sAge_, ROR #25                  SEP
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      bcax_m1 vAma, vBma, vBmi, vBme
eor sAgi, tmp,  sAgi_, ROR #58                  SEP
bic tmp, sAga_, sAgu_, ROR #31                  SEP
eor sAgo, tmp,  sAgo_, ROR #47                  SEP
bic tmp, sAge_, sAga_, ROR #56                  SEP      bcax_m1 vAme, vBme, vBmo, vBmi
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP
eor sAka, tmp,  sAka_, ROR #24                  SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
bic tmp, sAko_, sAki_, ROR #47                  SEP
eor sAke, tmp,  sAke_, ROR #2                   SEP
bic tmp, sAku_, sAko_, ROR #10                  SEP
eor sAki, tmp,  sAki_, ROR #57                  SEP      bcax_m1 vAmo, vBmo, vBma, vBmu
bic tmp, sAka_, sAku_, ROR #47                  SEP
eor sAko, tmp,  sAko_, ROR #57                  SEP
bic tmp, sAke_, sAka_, ROR #5                   SEP      bcax_m1 vAmu, vBmu, vBme, vBma
eor sAku, tmp,  sAku_, ROR #52                  SEP
bic tmp, sAmi_, sAme_, ROR #38                  SEP
eor sAma, tmp,  sAma_, ROR #47                  SEP      bcax_m1 vAsa, vBsa, vBsi, vBse
bic tmp, sAmo_, sAmi_, ROR #5                   SEP
eor sAme, tmp,  sAme_, ROR #43                  SEP
bic tmp, sAmu_, sAmo_, ROR #41                  SEP
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      bcax_m1 vAse, vBse, vBso, vBsi
bic tmp, sAma_, sAmu_, ROR #35                  SEP
ldr cur_const, [const_addr, count, UXTW #3]     SEP
add count, count, #1                            SEP      bcax_m1 vAsi, vBsi, vBsu, vBso
eor sAmo, tmp,  sAmo_, ROR #12                  SEP
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP
bic tmp, sAsi_, sAse_, ROR #48                  SEP      bcax_m1 vAso, vBso, vBsa, vBsu
eor sAsa, tmp,  sAsa_, ROR #41                  SEP
bic tmp, sAso_, sAsi_, ROR #2                   SEP
eor sAse, tmp,  sAse_, ROR #50                  SEP      bcax_m1 vAsu, vBsu, vBse, vBsa
bic tmp, sAsu_, sAso_, ROR #25                  SEP
eor sAsi, tmp,  sAsi_, ROR #27                  SEP
bic tmp, sAsa_, sAsu_, ROR #60                  SEP
eor sAso, tmp,  sAso_, ROR #21                  SEP      bcax_m1 vAba, vBba, vBbi, vBbe
bic tmp, sAse_, sAsa_, ROR #57                  SEP
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      bcax_m1 vAbe, vBbe, vBbo, vBbi
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
bic tmp, sAbo_, sAbi_, ROR #42                  SEP
eor sAbe, tmp,  sAbe_, ROR #41                  SEP
bic tmp, sAbu_, sAbo_, ROR #57                  SEP      bcax_m1 vAbi, vBbi, vBbu, vBbo
eor sAbi, tmp,  sAbi_, ROR #35                  SEP
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
eor sAbu, tmp,  sAbu_, ROR #30                  SEP
eor s_Aba, s_Aba, cur_const                     SEP      bcax_m1 vAbu, vBbu, vBbe, vBba
ror sAga, sAga,(64-3)                           SEP
ror sAka, sAka,(64-25)                          SEP
ror sAma, sAma,(64-10)                          SEP
ror sAsa, sAsa,(64-39)                          SEP      restore x26, STACK_OFFSET_CONST
ror sAbe, sAbe,(64-21)                          SEP
ror sAge, sAge,(64-45)                          SEP
ror sAke, sAke,(64-8)                           SEP      ldr vvtmpq, [x26], #16
ror sAme, sAme,(64-15)                          SEP
ror sAse, sAse,(64-41)                          SEP
ror sAbi, sAbi,(64-14)                          SEP
ror sAgi, sAgi,(64-61)                          SEP      save x26, STACK_OFFSET_CONST
ror sAki, sAki,(64-18)                          SEP
ror sAmi, sAmi,(64-56)                          SEP
ror sAsi, sAsi,(64-2)                           SEP      eor vAba.16b, vAba.16b, vvtmp.16b
ror sAgo, sAgo,(64-28)                          SEP
ror sAko, sAko,(64-1)                           SEP
ror sAmo, sAmo,(64-27)                          SEP
ror sAso, sAso,(64-62)                          SEP      .unreq vvtmp
ror sAbu, sAbu,(64-44)                          SEP
ror sAgu, sAgu,(64-20)                          SEP
ror sAku, sAku,(64-6)                           SEP      .unreq vvtmpq
ror sAmu, sAmu,(64-36)                          SEP
ror sAsu, sAsu,(64-55)                          SEP
.endm

#define KECCAK_F1600_ROUNDS 24

.global keccak_f1600_x4_hybrid_asm_v5
.global _keccak_f1600_x4_hybrid_asm_v5
.text
.align 4

keccak_f1600_x4_hybrid_asm_v5:
_keccak_f1600_x4_hybrid_asm_v5:
    alloc_stack
    save_gprs
    save_vregs
    save input_addr, STACK_OFFSET_INPUT


     ASM_LOAD(const_addr,round_constants_vec)

     save const_addr, STACK_OFFSET_CONST
    load_input_vector 2,1

     // First scalar Keccak computation alongside first half of SIMD computation
     load_input_scalar 4,0
     hybrid_round_initial
 loop_0:
     hybrid_round_noninitial
     cmp count, #(KECCAK_F1600_ROUNDS-3)
     ble loop_0

     hybrid_round_final

     restore input_addr, STACK_OFFSET_INPUT
     store_input_scalar 4,0

     // Second scalar Keccak computation alongsie second half of SIMD computation
     load_input_scalar 4,1
     hybrid_round_initial
 loop_1:
     hybrid_round_noninitial
     cmp count, #(KECCAK_F1600_ROUNDS-3)
     ble loop_1

     hybrid_round_final

     restore input_addr, STACK_OFFSET_INPUT
     store_input_scalar 4,1
     store_input_vector 2,1

    restore_vregs
    restore_gprs
    free_stack


    ret
