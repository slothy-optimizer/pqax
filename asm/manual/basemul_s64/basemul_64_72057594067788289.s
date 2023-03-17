
.macro save_regs
        sub sp, sp, #(16*6)
        stp x19, x20, [sp, #16*0]
        stp x19, x20, [sp, #16*0]
        stp x21, x22, [sp, #16*1]
        stp x23, x24, [sp, #16*2]
        stp x25, x26, [sp, #16*3]
        stp x27, x28, [sp, #16*4]
        stp x29, x30, [sp, #16*5]
        sub sp, sp, #(16*4)
        stp  d8,  d9, [sp, #16*0]
        stp d10, d11, [sp, #16*1]
        stp d12, d13, [sp, #16*2]
        stp d14, d15, [sp, #16*3]
.endm

.macro restore_regs
        ldp  d8,  d9, [sp, #16*0]
        ldp d10, d11, [sp, #16*1]
        ldp d12, d13, [sp, #16*2]
        ldp d14, d15, [sp, #16*3]
        add sp, sp, #(16*4)
        ldp x19, x20, [sp, #16*0]
        ldp x21, x22, [sp, #16*1]
        ldp x23, x24, [sp, #16*2]
        ldp x25, x26, [sp, #16*3]
        ldp x27, x28, [sp, #16*4]
        ldp x29, x30, [sp, #16*5]
        add sp, sp, #(16*5+16)
.endm

.data
modulus:
        .dword 72057594067788289
        .dword 249802778572774913

        .text
        .type basemul_u64, %function
        .global basemul_u64

modulus_addr:
        .dword modulus
basemul_u64:
        dst   .req x0
        src_a .req x1
        src_b .req x2
        count .req x3

        addr      .req x4

        in_a0  .req z0
        in_a1  .req z1
        in_b0  .req z2
        in_b1  .req z3
        dst_0  .req z4
        dst_1  .req z5

        in_a0q .req q0
        in_a1q .req q1
        in_b0q .req q2
        in_b1q .req q3
        dst_0q .req q4
        dst_1q .req q5

        modulus .req z6
        twist   .req z7

        tmp     .req z8

        save_regs

        ptrue P0.d

        ldr addr, modulus_addr
        ld1rd {modulus.d}, P0/z, [addr, #0]
        ld1rd {twist.d},   P0/z, [addr, #8]

        // # of elements must be divisible by 4
        mov count, count, LSR #2
        cmp count, #0
        b.eq 2f
1:
        ldp in_a0q, in_a1q, [src_a], #32
        ldp in_b0q, in_b1q, [src_b], #32

        sqdmulh dst_0.d,       in_a0.d, in_b0.d
        mul     tmp.d,         in_a0.d, in_b0.d
        mul     tmp.d,         tmp.d,   twist.d
        sqdmulh tmp.d,         tmp.d,    modulus.d
        shsub   dst_0.d, P0/M, dst_0.d,  tmp.d

        sqdmulh dst_1.d,       in_a1.d, in_b1.d
        mul     tmp.d,         in_a1.d, in_b1.d
        mul     tmp.d,         tmp.d,   twist.d
        sqdmulh tmp.d,         tmp.d,    modulus.d
        shsub   dst_1.d, P0/M, dst_1.d,  tmp.d

        stp dst_0q, dst_1q, [dst], #32

        subs count, count, 1
        bne 1b
2:
        restore_regs
        ret
