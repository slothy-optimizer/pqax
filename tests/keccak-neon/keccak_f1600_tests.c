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

#include <hal.h>

#include "keccak_f1600_tests.h"
#include "keccak_f1600_variants.h"

#include "misc.h"

void bench_scalar(void*);
void bench_vector(void*);
void bench_hybrid(void*);

static int cmp_uint64_t(const void *a, const void *b)
{
    return (int)((*((const uint64_t *)a)) - (*((const uint64_t *)b)));
}


void zip_f1600_states_real( int num, uint64_t *dst, uint64_t const  *src )
{
    for( int i=0; i < KECCAK_F1600_X1_STATE_SIZE_UINT64; i++ )
        for( int j=0; j<num; j++ )
            dst[num*i+j] = src[j*KECCAK_F1600_X1_STATE_SIZE_UINT64+i];
}

void zip_f1600_states( int num, uint64_t *dst, uint64_t const  *src )
{
    if( num == 1 || num == 2 || num == 4 )
    {
        zip_f1600_states_real( num, dst, src );
    }
    else
    {
        zip_f1600_states_real( 2, dst, src );

        if( num > 2 )
        {
            dst += 2 * KECCAK_F1600_X1_STATE_SIZE_UINT64;
            src += 2 * KECCAK_F1600_X1_STATE_SIZE_UINT64;
            memcpy( dst, src, ( num - 2 ) * KECCAK_F1600_X1_STATE_SIZE_BYTES );
        }
    }
}

#define stringify(x) stringify_(x)
#define stringify_(x) #x

#define MAKE_VALIDATE_F1600_X_GENERIC_DO(testname,funcname,NUM)         \
int testname (void)                                                     \
{                                                                       \
    debug_test_start( stringify(testname) );                            \
                                                                        \
    ALIGN(64)                                                           \
    uint64_t state[NUM*KECCAK_F1600_X1_STATE_SIZE_UINT64] = { 0 };      \
    ALIGN(64)                                                           \
    uint64_t ref_state[NUM*KECCAK_F1600_X1_STATE_SIZE_UINT64] = { 0 };  \
    ALIGN(64)                                                           \
    uint64_t ref_state_[NUM*KECCAK_F1600_X1_STATE_SIZE_UINT64] = { 0 }; \
                                                                        \
    fill_random_u8( (uint8_t*) ref_state, KECCAK_F1600_X1_STATE_SIZE_BYTES ); \
    for( int i=1; i < NUM; i++ )                                        \
    memcpy( (uint8_t*) &ref_state[i*KECCAK_F1600_X1_STATE_SIZE_UINT64],   \
            (uint8_t*) &ref_state[0*KECCAK_F1600_X1_STATE_SIZE_UINT64], \
            KECCAK_F1600_X1_STATE_SIZE_BYTES );                         \
                                                                        \
    zip_f1600_states( NUM, state, ref_state );                          \
                                                                        \
    funcname( state );                                                  \
                                                                        \
    for( int i=0; i<NUM; i++ )                                          \
    {                                                                   \
        keccak_f1600_x1_scalar_C( ref_state +                           \
                               i * KECCAK_F1600_X1_STATE_SIZE_UINT64 ); \
    }                                                                   \
                                                                        \
    zip_f1600_states( NUM, ref_state_, ref_state );                     \
                                                                        \
    if( compare_buf_u8( (uint8_t*) state, (uint8_t*) ref_state_,        \
                        NUM * KECCAK_F1600_X1_STATE_SIZE_BYTES ) != 0 ) \
    {                                                                   \
        debug_print_buf_u8( (uint8_t*) ref_state_,                      \
                            NUM * KECCAK_F1600_X1_STATE_SIZE_BYTES,     \
                            "Reference" );                              \
        debug_print_buf_u8( (uint8_t*) state,                           \
                            NUM * KECCAK_F1600_X1_STATE_SIZE_BYTES,     \
                            "Actual" );                                 \
        debug_test_fail();                                              \
    }                                                                   \
                                                                        \
    debug_test_ok();                                                    \
    return 0;                                                           \
}

#define MAKE_VALIDATE_F1600_X_GENERIC_SKIP(testname,funcname,NUM)       \
int testname (void)                                                     \
{                                                                       \
    debug_test_start( stringify(testname) );                            \
    debug_printf( "skip\n" );                                           \
    return( 0 );                                                        \
}

#if defined(__ARM_FEATURE_SHA3)
#define MAKE_VALIDATE_F1600_X_GENERIC_V84A(testname,funcname,NUM)       \
    MAKE_VALIDATE_F1600_X_GENERIC_DO(testname,funcname,NUM)
#else
#define MAKE_VALIDATE_F1600_X_GENERIC_V84A(testname,funcname,NUM)       \
    MAKE_VALIDATE_F1600_X_GENERIC_SKIP(testname,funcname,NUM)
#endif

#if defined(__ARM_FEATURE_SVE2)
#define MAKE_VALIDATE_F1600_X_GENERIC_V9A(testname,funcname,NUM)       \
    MAKE_VALIDATE_F1600_X_GENERIC_DO(testname,funcname,NUM)
#else
#define MAKE_VALIDATE_F1600_X_GENERIC_V9A(testname,funcname,NUM)       \
    MAKE_VALIDATE_F1600_X_GENERIC_SKIP(testname,funcname,NUM)
#endif

#define MAKE_VALIDATE_F1600_X_GENERIC(testname,funcname,NUM)            \
    MAKE_VALIDATE_F1600_X_GENERIC_DO(testname,funcname,NUM)

#define MAKE_BENCHMARK_F1600_X_GENERIC_DO(testname,funcname,NUM) \
int testname (void)                                                     \
{                                                                       \
    ALIGN(64)                                                           \
    uint64_t state [NUM*KECCAK_F1600_X1_STATE_SIZE_UINT64] = { 0 };     \
                                                                        \
    fill_random_u8( (uint8_t*) state,                                   \
                    NUM*KECCAK_F1600_X1_STATE_SIZE_BYTES );             \
                                                                        \
    uint64_t cycles[TEST_ITERATIONS+1];                                 \
    uint64_t cycles_orig[TEST_ITERATIONS+1];                            \
                                                                        \
    for(unsigned cnt=0; cnt < TEST_WARMUP; cnt++)                       \
        funcname( state );                                              \
                                                                        \
    unsigned cnt;                                                       \
    for(cnt=0; cnt < TEST_ITERATIONS; cnt++)                          \
    {                                                                   \
        cycles[cnt] = get_cyclecounter();                               \
        for( unsigned cnt2=0; cnt2 < TEST_AVG_CNT; cnt2++ )             \
            funcname( state );                                          \
    }                                                                   \
    cycles[TEST_ITERATIONS] = get_cyclecounter();                       \
                                                                        \
    for( cnt=0; cnt < TEST_ITERATIONS; cnt++)                   \
        cycles[cnt] = (cycles[cnt+1] - cycles[cnt]) / TEST_AVG_CNT;                    \
                                                                        \
    /* Report median */                                                 \
    memcpy( cycles_orig, cycles, sizeof( cycles ) );                    \
    qsort( cycles, TEST_ITERATIONS, sizeof(uint64_t), cmp_uint64_t );   \
    debug_printf( "[0|5|25|50|75|95|100] = " \
                  "[(%4lld) | %4lld | %4lld |* %4lld *| %4lld | %4lld | (%4lld)] (%u-th AVGs of " stringify(funcname) ")\n", \
                  cycles[0],                                            \
                  cycles[TEST_ITERATIONS*5/100],                        \
                  cycles[TEST_ITERATIONS*25/100],                       \
                  cycles[TEST_ITERATIONS*50/100],                       \
                  cycles[TEST_ITERATIONS*75/100],                       \
                  cycles[TEST_ITERATIONS*95/100],                       \
                  cycles[TEST_ITERATIONS-1], TEST_AVG_CNT );            \
    return( 0 );                                                        \
}

#define MAKE_BENCHMARK_F1600_X_GENERIC_SKIP(testname,funcname,NUM)      \
int testname (void)                                                     \
{                                                                       \
    debug_test_start( stringify(testname) );                            \
    debug_printf( "skip\n" );                                           \
    return( 0 );                                                        \
}

#if defined(__ARM_FEATURE_SHA3)
#define MAKE_BENCHMARK_F1600_X_GENERIC_V84A(testname,funcname,NUM)       \
MAKE_BENCHMARK_F1600_X_GENERIC_DO(testname,funcname,NUM)
#else
#define MAKE_BENCHMARK_F1600_X_GENERIC_V84A(testname,funcname,NUM)       \
MAKE_BENCHMARK_F1600_X_GENERIC_SKIP(testname,funcname,NUM)
#endif

#if defined(__ARM_FEATURE_SVE2)
#define MAKE_BENCHMARK_F1600_X_GENERIC_V9A(testname,funcname,NUM)       \
MAKE_BENCHMARK_F1600_X_GENERIC_DO(testname,funcname,NUM)
#else
#define MAKE_BENCHMARK_F1600_X_GENERIC_V9A(testname,funcname,NUM)       \
MAKE_BENCHMARK_F1600_X_GENERIC_SKIP(testname,funcname,NUM)
#endif

#define MAKE_BENCHMARK_F1600_X_GENERIC(testname,funcname,NUM)      \
    MAKE_BENCHMARK_F1600_X_GENERIC_DO(testname,funcname,NUM)

#define KECCAK_F1600_X1_FUNCNAME(variant) keccak_f1600_x1_ ## variant
#define KECCAK_F1600_X1_TESTNAME(variant) validate_keccak_f1600_x1_ ## variant
#define MAKE_VALIDATE_F1600_X1(variant)                                    \
    MAKE_VALIDATE_F1600_X_GENERIC_DO(KECCAK_F1600_X1_TESTNAME(variant),    \
                                  KECCAK_F1600_X1_FUNCNAME(variant),1)
#define KECCAK_F1600_X1_BENCHMARK_TESTNAME(variant)              \
    benchmark_keccak_f1600_x1_ ## variant
#define MAKE_BENCHMARK_F1600_X1(variant)                         \
    MAKE_BENCHMARK_F1600_X_GENERIC_DO(                           \
        KECCAK_F1600_X1_BENCHMARK_TESTNAME(variant),             \
        KECCAK_F1600_X1_FUNCNAME(variant),1)

/////////////////////////////// TEST CASES ////////////////////////////////////

MAKE_VALIDATE_F1600_X1(scalar_asm_v1)
MAKE_VALIDATE_F1600_X1(scalar_asm_v2)
MAKE_VALIDATE_F1600_X1(scalar_asm_v3)
MAKE_VALIDATE_F1600_X1(scalar_asm_v4)
MAKE_VALIDATE_F1600_X1(scalar_asm_v5)
MAKE_VALIDATE_F1600_X1(scalar_C_v0)
MAKE_VALIDATE_F1600_X1(scalar_C_v1)

MAKE_BENCHMARK_F1600_X1(scalar_asm_v1)
MAKE_BENCHMARK_F1600_X1(scalar_asm_v2)
MAKE_BENCHMARK_F1600_X1(scalar_asm_v3)
MAKE_BENCHMARK_F1600_X1(scalar_asm_v4)
MAKE_BENCHMARK_F1600_X1(scalar_asm_v5)
MAKE_BENCHMARK_F1600_X1(scalar_C_v0)
MAKE_BENCHMARK_F1600_X1(scalar_C_v1)

MAKE_BENCHMARK_F1600_X1(scalar_C)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_scalar_C,
                              keccak_f1600_x2_scalar_C,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_neon_C_cothan,
                              keccak_f1600_x2_neon_C_cothan,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_bas,
                              keccak_f1600_x2_bas,2)

MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_v84a_asm_v1,
                              keccak_f1600_x2_v84a_asm_v1,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_v84a_asm_v1p0,
                              keccak_f1600_x2_v84a_asm_v1p0,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x4_v84a_asm_v1p0,
                              keccak_f1600_x4_v84a_asm_v1p0,4)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2,
                              keccak_f1600_x2_v84a_asm_v2,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2pp0,
                              keccak_f1600_x2_v84a_asm_v2pp0,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2pp1,
                              keccak_f1600_x2_v84a_asm_v2pp1,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2pp2,
                              keccak_f1600_x2_v84a_asm_v2pp2,2)
MAKE_VALIDATE_F1600_X_GENERIC_V9A(validate_keccak_f1600_x2_v84a_asm_v2pp3,
                              keccak_f1600_x2_v84a_asm_v2pp3,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2pp4,
                              keccak_f1600_x2_v84a_asm_v2pp4,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2pp5,
                              keccak_f1600_x2_v84a_asm_v2pp5,2)
MAKE_VALIDATE_F1600_X_GENERIC_V9A(validate_keccak_f1600_x2_v84a_asm_v2pp6,
                              keccak_f1600_x2_v84a_asm_v2pp6,2)
MAKE_VALIDATE_F1600_X_GENERIC_V9A(validate_keccak_f1600_x2_v84a_asm_v2pp7,
                              keccak_f1600_x2_v84a_asm_v2pp7,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2p0,
                              keccak_f1600_x2_v84a_asm_v2p0,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2p1,
                              keccak_f1600_x2_v84a_asm_v2p1,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2p2,
                              keccak_f1600_x2_v84a_asm_v2p2,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2p3,
                              keccak_f1600_x2_v84a_asm_v2p3,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2p4,
                              keccak_f1600_x2_v84a_asm_v2p4,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2p5,
                              keccak_f1600_x2_v84a_asm_v2p5,2)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x2_v84a_asm_v2p6,
                              keccak_f1600_x2_v84a_asm_v2p6,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_hybrid_asm_v1,
                              keccak_f1600_x2_hybrid_asm_v1,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_hybrid_asm_v2p0,
                              keccak_f1600_x2_hybrid_asm_v2p0,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_hybrid_asm_v2p1,
                              keccak_f1600_x2_hybrid_asm_v2p1,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_hybrid_asm_v2p2,
                              keccak_f1600_x2_hybrid_asm_v2p2,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_hybrid_asm_v2pp0,
                              keccak_f1600_x2_hybrid_asm_v2pp0,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_hybrid_asm_v2pp1,
                              keccak_f1600_x2_hybrid_asm_v2pp1,2)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x2_hybrid_asm_v2pp2,
                              keccak_f1600_x2_hybrid_asm_v2pp2,2)

MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x3_hybrid_asm_v3p,
                              keccak_f1600_x3_hybrid_asm_v3p,3)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x3_hybrid_asm_v6,
                              keccak_f1600_x3_hybrid_asm_v6,3)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x3_hybrid_asm_v7,
                              keccak_f1600_x3_hybrid_asm_v7,3)

MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x4_hybrid_asm_v1,
                              keccak_f1600_x4_hybrid_asm_v1,4)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x4_hybrid_asm_v2,
                              keccak_f1600_x4_hybrid_asm_v2,4)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x4_hybrid_asm_v2p0,
                              keccak_f1600_x4_hybrid_asm_v2p0,4)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x4_hybrid_asm_v3,
                              keccak_f1600_x4_hybrid_asm_v3,4)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x4_hybrid_asm_v3p,
                              keccak_f1600_x4_hybrid_asm_v3p,4)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x4_hybrid_asm_v3pp,
                              keccak_f1600_x4_hybrid_asm_v3pp,4)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x4_hybrid_asm_v4,
                              keccak_f1600_x4_hybrid_asm_v4,4)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x4_hybrid_asm_v4p,
                              keccak_f1600_x4_hybrid_asm_v4p,4)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x4_hybrid_asm_v5,
                              keccak_f1600_x4_hybrid_asm_v5,4)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x4_hybrid_asm_v5p,
                              keccak_f1600_x4_hybrid_asm_v5p,4)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x4_hybrid_asm_v6,
                              keccak_f1600_x4_hybrid_asm_v6,4)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x4_hybrid_asm_v7,
                              keccak_f1600_x4_hybrid_asm_v7,4)
MAKE_VALIDATE_F1600_X_GENERIC_V84A(validate_keccak_f1600_x4_hybrid_asm_v8,
                              keccak_f1600_x4_hybrid_asm_v8,4)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x4_scalar_asm_v5,
                              keccak_f1600_x4_scalar_asm_v5,4)


MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x5_hybrid_asm_v8,
                              keccak_f1600_x5_hybrid_asm_v8,5)
MAKE_VALIDATE_F1600_X_GENERIC(validate_keccak_f1600_x5_hybrid_asm_v8p,
                              keccak_f1600_x5_hybrid_asm_v8p,5)

MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_scalar_C,
                               keccak_f1600_x2_scalar_C,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_neon_C_cothan,
                              keccak_f1600_x2_neon_C_cothan,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_bas,
                                    keccak_f1600_x2_bas,2)

MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_v84a_asm_v1,
                              keccak_f1600_x2_v84a_asm_v1,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_v84a_asm_v1p0,
                              keccak_f1600_x2_v84a_asm_v1p0,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x4_v84a_asm_v1p0,
                              keccak_f1600_x4_v84a_asm_v1p0,4)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2,
                              keccak_f1600_x2_v84a_asm_v2,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2pp0,
                              keccak_f1600_x2_v84a_asm_v2pp0,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2pp1,
                              keccak_f1600_x2_v84a_asm_v2pp1,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2pp2,
                              keccak_f1600_x2_v84a_asm_v2pp2,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V9A(benchmark_keccak_f1600_x2_v84a_asm_v2pp3,
                              keccak_f1600_x2_v84a_asm_v2pp3,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2pp4,
                              keccak_f1600_x2_v84a_asm_v2pp4,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2pp5,
                              keccak_f1600_x2_v84a_asm_v2pp5,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V9A(benchmark_keccak_f1600_x2_v84a_asm_v2pp6,
                              keccak_f1600_x2_v84a_asm_v2pp6,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V9A(benchmark_keccak_f1600_x2_v84a_asm_v2pp7,
                              keccak_f1600_x2_v84a_asm_v2pp7,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2p0,
                              keccak_f1600_x2_v84a_asm_v2p0,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2p1,
                              keccak_f1600_x2_v84a_asm_v2p1,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2p2,
                              keccak_f1600_x2_v84a_asm_v2p2,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2p3,
                              keccak_f1600_x2_v84a_asm_v2p3,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2p4,
                              keccak_f1600_x2_v84a_asm_v2p4,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2p5,
                              keccak_f1600_x2_v84a_asm_v2p5,2)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x2_v84a_asm_v2p6,
                              keccak_f1600_x2_v84a_asm_v2p6,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_hybrid_asm_v1,
                              keccak_f1600_x2_hybrid_asm_v1,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_hybrid_asm_v2p0,
                              keccak_f1600_x2_hybrid_asm_v2p0,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_hybrid_asm_v2p1,
                              keccak_f1600_x2_hybrid_asm_v2p1,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_hybrid_asm_v2p2,
                              keccak_f1600_x2_hybrid_asm_v2p2,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_hybrid_asm_v2pp0,
                              keccak_f1600_x2_hybrid_asm_v2pp0,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_hybrid_asm_v2pp1,
                              keccak_f1600_x2_hybrid_asm_v2pp1,2)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x2_hybrid_asm_v2pp2,
                              keccak_f1600_x2_hybrid_asm_v2pp2,2)

MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x3_hybrid_asm_v3p,
                              keccak_f1600_x3_hybrid_asm_v3p,3)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x3_hybrid_asm_v6,
                              keccak_f1600_x3_hybrid_asm_v6,3)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x3_hybrid_asm_v7,
                              keccak_f1600_x3_hybrid_asm_v7,3)


MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x4_hybrid_asm_v1,
                              keccak_f1600_x4_hybrid_asm_v1,4)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x4_hybrid_asm_v2,
                              keccak_f1600_x4_hybrid_asm_v2,4)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x4_hybrid_asm_v2p0,
                              keccak_f1600_x4_hybrid_asm_v2p0,4)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x4_hybrid_asm_v3,
                              keccak_f1600_x4_hybrid_asm_v3,4)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x4_hybrid_asm_v3p,
                              keccak_f1600_x4_hybrid_asm_v3p,4)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x4_hybrid_asm_v3pp,
                              keccak_f1600_x4_hybrid_asm_v3pp,4)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x4_hybrid_asm_v4,
                              keccak_f1600_x4_hybrid_asm_v4,4)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x4_hybrid_asm_v4p,
                              keccak_f1600_x4_hybrid_asm_v4p,4)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x4_hybrid_asm_v5,
                              keccak_f1600_x4_hybrid_asm_v5,4)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x4_hybrid_asm_v5p,
                              keccak_f1600_x4_hybrid_asm_v5p,4)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x4_hybrid_asm_v6,
                              keccak_f1600_x4_hybrid_asm_v6,4)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x4_hybrid_asm_v7,
                              keccak_f1600_x4_hybrid_asm_v7,4)
MAKE_BENCHMARK_F1600_X_GENERIC_V84A(benchmark_keccak_f1600_x4_hybrid_asm_v8,
                              keccak_f1600_x4_hybrid_asm_v8,4)

MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x4_scalar_asm_v5,
                              keccak_f1600_x4_scalar_asm_v5,4)

MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x5_hybrid_asm_v8,
                              keccak_f1600_x5_hybrid_asm_v8,5)
MAKE_BENCHMARK_F1600_X_GENERIC(benchmark_keccak_f1600_x5_hybrid_asm_v8p,
                              keccak_f1600_x5_hybrid_asm_v8p,5)
