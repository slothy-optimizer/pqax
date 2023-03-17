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

    /* E[x] = C[x-1] xor rot(C[x+1],1), for x in 0..4 */
    E0 .req v26
    E1 .req v26
    E2 .req v26
    E3 .req v26
    E4 .req v26

    E0q .req q26
    E1q .req q26
    E2q .req q26
    E3q .req q26
    E4q .req q26

    /* A_[y,2*x+3*y] = rot(A[x,y]) */
    // vBgi .req v27
    // vBgo .req v28
    // vBga .req v29
    // vBge .req v30
    // vBgu .req v31
    vBki .req v27
    vBko .req v28
    vBka .req v29
    vBke .req v30
    vBku .req v31
    vBmu .req v27
    vBmo .req v28
    vBmi .req v29
    vBma .req v30
    vBme .req v31
    vBba .req v27
    vBbi .req v28
    vBbo .req v29
    vBbu .req v30
    vBbe .req v31
    vBsa .req v27
    vBso .req v28
    vBse .req v29
    vBsi .req v30
    vBsu .req v31

    // vBgiq .req q27
    // vBgoq .req q28
    // vBgaq .req q29
    // vBgeq .req q30
    // vBguq .req q31
    vBkiq .req q27
    vBkoq .req q28
    vBkaq .req q29
    vBkeq .req q30
    vBkuq .req q31
    vBmuq .req q27
    vBmoq .req q28
    vBmiq .req q29
    vBmaq .req q30
    vBmeq .req q31
    vBbaq .req q27
    vBbiq .req q28
    vBboq .req q29
    vBbuq .req q30
    vBbeq .req q31
    vBsaq .req q27
    vBsoq .req q28
    vBseq .req q29
    vBsiq .req q30
    vBsuq .req q31

    vEgu .req Agu
    vEga .req v26
    vEge .req v26
    vEgi .req v26
    vEgo .req v26
    vEka .req Aka
    vEko .req Ako
    vEke .req v26
    vEki .req v26
    vEku .req v26
    vEma .req v26
    vEme .req Ame
    vEmi .req Ami
    vEmo .req v26
    vEmu .req Amu
    vEba .req Aba
    vEbe .req Abe
    vEbi .req v26
    vEbo .req Abo
    vEbu .req Abu
    vEsa .req Asa
    vEse .req Ase
    vEsi .req Asi
    vEso .req Aso
    vEsu .req Asu

    vEguq .req Aguq
    vEgaq .req q26
    vEgeq .req q26
    vEgiq .req q26
    vEgoq .req q26
    vEkaq .req Akaq
    vEkoq .req Akoq
    vEkeq .req q26
    vEkiq .req q26
    vEkuq .req q26
    vEmaq .req q26
    vEmeq .req Ameq
    vEmiq .req Amiq
    vEmoq .req q26
    vEmuq .req Amuq
    vEbaq .req Abaq
    vEbeq .req Abeq
    vEbiq .req q26
    vEboq .req Aboq
    vEbuq .req Abuq
    vEsaq .req Asaq
    vEseq .req Aseq
    vEsiq .req Asiq
    vEsoq .req Asoq
    vEsuq .req Asuq

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

#define STACK_SIZE (16*4 + 16*30)
#define STACK_BASE_VREGS 0
#define STACK_BASE_TMP   16*4

#define E0_offset  0
#define E1_offset  1
#define E2_offset  2
#define E3_offset  3
#define E4_offset  4

#define Aba_offset (5 + 0  )
#define Abe_offset (5 + 1  )
#define Abi_offset (5 + 2  )
#define Abo_offset (5 + 3  )
#define Abu_offset (5 + 4  )
#define Aga_offset (5 + 5  )
#define Age_offset (5 + 6  )
#define Agi_offset (5 + 7  )
#define Ago_offset (5 + 8  )
#define Agu_offset (5 + 9  )
#define Aka_offset (5 + 10 )
#define Ake_offset (5 + 11 )
#define Aki_offset (5 + 12 )
#define Ako_offset (5 + 13 )
#define Aku_offset (5 + 14 )
#define Ama_offset (5 + 15 )
#define Ame_offset (5 + 16 )
#define Ami_offset (5 + 17 )
#define Amo_offset (5 + 18 )
#define Amu_offset (5 + 19 )
#define Asa_offset (5 + 20 )
#define Ase_offset (5 + 21 )
#define Asi_offset (5 + 22 )
#define Aso_offset (5 + 23 )
#define Asu_offset (5 + 24 )

#define vEba_offset (5 + 0  )
#define vEbe_offset (5 + 1  )
#define vEbi_offset (5 + 2  )
#define vEbo_offset (5 + 3  )
#define vEbu_offset (5 + 4  )
#define vEga_offset (5 + 5  )
#define vEge_offset (5 + 6  )
#define vEgi_offset (5 + 7  )
#define vEgo_offset (5 + 8  )
#define vEgu_offset (5 + 9  )
#define vEka_offset (5 + 10 )
#define vEke_offset (5 + 11 )
#define vEki_offset (5 + 12 )
#define vEko_offset (5 + 13 )
#define vEku_offset (5 + 14 )
#define vEma_offset (5 + 15 )
#define vEme_offset (5 + 16 )
#define vEmi_offset (5 + 17 )
#define vEmo_offset (5 + 18 )
#define vEmu_offset (5 + 19 )
#define vEsa_offset (5 + 20 )
#define vEse_offset (5 + 21 )
#define vEsi_offset (5 + 22 )
#define vEso_offset (5 + 23 )
#define vEsu_offset (5 + 24 )

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
   add tmp.2d, \s1\().2d, \s1\().2d
   sri tmp.2d, \s1\().2d, #63
   eor \d\().16b, tmp.16b, \s0\().16b
.endm

.macro xar_m1 d s0 s1 imm
   eor \s0\().16b, \s0\().16b, \s1\().16b
   shl \d\().2d, \s0\().2d, #(64-\imm)
   sri \d\().2d, \s0\().2d, #(\imm)
.endm

.macro xar_m1_0 d s0 s1 imm tmp
   eor \tmp\().16b, \s0\().16b, \s1\().16b
.endm

.macro xar_m1_1 d s0 s1 imm tmp
   shl \d\().2d, \tmp\().2d, #(64-\imm)
.endm

.macro xar_m1_2 d s0 s1 imm tmp
   sri \d\().2d, \tmp\().2d, #(\imm)
.endm

.macro bcax_m1 d s0 s1 s2
    bic tmp.16b, \s1\().16b, \s2\().16b
    eor \d\().16b, tmp.16b, \s0\().16b
.endm

.macro refresh d
    mov \d\().16b, \d\().16b
.endm
/* Keccak-f1600 round */

.macro keccak_f1600_round_pre
    eor2 C0,  Aka, Aga
    eor2 C1,  Ake, Age
    eor2 C2,  Aki, Agi
    eor2 C3,  Ako, Ago
    eor2 C4,  Aku, Agu
    eor2 C0,  C0,  Ama
    eor2 C1,  C1,  Ame
    eor2 C2,  C2,  Ami
    eor2 C3,  C3,  Amo
    eor2 C4,  C4,  Amu
    eor2 C0,  C0,  Asa
    eor2 C1,  C1,  Ase
    eor2 C2,  C2,  Asi
    eor2 C3,  C3,  Aso
    eor2 C4,  C4,  Asu
    eor2 C0,  C0,  Aba
    eor2 C1,  C1,  Abe
    eor2 C2,  C2,  Abi
    eor2 C3,  C3,  Abo
    eor2 C4,  C4,  Abu
.endm

.macro keccak_f1600_round_core

    /* 5x RAX1, 15 Neon Instructions total */

    tmp .req v25

    .unreq E0
    .unreq E1
    .unreq E2
    .unreq E3
    .unreq E4
    .unreq E0q
    .unreq E1q
    .unreq E2q
    .unreq E3q
    .unreq E4q

    E1 .req v26
    E3 .req C2
    E0 .req C4
    E2 .req C1
    E4 .req C3

    E1q .req q26
    E3q .req C2q
    E0q .req C4q
    E2q .req C1q
    E4q .req C3q

    rax1_m1 E1, C0, C2                 SEP      save(E1)
    rax1_m1 E3, C2, C4                 SEP      save(E3)
    rax1_m1 E0, C4, C1                 SEP      save(E0)
    rax1_m1 E2, C1, C3                 SEP      save(E2)
    rax1_m1 E4, C3, C0                 SEP      save(E4)

    vBgi .req E0
    vBgo .req v27
    vBga .req E3
    vBge .req E4
    vBgu .req E2

    xar_m1 vBgi, Aka, E0, 61           SEP
    xar_m1 vBgo, Ame, E1, 19           SEP
    xar_m1 vBga, Abo, E3, 36           SEP
    xar_m1 vBge, Agu, E4, 44           SEP
    xar_m1 vBgu, Asi, E2, 3            SEP

    bcax_m1 vEga, vBga, vBgi, vBge     SEP      save(vEga)
    bcax_m1 vEge, vBge, vBgo, vBgi     SEP      save(vEge)
    bcax_m1 vEgi, vBgi, vBgu, vBgo     SEP      save(vEgi)
    bcax_m1 vEgo, vBgo, vBga, vBgu     SEP      save(vEgo)
    bcax_m1 vEgu, vBgu, vBge, vBga

    .unreq E0
    .unreq E1
    .unreq E2
    .unreq E3
    .unreq E4
    .unreq E0q
    .unreq E1q
    .unreq E2q
    .unreq E3q
    .unreq E4q

    E0 .req v26
    E1 .req v26
    E2 .req v26
    E3 .req v26
    E4 .req v26
    E0q .req q26
    E1q .req q26
    E2q .req q26
    E3q .req q26
    E4q .req q26

                                                 restore(E3)
    xar_m1 vBki, Ako, E3, 39           SEP       restore(E4)
    xar_m1 vBko, Amu, E4, 56           SEP       restore(E1)
    xar_m1 vBka, Abe, E1, 63           SEP       restore(E2)
    xar_m1 vBke, Agi, E2, 58           SEP       restore(E0)
    xar_m1 vBku, Asa, E0, 46

    bcax_m1 vEke, vBke, vBko, vBki     SEP       save(vEke)
    bcax_m1 vEki, vBki, vBku, vBko     SEP       save(vEki)
    bcax_m1 vEku, vBku, vBke, vBka     SEP       save(vEku)
    bcax_m1 vEko, vBko, vBka, vBku
    bcax_m1 vEka, vBka, vBki, vBke

                                                restore(E3)
    xar_m1 vBmu, Aso, E3, 8            SEP      restore(E2)
    xar_m1 vBmo, Ami, E2, 49           SEP      restore(E1)
    xar_m1 vBmi, Ake, E1, 54           SEP      restore(E4)
    xar_m1 vBma, Abu, E4, 37           SEP      restore(E0)
    xar_m1 vBme, Aga, E0, 28

    bcax_m1 vEma, vBma, vBmi, vBme     SEP      save(vEma)
    bcax_m1 vEmo, vBmo, vBma, vBmu     SEP      save(vEmo)
    bcax_m1 vEme, vBme, vBmo, vBmi
    bcax_m1 vEmi, vBmi, vBmu, vBmo
    bcax_m1 vEmu, vBmu, vBme, vBma

                                                restore(E0)
    eor2   vBba, Aba, E0               SEP      restore(E2)
    xar_m1 vBbi, Aki, E2, 21           SEP      restore(E3)
    xar_m1 vBbo, Amo, E3, 43           SEP      restore(E4)
    xar_m1 vBbu, Asu, E4, 50           SEP      restore(E1)
    xar_m1 vBbe, Age, E1, 20

    bcax_m1 vEbi, vBbi, vBbu, vBbo     SEP      save(vEbi)
    bcax_m1 vEba, vBba, vBbi, vBbe
    ld1r {tmp.2d}, [const_addr], #8
    eor2    vEba, vEba, tmp
    bcax_m1 vEbe, vBbe, vBbo, vBbi
    bcax_m1 vEbo, vBbo, vBba, vBbu
    bcax_m1 vEbu, vBbu, vBbe, vBba

                                               restore(E2)
    xar_m1 vBsa, Abi, E2, 2           SEP      restore(E0)
    xar_m1 vBso, Ama, E0, 23          SEP      restore(E3)
    xar_m1 vBse, Ago, E3, 9           SEP      restore(E4)
    xar_m1 vBsi, Aku, E4, 25          SEP      restore(E1)
    xar_m1 vBsu, Ase, E1, 62

    bcax_m1 vEsa, vBsa, vBsi, vBse    SEP      restore(Amo)
    bcax_m1 vEse, vBse, vBso, vBsi    SEP      restore(Agi)
    bcax_m1 vEsi, vBsi, vBsu, vBso    SEP      restore(Abi)
    bcax_m1 vEso, vBso, vBsa, vBsu    SEP      restore(Ake)
    bcax_m1 vEsu, vBsu, vBse, vBsa    SEP      restore(Aki)

    restore(Age)
    restore(Aku)
    restore(Ama)
    restore(Aga)
    restore(Ago)

    eor2 C3, Ako, Ago
    eor2 C0, Aka, Aga
    eor2 C1, Ake, Age
    eor2 C2, Aki, Agi
    eor2 C4, Aku, Agu

    eor2 C0,  C0,  Ama
    eor2 C1,  C1,  Ame
    eor2 C2,  C2,  Ami
    eor2 C3,  C3,  Amo
    eor2 C4,  C4,  Amu

    eor2 C0,  C0,  Aba
    eor2 C1,  C1,  Abe
    eor2 C2,  C2,  Abi
    eor2 C3,  C3,  Abo
    eor2 C4,  C4,  Abu

    eor2 C0,  C0,  Asa
    eor2 C1,  C1,  Ase
    eor2 C2,  C2,  Asi
    eor2 C3,  C3,  Aso
    eor2 C4,  C4,  Asu

    .unreq tmp

.endm

.macro keccak_f1600_round_post

    /* 5x RAX1, 15 Neon Instructions total */

    tmp .req v25

    .unreq E0
    .unreq E1
    .unreq E2
    .unreq E3
    .unreq E4
    .unreq E0q
    .unreq E1q
    .unreq E2q
    .unreq E3q
    .unreq E4q

    E1 .req v26
    E3 .req C2
    E0 .req C4
    E2 .req C1
    E4 .req C3

    E1q .req q26
    E3q .req C2q
    E0q .req C4q
    E2q .req C1q
    E4q .req C3q

    rax1_m1 E1, C0, C2                 SEP      save(E1)
    rax1_m1 E3, C2, C4                 SEP      save(E3)
    rax1_m1 E0, C4, C1                 SEP      save(E0)
    rax1_m1 E2, C1, C3                 SEP      save(E2)
    rax1_m1 E4, C3, C0                 SEP      save(E4)

    .unreq vBgi
    .unreq vBgo
    .unreq vBga
    .unreq vBge
    .unreq vBgu
    vBgi .req E0
    vBgo .req v27
    vBga .req E3
    vBge .req E4
    vBgu .req E2

    xar_m1 vBgi, Aka, E0, 61           SEP
    xar_m1 vBgo, Ame, E1, 19           SEP
    xar_m1 vBga, Abo, E3, 36           SEP
    xar_m1 vBge, Agu, E4, 44           SEP
    xar_m1 vBgu, Asi, E2, 3            SEP

    bcax_m1 vEga, vBga, vBgi, vBge     SEP      save(vEga)
    bcax_m1 vEge, vBge, vBgo, vBgi     SEP      save(vEge)
    bcax_m1 vEgi, vBgi, vBgu, vBgo     SEP      save(vEgi)
    bcax_m1 vEgo, vBgo, vBga, vBgu     SEP      save(vEgo)
    bcax_m1 vEgu, vBgu, vBge, vBga

    .unreq E0
    .unreq E1
    .unreq E2
    .unreq E3
    .unreq E4
    .unreq E0q
    .unreq E1q
    .unreq E2q
    .unreq E3q
    .unreq E4q

    E0 .req v26
    E1 .req v26
    E2 .req v26
    E3 .req v26
    E4 .req v26
    E0q .req q26
    E1q .req q26
    E2q .req q26
    E3q .req q26
    E4q .req q26

                                                 restore(E3)
    xar_m1 vBki, Ako, E3, 39           SEP       restore(E4)
    xar_m1 vBko, Amu, E4, 56           SEP       restore(E1)
    xar_m1 vBka, Abe, E1, 63           SEP       restore(E2)
    xar_m1 vBke, Agi, E2, 58           SEP       restore(E0)
    xar_m1 vBku, Asa, E0, 46

    bcax_m1 vEke, vBke, vBko, vBki     SEP       save(vEke)
    bcax_m1 vEki, vBki, vBku, vBko     SEP       save(vEki)
    bcax_m1 vEku, vBku, vBke, vBka     SEP       save(vEku)
    bcax_m1 vEko, vBko, vBka, vBku
    bcax_m1 vEka, vBka, vBki, vBke

                                                restore(E3)
    xar_m1 vBmu, Aso, E3, 8            SEP      restore(E2)
    xar_m1 vBmo, Ami, E2, 49           SEP      restore(E1)
    xar_m1 vBmi, Ake, E1, 54           SEP      restore(E4)
    xar_m1 vBma, Abu, E4, 37           SEP      restore(E0)
    xar_m1 vBme, Aga, E0, 28

    bcax_m1 vEma, vBma, vBmi, vBme     SEP      save(vEma)
    bcax_m1 vEmo, vBmo, vBma, vBmu     SEP      save(vEmo)
    bcax_m1 vEme, vBme, vBmo, vBmi
    bcax_m1 vEmi, vBmi, vBmu, vBmo
    bcax_m1 vEmu, vBmu, vBme, vBma

                                                restore(E0)
    eor2   vBba, Aba, E0               SEP      restore(E2)
    xar_m1 vBbi, Aki, E2, 21           SEP      restore(E3)
    xar_m1 vBbo, Amo, E3, 43           SEP      restore(E4)
    xar_m1 vBbu, Asu, E4, 50           SEP      restore(E1)
    xar_m1 vBbe, Age, E1, 20

    bcax_m1 vEbi, vBbi, vBbu, vBbo     SEP      save(vEbi)
    bcax_m1 vEba, vBba, vBbi, vBbe
    ld1r {tmp.2d}, [const_addr], #8
    eor2    vEba, vEba, tmp
    bcax_m1 vEbe, vBbe, vBbo, vBbi
    bcax_m1 vEbo, vBbo, vBba, vBbu
    bcax_m1 vEbu, vBbu, vBbe, vBba

                                               restore(E2)
    xar_m1 vBsa, Abi, E2, 2           SEP      restore(E0)
    xar_m1 vBso, Ama, E0, 23          SEP      restore(E3)
    xar_m1 vBse, Ago, E3, 9           SEP      restore(E4)
    xar_m1 vBsi, Aku, E4, 25          SEP      restore(E1)
    xar_m1 vBsu, Ase, E1, 62

    bcax_m1 vEsa, vBsa, vBsi, vBse    SEP      restore(Amo)
    bcax_m1 vEse, vBse, vBso, vBsi    SEP      restore(Agi)
    bcax_m1 vEsi, vBsi, vBsu, vBso    SEP      restore(Abi)
    bcax_m1 vEso, vBso, vBsa, vBsu    SEP      restore(Ake)
    bcax_m1 vEsu, vBsu, vBse, vBsa    SEP      restore(Aki)

    restore(Age)
    restore(Aku)
    restore(Ama)
    restore(Aga)
    restore(Ago)

    .unreq tmp

.endm


.text
.align 4
.global keccak_f1600_x2_v84a_asm_v2p2
.global _keccak_f1600_x2_v84a_asm_v2p2

#define KECCAK_F1600_ROUNDS 24

keccak_f1600_x2_v84a_asm_v2p2:
_keccak_f1600_x2_v84a_asm_v2p2:
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
