// Needed to provide ASM_LOAD directive
#include <hal_env.h>

        qform_v0  .req q0
        qform_v1  .req q1
        qform_v2  .req q2
        qform_v3  .req q3
        qform_v4  .req q4
        qform_v5  .req q5
        qform_v6  .req q6
        qform_v7  .req q7
        qform_v8  .req q8
        qform_v9  .req q9
        qform_v10 .req q10
        qform_v11 .req q11
        qform_v12 .req q12
        qform_v13 .req q13
        qform_v14 .req q14
        qform_v15 .req q15
        qform_v16 .req q16
        qform_v17 .req q17
        qform_v18 .req q18
        qform_v19 .req q19
        qform_v20 .req q20
        qform_v21 .req q21
        qform_v22 .req q22
        qform_v23 .req q23
        qform_v24 .req q24
        qform_v25 .req q25
        qform_v26 .req q26
        qform_v27 .req q27
        qform_v28 .req q28
        qform_v29 .req q29
        qform_v30 .req q30
        qform_v31 .req q31

.macro save_gprs
        sub sp, sp, #(16*6)
        stp x19, x20, [sp, #16*0]
        stp x19, x20, [sp, #16*0]
        stp x21, x22, [sp, #16*1]
        stp x23, x24, [sp, #16*2]
        stp x25, x26, [sp, #16*3]
        stp x27, x28, [sp, #16*4]
        stp x29, x30, [sp, #16*5]
.endm

.macro restore_gprs
        ldp x19, x20, [sp, #16*0]
        ldp x21, x22, [sp, #16*1]
        ldp x23, x24, [sp, #16*2]
        ldp x25, x26, [sp, #16*3]
        ldp x27, x28, [sp, #16*4]
        ldp x29, x30, [sp, #16*5]
        add sp, sp, #(16*6)
.endm

.macro save_vregs
        sub sp, sp, #(16*4)
        stp  d8,  d9, [sp, #16*0]
        stp d10, d11, [sp, #16*1]
        stp d12, d13, [sp, #16*2]
        stp d14, d15, [sp, #16*3]
.endm

.macro restore_vregs
        ldp  d8,  d9, [sp, #16*0]
        ldp d10, d11, [sp, #16*1]
        ldp d12, d13, [sp, #16*2]
        ldp d14, d15, [sp, #16*3]
        add sp, sp, #(16*4)
.endm

#define STACK_SIZE 1024

.macro push_stack
        save_gprs
        save_vregs
        sub sp, sp, #STACK_SIZE
.endm

.macro pop_stack
        add sp, sp, #STACK_SIZE
        restore_vregs
        restore_gprs
.endm

loop_cnt .req x30

.macro make_ubench name, preamble, code, end_of_iteration
       .p2align 4
       .text
       .global ubench_\name\()
       .global _ubench_\name\()
ubench_\name\():
_ubench_\name\():
        push_stack
        mov loop_cnt, #4
        \preamble\()
        .p2align 2
1:
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \code\()
        \end_of_iteration\()
        subs loop_cnt, loop_cnt, #1
        cbnz loop_cnt, 1b
        pop_stack
        ret
.endm

.macro padding
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
.endm
