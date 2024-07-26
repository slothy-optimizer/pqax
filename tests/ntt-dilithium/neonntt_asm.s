
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


.macro wrap_trn_4x4 a0, a1, a2, a3, t0, t1, t2, t3, qS, dD

    trn1 \t0\qS, \a0\qS, \a1\qS
    trn2 \t1\qS, \a0\qS, \a1\qS
    trn1 \t2\qS, \a2\qS, \a3\qS
    trn2 \t3\qS, \a2\qS, \a3\qS

    trn1 \a0\dD, \t0\dD, \t2\dD
    trn2 \a2\dD, \t0\dD, \t2\dD
    trn1 \a1\dD, \t1\dD, \t3\dD
    trn2 \a3\dD, \t1\dD, \t3\dD

.endm

.macro trn_4x4 a0, a1, a2, a3, t0, t1, t2, t3
    wrap_trn_4x4 \a0, \a1, \a2, \a3, \t0, \t1, \t2, \t3, .4S, .2D
.endm


.macro dq_butterfly_vec_bot a0, a1, b0, b1, t0, t1, mod, l0, h0, l1, h1
    wrap_dX_butterfly_vec_bot \a0, \a1, \b0, \b1, \t0, \t1, \mod, \l0, \h0, \l1, \h1, .4S, .S
.endm

.macro dq_butterfly_vec_top a0, a1, b0, b1, t0, t1, mod, l0, h0, l1, h1
    wrap_dX_butterfly_vec_top \a0, \a1, \b0, \b1, \t0, \t1, \mod, \l0, \h0, \l1, \h1, .4S, .S
.endm

.macro dq_butterfly_vec_mixed a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, l0, h0, l1, h1, l2, h2, l3, h3
    wrap_dX_butterfly_vec_mixed \a0, \a1, \b0, \b1, \t0, \t1, \a2, \a3, \b2, \b3, \t2, \t3, \mod, \l0, \h0, \l1, \h1, \l2, \h2, \l3, \h3, .4S, .S
.endm

.macro dq_butterfly_vec_mixed_rev a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, l0, h0, l1, h1, l2, h2, l3, h3
    wrap_dX_butterfly_vec_mixed_rev \a0, \a1, \b0, \b1, \t0, \t1, \a2, \a3, \b2, \b3, \t2, \t3, \mod, \l0, \h0, \l1, \h1, \l2, \h2, \l3, \h3, .4S, .S
.endm


.macro dq_butterfly_top a0, a1, b0, b1, t0, t1, mod, z0, l0, h0, z1, l1, h1
    wrap_dX_butterfly_top \a0, \a1, \b0, \b1, \t0, \t1, \mod, \z0, \l0, \h0, \z1, \l1, \h1, .4S, .S
.endm

.macro dq_butterfly_bot a0, a1, b0, b1, t0, t1, mod, z0, l0, h0, z1, l1, h1
    wrap_dX_butterfly_bot \a0, \a1, \b0, \b1, \t0, \t1, \mod, \z0, \l0, \h0, \z1, \l1, \h1, .4S, .S
.endm

.macro dq_butterfly_mixed a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3
    wrap_dX_butterfly_mixed \a0, \a1, \b0, \b1, \t0, \t1, \a2, \a3, \b2, \b3, \t2, \t3, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, .4S, .S
.endm

.macro dq_butterfly_mixed_rev a0, a1, b0, b1, t0, t1, a2, a3, b2, b3, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3
    wrap_dX_butterfly_mixed_rev \a0, \a1, \b0, \b1, \t0, \t1, \a2, \a3, \b2, \b3, \t2, \t3, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, .4S, .S
.endm


.macro qq_montgomery_mul b0, b1, b2, b3, t0, t1, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3
    wrap_qX_montgomery_mul \b0, \b1, \b2, \b3, \t0, \t1, \t2, \t3, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, .4S, .S
.endm


.macro qq_butterfly_top a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3
    wrap_qX_butterfly_top \a0, \a1, \a2, \a3, \b0, \b1, \b2, \b3, \t0, \t1, \t2, \t3, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, .4S, .S
.endm

.macro qq_butterfly_bot a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3
    wrap_qX_butterfly_bot \a0, \a1, \a2, \a3, \b0, \b1, \b2, \b3, \t0, \t1, \t2, \t3, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, .4S, .S
.endm

.macro qq_butterfly_mixed a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, a4, a5, a6, a7, b4, b5, b6, b7, t4, t5, t6, t7, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, z4, l4, h4, z5, l5, h5, z6, l6, h6, z7, l7, h7
    wrap_qX_butterfly_mixed \a0, \a1, \a2, \a3, \b0, \b1, \b2, \b3, \t0, \t1, \t2, \t3, \a4, \a5, \a6, \a7, \b4, \b5, \b6, \b7, \t4, \t5, \t6, \t7, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, \z4, \l4, \h4, \z5, \l5, \h5, \z6, \l6, \h6, \z7, \l7, \h7, .4S, .S
.endm

.macro qq_butterfly_mixed_rev a0, a1, a2, a3, b0, b1, b2, b3, t0, t1, t2, t3, a4, a5, a6, a7, b4, b5, b6, b7, t4, t5, t6, t7, mod, z0, l0, h0, z1, l1, h1, z2, l2, h2, z3, l3, h3, z4, l4, h4, z5, l5, h5, z6, l6, h6, z7, l7, h7
    wrap_qX_butterfly_mixed_rev \a0, \a1, \a2, \a3, \b0, \b1, \b2, \b3, \t0, \t1, \t2, \t3, \a4, \a5, \a6, \a7, \b4, \b5, \b6, \b7, \t4, \t5, \t6, \t7, \mod, \z0, \l0, \h0, \z1, \l1, \h1, \z2, \l2, \h2, \z3, \l3, \h3, \z4, \l4, \h4, \z5, \l5, \h5, \z6, \l6, \h6, \z7, \l7, \h7, .4S, .S
.endm


.macro qq_montgomery c0, c1, c2, c3, l0, l1, l2, l3, h0, h1, h2, h3, t0, t1, t2, t3, Qprime, Q
    wrap_qX_montgomery \c0, \c1, \c2, \c3, \l0, \l1, \l2, \l3, \h0, \h1, \h2, \h3, \t0, \t1, \t2, \t3, \Qprime, \Q, .2S, .4S, .2D
.endm

.macro qq_sub_add s0, s1, s2, s3, t0, t1, t2, t3, a0, a1, a2, a3, b0, b1, b2, b3
    wrap_qX_sub_add \s0, \s1, \s2, \s3, \t0, \t1, \t2, \t3, \a0, \a1, \a2, \a3, \b0, \b1, \b2, \b3, .4S
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

    ldr Q, [x2]

    mov table, x1

    add  src1, src0, #64
    add  src2, src0, #128

    add  src3, src0, #192
    add  src4, src0, #256

    add  src5, src0, #320
    add  src6, src0, #384

    add  src7, src0, #448
    add  src8, src0, #512

    add  src9, src0, #576
    add src10, src0, #640

    add src11, src0, #704
    add src12, src0, #768

    add src13, src0, #832
    add src14, src0, #896

    add src15, src0, #960

    ld1 {v20.4S, v21.4S, v22.4S, v23.4S}, [table], #64
    ld1 {v24.4S, v25.4S, v26.4S, v27.4S}, [table], #64

    mov v20.S[0], Q

    ld1 { v1.4S}, [ src1]
    ld1 { v3.4S}, [ src3]
    ld1 { v5.4S}, [ src5]
    ld1 { v7.4S}, [ src7]
    ld1 { v9.4S}, [ src9]
    ld1 {v11.4S}, [src11]
    ld1 {v13.4S}, [src13]
    ld1 {v15.4S}, [src15]

    ld1 { v0.4S}, [ src0]
    ld1 { v2.4S}, [ src2]
    ld1 { v4.4S}, [ src4]
    ld1 { v6.4S}, [ src6]
    ld1 { v8.4S}, [ src8]
    ld1 {v10.4S}, [src10]
    ld1 {v12.4S}, [src12]
    ld1 {v14.4S}, [src14]

    qq_butterfly_top  v1,  v3,  v5,  v7,  v9, v11, v13, v15, v16, v17, v18, v19, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3
    qq_butterfly_mixed  v1,  v3,  v5,  v7,  v9, v11, v13, v15, v16, v17, v18, v19,  v0,  v2,  v4,  v6,  v8, v10, v12, v14, v28, v29, v30, v31, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3
    qq_butterfly_mixed  v0,  v2,  v4,  v6,  v8, v10, v12, v14, v28, v29, v30, v31,  v1,  v3,  v9, v11,  v5,  v7, v13, v15, v16, v17, v18, v19, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3
    qq_butterfly_mixed  v1,  v3,  v9, v11,  v5,  v7, v13, v15, v16, v17, v18, v19,  v0,  v2,  v8, v10,  v4,  v6, v12, v14, v28, v29, v30, v31, v20, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3
    qq_butterfly_mixed  v0,  v2,  v8, v10,  v4,  v6, v12, v14, v28, v29, v30, v31,  v1,  v5,  v9, v13,  v3,  v7, v11, v15, v16, v17, v18, v19, v20, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3, v22, 0, 1, v22, 2, 3, v23, 0, 1, v23, 2, 3
    qq_butterfly_mixed  v1,  v5,  v9, v13,  v3,  v7, v11, v15, v16, v17, v18, v19,  v0,  v4,  v8, v12,  v2,  v6, v10, v14, v28, v29, v30, v31, v20, v22, 0, 1, v22, 2, 3, v23, 0, 1, v23, 2, 3, v22, 0, 1, v22, 2, 3, v23, 0, 1, v23, 2, 3
    qq_butterfly_mixed  v0,  v4,  v8, v12,  v2,  v6, v10, v14, v28, v29, v30, v31,  v0,  v2,  v4,  v6,  v1,  v3,  v5,  v7, v16, v17, v18, v19, v20, v22, 0, 1, v22, 2, 3, v23, 0, 1, v23, 2, 3, v24, 0, 1, v24, 2, 3, v25, 0, 1, v25, 2, 3
    qq_butterfly_mixed  v0,  v2,  v4,  v6,  v1,  v3,  v5,  v7, v16, v17, v18, v19,  v8, v10, v12, v14,  v9, v11, v13, v15, v28, v29, v30, v31, v20,  v24, 0, 1, v24, 2, 3, v25, 0, 1, v25, 2, 3, v26, 0, 1, v26, 2, 3, v27, 0, 1, v27, 2, 3
    qq_butterfly_bot  v8, v10, v12, v14,  v9, v11, v13, v15, v28, v29, v30, v31, v20, v26, 0, 1, v26, 2, 3, v27, 0, 1, v27, 2, 3

    mov counter, #3
    _ntt_top_loop:

    st1 { v1.4S}, [ src1], #16
    ld1 { v1.4S}, [ src1]
    st1 { v3.4S}, [ src3], #16
    ld1 { v3.4S}, [ src3]
    st1 { v5.4S}, [ src5], #16
    ld1 { v5.4S}, [ src5]
    st1 { v7.4S}, [ src7], #16
    ld1 { v7.4S}, [ src7]
    st1 { v9.4S}, [ src9], #16
    ld1 { v9.4S}, [ src9]
    st1 {v11.4S}, [src11], #16
    ld1 {v11.4S}, [src11]
    st1 {v13.4S}, [src13], #16
    ld1 {v13.4S}, [src13]
    st1 {v15.4S}, [src15], #16
    ld1 {v15.4S}, [src15]

    st1 { v0.4S}, [ src0], #16
    ld1 { v0.4S}, [ src0]
    st1 { v2.4S}, [ src2], #16
    ld1 { v2.4S}, [ src2]
    st1 { v4.4S}, [ src4], #16
    ld1 { v4.4S}, [ src4]
    st1 { v6.4S}, [ src6], #16
    ld1 { v6.4S}, [ src6]
    st1 { v8.4S}, [ src8], #16
    ld1 { v8.4S}, [ src8]
    st1 {v10.4S}, [src10], #16
    ld1 {v10.4S}, [src10]
    st1 {v12.4S}, [src12], #16
    ld1 {v12.4S}, [src12]
    st1 {v14.4S}, [src14], #16
    ld1 {v14.4S}, [src14]

    qq_butterfly_top  v1,  v3,  v5,  v7,  v9, v11, v13, v15, v16, v17, v18, v19, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3
    qq_butterfly_mixed  v1,  v3,  v5,  v7,  v9, v11, v13, v15, v16, v17, v18, v19,  v0,  v2,  v4,  v6,  v8, v10, v12, v14, v28, v29, v30, v31, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3
    qq_butterfly_mixed  v0,  v2,  v4,  v6,  v8, v10, v12, v14, v28, v29, v30, v31,  v1,  v3,  v9, v11,  v5,  v7, v13, v15, v16, v17, v18, v19, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3
    qq_butterfly_mixed  v1,  v3,  v9, v11,  v5,  v7, v13, v15, v16, v17, v18, v19,  v0,  v2,  v8, v10,  v4,  v6, v12, v14, v28, v29, v30, v31, v20, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3
    qq_butterfly_mixed  v0,  v2,  v8, v10,  v4,  v6, v12, v14, v28, v29, v30, v31,  v1,  v5,  v9, v13,  v3,  v7, v11, v15, v16, v17, v18, v19, v20, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3, v22, 0, 1, v22, 2, 3, v23, 0, 1, v23, 2, 3
    qq_butterfly_mixed  v1,  v5,  v9, v13,  v3,  v7, v11, v15, v16, v17, v18, v19,  v0,  v4,  v8, v12,  v2,  v6, v10, v14, v28, v29, v30, v31, v20, v22, 0, 1, v22, 2, 3, v23, 0, 1, v23, 2, 3, v22, 0, 1, v22, 2, 3, v23, 0, 1, v23, 2, 3
    qq_butterfly_mixed  v0,  v4,  v8, v12,  v2,  v6, v10, v14, v28, v29, v30, v31,  v0,  v2,  v4,  v6,  v1,  v3,  v5,  v7, v16, v17, v18, v19, v20, v22, 0, 1, v22, 2, 3, v23, 0, 1, v23, 2, 3, v24, 0, 1, v24, 2, 3, v25, 0, 1, v25, 2, 3
    qq_butterfly_mixed  v0,  v2,  v4,  v6,  v1,  v3,  v5,  v7, v16, v17, v18, v19,  v8, v10, v12, v14,  v9, v11, v13, v15, v28, v29, v30, v31, v20,  v24, 0, 1, v24, 2, 3, v25, 0, 1, v25, 2, 3, v26, 0, 1, v26, 2, 3, v27, 0, 1, v27, 2, 3
    qq_butterfly_bot  v8, v10, v12, v14,  v9, v11, v13, v15, v28, v29, v30, v31, v20, v26, 0, 1, v26, 2, 3, v27, 0, 1, v27, 2, 3

    sub counter, counter, #1
    cbnz counter, _ntt_top_loop

    st1 { v1.4S}, [ src1], #16
    st1 { v3.4S}, [ src3], #16
    st1 { v5.4S}, [ src5], #16
    st1 { v7.4S}, [ src7], #16
    st1 { v9.4S}, [ src9], #16
    st1 {v11.4S}, [src11], #16
    st1 {v13.4S}, [src13], #16
    st1 {v15.4S}, [src15], #16

    st1 { v0.4S}, [ src0], #16
    st1 { v2.4S}, [ src2], #16
    st1 { v4.4S}, [ src4], #16
    st1 { v6.4S}, [ src6], #16
    st1 { v8.4S}, [ src8], #16
    st1 {v10.4S}, [src10], #16
    st1 {v12.4S}, [src12], #16
    st1 {v14.4S}, [src14], #16

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
    src0      .req x0
    des0      .req x1
    src1      .req x2
    des1      .req x3
    table0    .req x28
    table1    .req x27
    counter   .req x19

    ldr Q, [x2]

    add table0, x1, #128
    add table1, table0, #1024

    add src1, src0, #512

    add des0, src0, #0
    add des1, src0, #512

    mov counter, #8
    _ntt_bot_loop:

    ld1 {  v0.4S,  v1.4S,  v2.4S,  v3.4S}, [src0], #64
    ld1 { v16.4S, v17.4S, v18.4S, v19.4S}, [src1], #64

    ld1 {  v4.4S,  v5.4S}, [table0], #32
    ld2 {  v6.4S,  v7.4S}, [table0], #32
    ld4 {  v8.4S,  v9.4S, v10.4S, v11.4S}, [table0], #64
    ld1 { v20.4S, v21.4S}, [table1], #32
    ld2 { v22.4S, v23.4S}, [table1], #32
    ld4 { v24.4S, v25.4S, v26.4S, v27.4S}, [table1], #64

    mov v4.S[0], Q

    dq_butterfly_top  v0,  v1,  v2,  v3, v12, v13, v4,  v4, 2, 3,  v4, 2, 3
    dq_butterfly_mixed  v0,  v1,  v2,  v3, v12, v13, v16, v17, v18, v19, v28, v29, v4,  v4, 2, 3,  v4, 2, 3, v20, 2, 3, v20, 2, 3
    dq_butterfly_mixed v16, v17, v18, v19, v28, v29,  v0,  v2,  v1,  v3, v12, v13, v4, v20, 2, 3, v20, 2, 3,  v5, 0, 1,  v5, 2, 3
    dq_butterfly_mixed  v0,  v2,  v1,  v3, v12, v13, v16, v18, v17, v19, v28, v29, v4,  v5, 0, 1,  v5, 2, 3, v21, 0, 1, v21, 2, 3
    dq_butterfly_bot v16, v18, v17, v19, v28, v29, v4, v21, 0, 1, v21, 2, 3

    trn_4x4  v0,  v1,  v2,  v3, v12, v13, v14, v15
    trn_4x4 v16, v17, v18, v19, v28, v29, v30, v31

    dq_butterfly_vec_top  v0,  v1,  v2,  v3, v12, v13, v4,  v6,  v7,  v6,  v7
    dq_butterfly_vec_mixed  v0,  v1,  v2,  v3, v12, v13, v16, v17, v18, v19, v28, v29, v4,  v6,  v7,  v6,  v7, v22, v23, v22, v23
    dq_butterfly_vec_mixed v16, v17, v18, v19, v28, v29,  v0,  v2,  v1,  v3, v12, v13, v4, v22, v23, v22, v23,  v8,  v9, v10, v11
    dq_butterfly_vec_mixed  v0,  v2,  v1,  v3, v12, v13, v16, v18, v17, v19, v28, v29, v4,  v8,  v9, v10, v11, v24, v25, v26, v27
    dq_butterfly_vec_bot v16, v18, v17, v19, v28, v29, v4, v24, v25, v26, v27

    st4 {  v0.4S,  v1.4S,  v2.4S,  v3.4S}, [des0], #64
    st4 { v16.4S, v17.4S, v18.4S, v19.4S}, [des1], #64

    sub counter, counter, #1
    cbnz counter, _ntt_bot_loop

    .unreq    Q
    .unreq    src0
    .unreq    des0
    .unreq    src1
    .unreq    des1
    .unreq    table0
    .unreq    table1
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
    Qhalf     .req w21
    nQhalf    .req w22
    invNR2ph  .req w24
    invNR2dp  .req w25
    invNWR2ph .req w26
    invNWR2dp .req w27
    src0      .req  x0
    src1      .req  x1
    src2      .req  x2
    src3      .req  x3
    src4      .req  x4
    src5      .req  x5
    src6      .req  x6
    src7      .req  x7
    src8      .req  x8
    src9      .req  x9
    src10     .req x10
    src11     .req x11
    src12     .req x12
    src13     .req x13
    src14     .req x14
    src15     .req x15
    table     .req x28
    counter   .req x19

    ldr Q, [x2, #0]
    lsr Qhalf, Q, #1
    neg nQhalf, Qhalf

    ldr invNR2ph,  [x2, #16]
    ldr invNR2dp,  [x2, #20]
    ldr invNWR2ph, [x2, #24]
    ldr invNWR2dp, [x2, #28]

    mov table, x1

    add  src1, src0, #64
    add  src2, src0, #128

    add  src3, src0, #192
    add  src4, src0, #256

    add  src5, src0, #320
    add  src6, src0, #384

    add  src7, src0, #448
    add  src8, src0, #512

    add  src9, src0, #576
    add src10, src0, #640

    add src11, src0, #704
    add src12, src0, #768

    add src13, src0, #832
    add src14, src0, #896

    add src15, src0, #960

    ld1 {v20.4S, v21.4S, v22.4S, v23.4S}, [table], #64
    ld1 {v24.4S, v25.4S, v26.4S, v27.4S}, [table], #64

    mov v20.S[0], Q

    ld1 { v0.4S}, [ src0]
    ld1 { v1.4S}, [ src1]
    ld1 { v2.4S}, [ src2]
    ld1 { v3.4S}, [ src3]
    ld1 { v4.4S}, [ src4]
    ld1 { v5.4S}, [ src5]
    ld1 { v6.4S}, [ src6]
    ld1 { v7.4S}, [ src7]

    ld1 { v8.4S}, [ src8]
    ld1 { v9.4S}, [ src9]
    ld1 {v10.4S}, [src10]
    ld1 {v11.4S}, [src11]
    ld1 {v12.4S}, [src12]
    ld1 {v13.4S}, [src13]
    ld1 {v14.4S}, [src14]
    ld1 {v15.4S}, [src15]

    qq_butterfly_bot  v0,  v2,  v4,  v6, v16, v17, v18, v19,  v1,  v3,  v5,  v7, v20, v24, 0, 1, v24, 2, 3, v25, 0, 1, v25, 2, 3
    qq_butterfly_mixed_rev  v0,  v2,  v4,  v6, v16, v17, v18, v19,  v1,  v3,  v5,  v7,  v8, v10, v12, v14, v28, v29, v30, v31,  v9, v11, v13, v15, v20, v24, 0, 1, v24, 2, 3, v25, 0, 1, v25, 2, 3, v26, 0, 1, v26, 2, 3, v27, 0, 1, v27, 2, 3
    qq_butterfly_mixed_rev  v8, v10, v12, v14, v28, v29, v30, v31,  v9, v11, v13, v15,  v0,  v1,  v4,  v5, v16, v17, v18, v19,  v2,  v3,  v6,  v7, v20, v26, 0, 1, v26, 2, 3, v27, 0, 1, v27, 2, 3, v22, 0, 1, v22, 0, 1, v22, 2, 3, v22, 2, 3
    qq_butterfly_mixed_rev  v0,  v1,  v4,  v5, v16, v17, v18, v19,  v2,  v3,  v6,  v7,  v8,  v9, v12, v13, v28, v29, v30, v31, v10, v11, v14, v15, v20, v22, 0, 1, v22, 0, 1, v22, 2, 3, v22, 2, 3, v23, 0, 1, v23, 0, 1, v23, 2, 3, v23, 2, 3
    qq_butterfly_mixed_rev  v8,  v9, v12, v13, v28, v29, v30, v31, v10, v11, v14, v15,  v0,  v1,  v2,  v3, v16, v17, v18, v19,  v4,  v5,  v6,  v7, v20, v23, 0, 1, v23, 0, 1, v23, 2, 3, v23, 2, 3, v21, 0, 1, v21, 0, 1, v21, 0, 1, v21, 0, 1
    qq_butterfly_mixed_rev  v0,  v1,  v2,  v3, v16, v17, v18, v19,  v4,  v5,  v6,  v7,  v8,  v9, v10, v11, v28, v29, v30, v31, v12, v13, v14, v15, v20, v21, 0, 1, v21, 0, 1, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3, v21, 2, 3, v21, 2, 3
    qq_butterfly_top  v8,  v9, v10, v11, v28, v29, v30, v31, v12, v13, v14, v15, v20, v21, 2, 3, v21, 2, 3, v21, 2, 3, v21, 2, 3

    mov v20.S[2], invNWR2ph
    mov v20.S[3], invNWR2dp

    qq_sub_add v16, v17, v18, v19, v28, v29, v30, v31,  v0,  v2,  v4,  v6,  v8, v10, v12, v14
    qq_sub_add  v0,  v2,  v4,  v6,  v8, v10, v12, v14,  v1,  v3,  v5,  v7,  v9, v11, v13, v15

    qq_montgomery_mul  v9, v11, v13, v15,  v8, v10, v12, v14, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3
    qq_montgomery_mul  v8, v10, v12, v14, v28, v29, v30, v31, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3

    mov v20.S[2], invNR2ph
    mov v20.S[3], invNR2dp

    qq_montgomery_mul  v1,  v3,  v5,  v7,  v0,  v2,  v4,  v6, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3
    qq_montgomery_mul  v0,  v2,  v4,  v6, v16, v17, v18, v19, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3

    dup v29.4S, Q
    dup v30.4S, Qhalf
    dup v31.4S, nQhalf

    cmge v18.4S, v31.4S,  v0.4S
    cmge v19.4S, v31.4S,  v1.4S
    cmge v16.4S,  v0.4S, v30.4S
    cmge v17.4S,  v1.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v0.4S, v16.4S, v29.4S
    mla   v1.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S,  v2.4S
    cmge v19.4S, v31.4S,  v3.4S
    cmge v16.4S,  v2.4S, v30.4S
    cmge v17.4S,  v3.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v2.4S, v16.4S, v29.4S
    mla   v3.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S,  v4.4S
    cmge v19.4S, v31.4S,  v5.4S
    cmge v16.4S,  v4.4S, v30.4S
    cmge v17.4S,  v5.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v4.4S, v16.4S, v29.4S
    mla   v5.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S,  v6.4S
    cmge v19.4S, v31.4S,  v7.4S
    cmge v16.4S,  v6.4S, v30.4S
    cmge v17.4S,  v7.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v6.4S, v16.4S, v29.4S
    mla   v7.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S,  v8.4S
    cmge v19.4S, v31.4S,  v9.4S
    cmge v16.4S,  v8.4S, v30.4S
    cmge v17.4S,  v9.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v8.4S, v16.4S, v29.4S
    mla   v9.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S, v10.4S
    cmge v19.4S, v31.4S, v11.4S
    cmge v16.4S, v10.4S, v30.4S
    cmge v17.4S, v11.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla  v10.4S, v16.4S, v29.4S
    mla  v11.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S, v12.4S
    cmge v19.4S, v31.4S, v13.4S
    cmge v16.4S, v12.4S, v30.4S
    cmge v17.4S, v13.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla  v12.4S, v16.4S, v29.4S
    mla  v13.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S, v14.4S
    cmge v19.4S, v31.4S, v15.4S
    cmge v16.4S, v14.4S, v30.4S
    cmge v17.4S, v15.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla  v14.4S, v16.4S, v29.4S
    mla  v15.4S, v17.4S, v29.4S

    mov counter, #3
    _intt_top_loop:

    st1 { v0.4S}, [ src0], #16
    ld1 { v0.4S}, [ src0]
    st1 { v1.4S}, [ src1], #16
    ld1 { v1.4S}, [ src1]
    st1 { v2.4S}, [ src2], #16
    ld1 { v2.4S}, [ src2]
    st1 { v3.4S}, [ src3], #16
    ld1 { v3.4S}, [ src3]
    st1 { v4.4S}, [ src4], #16
    ld1 { v4.4S}, [ src4]
    st1 { v5.4S}, [ src5], #16
    ld1 { v5.4S}, [ src5]
    st1 { v6.4S}, [ src6], #16
    ld1 { v6.4S}, [ src6]
    st1 { v7.4S}, [ src7], #16
    ld1 { v7.4S}, [ src7]

    st1 { v8.4S}, [ src8], #16
    ld1 { v8.4S}, [ src8]
    st1 { v9.4S}, [ src9], #16
    ld1 { v9.4S}, [ src9]
    st1 {v10.4S}, [src10], #16
    ld1 {v10.4S}, [src10]
    st1 {v11.4S}, [src11], #16
    ld1 {v11.4S}, [src11]
    st1 {v12.4S}, [src12], #16
    ld1 {v12.4S}, [src12]
    st1 {v13.4S}, [src13], #16
    ld1 {v13.4S}, [src13]
    st1 {v14.4S}, [src14], #16
    ld1 {v14.4S}, [src14]
    st1 {v15.4S}, [src15], #16
    ld1 {v15.4S}, [src15]

    qq_butterfly_bot  v0,  v2,  v4,  v6, v16, v17, v18, v19,  v1,  v3,  v5,  v7, v20, v24, 0, 1, v24, 2, 3, v25, 0, 1, v25, 2, 3
    qq_butterfly_mixed_rev  v0,  v2,  v4,  v6, v16, v17, v18, v19,  v1,  v3,  v5,  v7,  v8, v10, v12, v14, v28, v29, v30, v31,  v9, v11, v13, v15, v20, v24, 0, 1, v24, 2, 3, v25, 0, 1, v25, 2, 3, v26, 0, 1, v26, 2, 3, v27, 0, 1, v27, 2, 3
    qq_butterfly_mixed_rev  v8, v10, v12, v14, v28, v29, v30, v31,  v9, v11, v13, v15,  v0,  v1,  v4,  v5, v16, v17, v18, v19,  v2,  v3,  v6,  v7, v20, v26, 0, 1, v26, 2, 3, v27, 0, 1, v27, 2, 3, v22, 0, 1, v22, 0, 1, v22, 2, 3, v22, 2, 3
    qq_butterfly_mixed_rev  v0,  v1,  v4,  v5, v16, v17, v18, v19,  v2,  v3,  v6,  v7,  v8,  v9, v12, v13, v28, v29, v30, v31, v10, v11, v14, v15, v20, v22, 0, 1, v22, 0, 1, v22, 2, 3, v22, 2, 3, v23, 0, 1, v23, 0, 1, v23, 2, 3, v23, 2, 3
    qq_butterfly_mixed_rev  v8,  v9, v12, v13, v28, v29, v30, v31, v10, v11, v14, v15,  v0,  v1,  v2,  v3, v16, v17, v18, v19,  v4,  v5,  v6,  v7, v20, v23, 0, 1, v23, 0, 1, v23, 2, 3, v23, 2, 3, v21, 0, 1, v21, 0, 1, v21, 0, 1, v21, 0, 1
    qq_butterfly_mixed_rev  v0,  v1,  v2,  v3, v16, v17, v18, v19,  v4,  v5,  v6,  v7,  v8,  v9, v10, v11, v28, v29, v30, v31, v12, v13, v14, v15, v20, v21, 0, 1, v21, 0, 1, v21, 0, 1, v21, 0, 1, v21, 2, 3, v21, 2, 3, v21, 2, 3, v21, 2, 3
    qq_butterfly_top  v8,  v9, v10, v11, v28, v29, v30, v31, v12, v13, v14, v15, v20, v21, 2, 3, v21, 2, 3, v21, 2, 3, v21, 2, 3

    mov v20.S[2], invNWR2ph
    mov v20.S[3], invNWR2dp

    qq_sub_add v16, v17, v18, v19, v28, v29, v30, v31,  v0,  v2,  v4,  v6,  v8, v10, v12, v14
    qq_sub_add  v0,  v2,  v4,  v6,  v8, v10, v12, v14,  v1,  v3,  v5,  v7,  v9, v11, v13, v15

    qq_montgomery_mul  v9, v11, v13, v15,  v8, v10, v12, v14, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3
    qq_montgomery_mul  v8, v10, v12, v14, v28, v29, v30, v31, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3

    mov v20.S[2], invNR2ph
    mov v20.S[3], invNR2dp

    qq_montgomery_mul  v1,  v3,  v5,  v7,  v0,  v2,  v4,  v6, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3
    qq_montgomery_mul  v0,  v2,  v4,  v6, v16, v17, v18, v19, v20, v20, 2, 3, v20, 2, 3, v20, 2, 3, v20, 2, 3

    dup v29.4S, Q
    dup v30.4S, Qhalf
    dup v31.4S, nQhalf

    cmge v18.4S, v31.4S,  v0.4S
    cmge v19.4S, v31.4S,  v1.4S
    cmge v16.4S,  v0.4S, v30.4S
    cmge v17.4S,  v1.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v0.4S, v16.4S, v29.4S
    mla   v1.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S,  v2.4S
    cmge v19.4S, v31.4S,  v3.4S
    cmge v16.4S,  v2.4S, v30.4S
    cmge v17.4S,  v3.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v2.4S, v16.4S, v29.4S
    mla   v3.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S,  v4.4S
    cmge v19.4S, v31.4S,  v5.4S
    cmge v16.4S,  v4.4S, v30.4S
    cmge v17.4S,  v5.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v4.4S, v16.4S, v29.4S
    mla   v5.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S,  v6.4S
    cmge v19.4S, v31.4S,  v7.4S
    cmge v16.4S,  v6.4S, v30.4S
    cmge v17.4S,  v7.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v6.4S, v16.4S, v29.4S
    mla   v7.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S,  v8.4S
    cmge v19.4S, v31.4S,  v9.4S
    cmge v16.4S,  v8.4S, v30.4S
    cmge v17.4S,  v9.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla   v8.4S, v16.4S, v29.4S
    mla   v9.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S, v10.4S
    cmge v19.4S, v31.4S, v11.4S
    cmge v16.4S, v10.4S, v30.4S
    cmge v17.4S, v11.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla  v10.4S, v16.4S, v29.4S
    mla  v11.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S, v12.4S
    cmge v19.4S, v31.4S, v13.4S
    cmge v16.4S, v12.4S, v30.4S
    cmge v17.4S, v13.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla  v12.4S, v16.4S, v29.4S
    mla  v13.4S, v17.4S, v29.4S

    cmge v18.4S, v31.4S, v14.4S
    cmge v19.4S, v31.4S, v15.4S
    cmge v16.4S, v14.4S, v30.4S
    cmge v17.4S, v15.4S, v30.4S

    sub  v16.4S, v16.4S, v18.4S
    sub  v17.4S, v17.4S, v19.4S

    mla  v14.4S, v16.4S, v29.4S
    mla  v15.4S, v17.4S, v29.4S

    sub counter, counter, #1
    cbnz counter, _intt_top_loop

    st1 { v0.4S}, [ src0], #16
    st1 { v1.4S}, [ src1], #16
    st1 { v2.4S}, [ src2], #16
    st1 { v3.4S}, [ src3], #16
    st1 { v4.4S}, [ src4], #16
    st1 { v5.4S}, [ src5], #16
    st1 { v6.4S}, [ src6], #16
    st1 { v7.4S}, [ src7], #16

    st1 { v8.4S}, [ src8], #16
    st1 { v9.4S}, [ src9], #16
    st1 {v10.4S}, [src10], #16
    st1 {v11.4S}, [src11], #16
    st1 {v12.4S}, [src12], #16
    st1 {v13.4S}, [src13], #16
    st1 {v14.4S}, [src14], #16
    st1 {v15.4S}, [src15], #16

    .unreq    Q
    .unreq    Qhalf
    .unreq    nQhalf
    .unreq    invNR2ph
    .unreq    invNR2dp
    .unreq    invNWR2ph
    .unreq    invNWR2dp
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
.global __asm_intt_SIMD_bot
.global ___asm_intt_SIMD_bot
__asm_intt_SIMD_bot:
___asm_intt_SIMD_bot:

    push_all
    Q         .req w20
    RphRdp    .req x21
    src0      .req x0
    des0      .req x1
    src1      .req x2
    des1      .req x3
    table0    .req x28
    table1    .req x27
    counter   .req x19

    ldr Q, [x2]
    ldr RphRdp, [x2, #8]

    add table0, x1, #128
    add table1, table0, #1024

    add src1, src0, #512    

    add des0, src0, #0
    add des1, src0, #512

    mov counter, #8
    _intt_bot_loop:

    ld4 {  v0.4S,  v1.4S,  v2.4S,  v3.4S}, [src0], #64
    ld4 { v16.4S, v17.4S, v18.4S, v19.4S}, [src1], #64

    ld1 {  v4.4S,  v5.4S}, [table0], #32
    ld2 {  v6.4S,  v7.4S}, [table0], #32
    ld4 {  v8.4S,  v9.4S, v10.4S, v11.4S}, [table0], #64
    ld1 { v20.4S, v21.4S}, [table1], #32
    ld2 { v22.4S, v23.4S}, [table1], #32
    ld4 { v24.4S, v25.4S, v26.4S, v27.4S}, [table1], #64

    mov v4.S[0], Q
    mov v20.D[0], RphRdp

    dq_butterfly_vec_bot  v0,  v2, v12, v13,  v1,  v3,  v4,  v8,  v9, v10, v11
    dq_butterfly_vec_mixed_rev  v0,  v2, v12, v13,  v1,  v3, v16, v18, v28, v29, v17, v19,  v4,  v8,  v9, v10, v11, v24, v25, v26, v27
    dq_butterfly_vec_mixed_rev v16, v18, v28, v29, v17, v19,  v0,  v1, v12, v13,  v2,  v3,  v4, v24, v25, v26, v27,  v6,  v7,  v6,  v7
    dq_butterfly_vec_mixed_rev  v0,  v1, v12, v13,  v2,  v3, v16, v17, v28, v29, v18, v19,  v4,  v6,  v7,  v6,  v7, v22, v23, v22, v23
    dq_butterfly_vec_top v16, v17, v28, v29, v18, v19,  v4, v22, v23, v22, v23

    trn_4x4  v0,  v1,  v2,  v3, v12, v13, v14, v15
    trn_4x4 v16, v17, v18, v19, v28, v29, v30, v31

    dq_butterfly_bot  v0,  v2, v12, v13,  v1,  v3,  v4,  v5, 0, 1,  v5, 2, 3
    dq_butterfly_mixed_rev  v0,  v2, v12, v13,  v1,  v3, v16, v18, v28, v29, v17, v19,  v4,  v5, 0, 1,  v5, 2, 3, v21, 0, 1, v21, 2, 3
    dq_butterfly_mixed_rev v16, v18, v28, v29, v17, v19,  v0,  v1, v12, v13,  v2,  v3,  v4, v21, 0, 1, v21, 2, 3,  v4, 2, 3,  v4, 2, 3
    dq_butterfly_mixed_rev  v0,  v1, v12, v13,  v2,  v3, v16, v17, v28, v29, v18, v19,  v4,  v4, 2, 3,  v4, 2, 3, v20, 2, 3, v20, 2, 3
    dq_butterfly_top v16, v17, v28, v29, v18, v19,  v4, v20, 2, 3, v20, 2, 3

    srshr v14.4S,  v0.4S, #23
    srshr v15.4S,  v1.4S, #23
    srshr v30.4S, v16.4S, #23
    srshr v31.4S, v17.4S, #23

    mls    v0.4S, v14.4S, v4.S[0]
    mls    v1.4S, v15.4S, v4.S[0]
    mls   v16.4S, v30.4S, v4.S[0]
    mls   v17.4S, v31.4S, v4.S[0]

    st1 {  v0.4S,  v1.4S,  v2.4S,  v3.4S}, [des0], #64
    st1 { v16.4S, v17.4S, v18.4S, v19.4S}, [des1], #64

    sub counter, counter, #1
    cbnz counter, _intt_bot_loop

    .unreq    Q
    .unreq    RphRdp
    .unreq    src0
    .unreq    des0
    .unreq    src1
    .unreq    des1
    .unreq    table0
    .unreq    table1
    .unreq    counter
    pop_all

    br lr






