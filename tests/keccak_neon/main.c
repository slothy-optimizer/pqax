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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include "keccak_f1600_tests.h"
#include "hal.h"

int main(void)
{
    enable_cyclecounter();

#if defined(KECCAK_F1600_TEST_VALIDATE)
    if( validate_keccak_f1600_x1_scalar_C_v0() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x1_scalar_C_v1() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x1_scalar_asm_v1() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x1_scalar_asm_v2() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x1_scalar_asm_v3() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x1_scalar_asm_v4() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x1_scalar_asm_v5() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v1() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v1p0() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_v84a_asm_v1p0() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2p0() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2p1() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2p2() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2p3() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2p4() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2p5() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2p6() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2pp0() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2pp1() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2pp2() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2pp3() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2pp4() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2pp5() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2pp6() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_v84a_asm_v2pp7() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_scalar_C() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_neon_C_cothan() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_bas() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x3_hybrid_asm_v3p() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x3_hybrid_asm_v6() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x3_hybrid_asm_v7() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v1() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v2() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v3() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v3p() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v3pp() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v4() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v4p() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v5() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v5p() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v6() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v7() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_hybrid_asm_v8() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x4_scalar_asm_v5() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x5_hybrid_asm_v8() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_hybrid_asm_v1() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_hybrid_asm_v2p0() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_hybrid_asm_v2p1() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_hybrid_asm_v2p2() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_hybrid_asm_v2pp0() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_hybrid_asm_v2pp1() != 0 )
        return( 1 );
    if( validate_keccak_f1600_x2_hybrid_asm_v2pp2() != 0 )
        return( 1 );
#endif /* KECCAK_F1600_TEST_VALIDATE */

#if defined(KECCAK_F1600_TEST_BENCHMARK)
    benchmark_keccak_f1600_x1_scalar_C();
    benchmark_keccak_f1600_x1_scalar_C_v0();
    benchmark_keccak_f1600_x1_scalar_C_v1();

    benchmark_keccak_f1600_x1_scalar_asm_v1();
    benchmark_keccak_f1600_x1_scalar_asm_v2();
    benchmark_keccak_f1600_x1_scalar_asm_v3();
    benchmark_keccak_f1600_x1_scalar_asm_v4();
    benchmark_keccak_f1600_x1_scalar_asm_v5();

    benchmark_keccak_f1600_x2_scalar_C();
    benchmark_keccak_f1600_x2_v84a_asm_v2();
    benchmark_keccak_f1600_x2_v84a_asm_v1();
    benchmark_keccak_f1600_x2_v84a_asm_v1p0();
    benchmark_keccak_f1600_x4_v84a_asm_v1p0();
    benchmark_keccak_f1600_x2_v84a_asm_v2p0();
    benchmark_keccak_f1600_x2_v84a_asm_v2p1();
    benchmark_keccak_f1600_x2_v84a_asm_v2p2();
    benchmark_keccak_f1600_x2_v84a_asm_v2p3();
    benchmark_keccak_f1600_x2_v84a_asm_v2p4();
    benchmark_keccak_f1600_x2_v84a_asm_v2p5();
    benchmark_keccak_f1600_x2_v84a_asm_v2p6();
    benchmark_keccak_f1600_x2_v84a_asm_v2pp0();
    benchmark_keccak_f1600_x2_v84a_asm_v2pp1();
    benchmark_keccak_f1600_x2_v84a_asm_v2pp2();
    benchmark_keccak_f1600_x2_v84a_asm_v2pp3();
    benchmark_keccak_f1600_x2_v84a_asm_v2pp4();
    benchmark_keccak_f1600_x2_v84a_asm_v2pp5();
    benchmark_keccak_f1600_x2_v84a_asm_v2pp6();
    benchmark_keccak_f1600_x2_v84a_asm_v2pp7();
    benchmark_keccak_f1600_x2_neon_C_cothan();
    benchmark_keccak_f1600_x2_bas();

    benchmark_keccak_f1600_x2_hybrid_asm_v1();
    benchmark_keccak_f1600_x2_hybrid_asm_v2p0();
    benchmark_keccak_f1600_x2_hybrid_asm_v2p1();
    benchmark_keccak_f1600_x2_hybrid_asm_v2p2();
    benchmark_keccak_f1600_x2_hybrid_asm_v2pp0();
    benchmark_keccak_f1600_x2_hybrid_asm_v2pp1();
    benchmark_keccak_f1600_x2_hybrid_asm_v2pp2();

    benchmark_keccak_f1600_x3_hybrid_asm_v3p();
    benchmark_keccak_f1600_x3_hybrid_asm_v6();
    benchmark_keccak_f1600_x3_hybrid_asm_v7();

    benchmark_keccak_f1600_x4_hybrid_asm_v1();
    benchmark_keccak_f1600_x4_hybrid_asm_v2();
    benchmark_keccak_f1600_x4_hybrid_asm_v2p0();
    benchmark_keccak_f1600_x4_hybrid_asm_v3();
    benchmark_keccak_f1600_x4_hybrid_asm_v3p();
    benchmark_keccak_f1600_x4_hybrid_asm_v3pp();
    benchmark_keccak_f1600_x4_hybrid_asm_v4();
    benchmark_keccak_f1600_x4_hybrid_asm_v4p();
    benchmark_keccak_f1600_x4_hybrid_asm_v5();
    benchmark_keccak_f1600_x4_hybrid_asm_v5p();
    benchmark_keccak_f1600_x4_hybrid_asm_v6();
    benchmark_keccak_f1600_x4_hybrid_asm_v7();
    benchmark_keccak_f1600_x4_hybrid_asm_v8();

    benchmark_keccak_f1600_x4_scalar_asm_v5();

    benchmark_keccak_f1600_x5_hybrid_asm_v8();
    benchmark_keccak_f1600_x5_hybrid_asm_v8p();
#endif /* KECCAK_F1600_TEST_BENCHMARK */

    disable_cyclecounter();
    return( 0 );
}
