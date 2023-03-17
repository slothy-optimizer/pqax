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

#define ba_offset (5 + 0  )
#define be_offset (5 + 1  )
#define bi_offset (5 + 2  )
#define bo_offset (5 + 3  )
#define bu_offset (5 + 4  )
#define ga_offset (5 + 5  )
#define ge_offset (5 + 6  )
#define gi_offset (5 + 7  )
#define go_offset (5 + 8  )
#define gu_offset (5 + 9  )
#define ka_offset (5 + 10 )
#define ke_offset (5 + 11 )
#define ki_offset (5 + 12 )
#define ko_offset (5 + 13 )
#define ku_offset (5 + 14 )
#define ma_offset (5 + 15 )
#define me_offset (5 + 16 )
#define mi_offset (5 + 17 )
#define mo_offset (5 + 18 )
#define mu_offset (5 + 19 )
#define sa_offset (5 + 20 )
#define se_offset (5 + 21 )
#define si_offset (5 + 22 )
#define so_offset (5 + 23 )
#define su_offset (5 + 24 )

#define savep(reg, offset_prefix) \
    str reg ## q, [sp, #(STACK_BASE_TMP + 16 * offset_prefix ## _offset)]
#define restorep(reg, offset_prefix) \
    ldr reg ## q, [sp, #(STACK_BASE_TMP + 16 * offset_prefix ## _offset)]
#define save(name) savep(name,name)
#define restore(name) restorep(name,name)

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

    Aspare0  .req v25
    Aspare1  .req v26
    Aspare2  .req v27
    Aspare3  .req v28
    Aspare4  .req v29
    Aspare5  .req v30
    Aspare6  .req v31
    Aspare0q .req q25
    Aspare1q .req q26
    Aspare2q .req q27
    Aspare3q .req q28
    Aspare4q .req q29
    Aspare5q .req q30
    Aspare6q .req q31

.macro declare_remappings out,in
    tmp     .req \in\()spare6
    tmpq    .req \in\()spare6q

    \out\()gu .req \in\()gu      /* keep */
    \out\()ga .req \in\()spare0  /* out  */
    \out\()ge .req \in\()spare1  /* out  */
    \out\()gi .req \in\()spare2  /* out  */
    \out\()go .req \in\()spare3  /* out  */

    \out\()ka .req \in\()ka      /* keep */
    \out\()ko .req \in\()ko      /* keep */
    \out\()ke .req \in\()spare4  /* out  */
    \out\()ki .req \in\()spare5  /* out  */
    \out\()ku .req \in\()gi      /* in   */

    \out\()ma .req \in\()ke      /* in   */
    \out\()me .req \in\()me      /* keep */
    \out\()mi .req \in\()mi      /* keep */
    \out\()mo .req \in\()ga      /* in   */
    \out\()mu .req \in\()mu      /* keep */

    \out\()ba .req \in\()ba      /* keep */
    \out\()be .req \in\()be      /* keep */
    \out\()bi .req \in\()ki      /* in   */
    \out\()bo .req \in\()bo      /* keep */
    \out\()bu .req \in\()bu      /* keep */

    \out\()sa .req \in\()sa      /* keep */
    \out\()se .req \in\()se      /* keep */
    \out\()si .req \in\()si      /* keep */
    \out\()so .req \in\()so      /* keep */
    \out\()su .req \in\()su      /* keep */

    \out\()guq .req \in\()guq
    \out\()gaq .req \in\()spare0q
    \out\()geq .req \in\()spare1q
    \out\()giq .req \in\()spare2q
    \out\()goq .req \in\()spare3q

    \out\()kaq .req \in\()kaq
    \out\()koq .req \in\()koq
    \out\()keq .req \in\()spare4q
    \out\()kiq .req \in\()spare5q
    \out\()kuq .req \in\()giq

    \out\()maq .req \in\()keq
    \out\()meq .req \in\()meq
    \out\()miq .req \in\()miq
    \out\()moq .req \in\()gaq
    \out\()muq .req \in\()muq

    \out\()baq .req \in\()baq
    \out\()beq .req \in\()beq
    \out\()biq .req \in\()kiq
    \out\()boq .req \in\()boq
    \out\()buq .req \in\()buq

    \out\()saq .req \in\()saq
    \out\()seq .req \in\()seq
    \out\()siq .req \in\()siq
    \out\()soq .req \in\()soq
    \out\()suq .req \in\()suq

    \out\()spare0 .req \in\()bi
    \out\()spare1 .req \in\()ma
    \out\()spare2 .req \in\()go
    \out\()spare3 .req \in\()ku
    \out\()spare4 .req \in\()ge
    \out\()spare5 .req \in\()mo
    \out\()spare6 .req \in\()spare6
    \out\()spare0q .req \in\()biq
    \out\()spare1q .req \in\()maq
    \out\()spare2q .req \in\()goq
    \out\()spare3q .req \in\()kuq
    \out\()spare4q .req \in\()geq
    \out\()spare5q .req \in\()moq
    \out\()spare6q .req \in\()spare6q

    C0  .req \in\()spare0
    C1  .req \in\()spare1
    C2  .req \in\()spare2
    C3  .req \in\()spare3
    C4  .req \in\()spare4
    C0q .req \in\()spare0q
    C1q .req \in\()spare1q
    C2q .req \in\()spare2q
    C3q .req \in\()spare3q
    C4q .req \in\()spare4q

    E1c .req \in\()spare5
    E3c .req C2
    E0c .req C4
    E2c .req C1
    E4c .req C3

    E1cq .req \in\()spare5q
    E3cq .req C2q
    E0cq .req C4q
    E2cq .req C1q
    E4cq .req C3q

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
    vBgi .req \in\()me
    vBga .req \in\()ka
    vBge .req \in\()bo
    vBgu .req \in\()gu

    vBko .req \in\()me
    vBka .req \in\()mu
    vBke .req \in\()be
    vBku .req \in\()gi
    vBki .req \in\()sa

    vBmu .req \in\()bo
    vBmo .req \in\()so
    vBmi .req \in\()bu
    vBma .req \in\()si
    vBme .req \in\()be

    vBba .req \in\()si
    vBbi .req \in\()sa
    vBbo .req \in\()so
    vBbu .req \in\()mo
    vBbe .req \in\()su

    vBsa .req \in\()mo
    vBso .req \in\()bi
    vBse .req \in\()ma
    vBsi .req \in\()go
    vBsu .req \in\()ku
.endm

.macro transfer_uncommon out, in
    savep(\in\()ga, ga)
    savep(\in\()gi, gi)
    savep(\in\()ki, ki)
    savep(\in\()ke, ke)
    savep(\in\()bi, bi)
    savep(\in\()ma, ma)
    savep(\in\()go, go)
    savep(\in\()ku, ku)
    savep(\in\()ge, ge)
    savep(\in\()mo, mo)

    restorep(\out\()gi, gi)
    restorep(\out\()ke, ke)
    restorep(\out\()ga, ga)
    restorep(\out\()ki, ki)
    restorep(\out\()bi, bi)
    restorep(\out\()ma, ma)
    restorep(\out\()go, go)
    restorep(\out\()ku, ku)
    restorep(\out\()ge, ge)
    restorep(\out\()mo, mo)
.endm

.macro undeclare_remappings out, in
    .unreq vBgo
    .unreq vBgi
    .unreq vBga
    .unreq vBge
    .unreq vBgu
    .unreq vBko
    .unreq vBka
    .unreq vBke
    .unreq vBku
    .unreq vBki
    .unreq vBmu
    .unreq vBmo
    .unreq vBmi
    .unreq vBma
    .unreq vBme
    .unreq vBba
    .unreq vBbi
    .unreq vBbo
    .unreq vBbu
    .unreq vBbe
    .unreq vBsa
    .unreq vBso
    .unreq vBse
    .unreq vBsi
    .unreq vBsu
    .unreq C0
    .unreq C1
    .unreq C2
    .unreq C3
    .unreq C4
    .unreq C0q
    .unreq C1q
    .unreq C2q
    .unreq C3q
    .unreq C4q
    .unreq E1u
    .unreq E3u
    .unreq E0u
    .unreq E2u
    .unreq E4u
    .unreq E1c
    .unreq E3c
    .unreq E0c
    .unreq E2c
    .unreq E4c
    .unreq E1uq
    .unreq E3uq
    .unreq E0uq
    .unreq E2uq
    .unreq E4uq
    .unreq E1cq
    .unreq E3cq
    .unreq E0cq
    .unreq E2cq
    .unreq E4cq
.endm

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

.macro alloc_stack
   sub sp, sp, #(STACK_SIZE)
.endm

.macro free_stack
    add sp, sp, #(STACK_SIZE)
.endm

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

.macro eor3_m1_0 d, s0, s1, s2
    eor \d\().16b, \s0\().16b, \s1\().16b
.endm

.macro eor2 d, s0, s1
    eor \d\().16b, \s0\().16b, \s1\().16b
.endm

.macro move d, s
    mov \d\().16b, \s\().16b
.endm


.macro eor3_m1_1 d, s0, s1, s2
    eor \d\().16b, \d\().16b,  \s2\().16b
.endm

.macro eor3_m1 d, s0, s1, s2
    eor3_m1_0 \d, \s0, \s1, \s2
    eor3_m1_1 \d, \s0, \s1, \s2
.endm

.macro rax1_m1 d, s0, s1
   add tmp.2d, \s1\().2d, \s1\().2d
   sri tmp.2d, \s1\().2d, #63
   eor \d\().16b, tmp.16b, \s0\().16b
.endm

.macro xar_m1 d, s0, s1, imm
   eor \s0\().16b, \s0\().16b, \s1\().16b
   shl \d\().2d, \s0\().2d, #(64-\imm)
   sri \d\().2d, \s0\().2d, #(\imm)
.endm

.macro xar_m1_0 d, s0, s1, imm, tmp
   eor \tmp\().16b, \s0\().16b, \s1\().16b
.endm

.macro xar_m1_1 d, s0, s1, imm, tmp
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

.macro keccak_f1600_round_core out in

    eor2 C3, \in\()ko, \in\()go
    eor2 C0, \in\()ka, \in\()ga
    eor2 C1, \in\()ke, \in\()ge
    eor2 C2, \in\()ki, \in\()gi
    eor2 C4, \in\()ku, \in\()gu

    eor2 C0,  C0,  \in\()ma
    eor2 C1,  C1,  \in\()me
    eor2 C2,  C2,  \in\()mi
    eor2 C3,  C3,  \in\()mo
    eor2 C4,  C4,  \in\()mu

    eor2 C0,  C0,  \in\()ba
    eor2 C1,  C1,  \in\()be
    eor2 C2,  C2,  \in\()bi
    eor2 C3,  C3,  \in\()bo
    eor2 C4,  C4,  \in\()bu

    eor2 C0,  C0,  \in\()sa
    eor2 C1,  C1,  \in\()se
    eor2 C2,  C2,  \in\()si
    eor2 C3,  C3,  \in\()so
    eor2 C4,  C4,  \in\()su

    rax1_m1 E1c, C0, C2                 SEP      save(E1c)
    rax1_m1 E3c, C2, C4                 SEP      save(E3c)
    rax1_m1 E0c, C4, C1                 SEP      save(E0c)
    rax1_m1 E2c, C1, C3                 SEP      save(E2c)
    rax1_m1 E4c, C3, C0                 SEP      save(E4c)

    xar_m1 vBgo, \in\()me /* used at block 3 */, E1c, 19
    xar_m1 vBgi, \in\()ka /* used at block 2 */, E0c, 61
    xar_m1 vBga, \in\()bo /* used at block 4 */, E3c, 36
    xar_m1 vBge, \in\()gu /* used at block 1 */, E4c, 44
    xar_m1 vBgu, \in\()si /* used at block 5 */, E2c, 3

    bcax_m1 \out\()ga, vBga, vBgi, vBge
    bcax_m1 \out\()ge, vBge, vBgo, vBgi
    bcax_m1 \out\()gi, vBgi, vBgu, vBgo
    bcax_m1 \out\()go, vBgo, vBga, vBgu
    bcax_m1 \out\()gu, vBgu, vBge, vBga
                                                                             restore(E4u)
    xar_m1 vBko, \in\()mu /* used at block 3 */, E4u, 56           SEP       restore(E1u)
    xar_m1 vBka, \in\()be /* used at block 4 */, E1u, 63           SEP       restore(E2u)
    xar_m1 vBke, \in\()gi /* not used        */, E2u, 58           SEP       restore(E0u)
    xar_m1 vBku, \in\()sa /* used at block 5 */, E0u, 46           SEP       restore(E3u)
    xar_m1 vBki, \in\()ko /* used at block 2 */, E3u, 39

    bcax_m1 \out\()ke, vBke, vBko, vBki
    bcax_m1 \out\()ki, vBki, vBku, vBko
    bcax_m1 \out\()ku, vBku, vBke, vBka
    bcax_m1 \out\()ko, vBko, vBka, vBku
    bcax_m1 \out\()ka, vBka, vBki, vBke

    // Can use: Abo, Asi, Abe, Asa; Abu, Aso
                                                                            restore(E3u)
    xar_m1 vBmu, \in\()so /* used at block 5 */, E3u, 8            SEP      restore(E4u)
    xar_m1 vBma, \in\()bu /* used at block 4 */, E4u, 37           SEP      restore(E2u)
    xar_m1 vBmo, \in\()mi /* used at block 3 */, E2u, 49           SEP      restore(E1u)
    xar_m1 vBmi, \in\()ke /* not used        */, E1u, 54           SEP      restore(E0u)
    xar_m1 vBme, \in\()ga /* not used        */, E0u, 28

    bcax_m1 \out\()ma, vBma, vBmi, vBme
    bcax_m1 \out\()mo, vBmo, vBma, vBmu
    bcax_m1 \out\()me, vBme, vBmo, vBmi
    bcax_m1 \out\()mi, vBmi, vBmu, vBmo
    bcax_m1 \out\()mu, vBmu, vBme, vBma

    // Can use: Asi, Asa, Aso, Asu, Amo
                                                                            restore(E0u)
    eor2   vBba, \in\()ba /* used at block 4 */, E0u               SEP      restore(E2u)
    xar_m1 vBbi, \in\()ki /* not used        */, E2u, 21           SEP      restore(E3u)
    xar_m1 vBbo, \in\()mo /* not used        */, E3u, 43           SEP      restore(E4u)
    xar_m1 vBbu, \in\()su /* used at block 5 */, E4u, 50           SEP      restore(E1u)
    xar_m1 vBbe, \in\()ge /* not used        */, E1u, 20

    bcax_m1 \out\()ba, vBba, vBbi, vBbe
    ld1r {tmp.2d}, [const_addr], #8
    eor2    \out\()ba, \out\()ba, tmp
    bcax_m1 \out\()be, vBbe, vBbo, vBbi
    bcax_m1 \out\()bo, vBbo, vBba, vBbu
    bcax_m1 \out\()bu, vBbu, vBbe, vBba
    bcax_m1 \out\()bi, vBbi, vBbu, vBbo

    // Can use: Amo, Age, Abi, Ama, Ago, Aku
                                                                           restore(E2u)
    xar_m1 vBsa, \in\()bi /* not used        */, E2u, 2           SEP      restore(E0u)
    xar_m1 vBso, \in\()ma /* not used        */, E0u, 23          SEP      restore(E3u)
    xar_m1 vBse, \in\()go /* not used        */, E3u, 9           SEP      restore(E4u)
    xar_m1 vBsi, \in\()ku /* not used        */, E4u, 25          SEP      restore(E1u)
    xar_m1 vBsu, \in\()se /* used at block 5 */, E1u, 62

    bcax_m1 \out\()sa, vBsa, vBsi, vBse
    bcax_m1 \out\()se, vBse, vBso, vBsi
    bcax_m1 \out\()si, vBsi, vBsu, vBso
    bcax_m1 \out\()so, vBso, vBsa, vBsu
    bcax_m1 \out\()su, vBsu, vBse, vBsa

.endm

.text
.align 4
.global keccak_f1600_x2_v84a_asm_v2p4
.global _keccak_f1600_x2_v84a_asm_v2p4

#define KECCAK_F1600_ROUNDS 24

keccak_f1600_x2_v84a_asm_v2p4:
_keccak_f1600_x2_v84a_asm_v2p4:
    alloc_stack
    save_vregs
    load_constant_ptr
    load_input


    //mov count, #(KECCAK_F1600_ROUNDS-2)
    mov count, #24
loop:
    declare_remappings A1, A
    keccak_f1600_round_core A1, A
    undeclare_remappings A1, A

    declare_remappings A2, A1
    keccak_f1600_round_core A2, A1
    undeclare_remappings A2, A1

    declare_remappings A3, A2
    keccak_f1600_round_core A3, A2
    undeclare_remappings A3, A2

    declare_remappings A4, A3
    keccak_f1600_round_core A4, A3
    undeclare_remappings A4, A3

    transfer_uncommon A, A4

    sub count, count, #4
    cbnz count, loop


    store_input
    restore_vregs
    free_stack
    ret
