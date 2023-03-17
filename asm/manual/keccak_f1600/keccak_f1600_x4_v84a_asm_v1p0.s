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

/****************** REGISTER ALLOCATIONS *******************/

    input_addr     .req x0
    const_addr     .req x1
    count          .req x2
    cur_const      .req x3
    out_count      .req x4

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

    Abaz    .req z0
    Abez    .req z1
    Abiz    .req z2
    Aboz    .req z3
    Abuz    .req z4
    Agaz    .req z5
    Agez    .req z6
    Agiz    .req z7
    Agoz    .req z8
    Aguz    .req z9
    Akaz    .req z10
    Akez    .req z11
    Akiz    .req z12
    Akoz    .req z13
    Akuz    .req z14
    Amaz    .req z15
    Amez    .req z16
    Amiz    .req z17
    Amoz    .req z18
    Amuz    .req z19
    Asaz    .req z20
    Asez    .req z21
    Asiz    .req z22
    Asoz    .req z23
    Asuz    .req z24

    /* C[x] = A[x,0] xor A[x,1] xor A[x,2] xor A[x,3] xor A[x,4],   for x in 0..4 */
    C0 .req v25
    C1 .req v26
    C2 .req v27
    C3 .req v28
    C4 .req v29

    /* E[x] = C[x-1] xor rot(C[x+1],1), for x in 0..4 */
    E0 .req C4
    E1 .req C0
    E2 .req C1
    E3 .req C2
    E4 .req C3

    /* A_[y,2*x+3*y] = rot(A[x,y]) */
    Abi_ .req v2
    Abo_ .req v3
    Abu_ .req v4
    Aga_ .req v10
    Age_ .req v11
    Agi_ .req v7
    Ago_ .req v8
    Agu_ .req v9
    Aka_ .req v15
    Ake_ .req v16
    Aki_ .req v12
    Ako_ .req v13
    Aku_ .req v14
    Ama_ .req v20
    Ame_ .req v21
    Ami_ .req v17
    Amo_ .req v18
    Amu_ .req v19
    Asa_ .req v0
    Ase_ .req v1
    Asi_ .req v22
    Aso_ .req v23
    Asu_ .req v24
    Aba_ .req v30
    Abe_ .req E0

/************************ MACROS ****************************/

.macro load_input
    ldr Abaq, [input_addr, #(4*8*0)]
    ldr Abeq, [input_addr, #(4*8*1)]
    ldr Abiq, [input_addr, #(4*8*2)]
    ldr Aboq, [input_addr, #(4*8*3)]
    ldr Abuq, [input_addr, #(4*8*4)]
    ldr Agaq, [input_addr, #(4*8*5)]
    ldr Ageq, [input_addr, #(4*8*6)]
    ldr Agiq, [input_addr, #(4*8*7)]
    ldr Agoq, [input_addr, #(4*8*8)]
    ldr Aguq, [input_addr, #(4*8*9)]
    ldr Akaq, [input_addr, #(4*8*10)]
    ldr Akeq, [input_addr, #(4*8*11)]
    ldr Akiq, [input_addr, #(4*8*12)]
    ldr Akoq, [input_addr, #(4*8*13)]
    ldr Akuq, [input_addr, #(4*8*14)]
    ldr Amaq, [input_addr, #(4*8*15)]
    ldr Ameq, [input_addr, #(4*8*16)]
    ldr Amiq, [input_addr, #(4*8*17)]
    ldr Amoq, [input_addr, #(4*8*18)]
    ldr Amuq, [input_addr, #(4*8*19)]
    ldr Asaq, [input_addr, #(4*8*20)]
    ldr Aseq, [input_addr, #(4*8*21)]
    ldr Asiq, [input_addr, #(4*8*22)]
    ldr Asoq, [input_addr, #(4*8*23)]
    ldr Asuq, [input_addr, #(4*8*24)]
.endm

.macro store_input
    str Abaq, [input_addr, #(4*8*0)]
    str Abeq, [input_addr, #(4*8*1)]
    str Abiq, [input_addr, #(4*8*2)]
    str Aboq, [input_addr, #(4*8*3)]
    str Abuq, [input_addr, #(4*8*4)]
    str Agaq, [input_addr, #(4*8*5)]
    str Ageq, [input_addr, #(4*8*6)]
    str Agiq, [input_addr, #(4*8*7)]
    str Agoq, [input_addr, #(4*8*8)]
    str Aguq, [input_addr, #(4*8*9)]
    str Akaq, [input_addr, #(4*8*10)]
    str Akeq, [input_addr, #(4*8*11)]
    str Akiq, [input_addr, #(4*8*12)]
    str Akoq, [input_addr, #(4*8*13)]
    str Akuq, [input_addr, #(4*8*14)]
    str Amaq, [input_addr, #(4*8*15)]
    str Ameq, [input_addr, #(4*8*16)]
    str Amiq, [input_addr, #(4*8*17)]
    str Amoq, [input_addr, #(4*8*18)]
    str Amuq, [input_addr, #(4*8*19)]
    str Asaq, [input_addr, #(4*8*20)]
    str Aseq, [input_addr, #(4*8*21)]
    str Asiq, [input_addr, #(4*8*22)]
    str Asoq, [input_addr, #(4*8*23)]
    str Asuq, [input_addr, #(4*8*24)]
.endm

#define STACK_SIZE (16*4 + 16*6 + 16*5) // VREGS (16*4) + GPRS (TODO: Remove)

#define STACK_BASE_GPRS (16*4)
#define STACK_BASE_VTMP (16*4 + 16*6)

#define save(name)\
    str name ## q, [sp, #(STACK_BASE_VTMP + 16*(name ## _offset))]
#define restore(name) \
    ldr name ## q, [sp, #(STACK_BASE_VTMP + 16*(name ## _offset))]

#define Aga_offset 0
#define Age_offset 1
#define Agi_offset 2
#define Ago_offset 3
#define Agu_offset 4

.macro alloc_stack
    sub sp, sp, #(STACK_SIZE)
.endm

.macro free_stack
    add sp, sp, #(STACK_SIZE)
.endm

.macro save_vregs
    stp  d8,  d9, [sp, #(16*0)]
    stp d10, d11, [sp, #(16*1)]
    stp d12, d13, [sp, #(16*2)]
    stp d14, d15, [sp, #(16*3)]
.endm

.macro restore_vregs
    ldp  d8,  d9, [sp, #(16*0)]
    ldp d10, d11, [sp, #(16*1)]
    ldp d12, d13, [sp, #(16*2)]
    ldp d14, d15, [sp, #(16*3)]
.endm

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

.macro bcax_m2 d s0 s1 s2
    bcax \d\()z.d, \s0\()z.d, \s1\()z.d, \s2\()z.d
.endm

/* Keccak-f1600 round */

.macro keccak_f1600_round

    eor3_m0 C2, Ami, Agi, Aki
    eor3_m0 C0, Ama, Aga, Aka
    eor3_m0 C1, Ame, Age, Ake
    eor3_m0 C3, Amo, Ago, Ako
    eor3_m0 C4, Asu, Agu, Aku

    vzr .req v31
    movi vzr.2d, #0

    eor3_m0 C2, C2, Abi, Asi
    save(Agi) SEP  C1r .req Agi
    eor3_m0 C0, C0, Aba, Asa
    eor3_m0 C1, C1, Abe, Ase
    save(Agu) SEP  C3r .req Agu
    eor3_m0 C3, C3, Abo, Aso
    eor3_m0 C4, C4, Amu, Abu

    save(Ago) SEP  C2r .req Ago
    xar_m0 C1r, vzr, C1, 63
    xar_m0 C3r, vzr, C3, 63
    save(Aga) SEP  C4r .req Aga
    xar_m0 C2r, vzr, C2, 63
    xar_m0 C4r, vzr, C4, 63
    save(Age) SEP  C0r .req Age
    eor2   E0, C4, C1r
    xar_m0 C0r, vzr, C0, 63
    eor2   E2, C1, C3r
    eor2   E1, C0, C2r
    restore(Agu) // C3r
    eor2   E3, C2, C4r
    eor2   E4, C3, C0r
    restore(Ago) // C2r
    restore(Agi) // C1r/Cor

    eor Aba_.16b, Aba.16b, E0.16b
    xar_m0 Asa_, Abi, E2, 2
    restore(Aga) // C4r
    xar_m0 Abi_, Aki, E2, 21
    xar_m0 Aki_, Ako, E3, 39
    restore(Age) // C0r
    xar_m0 Ako_, Amu, E4, 56
    xar_m0 Amu_, Aso, E3, 8
    xar_m0 Aso_, Ama, E0, 23
    xar_m0 Aka_, Abe, E1, 63
    xar_m0 Ase_, Ago, E3, 9
    xar_m0 Ago_, Ame, E1, 19
    xar_m0 Ake_, Agi, E2, 58
    xar_m0 Agi_, Aka, E0, 61
    xar_m0 Aga_, Abo, E3, 36
    xar_m0 Abo_, Amo, E3, 43
    xar_m0 Amo_, Ami, E2, 49
    xar_m0 Ami_, Ake, E1, 54
    xar_m0 Age_, Agu, E4, 44
    xar_m0 Agu_, Asi, E2, 3
    xar_m0 Asi_, Aku, E4, 25
    xar_m0 Aku_, Asa, E0, 46
    xar_m0 Ama_, Abu, E4, 37
    xar_m0 Abu_, Asu, E4, 50
    xar_m0 Asu_, Ase, E1, 62
    xar_m0 Ame_, Aga, E0, 28
    xar_m0 Abe_, Age, E1, 20

    ld1r {v31.2d}, [const_addr], #8

    bcax_m0 Aga, Aga_, Agi_, Age_
    bcax_m0 Age, Age_, Ago_, Agi_
    bcax_m0 Agi, Agi_, Agu_, Ago_
    bcax_m0 Ago, Ago_, Aga_, Agu_
    bcax_m0 Agu, Agu_, Age_, Aga_
    bcax_m0 Aka, Aka_, Aki_, Ake_
    bcax_m0 Ake, Ake_, Ako_, Aki_
    bcax_m0 Aki, Aki_, Aku_, Ako_
    bcax_m0 Ako, Ako_, Aka_, Aku_
    bcax_m0 Aku, Aku_, Ake_, Aka_
    bcax_m0 Ama, Ama_, Ami_, Ame_
    bcax_m0 Ame, Ame_, Amo_, Ami_
    bcax_m0 Ami, Ami_, Amu_, Amo_
    bcax_m0 Amo, Amo_, Ama_, Amu_
    bcax_m0 Amu, Amu_, Ame_, Ama_
    bcax_m0 Asa, Asa_, Asi_, Ase_
    bcax_m0 Ase, Ase_, Aso_, Asi_
    bcax_m0 Asi, Asi_, Asu_, Aso_
    bcax_m0 Aso, Aso_, Asa_, Asu_
    bcax_m0 Asu, Asu_, Ase_, Asa_
    bcax_m0 Aba, Aba_, Abi_, Abe_
    bcax_m0 Abe, Abe_, Abo_, Abi_
    bcax_m0 Abi, Abi_, Abu_, Abo_
    bcax_m0 Abo, Abo_, Aba_, Abu_
    bcax_m0 Abu, Abu_, Abe_, Aba_

    // iota step
    eor Aba.16b, Aba.16b, v31.16b

.endm

#define KECCAK_F1600_ROUNDS 24

.text
.align 4
.global keccak_f1600_x4_v84a_asm_v1p0
.global _keccak_f1600_x4_v84a_asm_v1p0

keccak_f1600_x4_v84a_asm_v1p0:
_keccak_f1600_x4_v84a_asm_v1p0:
    alloc_stack
    save_vregs

    mov out_count, #2
1:
    load_constant_ptr
    load_input
    mov count, #(KECCAK_F1600_ROUNDS)
2:
    keccak_f1600_round
    sub count, count, #1
    cbnz count, 2b

    store_input
    add input_addr, input_addr, #16

    sub out_count, out_count, #1
    cbnz out_count, 1b

    restore_vregs
    free_stack
    ret

#endif
