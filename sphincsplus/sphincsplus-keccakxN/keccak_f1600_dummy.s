/*
 * Copyright (c) 2022 Arm Limited
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
// This implementation is based on the public domain implementation of SPHINCS+
// available on https://github.com/sphincs/sphincsplus
//

/****************** REGISTER ALLOCATIONS *******************/

    input_addr     .req x0

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

.macro save_gprs
    stp x19, x20, [sp, #(16*0)]
    stp x21, x22, [sp, #(16*1)]
    stp x23, x24, [sp, #(16*2)]
    stp x25, x26, [sp, #(16*3)]
    stp x27, x28, [sp, #(16*4)]
    stp x29, x30, [sp, #(16*5)]
.endm

.macro restore_gprs
    ldp x19, x20, [sp, #(16*0)]
    ldp x21, x22, [sp, #(16*1)]
    ldp x23, x24, [sp, #(16*2)]
    ldp x25, x26, [sp, #(16*3)]
    ldp x27, x28, [sp, #(16*4)]
    ldp x29, x30, [sp, #(16*5)]
.endm

#define STACK_SIZE (16*6)

.macro alloc_stack
    sub sp, sp, #(STACK_SIZE)
.endm

.macro free_stack
    add sp, sp, #(STACK_SIZE)
.endm

.text
.align 4
.global keccak_f1600_dummy
.global _keccak_f1600_dummy

keccak_f1600_dummy:
_keccak_f1600_dummy:
    alloc_stack
    save_gprs

    load_input
    store_input

    restore_gprs
    free_stack
    ret
