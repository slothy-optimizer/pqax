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
    Abe_ .req v27

    /* Unused temporary */
    tmp .req v31

/************************ MACROS ****************************/

.macro load_input
    ldr Abaq, [input_addr, #(2*8*0)]
    ldr Abeq, [input_addr, #(2*8*1)]
    ldr Abiq, [input_addr, #(2*8*2)]
    ldr Aboq, [input_addr, #(2*8*3)]
    ldr Abuq, [input_addr, #(2*8*4)]
    ldr Agaq, [input_addr, #(2*8*5)]
    ldr Ageq, [input_addr, #(2*8*6)]
    ldr Agiq, [input_addr, #(2*8*7)]
    ldr Agoq, [input_addr, #(2*8*8)]
    ldr Aguq, [input_addr, #(2*8*9)]
    ldr Akaq, [input_addr, #(2*8*10)]
    ldr Akeq, [input_addr, #(2*8*11)]
    ldr Akiq, [input_addr, #(2*8*12)]
    ldr Akoq, [input_addr, #(2*8*13)]
    ldr Akuq, [input_addr, #(2*8*14)]
    ldr Amaq, [input_addr, #(2*8*15)]
    ldr Ameq, [input_addr, #(2*8*16)]
    ldr Amiq, [input_addr, #(2*8*17)]
    ldr Amoq, [input_addr, #(2*8*18)]
    ldr Amuq, [input_addr, #(2*8*19)]
    ldr Asaq, [input_addr, #(2*8*20)]
    ldr Aseq, [input_addr, #(2*8*21)]
    ldr Asiq, [input_addr, #(2*8*22)]
    ldr Asoq, [input_addr, #(2*8*23)]
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

#define STACK_SIZE (16*4) // VREGS (16*4)
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

.macro eor3_m1 d s0 s1 s2
    eor \d\().16b, \s0\().16b, \s1\().16b
    eor \d\().16b, \d\().16b,  \s2\().16b
.endm

.macro rax1_m1 d s0 s1
   shl tmp.2d, \s1\().2d, #1
   sri tmp.2d, \s1\().2d, #63
   eor \d\().16b, tmp.16b, \s0\().16b
.endm

.macro xar_m1 d s0 s1 imm
   eor tmp.16b, \s0\().16b, \s1\().16b
   shl \d\().2d, tmp.2d, #(64-\imm)
   sri \d\().2d, tmp.2d, #(\imm)
.endm

.macro bcax_m1 d s0 s1 s2
    bic tmp.16b, \s1\().16b, \s2\().16b
    eor \d\().16b, tmp.16b, \s0\().16b
.endm

/* Keccak-f1600 round */

.macro keccak_f1600_round

    eor3_m1 C0, Aba, Aga, Aka
    eor3_m1 C0, C0, Ama,  Asa
    eor3_m1 C1, Abe, Age, Ake
    eor3_m1 C1, C1, Ame,  Ase
    eor3_m1 C2, Abi, Agi, Aki
    eor3_m1 C2, C2, Ami,  Asi
    eor3_m1 C3, Abo, Ago, Ako
    eor3_m1 C3, C3, Amo,  Aso
    eor3_m1 C4, Abu, Agu, Aku
    eor3_m1 C4, C4, Amu,  Asu

    rax1_m1 E1, C0, C2
    rax1_m1 E3, C2, C4
    rax1_m1 E0, C4, C1
    rax1_m1 E2, C1, C3
    rax1_m1 E4, C3, C0

    eor Aba_.16b, Aba.16b, E0.16b
    xar_m1 Asa_, Abi, E2, 2
    xar_m1 Abi_, Aki, E2, 21
    xar_m1 Aki_, Ako, E3, 39
    xar_m1 Ako_, Amu, E4, 56
    xar_m1 Amu_, Aso, E3, 8
    xar_m1 Aso_, Ama, E0, 23
    xar_m1 Aka_, Abe, E1, 63
    xar_m1 Ase_, Ago, E3, 9
    xar_m1 Ago_, Ame, E1, 19
    xar_m1 Ake_, Agi, E2, 58
    xar_m1 Agi_, Aka, E0, 61
    xar_m1 Aga_, Abo, E3, 36
    xar_m1 Abo_, Amo, E3, 43
    xar_m1 Amo_, Ami, E2, 49
    xar_m1 Ami_, Ake, E1, 54
    xar_m1 Age_, Agu, E4, 44
    xar_m1 Agu_, Asi, E2, 3
    xar_m1 Asi_, Aku, E4, 25
    xar_m1 Aku_, Asa, E0, 46
    xar_m1 Ama_, Abu, E4, 37
    xar_m1 Abu_, Asu, E4, 50
    xar_m1 Asu_, Ase, E1, 62
    xar_m1 Ame_, Aga, E0, 28
    xar_m1 Abe_, Age, E1, 20

    bcax_m1 Aga, Aga_, Agi_, Age_
    bcax_m1 Age, Age_, Ago_, Agi_
    bcax_m1 Agi, Agi_, Agu_, Ago_
    bcax_m1 Ago, Ago_, Aga_, Agu_
    bcax_m1 Agu, Agu_, Age_, Aga_
    bcax_m1 Aka, Aka_, Aki_, Ake_
    bcax_m1 Ake, Ake_, Ako_, Aki_
    bcax_m1 Aki, Aki_, Aku_, Ako_
    bcax_m1 Ako, Ako_, Aka_, Aku_
    bcax_m1 Aku, Aku_, Ake_, Aka_
    bcax_m1 Ama, Ama_, Ami_, Ame_
    bcax_m1 Ame, Ame_, Amo_, Ami_
    bcax_m1 Ami, Ami_, Amu_, Amo_
    bcax_m1 Amo, Amo_, Ama_, Amu_
    bcax_m1 Amu, Amu_, Ame_, Ama_
    bcax_m1 Asa, Asa_, Asi_, Ase_
    bcax_m1 Ase, Ase_, Aso_, Asi_
    bcax_m1 Asi, Asi_, Asu_, Aso_
    bcax_m1 Aso, Aso_, Asa_, Asu_
    bcax_m1 Asu, Asu_, Ase_, Asa_
    bcax_m1 Aba, Aba_, Abi_, Abe_
    bcax_m1 Abe, Abe_, Abo_, Abi_
    bcax_m1 Abi, Abi_, Abu_, Abo_
    bcax_m1 Abo, Abo_, Aba_, Abu_
    bcax_m1 Abu, Abu_, Abe_, Aba_

    // iota step
    ld1r {tmp.2d}, [const_addr], #8
    eor Aba.16b, Aba.16b, tmp.16b

.endm

#define KECCAK_F1600_ROUNDS 24

.text
.align 4
.global keccak_f1600_x2_v84a_asm_v2
.global _keccak_f1600_x2_v84a_asm_v2

keccak_f1600_x2_v84a_asm_v2:
_keccak_f1600_x2_v84a_asm_v2:
    alloc_stack
    save_vregs
    load_constant_ptr
    load_input

    mov count, #(KECCAK_F1600_ROUNDS)
loop:
    keccak_f1600_round
    sub count, count, #1
    cbnz count, loop

    store_input
    restore_vregs
    free_stack
    ret
