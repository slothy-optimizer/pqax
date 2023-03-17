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
    const_addr     .req x29
    count          .req w27
    cur_const      .req x26

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
    ldp Aba, Abe, [input_addr, #(1*8*0)]
    ldp Abi, Abo, [input_addr, #(1*8*2)]
    ldp Abu, Aga, [input_addr, #(1*8*4)]
    ldp Age, Agi, [input_addr, #(1*8*6)]
    ldp Ago, Agu, [input_addr, #(1*8*8)]
    ldp Aka, Ake, [input_addr, #(1*8*10)]
    ldp Aki, Ako, [input_addr, #(1*8*12)]
    ldp Aku, Ama, [input_addr, #(1*8*14)]
    ldp Ame, Ami, [input_addr, #(1*8*16)]
    ldp Amo, Amu, [input_addr, #(1*8*18)]
    ldp Asa, Ase, [input_addr, #(1*8*20)]
    ldp Asi, Aso, [input_addr, #(1*8*22)]
    ldr Asu,      [input_addr, #(1*8*24)]
.endm

.macro store_input
    stp Aba, Abe, [input_addr, #(1*8*0)]
    stp Abi, Abo, [input_addr, #(1*8*2)]
    stp Abu, Aga, [input_addr, #(1*8*4)]
    stp Age, Agi, [input_addr, #(1*8*6)]
    stp Ago, Agu, [input_addr, #(1*8*8)]
    stp Aka, Ake, [input_addr, #(1*8*10)]
    stp Aki, Ako, [input_addr, #(1*8*12)]
    stp Aku, Ama, [input_addr, #(1*8*14)]
    stp Ame, Ami, [input_addr, #(1*8*16)]
    stp Amo, Amu, [input_addr, #(1*8*18)]
    stp Asa, Ase, [input_addr, #(1*8*20)]
    stp Asi, Aso, [input_addr, #(1*8*22)]
    str Asu,      [input_addr, #(1*8*24)]
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

.macro keccak_f1600_round_initial

    eor C0, Ama, Asa
    eor C1, Ame, Ase
    eor C2, Ami, Asi
    eor C3, Amo, Aso
    eor C4, Amu, Asu
    eor C0, Aka, C0
    eor C1, Ake, C1
    eor C2, Aki, C2
    eor C3, Ako, C3
    eor C4, Aku, C4
    eor C0, Aga, C0
    eor C1, Age, C1
    eor C2, Agi, C2
    eor C3, Ago, C3
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

    bic tmp, Agi_, Age_, ROR #47
    eor Aga, tmp,  Aga_, ROR #39
    bic tmp, Ago_, Agi_, ROR #42
    eor Age, tmp,  Age_, ROR #25
    bic tmp, Agu_, Ago_, ROR #16
    eor Agi, tmp,  Agi_, ROR #58
    bic tmp, Aga_, Agu_, ROR #31
    eor Ago, tmp,  Ago_, ROR #47
    bic tmp, Age_, Aga_, ROR #56
    eor Agu, tmp,  Agu_, ROR #23
    bic tmp, Aki_, Ake_, ROR #19
    eor Aka, tmp,  Aka_, ROR #24
    bic tmp, Ako_, Aki_, ROR #47
    eor Ake, tmp,  Ake_, ROR #2
    bic tmp, Aku_, Ako_, ROR #10
    eor Aki, tmp,  Aki_, ROR #57
    bic tmp, Aka_, Aku_, ROR #47
    eor Ako, tmp,  Ako_, ROR #57
    bic tmp, Ake_, Aka_, ROR #5
    eor Aku, tmp,  Aku_, ROR #52
    bic tmp, Ami_, Ame_, ROR #38
    eor Ama, tmp,  Ama_, ROR #47
    bic tmp, Amo_, Ami_, ROR #5
    eor Ame, tmp,  Ame_, ROR #43
    bic tmp, Amu_, Amo_, ROR #41
    eor Ami, tmp,  Ami_, ROR #46

    ldr cur_const, [const_addr]
    mov count, #1

    bic tmp, Ama_, Amu_, ROR #35
    eor Amo, tmp,  Amo_, ROR #12
    bic tmp, Ame_, Ama_, ROR #9
    eor Amu, tmp,  Amu_, ROR #44
    bic tmp, Asi_, Ase_, ROR #48
    eor Asa, tmp,  Asa_, ROR #41
    bic tmp, Aso_, Asi_, ROR #2
    eor Ase, tmp,  Ase_, ROR #50
    bic tmp, Asu_, Aso_, ROR #25
    eor Asi, tmp,  Asi_, ROR #27
    bic tmp, Asa_, Asu_, ROR #60
    eor Aso, tmp,  Aso_, ROR #21
    bic tmp, Ase_, Asa_, ROR #57
    eor Asu, tmp,  Asu_, ROR #53
    bic tmp, Abi_, Abe_, ROR #63
    eor Aba, Aba_, tmp,  ROR #21
    bic tmp, Abo_, Abi_, ROR #42
    eor Abe, tmp,  Abe_, ROR #41
    bic tmp, Abu_, Abo_, ROR #57
    eor Abi, tmp,  Abi_, ROR #35
    bic tmp, Aba_, Abu_, ROR #50
    eor Abo, tmp,  Abo_, ROR #43
    bic tmp, Abe_, Aba_, ROR #44
    eor Abu, tmp,  Abu_, ROR #30

    eor Aba, Aba, cur_const

.endm


.macro keccak_f1600_round_noninitial

    save count, STACK_OFFSET_COUNT

    eor C0, Aka, Asa, ROR #50
    eor C1, Ase, Age, ROR #60
    eor C2, Ami, Agi, ROR #59
    eor C3, Ago, Aso, ROR #30
    eor C4, Abu, Asu, ROR #53
    eor C0, Ama, C0, ROR #49
    eor C1, Abe, C1, ROR #44
    eor C2, Aki, C2, ROR #26
    eor C3, Amo, C3, ROR #63
    eor C4, Amu, C4, ROR #56
    eor C0, Aga, C0, ROR #57
    eor C1, Ame, C1, ROR #58
    eor C2, Abi, C2, ROR #60
    eor C3, Ako, C3, ROR #38
    eor C4, Agu, C4, ROR #48
    eor C0, Aba, C0, ROR #61
    eor C1, Ake, C1, ROR #57
    eor C2, Asi, C2, ROR #52
    eor C3, Abo, C3, ROR #63
    eor C4, Aku, C4, ROR #50
    ror C1, C1, 56
    ror C4, C4, 58
    ror C2, C2, 62

    eor E1, C0, C2, ROR #63
    eor E3, C2, C4, ROR #63
    eor E0, C4, C1, ROR #63
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

    load_constant_ptr
    restore count, STACK_OFFSET_COUNT

    bic tmp, Agi_, Age_, ROR #47
    eor Aga, tmp,  Aga_, ROR #39
    bic tmp, Ago_, Agi_, ROR #42
    eor Age, tmp,  Age_, ROR #25
    bic tmp, Agu_, Ago_, ROR #16
    eor Agi, tmp,  Agi_, ROR #58
    bic tmp, Aga_, Agu_, ROR #31
    eor Ago, tmp,  Ago_, ROR #47
    bic tmp, Age_, Aga_, ROR #56
    eor Agu, tmp,  Agu_, ROR #23
    bic tmp, Aki_, Ake_, ROR #19
    eor Aka, tmp,  Aka_, ROR #24
    bic tmp, Ako_, Aki_, ROR #47
    eor Ake, tmp,  Ake_, ROR #2
    bic tmp, Aku_, Ako_, ROR #10
    eor Aki, tmp,  Aki_, ROR #57
    bic tmp, Aka_, Aku_, ROR #47
    eor Ako, tmp,  Ako_, ROR #57
    bic tmp, Ake_, Aka_, ROR #5
    eor Aku, tmp,  Aku_, ROR #52
    bic tmp, Ami_, Ame_, ROR #38
    eor Ama, tmp,  Ama_, ROR #47
    bic tmp, Amo_, Ami_, ROR #5
    eor Ame, tmp,  Ame_, ROR #43
    bic tmp, Amu_, Amo_, ROR #41
    eor Ami, tmp,  Ami_, ROR #46
    bic tmp, Ama_, Amu_, ROR #35

    ldr cur_const, [const_addr, count, UXTW #3]
    add count, count, #1

    eor Amo, tmp,  Amo_, ROR #12
    bic tmp, Ame_, Ama_, ROR #9
    eor Amu, tmp,  Amu_, ROR #44
    bic tmp, Asi_, Ase_, ROR #48
    eor Asa, tmp,  Asa_, ROR #41
    bic tmp, Aso_, Asi_, ROR #2
    eor Ase, tmp,  Ase_, ROR #50
    bic tmp, Asu_, Aso_, ROR #25
    eor Asi, tmp,  Asi_, ROR #27
    bic tmp, Asa_, Asu_, ROR #60
    eor Aso, tmp,  Aso_, ROR #21
    bic tmp, Ase_, Asa_, ROR #57
    eor Asu, tmp,  Asu_, ROR #53
    bic tmp, Abi_, Abe_, ROR #63
    eor Aba, Aba_, tmp,  ROR #21
    bic tmp, Abo_, Abi_, ROR #42
    eor Abe, tmp,  Abe_, ROR #41
    bic tmp, Abu_, Abo_, ROR #57
    eor Abi, tmp,  Abi_, ROR #35
    bic tmp, Aba_, Abu_, ROR #50
    eor Abo, tmp,  Abo_, ROR #43
    bic tmp, Abe_, Aba_, ROR #44
    eor Abu, tmp,  Abu_, ROR #30

    eor Aba, Aba, cur_const

.endm

.macro final_rotate
    ror Aga, Aga,#(64-3)
    ror Aka, Aka,#(64-25)
    ror Ama, Ama,#(64-10)
    ror Asa, Asa,#(64-39)
    ror Abe, Abe,#(64-21)
    ror Age, Age,#(64-45)
    ror Ake, Ake,#(64-8)
    ror Ame, Ame,#(64-15)
    ror Ase, Ase,#(64-41)
    ror Abi, Abi,#(64-14)
    ror Agi, Agi,#(64-61)
    ror Aki, Aki,#(64-18)
    ror Ami, Ami,#(64-56)
    ror Asi, Asi,#(64-2)
    ror Ago, Ago,#(64-28)
    ror Ako, Ako,#(64-1)
    ror Amo, Amo,#(64-27)
    ror Aso, Aso,#(64-62)
    ror Abu, Abu,#(64-44)
    ror Agu, Agu,#(64-20)
    ror Aku, Aku,#(64-6)
    ror Amu, Amu,#(64-36)
    ror Asu, Asu,#(64-55)
.endm


#define KECCAK_F1600_ROUNDS 24

.text
.balign 16
.global keccak_f1600_x1_scalar_asm_v2
.global _keccak_f1600_x1_scalar_asm_v2	

keccak_f1600_x1_scalar_asm_v2:
_keccak_f1600_x1_scalar_asm_v2:	
    alloc_stack
    save_gprs
    load_input
    save input_addr, STACK_OFFSET_INPUT

    keccak_f1600_round_initial
loop:
    keccak_f1600_round_noninitial
    cmp count, #(KECCAK_F1600_ROUNDS-1)
    ble loop

    final_rotate

    restore input_addr, STACK_OFFSET_INPUT
    store_input
    restore_gprs
    free_stack
    ret
