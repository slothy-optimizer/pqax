/*
 * Author: Hanno Becker <hannobecker@posteo.de>
 */

/*
 * Some external references to auto-generated assembly.
 */
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "profiling.h"
#include <hal.h>

MAKE_PROFILE(throughput_vldr_no_inc)
MAKE_PROFILE(throughput_vldr_inc)
MAKE_PROFILE(throughput_vldr_umull)
MAKE_PROFILE(throughput_vldr_lane_umull)
MAKE_PROFILE(throughput_ldr_umull)
MAKE_PROFILE(throughput_ins_str_mul)
MAKE_PROFILE(throughput_ins_str_umull)
MAKE_PROFILE(throughput_ldr_ins_umull)
MAKE_PROFILE(throughput_ldr_ins_mul)
MAKE_PROFILE(throughput_ins_umull)
MAKE_PROFILE(throughput_ins_mul)
MAKE_PROFILE(throughput_umov_mul)
MAKE_PROFILE(throughput_mov_mul)
MAKE_PROFILE(throughput_ldr_ins)
MAKE_PROFILE(throughput_ldr_ins_str)
MAKE_PROFILE(throughput_ldr_str)
MAKE_PROFILE(throughput_ldr_str_imm)
MAKE_PROFILE(throughput_ldr_str_inc)
MAKE_PROFILE(throughput_vldr2_umull)
MAKE_PROFILE(throughput_vldr_umull3)
MAKE_PROFILE(throughput_vldr_vstr)
MAKE_PROFILE(throughput_vldr_vstr_inc)
MAKE_PROFILE(throughput_vldr_vstr_inc_explicit)
MAKE_PROFILE(throughput_vldr_vstr_umull)
MAKE_PROFILE(throughput_vstr_ldr)
MAKE_PROFILE(throughput_vstr_var0)
MAKE_PROFILE(throughput_vstr_var1)
MAKE_PROFILE(throughput_vstr_var2)
MAKE_PROFILE(throughput_vstr_var3)
MAKE_PROFILE(throughput_vstr_var0p)
MAKE_PROFILE(throughput_vstr_var1p)
MAKE_PROFILE(throughput_vstr_var2p)
MAKE_PROFILE(throughput_vstr_var3p)
MAKE_PROFILE(throughput_vstr_var0pp)
MAKE_PROFILE(throughput_vstr_var1pp)
MAKE_PROFILE(throughput_vstr_var2pp)
MAKE_PROFILE(throughput_vstr_var3pp)
MAKE_PROFILE(throughput_vstr)
MAKE_PROFILE(throughput_vstr_padded)
MAKE_PROFILE(cyc_umaddl2_fwd)
MAKE_PROFILE(cyc_umaddl2)
MAKE_PROFILE(cyc_umaddl_vec2_fwd)
MAKE_PROFILE(cyc_umaddl_vec2)
MAKE_PROFILE(cyc_vec_umaddl2_vec)
MAKE_PROFILE(cyc_vec_umaddl2_add)
MAKE_PROFILE(cyc_umaddl_umlal2_fwd_add)
MAKE_PROFILE(cyc_umaddl_umlal2_add)


MAKE_PROFILE(latency_ldr_ins_with_dual_issue)
MAKE_PROFILE(latency_ldrx2_ins_with_dual_issue)
MAKE_PROFILE(latency_ldrx3_ins_with_dual_issue)
MAKE_PROFILE(latency_ldr_ins_mul)
MAKE_PROFILE(latency_ldr_ins_mul_with_imm)
MAKE_PROFILE(latency_ldr_ins_vmls_with_imm)
MAKE_PROFILE(latency_ldr_ins_vadd_with_imm)
MAKE_PROFILE(latency_ldr_ins)
MAKE_PROFILE(latency_vldr_umull)
MAKE_PROFILE(latency_vadd_vsub)
MAKE_PROFILE(latency_vadd_vmul)
MAKE_PROFILE(latency_s_vadd_vsub)
MAKE_PROFILE(latency_s_vadd_vmul)

MAKE_PROFILE(padding)

MAKE_PROFILE(throughput_vadd_vsub)

int main( void )
{
    debug_printf( "=========== uArch profiling ===============\n" );

    debug_printf( "- Enable cycle counter ..." );
    enable_cyclecounter();
    debug_printf( "ok\n" );

    profile_full();
    /* PROFILING */

    profile_throughput_vldr_no_inc();
    profile_throughput_vldr_inc();
    profile_throughput_vldr_umull();
    profile_throughput_vldr_lane_umull();
    profile_throughput_ldr_ins_umull();
    profile_throughput_ldr_ins_mul();
    profile_throughput_ins_umull();
    profile_throughput_ins_mul();
    profile_throughput_umov_mul();
    profile_throughput_mov_mul();
    profile_throughput_ldr_ins();
    profile_throughput_ldr_ins_str();
    profile_throughput_ldr_str();
    profile_throughput_ldr_str_imm();
    profile_throughput_ldr_str_inc();
    profile_throughput_ins_str_mul();
    profile_throughput_ins_str_umull();
    profile_throughput_ldr_umull();
    profile_throughput_vldr2_umull();
    profile_throughput_vldr_umull3();
    profile_throughput_vldr_vstr();
    profile_throughput_vldr_vstr_inc();
    profile_throughput_vldr_vstr_inc_explicit();
    profile_throughput_vldr_vstr_umull();
    profile_throughput_vstr_ldr();
    profile_throughput_vstr_var0();
    profile_throughput_vstr_var1();
    profile_throughput_vstr_var2();
    profile_throughput_vstr_var3();
    profile_throughput_vstr_var0p();
    profile_throughput_vstr_var1p();
    profile_throughput_vstr_var2p();
    profile_throughput_vstr_var3p();
    profile_throughput_vstr_var0pp();
    profile_throughput_vstr_var1pp();
    profile_throughput_vstr_var2pp();
    profile_throughput_vstr_var3pp();
    profile_throughput_vstr();
    profile_throughput_vstr_padded();
    profile_cyc_umaddl2_fwd();
    profile_cyc_umaddl2();
    profile_cyc_umaddl_vec2_fwd();
    profile_cyc_umaddl_vec2();
    profile_cyc_vec_umaddl2_vec();
    profile_cyc_vec_umaddl2_add();
    profile_cyc_umaddl_umlal2_fwd_add();
    profile_cyc_umaddl_umlal2_add();

    profile_latency_vadd_vsub();
    profile_latency_vadd_vmul();
    profile_latency_s_vadd_vsub();
    profile_latency_s_vadd_vmul();
    profile_latency_ldr_ins();
    profile_latency_ldr_ins_with_dual_issue();
    profile_latency_ldrx2_ins_with_dual_issue();
    profile_latency_ldrx3_ins_with_dual_issue();
    profile_latency_ldr_ins_mul();
    profile_latency_ldr_ins_mul_with_imm();
    profile_latency_ldr_ins_vmls_with_imm();
    profile_latency_ldr_ins_vadd_with_imm();
    profile_latency_vldr_umull();

    profile_padding();


    profile_throughput_vadd_vsub();
    debug_printf( "- Disable cycle counter ..." );
    disable_cyclecounter();
    debug_printf( "ok\n" );

    debug_printf( "\nDone!\n" );
    return(0);
}
