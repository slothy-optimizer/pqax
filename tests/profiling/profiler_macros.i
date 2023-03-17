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

// #else
//.macro ldr_vo vec, base, offset                    // slothy:no-unfold
//        ldr qform_\vec, [\base, #\offset]
//.endm
// .macro ldr_vi vec, base, inc                        // slothy:no-unfold
//         ldr qform_\vec, [\base], #\inc
// .endm
// #endif

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

.macro mulmodq dst, src, const, idx0, idx1
        vmulq       \dst,  \src, \const, \idx0
        vqrdmulhq   \src,  \src, \const, \idx1
        vmlsq        \dst,  \src, consts, 0
.endm

.macro mulmod dst, src, const, const_twisted
        vmul       \dst,  \src, \const
        vqrdmulh   \src,  \src, \const_twisted
        vmlsq      \dst,  \src, consts, 0
.endm

.macro ct_butterfly a, b, root, idx0, idx1
        mulmodq  tmp, \b, \root, \idx0, \idx1
        vsub     \b,    \a, tmp
        vadd     \a,    \a, tmp
.endm

.macro mulmod_v dst, src, const, const_twisted
        vmul        \dst,  \src, \const
        vqrdmulh    \src,  \src, \const_twisted
        vmlsq       \dst,  \src, consts, 0
.endm

.macro ct_butterfly_v a, b, root, root_twisted
        mulmod  tmp, \b, \root, \root_twisted
        vsub    \b,    \a, tmp
        vadd    \a,    \a, tmp
.endm

.macro barrett_reduce a
        vqdmulhq tmp, \a, consts, 1
        srshr    tmp.8H, tmp.8H, #11
        vmlsq    \a, tmp, consts, 0
.endm

.macro load_roots_123
        ldr_vi root0, r_ptr0, 32
        ldr_vo root1, r_ptr0, -16
.endm

.macro load_next_roots_45
        ldr_vi root0, r_ptr0, 16
.endm

.macro load_next_roots_67
        ldr_vi root0,    r_ptr1, (6*16)
        ldr_vo root0_tw, r_ptr1, (-6*16 + 1*16)
        ldr_vo root1,    r_ptr1, (-6*16 + 2*16)
        ldr_vo root1_tw, r_ptr1, (-6*16 + 3*16)
        ldr_vo root2,    r_ptr1, (-6*16 + 4*16)
        ldr_vo root2_tw, r_ptr1, (-6*16 + 5*16)
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

.macro transpose_single data_out, data_in
        trn1_s \data_out\()0, \data_in\()0, \data_in\()1
        trn2_s \data_out\()1, \data_in\()0, \data_in\()1
        trn1_s \data_out\()2, \data_in\()2, \data_in\()3
        trn2_s \data_out\()3, \data_in\()2, \data_in\()3
.endm
