///
/// Copyright (c) 2023 Hanno Becker
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
#include "ubenchmarks.i"
#include "macros_misc.i"

.macro throughput_vldr_no_inc_core
        ldr q0, [x0]
.endm
make_ubench throughput_vldr_no_inc, nop, throughput_vldr_no_inc_core, nop

.macro throughput_vldr_inc_core
        ldr q0, [x0]
.endm
.macro throughput_vldr_inc_end_of_iteration
        sub x0, x0, #(25*8)
.endm
make_ubench throughput_vldr_inc, nop, throughput_vldr_inc_core, throughput_vldr_inc_end_of_iteration

.macro latency_vadd_vsub_core
        add v0.4s, v0.4s, v0.4s
        sub v1.4s, v0.4s, v0.4s
        sub v3.4s, v2.4s, v2.4s
        sub v3.4s, v2.4s, v2.4s
        sub v3.4s, v2.4s, v2.4s
        sub v3.4s, v2.4s, v2.4s
.endm
make_ubench latency_vadd_vsub, nop, latency_vadd_vsub_core, nop

.macro latency_vadd_vmul_core
        add v0.4s, v0.4s, v0.4s
        mul v1.4s, v0.4s, v0.4s
        sub v3.4s, v2.4s, v2.4s
        sub v3.4s, v2.4s, v2.4s
        sub v3.4s, v2.4s, v2.4s
        sub v3.4s, v2.4s, v2.4s
.endm
make_ubench latency_vadd_vmul, nop, latency_vadd_vmul_core, nop

.macro latency_s_vadd_vsub_core
        add v0.2s, v0.2s, v0.2s
        sub v1.2s, v0.2s, v0.2s
        sub v3.2s, v2.2s, v2.2s
        sub v3.2s, v2.2s, v2.2s
        sub v3.2s, v2.2s, v2.2s
        sub v3.2s, v2.2s, v2.2s
.endm
make_ubench latency_s_vadd_vsub, nop, latency_s_vadd_vsub_core, nop

.macro latency_s_vadd_vmul_core
        add v0.2s, v0.2s, v0.2s
        mul v1.2s, v0.2s, v0.2s
        sub v3.2s, v2.2s, v2.2s
        sub v3.2s, v2.2s, v2.2s
        sub v3.2s, v2.2s, v2.2s
        sub v3.2s, v2.2s, v2.2s
.endm
make_ubench latency_s_vadd_vmul, nop, latency_s_vadd_vmul_core, nop

.macro latency_vldr_umull_core
        ldr q0, [x0]
        umull v1.2d, v0.2s, v0.2s
.endm
make_ubench latency_vldr_umull, nop, latency_vldr_umull_core, nop

.macro latency_ldr_ins_core
        ldr x2, [x0]
        ins v0.d[0], x2
.endm
make_ubench latency_ldr_ins, nop, latency_ldr_ins_core, nop

.macro latency_ldr_ins_with_dual_issue_core
        umull v1.2d, v0.2s, v0.2s
        ldr x2, [x0]
        umull v1.2d, v0.2s, v0.2s
        ins v7.d[0], x2
.endm
make_ubench latency_ldr_ins_with_dual_issue, nop, latency_ldr_ins_with_dual_issue_core, nop

.macro latency_ldrx2_ins_with_dual_issue_core
        umull v1.2d, v0.2s, v0.2s
        ldr x2, [x0]
        umull v1.2d, v0.2s, v0.2s
        ldr x3, [x0]
        umull v1.2d, v0.2s, v0.2s
        ins v7.d[0], x2
.endm
make_ubench latency_ldrx2_ins_with_dual_issue, nop, latency_ldrx2_ins_with_dual_issue_core, nop

.macro latency_ldrx3_ins_with_dual_issue_core
        umull v1.2d, v0.2s, v0.2s
        ldr x2, [x0]
        umull v1.2d, v0.2s, v0.2s
        ldr x3, [x0]
        umull v1.2d, v0.2s, v0.2s
        ldr x4, [x0]
        umull v1.2d, v0.2s, v0.2s
        ins v7.d[0], x2
.endm
make_ubench latency_ldrx3_ins_with_dual_issue, nop, latency_ldrx3_ins_with_dual_issue_core, nop

.macro latency_ldr_ins_mul_core
        mul v1.4s, v0.4s, v0.4s
        ldr x2, [x0]
        mul v1.4s, v0.4s, v0.4s
        ldr x3, [x0]
        mul v1.4s, v0.4s, v0.4s
        ins v7.d[0], x2
        mul v1.4s, v0.4s, v0.4s
        ldr x3, [x0]
        mul v1.4s, v7.4s, v7.4s
        ins v7.d[0], x2
.endm
make_ubench latency_ldr_ins_mul, nop, latency_ldr_ins_mul_core, nop

.macro latency_ldr_ins_mul_with_imm_core
        mul v1.4s, v0.4s, v0.4s
        ldr x2, [x0, #8]
        mul v1.4s, v0.4s, v0.4s
        ldr x3, [x0, #16]
        mul v1.4s, v0.4s, v0.4s
        ins v7.d[0], x2
        mul v1.4s, v0.4s, v0.4s
        ldr x3, [x0, #24]
        mul v1.4s, v7.4s, v7.4s
        ins v7.d[0], x2
.endm
make_ubench latency_ldr_ins_mul_with_imm, nop, latency_ldr_ins_mul_with_imm_core, nop

.macro latency_ldr_ins_vmls_with_imm_core
        mls v1.4s, v0.4s, v0.4s
        ldr x2, [x0, #8]
        mls v1.4s, v0.4s, v0.4s
        ldr x3, [x0, #16]
        mls v1.4s, v0.4s, v0.4s
        ins v7.d[0], x2
        mls v1.4s, v0.4s, v0.4s
        ldr x3, [x0, #24]
        mls v1.4s, v7.4s, v7.4s
        ins v7.d[0], x2
.endm
make_ubench latency_ldr_ins_vmls_with_imm, nop, latency_ldr_ins_vmls_with_imm_core, nop

.macro latency_ldr_ins_vadd_with_imm_core
        add v1.4s, v0.4s, v0.4s
        ldr x2, [x0, #8]
        add v1.4s, v0.4s, v0.4s
        ldr x3, [x0, #16]
        add v1.4s, v0.4s, v0.4s
        ins v7.d[0], x2
        add v1.4s, v0.4s, v0.4s
        ldr x3, [x0, #24]
        add v1.4s, v7.4s, v7.4s
        ins v7.d[0], x2
.endm
make_ubench latency_ldr_ins_vadd_with_imm, nop, latency_ldr_ins_vadd_with_imm_core, nop

.macro throughput_vldr_umull_core
        ldr q0, [x0]
        umull v10.2d, v8.2s, v9.2s
.endm
make_ubench throughput_vldr_umull, nop, throughput_vldr_umull_core, nop

.macro throughput_ldr_umull_core
        ldr x2, [x0]
        umull v10.2d, v8.2s, v9.2s
.endm
make_ubench throughput_ldr_umull, nop, throughput_ldr_umull_core, nop

.macro throughput_vldr_lane_umull_core
        ld1 {v0.d}[0], [x0]
        umull v10.2d, v8.2s, v9.2s
.endm
make_ubench throughput_vldr_lane_umull, nop, throughput_vldr_lane_umull_core, nop

.macro throughput_ins_umull_core
        ins v0.d[0], x4
        umull v10.2d, v8.2s, v9.2s
.endm
make_ubench throughput_ins_umull, nop, throughput_ins_umull_core, nop

.macro throughput_ins_mul_core
        ins v0.d[0], x4
        mul v10.4s, v8.4s, v9.4s
        ins v0.d[1], x5
        mul v11.4s, v8.4s, v9.4s
        ins v1.d[0], x6
        mul v12.4s, v8.4s, v9.4s
        ins v1.d[1], x7
        mul v13.4s, v8.4s, v9.4s
.endm
make_ubench throughput_ins_mul, nop, throughput_ins_mul_core, nop

.macro throughput_ldr_ins_umull_core
        ldr x2, [x0]
        umull v10.2d, v8.2s, v9.2s
        ldr x3, [x0, #8]
        umull v10.2d, v8.2s, v9.2s
        ins v0.d[0], x4
        umull v10.2d, v8.2s, v9.2s
        ins v0.d[1], x5
        umull v10.2d, v8.2s, v9.2s
.endm
make_ubench throughput_ldr_ins_umull, nop, throughput_ldr_ins_umull_core, nop

.macro throughput_ldr_ins_mul_core
        ldr x2, [x0]
        mul v10.4s, v8.4s, v9.4s
        ldr x3, [x0, #8]
        mul v10.4s, v8.4s, v9.4s
        ins v0.d[0], x4
        mul v10.4s, v8.4s, v9.4s
        ins v0.d[1], x5
        mul v10.4s, v8.4s, v9.4s
.endm
make_ubench throughput_ldr_ins_mul, nop, throughput_ldr_ins_mul_core, nop

.macro throughput_ldr_ins_core
        ldr x2, [x0]
        ins v0.d[0], x4
.endm
make_ubench throughput_ldr_ins, nop, throughput_ldr_ins_core, nop

.macro throughput_ldr_ins_str_core
        ldr x2, [x0]
        ins v0.d[0], x4
        str x3, [x1]
.endm
make_ubench throughput_ldr_ins_str, nop, throughput_ldr_ins_str_core, nop

.macro throughput_ldr_str_core
        ldr x2, [x0]
        str x3, [x1]
.endm
make_ubench throughput_ldr_str, nop, throughput_ldr_str_core, nop

.macro throughput_ldr_str_imm_core
        ldr x2, [x0, #8]
        str x3, [x1, #8]
.endm
make_ubench throughput_ldr_str_imm, nop, throughput_ldr_str_imm_core, nop

.macro throughput_ldr_str_inc_core
        ldr x2, [x0], #8
        str x3, [x1], #8
.endm
.macro throughput_ldr_str_inc_end_of_iteration
        sub x0, x0, #(25*8)
        sub x1, x1, #(25*8)
.endm
make_ubench throughput_ldr_str_inc, nop, throughput_ldr_str_inc_core, throughput_ldr_str_inc_end_of_iteration

.macro throughput_umov_mul_core
        umov x4, v0.d[0]
        mul v10.4s, v8.4s, v9.4s
        umov x5, v0.d[1]
        mul v10.4s, v8.4s, v9.4s
        umov x6, v1.d[0]
        mul v10.4s, v8.4s, v9.4s
        umov x7, v1.d[1]
        mul v10.4s, v8.4s, v9.4s
.endm
make_ubench throughput_umov_mul, nop, throughput_umov_mul_core, nop

.macro throughput_mov_mul_core
        mov x4, v0.d[0]
        mul v10.4s, v8.4s, v9.4s
        mov x5, v0.d[1]
        mul v10.4s, v8.4s, v9.4s
        mov x6, v1.d[0]
        mul v10.4s, v8.4s, v9.4s
        mov x7, v1.d[1]
        mul v10.4s, v8.4s, v9.4s
.endm
make_ubench throughput_mov_mul, nop, throughput_mov_mul_core, nop

.macro throughput_ins_str_mul_core
        umov x4, v0.d[0]
        mul v10.4s, v8.4s, v9.4s
        umov x5, v0.d[1]
        mul v10.4s, v8.4s, v9.4s
        str x2, [x0]
        mul v10.4s, v8.4s, v9.4s
        str x3, [x0, #8]
        mul v10.4s, v8.4s, v9.4s
.endm
make_ubench throughput_ins_str_mul, nop, throughput_ins_str_mul_core, nop

.macro throughput_ins_str_umull_core
        umov x4, v0.d[0]
        umull v10.2d, v8.2s, v9.2s
        umov x5, v0.d[1]
        umull v10.2d, v8.2s, v9.2s
        str x2, [x0]
        umull v10.2d, v8.2s, v9.2s
        str x3, [x0, #8]
        umull v10.2d, v8.2s, v9.2s
.endm
make_ubench throughput_ins_str_umull, nop, throughput_ins_str_umull_core, nop

.macro throughput_vldr_vstr_inc_core
        ldr q0, [x0]
        str q1, [x1], #8
.endm
.macro throughput_vldr_vstr_inc_end_of_iteration
        sub x1, x1, #(25*8)
.endm
make_ubench throughput_vldr_vstr_inc, nop, throughput_vldr_vstr_inc_core,\
            throughput_vldr_vstr_inc_end_of_iteration

.macro throughput_vldr_vstr_umull_core
        ldr q0, [x0]
        str q1, [x1]
        umull v10.2d, v8.2s, v9.2s
.endm
make_ubench throughput_vldr_vstr_umull, nop, throughput_vldr_vstr_umull_core, nop

.macro throughput_vldr_vstr_inc_explicit_core
        ldr q0, [x0]
        str q1, [x1]
        add x1, x1, #8
.endm
.macro throughput_vldr_vstr_inc_explicit_end_of_iteration
        sub x1, x1, #(25*8)
.endm
make_ubench throughput_vldr_vstr_inc_explicit, nop, throughput_vldr_vstr_inc_explicit_core,\
            throughput_vldr_vstr_inc_explicit_end_of_iteration

.macro throughput_vldr_vstr_core
        ldr q0, [x0]
        str q1, [x1]
.endm
make_ubench throughput_vldr_vstr, nop, throughput_vldr_vstr_core, nop

.macro throughput_vldr2_umull_core
        ldr q0, [x0]
        ldr q1, [x0]
        umull v10.2d, v8.2s, v9.2s
.endm
make_ubench throughput_vldr2_umull, nop, throughput_vldr2_umull_core, nop

.macro throughput_vldr_umull3_core
        ldr q0, [x0]
        umull v1.2d, v8.2s, v9.2s
        umull v2.2d, v8.2s, v9.2s
        umull v3.2d, v8.2s, v9.2s
.endm
make_ubench throughput_vldr_umull3, nop, throughput_vldr_umull3_core, nop

.macro cyc_umaddl2_fwd
        umaddl x1, w8, w9, x3
        umaddl x4, w5, w6, x1
.endm
make_ubench cyc_umaddl2_fwd, nop, cyc_umaddl2_fwd, nop

.macro cyc_umaddl2
        umaddl x1, w8, w9, x3
        umaddl x4, w5, w6, x2
.endm
make_ubench cyc_umaddl2, nop, cyc_umaddl2, nop

.macro cyc_umaddl_vec2_fwd
        umlal  v2.2d, v3.2s, v4.2s
        umaddl x1, w8, w9, x3
        umlal  v6.2d, v7.2s, v8.2s
        umaddl x4, w5, w6, x1
.endm
make_ubench cyc_umaddl_vec2_fwd, nop, cyc_umaddl_vec2_fwd, nop

.macro cyc_umaddl_vec2
        umlal  v2.2d, v3.2s, v4.2s
        umaddl x1, w8, w9, x3
        umlal  v6.2d, v7.2s, v8.2s
        umaddl x4, w5, w6, x2
.endm
make_ubench cyc_umaddl_vec2, nop, cyc_umaddl_vec2, nop

.macro cyc_vec_umaddl2_vec
        umlal  v2.2d, v3.2s, v4.2s
        umaddl x1, w8, w9, x3
        umaddl x4, w5, w6, x1
        add v10.2s, v11.2s, v12.2s
.endm
make_ubench cyc_vec_umaddl2_vec, nop, cyc_vec_umaddl2_vec, nop

.macro cyc_vec_umaddl2_add
        umlal  v2.2d, v3.2s, v4.2s
        umaddl x1, w8, w9, x3
        umaddl x4, w5, w6, x1
        add x10, x11, x12
.endm
make_ubench cyc_vec_umaddl2_add, nop, cyc_vec_umaddl2_add, nop

.macro cyc_umaddl_umlal2_fwd_add
        umaddl x1, w8, w9, x3
        umlal  v2.2d, v3.2s, v4.2s
        umlal  v5.2d, v6.2s, v2.2s
        add x10, x11, x12
.endm
make_ubench cyc_umaddl_umlal2_fwd_add, nop, cyc_umaddl_umlal2_fwd_add, nop

.macro cyc_umaddl_umlal2_add
        umaddl x1, w8, w9, x3
        umlal  v7.2d, v3.2s, v4.2s
        umlal  v5.2d, v6.2s, v2.2s
        add x10, x11, x12
.endm
make_ubench cyc_umaddl_umlal2_add, nop, cyc_umaddl_umlal2_add, nop

make_ubench padding, nop, padding, nop
.macro throughput_vadd_vsub_core
/*14*/        vadd v16, v9, v11
              nop // gap
/*15*/        vsub v22, v9, v11
              nop // gap
              padding
.endm
make_ubench throughput_vadd_vsub, nop, throughput_vadd_vsub_core, nop

.macro throughput_vstr_ldr_core
        str_vo v12, x0, 240
        ldr x21, [x0, #456]
        str_vo v13, x0, 304
        ldr x20, [x0, #448]
        str_vo v15, x0, 432
        ldr x9, [x0, #384]
        str_vo v14, x0, 368
.endm
make_ubench throughput_vstr_ldr, nop, throughput_vstr_ldr_core, nop

.macro throughput_vstr_var0_core
        str_vo v10, x0, 0
        str_vo v11, x0, 32
        str_vo v12, x0, 64
        str_vo v13, x0, 96
        str_vo v14, x0, 128
.endm
make_ubench throughput_vstr_var0, nop, throughput_vstr_var0_core, nop

.macro throughput_vstr_var1_core
        str_vo v10, x0, 0
        str_vo v11, x0, 32
        str_vo v12, x0, 64
        str_vo v13, x0, 96
        str_vo v14, x0, 128
        str_vo v15, x0, 160
.endm
make_ubench throughput_vstr_var1, nop, throughput_vstr_var1_core, nop

.macro throughput_vstr_var2_core
        str_vo v10, x0, 0
        str_vo v11, x0, 32
        str_vo v12, x0, 64
        str_vo v13, x0, 96
        str_vo v14, x0, 128
        str_vo v15, x0, 160
        str_vo v16, x0, 192
.endm
make_ubench throughput_vstr_var2, nop, throughput_vstr_var2_core, nop

.macro throughput_vstr_var3_core
        str_vo v10, x0, 0
        str_vo v11, x0, 32
        str_vo v12, x0, 64
        str_vo v13, x0, 96
        str_vo v14, x0, 128
        str_vo v15, x0, 160
        str_vo v16, x0, 192
        str_vo v17, x0, 224
.endm
make_ubench throughput_vstr_var3, nop, throughput_vstr_var3_core, nop

.macro throughput_vstr_var0p_core
        str_vo v10, x0, 0
        str_vo v11, x0, 32
        str_vo v12, x0, 64
        str_vo v13, x0, 96
        str_vo v14, x0, 128
.endm
make_ubench throughput_vstr_var0p, nop, throughput_vstr_var0p_core, nop

.macro throughput_vstr_var1p_core
        str_vo v10, x0, 0/2
        str_vo v11, x0, 32/2
        str_vo v12, x0, 64/2
        str_vo v13, x0, 96/2
        str_vo v14, x0, 128/2
        str_vo v15, x0, 160/2
.endm
make_ubench throughput_vstr_var1p, nop, throughput_vstr_var1p_core, nop

.macro throughput_vstr_var2p_core
        str_vo v10, x0, 0/2
        str_vo v11, x0, 32/2
        str_vo v12, x0, 64/2
        str_vo v13, x0, 96/2
        str_vo v14, x0, 128/2
        str_vo v15, x0, 160/2
        str_vo v16, x0, 192/2
.endm
make_ubench throughput_vstr_var2p, nop, throughput_vstr_var2p_core, nop

.macro throughput_vstr_var3p_core
        str_vo v10, x0, 0/2
        str_vo v11, x0, 32/2
        str_vo v12, x0, 64/2
        str_vo v13, x0, 96/2
        str_vo v14, x0, 128/2
        str_vo v15, x0, 160/2
        str_vo v16, x0, 192/2
        str_vo v17, x0, 224/2
.endm
make_ubench throughput_vstr_var3p, nop, throughput_vstr_var3p_core, nop

.macro throughput_vstr_var0pp_core
        str_vo v10, x0, 0
        mul v20.4s, v21.4s, v22.4s
        str_vo v11, x0, 32
        mul v20.4s, v21.4s, v22.4s
        str_vo v12, x0, 64
        mul v20.4s, v21.4s, v22.4s
        str_vo v13, x0, 96
        mul v20.4s, v21.4s, v22.4s
        str_vo v14, x0, 128
        mul v20.4s, v21.4s, v22.4s
.endm
make_ubench throughput_vstr_var0pp, nop, throughput_vstr_var0pp_core, nop

.macro throughput_vstr_var1pp_core
        str_vo v10, x0, 0
        mul v20.4s, v21.4s, v22.4s
        str_vo v11, x0, 32
        mul v20.4s, v21.4s, v22.4s
        str_vo v12, x0, 64
        mul v20.4s, v21.4s, v22.4s
        str_vo v13, x0, 96
        mul v20.4s, v21.4s, v22.4s
        str_vo v14, x0, 128
        mul v20.4s, v21.4s, v22.4s
        str_vo v15, x0, 160
        mul v20.4s, v21.4s, v22.4s
.endm
make_ubench throughput_vstr_var1pp, nop, throughput_vstr_var1pp_core, nop

.macro throughput_vstr_var2pp_core
        str_vo v10, x0, 0
        mul v20.4s, v21.4s, v22.4s
        str_vo v11, x0, 32
        mul v20.4s, v21.4s, v22.4s
        str_vo v12, x0, 64
        mul v20.4s, v21.4s, v22.4s
        str_vo v13, x0, 96
        mul v20.4s, v21.4s, v22.4s
        str_vo v14, x0, 128
        mul v20.4s, v21.4s, v22.4s
        str_vo v15, x0, 160
        mul v20.4s, v21.4s, v22.4s
        str_vo v16, x0, 192
        mul v20.4s, v21.4s, v22.4s
.endm
make_ubench throughput_vstr_var2pp, nop, throughput_vstr_var2pp_core, nop

.macro throughput_vstr_var3pp_core
        str_vo v10, x0, 0
        mul v20.4s, v21.4s, v22.4s
        str_vo v11, x0, 32
        mul v20.4s, v21.4s, v22.4s
        str_vo v12, x0, 64
        mul v20.4s, v21.4s, v22.4s
        str_vo v13, x0, 96
        mul v20.4s, v21.4s, v22.4s
        str_vo v14, x0, 128
        mul v20.4s, v21.4s, v22.4s
        str_vo v15, x0, 160
        mul v20.4s, v21.4s, v22.4s
        str_vo v16, x0, 192
        mul v20.4s, v21.4s, v22.4s
        str_vo v17, x0, 224
        mul v20.4s, v21.4s, v22.4s
.endm
make_ubench throughput_vstr_var3pp, nop, throughput_vstr_var3pp_core, nop

.macro throughput_vstr_core
        str_vo v12, x0, 0
        str_vo v13, x0, 16
        str_vo v14, x0, 32
        str_vo v15, x0, 48
.endm
make_ubench throughput_vstr, nop, throughput_vstr_core, nop

.macro throughput_vstr_padded_core
        str_vo v12, x0, 0
        str_vo v13, x0, 16
        str_vo v14, x0, 32
        str_vo v15, x0, 48
        padding
.endm
make_ubench throughput_vstr_padded, nop, throughput_vstr_padded_core, nop
