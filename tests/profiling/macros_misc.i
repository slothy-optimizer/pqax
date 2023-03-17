xtmp0 .req x10
xtmp1 .req x11
.macro vins vec_out, gpr_in, lane                // slothy:no-unfold
        ins \vec_out\().d[\lane], \gpr_in
.endm

.macro vext gpr_out, vec_in, lane                // slothy:no-unfold
        umov \gpr_out\(), \vec_in\().d[\lane]
.endm

.macro ldr_vo vec, base, offset
        ldr xtmp0, [\base, #\offset]
        ldr xtmp1, [\base, #(\offset+8)]
        vins \vec, xtmp0, 0
        vins \vec, xtmp1, 1
.endm

.macro ldr_vi vec, base, inc
        ldr xtmp0, [\base], #\inc
        ldr xtmp1, [\base, #(-\inc+8)]
        vins \vec, xtmp0, 0
        vins \vec, xtmp1, 1
.endm

.macro str_vo vec, base, offset                     // slothy:no-unfold
        str qform_\vec, [\base, #\offset]
.endm
.macro str_vi vec, base, inc                        // slothy:no-unfold
        str qform_\vec, [\base], #\inc
.endm

.macro vsub d,a,b                                   // slothy:no-unfold
        sub \d\().8h, \a\().8h, \b\().8h
.endm
.macro vadd d,a,b                                   // slothy:no-unfold
        add \d\().8h, \a\().8h, \b\().8h
.endm
.macro vqrdmulh d,a,b                               // slothy:no-unfold
        sqrdmulh \d\().8h, \a\().8h, \b\().8h
.endm
.macro vmul d,a,b                                   // slothy:no-unfold
        mul \d\().8h, \a\().8h, \b\().8h
.endm
.macro vmlsq d,a,b,i                                // slothy:no-unfold
        mls \d\().8h, \a\().8h, \b\().h[\i]
.endm
.macro vmls d,a,b                                // slothy:no-unfold
        mls \d\().8h, \a\().8h, \b\().8h
.endm
.macro vqrdmulhq d,a,b,i                            // slothy:no-unfold
        sqrdmulh \d\().8h, \a\().8h, \b\().h[\i]
.endm
.macro vqdmulhq d,a,b,i                            // slothy:no-unfold
        sqdmulh \d\().8h, \a\().8h, \b\().h[\i]
.endm
.macro vmulq d,a,b,i                                // slothy:no-unfold
        mul \d\().8h, \a\().8h, \b\().h[\i]
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

.macro restore a, loc     // slothy:no-unfold
        ldr \a, [sp, #\loc\()]
.endm
.macro save loc, a        // slothy:no-unfold
        str \a, [sp, #\loc\()]
.endm

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
