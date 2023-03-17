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

#if defined(__ARM_FEATURE_SHA3)

/********************** CONSTANTS *************************/
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
    .quad 0x0

/****************** REGISTER ALLOCATIONS *******************/

    input_addr     .req x0
    const_addr     .req x1
    count          .req x2
    cur_const      .req x3

    /* Mapping of Kecck-f1600 state to vector registers
     * at the beginning and end of each round. */
    ASba     .req v0
    ASbe     .req v1
    ASbi     .req v2
    ASbo     .req v3
    ASbu     .req v4
    ASga     .req v5
    ASge     .req v6
    ASgi     .req v7
    ASgo     .req v8
    ASgu     .req v9
    ASka     .req v10
    ASke     .req v11
    ASki     .req v12
    ASko     .req v13
    ASku     .req v14
    ASma     .req v15
    ASme     .req v16
    ASmi     .req v17
    ASmo     .req v18
    ASmu     .req v19
    ASsa     .req v20
    ASse     .req v21
    ASsi     .req v22
    ASso     .req v23
    ASsu     .req v24

    /* q-form of the above mapping */
    ASbaq    .req q0
    ASbeq    .req q1
    ASbiq    .req q2
    ASboq    .req q3
    ASbuq    .req q4
    ASgaq    .req q5
    ASgeq    .req q6
    ASgiq    .req q7
    ASgoq    .req q8
    ASguq    .req q9
    ASkaq    .req q10
    ASkeq    .req q11
    ASkiq    .req q12
    ASkoq    .req q13
    ASkuq    .req q14
    ASmaq    .req q15
    ASmeq    .req q16
    ASmiq    .req q17
    ASmoq    .req q18
    ASmuq    .req q19
    ASsaq    .req q20
    ASseq    .req q21
    ASsiq    .req q22
    ASsoq    .req q23
    ASsuq    .req q24

    Ascratch0 .req v25
    Ascratch1 .req v26
    Ascratch2 .req v27
    Ascratch3 .req v28
    Ascratch4 .req v29
    Ascratch5 .req v30
    Ascratch6 .req v31

    Ascratch0q .req q25
    Ascratch1q .req q26
    Ascratch2q .req q27
    Ascratch3q .req q28
    Ascratch4q .req q29
    Ascratch5q .req q30
    Ascratch6q .req q31

/************************ MACROS ****************************/

.macro load_input
    ldp ASbaq, ASbeq, [input_addr, #(2*8*0)]
    ldp ASbiq, ASboq, [input_addr, #(2*8*2)]
    ldp ASbuq, ASgaq, [input_addr, #(2*8*4)]
    ldp ASgeq, ASgiq, [input_addr, #(2*8*6)]
    ldp ASgoq, ASguq, [input_addr, #(2*8*8)]
    ldp ASkaq, ASkeq, [input_addr, #(2*8*10)]
    ldp ASkiq, ASkoq, [input_addr, #(2*8*12)]
    ldp ASkuq, ASmaq, [input_addr, #(2*8*14)]
    ldp ASmeq, ASmiq, [input_addr, #(2*8*16)]
    ldp ASmoq, ASmuq, [input_addr, #(2*8*18)]
    ldp ASsaq, ASseq, [input_addr, #(2*8*20)]
    ldp ASsiq, ASsoq, [input_addr, #(2*8*22)]
    ldr ASsuq, [input_addr, #(2*8*24)]
.endm

.macro store_input in
    str \in\()Sbaq, [input_addr, #(2*8*0)]
    str \in\()Sbeq, [input_addr, #(2*8*1)]
    str \in\()Sbiq, [input_addr, #(2*8*2)]
    str \in\()Sboq, [input_addr, #(2*8*3)]
    str \in\()Sbuq, [input_addr, #(2*8*4)]
    str \in\()Sgaq, [input_addr, #(2*8*5)]
    str \in\()Sgeq, [input_addr, #(2*8*6)]
    str \in\()Sgiq, [input_addr, #(2*8*7)]
    str \in\()Sgoq, [input_addr, #(2*8*8)]
    str \in\()Sguq, [input_addr, #(2*8*9)]
    str \in\()Skaq, [input_addr, #(2*8*10)]
    str \in\()Skeq, [input_addr, #(2*8*11)]
    str \in\()Skiq, [input_addr, #(2*8*12)]
    str \in\()Skoq, [input_addr, #(2*8*13)]
    str \in\()Skuq, [input_addr, #(2*8*14)]
    str \in\()Smaq, [input_addr, #(2*8*15)]
    str \in\()Smeq, [input_addr, #(2*8*16)]
    str \in\()Smiq, [input_addr, #(2*8*17)]
    str \in\()Smoq, [input_addr, #(2*8*18)]
    str \in\()Smuq, [input_addr, #(2*8*19)]
    str \in\()Ssaq, [input_addr, #(2*8*20)]
    str \in\()Sseq, [input_addr, #(2*8*21)]
    str \in\()Ssiq, [input_addr, #(2*8*22)]
    str \in\()Ssoq, [input_addr, #(2*8*23)]
    str \in\()Ssuq, [input_addr, #(2*8*24)]
.endm

#define STACK_SIZE (16*4 + 16*30)
#define STACK_BASE_VREGS 0
#define STACK_BASE_TMP   16*4

#define E0_offset  0
#define E1_offset  1
#define E2_offset  2
#define E3_offset  3
#define E4_offset  4

#define Aba_offset (5 + 0  )
#define Abe_offset (5 + 1  )
#define Abi_offset (5 + 2  )
#define Abo_offset (5 + 3  )
#define Abu_offset (5 + 4  )
#define Aga_offset (5 + 5  )
#define Age_offset (5 + 6  )
#define Agi_offset (5 + 7  )
#define Ago_offset (5 + 8  )
#define Agu_offset (5 + 9  )
#define Aka_offset (5 + 10 )
#define Ake_offset (5 + 11 )
#define Aki_offset (5 + 12 )
#define Ako_offset (5 + 13 )
#define Aku_offset (5 + 14 )
#define Ama_offset (5 + 15 )
#define Ame_offset (5 + 16 )
#define Ami_offset (5 + 17 )
#define Amo_offset (5 + 18 )
#define Amu_offset (5 + 19 )
#define Asa_offset (5 + 20 )
#define Ase_offset (5 + 21 )
#define Asi_offset (5 + 22 )
#define Aso_offset (5 + 23 )
#define Asu_offset (5 + 24 )

#define ba_offset (5 + 0  )
#define be_offset (5 + 1  )
#define bi_offset (5 + 2  )
#define bo_offset (5 + 3  )
#define bu_offset (5 + 4  )
#define ga_offset (5 + 5  )
#define ge_offset (5 + 6  )
#define gi_offset (5 + 7  )
#define go_offset (5 + 8  )
#define gu_offset (5 + 9  )
#define ka_offset (5 + 10 )
#define ke_offset (5 + 11 )
#define ki_offset (5 + 12 )
#define ko_offset (5 + 13 )
#define ku_offset (5 + 14 )
#define ma_offset (5 + 15 )
#define me_offset (5 + 16 )
#define mi_offset (5 + 17 )
#define mo_offset (5 + 18 )
#define mu_offset (5 + 19 )
#define sa_offset (5 + 20 )
#define se_offset (5 + 21 )
#define si_offset (5 + 22 )
#define so_offset (5 + 23 )
#define su_offset (5 + 24 )

.macro alloc_stack
   sub sp, sp, #(STACK_SIZE)
.endm

.macro free_stack
    add sp, sp, #(STACK_SIZE)
.endm

#define savep(reg, offset_prefix) \
    str reg, [sp, #(STACK_BASE_TMP + 16 * offset_prefix ## _offset)]
#define restorep(reg, offset_prefix) \
    ldr reg, [sp, #(STACK_BASE_TMP + 16 * offset_prefix ## _offset)]
#define save(name) savep(name ## q,name)
#define restore(name) restorep(name ## q,name)

.macro save_vregs
    stp  d8,  d9, [sp, #(STACK_BASE_VREGS + 16*0)]
    stp d10, d11, [sp, #(STACK_BASE_VREGS + 16*1)]
    stp d12, d13, [sp, #(STACK_BASE_VREGS + 16*2)]
    stp d14, d15, [sp, #(STACK_BASE_VREGS + 16*3)]
.endm

.macro restore_vregs
    ldp  d8,  d9, [sp, #(STACK_BASE_VREGS + 16*0)]
    ldp d10, d11, [sp, #(STACK_BASE_VREGS + 16*1)]
    ldp d12, d13, [sp, #(STACK_BASE_VREGS + 16*2)]
    ldp d14, d15, [sp, #(STACK_BASE_VREGS + 16*3)]
.endm

/* Macros using v8.4-A SHA-3 instructions */

.macro eor3_m1_0 d s0 s1 s2
    eor \d\().16b, \s0\().16b, \s1\().16b
.endm

.macro eor2 d s0 s1
    eor \d\().16b, \s0\().16b, \s1\().16b
.endm

.macro eor3_m1_1 d s0 s1 s2
    eor \d\().16b, \d\().16b,  \s2\().16b
.endm

.macro eor3_m1 d s0 s1 s2
    eor3_m1_0 \d, \s0, \s1, \s2
    eor3_m1_1 \d, \s0, \s1, \s2
.endm

.macro rax1_m1 d s0 s1
   add tmp.2d, \s1\().2d, \s1\().2d
   sri tmp.2d, \s1\().2d, #63
   eor \d\().16b, tmp.16b, \s0\().16b
.endm

.macro xar_m1 d s0 s1 imm
   eor tmp.16b, \s0\().16b, \s1\().16b
   shl \d\().2d, tmp.2d, #(64-\imm)
   sri \d\().2d, tmp.2d, #(\imm)
.endm

.macro bcax_m1 d s0 s1 s2
    bic tmp.16b, \s1\().16b, \s2\().16b
    eor \d\().16b, tmp.16b, \s0\().16b
.endm

.macro eor3_m0 d s0 s1 s2
    eor3 \d\().16b, \s0\().16b, \s1\().16b, \s2\().16b
.endm

.macro rax1_m0 d s0 s1
    rax1 \d\().2d, \s0\().2d, \s1\().2d
.endm

.macro xar_m0 d s0 s1 imm
    xar \d\().2d, \s0\().2d, \s1\().2d, #\imm
.endm

.macro bcax_m0 d s0 s1 s2
    bcax \d\().16b, \s0\().16b, \s1\().16b, \s2\().16b
.endm

#define CONCAT5(a,b,c,d,e) a ## b ## c ## d ## e
#define CONCAT4(a,b,c,d) a ## b ## c ## d

#define OUT(x)   \out\()S##x
#define IN(x)    \in\()S##x
#define B(x)     \in\()B##x
#define E(x)     \in\()E##x
#define C(x)     \in\()C##x
#define Cnext(x) \out\()C##x
#define TMP_IN(x) \in\()scratch ## x
#define TMP_OUT(x) \out\()scratch ## x

#define OUTq(x)   \out\()S##x##q
#define INq(x)    \in\()S##x##q
#define Bq(x)     \in\()B##x##q
#define Eq(x)     \in\()E##x##q
#define Cq(x)     \in\()C##x##q
#define Cnextq(x) \out\()C##x##q
#define TMP_INq(x)  \in\()scratch ## x ## q
#define TMP_OUTq(x) \out\()scratch ## x ## q

.macro declare_mappings out, in

    C(0) .req TMP_IN(0)
    C(1) .req TMP_IN(1)
    C(2) .req TMP_IN(2)
    C(3) .req TMP_IN(3)
    C(4) .req TMP_IN(4)

    Cq(0) .req TMP_INq(0)
    Cq(1) .req TMP_INq(1)
    Cq(2) .req TMP_INq(2)
    Cq(3) .req TMP_INq(3)
    Cq(4) .req TMP_INq(4)

    E(1) .req TMP_IN(5)
    E(3) .req C(2)
    E(0) .req C(4)
    E(2) .req C(1)
    E(4) .req C(3)

    Eq(1) .req TMP_INq(5)
    Eq(3) .req Cq(2)
    Eq(0) .req Cq(4)
    Eq(2) .req Cq(1)
    Eq(4) .req Cq(3)

    /* A_[y,2*x+3*y] = rot(A[x,y]) */
    B(go) .req IN(me)
    B(gi) .req IN(ka)
    B(ga) .req IN(bo)
    B(ge) .req IN(gu)
    B(gu) .req IN(si)
    B(ki) .req IN(ko)
    B(ko) .req IN(mu)
    B(ka) .req IN(be)
    B(ke) .req IN(gi)
    B(ku) .req IN(sa)
    B(mu) .req IN(so)
    B(mo) .req IN(mi)
    B(mi) .req IN(ke)
    B(ma) .req IN(bu)
    B(me) .req IN(ga)
    B(ba) .req IN(ba)
    B(bi) .req IN(ki)
    B(bo) .req IN(mo)
    B(bu) .req IN(su)
    B(be) .req IN(ge)
    B(sa) .req IN(bi)
    B(so) .req IN(ma)
    B(se) .req IN(go)
    B(si) .req IN(ku)
    B(su) .req IN(se)

    Bq(go) .req INq(me)
    Bq(gi) .req INq(ka)
    Bq(ga) .req INq(bo)
    Bq(ge) .req INq(gu)
    Bq(gu) .req INq(si)
    Bq(ki) .req INq(ko)
    Bq(ko) .req INq(mu)
    Bq(ka) .req INq(be)
    Bq(ke) .req INq(gi)
    Bq(ku) .req INq(sa)
    Bq(mu) .req INq(so)
    Bq(mo) .req INq(mi)
    Bq(mi) .req INq(ke)
    Bq(ma) .req INq(bu)
    Bq(me) .req INq(ga)
    Bq(ba) .req INq(ba)
    Bq(bi) .req INq(ki)
    Bq(bo) .req INq(mo)
    Bq(bu) .req INq(su)
    Bq(be) .req INq(ge)
    Bq(sa) .req INq(bi)
    Bq(so) .req INq(ma)
    Bq(se) .req INq(go)
    Bq(si) .req INq(ku)
    Bq(su) .req INq(se)

    OUT(ba) .req TMP_IN(0)
    OUT(be) .req TMP_IN(5)
    OUT(bi) .req B(bi)
    OUT(bo) .req B(bo)
    OUT(bu) .req B(bu)
    OUT(ga) .req B(ba)
    OUT(ge) .req B(be)
    OUT(gi) .req B(gi)
    OUT(go) .req B(go)
    OUT(gu) .req B(gu)
    OUT(ka) .req B(ga)
    OUT(ke) .req B(ge)
    OUT(ki) .req B(ki)
    OUT(ko) .req B(ko)
    OUT(ku) .req B(ku)
    OUT(ma) .req B(ka)
    OUT(me) .req B(ke)
    OUT(mi) .req B(mi)
    OUT(mo) .req B(mo)
    OUT(mu) .req B(mu)
    OUT(sa) .req B(ma)
    OUT(se) .req B(me)
    OUT(si) .req B(si)
    OUT(so) .req B(so)
    OUT(su) .req B(su)

    OUTq(ba) .req TMP_INq(0)
    OUTq(be) .req TMP_INq(5)
    OUTq(bi) .req Bq(bi)
    OUTq(bo) .req Bq(bo)
    OUTq(bu) .req Bq(bu)
    OUTq(ga) .req Bq(ba)
    OUTq(ge) .req Bq(be)
    OUTq(gi) .req Bq(gi)
    OUTq(go) .req Bq(go)
    OUTq(gu) .req Bq(gu)
    OUTq(ka) .req Bq(ga)
    OUTq(ke) .req Bq(ge)
    OUTq(ki) .req Bq(ki)
    OUTq(ko) .req Bq(ko)
    OUTq(ku) .req Bq(ku)
    OUTq(ma) .req Bq(ka)
    OUTq(me) .req Bq(ke)
    OUTq(mi) .req Bq(mi)
    OUTq(mo) .req Bq(mo)
    OUTq(mu) .req Bq(mu)
    OUTq(sa) .req Bq(ma)
    OUTq(se) .req Bq(me)
    OUTq(si) .req Bq(si)
    OUTq(so) .req Bq(so)
    OUTq(su) .req Bq(su)

    TMP_OUT(0) .req TMP_IN(1)
    TMP_OUT(1) .req TMP_IN(2)
    TMP_OUT(2) .req TMP_IN(3)
    TMP_OUT(3) .req TMP_IN(4)
    TMP_OUT(4) .req B(sa)
    TMP_OUT(5) .req B(se)
    TMP_OUT(6) .req TMP_IN(6)

    TMP_OUTq(0) .req TMP_INq(1)
    TMP_OUTq(1) .req TMP_INq(2)
    TMP_OUTq(2) .req TMP_INq(3)
    TMP_OUTq(3) .req TMP_INq(4)
    TMP_OUTq(4) .req Bq(sa)
    TMP_OUTq(5) .req Bq(se)
    TMP_OUTq(6) .req TMP_INq(6)

    Cnext(0) .req TMP_OUT(0)
    Cnext(1) .req TMP_OUT(1)
    Cnext(2) .req TMP_OUT(2)
    Cnext(3) .req TMP_OUT(3)
    Cnext(4) .req TMP_OUT(4)

    Cnextq(0) .req TMP_OUTq(0)
    Cnextq(1) .req TMP_OUTq(1)
    Cnextq(2) .req TMP_OUTq(2)
    Cnextq(3) .req TMP_OUTq(3)
    Cnextq(4) .req TMP_OUTq(4)

    tmp .req v0
    .unreq tmp
    tmp .req TMP_IN(6)
.endm

.macro undeclare_mappings out, in

    .unreq C(0)
    .unreq C(1)
    .unreq C(2)
    .unreq C(3)
    .unreq C(4)

    .unreq Cq(0)
    .unreq Cq(1)
    .unreq Cq(2)
    .unreq Cq(3)
    .unreq Cq(4)

    .unreq E(2)
    .unreq E(4)
    .unreq E(1)
    .unreq E(3)
    .unreq E(0)

    .unreq Eq(2)
    .unreq Eq(4)
    .unreq Eq(1)
    .unreq Eq(3)
    .unreq Eq(0)

    .unreq B(go)
    .unreq B(gi)
    .unreq B(ga)
    .unreq B(ge)
    .unreq B(gu)
    .unreq B(ki)
    .unreq B(ko)
    .unreq B(ka)
    .unreq B(ke)
    .unreq B(ku)
    .unreq B(mu)
    .unreq B(mo)
    .unreq B(mi)
    .unreq B(ma)
    .unreq B(me)
    .unreq B(ba)
    .unreq B(bi)
    .unreq B(bo)
    .unreq B(bu)
    .unreq B(be)
    .unreq B(sa)
    .unreq B(so)
    .unreq B(se)
    .unreq B(si)
    .unreq B(su)

    .unreq Bq(go)
    .unreq Bq(gi)
    .unreq Bq(ga)
    .unreq Bq(ge)
    .unreq Bq(gu)
    .unreq Bq(ki)
    .unreq Bq(ko)
    .unreq Bq(ka)
    .unreq Bq(ke)
    .unreq Bq(ku)
    .unreq Bq(mu)
    .unreq Bq(mo)
    .unreq Bq(mi)
    .unreq Bq(ma)
    .unreq Bq(me)
    .unreq Bq(ba)
    .unreq Bq(bi)
    .unreq Bq(bo)
    .unreq Bq(bu)
    .unreq Bq(be)
    .unreq Bq(sa)
    .unreq Bq(so)
    .unreq Bq(se)
    .unreq Bq(si)
    .unreq Bq(su)

    .unreq OUT(ga)
    .unreq OUT(ge)
    .unreq OUT(gi)
    .unreq OUT(go)
    .unreq OUT(gu)
    .unreq OUT(ka)
    .unreq OUT(ke)
    .unreq OUT(ki)
    .unreq OUT(ko)
    .unreq OUT(ku)
    .unreq OUT(ma)
    .unreq OUT(me)
    .unreq OUT(mi)
    .unreq OUT(mo)
    .unreq OUT(mu)
    .unreq OUT(ba)
    .unreq OUT(be)
    .unreq OUT(bi)
    .unreq OUT(bo)
    .unreq OUT(bu)
    .unreq OUT(sa)
    .unreq OUT(se)
    .unreq OUT(si)
    .unreq OUT(so)
    .unreq OUT(su)

    .unreq OUTq(ga)
    .unreq OUTq(ge)
    .unreq OUTq(gi)
    .unreq OUTq(go)
    .unreq OUTq(gu)
    .unreq OUTq(ka)
    .unreq OUTq(ke)
    .unreq OUTq(ki)
    .unreq OUTq(ko)
    .unreq OUTq(ku)
    .unreq OUTq(ma)
    .unreq OUTq(me)
    .unreq OUTq(mi)
    .unreq OUTq(mo)
    .unreq OUTq(mu)
    .unreq OUTq(ba)
    .unreq OUTq(be)
    .unreq OUTq(bi)
    .unreq OUTq(bo)
    .unreq OUTq(bu)
    .unreq OUTq(sa)
    .unreq OUTq(se)
    .unreq OUTq(si)
    .unreq OUTq(so)
    .unreq OUTq(su)

    .unreq TMP_OUT(0)
    .unreq TMP_OUT(1)
    .unreq TMP_OUT(2)
    .unreq TMP_OUT(3)
    .unreq TMP_OUT(4)
    .unreq TMP_OUT(5)
    .unreq TMP_OUT(6)

    .unreq TMP_OUTq(0)
    .unreq TMP_OUTq(1)
    .unreq TMP_OUTq(2)
    .unreq TMP_OUTq(3)
    .unreq TMP_OUTq(4)
    .unreq TMP_OUTq(5)
    .unreq TMP_OUTq(6)

    .unreq tmp
.endm

.macro keccak_f1600_round_pre out, in

    eor3_m0 C(0), IN(ba), IN(ga), IN(ka)
    eor3_m1 C(3), IN(bo), IN(go), IN(ko)
    eor3_m0 C(2), IN(bi), IN(gi), IN(ki)
    eor3_m1 C(1), IN(be), IN(ge), IN(ke)
    eor3_m0 C(0), C(0),   IN(ma), IN(sa)
    eor3_m1 C(3), C(3),   IN(mo), IN(so)
    eor3_m0 C(2), C(2),   IN(mi), IN(si)
    eor3_m1 C(1), C(1),   IN(me), IN(se)
    eor3_m0 C(4), IN(bu), IN(gu), IN(ku)

.endm

.macro keccak_f1600_round_core out, in

    rax1_m0 E(1), C(0), C(2)
    xar_m1  B(mi), IN(ke), E(1), 54
    eor3_m0 C(4), C(4),   IN(mu), IN(su)
    xar_m1 B(go), IN(me), E(1), 19
    rax1_m0 E(3), C(2), C(4)
    xar_m1 B(ka), IN(be), E(1), 63
    rax1_m0 E(0), C(4), C(1)
    xar_m1 B(be), IN(ge), E(1), 20
    rax1_m0 E(2), C(1), C(3)
    xar_m1 B(su), IN(se), E(1), 62
    rax1_m0 E(4), C(3), C(0)

    // TODO: * Interleave (fast) v8.4-A based 5-block with (slow) v8-A based 5-block,
    //         and then pull forward BCAX for the v8.4-A block
    //       * Handle XAR's for a fixed E(?) first, so that the remaining E(?)'s
    //         can be computed in parallel?

    eor2   B(ba), IN(ba), E(0)
    xar_m1 B(ga), IN(bo), E(3), 36
    xar_m0 B(bi), IN(ki), E(2), 21
    xar_m1 B(ge), IN(gu), E(4), 44
    xar_m0 B(bo), IN(mo), E(3), 43
    xar_m1 B(gi), IN(ka), E(0), 61
    xar_m0 B(bu), IN(su), E(4), 50
    xar_m1 B(gu), IN(si), E(2), 3

    xar_m0 B(ke), IN(gi), E(2), 58
    xar_m0 B(ki), IN(ko), E(3), 39
    bcax_m1 OUT(ba), B(ba), B(bi), B(be)
    bcax_m1 OUT(be), B(be), B(bo), B(bi)
    xar_m0 B(ko), IN(mu), E(4), 56
    xar_m0 B(ku), IN(sa), E(0), 46
    bcax_m1 OUT(bi), B(bi), B(bu), B(bo)
    bcax_m1 OUT(bo), B(bo), B(ba), B(bu)

    xar_m0 B(ma), IN(bu), E(4), 37
    xar_m0 B(me), IN(ga), E(0), 28
    bcax_m1 OUT(bu), B(bu), B(be), B(ba)
    bcax_m1 OUT(ga), B(ga), B(gi), B(ge)
    xar_m0 B(mo), IN(mi), E(2), 49
    xar_m0 B(mu), IN(so), E(3), 8
    bcax_m1 OUT(ge), B(ge), B(go), B(gi)
    bcax_m1 OUT(gi), B(gi), B(gu), B(go)

    ld1r {tmp.2d}, [const_addr], #8
    eor OUT(ba).16b, OUT(ba).16b, tmp.16b

    xar_m0 B(sa), IN(bi), E(2), 2
    bcax_m1 OUT(go), B(go), B(ga), B(gu)
    xar_m0 B(se), IN(go), E(3), 9
    bcax_m1 OUT(gu), B(gu), B(ge), B(ga)
    bcax_m1 OUT(ka), B(ka), B(ki), B(ke)
    xar_m0 B(si), IN(ku), E(4), 25
    bcax_m1 OUT(ke), B(ke), B(ko), B(ki)
    bcax_m1 OUT(ki), B(ki), B(ku), B(ko)
    xar_m0 B(so), IN(ma), E(0), 23
    bcax_m1 OUT(ko), B(ko), B(ka), B(ku)
    bcax_m1 OUT(ku), B(ku), B(ke), B(ka)

    bcax_m0 OUT(ma), B(ma), B(mi), B(me)
    bcax_m1 OUT(me), B(me), B(mo), B(mi)
    bcax_m1 OUT(mi), B(mi), B(mu), B(mo)
    bcax_m0 OUT(mo), B(mo), B(ma), B(mu)
    bcax_m1 OUT(mu), B(mu), B(me), B(ma)

    bcax_m0 OUT(sa), B(sa), B(si), B(se)
    bcax_m1 OUT(se), B(se), B(so), B(si)
    bcax_m1 OUT(si), B(si), B(su), B(so)
    bcax_m0 OUT(so), B(so), B(sa), B(su)
    bcax_m1 OUT(su), B(su), B(se), B(sa)

    eor3_m0 Cnext(0), OUT(ba),  OUT(ga), OUT(ka)
    eor3_m1 Cnext(3), OUT(bo),  OUT(go), OUT(ko)
    eor3_m0 Cnext(2), OUT(bi),  OUT(gi), OUT(ki)
    eor3_m1 Cnext(1), OUT(be),  OUT(ge), OUT(ke)

    eor3_m0 Cnext(0), Cnext(0), OUT(ma), OUT(sa)
    eor3_m1 Cnext(3), Cnext(3), OUT(mo), OUT(so)
    eor3_m0 Cnext(2), Cnext(2), OUT(mi), OUT(si)
    eor3_m1 Cnext(1), Cnext(1), OUT(me), OUT(se)
    eor3_m0 Cnext(4), OUT(bu), OUT(gu), OUT(ku)

.endm

.macro keccak_f1600_round_last out, in

    rax1_m0 E(1), C(0), C(2)
    xar_m1  B(mi), IN(ke), E(1), 54
    eor3_m0 C(4), C(4),   IN(mu), IN(su)
    xar_m1 B(go), IN(me), E(1), 19
    rax1_m0 E(3), C(2), C(4)
    xar_m1 B(ka), IN(be), E(1), 63
    rax1_m0 E(0), C(4), C(1)
    xar_m1 B(be), IN(ge), E(1), 20
    rax1_m0 E(2), C(1), C(3)
    xar_m1 B(su), IN(se), E(1), 62
    rax1_m0 E(4), C(3), C(0)

    // TODO: * Interleave (fast) v8.4-A based 5-block with (slow) v8-A based 5-block,
    //         and then pull forward BCAX for the v8.4-A block
    //       * Handle XAR's for a fixed E(?) first, so that the remaining E(?)'s
    //         can be computed in parallel?

    eor2   B(ba), IN(ba), E(0)
    xar_m1 B(ga), IN(bo), E(3), 36
    xar_m0 B(bi), IN(ki), E(2), 21
    xar_m1 B(ge), IN(gu), E(4), 44
    xar_m0 B(bo), IN(mo), E(3), 43
    xar_m1 B(gi), IN(ka), E(0), 61
    xar_m0 B(bu), IN(su), E(4), 50
    xar_m1 B(gu), IN(si), E(2), 3

    xar_m0 B(ke), IN(gi), E(2), 58
    xar_m0 B(ki), IN(ko), E(3), 39
    bcax_m1 OUT(ba), B(ba), B(bi), B(be)
    bcax_m1 OUT(be), B(be), B(bo), B(bi)
    xar_m0 B(ko), IN(mu), E(4), 56
    xar_m0 B(ku), IN(sa), E(0), 46
    bcax_m1 OUT(bi), B(bi), B(bu), B(bo)
    bcax_m1 OUT(bo), B(bo), B(ba), B(bu)

    xar_m0 B(ma), IN(bu), E(4), 37
    xar_m0 B(me), IN(ga), E(0), 28
    bcax_m1 OUT(bu), B(bu), B(be), B(ba)
    bcax_m1 OUT(ga), B(ga), B(gi), B(ge)
    xar_m0 B(mo), IN(mi), E(2), 49
    xar_m0 B(mu), IN(so), E(3), 8
    bcax_m1 OUT(ge), B(ge), B(go), B(gi)
    bcax_m1 OUT(gi), B(gi), B(gu), B(go)

    ld1r {tmp.2d}, [const_addr], #8
    eor OUT(ba).16b, OUT(ba).16b, tmp.16b

    xar_m0 B(sa), IN(bi), E(2), 2
    bcax_m1 OUT(go), B(go), B(ga), B(gu)
    xar_m0 B(se), IN(go), E(3), 9
    bcax_m1 OUT(gu), B(gu), B(ge), B(ga)
    bcax_m1 OUT(ka), B(ka), B(ki), B(ke)
    xar_m0 B(si), IN(ku), E(4), 25
    bcax_m1 OUT(ke), B(ke), B(ko), B(ki)
    bcax_m1 OUT(ki), B(ki), B(ku), B(ko)
    xar_m0 B(so), IN(ma), E(0), 23
    bcax_m1 OUT(ko), B(ko), B(ka), B(ku)
    bcax_m1 OUT(ku), B(ku), B(ke), B(ka)

    bcax_m0 OUT(ma), B(ma), B(mi), B(me)
    bcax_m1 OUT(me), B(me), B(mo), B(mi)
    bcax_m1 OUT(mi), B(mi), B(mu), B(mo)
    bcax_m0 OUT(mo), B(mo), B(ma), B(mu)
    bcax_m1 OUT(mu), B(mu), B(me), B(ma)

    bcax_m0 OUT(sa), B(sa), B(si), B(se)
    bcax_m1 OUT(se), B(se), B(so), B(si)
    bcax_m1 OUT(si), B(si), B(su), B(so)
    bcax_m0 OUT(so), B(so), B(sa), B(su)
    bcax_m1 OUT(su), B(su), B(se), B(sa)
.endm

.macro transfer_state out, in

    savep(INq(ga),ga)
    savep(INq(ge),ge)
    savep(INq(gi),gi)
    savep(INq(go),go)
    savep(INq(gu),gu)
    savep(INq(ka),ka)
    savep(INq(ke),ke)
    savep(INq(ki),ki)
    savep(INq(ko),ko)
    savep(INq(ku),ku)
    savep(INq(ma),ma)
    savep(INq(me),me)
    savep(INq(mi),mi)
    savep(INq(mo),mo)
    savep(INq(mu),mu)
    savep(INq(ba),ba)
    savep(INq(be),be)
    savep(INq(bi),bi)
    savep(INq(bo),bo)
    savep(INq(bu),bu)
    savep(INq(sa),sa)
    savep(INq(se),se)
    savep(INq(si),si)
    savep(INq(so),so)
    savep(INq(su),su)

    restorep(OUTq(ga),ga)
    restorep(OUTq(ge),ge)
    restorep(OUTq(gi),gi)
    restorep(OUTq(go),go)
    restorep(OUTq(gu),gu)
    restorep(OUTq(ka),ka)
    restorep(OUTq(ke),ke)
    restorep(OUTq(ki),ki)
    restorep(OUTq(ko),ko)
    restorep(OUTq(ku),ku)
    restorep(OUTq(ma),ma)
    restorep(OUTq(me),me)
    restorep(OUTq(mi),mi)
    restorep(OUTq(mo),mo)
    restorep(OUTq(mu),mu)
    restorep(OUTq(ba),ba)
    restorep(OUTq(be),be)
    restorep(OUTq(bi),bi)
    restorep(OUTq(bo),bo)
    restorep(OUTq(bu),bu)
    restorep(OUTq(sa),sa)
    restorep(OUTq(se),se)
    restorep(OUTq(si),si)
    restorep(OUTq(so),so)
    restorep(OUTq(su),su)

.endm

.text
.align 4
.global keccak_f1600_x2_hybrid_asm_v2p2
.global _keccak_f1600_x2_hybrid_asm_v2p2

#define KECCAK_F1600_ROUNDS 24

keccak_f1600_x2_hybrid_asm_v2p2:
_keccak_f1600_x2_hybrid_asm_v2p2:
    alloc_stack
    save_vregs
    load_constant_ptr
    load_input

    /* NOTE: Unrolling the whole loop isn't really practical, but for now
     *       this is just for the sake of understanding the theoretical performance
     *       uplift of the present approach. */

    declare_mappings A1, A
    keccak_f1600_round_pre  A1, A
    keccak_f1600_round_core A1, A
    declare_mappings A2, A1
    keccak_f1600_round_core A2, A1
    declare_mappings A3, A2
    keccak_f1600_round_core A3, A2
    declare_mappings A4, A3
    keccak_f1600_round_core A4, A3
    declare_mappings A5, A4
    keccak_f1600_round_core A5, A4
    declare_mappings A6, A5
    keccak_f1600_round_core A6, A5
    declare_mappings A7, A6
    keccak_f1600_round_core A7, A6
    declare_mappings A8, A7
    keccak_f1600_round_core A8, A7

    declare_mappings A9, A8
    keccak_f1600_round_core A9, A8
    declare_mappings A10, A9
    keccak_f1600_round_core A10, A9
    declare_mappings A11, A10
    keccak_f1600_round_core A11, A10
    declare_mappings A12, A11
    keccak_f1600_round_core A12, A11
    declare_mappings A13, A12
    keccak_f1600_round_core A13, A12
    declare_mappings A14, A13
    keccak_f1600_round_core A14, A13
    declare_mappings A15, A14
    keccak_f1600_round_core A15, A14
    declare_mappings A16, A15
    keccak_f1600_round_core A16, A15

    declare_mappings A17, A16
    keccak_f1600_round_core A17, A16
    declare_mappings A18, A17
    keccak_f1600_round_core A18, A17
    declare_mappings A19, A18
    keccak_f1600_round_core A19, A18
    declare_mappings A20, A19
    keccak_f1600_round_core A20, A19
    declare_mappings A21, A20
    keccak_f1600_round_core A21, A20
    declare_mappings A22, A21
    keccak_f1600_round_core A22, A21
    declare_mappings A23, A22
    keccak_f1600_round_core A23, A22
    declare_mappings A24, A23
    keccak_f1600_round_last A24, A23

    store_input A24
    restore_vregs
    free_stack
    ret

#endif