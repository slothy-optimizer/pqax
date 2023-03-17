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
_round_constants:
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
round_constants:
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
    const_addr     .req x1
    count          .req x2
    cur_const      .req x3

    /* Mapping of Kecck-f1600 state to vector registers
     * at the beginning and end of each round. */
    Aba     .req v0
    Abe     .req v1
    Abi     .req v2
    Abo     .req v3
    Abu     .req v4
    Aga     .req v5
    Age     .req v6
    Agi     .req v7
    Ago     .req v8
    Agu     .req v9
    Aka     .req v10
    Ake     .req v11
    Aki     .req v12
    Ako     .req v13
    Aku     .req v14
    Ama     .req v15
    Ame     .req v16
    Ami     .req v17
    Amo     .req v18
    Amu     .req v19
    Asa     .req v20
    Ase     .req v21
    Asi     .req v22
    Aso     .req v23
    Asu     .req v24

    /* q-form of the above mapping */
    Abaq    .req q0
    Abeq    .req q1
    Abiq    .req q2
    Aboq    .req q3
    Abuq    .req q4
    Agaq    .req q5
    Ageq    .req q6
    Agiq    .req q7
    Agoq    .req q8
    Aguq    .req q9
    Akaq    .req q10
    Akeq    .req q11
    Akiq    .req q12
    Akoq    .req q13
    Akuq    .req q14
    Amaq    .req q15
    Ameq    .req q16
    Amiq    .req q17
    Amoq    .req q18
    Amuq    .req q19
    Asaq    .req q20
    Aseq    .req q21
    Asiq    .req q22
    Asoq    .req q23
    Asuq    .req q24

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
    vBbi .req Abi
    vBbo .req Abo
    vBbu .req Abu
    vBga .req Aka
    vBge .req Ake
    vBgi .req Agi
    vBgo .req Ago
    vBgu .req Agu
    vBka .req Ama
    vBke .req Ame
    vBki .req Aki
    vBko .req Ako
    vBku .req Aku
    vBma .req Asa
    vBme .req Ase
    vBmi .req Ami
    vBmo .req Amo
    vBmu .req Amu
    vBsa .req Aba
    vBse .req Abe
    vBsi .req Asi
    vBso .req Aso
    vBsu .req Asu

    vBbaq .req q25 // fresh
    vBbeq .req q26 // fresh
    vBbiq .req Abiq
    vBboq .req Aboq
    vBbuq .req Abuq
    vBgaq .req Akaq
    vBgeq .req Akeq
    vBgiq .req Agiq
    vBgoq .req Agoq
    vBguq .req Aguq
    vBkaq .req Amaq
    vBkeq .req Ameq
    vBkiq .req Akiq
    vBkoq .req Akoq
    vBkuq .req Akuq
    vBmaq .req Asaq
    vBmeq .req Aseq
    vBmiq .req Amiq
    vBmoq .req Amoq
    vBmuq .req Amuq
    vBsaq .req Abaq
    vBseq .req Abeq
    vBsiq .req Asiq
    vBsoq .req Asoq
    vBsuq .req Asuq

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


/************************ MACROS ****************************/

.macro load_input
    ldp Abaq, Abeq, [input_addr, #(2*8*0)]
    ldp Abiq, Aboq, [input_addr, #(2*8*2)]
    ldp Abuq, Agaq, [input_addr, #(2*8*4)]
    ldp Ageq, Agiq, [input_addr, #(2*8*6)]
    ldp Agoq, Aguq, [input_addr, #(2*8*8)]
    ldp Akaq, Akeq, [input_addr, #(2*8*10)]
    ldp Akiq, Akoq, [input_addr, #(2*8*12)]
    ldp Akuq, Amaq, [input_addr, #(2*8*14)]
    ldp Ameq, Amiq, [input_addr, #(2*8*16)]
    ldp Amoq, Amuq, [input_addr, #(2*8*18)]
    ldp Asaq, Aseq, [input_addr, #(2*8*20)]
    ldp Asiq, Asoq, [input_addr, #(2*8*22)]
    ldr Asuq, [input_addr, #(2*8*24)]
.endm

.macro store_input
    str Abaq, [input_addr, #(2*8*0)]
    str Abeq, [input_addr, #(2*8*1)]
    str Abiq, [input_addr, #(2*8*2)]
    str Aboq, [input_addr, #(2*8*3)]
    str Abuq, [input_addr, #(2*8*4)]
    str Agaq, [input_addr, #(2*8*5)]
    str Ageq, [input_addr, #(2*8*6)]
    str Agiq, [input_addr, #(2*8*7)]
    str Agoq, [input_addr, #(2*8*8)]
    str Aguq, [input_addr, #(2*8*9)]
    str Akaq, [input_addr, #(2*8*10)]
    str Akeq, [input_addr, #(2*8*11)]
    str Akiq, [input_addr, #(2*8*12)]
    str Akoq, [input_addr, #(2*8*13)]
    str Akuq, [input_addr, #(2*8*14)]
    str Amaq, [input_addr, #(2*8*15)]
    str Ameq, [input_addr, #(2*8*16)]
    str Amiq, [input_addr, #(2*8*17)]
    str Amoq, [input_addr, #(2*8*18)]
    str Amuq, [input_addr, #(2*8*19)]
    str Asaq, [input_addr, #(2*8*20)]
    str Aseq, [input_addr, #(2*8*21)]
    str Asiq, [input_addr, #(2*8*22)]
    str Asoq, [input_addr, #(2*8*23)]
    str Asuq, [input_addr, #(2*8*24)]
.endm

#define STACK_SIZE (16*4 + 16*34)
#define STACK_BASE_VREGS 0
#define STACK_BASE_TMP   16*4

#define Aga_offset 0
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

.macro alloc_stack
   sub sp, sp, #(STACK_SIZE)
.endm

.macro free_stack
    add sp, sp, #(STACK_SIZE)
.endm

#define save(name) \
    str name ## q, [sp, #(STACK_BASE_TMP + 16 * name ## _offset)]
#define restore(name) \
    ldr name ## q, [sp, #(STACK_BASE_TMP + 16 * name ## _offset)]

.macro save_vregs
    stp  d8,  d9, [sp, #(STACK_BASE_VREGS + 16*0)]
    stp d10, d11, [sp, #(STACK_BASE_VREGS + 16*1)]
    stp d12, d13, [sp, #(STACK_BASE_VREGS + 16*2)]
    stp d14, d15, [sp, #(STACK_BASE_VREGS + 16*3)]
.endm

.macro restore_vregs
    ldp  d8,  d9, [sp, #(STACK_BASE_VREGS + 16*0)]
    ldp d10, d11, [sp, #(STACK_BASE_VREGS + 16*1)]
    ldp d12, d13, [sp, #(STACK_BASE_VREGS + 16*2)]
    ldp d14, d15, [sp, #(STACK_BASE_VREGS + 16*3)]
.endm

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
   add tmp.2d, \s1\().2d, \s1\().2d
   sri tmp.2d, \s1\().2d, #63
   eor \d\().16b, tmp.16b, \s0\().16b
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
    bic tmp.16b, \s1\().16b, \s2\().16b
    eor \d\().16b, tmp.16b, \s0\().16b
.endm

/* Keccak-f1600 round */

.macro keccak_f1600_round_pre

    /* 10 EOR3, so 20 individual EOR */

    eor3_m1_0 C1, Abe, Age, Ake
    eor3_m1_0 C3, Abo, Ago, Ako
    eor3_m1_0 C0, Aba, Aga, Aka
    eor3_m1_0 C2, Abi, Agi, Aki
    eor3_m1_0 C4, Abu, Agu, Aku
    eor3_m1_1 C1, Abe, Age, Ake
    eor3_m1_1 C3, Abo, Ago, Ako
    eor3_m1_1 C0, Aba, Aga, Aka
    eor3_m1_1 C2, Abi, Agi, Aki
    eor3_m1_1 C4, Abu, Agu, Aku
    eor3_m1_0 C1, C1, Ame,  Ase
    eor3_m1_0 C3, C3, Amo,  Aso
    eor3_m1_0 C0, C0, Ama,  Asa
    eor3_m1_0 C2, C2, Ami,  Asi
    eor3_m1_0 C4, C4, Amu,  Asu
    eor3_m1_1 C1, C1, Ame,  Ase
    eor3_m1_1 C3, C3, Amo,  Aso
    eor3_m1_1 C0, C0, Ama,  Asa
    eor3_m1_1 C2, C2, Ami,  Asi
    eor3_m1_1 C4, C4, Amu,  Asu

.endm

.macro keccak_f1600_round

    /* 10 EOR3, so 20 individual EOR */

    eor3_m1_0 C0, Aba, Aga, Aka
    eor3_m1_0 C1, Abe, Age, Ake
    eor3_m1_0 C2, Abi, Agi, Aki
    eor3_m1_0 C3, Abo, Ago, Ako
    eor3_m1_0 C4, Abu, Agu, Aku
    eor3_m1_1 C0, Aba, Aga, Aka
    eor3_m1_1 C1, Abe, Age, Ake
    eor3_m1_1 C2, Abi, Agi, Aki
    eor3_m1_1 C3, Abo, Ago, Ako
    eor3_m1_1 C4, Abu, Agu, Aku
    eor3_m1_0 C0, C0, Ama,  Asa
    eor3_m1_0 C1, C1, Ame,  Ase
    eor3_m1_0 C2, C2, Ami,  Asi
    eor3_m1_0 C3, C3, Amo,  Aso
    eor3_m1_0 C4, C4, Amu,  Asu
    eor3_m1_1 C0, C0, Ama,  Asa
    eor3_m1_1 C1, C1, Ame,  Ase
    eor3_m1_1 C2, C2, Ami,  Asi
    eor3_m1_1 C3, C3, Amo,  Aso
    eor3_m1_1 C4, C4, Amu,  Asu

    /* 5x RAX1, 15 Neon Instructions total */

    tmp .req vBba
    rax1_m1 E2, C1, C3
    rax1_m1 E4, C3, C0
    rax1_m1 E1, C0, C2
    rax1_m1 E3, C2, C4
    rax1_m1 E0, C4, C1
    .unreq tmp

    /* 25x XAR, 75 in total */

    tmp  .req C1
    tmpq .req C1q

    eor vBba.16b, Aba.16b, E0.16b
    xar_m1 vBsa, Abi, E2, 2
    xar_m1 vBbi, Aki, E2, 21
    xar_m1 vBki, Ako, E3, 39
    xar_m1 vBko, Amu, E4, 56
    xar_m1 vBmu, Aso, E3, 8
    xar_m1 vBso, Ama, E0, 23
    xar_m1 vBka, Abe, E1, 63
    xar_m1 vBse, Ago, E3, 9
    xar_m1 vBgo, Ame, E1, 19
    xar_m1 vBke, Agi, E2, 58
    xar_m1 vBgi, Aka, E0, 61
    xar_m1 vBga, Abo, E3, 36
    xar_m1 vBbo, Amo, E3, 43
    xar_m1 vBmo, Ami, E2, 49
    xar_m1 vBmi, Ake, E1, 54
    xar_m1 vBge, Agu, E4, 44
    xar_m1 vBgu, Asi, E2, 3
    xar_m1 vBsi, Aku, E4, 25
    xar_m1 vBku, Asa, E0, 46
    xar_m1 vBma, Abu, E4, 37
    xar_m1 vBbu, Asu, E4, 50
    xar_m1 vBsu, Ase, E1, 62
    xar_m1 vBme, Aga, E0, 28
    xar_m1 vBbe, Age, E1, 20

    /* 25x BCAX, 50 in total */

    bcax_m1 Aga, vBga, vBgi, vBge
    bcax_m1 Age, vBge, vBgo, vBgi
    bcax_m1 Agi, vBgi, vBgu, vBgo
    bcax_m1 Ago, vBgo, vBga, vBgu
    bcax_m1 Agu, vBgu, vBge, vBga
    bcax_m1 Aka, vBka, vBki, vBke
    bcax_m1 Ake, vBke, vBko, vBki
    bcax_m1 Aki, vBki, vBku, vBko
    bcax_m1 Ako, vBko, vBka, vBku
    bcax_m1 Aku, vBku, vBke, vBka
    bcax_m1 Ama, vBma, vBmi, vBme
    bcax_m1 Ame, vBme, vBmo, vBmi
    bcax_m1 Ami, vBmi, vBmu, vBmo
    bcax_m1 Amo, vBmo, vBma, vBmu
    bcax_m1 Amu, vBmu, vBme, vBma
    bcax_m1 Asa, vBsa, vBsi, vBse
    bcax_m1 Ase, vBse, vBso, vBsi
    bcax_m1 Asi, vBsi, vBsu, vBso
    bcax_m1 Aso, vBso, vBsa, vBsu
    bcax_m1 Asu, vBsu, vBse, vBsa
    bcax_m1 Aba, vBba, vBbi, vBbe
    bcax_m1 Abe, vBbe, vBbo, vBbi
    bcax_m1 Abi, vBbi, vBbu, vBbo
    bcax_m1 Abo, vBbo, vBba, vBbu
    bcax_m1 Abu, vBbu, vBbe, vBba

    // iota step
    //ld1r {tmp.2d}, [const_addr], #8
    ldr tmpq, [const_addr], #16
    eor Aba.16b, Aba.16b, tmp.16b

    .unreq tmp
    .unreq tmpq

.endm

.macro keccak_f1600_round_core

    /* 5x RAX1, 15 Neon Instructions total */

    tmp .req vBba
    rax1_m1 E2, C1, C3
    rax1_m1 E4, C3, C0
    rax1_m1 E1, C0, C2
    rax1_m1 E3, C2, C4
    rax1_m1 E0, C4, C1

    /* 25x XAR, 75 in total */

    .unreq tmp
    tmp .req C1
    tmpq .req C1q

    eor vBba.16b, Aba.16b, E0.16b
    xar_m1 vBsa, Abi, E2, 2
    xar_m1 vBbi, Aki, E2, 21
    xar_m1 vBki, Ako, E3, 39
    xar_m1 vBko, Amu, E4, 56
    xar_m1 vBmu, Aso, E3, 8
    xar_m1 vBso, Ama, E0, 23
    xar_m1 vBka, Abe, E1, 63
    xar_m1 vBse, Ago, E3, 9
    xar_m1 vBgo, Ame, E1, 19
    xar_m1 vBke, Agi, E2, 58
    xar_m1 vBgi, Aka, E0, 61
    xar_m1 vBga, Abo, E3, 36
    xar_m1 vBbo, Amo, E3, 43
    xar_m1 vBmo, Ami, E2, 49
    xar_m1 vBmi, Ake, E1, 54
    xar_m1 vBge, Agu, E4, 44
    mov E3.16b, Aga.16b
    bcax_m1 Aga, vBga, vBgi, vBge
    xar_m1 vBgu, Asi, E2, 3
    xar_m1 vBsi, Aku, E4, 25
    xar_m1 vBku, Asa, E0, 46
    xar_m1 vBma, Abu, E4, 37
    xar_m1 vBbu, Asu, E4, 50
    xar_m1 vBsu, Ase, E1, 62
    xar_m1 vBme, E3, E0, 28
    xar_m1 vBbe, Age, E1, 20

    /* 25x BCAX, 50 in total */

    bcax_m1 Age, vBge, vBgo, vBgi
    bcax_m1 Agi, vBgi, vBgu, vBgo
    bcax_m1 Ago, vBgo, vBga, vBgu
    bcax_m1 Agu, vBgu, vBge, vBga
    bcax_m1 Aka, vBka, vBki, vBke
    bcax_m1 Ake, vBke, vBko, vBki

    .unreq tmp
    .unreq tmpq

    eor2    C0,  Aka, Aga
    save(Aga)

    tmp .req Aga
    tmpq .req Agaq
    bcax_m1 Aki, vBki, vBku, vBko
    bcax_m1 Ako, vBko, vBka, vBku
    eor2    C1,  Ake, Age
    bcax_m1 Aku, vBku, vBke, vBka
    eor2    C2,  Aki, Agi
    bcax_m1 Ama, vBma, vBmi, vBme
    eor2    C3,  Ako, Ago
    bcax_m1 Ame, vBme, vBmo, vBmi
    eor2    C4,  Aku, Agu
    bcax_m1 Ami, vBmi, vBmu, vBmo
    eor2    C0,  C0,  Ama
    bcax_m1 Amo, vBmo, vBma, vBmu
    eor2    C1,  C1,  Ame
    bcax_m1 Amu, vBmu, vBme, vBma
    eor2    C2,  C2,  Ami
    bcax_m1 Asa, vBsa, vBsi, vBse
    eor2    C3,  C3,  Amo
    bcax_m1 Ase, vBse, vBso, vBsi
    eor2    C4,  C4,  Amu
    bcax_m1 Asi, vBsi, vBsu, vBso
    eor2    C0,  C0,  Asa
    bcax_m1 Aso, vBso, vBsa, vBsu
    eor2    C1,  C1,  Ase
    bcax_m1 Asu, vBsu, vBse, vBsa
    eor2    C2,  C2,  Asi
    eor2    C3,  C3,  Aso
    bcax_m1 Aba, vBba, vBbi, vBbe
    bcax_m1 Abe, vBbe, vBbo, vBbi
    eor2    C1,  C1,  Abe

    // iota step
    //ld1r {tmp.2d}, [const_addr], #8
    ldr tmpq, [const_addr], #16
    eor Aba.16b, Aba.16b, tmp.16b
    eor2    C4,  C4,  Asu
    bcax_m1 Abi, vBbi, vBbu, vBbo
    bcax_m1 Abo, vBbo, vBba, vBbu
    eor2    C3,  C3,  Abo
    eor2    C2,  C2,  Abi
    eor2    C0,  C0,  Aba
    bcax_m1 Abu, vBbu, vBbe, vBba
    eor2    C4,  C4,  Abu

    restore(Aga)
    .unreq tmp
    .unreq tmpq

.endm

.macro keccak_f1600_round_post

    /* 5x RAX1, 15 Neon Instructions total */

    tmp .req vBba
    rax1_m1 E2, C1, C3
    rax1_m1 E4, C3, C0
    rax1_m1 E1, C0, C2
    rax1_m1 E3, C2, C4
    rax1_m1 E0, C4, C1

    /* 25x XAR, 75 in total */

    .unreq tmp
    tmp .req C1
    tmpq .req C1q

    eor vBba.16b, Aba.16b, E0.16b
    xar_m1 vBsa, Abi, E2, 2
    xar_m1 vBbi, Aki, E2, 21
    xar_m1 vBki, Ako, E3, 39
    xar_m1 vBko, Amu, E4, 56
    xar_m1 vBmu, Aso, E3, 8
    xar_m1 vBso, Ama, E0, 23
    xar_m1 vBka, Abe, E1, 63
    xar_m1 vBse, Ago, E3, 9
    xar_m1 vBgo, Ame, E1, 19
    xar_m1 vBke, Agi, E2, 58
    xar_m1 vBgi, Aka, E0, 61
    xar_m1 vBga, Abo, E3, 36
    xar_m1 vBbo, Amo, E3, 43
    xar_m1 vBmo, Ami, E2, 49
    xar_m1 vBmi, Ake, E1, 54
    xar_m1 vBge, Agu, E4, 44
    mov E3.16b, Aga.16b
    bcax_m1 Aga, vBga, vBgi, vBge
    xar_m1 vBgu, Asi, E2, 3
    xar_m1 vBsi, Aku, E4, 25
    xar_m1 vBku, Asa, E0, 46
    xar_m1 vBma, Abu, E4, 37
    xar_m1 vBbu, Asu, E4, 50
    xar_m1 vBsu, Ase, E1, 62
    xar_m1 vBme, E3, E0, 28
    xar_m1 vBbe, Age, E1, 20

    /* 25x BCAX, 50 in total */

    bcax_m1 Age, vBge, vBgo, vBgi
    bcax_m1 Agi, vBgi, vBgu, vBgo
    bcax_m1 Ago, vBgo, vBga, vBgu
    bcax_m1 Agu, vBgu, vBge, vBga
    bcax_m1 Aka, vBka, vBki, vBke
    bcax_m1 Ake, vBke, vBko, vBki
    bcax_m1 Aki, vBki, vBku, vBko
    bcax_m1 Ako, vBko, vBka, vBku
    bcax_m1 Aku, vBku, vBke, vBka
    bcax_m1 Ama, vBma, vBmi, vBme
    bcax_m1 Ame, vBme, vBmo, vBmi
    bcax_m1 Ami, vBmi, vBmu, vBmo
    bcax_m1 Amo, vBmo, vBma, vBmu
    bcax_m1 Amu, vBmu, vBme, vBma
    bcax_m1 Asa, vBsa, vBsi, vBse
    bcax_m1 Ase, vBse, vBso, vBsi
    bcax_m1 Asi, vBsi, vBsu, vBso
    bcax_m1 Aso, vBso, vBsa, vBsu
    bcax_m1 Asu, vBsu, vBse, vBsa
    bcax_m1 Aba, vBba, vBbi, vBbe
    bcax_m1 Abe, vBbe, vBbo, vBbi
    bcax_m1 Abi, vBbi, vBbu, vBbo
    bcax_m1 Abo, vBbo, vBba, vBbu
    bcax_m1 Abu, vBbu, vBbe, vBba

    // iota step
    //ld1r {tmp.2d}, [const_addr], #8
    ldr tmpq, [const_addr], #16
    eor Aba.16b, Aba.16b, tmp.16b

    .unreq tmp
    .unreq tmpq

.endm


.text
.align 4
.global keccak_f1600_x2_v84a_asm_v2pp4
.global _keccak_f1600_x2_v84a_asm_v2pp4

#define KECCAK_F1600_ROUNDS 24

keccak_f1600_x2_v84a_asm_v2pp4:
_keccak_f1600_x2_v84a_asm_v2pp4:
    alloc_stack
    save_vregs
    load_constant_ptr
    load_input

    //mov count, #(KECCAK_F1600_ROUNDS-2)
    mov count, #11
    keccak_f1600_round_pre
loop:
    keccak_f1600_round_core
    keccak_f1600_round_core
    sub count, count, #1
    cbnz count, loop

    keccak_f1600_round_core
    keccak_f1600_round_post
    store_input
    restore_vregs
    free_stack
    ret
