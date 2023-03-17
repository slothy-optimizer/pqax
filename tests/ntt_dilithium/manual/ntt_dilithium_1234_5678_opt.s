///
/// Copyright (c) 2022 Arm Limited
/// Copyright (c) 2022 Hanno Becker
/// SPDX-License-Identifier: MIT
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in all
/// copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
/// SOFTWARE.
///

// Needed to provide ASM_LOAD directive
#include <hal_env.h>

// NOTE
// We use a lot of trivial macros to simplify the parsing burden for Slothy
// The macros are not unfolded by Slothy and thus interpreted as instructions,
// which are easier to parse due to e.g. the lack of size specifiers and simpler
// syntax for pre and post increment for loads and stores.
//
// Eventually, NeLight should include a proper parser for AArch64,
// but for initial investigations, the below is enough.

.macro ldr_vo vec, base, offset                    // slothy:no-unfold
        ldr qform_\vec, [\base, \offset]
.endm
.macro ldr_vi vec, base, inc                        // slothy:no-unfold
        ldr qform_\vec, [\base], \inc
.endm
.macro str_vo vec, base, offset                     // slothy:no-unfold
        str qform_\vec, [\base, \offset]
.endm
.macro str_vi vec, base, inc                        // slothy:no-unfold
        str qform_\vec, [\base], \inc
.endm
.macro vsub d,a,b                                   // slothy:no-unfold
        sub \d\().4s, \a\().4s, \b\().4s
.endm
.macro vadd d,a,b                                   // slothy:no-unfold
        add \d\().4s, \a\().4s, \b\().4s
.endm
.macro vqrdmulh d,a,b                               // slothy:no-unfold
        sqrdmulh \d\().4s, \a\().4s, \b\().4s
.endm
.macro vmul d,a,b                                   // slothy:no-unfold
        mul \d\().4s, \a\().4s, \b\().4s
.endm
.macro vmla d,a,b                                   // slothy:no-unfold
        mla \d\().4s, \a\().4s, \b\().4s
.endm
.macro vqrdmulhq d,a,b,i                            // slothy:no-unfold
        sqrdmulh \d\().4s, \a\().4s, \b\().s[\i]
.endm
.macro vmulq d,a,b,i                                // slothy:no-unfold
        mul \d\().4s, \a\().4s, \b\().s[\i]
.endm
.macro vmlaq d,a,b,i                                // slothy:no-unfold
        mla \d\().4s, \a\().4s, \b\().s[\i]
.endm
.macro trn1_d d,a,b                                 // slothy:no-unfold
        trn1 \d\().2d, \a\().2d, \b\().2d
.endm
.macro trn2_d d,a,b                                 // slothy:no-unfold
        trn2 \d\().2d, \a\().2d, \b\().2d
.endm
.macro trn1_s d,a,b                                 // slothy:no-unfold
        trn1 \d\().4s, \a\().4s, \b\().4s
.endm
.macro trn2_s d,a,b                                 // slothy:no-unfold
        trn2 \d\().4s, \a\().4s, \b\().4s
.endm

.macro mulmodq dst, src, const, idx0, idx1
        vmulq       \dst,  \src, \const, \idx0
        vqrdmulhq   \src,  \src, \const, \idx1
        vmla        \dst,  \src, modulus
.endm

.macro mulmod dst, src, const, const_twisted
        vmul       \dst,  \src, \const
        vqrdmulh   \src,  \src, \const_twisted
        vmla       \dst,  \src, modulus
.endm

.macro ct_butterfly a, b, root, idx0, idx1
        mulmodq  tmp, \b, \root, \idx0, \idx1
        vsub     \b,    \a, tmp
        vadd     \a,    \a, tmp
.endm

.macro mulmod_v dst, src, const, const_twisted
        vmul        \dst,  \src, \const
        vqrdmulh    \src,  \src, \const_twisted
        vmla        \dst,  \src, modulus
.endm

.macro ct_butterfly_v a, b, root, root_twisted
        mulmod  tmp, \b, \root, \root_twisted
        vsub    \b,    \a, tmp
        vadd    \a,    \a, tmp
.endm

.macro load_roots_1234
        ldr_vi root0, r_ptr0, (8*16)
        ldr_vo root1, r_ptr0, (-8*16 + 1*16)
        ldr_vo root2, r_ptr0, (-8*16 + 2*16)
        ldr_vo root3, r_ptr0, (-8*16 + 3*16)
        ldr_vo root4, r_ptr0, (-8*16 + 4*16)
        ldr_vo root5, r_ptr0, (-8*16 + 5*16)
        ldr_vo root6, r_ptr0, (-8*16 + 6*16)
        ldr_vo root7, r_ptr0, (-8*16 + 7*16)
.endm

.macro load_next_roots_56 root0, r_ptr0
        ldr_vi \root0, \r_ptr0, 16
.endm

.macro load_next_roots_6 root0, r_ptr0
        ldr_vi \root0, \r_ptr0, 8
.endm

.macro load_next_roots_78 root0, root0_tw, root1, root1_tw, root2, root2_tw, r_ptr1
        ldr_vi \root0,    \r_ptr1, (6*16)
        ldr_vo \root0_tw, \r_ptr1, (-6*16 + 1*16)
        ldr_vo \root1,    \r_ptr1, (-6*16 + 2*16)
        ldr_vo \root1_tw, \r_ptr1, (-6*16 + 3*16)
        ldr_vo \root2,    \r_ptr1, (-6*16 + 4*16)
        ldr_vo \root2_tw, \r_ptr1, (-6*16 + 5*16)
.endm

.macro transpose4 data
        trn1_s t0, \data\()0, \data\()1
        trn2_s t1, \data\()0, \data\()1
        trn1_s t2, \data\()2, \data\()3
        trn2_s t3, \data\()2, \data\()3

        trn2_d \data\()2, t0, t2
        trn2_d \data\()3, t1, t3
        trn1_d \data\()0, t0, t2
        trn1_d \data\()1, t1, t3
.endm

.macro save_gprs // slothy:no-unfold
        sub sp, sp, #(16*6)
        stp x19, x20, [sp, #16*0]
        stp x19, x20, [sp, #16*0]
        stp x21, x22, [sp, #16*1]
        stp x23, x24, [sp, #16*2]
        stp x25, x26, [sp, #16*3]
        stp x27, x28, [sp, #16*4]
        str x29, [sp, #16*5]
.endm

.macro restore_gprs // slothy:no-unfold
        ldp x19, x20, [sp, #16*0]
        ldp x21, x22, [sp, #16*1]
        ldp x23, x24, [sp, #16*2]
        ldp x25, x26, [sp, #16*3]
        ldp x27, x28, [sp, #16*4]
        ldr x29, [sp, #16*5]
        add sp, sp, #(16*6)
.endm

.macro save_vregs // slothy:no-unfold
        sub sp, sp, #(16*4)
        stp  d8,  d9, [sp, #16*0]
        stp d10, d11, [sp, #16*1]
        stp d12, d13, [sp, #16*2]
        stp d14, d15, [sp, #16*3]
.endm

.macro restore_vregs // slothy:no-unfold
        ldp  d8,  d9, [sp, #16*0]
        ldp d10, d11, [sp, #16*1]
        ldp d12, d13, [sp, #16*2]
        ldp d14, d15, [sp, #16*3]
        add sp, sp, #(16*4)
.endm

#define STACK_SIZE 16
#define STACK0 0

.macro restore a, loc     // slothy:no-unfold
        ldr \a, [sp, #\loc\()]
.endm
.macro save loc, a        // slothy:no-unfold
        str \a, [sp, #\loc\()]
.endm
.macro push_stack // slothy:no-unfold
        save_gprs
        save_vregs
        sub sp, sp, #STACK_SIZE
.endm

.macro pop_stack // slothy:no-unfold
        add sp, sp, #STACK_SIZE
        restore_vregs
        restore_gprs
.endm

.data
.p2align 4
roots:
#include "ntt_dilithium_1234_5678_twiddles.s"
.text

        .global ntt_dilithium_1234_5678_opt
        .global _ntt_dilithium_1234_5678_opt

.p2align 4
modulus_addr:   .quad -8380417
ntt_dilithium_1234_5678_opt:
_ntt_dilithium_1234_5678_opt:
        push_stack

        in      .req x0
        inp     .req x1
        count   .req x2
        r_ptr0  .req x3
        r_ptr1  .req x4
        xtmp    .req x5

        data0  .req v8
        data1  .req v9
        data2  .req v10
        data3  .req v11
        data4  .req v12
        data5  .req v13
        data6  .req v14
        data7  .req v15
        data8  .req v16
        data9  .req v17
        data10 .req v18
        data11 .req v19
        data12 .req v20
        data13 .req v21
        data14 .req v22
        data15 .req v23

        qform_v0 .req q0
qform_v1 .req q1
qform_v2 .req q2
qform_v3 .req q3
qform_v4 .req q4
qform_v5 .req q5
qform_v6 .req q6
qform_v7 .req q7
qform_v8 .req q8
qform_v9 .req q9
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

        qform_data0  .req q8
        qform_data1  .req q9
        qform_data2  .req q10
        qform_data3  .req q11
        qform_data4  .req q12
        qform_data5  .req q13
        qform_data6  .req q14
        qform_data7  .req q15
        qform_data8  .req q16
        qform_data9  .req q17
        qform_data10 .req q18
        qform_data11 .req q19
        qform_data12 .req q20
        qform_data13 .req q21
        qform_data14 .req q22
        qform_data15 .req q23

        root0    .req v0
        root1    .req v1
        root2    .req v2
        root3    .req v3
        root4 .req v4
        root5 .req v5
        root6 .req v6
        root7 .req v7

        qform_root0    .req q0
        qform_root1    .req q1
        qform_root2    .req q2
        qform_root3    .req q3
        qform_root4    .req q4
        qform_root5    .req q5
        qform_root6    .req q6
        qform_root7    .req q7


        tmp .req v24
        t0  .req v25
        t1  .req v26
        t2  .req v27
        t3  .req v28

        modulus .req v29

        ASM_LOAD(r_ptr0, roots)
        ASM_LOAD(r_ptr1, roots_l67)

        ASM_LOAD(xtmp, modulus_addr)
        ld1r {modulus.4s}, [xtmp]

        save STACK0, in
        mov count, #4

        load_roots_1234

        .p2align 2
        ldr_vo v28, x0, 512
        ldr_vo v30, x0, 320
        ldr_vo v8, x0, 256
        ldr_vo v23, x0, 576
        ldr_vo v14, x0, 768
        vmulq v22, v28, v0, 0
        vqrdmulhq v28, v28, v0, 1
        ldr_vo v20, x0, 704
        ldr_vo v21, x0, 192
        vqrdmulhq v13, v23, v0, 1
        ldr_vo v25, x0, 0
        ldr_vo v11, x0, 64
        vmla v22, v28, v29
        vmulq v9, v23, v0, 0
        ldr_vo v16, x0, 640
        vqrdmulhq v28, v20, v0, 1
        ldr_vo v31, x0, 128
        vmla v9, v13, v29
        vmulq v13, v20, v0, 0
        vsub v26, v25, v22
        vmulq v23, v16, v0, 0
        vadd v25, v25, v22
        vqrdmulhq v19, v16, v0, 1
        ldr_vo v16, x0, 832
        vmulq v27, v16, v0, 0
        vqrdmulhq v10, v16, v0, 1
        vmla v23, v19, v29
        vmla v13, v28, v29
        vmulq v22, v14, v0, 0
        vqrdmulhq v19, v14, v0, 1
        vadd v20, v21, v13
        vsub v24, v21, v13
        vmla v27, v10, v29
        ldr_vo v13, x0, 896
        vsub v15, v11, v9
        vadd v11, v11, v9
        vsub v21, v30, v27
        vadd v16, v30, v27
        vmla v22, v19, v29
        ldr_vo v12, x0, 960
        vqrdmulhq v17, v13, v0, 1
        vadd v10, v8, v22
        vmulq v27, v13, v0, 0
        vqrdmulhq v30, v12, v0, 1
        vsub v18, v8, v22
        vmulq v8, v12, v0, 0
        ldr_vo v12, x0, 384
        vmulq v13, v10, v0, 2
        vmla v27, v17, v29
        vqrdmulhq v9, v16, v0, 3
        vsub v17, v31, v23
        vmulq v14, v16, v0, 2
        vqrdmulhq v19, v10, v0, 3
        vadd v31, v31, v23
        ldr_vo v16, x0, 448
        vmla v8, v30, v29
        vadd v10, v12, v27
        vmulq v23, v10, v0, 2
        vqrdmulhq v28, v10, v0, 3
        vmla v13, v19, v29
        vmulq v22, v18, v1, 0
        vadd v19, v16, v8
        vqrdmulhq v10, v18, v1, 1
        vsub v30, v16, v8
        vmulq v18, v19, v0, 2
        vsub v8, v12, v27
        vqrdmulhq v12, v19, v0, 3
        vmla v14, v9, v29
        vmla v23, v28, v29
        vadd v19, v25, v13
        vmla v22, v10, v29
        vsub v10, v25, v13
        vqrdmulhq v25, v21, v1, 1
        vadd v9, v11, v14
        vmulq v21, v21, v1, 0
        vmulq v13, v8, v1, 0
        vsub v27, v26, v22
        vqrdmulhq v16, v8, v1, 1
        vmulq v28, v30, v1, 0
        vqrdmulhq v8, v30, v1, 1
        vmla v18, v12, v29
        vsub v12, v11, v14
        vmla v21, v25, v29
        vsub v25, v31, v23
        vadd v14, v20, v18
        vadd v30, v31, v23
        vmla v13, v16, v29
        vadd v16, v15, v21
        vmulq v11, v14, v1, 2
        vsub v31, v20, v18
        vqrdmulhq v18, v14, v1, 3
        vqrdmulhq v20, v30, v1, 3
        vadd v14, v26, v22
        vmulq v30, v30, v1, 2
        vsub v26, v15, v21
        vmla v28, v8, v29
        sub count, count, #1
.p2align 2
layer1234_start:
        vqrdmulhq v22, v31, v2, 1
        vsub v8, v24, v28
        vqrdmulhq v21, v25, v2, 1
        vadd v24, v24, v28
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vmulq v28, v25, v2, 0
        vsub v23, v17, v13
        // gap
        // gap
        // gap
        // gap
        vmulq v31, v31, v2, 0
        vadd v15, v17, v13
        vmla v30, v20, v29
        // gap
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v17, v15, v2, 3
        // gap
        vmla v11, v18, v29
        // gap
        // gap
        // gap
        // gap
        // gap
        vmulq v18, v15, v2, 2
        // gap
        vmla v28, v21, v29
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vsub v25, v9, v11
        vqrdmulhq v20, v23, v3, 1
        // gap
        // gap
        // gap
        // gap
        // gap
        vmulq v23, v23, v3, 0
        vadd v21, v9, v11
        vmla v31, v22, v29
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v18, v17, v29
        vadd v15, v19, v30
        vmulq v9, v8, v3, 0
        // gap
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v8, v8, v3, 1
        // gap
        // gap
        vsub v22, v12, v31
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v11, v24, v2, 3
        // gap
        vmla v23, v20, v29
        vadd v12, v12, v31
        // gap
        // gap
        // gap
        // gap
        vmulq v31, v24, v2, 2
        vadd v24, v10, v28
        vmla v9, v8, v29
        vsub v20, v19, v30
        // gap
        // gap
        // gap
        // gap
        vmulq v17, v21, v3, 2
        vsub v28, v10, v28
        vqrdmulhq v10, v21, v3, 3
        vadd v21, v27, v23
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v13, v12, v4, 3
        // gap
        vmulq v12, v12, v4, 2
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v31, v11, v29
        vsub v19, v27, v23
        vqrdmulhq v23, v25, v4, 1
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v12, v13, v29
        // gap
        vmulq v11, v25, v4, 0
        vadd v30, v26, v9
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v25, v22, v5, 1
        // gap
        vmulq v8, v22, v5, 0
        vadd v27, v16, v31
        // gap
        // gap
        // gap
        // gap
        vmla v11, v23, v29
        vsub v13, v16, v31
        vqrdmulhq v31, v27, v5, 3
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v17, v10, v29
        vsub v9, v26, v9
        vmulq v26, v13, v6, 0
        vadd v16, v24, v12
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v13, v13, v6, 1
        vsub v23, v24, v12
        vmulq v27, v27, v5, 2
        vsub v24, v20, v11
        // gap
        // gap
        // gap
        // gap
        vadd v22, v15, v17
        vsub v17, v15, v17
        vmla v8, v25, v29
        vadd v20, v20, v11
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v25, v30, v6, 3
        str_vo v20, x0, 128
        vmulq v30, v30, v6, 2
        vsub v10, v14, v18
        // gap
        // gap
        // gap
        // gap
        vmla v27, v31, v29
        str_vo v17, x0, 64
        vmla v26, v13, v29
        vadd v18, v14, v18
        // gap
        // gap
        // gap
        // gap
        vmla v30, v25, v29
        str_vo v24, x0, 192
        vqrdmulhq v14, v9, v7, 1
        vadd v13, v28, v8
        // gap
        // gap
        // gap
        // gap
        str_vo v23, x0, 320
        str_vo v13, x0, 384
        vmulq v13, v9, v7, 0
        vsub v28, v28, v8
        // gap
        // gap
        // gap
        // gap
        str_vo v16, x0, 256
        str_vo v28, x0, 448
        vadd v15, v18, v27
        vsub v28, v21, v30
        // gap
        // gap
        // gap
        // gap
        vmla v13, v14, v29
        str_vo v28, x0, 832
        vsub v11, v18, v27
        vadd v28, v21, v30
        // gap
        // gap
        // gap
        // gap
        str_vo v11, x0, 576
        str_vo v28, x0, 768
        vsub v20, v10, v26
        vadd v14, v10, v26
        // gap
        // gap
        ldr_vo v23, x0, 720
        ldr_vo v26, x0, 528
        str_vo v14, x0, 640
        str_vo v20, x0, 704
        vadd v8, v19, v13
        vsub v13, v19, v13
        // gap
        // gap
        ldr_vo v16, x0, 592
        ldr_vo v25, x0, 80
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v11, v26, v0, 1
        str_vi v22, x0, 16
        vmulq v10, v26, v0, 0
        // gap
        // gap
        // gap
        // gap
        // gap
        vmulq v20, v16, v0, 0
        str_vo v13, x0, 944
        vqrdmulhq v19, v16, v0, 1
        // gap
        // gap
        // gap
        ldr_vo v26, x0, 0
        ldr_vo v28, x0, 640
        vmla v10, v11, v29
        str_vo v15, x0, 496
        vqrdmulhq v16, v23, v0, 1
        // gap
        // gap
        // gap
        // gap
        // gap
        vmulq v23, v23, v0, 0
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v17, v28, v0, 1
        vsub v15, v26, v10
        vmla v20, v19, v29
        vadd v10, v26, v10
        // gap
        ldr_vo v31, x0, 192
        ldr_vo v9, x0, 768
        ldr_vo v13, x0, 832
        vmulq v11, v28, v0, 0
        // gap
        vmla v23, v16, v29
        // gap
        // gap
        // gap
        // gap
        ldr_vo v28, x0, 896
        vadd v12, v25, v20
        vsub v26, v25, v20
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vmulq v20, v9, v0, 0
        // gap
        vqrdmulhq v22, v9, v0, 1
        // gap
        // gap
        // gap
        // gap
        ldr_vo v16, x0, 960
        vmulq v9, v13, v0, 0
        // gap
        vqrdmulhq v13, v13, v0, 1
        vsub v24, v31, v23
        // gap
        ldr_vo v14, x0, 256
        // gap
        // gap
        vmla v20, v22, v29
        // gap
        vmla v11, v17, v29
        // gap
        // gap
        // gap
        // gap
        ldr_vo v25, x0, 320
        vmla v9, v13, v29
        str_vo v8, x0, 880
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v22, v28, v0, 1
        // gap
        vmulq v21, v28, v0, 0
        vadd v28, v14, v20
        // gap
        // gap
        // gap
        ldr_vo v13, x0, 128
        vmulq v8, v28, v0, 2
        vsub v27, v25, v9
        vqrdmulhq v28, v28, v0, 3
        vsub v20, v14, v20
        // gap
        // gap
        // gap
        ldr_vo v19, x0, 384
        vmla v21, v22, v29
        // gap
        vmulq v14, v16, v0, 0
        vadd v22, v25, v9
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v9, v22, v0, 3
        vadd v18, v13, v11
        vmulq v25, v22, v0, 2
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vadd v22, v19, v21
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v16, v16, v0, 1
        vadd v31, v31, v23
        vqrdmulhq v23, v22, v0, 3
        // gap
        // gap
        // gap
        // gap
        // gap
        vmulq v30, v20, v1, 0
        vsub v17, v13, v11
        vmulq v11, v22, v0, 2
        // gap
        // gap
        // gap
        // gap
        ldr_vo v13, x0, 448
        vqrdmulhq v20, v20, v1, 1
        // gap
        vmla v14, v16, v29
        vsub v22, v19, v21
        // gap
        // gap
        // gap
        // gap
        vmla v8, v28, v29
        // gap
        vqrdmulhq v28, v27, v1, 1
        // gap
        // gap
        // gap
        // gap
        // gap
        vmulq v21, v27, v1, 0
        // gap
        vmla v25, v9, v29
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v16, v22, v1, 1
        vadd v19, v10, v8
        // gap
        // gap
        // gap
        // gap
        vmla v21, v28, v29
        vadd v28, v13, v14
        vmla v11, v23, v29
        vsub v13, v13, v14
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v27, v28, v0, 3
        vadd v9, v12, v25
        vsub v12, v12, v25
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vsub v25, v18, v11
        // gap
        // gap
        // gap
        // gap
        vmulq v23, v28, v0, 2
        // gap
        vmla v30, v20, v29
        vsub v10, v10, v8
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v20, v13, v1, 1
        // gap
        vmulq v28, v13, v1, 0
        vadd v11, v18, v11
        // gap
        // gap
        // gap
        // gap
        vmla v23, v27, v29
        vadd v14, v15, v30
        vmulq v13, v22, v1, 0
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v28, v20, v29
        vsub v27, v15, v30
        vmulq v30, v11, v1, 2
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v13, v16, v29
        vadd v22, v31, v23
        vqrdmulhq v20, v11, v1, 3
        vadd v16, v26, v21
        // gap
        // gap
        // gap
        // gap
        vmulq v11, v22, v1, 2
        vsub v26, v26, v21
        vqrdmulhq v18, v22, v1, 3
        vsub v31, v31, v23
        // gap
        // gap
        // gap
        // gap
        sub count, count, #1
        cbnz count, layer1234_start
layer1234_end: // end of loop kernel
        vmla v30, v20, v29
        vadd v22, v24, v28
        vqrdmulhq v20, v31, v2, 1
        vsub v21, v24, v28
        vmulq v28, v31, v2, 0
        vadd v24, v17, v13
        vqrdmulhq v15, v25, v2, 1
        vmulq v31, v25, v2, 0
        vsub v8, v19, v30
        vmla v11, v18, v29
        vqrdmulhq v23, v24, v2, 3
        vsub v18, v17, v13
        vmulq v13, v24, v2, 2
        vmla v31, v15, v29
        vadd v30, v19, v30
        vqrdmulhq v17, v22, v2, 3
        vmulq v22, v22, v2, 2
        vsub v19, v9, v11
        vmla v13, v23, v29
        vadd v9, v9, v11
        vqrdmulhq v15, v18, v3, 1
        vadd v25, v10, v31
        vmla v22, v17, v29
        vmulq v17, v18, v3, 0
        vmla v28, v20, v29
        vsub v24, v10, v31
        vmla v17, v15, v29
        vsub v10, v14, v13
        vqrdmulhq v23, v21, v3, 1
        vmulq v21, v21, v3, 0
        vadd v20, v14, v13
        vmulq v15, v9, v3, 2
        vqrdmulhq v13, v9, v3, 3
        vsub v11, v12, v28
        vmla v21, v23, v29
        vadd v31, v12, v28
        vqrdmulhq v28, v11, v5, 1
        vsub v14, v16, v22
        vmulq v9, v11, v5, 0
        vadd v23, v27, v17
        vqrdmulhq v12, v19, v4, 1
        vmulq v18, v19, v4, 0
        vadd v16, v16, v22
        vmulq v11, v31, v4, 2
        vadd v22, v26, v21
        vqrdmulhq v19, v31, v4, 3
        vmla v15, v13, v29
        vmla v18, v12, v29
        vmla v9, v28, v29
        vsub v12, v27, v17
        vmulq v17, v16, v5, 2
        vsub v27, v26, v21
        vqrdmulhq v31, v16, v5, 3
        vsub v21, v8, v18
        vmulq v16, v14, v6, 0
        vadd v8, v8, v18
        vmla v11, v19, v29
        vqrdmulhq v18, v14, v6, 1
        vsub v26, v30, v15
        vmla v17, v31, v29
        vmulq v28, v22, v6, 2
        str_vo v21, x0, 192
        vmulq v21, v27, v7, 0
        vadd v31, v20, v17
        vqrdmulhq v13, v27, v7, 1
        str_vo v8, x0, 128
        vqrdmulhq v8, v22, v6, 3
        vadd v19, v25, v11
        vadd v22, v30, v15
        str_vo v26, x0, 64
        vmla v16, v18, v29
        vsub v30, v25, v11
        vmla v28, v8, v29
        str_vo v31, x0, 512
        vmla v21, v13, v29
        vadd v14, v10, v16
        str_vo v19, x0, 256
        str_vo v14, x0, 640
        vadd v27, v24, v9
        str_vo v27, x0, 384
        str_vi v22, x0, 16
        vsub v25, v23, v28
        vadd v18, v23, v28
        str_vo v25, x0, 816
        str_vo v30, x0, 304
        vadd v26, v12, v21
        vsub v28, v24, v9
        str_vo v26, x0, 880
        str_vo v28, x0, 432
        vsub v28, v10, v16
        vsub v8, v12, v21
        str_vo v18, x0, 752
        str_vo v28, x0, 688
        vsub v28, v20, v17
        str_vo v8, x0, 944
        str_vo v28, x0, 560

        restore inp, STACK0
        mov count, #16

        .unreq root4
        .unreq root5
        .unreq root6
        .unreq root7
        .unreq qform_root4
        .unreq qform_root5
        .unreq qform_root6
        .unreq qform_root7
        root0_tw .req v4
        root1_tw .req v5
        root2_tw .req v6
        root3_tw .req v7
        qform_root0_tw .req q4
        qform_root1_tw .req q5
        qform_root2_tw .req q6
        qform_root3_tw .req q7

        .p2align 2
        ldr_vi v8, x3, 16
        ldr_vo v1, x1, 32
        ldr_vo v22, x1, 0
        ldr_vo v12, x1, 16
        vmulq v13, v1, v8, 0
        vqrdmulhq v28, v1, v8, 1
        ldr_vo v0, x1, 48
        ldr_vi v11, x3, 8
        vmulq v23, v0, v8, 0
        vqrdmulhq v16, v0, v8, 1
        vmla v13, v28, v29
        vmla v23, v16, v29
        vsub v15, v22, v13
        vadd v28, v12, v23
        vmulq v21, v28, v8, 2
        vqrdmulhq v16, v28, v8, 3
        vsub v0, v12, v23
        vmla v21, v16, v29
        vmulq v6, v0, v11, 0
        vqrdmulhq v31, v0, v11, 1
        vadd v0, v22, v13
        vmla v6, v31, v29
        vsub v16, v0, v21
        vadd v28, v15, v6
        vsub v7, v15, v6
        vadd v6, v0, v21
        trn1_s v1, v28, v7
        trn1_s v22, v6, v16
        trn2_s v28, v28, v7
        trn2_s v16, v6, v16
        sub count, count, #1
.p2align 2
layer5678_start:
        trn2_d v6, v22, v1
        trn2_d v8, v16, v28
        trn1_d v25, v22, v1
        trn1_d v31, v16, v28
        // gap
        ldr_vi v13, x4, 96
        ldr_vo v18, x4, -80
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        ldr_vo v15, x4, -32
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vmul v1, v6, v13
        // gap
        vqrdmulh v28, v6, v18
        // gap
        // gap
        ldr_vo v0, x4, -48
        // gap
        // gap
        vqrdmulh v30, v8, v18
        // gap
        vmul v22, v8, v13
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v1, v28, v29
        // gap
        // gap
        ldr_vo v28, x4, -64
        // gap
        // gap
        vmla v22, v30, v29
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vadd v13, v31, v22
        vsub v16, v25, v1
        // gap
        // gap
        // gap
        ldr_vo v27, x4, -16
        // gap
        // gap
        vmul v30, v13, v28
        vsub v28, v31, v22
        vqrdmulh v13, v13, v0
        // gap
        // gap
        // gap
        // gap
        // gap
        vmul v2, v28, v15
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vqrdmulh v28, v28, v27
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v2, v28, v29
        // gap
        vmla v30, v13, v29
        vadd v28, v25, v1
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vsub v5, v28, v30
        vadd v6, v16, v2
        vsub v7, v16, v2
        vadd v4, v28, v30
        // gap
        // gap
        ldr_vi v3, x3, 16
        ldr_vo v1, x1, 32+64
        // gap
        // gap
        // gap
        // gap
        // gap
        ldr_vo v28, x1, 0+64
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v2, v1, v3, 1
        // gap
        vmulq v12, v1, v3, 0
        // gap
        // gap
        ldr_vo v1, x1, 48+64
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v12, v2, v29
        // gap
        // gap
        // gap
        // gap
        // gap
        vqrdmulhq v18, v1, v3, 1
        // gap
        vmulq v15, v1, v3, 0
        // gap
        // gap
        // gap
        // gap
        // gap
        vsub v30, v28, v12
        // gap
        // gap
        // gap
        // gap
        ldr_vo v17, x1, 16+64
        st4 {v4.4S,v5.4S,v6.4S,v7.4S}, [x1], #64
        // gap
        vmla v15, v18, v29
        // gap
        // gap
        // gap
        // gap
        ldr_vi v0, x3, 8
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vadd v13, v17, v15
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vmulq v1, v13, v3, 2
        // gap
        vqrdmulhq v22, v13, v3, 3
        vsub v13, v17, v15
        // gap
        // gap
        // gap
        // gap
        vmulq v31, v13, v0, 0
        // gap
        vqrdmulhq v13, v13, v0, 1
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vmla v31, v13, v29
        // gap
        vmla v1, v22, v29
        vadd v28, v28, v12
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        // gap
        vsub v13, v28, v1
        vadd v23, v30, v31
        vsub v31, v30, v31
        vadd v22, v28, v1
        // gap
        // gap
        // gap
        // gap
        trn2_s v16, v22, v13
        trn2_s v28, v23, v31
        trn1_s v22, v22, v13
        trn1_s v1, v23, v31
        // gap
        // gap
        // gap
        // gap
        sub count, count, #1
        cbnz count, layer5678_start
layer5678_end: // end of loop kernel
        ldr_vi v5, x4, 96
        ldr_vo v25, x4, -80
        trn1_d v13, v16, v28
        trn1_d v17, v22, v1
        trn2_d v18, v16, v28
        ldr_vo v4, x4, -64
        trn2_d v28, v22, v1
        ldr_vo v14, x4, -48
        vqrdmulh v22, v28, v25
        vmul v28, v28, v5
        ldr_vo v15, x4, -32
        vmul v5, v18, v5
        vqrdmulh v23, v18, v25
        vmla v28, v22, v29
        vsub v8, v17, v28
        vmla v5, v23, v29
        vadd v23, v13, v5
        vsub v22, v13, v5
        vqrdmulh v16, v23, v14
        vmul v13, v23, v4
        vmla v13, v16, v29
        ldr_vo v23, x4, -16
        vadd v16, v17, v28
        vmul v28, v22, v15
        vqrdmulh v22, v22, v23
        vadd v1, v16, v13
        vmla v28, v22, v29
        vsub v2, v16, v13
        vsub v4, v8, v28
        vadd v3, v8, v28
        st4 {v1.4S,v2.4S,v3.4S,v4.4S}, [x1], #64

       pop_stack
       ret
