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
    const_addr     .req x26
    cur_const      .req x26
    count          .req w27
    out_count      .req w27

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
    Aba_ .req x30
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
    C0 .req x30
    E0 .req x29
    C1 .req x26
    E1 .req x0
    C2 .req x27
    E2 .req x26
    C3 .req x28
    E3 .req x27
    C4 .req x29
    E4 .req x28

    tmp .req x0

/************************ MACROS ****************************/

#define STACK_SIZE (16*6 + 3*8 + 8) // GPRs (16*6), count (8), const (8), input (8), padding (8)
#define STACK_BASE_GPRS (3*8+8)
#define STACK_OFFSET_INPUT (0*8)
#define STACK_OFFSET_CONST (1*8)
#define STACK_OFFSET_COUNT (2*8)
#define STACK_OFFSET_OUTCOUNT (3*8)

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

.macro keccak_f1600_round_initial
    ldr Aku, [input_addr, 8*(4*(14)  )]
    ldr Ama, [input_addr, 8*(4*(14+1))]
    ldr Asa, [input_addr, 8*(4*(20)  )]
    ldr Ase, [input_addr, 8*(4*(20+1))]
    eor C0, Ama, Asa
    ldr Ame, [input_addr, 8*(4*(16)  )]
    ldr Ami, [input_addr, 8*(4*(16+1))]
    eor C1, Ame, Ase
    ldr Asi, [input_addr, 8*(4*(22)  )]
    ldr Aso, [input_addr, 8*(4*(22+1))]
    eor C2, Ami, Asi
    ldr Amo, [input_addr, 8*(4*(18)  )]
    ldr Amu, [input_addr, 8*(4*(18+1))]
    eor C3, Amo, Aso
    ldr Asu,      [input_addr, #(4*8*24)]
    eor C4, Amu, Asu
    ldr Aka, [input_addr, 8*(4*(10)  )]
    ldr Ake, [input_addr, 8*(4*(10+1))]
    eor C0, Aka, C0
    eor C1, Ake, C1
    ldr Aki, [input_addr, 8*(4*(12)  )]
    ldr Ako, [input_addr, 8*(4*(12+1))]
    eor C2, Aki, C2
    ldr Abu, [input_addr, 8*(4*(4))]
    ldr Aga, [input_addr, 8*(4*(4+1) )]
    eor C3, Ako, C3
    eor C4, Aku, C4
    ldr Age, [input_addr, 8*(4*(6))]
    ldr Agi, [input_addr, 8*(4*(6+1) )]
    eor C0, Aga, C0
    ldr Ago, [input_addr, 8*(4*(8))]
    ldr Agu, [input_addr, 8*(4*(8+1) )]
    eor C1, Age, C1
    ldr Aba, [input_addr, 8*(4*(0)  )]
    ldr Abe, [input_addr, 8*(4*(0+1) )]
    eor C2, Agi, C2
    ldr Abi, [input_addr, 8*(4*(2))]
    ldr Abo, [input_addr, 8*(4*(2+1) )]
    eor C3, Ago, C3
    save input_addr, STACK_OFFSET_INPUT
    eor C4, Agu, C4
    eor C0, Aba, C0
    eor C1, Abe, C1
    eor C2, Abi, C2
    eor C3, Abo, C3
    eor C4, Abu, C4

    eor E1, C0, C2, ROR #63
    eor E3, C2, C4, ROR #63
    eor E0, C4, C1, ROR #63
    eor E2, C1, C3, ROR #63
    eor E4, C3, C0, ROR #63

    eor Aba_, Aba, E0
    eor Asa_, Abi, E2
    eor Abi_, Aki, E2
    eor Aki_, Ako, E3
    eor Ako_, Amu, E4
    eor Amu_, Aso, E3
    eor Aso_, Ama, E0
    eor Aka_, Abe, E1
    eor Ase_, Ago, E3
    eor Ago_, Ame, E1
    eor Ake_, Agi, E2
    eor Agi_, Aka, E0
    eor Aga_, Abo, E3
    eor Abo_, Amo, E3
    eor Amo_, Ami, E2
    eor Ami_, Ake, E1
    eor Age_, Agu, E4
    eor Agu_, Asi, E2
    eor Asi_, Aku, E4
    eor Aku_, Asa, E0
    eor Ama_, Abu, E4
    eor Abu_, Asu, E4
    eor Asu_, Ase, E1
    eor Ame_, Aga, E0
    eor Abe_, Age, E1

    load_constant_ptr

    tmp0 .req x0
    tmp1 .req x29

    bic tmp0, Agi_, Age_, ROR #47
    bic tmp1, Ago_, Agi_, ROR #42
    eor Aga, tmp0,  Aga_, ROR #39
    bic tmp0, Agu_, Ago_, ROR #16
    eor Age, tmp1,  Age_, ROR #25
    bic tmp1, Aga_, Agu_, ROR #31
    eor Agi, tmp0,  Agi_, ROR #58
    bic tmp0, Age_, Aga_, ROR #56
    eor Ago, tmp1,  Ago_, ROR #47
    bic tmp1, Aki_, Ake_, ROR #19
    eor Agu, tmp0,  Agu_, ROR #23
    bic tmp0, Ako_, Aki_, ROR #47
    eor Aka, tmp1,  Aka_, ROR #24
    bic tmp1, Aku_, Ako_, ROR #10
    eor Ake, tmp0,  Ake_, ROR #2
    bic tmp0, Aka_, Aku_, ROR #47
    eor Aki, tmp1,  Aki_, ROR #57
    bic tmp1, Ake_, Aka_, ROR #5
    eor Ako, tmp0,  Ako_, ROR #57
    bic tmp0, Ami_, Ame_, ROR #38
    eor Aku, tmp1,  Aku_, ROR #52
    bic tmp1, Amo_, Ami_, ROR #5
    eor Ama, tmp0,  Ama_, ROR #47
    bic tmp0, Amu_, Amo_, ROR #41
    eor Ame, tmp1,  Ame_, ROR #43
    bic tmp1, Ama_, Amu_, ROR #35
    eor Ami, tmp0,  Ami_, ROR #46
    bic tmp0, Ame_, Ama_, ROR #9

    str const_addr, [sp, #(STACK_OFFSET_CONST)]
    ldr cur_const, [const_addr]

    eor Amo, tmp1,  Amo_, ROR #12
    bic tmp1, Asi_, Ase_, ROR #48
    eor Amu, tmp0,  Amu_, ROR #44
    bic tmp0, Aso_, Asi_, ROR #2
    eor Asa, tmp1,  Asa_, ROR #41
    bic tmp1, Asu_, Aso_, ROR #25
    eor Ase, tmp0,  Ase_, ROR #50
    bic tmp0, Asa_, Asu_, ROR #60
    eor Asi, tmp1,  Asi_, ROR #27
    bic tmp1, Ase_, Asa_, ROR #57
    eor Aso, tmp0,  Aso_, ROR #21

    mov count, #1

    bic tmp0, Abi_, Abe_, ROR #63
    eor Asu, tmp1,  Asu_, ROR #53
    bic tmp1, Abo_, Abi_, ROR #42
    eor Aba, Aba_, tmp0,  ROR #21
    bic tmp0, Abu_, Abo_, ROR #57
    eor Abe, tmp1,  Abe_, ROR #41
    bic tmp1, Aba_, Abu_, ROR #50
    eor Abi, tmp0,  Abi_, ROR #35
    bic tmp0, Abe_, Aba_, ROR #44
    eor Abo, tmp1,  Abo_, ROR #43
    eor Abu, tmp0,  Abu_, ROR #30

    eor Aba, Aba, cur_const
    save count, STACK_OFFSET_COUNT

.endm


.macro keccak_f1600_round_noninitial

    eor C2, Asi, Abi, ROR #52
    eor C0, Aba, Aga, ROR #61
    eor C4, Aku, Agu, ROR #50
    eor C1, Ake, Ame, ROR #57
    eor C3, Abo, Ako, ROR #63
    eor C2, C2, Aki, ROR #48
    eor C0, C0, Ama, ROR #54
    eor C4, C4, Amu, ROR #34
    eor C1, C1, Abe, ROR #51
    eor C3, C3, Amo, ROR #37
    eor C2, C2, Ami, ROR #10
    eor C0, C0, Aka, ROR #39
    eor C4, C4, Abu, ROR #26
    eor C1, C1, Ase, ROR #31
    eor C3, C3, Ago, ROR #36
    eor C2, C2, Agi, ROR #5
    eor C0, C0, Asa, ROR #25
    eor C4, C4, Asu, ROR #15
    eor C1, C1, Age, ROR #27
    eor C3, C3, Aso, ROR #2

    eor E1, C0, C2, ROR #61
    ror C2, C2, 62
    eor E3, C2, C4, ROR #57
    ror C4, C4, 58
    eor E0, C4, C1, ROR #55
    ror C1, C1, 56
    eor E2, C1, C3, ROR #63
    eor E4, C3, C0, ROR #63

    eor Aba_, E0, Aba
    eor Asa_, E2, Abi, ROR #50
    eor Abi_, E2, Aki, ROR #46
    eor Aki_, E3, Ako, ROR #63
    eor Ako_, E4, Amu, ROR #28
    eor Amu_, E3, Aso, ROR #2
    eor Aso_, E0, Ama, ROR #54
    eor Aka_, E1, Abe, ROR #43
    eor Ase_, E3, Ago, ROR #36
    eor Ago_, E1, Ame, ROR #49
    eor Ake_, E2, Agi, ROR #3
    eor Agi_, E0, Aka, ROR #39
    eor Aga_, E3, Abo
    eor Abo_, E3, Amo, ROR #37
    eor Amo_, E2, Ami, ROR #8
    eor Ami_, E1, Ake, ROR #56
    eor Age_, E4, Agu, ROR #44
    eor Agu_, E2, Asi, ROR #62
    eor Asi_, E4, Aku, ROR #58
    eor Aku_, E0, Asa, ROR #25
    eor Ama_, E4, Abu, ROR #20
    eor Abu_, E4, Asu, ROR #9
    eor Asu_, E1, Ase, ROR #23
    eor Ame_, E0, Aga, ROR #61
    eor Abe_, E1, Age, ROR #19

    load_constant_ptr_stack
    restore count, STACK_OFFSET_COUNT

    tmp0 .req x0
    tmp1 .req x29

    bic tmp0, Agi_, Age_, ROR #47
    bic tmp1, Ago_, Agi_, ROR #42
    eor Aga, tmp0,  Aga_, ROR #39
    bic tmp0, Agu_, Ago_, ROR #16
    eor Age, tmp1,  Age_, ROR #25
    bic tmp1, Aga_, Agu_, ROR #31
    eor Agi, tmp0,  Agi_, ROR #58
    bic tmp0, Age_, Aga_, ROR #56
    eor Ago, tmp1,  Ago_, ROR #47
    bic tmp1, Aki_, Ake_, ROR #19
    eor Agu, tmp0,  Agu_, ROR #23
    bic tmp0, Ako_, Aki_, ROR #47
    eor Aka, tmp1,  Aka_, ROR #24
    bic tmp1, Aku_, Ako_, ROR #10
    eor Ake, tmp0,  Ake_, ROR #2
    bic tmp0, Aka_, Aku_, ROR #47
    eor Aki, tmp1,  Aki_, ROR #57
    bic tmp1, Ake_, Aka_, ROR #5
    eor Ako, tmp0,  Ako_, ROR #57
    bic tmp0, Ami_, Ame_, ROR #38
    eor Aku, tmp1,  Aku_, ROR #52
    bic tmp1, Amo_, Ami_, ROR #5
    eor Ama, tmp0,  Ama_, ROR #47
    bic tmp0, Amu_, Amo_, ROR #41
    eor Ame, tmp1,  Ame_, ROR #43
    bic tmp1, Ama_, Amu_, ROR #35
    eor Ami, tmp0,  Ami_, ROR #46
    bic tmp0, Ame_, Ama_, ROR #9

    ldr cur_const, [const_addr, count, UXTW #3]

    eor Amo, tmp1,  Amo_, ROR #12
    bic tmp1, Asi_, Ase_, ROR #48
    eor Amu, tmp0,  Amu_, ROR #44
    bic tmp0, Aso_, Asi_, ROR #2
    eor Asa, tmp1,  Asa_, ROR #41
    bic tmp1, Asu_, Aso_, ROR #25
    eor Ase, tmp0,  Ase_, ROR #50
    bic tmp0, Asa_, Asu_, ROR #60
    eor Asi, tmp1,  Asi_, ROR #27
    bic tmp1, Ase_, Asa_, ROR #57
    eor Aso, tmp0,  Aso_, ROR #21
    bic tmp0, Abi_, Abe_, ROR #63
    add count, count, #1
    save count, STACK_OFFSET_COUNT
    eor Asu, tmp1,  Asu_, ROR #53
    bic tmp1, Abo_, Abi_, ROR #42
    eor Aba, Aba_, tmp0,  ROR #21
    bic tmp0, Abu_, Abo_, ROR #57
    eor Abe, tmp1,  Abe_, ROR #41
    bic tmp1, Aba_, Abu_, ROR #50
    eor Abi, tmp0,  Abi_, ROR #35
    bic tmp0, Abe_, Aba_, ROR #44
    eor Abo, tmp1,  Abo_, ROR #43
    eor Abu, tmp0,  Abu_, ROR #30

    eor Aba, Aba, cur_const

.endm

.macro final_rotate_store
    ror Aga, Aga,#(64-3)
    restore input_addr, STACK_OFFSET_INPUT
    ror Abu, Abu,#(64-44)
    ror Aka, Aka,#(64-25)
    ror Ake, Ake,#(64-8)
    str Abu, [input_addr, 8*(4*(4))]
    str Aga, [input_addr, 8*(4*(4+1) )]
    ror Ama, Ama,#(64-10)
    ror Aku, Aku,#(64-6)
    str Aka, [input_addr, 8*(4*(10)  )]
    str Ake, [input_addr, 8*(4*(10+1))]
    ror Asa, Asa,#(64-39)
    ror Ase, Ase,#(64-41)
    str Aku, [input_addr, 8*(4*(14)  )]
    str Ama, [input_addr, 8*(4*(14+1))]
    ror Abe, Abe,#(64-21)
    ror Age, Age,#(64-45)
    str Asa, [input_addr, 8*(4*(20)  )]
    str Ase, [input_addr, 8*(4*(20+1))]
    ror Agi, Agi,#(64-61)
    str Aba, [input_addr, 8*(4*(0)  )]
    str Abe, [input_addr, 8*(4*(0+1) )]
    ror Ame, Ame,#(64-15)
    ror Ami, Ami,#(64-56)
    str Age, [input_addr, 8*(4*(6))]
    str Agi, [input_addr, 8*(4*(6+1) )]
    ror Abi, Abi,#(64-14)
    ror Aki, Aki,#(64-18)
    str Ame, [input_addr, 8*(4*(16)  )]
    str Ami, [input_addr, 8*(4*(16+1))]
    ror Ako, Ako,#(64-1)
    str Abi, [input_addr, 8*(4*(2))]
    str Abo, [input_addr, 8*(4*(2+1) )]
    ror Asi, Asi,#(64-2)
    ror Aso, Aso,#(64-62)
    str Aki, [input_addr, 8*(4*(12)  )]
    str Ako, [input_addr, 8*(4*(12+1))]
    ror Ago, Ago,#(64-28)
    ror Agu, Agu,#(64-20)
    str Asi, [input_addr, 8*(4*(22)  )]
    str Aso, [input_addr, 8*(4*(22+1))]
    ror Amo, Amo,#(64-27)
    ror Amu, Amu,#(64-36)
    str Ago, [input_addr, 8*(4*(8))]
    str Agu, [input_addr, 8*(4*(8+1) )]
    ror Asu, Asu,#(64-55)
    str Amo, [input_addr, 8*(4*(18)  )]
    str Amu, [input_addr, 8*(4*(18+1))]
    str Asu,      [input_addr, #(4*8*24)]
.endm

#define KECCAK_F1600_ROUNDS 24

.text
.balign 16
.global keccak_f1600_x4_scalar_asm_v5
.global _keccak_f1600_x4_scalar_asm_v5

.macro load_constant_ptr_stack
    ldr const_addr, [sp, #(STACK_OFFSET_CONST)]
.endm
keccak_f1600_x4_scalar_asm_v5:
_keccak_f1600_x4_scalar_asm_v5:
    alloc_stack
    save_gprs

    mov out_count, #4
1:
    save out_count, STACK_OFFSET_OUTCOUNT

    keccak_f1600_round_initial
loop:
    keccak_f1600_round_noninitial
    cmp count, #(KECCAK_F1600_ROUNDS-1)
    ble loop

    final_rotate_store
    add input_addr, input_addr, #8

    restore out_count, STACK_OFFSET_OUTCOUNT
    sub out_count, out_count, #1
    cbnz out_count, 1b


    restore_gprs
    free_stack
    ret
