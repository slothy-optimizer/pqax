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
    .balign 64
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
    const_addr     .req x28
    count          .req x29
    cur_const      .req x30

    /* Mapping of Kecck-f1600 state to scalar registers
     * at the beginning and end of each round. */
    Aba     .req x1
    Abe     .req x6
    Abi     .req x11
    Abo     .req x16
    Abu     .req x21
    Aga     .req x2
    Age     .req x7
    Agi     .req x12
    Ago     .req x17
    Agu     .req x22
    Aka     .req x3
    Ake     .req x8
    Aki     .req x13
    Ako     .req x18
    Aku     .req x23
    Ama     .req x4
    Ame     .req x9
    Ami     .req x14
    Amo     .req x19
    Amu     .req x24
    Asa     .req x5
    Ase     .req x10
    Asi     .req x15
    Aso     .req x20
    Asu     .req x25

    /* A_[y,2*x+3*y] = rot(A[x,y]) */
    Aba_ .req x0
    Abe_ .req x28
    Abi_ .req x11
    Abo_ .req x16
    Abu_ .req x21
    Aga_ .req x3
    Age_ .req x8
    Agi_ .req x12
    Ago_ .req x17
    Agu_ .req x22
    Aka_ .req x4
    Ake_ .req x9
    Aki_ .req x13
    Ako_ .req x18
    Aku_ .req x23
    Ama_ .req x5
    Ame_ .req x10
    Ami_ .req x14
    Amo_ .req x19
    Amu_ .req x24
    Asa_ .req x1
    Ase_ .req x6
    Asi_ .req x15
    Aso_ .req x20
    Asu_ .req x25

    /* C[x] = A[x,0] xor A[x,1] xor A[x,2] xor A[x,3] xor A[x,4],   for x in 0..4 */
    /* E[x] = C[x-1] xor rot(C[x+1],1), for x in 0..4 */
    C0 .req x0
    E0 .req x29
    C1 .req x26
    E1 .req x30
    C2 .req x27
    E2 .req x26
    C3 .req x28
    E3 .req x27
    C4 .req x29
    E4 .req x28

    tmp .req x30

/************************ MACROS ****************************/

.macro load_input
    ldr Aba, [input_addr, #(1*8*0)]
    ldr Abe, [input_addr, #(1*8*1)]
    ldr Abi, [input_addr, #(1*8*2)]
    ldr Abo, [input_addr, #(1*8*3)]
    ldr Abu, [input_addr, #(1*8*4)]
    ldr Aga, [input_addr, #(1*8*5)]
    ldr Age, [input_addr, #(1*8*6)]
    ldr Agi, [input_addr, #(1*8*7)]
    ldr Ago, [input_addr, #(1*8*8)]
    ldr Agu, [input_addr, #(1*8*9)]
    ldr Aka, [input_addr, #(1*8*10)]
    ldr Ake, [input_addr, #(1*8*11)]
    ldr Aki, [input_addr, #(1*8*12)]
    ldr Ako, [input_addr, #(1*8*13)]
    ldr Aku, [input_addr, #(1*8*14)]
    ldr Ama, [input_addr, #(1*8*15)]
    ldr Ame, [input_addr, #(1*8*16)]
    ldr Ami, [input_addr, #(1*8*17)]
    ldr Amo, [input_addr, #(1*8*18)]
    ldr Amu, [input_addr, #(1*8*19)]
    ldr Asa, [input_addr, #(1*8*20)]
    ldr Ase, [input_addr, #(1*8*21)]
    ldr Asi, [input_addr, #(1*8*22)]
    ldr Aso, [input_addr, #(1*8*23)]
    ldr Asu, [input_addr, #(1*8*24)]
.endm

.macro store_input
    str Aba, [input_addr, #(1*8*0)]
    str Abe, [input_addr, #(1*8*1)]
    str Abi, [input_addr, #(1*8*2)]
    str Abo, [input_addr, #(1*8*3)]
    str Abu, [input_addr, #(1*8*4)]
    str Aga, [input_addr, #(1*8*5)]
    str Age, [input_addr, #(1*8*6)]
    str Agi, [input_addr, #(1*8*7)]
    str Ago, [input_addr, #(1*8*8)]
    str Agu, [input_addr, #(1*8*9)]
    str Aka, [input_addr, #(1*8*10)]
    str Ake, [input_addr, #(1*8*11)]
    str Aki, [input_addr, #(1*8*12)]
    str Ako, [input_addr, #(1*8*13)]
    str Aku, [input_addr, #(1*8*14)]
    str Ama, [input_addr, #(1*8*15)]
    str Ame, [input_addr, #(1*8*16)]
    str Ami, [input_addr, #(1*8*17)]
    str Amo, [input_addr, #(1*8*18)]
    str Amu, [input_addr, #(1*8*19)]
    str Asa, [input_addr, #(1*8*20)]
    str Ase, [input_addr, #(1*8*21)]
    str Asi, [input_addr, #(1*8*22)]
    str Aso, [input_addr, #(1*8*23)]
    str Asu, [input_addr, #(1*8*24)]
.endm

#define STACK_SIZE (16*6 + 3*8 + 8) // GPRs (16*6), count (8), const (8), input (8), padding (8)
#define STACK_BASE_GPRS (3*8+8)
#define STACK_OFFSET_INPUT (0*8)
#define STACK_OFFSET_CONST (1*8)
#define STACK_OFFSET_COUNT (2*8)

.macro alloc_stack
    sub sp, sp, #(STACK_SIZE)
.endm

.macro free_stack
    add sp, sp, #(STACK_SIZE)
.endm

.macro save reg, offset
    str \reg, [sp, #\offset]
.endm

.macro restore reg, offset
    ldr \reg, [sp, #\offset]
.endm

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

/* Keccak-f1600 round */

.macro keccak_f1600_round
    save count, STACK_OFFSET_COUNT

eor C0, Aba, Aga
eor C0, C0,  Aka
eor C0, C0,  Ama
eor C0, C0,  Asa
eor C1, Abe, Age
eor C1, C1,  Ake
eor C1, C1,  Ame
eor C1, C1,  Ase
eor C2, Abi, Agi
eor C2, C2,  Aki
eor C2, C2,  Ami
eor C2, C2,  Asi
eor C3, Abo, Ago
eor C3, C3,  Ako
eor C3, C3,  Amo
eor C3, C3,  Aso
eor C4, Abu, Agu
eor C4, C4,  Aku
eor C4, C4,  Amu
eor C4, C4,  Asu


eor E1, C0, C2, ROR #63
eor E3, C2, C4, ROR #63
eor E0, C4, C1, ROR #63
eor E2, C1, C3, ROR #63
eor E4, C3, C0, ROR #63

eor Aba_, Aba, E0
eor Asa_, Abi, E2
ror Asa_, Asa_, #2
eor Abi_, Aki, E2
ror Abi_, Abi_, #21
eor Aki_, Ako, E3
ror Aki_, Aki_, #39
eor Ako_, Amu, E4
ror Ako_, Ako_, #56
eor Amu_, Aso, E3
ror Amu_, Amu_, #8
eor Aso_, Ama, E0
ror Aso_, Aso_, #23
eor Aka_, Abe, E1
ror Aka_, Aka_, #63
eor Ase_, Ago, E3
ror Ase_, Ase_, #9
eor Ago_, Ame, E1
ror Ago_, Ago_, #19
eor Ake_, Agi, E2
ror Ake_, Ake_, #58
eor Agi_, Aka, E0
ror Agi_, Agi_, #61
eor Aga_, Abo, E3
ror Aga_, Aga_, #36
eor Abo_, Amo, E3
ror Abo_, Abo_, #43
eor Amo_, Ami, E2
ror Amo_, Amo_, #49
eor Ami_, Ake, E1
ror Ami_, Ami_, #54
eor Age_, Agu, E4
ror Age_, Age_, #44
eor Agu_, Asi, E2
ror Agu_, Agu_, #3
eor Asi_, Aku, E4
ror Asi_, Asi_, #25
eor Aku_, Asa, E0
ror Aku_, Aku_, #46
eor Ama_, Abu, E4
ror Ama_, Ama_, #37
eor Abu_, Asu, E4
ror Abu_, Abu_, #50
eor Asu_, Ase, E1
ror Asu_, Asu_, #62
eor Ame_, Aga, E0
ror Ame_, Ame_, #28

eor Abe_, Age, E1
ror Abe_, Abe_, #20

// xi step
// Row 1
bic tmp, Agi_, Age_
eor Aga, tmp,  Aga_
bic tmp, Ago_, Agi_
eor Age, tmp,  Age_
bic tmp, Agu_, Ago_
eor Agi, tmp,  Agi_
bic tmp, Aga_, Agu_
eor Ago, tmp,  Ago_
bic tmp, Age_, Aga_
eor Agu, tmp,  Agu_
// Row 2
bic tmp, Aki_, Ake_
eor Aka, tmp,  Aka_
bic tmp, Ako_, Aki_
eor Ake, tmp,  Ake_
bic tmp, Aku_, Ako_
eor Aki, tmp,  Aki_
bic tmp, Aka_, Aku_
eor Ako, tmp,  Ako_
bic tmp, Ake_, Aka_
eor Aku, tmp,  Aku_
// Row 3
bic tmp, Ami_, Ame_
eor Ama, tmp,  Ama_
bic tmp, Amo_, Ami_
eor Ame, tmp,  Ame_
bic tmp, Amu_, Amo_
eor Ami, tmp,  Ami_
bic tmp, Ama_, Amu_
eor Amo, tmp,  Amo_
bic tmp, Ame_, Ama_
eor Amu, tmp,  Amu_
// Row 4
bic tmp, Asi_, Ase_
eor Asa, tmp,  Asa_
bic tmp, Aso_, Asi_
eor Ase, tmp,  Ase_
bic tmp, Asu_, Aso_
eor Asi, tmp,  Asi_
bic tmp, Asa_, Asu_
eor Aso, tmp,  Aso_
bic tmp, Ase_, Asa_
eor Asu, tmp,  Asu_
// Row 0
bic tmp, Abi_, Abe_
eor Aba, tmp,  Aba_
bic tmp, Abo_, Abi_
eor Abe, tmp,  Abe_
bic tmp, Abu_, Abo_
eor Abi, tmp,  Abi_
bic tmp, Aba_, Abu_
eor Abo, tmp,  Abo_
bic tmp, Abe_, Aba_
eor Abu, tmp,  Abu_

    restore const_addr, STACK_OFFSET_CONST
    ldr cur_const, [const_addr], #8
    eor Aba, Aba, cur_const
    save const_addr, STACK_OFFSET_CONST

    restore count, STACK_OFFSET_COUNT
.endm

#define KECCAK_F1600_ROUNDS 24

.text
.balign 16
.global keccak_f1600_x1_scalar_asm_v1
.global _keccak_f1600_x1_scalar_asm_v1	

keccak_f1600_x1_scalar_asm_v1:
_keccak_f1600_x1_scalar_asm_v1:	
    alloc_stack
    save_gprs
    load_constant_ptr
    save const_addr, STACK_OFFSET_CONST
    load_input
    save input_addr, STACK_OFFSET_INPUT

    mov count, #0
loop:
    keccak_f1600_round
    add count, count, #1
    cmp count, #(KECCAK_F1600_ROUNDS-1)
    ble loop

    restore input_addr, STACK_OFFSET_INPUT
    store_input
    restore_gprs
    free_stack
    ret
