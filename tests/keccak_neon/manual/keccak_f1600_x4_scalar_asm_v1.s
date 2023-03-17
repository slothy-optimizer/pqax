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

        input_addr     .req x0
        const_addr     .req x1
        count          .req w0
        cur_const      .req x1

        /* Allocation of GPRs for Keccak-f1600 state */
#define ABA x2
#define ABE x3
#define ABI x4
#define ABO x5
#define ABU x6
#define AGA x7
#define AGE x8
#define AGI x9
#define AGO x10
#define AGU x11
#define AKA x12
#define AKE x13
#define AKI x14
#define AKO x15
#define AKU x16
#define AMA x17
#define AME x18
#define AMI x19
#define AMO x20
#define AMU x21
#define ASA x22
#define ASE x23
#define ASI x24
#define ASO x25
#define ASU x26

        Aba .req ABA
        Abe .req ABE
        Abi .req ABI
        Abo .req ABO
        Abu .req ABU
        Aga .req AGA
        Age .req AGE
        Agi .req AGI
        Ago .req AGO
        Agu .req AGU
        Aka .req AKA
        Ake .req AKE
        Aki .req AKI
        Ako .req AKO
        Aku .req AKU
        Ama .req AMA
        Ame .req AME
        Ami .req AMI
        Amo .req AMO
        Amu .req AMU
        Asa .req ASA
        Ase .req ASE
        Asi .req ASI
        Aso .req ASO
        Asu .req ASU

        Aba_tmp .req AGA
        Abe_tmp .req AGE
        Abi_tmp .req ABI
        Abo_tmp .req ABO
        Abu_tmp .req ABU
        Aga_tmp .req AKA
        Age_tmp .req AKE
        Agi_tmp .req AGI
        Ago_tmp .req AGO
        Agu_tmp .req AGU
        Aka_tmp .req AMA
        Ake_tmp .req AME
        Aki_tmp .req AKI
        Ako_tmp .req AKO
        Aku_tmp .req AKU
        Ama_tmp .req ASA
        Ame_tmp .req ASE
        Ami_tmp .req AMI
        Amo_tmp .req AMO
        Amu_tmp .req AMU
        Asa_tmp .req x28
        Ase_tmp .req x27
        Asi_tmp .req ASI
        Aso_tmp .req ASO
        Asu_tmp .req ASU

#define STACK_SIZE (16*6 + 3*8 + 8) // GPRs (16*6), count (8), const (8), input (8), padding (8)
#define STACK_BASE_GPRS (3*8+8)
#define STACK_OFFSET_INPUT (0*8)
#define STACK_OFFSET_CONST (1*8)
#define STACK_OFFSET_COUNT (2*8)

.macro store_input_scalar num idx
    str Aba, [input_addr, 8*(\num*(0)  +\idx)]
    str Abe, [input_addr, 8*(\num*(0+1) +\idx)]
    str Abi, [input_addr, 8*(\num*(2)+   \idx)]
    str Abo, [input_addr, 8*(\num*(2+1) +\idx)]
    str Abu, [input_addr, 8*(\num*(4)+   \idx)]
    str Aga, [input_addr, 8*(\num*(4+1) +\idx)]
    str Age, [input_addr, 8*(\num*(6)+   \idx)]
    str Agi, [input_addr, 8*(\num*(6+1) +\idx)]
    str Ago, [input_addr, 8*(\num*(8)+   \idx)]
    str Agu, [input_addr, 8*(\num*(8+1) +\idx)]
    str Aka, [input_addr, 8*(\num*(10)  +\idx)]
    str Ake, [input_addr, 8*(\num*(10+1)+\idx)]
    str Aki, [input_addr, 8*(\num*(12)  +\idx)]
    str Ako, [input_addr, 8*(\num*(12+1)+\idx)]
    str Aku, [input_addr, 8*(\num*(14)  +\idx)]
    str Ama, [input_addr, 8*(\num*(14+1)+\idx)]
    str Ame, [input_addr, 8*(\num*(16)  +\idx)]
    str Ami, [input_addr, 8*(\num*(16+1)+\idx)]
    str Amo, [input_addr, 8*(\num*(18)  +\idx)]
    str Amu, [input_addr, 8*(\num*(18+1)+\idx)]
    str Asa, [input_addr, 8*(\num*(20)  +\idx)]
    str Ase, [input_addr, 8*(\num*(20+1)+\idx)]
    str Asi, [input_addr, 8*(\num*(22)  +\idx)]
    str Aso, [input_addr, 8*(\num*(22+1)+\idx)]
    str Asu, [input_addr, 8*(\num*(24)  +\idx)]
.endm

.macro load_input_scalar num idx
    ldr Aba, [input_addr, 8*(\num*(0)  +\idx)]
    ldr Abe, [input_addr, 8*(\num*(0+1) +\idx)]
    ldr Abi, [input_addr, 8*(\num*(2)+   \idx)]
    ldr Abo, [input_addr, 8*(\num*(2+1) +\idx)]
    ldr Abu, [input_addr, 8*(\num*(4)+   \idx)]
    ldr Aga, [input_addr, 8*(\num*(4+1) +\idx)]
    ldr Age, [input_addr, 8*(\num*(6)+   \idx)]
    ldr Agi, [input_addr, 8*(\num*(6+1) +\idx)]
    ldr Ago, [input_addr, 8*(\num*(8)+   \idx)]
    ldr Agu, [input_addr, 8*(\num*(8+1) +\idx)]
    ldr Aka, [input_addr, 8*(\num*(10)  +\idx)]
    ldr Ake, [input_addr, 8*(\num*(10+1)+\idx)]
    ldr Aki, [input_addr, 8*(\num*(12)  +\idx)]
    ldr Ako, [input_addr, 8*(\num*(12+1)+\idx)]
    ldr Aku, [input_addr, 8*(\num*(14)  +\idx)]
    ldr Ama, [input_addr, 8*(\num*(14+1)+\idx)]
    ldr Ame, [input_addr, 8*(\num*(16)  +\idx)]
    ldr Ami, [input_addr, 8*(\num*(16+1)+\idx)]
    ldr Amo, [input_addr, 8*(\num*(18)  +\idx)]
    ldr Amu, [input_addr, 8*(\num*(18+1)+\idx)]
    ldr Asa, [input_addr, 8*(\num*(20)  +\idx)]
    ldr Ase, [input_addr, 8*(\num*(20+1)+\idx)]
    ldr Asi, [input_addr, 8*(\num*(22)  +\idx)]
    ldr Aso, [input_addr, 8*(\num*(22+1)+\idx)]
    ldr Asu, [input_addr, 8*(\num*(24)  +\idx)]
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

.macro  keccak_f1600_round is_first

    .if \is_first == 0
        save count, STACK_OFFSET_COUNT
    .endif

#define BCE x30
#define BCA x0
#define BCI x27
#define BCO x28
#define BCU x29

    BCe .req BCE
    BCa .req BCA
    BCi .req BCI
    BCo .req BCO
    BCu .req BCU

    .if \is_first == 1
        eor5 BCa, Aba, Aga, Aka, Ama, Asa
        eor5 BCe, Abe, Age, Ake, Ame, Ase
        eor5 BCi, Abi, Agi, Aki, Ami, Asi
        eor5 BCo, Abo, Ago, Ako, Amo, Aso
        eor5 BCu, Abu, Agu, Aku, Amu, Asu
    .else
        xor_rol BCu, Asu, Abu , 11
        xor_rol BCa, Asa, Aka, 14
        xor_rol BCe, Age, Ase , 4
        xor_rol BCi, Agi, Ami , 5
        xor_rol BCu, BCu, Amu , 8
        xor_rol BCo, Aso, Ago , 34
        xor_rol BCe, BCe, Abe , 20
        xor_rol BCa, BCa, Ama , 15
        xor_rol BCi, BCi, Aki , 38
        xor_rol BCu, BCu, Agu , 16
        xor_rol BCe, BCe, Ame , 6
        xor_rol BCo, BCo, Amo , 1
        xor_rol BCi, BCi, Abi , 4
        xor_rol BCu, BCu, Aku , 14
        xor_rol BCe, BCe, Ake , 7
        xor_rol BCo, BCo, Ako , 26
        xor_rol BCa, BCa, Aga , 7
        xor_rol BCi, BCi, Asi , 12
        rotate  BCe, BCe, 8
        xor_rol BCo, BCo, Abo , 1
        rotate  BCu, BCu, 6
        rotate  BCi, BCi, 2
        xor_rol BCa, BCa, Aba , 3
    .endif

    Da  .req BCE
    Du  .req BCA
    De  .req BCI
    Di  .req x1
    Do  .req BCU

    xor_rol Di,BCo,BCe,1
    xor_rol Da,BCe,BCu,1
    xor_rol Do,BCu,BCi,1
    .unreq BCu
    xor_rol De,BCi,BCa,1
    .unreq BCi
    xor_rol Du,BCa,BCo,1
    .unreq BCa
    .unreq BCo
    .unreq BCe

    .if \is_first == 1

        eor Asa_tmp,Abi,Di
        eor Abi_tmp,Aki,Di
        eor Aki_tmp,Ako,Do
        eor Ako_tmp,Amu,Du
        eor Amu_tmp,Aso,Do
        eor Aso_tmp,Ama,Da
        eor Aka_tmp,Abe,De

	eor Abe_tmp,Age,De

        temp .req ABE
        eor temp,Ago,Do
        eor Ago_tmp,Ame,De
        eor Ake_tmp,Agi,Di
        eor Agi_tmp,Aka,Da
        eor Aga_tmp,Abo,Do
        eor Abo_tmp,Amo,Do
        eor Amo_tmp,Ami,Di
        eor Ami_tmp,Ake,De
        eor Age_tmp,Agu,Du
        eor Agu_tmp,Asi,Di
        eor Asi_tmp,Aku,Du
        eor Aku_tmp,Asa,Da
        eor Ama_tmp,Abu,Du
        eor Abu_tmp,Asu,Du
        eor Asu_tmp,Ase,De
        eor Ame_tmp,Aga,Da
        eor Aba_tmp,Aba,Da
        mov Ase_tmp,temp
        .unreq temp

    .else

        xor_rol Asa_tmp,Abi,Di,14
        xor_rol Abi_tmp,Aki,Di,18
        xor_rol Aki_tmp,Ako,Do,1
        xor_rol Ako_tmp,Amu,Du,36
        xor_rol Amu_tmp,Aso,Do,62
        xor_rol Aso_tmp,Ama,Da,10
        xor_rol Aka_tmp,Abe,De,21

        xor_rol Abe_tmp,Age,De,45

        temp .req ABE
        xor_rol temp,Ago,Do,28
        xor_rol Ago_tmp,Ame,De,15
        xor_rol Ake_tmp,Agi,Di,61
        xor_rol Agi_tmp,Aka,Da,25
        eor     Aga_tmp,Abo,Do
        xor_rol Abo_tmp,Amo,Do,27
        xor_rol Amo_tmp,Ami,Di,56
        xor_rol Ami_tmp,Ake,De,8
        xor_rol Age_tmp,Agu,Du,20
        xor_rol Agu_tmp,Asi,Di,2
        xor_rol Asi_tmp,Aku,Du,6
        xor_rol Aku_tmp,Asa,Da,39
        xor_rol Ama_tmp,Abu,Du,44
        xor_rol Abu_tmp,Asu,Du,55
        xor_rol Asu_tmp,Ase,De,41
        xor_rol Ame_tmp,Aga,Da,3
        eor     Aba_tmp,Aba,Da
        mov Ase_tmp,temp
        .unreq temp

    .endif

    .unreq Da
    .unreq De
    .unreq Di
    .unreq Do
    .unreq Du

    tmp .req x30

    bic_rol tmp, Abe_tmp,  Abi_tmp,1
    xor_rol Aba, tmp,      Aba_tmp,43
    bic_rol tmp, Abi_tmp,  Abo_tmp,22
    xor_rol Abe, Abe_tmp,      tmp,23
    bic_rol tmp ,Abo_tmp,  Abu_tmp,7
    xor_rol Abi ,Abi_tmp,      tmp,29
    bic_rol tmp ,Abu_tmp,  Aba_tmp,14
    xor_rol Abo ,Abo_tmp,      tmp,21
    bic_rol tmp ,Aba_tmp,  Abe_tmp,20
    xor_rol Abu ,Abu_tmp,      tmp,34

    bic_rol tmp, Age_tmp, Agi_tmp,17
    xor_rol Aga, Aga_tmp,     tmp,25
    bic_rol tmp, Agi_tmp, Ago_tmp,22
    xor_rol Age, Age_tmp,     tmp,39
    bic_rol tmp ,Ago_tmp, Agu_tmp,48
    xor_rol Agi ,Agi_tmp,     tmp,6
    bic_rol tmp ,Agu_tmp, Aga_tmp,33
    xor_rol Ago ,Ago_tmp,     tmp,17
    bic_rol tmp ,Aga_tmp, Age_tmp,8
    xor_rol Agu ,Agu_tmp,     tmp,41

    .if \is_first == 0
        restore count, STACK_OFFSET_COUNT
    .endif

    load_constant_ptr

    bic_rol tmp, Ake_tmp, Aki_tmp,45
    xor_rol Aka, Aka_tmp,     tmp,40
    bic_rol tmp, Aki_tmp, Ako_tmp,17
    xor_rol Ake, Ake_tmp,     tmp,62
    bic_rol tmp ,Ako_tmp, Aku_tmp,54
    xor_rol Aki ,Aki_tmp,     tmp,7
    bic_rol tmp ,Aku_tmp, Aka_tmp,17
    xor_rol Ako ,Ako_tmp,     tmp,7
    bic_rol tmp ,Aka_tmp, Ake_tmp,59
    xor_rol Aku ,Aku_tmp,     tmp,12

    bic_rol tmp, Ame_tmp, Ami_tmp,26
    xor_rol Ama, Ama_tmp,     tmp,17
    bic_rol tmp, Ami_tmp, Amo_tmp,59
    xor_rol Ame, Ame_tmp,     tmp,21
    bic_rol tmp ,Amo_tmp, Amu_tmp,23
    xor_rol Ami ,Ami_tmp,     tmp,18
    bic_rol tmp ,Amu_tmp, Ama_tmp,29
    xor_rol Amo ,Amo_tmp,     tmp,52
    bic_rol tmp ,Ama_tmp, Ame_tmp,55
    xor_rol Amu ,Amu_tmp,     tmp,20

    .if \is_first == 0
        ldr cur_const, [const_addr, count, UXTW #3]
        add count, count, #1
    .else
        ldr cur_const, [const_addr]
        mov count, #1
    .endif

    bic_rol tmp, Ase_tmp, Asi_tmp,16
    xor_rol Asa, Asa_tmp,     tmp,23
    bic_rol tmp, Asi_tmp, Aso_tmp,62
    xor_rol Ase, Ase_tmp,     tmp,14
    bic_rol tmp ,Aso_tmp, Asu_tmp,39
    xor_rol Asi ,Asi_tmp,     tmp,37
    bic_rol tmp ,Asu_tmp, Asa_tmp,4
    xor_rol Aso ,Aso_tmp,     tmp,43
    bic_rol tmp ,Asa_tmp, Ase_tmp,7
    xor_rol Asu ,Asu_tmp,     tmp,11

    eor Aba, Aba, cur_const

.endm

.macro final_rotate
    rotate Aga, Aga,3
    rotate Aka, Aka,25
    rotate Ama, Ama,10
    rotate Asa, Asa,39
    rotate Abe, Abe,21
    rotate Age, Age,45
    rotate Ake, Ake,8
    rotate Ame, Ame,15
    rotate Ase, Ase,41
    rotate Abi, Abi,14
    rotate Agi, Agi,61
    rotate Aki, Aki,18
    rotate Ami, Ami,56
    rotate Asi, Asi,2
    rotate Ago, Ago,28
    rotate Ako, Ako,1
    rotate Amo, Amo,27
    rotate Aso, Aso,62
    rotate Abu, Abu,44
    rotate Agu, Agu,20
    rotate Aku, Aku,6
    rotate Amu, Amu,36
    rotate Asu, Asu,55
.endm

#define KECCAK_F1600_ROUNDS 24

.global keccak_f1600_x4_scalar_asm_v1
.global _keccak_f1600_x4_scalar_asm_v1
.text
.align 4

keccak_f1600_x4_scalar_asm_v1:
_keccak_f1600_x4_scalar_asm_v1:
    alloc_stack
    save_gprs
    save input_addr, STACK_OFFSET_INPUT

    // First scalar Keccak computation
    load_input_scalar 4,0
    keccak_f1600_round 1
loop_0:
    keccak_f1600_round 0
    cmp count, #(KECCAK_F1600_ROUNDS-1)
    ble loop_0
    final_rotate
    restore input_addr, STACK_OFFSET_INPUT
    store_input_scalar 4,0

    // Second scalar Keccak computation
    load_input_scalar 4, 1
    keccak_f1600_round 1
loop_1:
    keccak_f1600_round 0
    cmp count, #(KECCAK_F1600_ROUNDS-1)
    ble loop_1
    final_rotate
    restore input_addr, STACK_OFFSET_INPUT
    store_input_scalar 4, 1

    // Third scalar Keccak computation
    load_input_scalar 4, 2
    keccak_f1600_round 1
loop_2:
    keccak_f1600_round 0
    cmp count, #(KECCAK_F1600_ROUNDS-1)
    ble loop_2
    final_rotate
    restore input_addr, STACK_OFFSET_INPUT
    store_input_scalar 4, 2

    // Fourth scalar Keccak computation
    load_input_scalar 4, 3
    keccak_f1600_round 1
loop_3:
    keccak_f1600_round 0
    cmp count, #(KECCAK_F1600_ROUNDS-1)
    ble loop_3
    final_rotate
    restore input_addr, STACK_OFFSET_INPUT
    store_input_scalar 4, 3

    restore_gprs
    free_stack
    ret
