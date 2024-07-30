// for ABI

.macro push_all

    sub sp, sp, #(16*9)
    stp x19, x20, [sp, #16*0]
    stp x21, x22, [sp, #16*1]
    stp x23, x24, [sp, #16*2]
    stp x25, x26, [sp, #16*3]
    stp x27, x28, [sp, #16*4]
    stp  d8,  d9, [sp, #16*5]
    stp d10, d11, [sp, #16*6]
    stp d12, d13, [sp, #16*7]
    stp d14, d15, [sp, #16*8]

.endm

.macro pop_all

    ldp x19, x20, [sp, #16*0]
    ldp x21, x22, [sp, #16*1]
    ldp x23, x24, [sp, #16*2]
    ldp x25, x26, [sp, #16*3]
    ldp x27, x28, [sp, #16*4]
    ldp  d8,  d9, [sp, #16*5]
    ldp d10, d11, [sp, #16*6]
    ldp d12, d13, [sp, #16*7]
    ldp d14, d15, [sp, #16*8]
    add sp, sp, #(16*9)

.endm

// vector-scalar butterflies

.macro wrap_dX_butterfly_top a0, a1, b0, b1, t0, t1, mod, z0, l0, h0, z1, l1, h1, wX, nX

    mul      \t0\wX, \b0\wX, \z0\nX[\h0]
    mul      \t1\wX, \b1\wX, \z1\nX[\h1]

    sqrdmulh \b0\wX, \b0\wX, \z0\nX[\l0]
    sqrdmulh \b1\wX, \b1\wX, \z1\nX[\l1]

    mls      \t0\wX, \b0\wX, \mod\nX[0]
    mls      \t1\wX, \b1\wX, \mod\nX[0]

.endm

.macro wrap_dX_butterfly_bot a0, a1, b0, b1, t0, t1, mod, z0, l0, h0, z1, l1, h1, wX, nX

    sub     \b0\wX, \a0\wX, \t0\wX
    sub     \b1\wX, \a1\wX, \t1\wX

    add     \a0\wX, \a0\wX, \t0\wX
    add     \a1\wX, \a1\wX, \t1\wX

.endm

.macro wrap_dX_butterfly_mixed a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, wX, nX

    sub      \b0\wX, \a0\wX, \t0\wX
    mul      \t2\wX, \b2\wX, \z2\nX[\h2]
    sub      \b1\wX, \a1\wX, \t1\wX
    mul      \t3\wX, \b3\wX, \z3\nX[\h3]

    add      \a0\wX, \a0\wX, \t0\wX
    sqrdmulh \b2\wX, \b2\wX, \z2\nX[\l2]
    add      \a1\wX, \a1\wX, \t1\wX
    sqrdmulh \b3\wX, \b3\wX, \z3\nX[\l3]

    mls      \t2\wX, \b2\wX, \mod\nX[0]
    mls      \t3\wX, \b3\wX, \mod\nX[0]

.endm

.macro wrap_dX_butterfly_mixed_rev a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, wX, nX

    mul      \t0\wX, \b0\wX, \z0\nX[\h0]
    sub      \b2\wX, \a2\wX, \t2\wX
    mul      \t1\wX, \b1\wX, \z1\nX[\h1]
    sub      \b3\wX, \a3\wX, \t3\wX

    sqrdmulh \b0\wX, \b0\wX, \z0\nX[\l0]
    add      \a2\wX, \a2\wX, \t2\wX
    sqrdmulh \b1\wX, \b1\wX, \z1\nX[\l1]
    add      \a3\wX, \a3\wX, \t3\wX

    mls      \t0\wX, \b0\wX, \mod\nX[0]
    mls      \t1\wX, \b1\wX, \mod\nX[0]

.endm

.macro wrap_qX_butterfly_top a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, wX, nX

    mul      \t0\wX, \b0\wX, \z0\nX[\h0]
    mul      \t1\wX, \b1\wX, \z1\nX[\h1]
    mul      \t2\wX, \b2\wX, \z2\nX[\h2]
    mul      \t3\wX, \b3\wX, \z3\nX[\h3]

    sqrdmulh \b0\wX, \b0\wX, \z0\nX[\l0]
    sqrdmulh \b1\wX, \b1\wX, \z1\nX[\l1]
    sqrdmulh \b2\wX, \b2\wX, \z2\nX[\l2]
    sqrdmulh \b3\wX, \b3\wX, \z3\nX[\l3]

    mls      \t0\wX, \b0\wX, \mod\nX[0]
    mls      \t1\wX, \b1\wX, \mod\nX[0]
    mls      \t2\wX, \b2\wX, \mod\nX[0]
    mls      \t3\wX, \b3\wX, \mod\nX[0]

.endm

.macro wrap_qX_butterfly_bot a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, wX, nX

    sub     \b0\wX, \a0\wX, \t0\wX
    sub     \b1\wX, \a1\wX, \t1\wX
    sub     \b2\wX, \a2\wX, \t2\wX
    sub     \b3\wX, \a3\wX, \t3\wX

    add     \a0\wX, \a0\wX, \t0\wX
    add     \a1\wX, \a1\wX, \t1\wX
    add     \a2\wX, \a2\wX, \t2\wX
    add     \a3\wX, \a3\wX, \t3\wX

.endm

.macro wrap_qX_butterfly_mixed a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, a4, a5, a6, a7, b4, b5, b6, b7, t4, t5, t6, t7, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, z4, l4, h4, z5, l5, h5, z6, l6, h6, z7, l7, h7, wX, nX

    sub      \b0\wX, \a0\wX, \t0\wX
    mul      \t4\wX, \b4\wX, \z4\nX[\h4]
    sub      \b1\wX, \a1\wX, \t1\wX
    mul      \t5\wX, \b5\wX, \z5\nX[\h5]
    sub      \b2\wX, \a2\wX, \t2\wX
    mul      \t6\wX, \b6\wX, \z6\nX[\h6]
    sub      \b3\wX, \a3\wX, \t3\wX
    mul      \t7\wX, \b7\wX, \z7\nX[\h7]

    add      \a0\wX, \a0\wX, \t0\wX
    sqrdmulh \b4\wX, \b4\wX, \z4\nX[\l4]
    add      \a1\wX, \a1\wX, \t1\wX
    sqrdmulh \b5\wX, \b5\wX, \z5\nX[\l5]
    add      \a2\wX, \a2\wX, \t2\wX
    sqrdmulh \b6\wX, \b6\wX, \z6\nX[\l6]
    add      \a3\wX, \a3\wX, \t3\wX
    sqrdmulh \b7\wX, \b7\wX, \z7\nX[\l7]

    mls      \t4\wX, \b4\wX, \mod\nX[0]
    mls      \t5\wX, \b5\wX, \mod\nX[0]
    mls      \t6\wX, \b6\wX, \mod\nX[0]
    mls      \t7\wX, \b7\wX, \mod\nX[0]

.endm

.macro wrap_qX_butterfly_mixed_rev a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, a4, a5, a6, a7, b4, b5, b6, b7, t4, t5, t6, t7, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, z4, l4, h4, z5, l5, h5, z6, l6, h6, z7, l7, h7, wX, nX

    mul      \t0\wX, \b0\wX, \z0\nX[\h0]
    sub      \b4\wX, \a4\wX, \t4\wX
    mul      \t1\wX, \b1\wX, \z1\nX[\h1]
    sub      \b5\wX, \a5\wX, \t5\wX
    mul      \t2\wX, \b2\wX, \z2\nX[\h2]
    sub      \b6\wX, \a6\wX, \t6\wX
    mul      \t3\wX, \b3\wX, \z3\nX[\h3]
    sub      \b7\wX, \a7\wX, \t7\wX

    sqrdmulh \b0\wX, \b0\wX, \z0\nX[\l0]
    add      \a4\wX, \a4\wX, \t4\wX
    sqrdmulh \b1\wX, \b1\wX, \z1\nX[\l1]
    add      \a5\wX, \a5\wX, \t5\wX
    sqrdmulh \b2\wX, \b2\wX, \z2\nX[\l2]
    add      \a6\wX, \a6\wX, \t6\wX
    sqrdmulh \b3\wX, \b3\wX, \z3\nX[\l3]
    add      \a7\wX, \a7\wX, \t7\wX

    mls      \t0\wX, \b0\wX, \mod\nX[0]
    mls      \t1\wX, \b1\wX, \mod\nX[0]
    mls      \t2\wX, \b2\wX, \mod\nX[0]
    mls      \t3\wX, \b3\wX, \mod\nX[0]

.endm

// vector-vector butterflies

.macro wrap_dX_butterfly_vec_top a0, a1, b0, b1, t0, t1, mod, l0, h0, l1, h1, wX, nX

    mul      \t0\wX, \b0\wX, \h0\wX
    mul      \t1\wX, \b1\wX, \h1\wX

    sqrdmulh \b0\wX, \b0\wX, \l0\wX
    sqrdmulh \b1\wX, \b1\wX, \l1\wX

    mls      \t0\wX, \b0\wX, \mod\nX[0]
    mls      \t1\wX, \b1\wX, \mod\nX[0]

.endm

.macro wrap_dX_butterfly_vec_bot a0, a1, b0, b1, t0, t1, mod, l0, h0, l1, h1, wX, nX

    sub     \b0\wX, \a0\wX, \t0\wX
    sub     \b1\wX, \a1\wX, \t1\wX

    add     \a0\wX, \a0\wX, \t0\wX
    add     \a1\wX, \a1\wX, \t1\wX

.endm

.macro wrap_dX_butterfly_vec_mixed a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, l0, h0, l1, h1, l2, h2, l3, h3, wX, nX

    sub      \b0\wX, \a0\wX, \t0\wX
    mul      \t2\wX, \b2\wX, \h2\wX
    sub      \b1\wX, \a1\wX, \t1\wX
    mul      \t3\wX, \b3\wX, \h3\wX

    add      \a0\wX, \a0\wX, \t0\wX
    sqrdmulh \b2\wX, \b2\wX, \l2\wX
    add      \a1\wX, \a1\wX, \t1\wX
    sqrdmulh \b3\wX, \b3\wX, \l3\wX

    mls      \t2\wX, \b2\wX, \mod\nX[0]
    mls      \t3\wX, \b3\wX, \mod\nX[0]

.endm

.macro wrap_dX_butterfly_vec_mixed_rev a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, l0, h0, l1, h1, l2, h2, l3, h3, wX, nX

    mul      \t0\wX, \b0\wX, \h0\wX
    sub      \b2\wX, \a2\wX, \t2\wX
    mul      \t1\wX, \b1\wX, \h1\wX
    sub      \b3\wX, \a3\wX, \t3\wX

    sqrdmulh \b0\wX, \b0\wX, \l0\wX
    add      \a2\wX, \a2\wX, \t2\wX
    sqrdmulh \b1\wX, \b1\wX, \l1\wX
    add      \a3\wX, \a3\wX, \t3\wX

    mls      \t0\wX, \b0\wX, \mod\nX[0]
    mls      \t1\wX, \b1\wX, \mod\nX[0]

.endm

// vector-scalar Barrett reduction

.macro wrap_qX_barrett a0, a1, a2, a3, t0, t1, t2, t3, barrett_const, shrv, Q, wX, nX

    sqdmulh \t0\wX, \a0\wX, \barrett_const\nX[0]
    sqdmulh \t1\wX, \a1\wX, \barrett_const\nX[0]

    sqdmulh \t2\wX, \a2\wX, \barrett_const\nX[0]
    srshr   \t0\wX, \t0\wX, \shrv
    sqdmulh \t3\wX, \a3\wX, \barrett_const\nX[0]
    srshr   \t1\wX, \t1\wX, \shrv

    srshr   \t2\wX, \t2\wX, \shrv
    mls     \a0\wX, \t0\wX, \Q\wX
    srshr   \t3\wX, \t3\wX, \shrv
    mls     \a1\wX, \t1\wX, \Q\wX

    mls     \a2\wX, \t2\wX, \Q\wX
    mls     \a3\wX, \t3\wX, \Q\wX

.endm

.macro wrap_oX_barrett a0, a1, a2, a3, t0, t1, t2, t3, a4, a5, a6, a7, t4, t5, t6, t7, barrett_const, shrv, Q, wX, nX

    sqdmulh \t0\wX, \a0\wX, \barrett_const\nX[0]
    sqdmulh \t1\wX, \a1\wX, \barrett_const\nX[0]
    sqdmulh \t2\wX, \a2\wX, \barrett_const\nX[0]
    sqdmulh \t3\wX, \a3\wX, \barrett_const\nX[0]

    srshr   \t0\wX, \t0\wX, \shrv
    sqdmulh \t4\wX, \a4\wX, \barrett_const\nX[0]
    srshr   \t1\wX, \t1\wX, \shrv
    sqdmulh \t5\wX, \a5\wX, \barrett_const\nX[0]
    srshr   \t2\wX, \t2\wX, \shrv
    sqdmulh \t6\wX, \a6\wX, \barrett_const\nX[0]
    srshr   \t3\wX, \t3\wX, \shrv
    sqdmulh \t7\wX, \a7\wX, \barrett_const\nX[0]

    mls     \a0\wX, \t0\wX, \Q\wX
    srshr   \t4\wX, \t4\wX, \shrv
    mls     \a1\wX, \t1\wX, \Q\wX
    srshr   \t5\wX, \t5\wX, \shrv
    mls     \a2\wX, \t2\wX, \Q\wX
    srshr   \t6\wX, \t6\wX, \shrv
    mls     \a3\wX, \t3\wX, \Q\wX
    srshr   \t7\wX, \t7\wX, \shrv

    mls     \a4\wX, \t4\wX, \Q\wX
    mls     \a5\wX, \t5\wX, \Q\wX
    mls     \a6\wX, \t6\wX, \Q\wX
    mls     \a7\wX, \t7\wX, \Q\wX

.endm

// vector-vector Barrett reduction

.macro wrap_qo_barrett_vec a0, a1, a2, a3, t0, t1, t2, t3, barrett_const, shrv, Q, wX, nX

    sqdmulh \t0\wX, \a0\wX, \barrett_const\wX
    sqdmulh \t1\wX, \a1\wX, \barrett_const\wX

    sqdmulh \t2\wX, \a2\wX, \barrett_const\wX
    srshr   \t0\wX, \t0\wX, \shrv
    sqdmulh \t3\wX, \a3\wX, \barrett_const\wX
    srshr   \t1\wX, \t1\wX, \shrv

    srshr   \t2\wX, \t2\wX, \shrv
    mls     \a0\wX, \t0\wX, \Q\wX
    srshr   \t3\wX, \t3\wX, \shrv
    mls     \a1\wX, \t1\wX, \Q\wX

    mls     \a2\wX, \t2\wX, \Q\wX
    mls     \a3\wX, \t3\wX, \Q\wX

.endm

.macro wrap_oo_barrett_vec a0, a1, a2, a3, t0, t1, t2, t3, a4, a5, a6, a7, t4, t5, t6, t7, barrett_const, shrv, Q, wX, nX

    sqdmulh \t0\wX, \a0\wX, \barrett_const\wX
    sqdmulh \t1\wX, \a1\wX, \barrett_const\wX
    sqdmulh \t2\wX, \a2\wX, \barrett_const\wX
    sqdmulh \t3\wX, \a3\wX, \barrett_const\wX

    srshr   \t0\wX, \t0\wX, \shrv
    sqdmulh \t4\wX, \a4\wX, \barrett_const\wX
    srshr   \t1\wX, \t1\wX, \shrv
    sqdmulh \t5\wX, \a5\wX, \barrett_const\wX
    srshr   \t2\wX, \t2\wX, \shrv
    sqdmulh \t6\wX, \a6\wX, \barrett_const\wX
    srshr   \t3\wX, \t3\wX, \shrv
    sqdmulh \t7\wX, \a7\wX, \barrett_const\wX

    mls     \a0\wX, \t0\wX, \Q\wX
    srshr   \t4\wX, \t4\wX, \shrv
    mls     \a1\wX, \t1\wX, \Q\wX
    srshr   \t5\wX, \t5\wX, \shrv
    mls     \a2\wX, \t2\wX, \Q\wX
    srshr   \t6\wX, \t6\wX, \shrv
    mls     \a3\wX, \t3\wX, \Q\wX
    srshr   \t7\wX, \t7\wX, \shrv

    mls     \a4\wX, \t4\wX, \Q\wX
    mls     \a5\wX, \t5\wX, \Q\wX
    mls     \a6\wX, \t6\wX, \Q\wX
    mls     \a7\wX, \t7\wX, \Q\wX

.endm

// Montgomery multiplication

.macro wrap_qX_montgomery_mul b0, b1, b2, b3, t0, t1, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, wX, nX

    mul      \b0\wX, \t0\wX, \z0\nX[\h0]
    mul      \b1\wX, \t1\wX, \z1\nX[\h1]
    mul      \b2\wX, \t2\wX, \z2\nX[\h2]
    mul      \b3\wX, \t3\wX, \z3\nX[\h3]

    sqrdmulh \t0\wX, \t0\wX, \z0\nX[\l0]
    sqrdmulh \t1\wX, \t1\wX, \z1\nX[\l1]
    sqrdmulh \t2\wX, \t2\wX, \z2\nX[\l2]
    sqrdmulh \t3\wX, \t3\wX, \z3\nX[\l3]

    mls      \b0\wX, \t0\wX, \mod\nX[0]
    mls      \b1\wX, \t1\wX, \mod\nX[0]
    mls      \b2\wX, \t2\wX, \mod\nX[0]
    mls      \b3\wX, \t3\wX, \mod\nX[0]

.endm

// Montgomery reduction with long

.macro wrap_qX_montgomery c0, c1, c2, c3, l0, l1, l2, l3, h0, h1, h2, h3, t0, t1, t2, t3, Qprime, Q, lX, wX, dwX

    uzp1 \t0\wX, \l0\wX, \h0\wX
    uzp1 \t1\wX, \l1\wX, \h1\wX
    uzp1 \t2\wX, \l2\wX, \h2\wX
    uzp1 \t3\wX, \l3\wX, \h3\wX

    mul \t0\wX, \t0\wX, \Qprime\wX
    mul \t1\wX, \t1\wX, \Qprime\wX
    mul \t2\wX, \t2\wX, \Qprime\wX
    mul \t3\wX, \t3\wX, \Qprime\wX

    smlal  \l0\dwX, \t0\lX, \Q\lX
    smlal2 \h0\dwX, \t0\wX, \Q\wX
    smlal  \l1\dwX, \t1\lX, \Q\lX
    smlal2 \h1\dwX, \t1\wX, \Q\wX
    smlal  \l2\dwX, \t2\lX, \Q\lX
    smlal2 \h2\dwX, \t2\wX, \Q\wX
    smlal  \l3\dwX, \t3\lX, \Q\lX
    smlal2 \h3\dwX, \t3\wX, \Q\wX

    uzp2 \c0\wX, \l0\wX, \h0\wX
    uzp2 \c1\wX, \l1\wX, \h1\wX
    uzp2 \c2\wX, \l2\wX, \h2\wX
    uzp2 \c3\wX, \l3\wX, \h3\wX

.endm

// add_sub, sub_add

.macro wrap_qX_add_sub s0, s1, s2, s3, t0, t1, t2, t3, a0, a1, a2, a3, b0, b1, b2, b3, wX

    add \s0\wX, \a0\wX, \b0\wX
    sub \t0\wX, \a0\wX, \b0\wX
    add \s1\wX, \a1\wX, \b1\wX
    sub \t1\wX, \a1\wX, \b1\wX
    add \s2\wX, \a2\wX, \b2\wX
    sub \t2\wX, \a2\wX, \b2\wX
    add \s3\wX, \a3\wX, \b3\wX
    sub \t3\wX, \a3\wX, \b3\wX

.endm

.macro wrap_qX_sub_add s0, s1, s2, s3, t0, t1, t2, t3, a0, a1, a2, a3, b0, b1, b2, b3, wX

    sub \t0\wX, \a0\wX, \b0\wX
    add \s0\wX, \a0\wX, \b0\wX
    sub \t1\wX, \a1\wX, \b1\wX
    add \s1\wX, \a1\wX, \b1\wX
    sub \t2\wX, \a2\wX, \b2\wX
    add \s2\wX, \a2\wX, \b2\wX
    sub \t3\wX, \a3\wX, \b3\wX
    add \s3\wX, \a3\wX, \b3\wX

.endm


.macro qo_barrett a0, a1, a2, a3, t0, t1, t2, t3, barrett_const, shrv, Q
    wrap_qX_barrett \a0, \a1, \a2, \a3, \t0, \t1, \t2, \t3, \barrett_const, \shrv, \Q, .8H, .H
.endm

.macro oo_barrett a0, a1, a2, a3, t0, t1, t2, t3, a4, a5, a6, a7, t4, t5, t6, t7, barrett_const, shrv, Q
    wrap_oX_barrett \a0, \a1, \a2, \a3, \t0, \t1, \t2, \t3, \a4, \a5, \a6, \a7, \t4, \t5, \t6, \t7, \barrett_const, \shrv, \Q, .8H, .H
.endm


.macro qo_barrett_vec a0, a1, a2, a3, t0, t1, t2, t3, barrett_const, shrv, Q
    wrap_qo_barrett_vec \a0, \a1, \a2, \a3, \t0, \t1, \t2, \t3, \barrett_const, \shrv, \Q, .8H, .H
.endm

.macro oo_barrett_vec a0, a1, a2, a3, t0, t1, t2, t3, a4, a5, a6, a7, t4, t5, t6, t7, barrett_const, shrv, Q
    wrap_oo_barrett_vec \a0, \a1, \a2, \a3, \t0, \t1, \t2, \t3, \a4, \a5, \a6, \a7, \t4, \t5, \t6, \t7, \barrett_const, \shrv, \Q, .8H, .H
.endm


.macro qo_butterfly_top a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3
    wrap_qX_butterfly_top \a0, \a1, \a2, \a3, \b0, \b1, \b2, \b3, \t0, \t1, \t2, \t3, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, .8H, .H
.endm

.macro qo_butterfly_bot a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3
    wrap_qX_butterfly_bot \a0, \a1, \a2, \a3, \b0, \b1, \b2, \b3, \t0, \t1, \t2, \t3, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, .8H, .H
.endm

.macro qo_butterfly_mixed a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, a4, a5, a6, a7, b4, b5, b6, b7, t4, t5, t6, t7, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, z4, l4, h4, z5, l5, h5, z6, l6, h6, z7, l7, h7
    wrap_qX_butterfly_mixed \a0, \a1, \a2, \a3, \b0, \b1, \b2, \b3, \t0, \t1, \t2, \t3, \a4, \a5, \a6, \a7, \b4, \b5, \b6, \b7, \t4, \t5, \t6, \t7, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, \z4, \l4, \h4, \z5, \l5, \h5, \z6, \l6, \h6, \z7, \l7, \h7, .8H, .H
.endm

.macro qo_butterfly_mixed_rev a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, a4, a5, a6, a7, b4, b5, b6, b7, t4, t5, t6, t7, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, z4, l4, h4, z5, l5, h5, z6, l6, h6, z7, l7, h7
    wrap_qX_butterfly_mixed_rev \a0, \a1, \a2, \a3, \b0, \b1, \b2, \b3, \t0, \t1, \t2, \t3, \a4, \a5, \a6, \a7, \b4, \b5, \b6, \b7, \t4, \t5, \t6, \t7, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, \z4, \l4, \h4, \z5, \l5, \h5, \z6, \l6, \h6, \z7, \l7, \h7, .8H, .H
.endm


.macro do_butterfly_vec_top a0, a1, b0, b1, t0, t1, mod, l0, h0, l1, h1
    wrap_dX_butterfly_vec_top \a0, \a1, \b0, \b1, \t0, \t1, \mod, \l0, \h0, \l1, \h1, .8H, .H
.endm

.macro do_butterfly_vec_bot a0, a1, b0, b1, t0, t1, mod, l0, h0, l1, h1
    wrap_dX_butterfly_vec_bot \a0, \a1, \b0, \b1, \t0, \t1, \mod, \l0, \h0, \l1, \h1, .8H, .H
.endm

.macro do_butterfly_vec_mixed a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, l0, h0, l1, h1, l2, h2, l3, h3
    wrap_dX_butterfly_vec_mixed \a0, \a1, \b0, \b1, \t0, \t1, \a2, \a3, \b2, \b3, \t2, \t3, \mod, \l0, \h0, \l1, \h1, \l2, \h2, \l3, \h3, .8H, .H
.endm

.macro do_butterfly_vec_mixed_rev a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, l0, h0, l1, h1, l2, h2, l3, h3
    wrap_dX_butterfly_vec_mixed_rev \a0, \a1, \b0, \b1, \t0, \t1, \a2, \a3, \b2, \b3, \t2, \t3, \mod, \l0, \h0, \l1, \h1, \l2, \h2, \l3, \h3, .8H, .H
.endm



.align 2
.global __asm_ntt_SIMD_top
.global ___asm_ntt_SIMD_top
__asm_ntt_SIMD_top:
___asm_ntt_SIMD_top:

    push_all
    Q         .req w20
    src0      .req x0
    src1      .req x1
    src2      .req x2
    src3      .req x3
    src4      .req x4
    src5      .req x5
    src6      .req x6
    src7      .req x7
    src8      .req x8
    src9      .req x9
    src10     .req x10
    src11     .req x11
    src12     .req x12
    src13     .req x13
    src14     .req x14
    src15     .req x15
    table     .req x28
    counter   .req x19

    ldrsh Q, [x2, #0]

    mov table, x1

    add  src0, x0,  #32*0
    add  src1, x0,  #32*1
    add  src2, x0,  #32*2
    add  src3, x0,  #32*3
    add  src4, x0,  #32*4
    add  src5, x0,  #32*5
    add  src6, x0,  #32*6
    add  src7, x0,  #32*7
    add  src8, x0,  #32*8
    add  src9, x0,  #32*9
    add src10, x0, #32*10
    add src11, x0, #32*11
    add src12, x0, #32*12
    add src13, x0, #32*13
    add src14, x0, #32*14
    add src15, x0, #32*15

    ld1 { v0.8H,  v1.8H,  v2.8H,  v3.8H}, [table], #64

    mov v0.H[0], Q

    ld1 { v4.8H}, [ src0]
    ld1 { v5.8H}, [ src1]
    ld1 { v6.8H}, [ src2]
    ld1 { v7.8H}, [ src3]
    ld1 { v8.8H}, [ src4]
    ld1 { v9.8H}, [ src5]
    ld1 {v10.8H}, [ src6]
    ld1 {v11.8H}, [ src7]

    ld1 {v12.8H}, [ src8]
    ld1 {v13.8H}, [ src9]
    ld1 {v14.8H}, [src10]
    ld1 {v15.8H}, [src11]
    ld1 {v16.8H}, [src12]
    ld1 {v17.8H}, [src13]
    ld1 {v18.8H}, [src14]
    ld1 {v19.8H}, [src15]

    qo_butterfly_top  v5,  v7,  v9, v11, v13, v15, v17, v19, v28, v29, v30, v31,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3
    qo_butterfly_mixed  v5,  v7,  v9, v11, v13, v15, v17, v19, v28, v29, v30, v31,  v4,  v6,  v8, v10, v12, v14, v16, v18, v20, v21, v22, v23,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3
    qo_butterfly_mixed  v4,  v6,  v8, v10, v12, v14, v16, v18, v20, v21, v22, v23,  v5,  v7, v13, v15,  v9, v11, v17, v19, v28, v29, v30, v31,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 4, 5,  v0, 4, 5,  v0, 6, 7,  v0, 6, 7
    qo_butterfly_mixed  v5,  v7, v13, v15,  v9, v11, v17, v19, v28, v29, v30, v31,  v4,  v6, v12, v14,  v8, v10, v16, v18, v20, v21, v22, v23,  v0,  v0, 4, 5,  v0, 4, 5,  v0, 6, 7,  v0, 6, 7,  v0, 4, 5,  v0, 4, 5,  v0, 6, 7,  v0, 6, 7
    qo_butterfly_mixed  v4,  v6, v12, v14,  v8, v10, v16, v18, v20, v21, v22, v23,  v5,  v9, v13, v17,  v7, v11, v15, v19, v28, v29, v30, v31,  v0,  v0, 4, 5,  v0, 4, 5,  v0, 6, 7,  v0, 6, 7,  v1, 0, 1,  v1, 2, 3,  v1, 4, 5,  v1, 6, 7
    qo_butterfly_mixed  v5,  v9, v13, v17,  v7, v11, v15, v19, v28, v29, v30, v31,  v4,  v8, v12, v16,  v6, v10, v14, v18, v20, v21, v22, v23,  v0,  v1, 0, 1,  v1, 2, 3,  v1, 4, 5,  v1, 6, 7,  v1, 0, 1,  v1, 2, 3,  v1, 4, 5,  v1, 6, 7
    qo_butterfly_mixed  v4,  v8, v12, v16,  v6, v10, v14, v18, v20, v21, v22, v23,  v4,  v6,  v8, v10,  v5,  v7,  v9, v11, v28, v29, v30, v31,  v0,  v1, 0, 1,  v1, 2, 3,  v1, 4, 5,  v1, 6, 7,  v2, 0, 1,  v2, 2, 3,  v2, 4, 5,  v2, 6, 7
    qo_butterfly_mixed  v4,  v6,  v8, v10,  v5,  v7,  v9, v11, v28, v29, v30, v31, v12, v14, v16, v18, v13, v15, v17, v19, v20, v21, v22, v23,  v0,  v2, 0, 1,  v2, 2, 3,  v2, 4, 5,  v2, 6, 7,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7
    qo_butterfly_bot v12, v14, v16, v18, v13, v15, v17, v19, v20, v21, v22, v23,  v0,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7

    st1 { v4.8H}, [ src0], #16
    ld1 { v4.8H}, [ src0]
    st1 { v5.8H}, [ src1], #16
    ld1 { v5.8H}, [ src1]
    st1 { v6.8H}, [ src2], #16
    ld1 { v6.8H}, [ src2]
    st1 { v7.8H}, [ src3], #16
    ld1 { v7.8H}, [ src3]
    st1 { v8.8H}, [ src4], #16
    ld1 { v8.8H}, [ src4]
    st1 { v9.8H}, [ src5], #16
    ld1 { v9.8H}, [ src5]
    st1 {v10.8H}, [ src6], #16
    ld1 {v10.8H}, [ src6]
    st1 {v11.8H}, [ src7], #16
    ld1 {v11.8H}, [ src7]

    st1 {v12.8H}, [ src8], #16
    ld1 {v12.8H}, [ src8]
    st1 {v13.8H}, [ src9], #16
    ld1 {v13.8H}, [ src9]
    st1 {v14.8H}, [src10], #16
    ld1 {v14.8H}, [src10]
    st1 {v15.8H}, [src11], #16
    ld1 {v15.8H}, [src11]
    st1 {v16.8H}, [src12], #16
    ld1 {v16.8H}, [src12]
    st1 {v17.8H}, [src13], #16
    ld1 {v17.8H}, [src13]
    st1 {v18.8H}, [src14], #16
    ld1 {v18.8H}, [src14]
    st1 {v19.8H}, [src15], #16
    ld1 {v19.8H}, [src15]

    qo_butterfly_top  v5,  v7,  v9, v11, v13, v15, v17, v19, v28, v29, v30, v31,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3
    qo_butterfly_mixed  v5,  v7,  v9, v11, v13, v15, v17, v19, v28, v29, v30, v31,  v4,  v6,  v8, v10, v12, v14, v16, v18, v20, v21, v22, v23,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3
    qo_butterfly_mixed  v4,  v6,  v8, v10, v12, v14, v16, v18, v20, v21, v22, v23,  v5,  v7, v13, v15,  v9, v11, v17, v19, v28, v29, v30, v31,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 4, 5,  v0, 4, 5,  v0, 6, 7,  v0, 6, 7
    qo_butterfly_mixed  v5,  v7, v13, v15,  v9, v11, v17, v19, v28, v29, v30, v31,  v4,  v6, v12, v14,  v8, v10, v16, v18, v20, v21, v22, v23,  v0,  v0, 4, 5,  v0, 4, 5,  v0, 6, 7,  v0, 6, 7,  v0, 4, 5,  v0, 4, 5,  v0, 6, 7,  v0, 6, 7
    qo_butterfly_mixed  v4,  v6, v12, v14,  v8, v10, v16, v18, v20, v21, v22, v23,  v5,  v9, v13, v17,  v7, v11, v15, v19, v28, v29, v30, v31,  v0,  v0, 4, 5,  v0, 4, 5,  v0, 6, 7,  v0, 6, 7,  v1, 0, 1,  v1, 2, 3,  v1, 4, 5,  v1, 6, 7
    qo_butterfly_mixed  v5,  v9, v13, v17,  v7, v11, v15, v19, v28, v29, v30, v31,  v4,  v8, v12, v16,  v6, v10, v14, v18, v20, v21, v22, v23,  v0,  v1, 0, 1,  v1, 2, 3,  v1, 4, 5,  v1, 6, 7,  v1, 0, 1,  v1, 2, 3,  v1, 4, 5,  v1, 6, 7
    qo_butterfly_mixed  v4,  v8, v12, v16,  v6, v10, v14, v18, v20, v21, v22, v23,  v4,  v6,  v8, v10,  v5,  v7,  v9, v11, v28, v29, v30, v31,  v0,  v1, 0, 1,  v1, 2, 3,  v1, 4, 5,  v1, 6, 7,  v2, 0, 1,  v2, 2, 3,  v2, 4, 5,  v2, 6, 7
    qo_butterfly_mixed  v4,  v6,  v8, v10,  v5,  v7,  v9, v11, v28, v29, v30, v31, v12, v14, v16, v18, v13, v15, v17, v19, v20, v21, v22, v23,  v0,  v2, 0, 1,  v2, 2, 3,  v2, 4, 5,  v2, 6, 7,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7
    qo_butterfly_bot v12, v14, v16, v18, v13, v15, v17, v19, v20, v21, v22, v23,  v0,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7

    st1 { v4.8H}, [ src0], #16
    st1 { v5.8H}, [ src1], #16
    st1 { v6.8H}, [ src2], #16
    st1 { v7.8H}, [ src3], #16
    st1 { v8.8H}, [ src4], #16
    st1 { v9.8H}, [ src5], #16
    st1 {v10.8H}, [ src6], #16
    st1 {v11.8H}, [ src7], #16

    st1 {v12.8H}, [ src8], #16
    st1 {v13.8H}, [ src9], #16
    st1 {v14.8H}, [src10], #16
    st1 {v15.8H}, [src11], #16
    st1 {v16.8H}, [src12], #16
    st1 {v17.8H}, [src13], #16
    st1 {v18.8H}, [src14], #16
    st1 {v19.8H}, [src15], #16

    .unreq    Q
    .unreq    src0
    .unreq    src1
    .unreq    src2
    .unreq    src3
    .unreq    src4
    .unreq    src5
    .unreq    src6
    .unreq    src7
    .unreq    src8
    .unreq    src9
    .unreq    src10
    .unreq    src11
    .unreq    src12
    .unreq    src13
    .unreq    src14
    .unreq    src15
    .unreq    table
    .unreq    counter
    pop_all

    br lr


.align 2
.global __asm_ntt_SIMD_bot
.global ___asm_ntt_SIMD_bot
__asm_ntt_SIMD_bot:
___asm_ntt_SIMD_bot:

    push_all
    Q         .req w20
    BarrettM  .req w21
    src0      .req x0
    src1      .req x1
    table     .req x28
    counter   .req x19

    ldrsh Q, [x2, #0]
    ldrsh BarrettM, [x2, #8]

    add table, x1, #64

    add src0, x0, #256*0
    add src1, x0, #256*1

    ld4 {v16.4S, v17.4S, v18.4S, v19.4S}, [src0]
    ld4 {v20.4S, v21.4S, v22.4S, v23.4S}, [src1]

    trn1 v24.4S, v16.4S, v20.4S
    ld2 { v0.8H,  v1.8H}, [table], #32
    trn2 v28.4S, v16.4S, v20.4S
    ld2 { v2.8H,  v3.8H}, [table], #32
    trn1 v25.4S, v17.4S, v21.4S
    ld2 { v4.8H,  v5.8H}, [table], #32
    trn2 v29.4S, v17.4S, v21.4S
    ld2 { v6.8H,  v7.8H}, [table], #32
    trn1 v26.4S, v18.4S, v22.4S
    ld2 { v8.8H,  v9.8H}, [table], #32
    trn2 v30.4S, v18.4S, v22.4S
    ld2 {v10.8H, v11.8H}, [table], #32
    trn1 v27.4S, v19.4S, v23.4S
    ld2 {v12.8H, v13.8H}, [table], #32
    trn2 v31.4S, v19.4S, v23.4S
    ld2 {v14.8H, v15.8H}, [table], #32

    dup v0.8H, Q
    mov v1.H[0], BarrettM

    do_butterfly_vec_top v25, v27, v29, v31, v18, v19,  v0,  v2,  v3,  v2,  v3
    do_butterfly_vec_mixed v25, v27, v29, v31, v18, v19, v24, v26, v28, v30, v16, v17,  v0,  v2,  v3,  v2,  v3,  v2,  v3,  v2,  v3
    do_butterfly_vec_mixed v24, v26, v28, v30, v16, v17, v25, v29, v27, v31, v18, v19,  v0,  v2,  v3,  v2,  v3,  v4,  v5,  v6,  v7
    do_butterfly_vec_mixed v25, v29, v27, v31, v18, v19, v24, v28, v26, v30, v16, v17,  v0,  v4,  v5,  v6,  v7,  v4,  v5,  v6,  v7
    do_butterfly_vec_mixed v24, v28, v26, v30, v16, v17, v24, v26, v25, v27, v18, v19,  v0,  v4,  v5,  v6,  v7,  v8,  v9, v10, v11
    do_butterfly_vec_mixed v24, v26, v25, v27, v18, v19, v28, v30, v29, v31, v16, v17,  v0,  v8,  v9, v10, v11, v12, v13, v14, v15
    do_butterfly_vec_bot v28, v30, v29, v31, v16, v17,  v0, v12, v13, v14, v15
    oo_barrett v24, v25, v26, v27, v16, v17, v18, v19, v28, v29, v30, v31, v20, v21, v22, v23,  v1,  #11,  v0

    trn1 v16.4S, v24.4S, v28.4S
    trn2 v20.4S, v24.4S, v28.4S
    trn1 v17.4S, v25.4S, v29.4S
    trn2 v21.4S, v25.4S, v29.4S
    trn1 v18.4S, v26.4S, v30.4S
    trn2 v22.4S, v26.4S, v30.4S
    trn1 v19.4S, v27.4S, v31.4S
    trn2 v23.4S, v27.4S, v31.4S

    mov counter, #3
    _ntt_bot_loop:

    st4 {v16.4S, v17.4S, v18.4S, v19.4S}, [src0], #64
    ld4 {v16.4S, v17.4S, v18.4S, v19.4S}, [src0]
    st4 {v20.4S, v21.4S, v22.4S, v23.4S}, [src1], #64
    ld4 {v20.4S, v21.4S, v22.4S, v23.4S}, [src1]

    trn1 v24.4S, v16.4S, v20.4S
    ld2 { v0.8H,  v1.8H}, [table], #32
    trn2 v28.4S, v16.4S, v20.4S
    ld2 { v2.8H,  v3.8H}, [table], #32
    trn1 v25.4S, v17.4S, v21.4S
    ld2 { v4.8H,  v5.8H}, [table], #32
    trn2 v29.4S, v17.4S, v21.4S
    ld2 { v6.8H,  v7.8H}, [table], #32
    trn1 v26.4S, v18.4S, v22.4S
    ld2 { v8.8H,  v9.8H}, [table], #32
    trn2 v30.4S, v18.4S, v22.4S
    ld2 {v10.8H, v11.8H}, [table], #32
    trn1 v27.4S, v19.4S, v23.4S
    ld2 {v12.8H, v13.8H}, [table], #32
    trn2 v31.4S, v19.4S, v23.4S
    ld2 {v14.8H, v15.8H}, [table], #32

    dup v0.8H, Q
    mov v1.H[0], BarrettM

    do_butterfly_vec_top v25, v27, v29, v31, v18, v19,  v0,  v2,  v3,  v2,  v3
    do_butterfly_vec_mixed v25, v27, v29, v31, v18, v19, v24, v26, v28, v30, v16, v17,  v0,  v2,  v3,  v2,  v3,  v2,  v3,  v2,  v3
    do_butterfly_vec_mixed v24, v26, v28, v30, v16, v17, v25, v29, v27, v31, v18, v19,  v0,  v2,  v3,  v2,  v3,  v4,  v5,  v6,  v7
    do_butterfly_vec_mixed v25, v29, v27, v31, v18, v19, v24, v28, v26, v30, v16, v17,  v0,  v4,  v5,  v6,  v7,  v4,  v5,  v6,  v7
    do_butterfly_vec_mixed  v24, v28, v26, v30, v16, v17, v24, v26, v25, v27, v18, v19,  v0,  v4,  v5,  v6,  v7,  v8,  v9, v10, v11
    do_butterfly_vec_mixed v24, v26, v25, v27, v18, v19, v28, v30, v29, v31, v16, v17,  v0,  v8,  v9, v10, v11, v12, v13, v14, v15
    do_butterfly_vec_bot v28, v30, v29, v31, v16, v17,  v0, v12, v13, v14, v15

    oo_barrett v24, v25, v26, v27, v16, v17, v18, v19, v28, v29, v30, v31, v20, v21, v22, v23,  v1,  #11,  v0

    trn1 v16.4S, v24.4S, v28.4S
    trn2 v20.4S, v24.4S, v28.4S
    trn1 v17.4S, v25.4S, v29.4S
    trn2 v21.4S, v25.4S, v29.4S
    trn1 v18.4S, v26.4S, v30.4S
    trn2 v22.4S, v26.4S, v30.4S
    trn1 v19.4S, v27.4S, v31.4S
    trn2 v23.4S, v27.4S, v31.4S

    sub counter, counter, #1
    cbnz counter, _ntt_bot_loop

    st4 {v16.4S, v17.4S, v18.4S, v19.4S}, [src0], #64
    st4 {v20.4S, v21.4S, v22.4S, v23.4S}, [src1], #64

    .unreq    Q
    .unreq    BarrettM
    .unreq    src0
    .unreq    src1
    .unreq    table
    .unreq    counter
    pop_all

    br lr














.align 2
.global __asm_intt_SIMD_bot
.global ___asm_intt_SIMD_bot
__asm_intt_SIMD_bot:
___asm_intt_SIMD_bot:

    push_all
    Q         .req w20
    BarrettM  .req w21
    src0      .req x0
    src1      .req x1
    table     .req x28
    counter   .req x19

    ldrsh Q, [x2, #0]
    ldrsh BarrettM, [x2, #8]

    add table, x1, #64

    add src0, x0, #256*0
    add src1, x0, #256*1

    mov counter, #4
    _intt_bot_loop:

    ld4 {v16.4S, v17.4S, v18.4S, v19.4S}, [src0]
    ld4 {v20.4S, v21.4S, v22.4S, v23.4S}, [src1]

    trn1 v24.4S, v16.4S, v20.4S
    ld2 { v0.8H,  v1.8H}, [table], #32
    trn2 v28.4S, v16.4S, v20.4S
    ld2 { v2.8H,  v3.8H}, [table], #32
    trn1 v25.4S, v17.4S, v21.4S
    ld2 { v4.8H,  v5.8H}, [table], #32
    trn2 v29.4S, v17.4S, v21.4S
    ld2 { v6.8H,  v7.8H}, [table], #32
    trn1 v26.4S, v18.4S, v22.4S
    ld2 { v8.8H,  v9.8H}, [table], #32
    trn2 v30.4S, v18.4S, v22.4S
    ld2 {v10.8H, v11.8H}, [table], #32
    trn1 v27.4S, v19.4S, v23.4S
    ld2 {v12.8H, v13.8H}, [table], #32
    trn2 v31.4S, v19.4S, v23.4S
    ld2 {v14.8H, v15.8H}, [table], #32

    dup v0.8H, Q
    mov v1.H[0], BarrettM

    do_butterfly_vec_bot v28, v30, v18, v19, v29, v31,  v0, v12, v13, v14, v15
    do_butterfly_vec_mixed_rev v28, v30, v18, v19, v29, v31, v24, v26, v16, v17, v25, v27,  v0, v12, v13, v14, v15,  v8,  v9, v10, v11
    do_butterfly_vec_mixed_rev v24, v26, v16, v17, v25, v27, v28, v29, v18, v19, v30, v31,  v0,  v8,  v9, v10, v11,  v6,  v7,  v6,  v7
    do_butterfly_vec_mixed_rev v28, v29, v18, v19, v30, v31, v24, v25, v16, v17, v26, v27,  v0,  v6,  v7,  v6,  v7,  v4,  v5,  v4,  v5
    do_butterfly_vec_mixed_rev v24, v25, v16, v17, v26, v27, v24, v25, v18, v19, v28, v29,  v0,  v4,  v5,  v4,  v5,  v2,  v3,  v2,  v3
    do_butterfly_vec_mixed_rev v24, v25, v18, v19, v28, v29, v26, v27, v16, v17, v30, v31,  v0,  v2,  v3,  v2,  v3,  v2,  v3,  v2,  v3
    do_butterfly_vec_top v26, v27, v16, v17, v30, v31,  v0,  v2,  v3,   v2, v3

    qo_barrett v24, v25, v26, v27, v16, v17, v18, v19,  v1,  #11,  v0

    trn1 v16.4S, v24.4S, v28.4S
    trn2 v20.4S, v24.4S, v28.4S
    trn1 v17.4S, v25.4S, v29.4S
    trn2 v21.4S, v25.4S, v29.4S
    trn1 v18.4S, v26.4S, v30.4S
    trn2 v22.4S, v26.4S, v30.4S
    trn1 v19.4S, v27.4S, v31.4S
    trn2 v23.4S, v27.4S, v31.4S

    st4 {v16.4S, v17.4S, v18.4S, v19.4S}, [src0], #64
    st4 {v20.4S, v21.4S, v22.4S, v23.4S}, [src1], #64

    sub counter, counter, #1
    cbnz counter, _intt_bot_loop

    .unreq    Q
    .unreq    BarrettM
    .unreq    src0
    .unreq    src1
    .unreq    table
    .unreq    counter
    pop_all

    br lr

.align 2
.global __asm_intt_SIMD_top
.global ___asm_intt_SIMD_top
__asm_intt_SIMD_top:
___asm_intt_SIMD_top:

    push_all
    Q         .req w20
    BarrettM  .req w21
    invN      .req w22
    invN_f    .req w23
    src0      .req x0
    src1      .req x1
    src2      .req x2
    src3      .req x3
    src4      .req x4
    src5      .req x5
    src6      .req x6
    src7      .req x7
    src8      .req x8
    src9      .req x9
    src10     .req x10
    src11     .req x11
    src12     .req x12
    src13     .req x13
    src14     .req x14
    src15     .req x15
    table     .req x28
    counter   .req x19

    ldrsh Q, [x2, #0]
    ldrsh BarrettM, [x2, #8]
    ldr   invN, [x2, #10]
    ldr   invN_f, [x2, #14]

    mov table, x1

    add  src0, x0,  #32*0
    add  src1, x0,  #32*1
    add  src2, x0,  #32*2
    add  src3, x0,  #32*3
    add  src4, x0,  #32*4
    add  src5, x0,  #32*5
    add  src6, x0,  #32*6
    add  src7, x0,  #32*7
    add  src8, x0,  #32*8
    add  src9, x0,  #32*9
    add src10, x0, #32*10
    add src11, x0, #32*11
    add src12, x0, #32*12
    add src13, x0, #32*13
    add src14, x0, #32*14
    add src15, x0, #32*15

    ld1 { v0.8H,  v1.8H,  v2.8H,  v3.8H}, [table], #64

    mov  v0.H[0], Q

    dup v24.8H, Q
    dup v25.8H, BarrettM

    ld1 { v4.8H}, [ src0]
    ld1 { v5.8H}, [ src1]
    ld1 { v6.8H}, [ src2]
    ld1 { v7.8H}, [ src3]
    ld1 { v8.8H}, [ src4]
    ld1 { v9.8H}, [ src5]
    ld1 {v10.8H}, [ src6]
    ld1 {v11.8H}, [ src7]

    ld1 {v12.8H}, [ src8]
    ld1 {v13.8H}, [ src9]
    ld1 {v14.8H}, [src10]
    ld1 {v15.8H}, [src11]
    ld1 {v16.8H}, [src12]
    ld1 {v17.8H}, [src13]
    ld1 {v18.8H}, [src14]
    ld1 {v19.8H}, [src15]

    qo_butterfly_bot v12, v14, v16, v18, v28, v29, v30, v31, v13, v15, v17, v19,  v0,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7
    qo_butterfly_mixed_rev v12, v14, v16, v18, v28, v29, v30, v31, v13, v15, v17, v19,  v4,  v6,  v8, v10, v20, v21, v22, v23,  v5,  v7,  v9, v11,  v0,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7
    qo_butterfly_mixed_rev  v4,  v6,  v8, v10, v20, v21, v22, v23,  v5,  v7,  v9, v11, v12, v13, v16, v17, v28, v29, v30, v31, v14, v15, v18, v19,  v0,  v2, 0, 1,  v2, 2, 3,  v2, 4, 5,  v2, 6, 7,  v1, 4, 5,  v1, 4, 5,  v1, 6, 7,  v1, 6, 7
    qo_butterfly_mixed_rev v12, v13, v16, v17, v28, v29, v30, v31, v14, v15, v18, v19,  v4,  v5,  v8,  v9, v20, v21, v22, v23,  v6,  v7, v10, v11,  v0,  v1, 4, 5,  v1, 4, 5,  v1, 6, 7,  v1, 6, 7,  v1, 0, 1,  v1, 0, 1,  v1, 2, 3,  v1, 2, 3
    qo_butterfly_mixed_rev  v4,  v5,  v8,  v9, v20, v21, v22, v23,  v6,  v7, v10, v11, v12, v13, v14, v15, v28, v29, v30, v31, v16, v17, v18, v19,  v0,  v1, 0, 1,  v1, 0, 1,  v1, 2, 3,  v1, 2, 3,  v0, 6, 7,  v0, 6, 7,  v0, 6, 7,  v0, 6, 7
    qo_butterfly_mixed_rev v12, v13, v14, v15, v28, v29, v30, v31, v16, v17, v18, v19,  v4,  v5,  v6,  v7, v20, v21, v22, v23,  v8,  v9, v10, v11,  v0,  v0, 6, 7,  v0, 6, 7,  v0, 6, 7,  v0, 6, 7,  v0, 4, 5,  v0, 4, 5,  v0, 4, 5,  v0, 4, 5
    qo_butterfly_top  v4,  v5,  v6,  v7, v20, v21, v22, v23,  v8,  v9, v10, v11,  v0,  v0, 4, 5,  v0, 4, 5,  v0, 4, 5,  v0, 4, 5

    qo_barrett_vec  v4,  v5,  v12,  v13, v20, v21, v22, v23, v25, #11, v24

    mov v0.S[1], invN_f

    qo_butterfly_bot  v4,  v5,  v6,  v7, v28, v29, v30, v31, v12, v13, v14, v15,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3
    qo_butterfly_mixed_rev  v4,  v5,  v6,  v7, v28, v29, v30, v31, v12, v13, v14, v15,  v8,  v9, v10, v11, v20, v21, v22, v23, v16, v17, v18, v19,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3
    qo_butterfly_top  v8,  v9, v10, v11, v20, v21, v22, v23, v16, v17, v18, v19,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3

    mov v0.S[1], invN

    sqrdmulh v28.8H,  v4.8H,  v0.H[2]
    sqrdmulh v29.8H,  v5.8H,  v0.H[2]
    sqrdmulh v30.8H,  v6.8H,  v0.H[2]
    sqrdmulh v31.8H,  v7.8H,  v0.H[2]
    sqrdmulh v20.8H,  v8.8H,  v0.H[2]
    sqrdmulh v21.8H,  v9.8H,  v0.H[2]
    sqrdmulh v22.8H, v10.8H,  v0.H[2]
    sqrdmulh v23.8H, v11.8H,  v0.H[2]

    mul       v4.8H,  v4.8H,  v0.H[3]
    mul       v5.8H,  v5.8H,  v0.H[3]
    mul       v6.8H,  v6.8H,  v0.H[3]
    mul       v7.8H,  v7.8H,  v0.H[3]
    mul       v8.8H,  v8.8H,  v0.H[3]
    mul       v9.8H,  v9.8H,  v0.H[3]
    mul      v10.8H, v10.8H,  v0.H[3]
    mul      v11.8H, v11.8H,  v0.H[3]

    mls       v4.8H, v28.8H,  v0.H[0]
    mls       v5.8H, v29.8H,  v0.H[0]
    mls       v6.8H, v30.8H,  v0.H[0]
    mls       v7.8H, v31.8H,  v0.H[0]
    mls       v8.8H, v20.8H,  v0.H[0]
    mls       v9.8H, v21.8H,  v0.H[0]
    mls      v10.8H, v22.8H,  v0.H[0]
    mls      v11.8H, v23.8H,  v0.H[0]

    st1 { v4.8H}, [ src0], #16
    ld1 { v4.8H}, [ src0]
    st1 { v5.8H}, [ src1], #16
    ld1 { v5.8H}, [ src1]
    st1 { v6.8H}, [ src2], #16
    ld1 { v6.8H}, [ src2]
    st1 { v7.8H}, [ src3], #16
    ld1 { v7.8H}, [ src3]
    st1 { v8.8H}, [ src4], #16
    ld1 { v8.8H}, [ src4]
    st1 { v9.8H}, [ src5], #16
    ld1 { v9.8H}, [ src5]
    st1 {v10.8H}, [ src6], #16
    ld1 {v10.8H}, [ src6]
    st1 {v11.8H}, [ src7], #16
    ld1 {v11.8H}, [ src7]

    st1 {v12.8H}, [ src8], #16
    ld1 {v12.8H}, [ src8]
    st1 {v13.8H}, [ src9], #16
    ld1 {v13.8H}, [ src9]
    st1 {v14.8H}, [src10], #16
    ld1 {v14.8H}, [src10]
    st1 {v15.8H}, [src11], #16
    ld1 {v15.8H}, [src11]
    st1 {v16.8H}, [src12], #16
    ld1 {v16.8H}, [src12]
    st1 {v17.8H}, [src13], #16
    ld1 {v17.8H}, [src13]
    st1 {v18.8H}, [src14], #16
    ld1 {v18.8H}, [src14]
    st1 {v19.8H}, [src15], #16
    ld1 {v19.8H}, [src15]

    qo_butterfly_bot v12, v14, v16, v18, v28, v29, v30, v31, v13, v15, v17, v19,  v0,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7
    qo_butterfly_mixed_rev v12, v14, v16, v18, v28, v29, v30, v31, v13, v15, v17, v19,  v4,  v6,  v8, v10, v20, v21, v22, v23,  v5,  v7,  v9, v11,  v0,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7,  v3, 0, 1,  v3, 2, 3,  v3, 4, 5,  v3, 6, 7
    qo_butterfly_mixed_rev  v4,  v6,  v8, v10, v20, v21, v22, v23,  v5,  v7,  v9, v11, v12, v13, v16, v17, v28, v29, v30, v31, v14, v15, v18, v19,  v0,  v2, 0, 1,  v2, 2, 3,  v2, 4, 5,  v2, 6, 7,  v1, 4, 5,  v1, 4, 5,  v1, 6, 7,  v1, 6, 7
    qo_butterfly_mixed_rev v12, v13, v16, v17, v28, v29, v30, v31, v14, v15, v18, v19,  v4,  v5,  v8,  v9, v20, v21, v22, v23,  v6,  v7, v10, v11,  v0,  v1, 4, 5,  v1, 4, 5,  v1, 6, 7,  v1, 6, 7,  v1, 0, 1,  v1, 0, 1,  v1, 2, 3,  v1, 2, 3
    qo_butterfly_mixed_rev  v4,  v5,  v8,  v9, v20, v21, v22, v23,  v6,  v7, v10, v11, v12, v13, v14, v15, v28, v29, v30, v31, v16, v17, v18, v19,  v0,  v1, 0, 1,  v1, 0, 1,  v1, 2, 3,  v1, 2, 3,  v0, 6, 7,  v0, 6, 7,  v0, 6, 7,  v0, 6, 7
    qo_butterfly_mixed_rev v12, v13, v14, v15, v28, v29, v30, v31, v16, v17, v18, v19,  v4,  v5,  v6,  v7, v20, v21, v22, v23,  v8,  v9, v10, v11,  v0,  v0, 6, 7,  v0, 6, 7,  v0, 6, 7,  v0, 6, 7,  v0, 4, 5,  v0, 4, 5,  v0, 4, 5,  v0, 4, 5
    qo_butterfly_top  v4,  v5,  v6,  v7, v20, v21, v22, v23,  v8,  v9, v10, v11,  v0,  v0, 4, 5,  v0, 4, 5,  v0, 4, 5,  v0, 4, 5

    qo_barrett_vec  v4,  v5,  v12,  v13, v20, v21, v22, v23, v25, #11, v24

    mov v0.S[1], invN_f

    qo_butterfly_bot  v4,  v5,  v6,  v7, v28, v29, v30, v31, v12, v13, v14, v15,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3
    qo_butterfly_mixed_rev  v4,  v5,  v6,  v7, v28, v29, v30, v31, v12, v13, v14, v15,  v8,  v9, v10, v11, v20, v21, v22, v23, v16, v17, v18, v19,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3
    qo_butterfly_top  v8,  v9, v10, v11, v20, v21, v22, v23, v16, v17, v18, v19,  v0,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3,  v0, 2, 3

    mov v0.S[1], invN

    sqrdmulh v28.8H,  v4.8H,  v0.H[2]
    sqrdmulh v29.8H,  v5.8H,  v0.H[2]
    sqrdmulh v30.8H,  v6.8H,  v0.H[2]
    sqrdmulh v31.8H,  v7.8H,  v0.H[2]
    sqrdmulh v20.8H,  v8.8H,  v0.H[2]
    sqrdmulh v21.8H,  v9.8H,  v0.H[2]
    sqrdmulh v22.8H, v10.8H,  v0.H[2]
    sqrdmulh v23.8H, v11.8H,  v0.H[2]

    mul       v4.8H,  v4.8H,  v0.H[3]
    mul       v5.8H,  v5.8H,  v0.H[3]
    mul       v6.8H,  v6.8H,  v0.H[3]
    mul       v7.8H,  v7.8H,  v0.H[3]
    mul       v8.8H,  v8.8H,  v0.H[3]
    mul       v9.8H,  v9.8H,  v0.H[3]
    mul      v10.8H, v10.8H,  v0.H[3]
    mul      v11.8H, v11.8H,  v0.H[3]

    mls       v4.8H, v28.8H,  v0.H[0]
    mls       v5.8H, v29.8H,  v0.H[0]
    mls       v6.8H, v30.8H,  v0.H[0]
    mls       v7.8H, v31.8H,  v0.H[0]
    mls       v8.8H, v20.8H,  v0.H[0]
    mls       v9.8H, v21.8H,  v0.H[0]
    mls      v10.8H, v22.8H,  v0.H[0]
    mls      v11.8H, v23.8H,  v0.H[0]

    st1 { v4.8H}, [ src0], #16
    st1 { v5.8H}, [ src1], #16
    st1 { v6.8H}, [ src2], #16
    st1 { v7.8H}, [ src3], #16
    st1 { v8.8H}, [ src4], #16
    st1 { v9.8H}, [ src5], #16
    st1 {v10.8H}, [ src6], #16
    st1 {v11.8H}, [ src7], #16

    st1 {v12.8H}, [ src8], #16
    st1 {v13.8H}, [ src9], #16
    st1 {v14.8H}, [src10], #16
    st1 {v15.8H}, [src11], #16
    st1 {v16.8H}, [src12], #16
    st1 {v17.8H}, [src13], #16
    st1 {v18.8H}, [src14], #16
    st1 {v19.8H}, [src15], #16

    .unreq    Q
    .unreq    BarrettM
    .unreq    invN
    .unreq    invN_f
    .unreq    src0
    .unreq    src1
    .unreq    src2
    .unreq    src3
    .unreq    src4
    .unreq    src5
    .unreq    src6
    .unreq    src7
    .unreq    src8
    .unreq    src9
    .unreq    src10
    .unreq    src11
    .unreq    src12
    .unreq    src13
    .unreq    src14
    .unreq    src15
    .unreq    table
    .unreq    counter
    pop_all

    br lr
