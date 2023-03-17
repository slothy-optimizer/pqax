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
    Abo     .req v2
    Abu     .req v3
    Agu     .req v4
    Aka     .req v5
    Ako     .req v6
    Ame     .req v7
    Ami     .req v8
    Amu     .req v9
    Asa     .req v10
    Ase     .req v11
    Asi     .req v12
    Aso     .req v13
    Asu     .req v14

    Agi     .req v15
    Ake     .req v16
    Aga     .req v17
    Aki     .req v18

    Abi     .req v19
    Ama     .req v20
    Ago     .req v21
    Aku     .req v22
    Age     .req v23
    Amo     .req v24

    /* q-form of the above mapping */
    Abaq    .req q0
    Abeq    .req q1
    Aboq    .req q2
    Abuq    .req q3
    Aguq    .req q4
    Akaq    .req q5
    Akoq    .req q6
    Ameq    .req q7
    Amiq    .req q8
    Amuq    .req q9
    Asaq    .req q10
    Aseq    .req q11
    Asiq    .req q12
    Asoq    .req q13
    Asuq    .req q14

    Agiq    .req q15
    Akeq    .req q16
    Agaq    .req q17
    Akiq    .req q18

    Abiq    .req q19
    Amaq    .req q20
    Agoq    .req q21
    Akuq    .req q22
    Ageq    .req q23
    Amoq    .req q24

    spare0  .req v25
    spare1  .req v26
    spare2  .req v27
    spare3  .req v28
    spare4  .req v29
    spare5  .req v30
    spare0q .req q25
    spare1q .req q26
    spare2q .req q27
    spare3q .req q28
    spare4q .req q29
    spare5q .req q30

    vEgu .req Agu      /* keep */
    vEga .req spare0   /* out  */
    vEge .req spare1   /* out  */
    vEgi .req spare2   /* out  */
    vEgo .req spare3   /* out  */

    vEka .req Aka      /* keep */
    vEko .req Ako      /* keep */
    vEke .req spare4   /* out  */
    vEki .req spare5   /* out  */
    vEku .req Agi      /* in   */

    vEma .req Ake      /* in   */
    vEme .req Ame      /* keep */
    vEmi .req Ami      /* keep */
    vEmo .req Aga      /* in   */
    vEmu .req Amu      /* keep */

    vEba .req Aba      /* keep */
    vEbe .req Abe      /* keep */
    vEbi .req Aki      /* in   */
    vEbo .req Abo      /* keep */
    vEbu .req Abu      /* keep */

    vEsa .req Asa      /* keep */
    vEse .req Ase      /* keep */
    vEsi .req Asi      /* keep */
    vEso .req Aso      /* keep */
    vEsu .req Asu      /* keep */

    vEguq .req Aguq
    vEgaq .req spare0q
    vEgeq .req spare1q
    vEgiq .req spare2q
    vEgoq .req spare3q

    vEkaq .req Akaq
    vEkoq .req Akoq
    vEkeq .req spare4q
    vEkiq .req spare5q
    vEkuq .req Agiq

    vEmaq .req Akeq
    vEmeq .req Ameq
    vEmiq .req Amiq
    vEmoq .req Agaq
    vEmuq .req Amuq

    vEbaq .req Abaq
    vEbeq .req Abeq
    vEbiq .req Akiq
    vEboq .req Aboq
    vEbuq .req Abuq

    vEsaq .req Asaq
    vEseq .req Aseq
    vEsiq .req Asiq
    vEsoq .req Asoq
    vEsuq .req Asuq

    tmp     .req v31
    tmpq    .req q31

    /* C[x] = A[x,0] xor A[x,1] xor A[x,2] xor A[x,3] xor A[x,4],   for x in 0..4 */
    C0  .req spare0
    C1  .req spare1
    C2  .req spare2
    C3  .req spare3
    C4  .req spare4
    C0q .req spare0q
    C1q .req spare1q
    C2q .req spare2q
    C3q .req spare3q
    C4q .req spare4q

    /* E[x] = C[x-1] xor rot(C[x+1],1), for x in 0..4 */

    // Registers used during computation time
    E1c .req spare5
    E3c .req C2
    E0c .req C4
    E2c .req C1
    E4c .req C3

    E1cq .req spare5q
    E3cq .req C2q
    E0cq .req C4q
    E2cq .req C1q
    E4cq .req C3q

    // Registers during use time
    E0u .req tmp
    E1u .req tmp
    E2u .req tmp
    E3u .req tmp
    E4u .req tmp

    E0uq .req tmpq
    E1uq .req tmpq
    E2uq .req tmpq
    E3uq .req tmpq
    E4uq .req tmpq

    vBgo .req E1c
    vBgi .req Ame
    vBga .req Aka
    vBge .req Abo
    vBgu .req Agu

    vBko .req Ame
    vBka .req Amu
    vBke .req Abe
    vBku .req Agi
    vBki .req Asa

    vBmu .req Abo
    vBmo .req Aso
    vBmi .req Abu
    vBma .req Asi
    vBme .req Abe

    vBba .req Asi
    vBbi .req Asa
    vBbo .req Aso
    vBbu .req Amo
    vBbe .req Asu

    vBsa .req Amo
    vBso .req Abi
    vBse .req Ama
    vBsi .req Ago
    vBsu .req Aku

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

#define E0c_offset  0
#define E1c_offset  1
#define E2c_offset  2
#define E3c_offset  3
#define E4c_offset  4
#define E0u_offset  0
#define E1u_offset  1
#define E2u_offset  2
#define E3u_offset  3
#define E4u_offset  4

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

.macro eor5 out i0 i1 i2 i3 i4 tmp
    eor2 \out, \i0, \i1
    eor2 \tmp, \i3, \i4
    eor2 \out, \out, \i2
    eor2 \out, \out, \tmp
.endm

.macro move d s
    mov \d\().16b, \s\().16b
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

    rax1_m1 E1c, C0, C2                 SEP      save(E1c)
    rax1_m1 E3c, C2, C4                 SEP      save(E3c)
    rax1_m1 E0c, C4, C1                 SEP      save(E0c)
    rax1_m1 E2c, C1, C3                 SEP      save(E2c)
    rax1_m1 E4c, C3, C0                 SEP      save(E4c)

    xar_m1 vBgo, Ame /* used at block 3 */, E1c, 19
    xar_m1 vBgi, Aka /* used at block 2 */, E0c, 61
    xar_m1 vBga, Abo /* used at block 4 */, E3c, 36
    xar_m1 vBge, Agu /* used at block 1 */, E4c, 44
    xar_m1 vBgu, Asi /* used at block 5 */, E2c, 3

    bcax_m1 vEga, vBga, vBgi, vBge   SEP save(vEga) /* TEMP */
    bcax_m1 vEge, vBge, vBgo, vBgi
    bcax_m1 vEgi, vBgi, vBgu, vBgo   SEP save(vEgi) /* TEMP */
    bcax_m1 vEgo, vBgo, vBga, vBgu
    bcax_m1 vEgu, vBgu, vBge, vBga

                                                                        restore(E4u)
    xar_m1 vBko, Amu /* used at block 3 */, E4u, 56           SEP       restore(E1u)
    xar_m1 vBka, Abe /* used at block 4 */, E1u, 63           SEP       restore(E2u)
    xar_m1 vBke, Agi /* not used        */, E2u, 58           SEP       restore(E0u)
    xar_m1 vBku, Asa /* used at block 5 */, E0u, 46           SEP       restore(E3u)
    xar_m1 vBki, Ako /* used at block 2 */, E3u, 39

    bcax_m1 vEke, vBke, vBko, vBki  SEP save(vEke) /* TEMP */
    bcax_m1 vEki, vBki, vBku, vBko  SEP save(vEki) /* TEMP */
    bcax_m1 vEku, vBku, vBke, vBka
    bcax_m1 vEko, vBko, vBka, vBku
    bcax_m1 vEka, vBka, vBki, vBke

    // Can use: Abo, Asi, Abe, Asa; Abu, Aso
                                                              SEP      restore(E3u)
    xar_m1 vBmu, Aso /* used at block 5 */, E3u, 8            SEP      restore(E4u)
    xar_m1 vBma, Abu /* used at block 4 */, E4u, 37           SEP      restore(E2u)
    xar_m1 vBmo, Ami /* used at block 3 */, E2u, 49           SEP      restore(E1u)
    xar_m1 vBmi, Ake /* not used        */, E1u, 54           SEP      restore(E0u)
    xar_m1 vBme, Aga /* not used        */, E0u, 28

    bcax_m1 vEma, vBma, vBmi, vBme
    bcax_m1 vEmo, vBmo, vBma, vBmu
    bcax_m1 vEme, vBme, vBmo, vBmi
    bcax_m1 vEmi, vBmi, vBmu, vBmo
    bcax_m1 vEmu, vBmu, vBme, vBma

    // Can use: Asi, Asa, Aso, Asu, Amo
                                                                       restore(E0u)
    eor2   vBba, Aba /* used at block 4 */, E0u               SEP      restore(E2u)
    xar_m1 vBbi, Aki /* not used        */, E2u, 21           SEP      restore(E3u)
    xar_m1 vBbo, Amo /* not used        */, E3u, 43           SEP      restore(E4u)
    xar_m1 vBbu, Asu /* used at block 5 */, E4u, 50           SEP      restore(E1u)
    xar_m1 vBbe, Age /* not used        */, E1u, 20

    bcax_m1 vEba, vBba, vBbi, vBbe
    ld1r {tmp.2d}, [const_addr], #8
    eor2    vEba, vEba, tmp
    bcax_m1 vEbe, vBbe, vBbo, vBbi
    bcax_m1 vEbo, vBbo, vBba, vBbu
    bcax_m1 vEbu, vBbu, vBbe, vBba
    bcax_m1 vEbi, vBbi, vBbu, vBbo

    // Can use: Amo, Age, Abi, Ama, Ago, Aku
                                                                      restore(E2u)
    xar_m1 vBsa, Abi /* not used        */, E2u, 2           SEP      restore(E0u)
    xar_m1 vBso, Ama /* not used        */, E0u, 23          SEP      restore(E3u)
    xar_m1 vBse, Ago /* not used        */, E3u, 9           SEP      restore(E4u)
    xar_m1 vBsi, Aku /* not used        */, E4u, 25          SEP      restore(E1u)
    xar_m1 vBsu, Ase /* used at block 5 */, E1u, 62

    bcax_m1 vEsa, vBsa, vBsi, vBse
    bcax_m1 vEse, vBse, vBso, vBsi
    bcax_m1 vEsi, vBsi, vBsu, vBso
    bcax_m1 vEso, vBso, vBsa, vBsu
    bcax_m1 vEsu, vBsu, vBse, vBsa

    /* TODO: Unroll twice and arrange things so that after two iterations
             we end up at the same allocation of state registers? */

    /* New spare registers:
     * - Abi, Ama, Ago, Aku, Age, Amo */

    move Abi, vEbi
    move Ama, vEma
    move Ago, vEgo
    move Aku, vEku
    move Age, vEge
    move Amo, vEmo

    /* Overlapping registers
     * - Agi, Ake, Aga, Aki */
//    save(vEgi)
//    save(vEke)
//    save(vEga)
//    save(vEki)

    restore(Agi)
    restore(Ake)
    restore(Aga)
    restore(Aki)

    eor5 C0, Aka, Aga, Ama, Aba, Asa, tmp
    eor5 C2, Aki, Agi, Ami, Abi, Asi, tmp
    eor5 C4, Aku, Agu, Amu, Abu, Asu, tmp
    eor5 C1, Ake, Age, Ame, Abe, Ase, tmp
    eor5 C3, Ako, Ago, Amo, Abo, Aso, tmp

    // eor2 C3, Ako, Ago
    // eor2 C0, Aka, Aga
    // eor2 C1, Ake, Age
    // eor2 C2, Aki, Agi
    // eor2 C4, Aku, Agu

    // eor2 C0,  C0,  Ama
    // eor2 C1,  C1,  Ame
    // eor2 C2,  C2,  Ami
    // eor2 C3,  C3,  Amo
    // eor2 C4,  C4,  Amu

    // eor2 C0,  C0,  Aba
    // eor2 C1,  C1,  Abe
    // eor2 C2,  C2,  Abi
    // eor2 C3,  C3,  Abo
    // eor2 C4,  C4,  Abu

    // eor2 C0,  C0,  Asa
    // eor2 C1,  C1,  Ase
    // eor2 C2,  C2,  Asi
    // eor2 C3,  C3,  Aso
    // eor2 C4,  C4,  Asu

.endm

.macro keccak_f1600_round_post

    /* 5x RAX1, 15 Neon Instructions total */

    rax1_m1 E1c, C0, C2                 SEP      save(E1c)
    rax1_m1 E3c, C2, C4                 SEP      save(E3c)
    rax1_m1 E0c, C4, C1                 SEP      save(E0c)
    rax1_m1 E2c, C1, C3                 SEP      save(E2c)
    rax1_m1 E4c, C3, C0                 SEP      save(E4c)

    xar_m1 vBgo, Ame /* used at block 3 */, E1c, 19
    xar_m1 vBgi, Aka /* used at block 2 */, E0c, 61
    xar_m1 vBga, Abo /* used at block 4 */, E3c, 36
    xar_m1 vBge, Agu /* used at block 1 */, E4c, 44
    xar_m1 vBgu, Asi /* used at block 5 */, E2c, 3

    bcax_m1 vEga, vBga, vBgi, vBge   SEP save(vEga) /* TEMP */
    bcax_m1 vEge, vBge, vBgo, vBgi
    bcax_m1 vEgi, vBgi, vBgu, vBgo   SEP save(vEgi) /* TEMP */
    bcax_m1 vEgo, vBgo, vBga, vBgu
    bcax_m1 vEgu, vBgu, vBge, vBga

                                                                        restore(E4u)
    xar_m1 vBko, Amu /* used at block 3 */, E4u, 56           SEP       restore(E1u)
    xar_m1 vBka, Abe /* used at block 4 */, E1u, 63           SEP       restore(E2u)
    xar_m1 vBke, Agi /* not used        */, E2u, 58           SEP       restore(E0u)
    xar_m1 vBku, Asa /* used at block 5 */, E0u, 46           SEP       restore(E3u)
    xar_m1 vBki, Ako /* used at block 2 */, E3u, 39

    bcax_m1 vEke, vBke, vBko, vBki  SEP save(vEke) /* TEMP */
    bcax_m1 vEki, vBki, vBku, vBko  SEP save(vEki) /* TEMP */
    bcax_m1 vEku, vBku, vBke, vBka
    bcax_m1 vEko, vBko, vBka, vBku
    bcax_m1 vEka, vBka, vBki, vBke

    // Can use: Abo, Asi, Abe, Asa; Abu, Aso
                                                              SEP      restore(E3u)
    xar_m1 vBmu, Aso /* used at block 5 */, E3u, 8            SEP      restore(E4u)
    xar_m1 vBma, Abu /* used at block 4 */, E4u, 37           SEP      restore(E2u)
    xar_m1 vBmo, Ami /* used at block 3 */, E2u, 49           SEP      restore(E1u)
    xar_m1 vBmi, Ake /* not used        */, E1u, 54           SEP      restore(E0u)
    xar_m1 vBme, Aga /* not used        */, E0u, 28

    bcax_m1 vEma, vBma, vBmi, vBme
    bcax_m1 vEmo, vBmo, vBma, vBmu
    bcax_m1 vEme, vBme, vBmo, vBmi
    bcax_m1 vEmi, vBmi, vBmu, vBmo
    bcax_m1 vEmu, vBmu, vBme, vBma

    // Can use: Asi, Asa, Aso, Asu, Amo
                                                                       restore(E0u)
    eor2   vBba, Aba /* used at block 4 */, E0u               SEP      restore(E2u)
    xar_m1 vBbi, Aki /* not used        */, E2u, 21           SEP      restore(E3u)
    xar_m1 vBbo, Amo /* not used        */, E3u, 43           SEP      restore(E4u)
    xar_m1 vBbu, Asu /* used at block 5 */, E4u, 50           SEP      restore(E1u)
    xar_m1 vBbe, Age /* not used        */, E1u, 20

    bcax_m1 vEba, vBba, vBbi, vBbe
    ld1r {tmp.2d}, [const_addr], #8
    eor2    vEba, vEba, tmp
    bcax_m1 vEbe, vBbe, vBbo, vBbi
    bcax_m1 vEbo, vBbo, vBba, vBbu
    bcax_m1 vEbu, vBbu, vBbe, vBba
    bcax_m1 vEbi, vBbi, vBbu, vBbo

    // Can use: Amo, Age, Abi, Ama, Ago, Aku
                                                                      restore(E2u)
    xar_m1 vBsa, Abi /* not used        */, E2u, 2           SEP      restore(E0u)
    xar_m1 vBso, Ama /* not used        */, E0u, 23          SEP      restore(E3u)
    xar_m1 vBse, Ago /* not used        */, E3u, 9           SEP      restore(E4u)
    xar_m1 vBsi, Aku /* not used        */, E4u, 25          SEP      restore(E1u)
    xar_m1 vBsu, Ase /* used at block 5 */, E1u, 62

    bcax_m1 vEsa, vBsa, vBsi, vBse
    bcax_m1 vEse, vBse, vBso, vBsi
    bcax_m1 vEsi, vBsi, vBsu, vBso
    bcax_m1 vEso, vBso, vBsa, vBsu
    bcax_m1 vEsu, vBsu, vBse, vBsa

    /* TODO: Unroll twice and arrange things so that after two iterations
             we end up at the same allocation of state registers? */

    /* New spare registers:
     * - Abi, Ama, Ago, Aku, Age, Amo */

    move Abi, vEbi
    move Ama, vEma
    move Ago, vEgo
    move Aku, vEku
    move Age, vEge
    move Amo, vEmo

    /* Overlapping registers
     * - Agi, Ake, Aga, Aki */
//    save(vEgi)
//    save(vEke)
//    save(vEga)
//    save(vEki)

    restore(Agi)
    restore(Ake)
    restore(Aga)
    restore(Aki)

.endm


.text
.align 4
.global keccak_f1600_x2_v84a_asm_v2p3
.global _keccak_f1600_x2_v84a_asm_v2p3

#define KECCAK_F1600_ROUNDS 24

keccak_f1600_x2_v84a_asm_v2p3:
_keccak_f1600_x2_v84a_asm_v2p3:
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
