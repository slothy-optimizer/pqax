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
   // .elseif \imm == 62
   //   eor \s0\().16b, \s0\().16b, \s1\().16b
   //   add \d\().2d, \s0\().2d, \s0\().2d
   //   add \d\().2d, \d\().2d,  \d\().2d
   //   sri \d\().2d, \s0\().2d, #(62)
   // .elseif \imm == 61
   //   eor \s0\().16b, \s0\().16b, \s1\().16b
   //   add \d\().2d, \s0\().2d, \s0\().2d
   //   add \d\().2d, \d\().2d,  \d\().2d
   //   add \d\().2d, \d\().2d,  \d\().2d
   //   sri \d\().2d, \s0\().2d, #(61)
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
eor sC0, sAma, sAsa                             SEP
eor sC1, sAme, sAse                             SEP      eor3_m0 C1,vAbe,vAge,vAke
eor sC2, sAmi, sAsi                             SEP      eor3_m1 C3,vAbo,vAgo,vAko
eor sC3, sAmo, sAso                             SEP      eor3_m0 C0,vAba,vAga,vAka
eor sC4, sAmu, sAsu                             SEP      eor3_m1 C2,vAbi,vAgi,vAki
eor sC0, sAka, sC0                              SEP      eor3_m0 C4,vAbu,vAgu,vAku
eor sC1, sAke, sC1                              SEP      eor3_m1 C1, C1,vAme, vAse
eor sC2, sAki, sC2                              SEP      eor3_m0 C3, C3,vAmo, vAso
eor sC3, sAko, sC3                              SEP      eor3_m1 C0, C0,vAma, vAsa
eor sC4, sAku, sC4                              SEP      eor3_m0 C2, C2,vAmi, vAsi
eor sC0, sAga, sC0                              SEP      eor3_m1 C4, C4,vAmu, vAsu
eor sC1, sAge, sC1                              SEP      vvtmp .req vBba
eor sC2, sAgi, sC2                              SEP
eor sC3, sAgo, sC3                              SEP      rax1_m0 E2, C1, C3
eor sC4, sAgu, sC4                              SEP      rax1_m1 E4, C3, C0
eor sC0, s_Aba, sC0                             SEP      rax1_m0 E1, C0, C2
eor sC1, sAbe, sC1                              SEP      rax1_m1 E3, C2, C4
eor sC2, sAbi, sC2                              SEP      rax1_m0 E0, C4, C1
eor sC3, sAbo, sC3                              SEP      .unreq vvtmp
eor sC4, sAbu, sC4                              SEP      vvtmp .req C1
eor sE1, sC0, sC2, ROR #63                      SEP      vvtmpq .req C1q
eor sE3, sC2, sC4, ROR #63                      SEP      eor vBba.16b, vAba.16b, E0.16b
eor sE0, sC4, sC1, ROR #63                      SEP      xar_m1 vBsa, vAbi, E2, 2
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP      xar_m0 vBbi, vAki, E2, 21
eor s_Aba_, s_Aba, sE0                          SEP      xar_m1 vBki, vAko, E3, 39
eor sAsa_, sAbi, sE2                            SEP      xar_m0 vBko, vAmu, E4, 56
eor sAbi_, sAki, sE2                            SEP      xar_m1 vBmu, vAso, E3, 8
eor sAki_, sAko, sE3                            SEP      xar_m0 vBso, vAma, E0, 23
eor sAko_, sAmu, sE4                            SEP      xar_m1 vBka, vAbe, E1, 63
eor sAmu_, sAso, sE3                            SEP      xar_m0 vBse, vAgo, E3, 9
eor sAso_, sAma, sE0                            SEP      xar_m1 vBgo, vAme, E1, 19
eor sAka_, sAbe, sE1                            SEP      xar_m0 vBke, vAgi, E2, 58
eor sAse_, sAgo, sE3                            SEP      xar_m1 vBgi, vAka, E0, 61
eor sAgo_, sAme, sE1                            SEP
eor sAke_, sAgi, sE2                            SEP      xar_m0 vBga, vAbo, E3, 36
eor sAgi_, sAka, sE0                            SEP      xar_m1 vBbo, vAmo, E3, 43
eor sAga_, sAbo, sE3                            SEP      xar_m0 vBmo, vAmi, E2, 49
eor sAbo_, sAmo, sE3                            SEP      xar_m1 vBmi, vAke, E1, 54
eor sAmo_, sAmi, sE2                            SEP      xar_m0 vBge, vAgu, E4, 44
eor sAmi_, sAke, sE1                            SEP      mov E3.16b, vAga.16b
eor sAge_, sAgu, sE4                            SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor sAgu_, sAsi, sE2                            SEP      xar_m0 vBgu, vAsi, E2, 3
eor sAsi_, sAku, sE4                            SEP      xar_m1 vBsi, vAku, E4, 25
eor sAku_, sAsa, sE0                            SEP      xar_m0 vBku, vAsa, E0, 46
eor sAma_, sAbu, sE4                            SEP
eor sAbu_, sAsu, sE4                            SEP      xar_m1 vBma, vAbu, E4, 37
eor sAsu_, sAse, sE1                            SEP      xar_m0 vBbu, vAsu, E4, 50
eor sAme_, sAga, sE0                            SEP      xar_m1 vBsu, vAse, E1, 62
eor sAbe_, sAge, sE1                            SEP      xar_m0 vBme, E3, E0, 28
load_constant_ptr                               SEP      xar_m1 vBbe, vAge, E1, 20
bic tmp, sAgi_, sAge_, ROR #47                  SEP      bcax_m1 vAge, vBge, vBgo, vBgi
eor sAga, tmp,  sAga_, ROR #39                  SEP      bcax_m0 vAgi, vBgi, vBgu, vBgo
bic tmp, sAgo_, sAgi_, ROR #42                  SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
eor sAge, tmp,  sAge_, ROR #25                  SEP      bcax_m0 vAgu, vBgu, vBge, vBga
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sAgi, tmp,  sAgi_, ROR #58                  SEP      bcax_m0 vAke, vBke, vBko, vBki
bic tmp, sAga_, sAgu_, ROR #31                  SEP
eor sAgo, tmp,  sAgo_, ROR #47                  SEP      .unreq vvtmp
bic tmp, sAge_, sAga_, ROR #56                  SEP      .unreq vvtmpq
eor sAgu, tmp,  sAgu_, ROR #23                  SEP      eor2    C0,  vAka, vAga
bic tmp, sAki_, sAke_, ROR #19                  SEP      save(vAga)
eor sAka, tmp,  sAka_, ROR #24                  SEP      vvtmp .req vAga
bic tmp, sAko_, sAki_, ROR #47                  SEP      vvtmpq .req vAgaq
eor sAke, tmp,  sAke_, ROR #2                   SEP      bcax_m0 vAki, vBki, vBku, vBko
bic tmp, sAku_, sAko_, ROR #10                  SEP      bcax_m1 vAko, vBko, vBka, vBku
eor sAki, tmp,  sAki_, ROR #57                  SEP      eor2    C1,  vAke, vAge
bic tmp, sAka_, sAku_, ROR #47                  SEP      bcax_m0 vAku, vBku, vBke, vBka
eor sAko, tmp,  sAko_, ROR #57                  SEP
bic tmp, sAke_, sAka_, ROR #5                   SEP      eor2    C2,  vAki, vAgi
eor sAku, tmp,  sAku_, ROR #52                  SEP      bcax_m1 vAma, vBma, vBmi, vBme
bic tmp, sAmi_, sAme_, ROR #38                  SEP      eor2    C3,  vAko, vAgo
eor sAma, tmp,  sAma_, ROR #47                  SEP      bcax_m0 vAme, vBme, vBmo, vBmi
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      eor2    C4,  vAku, vAgu
eor sAme, tmp,  sAme_, ROR #43                  SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      eor2    C0,  C0,  vAma
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      bcax_m0 vAmo, vBmo, vBma, vBmu
ldr cur_const, [const_addr]                     SEP      eor2    C1,  C1,  vAme
mov count, #1                                   SEP      bcax_m1 vAmu, vBmu, vBme, vBma
bic tmp, sAma_, sAmu_, ROR #35                  SEP
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      eor2    C2,  C2,  vAmi
bic tmp, sAme_, sAma_, ROR #9                   SEP      bcax_m0 vAsa, vBsa, vBsi, vBse
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      eor2    C3,  C3,  vAmo
bic tmp, sAsi_, sAse_, ROR #48                  SEP      bcax_m1 vAse, vBse, vBso, vBsi
eor sAsa, tmp,  sAsa_, ROR #41                  SEP      eor2    C4,  C4,  vAmu
bic tmp, sAso_, sAsi_, ROR #2                   SEP      bcax_m0 vAsi, vBsi, vBsu, vBso
eor sAse, tmp,  sAse_, ROR #50                  SEP      eor2    C0,  C0,  vAsa
bic tmp, sAsu_, sAso_, ROR #25                  SEP      bcax_m1 vAso, vBso, vBsa, vBsu
eor sAsi, tmp,  sAsi_, ROR #27                  SEP      eor2    C1,  C1,  vAse
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      bcax_m0 vAsu, vBsu, vBse, vBsa
eor sAso, tmp,  sAso_, ROR #21                  SEP
save count, STACK_OFFSET_COUNT                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP      eor2    C2,  C2,  vAsi
eor sAsu, tmp,  sAsu_, ROR #53                  SEP      eor2    C3,  C3,  vAso
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      bcax_m1 vAba, vBba, vBbi, vBbe
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP      bcax_m0 vAbe, vBbe, vBbo, vBbi
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      eor2    C1,  C1,  vAbe
eor sAbe, tmp,  sAbe_, ROR #41                  SEP      restore x27, STACK_OFFSET_CONST
bic tmp, sAbu_, sAbo_, ROR #57                  SEP      ldr vvtmpq, [x27], #16
eor sAbi, tmp,  sAbi_, ROR #35                  SEP      save x27, STACK_OFFSET_CONST
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP      eor vAba.16b, vAba.16b, vvtmp.16b
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      eor2    C4,  C4,  vAsu
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      bcax_m0 vAbi, vBbi, vBbu, vBbo
eor s_Aba, s_Aba, cur_const                     SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
                                                SEP      eor2    C3,  C3,  vAbo
eor sC0, sAka, sAsa, ROR #50                    SEP      eor2    C2,  C2,  vAbi
eor sC1, sAse, sAge, ROR #60                    SEP      eor2    C0,  C0,  vAba
eor sC2, sAmi, sAgi, ROR #59                    SEP      bcax_m0 vAbu, vBbu, vBbe, vBba
eor sC3, sAgo, sAso, ROR #30                    SEP      eor2    C4,  C4,  vAbu
eor sC4, sAbu, sAsu, ROR #53                    SEP      restore(vAga)
eor sC0, sAma, sC0, ROR #49                     SEP      .unreq vvtmp
eor sC1, sAbe, sC1, ROR #44                     SEP      .unreq vvtmpq
eor sC2, sAki, sC2, ROR #26                     SEP      vvtmp .req vBba
eor sC3, sAmo, sC3, ROR #63                     SEP
eor sC4, sAmu, sC4, ROR #56                     SEP      rax1_m0 E2, C1, C3
eor sC0, sAga, sC0, ROR #57                     SEP      rax1_m1 E4, C3, C0
eor sC1, sAme, sC1, ROR #58                     SEP      rax1_m0 E1, C0, C2
eor sC2, sAbi, sC2, ROR #60                     SEP      rax1_m1 E3, C2, C4
eor sC3, sAko, sC3, ROR #38                     SEP      rax1_m0 E0, C4, C1
eor sC4, sAgu, sC4, ROR #48                     SEP      .unreq vvtmp
eor sC0, s_Aba, sC0, ROR #61                    SEP      vvtmp .req C1
eor sC1, sAke, sC1, ROR #57                     SEP      vvtmpq .req C1q
eor sC2, sAsi, sC2, ROR #52                     SEP      eor vBba.16b, vAba.16b, E0.16b
eor sC3, sAbo, sC3, ROR #63                     SEP      xar_m1 vBsa, vAbi, E2, 2
eor sC4, sAku, sC4, ROR #50                     SEP
ror sC1, sC1, 56                                SEP      xar_m0 vBbi, vAki, E2, 21
ror sC4, sC4, 58                                SEP      xar_m1 vBki, vAko, E3, 39
ror sC2, sC2, 62                                SEP      xar_m0 vBko, vAmu, E4, 56
eor sE1, sC0, sC2, ROR #63                      SEP      xar_m1 vBmu, vAso, E3, 8
eor sE3, sC2, sC4, ROR #63                      SEP      xar_m0 vBso, vAma, E0, 23
eor sE0, sC4, sC1, ROR #63                      SEP      xar_m1 vBka, vAbe, E1, 63
eor sE2, sC1, sC3, ROR #63                      SEP      xar_m0 vBse, vAgo, E3, 9
eor sE4, sC3, sC0, ROR #63                      SEP      xar_m1 vBgo, vAme, E1, 19
eor s_Aba_, sE0, s_Aba                          SEP      xar_m0 vBke, vAgi, E2, 58
eor sAsa_, sE2, sAbi, ROR #50                   SEP      xar_m1 vBgi, vAka, E0, 61
eor sAbi_, sE2, sAki, ROR #46                   SEP
eor sAki_, sE3, sAko, ROR #63                   SEP      xar_m0 vBga, vAbo, E3, 36
eor sAko_, sE4, sAmu, ROR #28                   SEP      xar_m1 vBbo, vAmo, E3, 43
eor sAmu_, sE3, sAso, ROR #2                    SEP      xar_m0 vBmo, vAmi, E2, 49
eor sAso_, sE0, sAma, ROR #54                   SEP      xar_m1 vBmi, vAke, E1, 54
eor sAka_, sE1, sAbe, ROR #43                   SEP      xar_m0 vBge, vAgu, E4, 44
eor sAse_, sE3, sAgo, ROR #36                   SEP      mov E3.16b, vAga.16b
eor sAgo_, sE1, sAme, ROR #49                   SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor sAke_, sE2, sAgi, ROR #3                    SEP      xar_m0 vBgu, vAsi, E2, 3
eor sAgi_, sE0, sAka, ROR #39                   SEP      xar_m1 vBsi, vAku, E4, 25
eor sAga_, sE3, sAbo                            SEP      xar_m0 vBku, vAsa, E0, 46
eor sAbo_, sE3, sAmo, ROR #37                   SEP
eor sAmo_, sE2, sAmi, ROR #8                    SEP      xar_m1 vBma, vAbu, E4, 37
eor sAmi_, sE1, sAke, ROR #56                   SEP      xar_m0 vBbu, vAsu, E4, 50
eor sAge_, sE4, sAgu, ROR #44                   SEP      xar_m1 vBsu, vAse, E1, 62
eor sAgu_, sE2, sAsi, ROR #62                   SEP      xar_m0 vBme, E3, E0, 28
eor sAsi_, sE4, sAku, ROR #58                   SEP      xar_m1 vBbe, vAge, E1, 20
eor sAku_, sE0, sAsa, ROR #25                   SEP      bcax_m1 vAge, vBge, vBgo, vBgi
eor sAma_, sE4, sAbu, ROR #20                   SEP      bcax_m0 vAgi, vBgi, vBgu, vBgo
eor sAbu_, sE4, sAsu, ROR #9                    SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
eor sAsu_, sE1, sAse, ROR #23                   SEP      bcax_m0 vAgu, vBgu, vBge, vBga
eor sAme_, sE0, sAga, ROR #61                   SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sAbe_, sE1, sAge, ROR #19                   SEP
load_constant_ptr                               SEP      bcax_m0 vAke, vBke, vBko, vBki
restore count, STACK_OFFSET_COUNT               SEP      .unreq vvtmp
bic tmp, sAgi_, sAge_, ROR #47                  SEP      .unreq vvtmpq
eor sAga, tmp,  sAga_, ROR #39                  SEP      eor2    C0,  vAka, vAga
bic tmp, sAgo_, sAgi_, ROR #42                  SEP      save(vAga)
eor sAge, tmp,  sAge_, ROR #25                  SEP      vvtmp .req vAga
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      vvtmpq .req vAgaq
eor sAgi, tmp,  sAgi_, ROR #58                  SEP      bcax_m0 vAki, vBki, vBku, vBko
bic tmp, sAga_, sAgu_, ROR #31                  SEP      bcax_m1 vAko, vBko, vBka, vBku
eor sAgo, tmp,  sAgo_, ROR #47                  SEP      eor2    C1,  vAke, vAge
bic tmp, sAge_, sAga_, ROR #56                  SEP      bcax_m0 vAku, vBku, vBke, vBka
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP      eor2    C2,  vAki, vAgi
eor sAka, tmp,  sAka_, ROR #24                  SEP      bcax_m1 vAma, vBma, vBmi, vBme
bic tmp, sAko_, sAki_, ROR #47                  SEP      eor2    C3,  vAko, vAgo
eor sAke, tmp,  sAke_, ROR #2                   SEP      bcax_m0 vAme, vBme, vBmo, vBmi
bic tmp, sAku_, sAko_, ROR #10                  SEP      eor2    C4,  vAku, vAgu
eor sAki, tmp,  sAki_, ROR #57                  SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
bic tmp, sAka_, sAku_, ROR #47                  SEP      eor2    C0,  C0,  vAma
eor sAko, tmp,  sAko_, ROR #57                  SEP      bcax_m0 vAmo, vBmo, vBma, vBmu
bic tmp, sAke_, sAka_, ROR #5                   SEP      eor2    C1,  C1,  vAme
eor sAku, tmp,  sAku_, ROR #52                  SEP      bcax_m1 vAmu, vBmu, vBme, vBma
bic tmp, sAmi_, sAme_, ROR #38                  SEP
eor sAma, tmp,  sAma_, ROR #47                  SEP      eor2    C2,  C2,  vAmi
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      bcax_m0 vAsa, vBsa, vBsi, vBse
eor sAme, tmp,  sAme_, ROR #43                  SEP      eor2    C3,  C3,  vAmo
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      bcax_m1 vAse, vBse, vBso, vBsi
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      eor2    C4,  C4,  vAmu
bic tmp, sAma_, sAmu_, ROR #35                  SEP      bcax_m0 vAsi, vBsi, vBsu, vBso
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      eor2    C0,  C0,  vAsa
bic tmp, sAme_, sAma_, ROR #9                   SEP      bcax_m1 vAso, vBso, vBsa, vBsu
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      eor2    C1,  C1,  vAse
bic tmp, sAsi_, sAse_, ROR #48                  SEP      bcax_m0 vAsu, vBsu, vBse, vBsa

eor sAsa, tmp,  sAsa_, ROR #41                  SEP      eor2    C2,  C2,  vAsi
bic tmp, sAso_, sAsi_, ROR #2                   SEP      eor2    C3,  C3,  vAso
eor sAse, tmp,  sAse_, ROR #50                  SEP      bcax_m1 vAba, vBba, vBbi, vBbe
bic tmp, sAsu_, sAso_, ROR #25                  SEP      bcax_m0 vAbe, vBbe, vBbo, vBbi
eor sAsi, tmp,  sAsi_, ROR #27                  SEP      eor2    C1,  C1,  vAbe
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      restore x26, STACK_OFFSET_CONST
eor sAso, tmp,  sAso_, ROR #21                  SEP      ldr vvtmpq, [x26], #16
bic tmp, sAse_, sAsa_, ROR #57                  SEP      save x26, STACK_OFFSET_CONST
eor sAsu, tmp,  sAsu_, ROR #53                  SEP      eor vAba.16b, vAba.16b, vvtmp.16b
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      eor2    C4,  C4,  vAsu
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
ldr cur_const, [const_addr, count, UXTW #3]     SEP
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      bcax_m0 vAbi, vBbi, vBbu, vBbo
eor sAbe, tmp,  sAbe_, ROR #41                  SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
bic tmp, sAbu_, sAbo_, ROR #57                  SEP      eor2    C3,  C3,  vAbo
eor sAbi, tmp,  sAbi_, ROR #35                  SEP      eor2    C2,  C2,  vAbi
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP      eor2    C0,  C0,  vAba
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      bcax_m0 vAbu, vBbu, vBbe, vBba
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP      eor2    C4,  C4,  vAbu
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      restore(vAga)
add count, count, #1                            SEP      .unreq vvtmp
eor s_Aba, s_Aba, cur_const                     SEP      .unreq vvtmpq
.endm


.macro  hybrid_round_noninitial
save count, STACK_OFFSET_COUNT                  SEP
eor sC0, sAka, sAsa, ROR #50                    SEP      vvtmp .req vBba
eor sC1, sAse, sAge, ROR #60                    SEP      rax1_m0 E2, C1, C3
eor sC2, sAmi, sAgi, ROR #59                    SEP      rax1_m1 E4, C3, C0
eor sC3, sAgo, sAso, ROR #30                    SEP      rax1_m0 E1, C0, C2
eor sC4, sAbu, sAsu, ROR #53                    SEP      rax1_m1 E3, C2, C4
eor sC0, sAma, sC0, ROR #49                     SEP      rax1_m0 E0, C4, C1
eor sC1, sAbe, sC1, ROR #44                     SEP
eor sC2, sAki, sC2, ROR #26                     SEP      .unreq vvtmp
eor sC3, sAmo, sC3, ROR #63                     SEP      vvtmp .req C1
eor sC4, sAmu, sC4, ROR #56                     SEP      vvtmpq .req C1q
eor sC0, sAga, sC0, ROR #57                     SEP      eor vBba.16b, vAba.16b, E0.16b
eor sC1, sAme, sC1, ROR #58                     SEP      xar_m1 vBsa, vAbi, E2, 2
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP      xar_m0 vBbi, vAki, E2, 21
eor sC4, sAgu, sC4, ROR #48                     SEP      xar_m1 vBki, vAko, E3, 39
eor sC0, s_Aba, sC0, ROR #61                    SEP      xar_m0 vBko, vAmu, E4, 56
eor sC1, sAke, sC1, ROR #57                     SEP      xar_m1 vBmu, vAso, E3, 8
eor sC2, sAsi, sC2, ROR #52                     SEP      xar_m0 vBso, vAma, E0, 23
eor sC3, sAbo, sC3, ROR #63                     SEP      xar_m1 vBka, vAbe, E1, 63
eor sC4, sAku, sC4, ROR #50                     SEP
ror sC1, sC1, 56                                SEP      xar_m0 vBse, vAgo, E3, 9
ror sC4, sC4, 58                                SEP      xar_m1 vBgo, vAme, E1, 19
ror sC2, sC2, 62                                SEP      xar_m0 vBke, vAgi, E2, 58
eor sE1, sC0, sC2, ROR #63                      SEP      xar_m1 vBgi, vAka, E0, 61
eor sE3, sC2, sC4, ROR #63                      SEP      xar_m0 vBga, vAbo, E3, 36
eor sE0, sC4, sC1, ROR #63                      SEP
eor sE2, sC1, sC3, ROR #63                      SEP      xar_m1 vBbo, vAmo, E3, 43
eor sE4, sC3, sC0, ROR #63                      SEP      xar_m0 vBmo, vAmi, E2, 49
eor s_Aba_, sE0, s_Aba                          SEP      xar_m1 vBmi, vAke, E1, 54
eor sAsa_, sE2, sAbi, ROR #50                   SEP      xar_m0 vBge, vAgu, E4, 44
eor sAbi_, sE2, sAki, ROR #46                   SEP      mov E3.16b, vAga.16b
eor sAki_, sE3, sAko, ROR #63                   SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor sAko_, sE4, sAmu, ROR #28                   SEP
eor sAmu_, sE3, sAso, ROR #2                    SEP      xar_m0 vBgu, vAsi, E2, 3
eor sAso_, sE0, sAma, ROR #54                   SEP      xar_m1 vBsi, vAku, E4, 25
eor sAka_, sE1, sAbe, ROR #43                   SEP      xar_m0 vBku, vAsa, E0, 46
eor sAse_, sE3, sAgo, ROR #36                   SEP      xar_m1 vBma, vAbu, E4, 37
eor sAgo_, sE1, sAme, ROR #49                   SEP      xar_m0 vBbu, vAsu, E4, 50
eor sAke_, sE2, sAgi, ROR #3                    SEP
eor sAgi_, sE0, sAka, ROR #39                   SEP      xar_m1 vBsu, vAse, E1, 62
eor sAga_, sE3, sAbo                            SEP      xar_m0 vBme, E3, E0, 28
eor sAbo_, sE3, sAmo, ROR #37                   SEP      xar_m1 vBbe, vAge, E1, 20
eor sAmo_, sE2, sAmi, ROR #8                    SEP      bcax_m1 vAge, vBge, vBgo, vBgi
eor sAmi_, sE1, sAke, ROR #56                   SEP      bcax_m0 vAgi, vBgi, vBgu, vBgo
eor sAge_, sE4, sAgu, ROR #44                   SEP
eor sAgu_, sE2, sAsi, ROR #62                   SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
eor sAsi_, sE4, sAku, ROR #58                   SEP      bcax_m0 vAgu, vBgu, vBge, vBga
eor sAku_, sE0, sAsa, ROR #25                   SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sAma_, sE4, sAbu, ROR #20                   SEP      bcax_m0 vAke, vBke, vBko, vBki
eor sAbu_, sE4, sAsu, ROR #9                    SEP      .unreq vvtmp
eor sAsu_, sE1, sAse, ROR #23                   SEP      .unreq vvtmpq
eor sAme_, sE0, sAga, ROR #61                   SEP
eor sAbe_, sE1, sAge, ROR #19                   SEP      eor2    C0,  vAka, vAga
load_constant_ptr                               SEP      save(vAga)
restore count, STACK_OFFSET_COUNT               SEP      vvtmp .req vAga
bic tmp, sAgi_, sAge_, ROR #47                  SEP      vvtmpq .req vAgaq
eor sAga, tmp,  sAga_, ROR #39                  SEP      bcax_m0 vAki, vBki, vBku, vBko
bic tmp, sAgo_, sAgi_, ROR #42                  SEP
eor sAge, tmp,  sAge_, ROR #25                  SEP      bcax_m1 vAko, vBko, vBka, vBku
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      eor2    C1,  vAke, vAge
eor sAgi, tmp,  sAgi_, ROR #58                  SEP      bcax_m0 vAku, vBku, vBke, vBka
bic tmp, sAga_, sAgu_, ROR #31                  SEP      eor2    C2,  vAki, vAgi
eor sAgo, tmp,  sAgo_, ROR #47                  SEP      bcax_m1 vAma, vBma, vBmi, vBme
bic tmp, sAge_, sAga_, ROR #56                  SEP      eor2    C3,  vAko, vAgo
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP      bcax_m0 vAme, vBme, vBmo, vBmi
eor sAka, tmp,  sAka_, ROR #24                  SEP      eor2    C4,  vAku, vAgu
bic tmp, sAko_, sAki_, ROR #47                  SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
eor sAke, tmp,  sAke_, ROR #2                   SEP      eor2    C0,  C0,  vAma
bic tmp, sAku_, sAko_, ROR #10                  SEP      bcax_m0 vAmo, vBmo, vBma, vBmu
eor sAki, tmp,  sAki_, ROR #57                  SEP
bic tmp, sAka_, sAku_, ROR #47                  SEP      eor2    C1,  C1,  vAme
eor sAko, tmp,  sAko_, ROR #57                  SEP      bcax_m1 vAmu, vBmu, vBme, vBma
bic tmp, sAke_, sAka_, ROR #5                   SEP      eor2    C2,  C2,  vAmi
eor sAku, tmp,  sAku_, ROR #52                  SEP      bcax_m0 vAsa, vBsa, vBsi, vBse
bic tmp, sAmi_, sAme_, ROR #38                  SEP      eor2    C3,  C3,  vAmo
eor sAma, tmp,  sAma_, ROR #47                  SEP
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      bcax_m1 vAse, vBse, vBso, vBsi
eor sAme, tmp,  sAme_, ROR #43                  SEP      eor2    C4,  C4,  vAmu
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      bcax_m0 vAsi, vBsi, vBsu, vBso
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      eor2    C0,  C0,  vAsa
bic tmp, sAma_, sAmu_, ROR #35                  SEP      bcax_m1 vAso, vBso, vBsa, vBsu
ldr cur_const, [const_addr, count, UXTW #3]     SEP      eor2    C1,  C1,  vAse
add count, count, #1                            SEP
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      bcax_m0 vAsu, vBsu, vBse, vBsa
bic tmp, sAme_, sAma_, ROR #9                   SEP      eor2    C2,  C2,  vAsi
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      eor2    C3,  C3,  vAso
bic tmp, sAsi_, sAse_, ROR #48                  SEP      bcax_m1 vAba, vBba, vBbi, vBbe
eor sAsa, tmp,  sAsa_, ROR #41                  SEP      bcax_m0 vAbe, vBbe, vBbo, vBbi
bic tmp, sAso_, sAsi_, ROR #2                   SEP
save count, STACK_OFFSET_COUNT                  SEP
eor sAse, tmp,  sAse_, ROR #50                  SEP      eor2    C1,  C1,  vAbe
bic tmp, sAsu_, sAso_, ROR #25                  SEP      restore x27, STACK_OFFSET_CONST
eor sAsi, tmp,  sAsi_, ROR #27                  SEP      ldr vvtmpq, [x27], #16
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      save x27, STACK_OFFSET_CONST
eor sAso, tmp,  sAso_, ROR #21                  SEP      eor vAba.16b, vAba.16b, vvtmp.16b
bic tmp, sAse_, sAsa_, ROR #57                  SEP      eor2    C4,  C4,  vAsu
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      bcax_m0 vAbi, vBbi, vBbu, vBbo
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      eor2    C3,  C3,  vAbo
eor sAbe, tmp,  sAbe_, ROR #41                  SEP      eor2    C2,  C2,  vAbi
bic tmp, sAbu_, sAbo_, ROR #57                  SEP      eor2    C0,  C0,  vAba
eor sAbi, tmp,  sAbi_, ROR #35                  SEP
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP      bcax_m0 vAbu, vBbu, vBbe, vBba
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      eor2    C4,  C4,  vAbu
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP      restore(vAga)
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      .unreq vvtmp
eor s_Aba, s_Aba, cur_const                     SEP      .unreq vvtmpq
eor sC0, sAka, sAsa, ROR #50                    SEP      vvtmp .req vBba
eor sC1, sAse, sAge, ROR #60                    SEP      rax1_m0 E2, C1, C3
eor sC2, sAmi, sAgi, ROR #59                    SEP      rax1_m1 E4, C3, C0
eor sC3, sAgo, sAso, ROR #30                    SEP      rax1_m0 E1, C0, C2
eor sC4, sAbu, sAsu, ROR #53                    SEP      rax1_m1 E3, C2, C4
eor sC0, sAma, sC0, ROR #49                     SEP      rax1_m0 E0, C4, C1
eor sC1, sAbe, sC1, ROR #44                     SEP
eor sC2, sAki, sC2, ROR #26                     SEP      .unreq vvtmp
eor sC3, sAmo, sC3, ROR #63                     SEP      vvtmp .req C1
eor sC4, sAmu, sC4, ROR #56                     SEP      vvtmpq .req C1q
eor sC0, sAga, sC0, ROR #57                     SEP      eor vBba.16b, vAba.16b, E0.16b
eor sC1, sAme, sC1, ROR #58                     SEP      xar_m1 vBsa, vAbi, E2, 2
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP      xar_m0 vBbi, vAki, E2, 21
eor sC4, sAgu, sC4, ROR #48                     SEP      xar_m1 vBki, vAko, E3, 39
eor sC0, s_Aba, sC0, ROR #61                    SEP      xar_m0 vBko, vAmu, E4, 56
eor sC1, sAke, sC1, ROR #57                     SEP      xar_m1 vBmu, vAso, E3, 8
eor sC2, sAsi, sC2, ROR #52                     SEP      xar_m0 vBso, vAma, E0, 23
eor sC3, sAbo, sC3, ROR #63                     SEP      xar_m1 vBka, vAbe, E1, 63
eor sC4, sAku, sC4, ROR #50                     SEP
ror sC1, sC1, 56                                SEP      xar_m0 vBse, vAgo, E3, 9
ror sC4, sC4, 58                                SEP      xar_m1 vBgo, vAme, E1, 19
ror sC2, sC2, 62                                SEP      xar_m0 vBke, vAgi, E2, 58
eor sE1, sC0, sC2, ROR #63                      SEP      xar_m1 vBgi, vAka, E0, 61
eor sE3, sC2, sC4, ROR #63                      SEP      xar_m0 vBga, vAbo, E3, 36
eor sE0, sC4, sC1, ROR #63                      SEP
eor sE2, sC1, sC3, ROR #63                      SEP      xar_m1 vBbo, vAmo, E3, 43
eor sE4, sC3, sC0, ROR #63                      SEP      xar_m0 vBmo, vAmi, E2, 49
eor s_Aba_, sE0, s_Aba                          SEP      xar_m1 vBmi, vAke, E1, 54
eor sAsa_, sE2, sAbi, ROR #50                   SEP      xar_m0 vBge, vAgu, E4, 44
eor sAbi_, sE2, sAki, ROR #46                   SEP      mov E3.16b, vAga.16b
eor sAki_, sE3, sAko, ROR #63                   SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor sAko_, sE4, sAmu, ROR #28                   SEP
eor sAmu_, sE3, sAso, ROR #2                    SEP      xar_m0 vBgu, vAsi, E2, 3
eor sAso_, sE0, sAma, ROR #54                   SEP      xar_m1 vBsi, vAku, E4, 25
eor sAka_, sE1, sAbe, ROR #43                   SEP      xar_m0 vBku, vAsa, E0, 46
eor sAse_, sE3, sAgo, ROR #36                   SEP      xar_m1 vBma, vAbu, E4, 37
eor sAgo_, sE1, sAme, ROR #49                   SEP      xar_m0 vBbu, vAsu, E4, 50
eor sAke_, sE2, sAgi, ROR #3                    SEP
eor sAgi_, sE0, sAka, ROR #39                   SEP      xar_m1 vBsu, vAse, E1, 62
eor sAga_, sE3, sAbo                            SEP      xar_m0 vBme, E3, E0, 28
eor sAbo_, sE3, sAmo, ROR #37                   SEP      xar_m1 vBbe, vAge, E1, 20
eor sAmo_, sE2, sAmi, ROR #8                    SEP      bcax_m1 vAge, vBge, vBgo, vBgi
eor sAmi_, sE1, sAke, ROR #56                   SEP      bcax_m0 vAgi, vBgi, vBgu, vBgo
eor sAge_, sE4, sAgu, ROR #44                   SEP
eor sAgu_, sE2, sAsi, ROR #62                   SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
eor sAsi_, sE4, sAku, ROR #58                   SEP      bcax_m0 vAgu, vBgu, vBge, vBga
eor sAku_, sE0, sAsa, ROR #25                   SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sAma_, sE4, sAbu, ROR #20                   SEP      bcax_m0 vAke, vBke, vBko, vBki
eor sAbu_, sE4, sAsu, ROR #9                    SEP      .unreq vvtmp
eor sAsu_, sE1, sAse, ROR #23                   SEP      .unreq vvtmpq
eor sAme_, sE0, sAga, ROR #61                   SEP
eor sAbe_, sE1, sAge, ROR #19                   SEP      eor2    C0,  vAka, vAga
load_constant_ptr                               SEP      save(vAga)
restore count, STACK_OFFSET_COUNT               SEP      vvtmp .req vAga
bic tmp, sAgi_, sAge_, ROR #47                  SEP      vvtmpq .req vAgaq
eor sAga, tmp,  sAga_, ROR #39                  SEP      bcax_m0 vAki, vBki, vBku, vBko
bic tmp, sAgo_, sAgi_, ROR #42                  SEP
eor sAge, tmp,  sAge_, ROR #25                  SEP      bcax_m1 vAko, vBko, vBka, vBku
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      eor2    C1,  vAke, vAge
eor sAgi, tmp,  sAgi_, ROR #58                  SEP      bcax_m0 vAku, vBku, vBke, vBka
bic tmp, sAga_, sAgu_, ROR #31                  SEP      eor2    C2,  vAki, vAgi
eor sAgo, tmp,  sAgo_, ROR #47                  SEP      bcax_m1 vAma, vBma, vBmi, vBme
bic tmp, sAge_, sAga_, ROR #56                  SEP      eor2    C3,  vAko, vAgo
eor sAgu, tmp,  sAgu_, ROR #23                  SEP
bic tmp, sAki_, sAke_, ROR #19                  SEP      bcax_m0 vAme, vBme, vBmo, vBmi
eor sAka, tmp,  sAka_, ROR #24                  SEP      eor2    C4,  vAku, vAgu
bic tmp, sAko_, sAki_, ROR #47                  SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
eor sAke, tmp,  sAke_, ROR #2                   SEP      eor2    C0,  C0,  vAma
bic tmp, sAku_, sAko_, ROR #10                  SEP      bcax_m0 vAmo, vBmo, vBma, vBmu
eor sAki, tmp,  sAki_, ROR #57                  SEP
bic tmp, sAka_, sAku_, ROR #47                  SEP      eor2    C1,  C1,  vAme
eor sAko, tmp,  sAko_, ROR #57                  SEP      bcax_m1 vAmu, vBmu, vBme, vBma
bic tmp, sAke_, sAka_, ROR #5                   SEP      eor2    C2,  C2,  vAmi
eor sAku, tmp,  sAku_, ROR #52                  SEP      bcax_m0 vAsa, vBsa, vBsi, vBse
bic tmp, sAmi_, sAme_, ROR #38                  SEP      eor2    C3,  C3,  vAmo
eor sAma, tmp,  sAma_, ROR #47                  SEP
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      bcax_m1 vAse, vBse, vBso, vBsi
eor sAme, tmp,  sAme_, ROR #43                  SEP      eor2    C4,  C4,  vAmu
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      bcax_m0 vAsi, vBsi, vBsu, vBso
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      eor2    C0,  C0,  vAsa
bic tmp, sAma_, sAmu_, ROR #35                  SEP      bcax_m1 vAso, vBso, vBsa, vBsu
                                                SEP      eor2    C1,  C1,  vAse
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      bcax_m0 vAsu, vBsu, vBse, vBsa
bic tmp, sAme_, sAma_, ROR #9                   SEP      eor2    C2,  C2,  vAsi
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      eor2    C3,  C3,  vAso
bic tmp, sAsi_, sAse_, ROR #48                  SEP      bcax_m1 vAba, vBba, vBbi, vBbe
eor sAsa, tmp,  sAsa_, ROR #41                  SEP      bcax_m0 vAbe, vBbe, vBbo, vBbi
bic tmp, sAso_, sAsi_, ROR #2                   SEP
eor sAse, tmp,  sAse_, ROR #50                  SEP      eor2    C1,  C1,  vAbe
bic tmp, sAsu_, sAso_, ROR #25                  SEP      restore x26, STACK_OFFSET_CONST
eor sAsi, tmp,  sAsi_, ROR #27                  SEP      ldr vvtmpq, [x26], #16
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      save x26, STACK_OFFSET_CONST
eor sAso, tmp,  sAso_, ROR #21                  SEP      eor vAba.16b, vAba.16b, vvtmp.16b
bic tmp, sAse_, sAsa_, ROR #57                  SEP      eor2    C4,  C4,  vAsu
eor sAsu, tmp,  sAsu_, ROR #53                  SEP
ldr cur_const, [const_addr, count, UXTW #3]     SEP
add count, count, #1                            SEP
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      bcax_m0 vAbi, vBbi, vBbu, vBbo
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      eor2    C3,  C3,  vAbo
eor sAbe, tmp,  sAbe_, ROR #41                  SEP      eor2    C2,  C2,  vAbi
bic tmp, sAbu_, sAbo_, ROR #57                  SEP      eor2    C0,  C0,  vAba
eor sAbi, tmp,  sAbi_, ROR #35                  SEP
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP      bcax_m0 vAbu, vBbu, vBbe, vBba
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      eor2    C4,  C4,  vAbu
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP      restore(vAga)
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      .unreq vvtmp
eor s_Aba, s_Aba, cur_const                     SEP      .unreq vvtmpq
.endm


.macro  hybrid_round_final
save count, STACK_OFFSET_COUNT                  SEP
eor sC0, sAka, sAsa, ROR #50                    SEP      vvtmp .req vBba
eor sC1, sAse, sAge, ROR #60                    SEP      rax1_m0 E2, C1, C3
eor sC2, sAmi, sAgi, ROR #59                    SEP
eor sC3, sAgo, sAso, ROR #30                    SEP      rax1_m1 E4, C3, C0
eor sC4, sAbu, sAsu, ROR #53                    SEP      rax1_m0 E1, C0, C2
eor sC0, sAma, sC0, ROR #49                     SEP
eor sC1, sAbe, sC1, ROR #44                     SEP      rax1_m1 E3, C2, C4
eor sC2, sAki, sC2, ROR #26                     SEP      rax1_m0 E0, C4, C1
eor sC3, sAmo, sC3, ROR #63                     SEP
eor sC4, sAmu, sC4, ROR #56                     SEP      .unreq vvtmp
eor sC0, sAga, sC0, ROR #57                     SEP      vvtmp .req C1
eor sC1, sAme, sC1, ROR #58                     SEP
eor sC2, sAbi, sC2, ROR #60                     SEP      vvtmpq .req C1q
eor sC3, sAko, sC3, ROR #38                     SEP      eor vBba.16b, vAba.16b, E0.16b
eor sC4, sAgu, sC4, ROR #48                     SEP
eor sC0, s_Aba, sC0, ROR #61                    SEP      xar_m1 vBsa, vAbi, E2, 2
eor sC1, sAke, sC1, ROR #57                     SEP      xar_m0 vBbi, vAki, E2, 21
eor sC2, sAsi, sC2, ROR #52                     SEP
eor sC3, sAbo, sC3, ROR #63                     SEP      xar_m1 vBki, vAko, E3, 39
eor sC4, sAku, sC4, ROR #50                     SEP      xar_m0 vBko, vAmu, E4, 56
ror sC1, sC1, 56                                SEP
ror sC4, sC4, 58                                SEP      xar_m1 vBmu, vAso, E3, 8
ror sC2, sC2, 62                                SEP      xar_m0 vBso, vAma, E0, 23
eor sE1, sC0, sC2, ROR #63                      SEP
eor sE3, sC2, sC4, ROR #63                      SEP      xar_m1 vBka, vAbe, E1, 63
eor sE0, sC4, sC1, ROR #63                      SEP      xar_m0 vBse, vAgo, E3, 9
eor sE2, sC1, sC3, ROR #63                      SEP
eor sE4, sC3, sC0, ROR #63                      SEP      xar_m1 vBgo, vAme, E1, 19
eor s_Aba_, sE0, s_Aba                          SEP      xar_m0 vBke, vAgi, E2, 58
eor sAsa_, sE2, sAbi, ROR #50                   SEP
eor sAbi_, sE2, sAki, ROR #46                   SEP      xar_m1 vBgi, vAka, E0, 61
eor sAki_, sE3, sAko, ROR #63                   SEP
eor sAko_, sE4, sAmu, ROR #28                   SEP      xar_m0 vBga, vAbo, E3, 36
eor sAmu_, sE3, sAso, ROR #2                    SEP      xar_m1 vBbo, vAmo, E3, 43
eor sAso_, sE0, sAma, ROR #54                   SEP
eor sAka_, sE1, sAbe, ROR #43                   SEP      xar_m0 vBmo, vAmi, E2, 49
eor sAse_, sE3, sAgo, ROR #36                   SEP      xar_m1 vBmi, vAke, E1, 54
eor sAgo_, sE1, sAme, ROR #49                   SEP
eor sAke_, sE2, sAgi, ROR #3                    SEP      xar_m0 vBge, vAgu, E4, 44
eor sAgi_, sE0, sAka, ROR #39                   SEP      mov E3.16b, vAga.16b
eor sAga_, sE3, sAbo                            SEP
eor sAbo_, sE3, sAmo, ROR #37                   SEP      bcax_m1 vAga, vBga, vBgi, vBge
eor sAmo_, sE2, sAmi, ROR #8                    SEP      xar_m0 vBgu, vAsi, E2, 3
eor sAmi_, sE1, sAke, ROR #56                   SEP
eor sAge_, sE4, sAgu, ROR #44                   SEP      xar_m1 vBsi, vAku, E4, 25
eor sAgu_, sE2, sAsi, ROR #62                   SEP      xar_m0 vBku, vAsa, E0, 46
eor sAsi_, sE4, sAku, ROR #58                   SEP
eor sAku_, sE0, sAsa, ROR #25                   SEP      xar_m1 vBma, vAbu, E4, 37
eor sAma_, sE4, sAbu, ROR #20                   SEP      xar_m0 vBbu, vAsu, E4, 50
eor sAbu_, sE4, sAsu, ROR #9                    SEP
eor sAsu_, sE1, sAse, ROR #23                   SEP      xar_m1 vBsu, vAse, E1, 62
eor sAme_, sE0, sAga, ROR #61                   SEP      xar_m0 vBme, E3, E0, 28
eor sAbe_, sE1, sAge, ROR #19                   SEP
load_constant_ptr                               SEP      xar_m1 vBbe, vAge, E1, 20
restore count, STACK_OFFSET_COUNT               SEP      bcax_m1 vAge, vBge, vBgo, vBgi
bic tmp, sAgi_, sAge_, ROR #47                  SEP
eor sAga, tmp,  sAga_, ROR #39                  SEP      bcax_m0 vAgi, vBgi, vBgu, vBgo
bic tmp, sAgo_, sAgi_, ROR #42                  SEP      bcax_m1 vAgo, vBgo, vBga, vBgu
eor sAge, tmp,  sAge_, ROR #25                  SEP
bic tmp, sAgu_, sAgo_, ROR #16                  SEP      bcax_m0 vAgu, vBgu, vBge, vBga
eor sAgi, tmp,  sAgi_, ROR #58                  SEP
bic tmp, sAga_, sAgu_, ROR #31                  SEP      bcax_m1 vAka, vBka, vBki, vBke
eor sAgo, tmp,  sAgo_, ROR #47                  SEP      bcax_m0 vAke, vBke, vBko, vBki
bic tmp, sAge_, sAga_, ROR #56                  SEP
eor sAgu, tmp,  sAgu_, ROR #23                  SEP      .unreq vvtmp
bic tmp, sAki_, sAke_, ROR #19                  SEP      .unreq vvtmpq
eor sAka, tmp,  sAka_, ROR #24                  SEP
bic tmp, sAko_, sAki_, ROR #47                  SEP      eor2    C0,  vAka, vAga
eor sAke, tmp,  sAke_, ROR #2                   SEP      save(vAga)
bic tmp, sAku_, sAko_, ROR #10                  SEP
eor sAki, tmp,  sAki_, ROR #57                  SEP      vvtmp .req vAga
bic tmp, sAka_, sAku_, ROR #47                  SEP      vvtmpq .req vAgaq
eor sAko, tmp,  sAko_, ROR #57                  SEP
bic tmp, sAke_, sAka_, ROR #5                   SEP      bcax_m0 vAki, vBki, vBku, vBko
eor sAku, tmp,  sAku_, ROR #52                  SEP      bcax_m1 vAko, vBko, vBka, vBku
bic tmp, sAmi_, sAme_, ROR #38                  SEP
eor sAma, tmp,  sAma_, ROR #47                  SEP      eor2    C1,  vAke, vAge
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      bcax_m0 vAku, vBku, vBke, vBka
eor sAme, tmp,  sAme_, ROR #43                  SEP
bic tmp, sAmu_, sAmo_, ROR #41                  SEP      eor2    C2,  vAki, vAgi
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      bcax_m1 vAma, vBma, vBmi, vBme
bic tmp, sAma_, sAmu_, ROR #35                  SEP
ldr cur_const, [const_addr, count, UXTW #3]     SEP      eor2    C3,  vAko, vAgo
add count, count, #1                            SEP      bcax_m0 vAme, vBme, vBmo, vBmi
eor sAmo, tmp,  sAmo_, ROR #12                  SEP
bic tmp, sAme_, sAma_, ROR #9                   SEP      eor2    C4,  vAku, vAgu
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
bic tmp, sAsi_, sAse_, ROR #48                  SEP
eor sAsa, tmp,  sAsa_, ROR #41                  SEP      eor2    C0,  C0,  vAma
bic tmp, sAso_, sAsi_, ROR #2                   SEP      bcax_m0 vAmo, vBmo, vBma, vBmu
eor sAse, tmp,  sAse_, ROR #50                  SEP
bic tmp, sAsu_, sAso_, ROR #25                  SEP      eor2    C1,  C1,  vAme
eor sAsi, tmp,  sAsi_, ROR #27                  SEP
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      bcax_m1 vAmu, vBmu, vBme, vBma
eor sAso, tmp,  sAso_, ROR #21                  SEP      eor2    C2,  C2,  vAmi
bic tmp, sAse_, sAsa_, ROR #57                  SEP
eor sAsu, tmp,  sAsu_, ROR #53                  SEP      bcax_m0 vAsa, vBsa, vBsi, vBse
bic tmp, sAbi_, sAbe_, ROR #63                  SEP      eor2    C3,  C3,  vAmo
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      bcax_m1 vAse, vBse, vBso, vBsi
eor sAbe, tmp,  sAbe_, ROR #41                  SEP      eor2    C4,  C4,  vAmu
bic tmp, sAbu_, sAbo_, ROR #57                  SEP
eor sAbi, tmp,  sAbi_, ROR #35                  SEP      bcax_m0 vAsi, vBsi, vBsu, vBso
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP      eor2    C0,  C0,  vAsa
eor sAbo, tmp,  sAbo_, ROR #43                  SEP
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP      bcax_m1 vAso, vBso, vBsa, vBsu
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      eor2    C1,  C1,  vAse
eor s_Aba, s_Aba, cur_const                     SEP
save count, STACK_OFFSET_COUNT                  SEP      bcax_m0 vAsu, vBsu, vBse, vBsa
eor sC0, sAka, sAsa, ROR #50                    SEP      eor2    C2,  C2,  vAsi
eor sC1, sAse, sAge, ROR #60                    SEP
eor sC2, sAmi, sAgi, ROR #59                    SEP      eor2    C3,  C3,  vAso
eor sC3, sAgo, sAso, ROR #30                    SEP      bcax_m1 vAba, vBba, vBbi, vBbe
eor sC4, sAbu, sAsu, ROR #53                    SEP
eor sC0, sAma, sC0, ROR #49                     SEP      bcax_m0 vAbe, vBbe, vBbo, vBbi
eor sC1, sAbe, sC1, ROR #44                     SEP      eor2    C1,  C1,  vAbe
eor sC2, sAki, sC2, ROR #26                     SEP
eor sC3, sAmo, sC3, ROR #63                     SEP      restore x30, STACK_OFFSET_CONST
eor sC4, sAmu, sC4, ROR #56                     SEP      ldr vvtmpq, [x30], #16
eor sC0, sAga, sC0, ROR #57                     SEP
eor sC1, sAme, sC1, ROR #58                     SEP      save x30, STACK_OFFSET_CONST
eor sC2, sAbi, sC2, ROR #60                     SEP
eor sC3, sAko, sC3, ROR #38                     SEP      eor vAba.16b, vAba.16b, vvtmp.16b
eor sC4, sAgu, sC4, ROR #48                     SEP      eor2    C4,  C4,  vAsu
eor sC0, s_Aba, sC0, ROR #61                    SEP
eor sC1, sAke, sC1, ROR #57                     SEP      bcax_m0 vAbi, vBbi, vBbu, vBbo
eor sC2, sAsi, sC2, ROR #52                     SEP      bcax_m1 vAbo, vBbo, vBba, vBbu
eor sC3, sAbo, sC3, ROR #63                     SEP
eor sC4, sAku, sC4, ROR #50                     SEP      eor2    C3,  C3,  vAbo
ror sC1, sC1, 56                                SEP      eor2    C2,  C2,  vAbi
ror sC4, sC4, 58                                SEP
ror sC2, sC2, 62                                SEP      eor2    C0,  C0,  vAba
eor sE1, sC0, sC2, ROR #63                      SEP      bcax_m0 vAbu, vBbu, vBbe, vBba
eor sE3, sC2, sC4, ROR #63                      SEP
eor sE0, sC4, sC1, ROR #63                      SEP      eor2    C4,  C4,  vAbu
eor sE2, sC1, sC3, ROR #63                      SEP      restore(vAga)
eor sE4, sC3, sC0, ROR #63                      SEP
eor s_Aba_, sE0, s_Aba                          SEP      .unreq vvtmp
eor sAsa_, sE2, sAbi, ROR #50                   SEP      .unreq vvtmpq
eor sAbi_, sE2, sAki, ROR #46                   SEP
eor sAki_, sE3, sAko, ROR #63                   SEP      vvtmp .req vBba
eor sAko_, sE4, sAmu, ROR #28                   SEP      rax1_m0 E2, C1, C3
eor sAmu_, sE3, sAso, ROR #2                    SEP
eor sAso_, sE0, sAma, ROR #54                   SEP      rax1_m1 E4, C3, C0
eor sAka_, sE1, sAbe, ROR #43                   SEP      rax1_m0 E1, C0, C2
eor sAse_, sE3, sAgo, ROR #36                   SEP
eor sAgo_, sE1, sAme, ROR #49                   SEP      rax1_m1 E3, C2, C4
eor sAke_, sE2, sAgi, ROR #3                    SEP      rax1_m0 E0, C4, C1
eor sAgi_, sE0, sAka, ROR #39                   SEP
eor sAga_, sE3, sAbo                            SEP      .unreq vvtmp
eor sAbo_, sE3, sAmo, ROR #37                   SEP
eor sAmo_, sE2, sAmi, ROR #8                    SEP      vvtmp .req C1
eor sAmi_, sE1, sAke, ROR #56                   SEP      vvtmpq .req C1q
eor sAge_, sE4, sAgu, ROR #44                   SEP
eor sAgu_, sE2, sAsi, ROR #62                   SEP      eor vBba.16b, vAba.16b, E0.16b
eor sAsi_, sE4, sAku, ROR #58                   SEP      xar_m0 vBsa, vAbi, E2, 2
eor sAku_, sE0, sAsa, ROR #25                   SEP
eor sAma_, sE4, sAbu, ROR #20                   SEP      xar_m1 vBbi, vAki, E2, 21
eor sAbu_, sE4, sAsu, ROR #9                    SEP      xar_m0 vBki, vAko, E3, 39
eor sAsu_, sE1, sAse, ROR #23                   SEP
eor sAme_, sE0, sAga, ROR #61                   SEP      xar_m1 vBko, vAmu, E4, 56
eor sAbe_, sE1, sAge, ROR #19                   SEP      xar_m0 vBmu, vAso, E3, 8
load_constant_ptr                               SEP
restore count, STACK_OFFSET_COUNT               SEP      xar_m1 vBso, vAma, E0, 23
bic tmp, sAgi_, sAge_, ROR #47                  SEP      xar_m0 vBka, vAbe, E1, 63
eor sAga, tmp,  sAga_, ROR #39                  SEP
bic tmp, sAgo_, sAgi_, ROR #42                  SEP      xar_m1 vBse, vAgo, E3, 9
eor sAge, tmp,  sAge_, ROR #25                  SEP      xar_m0 vBgo, vAme, E1, 19
bic tmp, sAgu_, sAgo_, ROR #16                  SEP
eor sAgi, tmp,  sAgi_, ROR #58                  SEP      xar_m1 vBke, vAgi, E2, 58
bic tmp, sAga_, sAgu_, ROR #31                  SEP      xar_m0 vBgi, vAka, E0, 61
eor sAgo, tmp,  sAgo_, ROR #47                  SEP
bic tmp, sAge_, sAga_, ROR #56                  SEP      xar_m1 vBga, vAbo, E3, 36
eor sAgu, tmp,  sAgu_, ROR #23                  SEP      xar_m0 vBbo, vAmo, E3, 43
bic tmp, sAki_, sAke_, ROR #19                  SEP
eor sAka, tmp,  sAka_, ROR #24                  SEP      xar_m1 vBmo, vAmi, E2, 49
bic tmp, sAko_, sAki_, ROR #47                  SEP      xar_m0 vBmi, vAke, E1, 54
eor sAke, tmp,  sAke_, ROR #2                   SEP
bic tmp, sAku_, sAko_, ROR #10                  SEP      xar_m1 vBge, vAgu, E4, 44
eor sAki, tmp,  sAki_, ROR #57                  SEP      mov E3.16b, vAga.16b
bic tmp, sAka_, sAku_, ROR #47                  SEP
eor sAko, tmp,  sAko_, ROR #57                  SEP      bcax_m1 vAga, vBga, vBgi, vBge
bic tmp, sAke_, sAka_, ROR #5                   SEP
eor sAku, tmp,  sAku_, ROR #52                  SEP      xar_m0 vBgu, vAsi, E2, 3
bic tmp, sAmi_, sAme_, ROR #38                  SEP      xar_m1 vBsi, vAku, E4, 25
eor sAma, tmp,  sAma_, ROR #47                  SEP
bic tmp, sAmo_, sAmi_, ROR #5                   SEP      xar_m0 vBku, vAsa, E0, 46
eor sAme, tmp,  sAme_, ROR #43                  SEP      xar_m1 vBma, vAbu, E4, 37
bic tmp, sAmu_, sAmo_, ROR #41                  SEP
eor sAmi, tmp,  sAmi_, ROR #46                  SEP      xar_m0 vBbu, vAsu, E4, 50
bic tmp, sAma_, sAmu_, ROR #35                  SEP      xar_m1 vBsu, vAse, E1, 62
ldr cur_const, [const_addr, count, UXTW #3]     SEP
add count, count, #1                            SEP      xar_m0 vBme, E3, E0, 28
eor sAmo, tmp,  sAmo_, ROR #12                  SEP      xar_m1 vBbe, vAge, E1, 20
bic tmp, sAme_, sAma_, ROR #9                   SEP
eor sAmu, tmp,  sAmu_, ROR #44                  SEP      bcax_m0 vAge, vBge, vBgo, vBgi
bic tmp, sAsi_, sAse_, ROR #48                  SEP      bcax_m1 vAgi, vBgi, vBgu, vBgo
eor sAsa, tmp,  sAsa_, ROR #41                  SEP
bic tmp, sAso_, sAsi_, ROR #2                   SEP      bcax_m0 vAgo, vBgo, vBga, vBgu
eor sAse, tmp,  sAse_, ROR #50                  SEP      bcax_m1 vAgu, vBgu, vBge, vBga
bic tmp, sAsu_, sAso_, ROR #25                  SEP
eor sAsi, tmp,  sAsi_, ROR #27                  SEP      bcax_m0 vAka, vBka, vBki, vBke
bic tmp, sAsa_, sAsu_, ROR #60                  SEP      bcax_m1 vAke, vBke, vBko, vBki
eor sAso, tmp,  sAso_, ROR #21                  SEP
bic tmp, sAse_, sAsa_, ROR #57                  SEP      bcax_m0 vAki, vBki, vBku, vBko
eor sAsu, tmp,  sAsu_, ROR #53                  SEP      bcax_m1 vAko, vBko, vBka, vBku
bic tmp, sAbi_, sAbe_, ROR #63                  SEP
eor s_Aba, s_Aba_, tmp,  ROR #21                SEP      bcax_m0 vAku, vBku, vBke, vBka
bic tmp, sAbo_, sAbi_, ROR #42                  SEP      bcax_m1 vAma, vBma, vBmi, vBme
eor sAbe, tmp,  sAbe_, ROR #41                  SEP
bic tmp, sAbu_, sAbo_, ROR #57                  SEP      bcax_m0 vAme, vBme, vBmo, vBmi
eor sAbi, tmp,  sAbi_, ROR #35                  SEP
bic tmp, s_Aba_, sAbu_, ROR #50                 SEP      bcax_m1 vAmi, vBmi, vBmu, vBmo
eor sAbo, tmp,  sAbo_, ROR #43                  SEP      bcax_m0 vAmo, vBmo, vBma, vBmu
bic tmp, sAbe_, s_Aba_, ROR #44                 SEP
eor sAbu, tmp,  sAbu_, ROR #30                  SEP      bcax_m1 vAmu, vBmu, vBme, vBma
eor s_Aba, s_Aba, cur_const                     SEP      bcax_m0 vAsa, vBsa, vBsi, vBse
ror sAga, sAga,(64-3)                           SEP
ror sAka, sAka,(64-25)                          SEP      bcax_m1 vAse, vBse, vBso, vBsi
ror sAma, sAma,(64-10)                          SEP      bcax_m0 vAsi, vBsi, vBsu, vBso
ror sAsa, sAsa,(64-39)                          SEP
ror sAbe, sAbe,(64-21)                          SEP      bcax_m1 vAso, vBso, vBsa, vBsu
ror sAge, sAge,(64-45)                          SEP      bcax_m0 vAsu, vBsu, vBse, vBsa
ror sAke, sAke,(64-8)                           SEP
ror sAme, sAme,(64-15)                          SEP      bcax_m1 vAba, vBba, vBbi, vBbe
ror sAse, sAse,(64-41)                          SEP      bcax_m0 vAbe, vBbe, vBbo, vBbi
ror sAbi, sAbi,(64-14)                          SEP
ror sAgi, sAgi,(64-61)                          SEP      bcax_m1 vAbi, vBbi, vBbu, vBbo
ror sAki, sAki,(64-18)                          SEP      bcax_m0 vAbo, vBbo, vBba, vBbu
ror sAmi, sAmi,(64-56)                          SEP
ror sAsi, sAsi,(64-2)                           SEP      bcax_m1 vAbu, vBbu, vBbe, vBba
ror sAgo, sAgo,(64-28)                          SEP
ror sAko, sAko,(64-1)                           SEP
ror sAmo, sAmo,(64-27)                          SEP      restore x26, STACK_OFFSET_CONST
ror sAso, sAso,(64-62)                          SEP      ldr vvtmpq, [x26], #16
ror sAbu, sAbu,(64-44)                          SEP
ror sAgu, sAgu,(64-20)                          SEP      save x26, STACK_OFFSET_CONST
ror sAku, sAku,(64-6)                           SEP      eor vAba.16b, vAba.16b, vvtmp.16b
ror sAmu, sAmu,(64-36)                          SEP      .unreq vvtmp
ror sAsu, sAsu,(64-55)                          SEP      .unreq vvtmpq
.endm



#define KECCAK_F1600_ROUNDS 24

.global keccak_f1600_x3_hybrid_asm_v6
.global _keccak_f1600_x3_hybrid_asm_v6
.text
.align 4

keccak_f1600_x3_hybrid_asm_v6:
_keccak_f1600_x3_hybrid_asm_v6:
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
     cmp count, #(KECCAK_F1600_ROUNDS-3)
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