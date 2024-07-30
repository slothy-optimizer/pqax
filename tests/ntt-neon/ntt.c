/*
 * Copyright (c) 2021 Arm Limited
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include <hal.h>

#include "ntt.h"
#include "misc.h"

//#define CONFIG_TEST_NTT_VERBOSE

const int32_t  mod_q32             = MODULUS_Q32;
const uint32_t mod_q32_inv_u32     = MODULUS_Q32_INV_U32;
const uint32_t mod_q32_inv_u32_neg = MODULUS_Q32_INV_U32_NEG;
const int32_t  mod_q32_root        = MODULUS_Q32_BASE_ROOT;

ALIGN(16) int32_t  root_base[2*NTT_SIZE]             = { 0 };
ALIGN(16) uint32_t root_base_twisted[2*NTT_SIZE]     = { 0 };
ALIGN(16) int32_t  inv_root_base[2*NTT_SIZE]         = { 0 };
ALIGN(16) uint32_t inv_root_base_twisted[2*NTT_SIZE] = { 0 };

int32_t  roots        [NTT_SIZE] = { 0 };
uint32_t roots_twisted[NTT_SIZE] = { 0 };

void mul_q_u32( int32_t *src, int64_t c, size_t size )
{
    for( unsigned idx = 0; idx < size; idx++ )
    {
        int64_t tmp;
        src[idx] = src[idx] % mod_q32;
        if( src[idx] < 0 )
            src[idx] += mod_q32;
        tmp = (int64_t) src[idx] * c;
        src[idx] = tmp % mod_q32;
        if( src[idx] < 0 )
            src[idx] += mod_q32;
    }
}

void reduce_q_u32( int32_t *src, size_t size )
{
    for( unsigned idx = 0; idx < size; idx++ )
    {
        src[idx] = src[idx] % mod_q32;
        if( src[idx] < 0 )
            src[idx] += mod_q32;
    }
}

void mult_u32_C( int32_t const *src_a,
                 int32_t const *src_b,
                 int32_t *dst,
                 size_t size )
{
    unsigned idx;
    for( idx = 0; idx < size; idx++ )
    {
        int64_t tmp = (int64_t) src_a[idx] * (int64_t) src_b[idx];
        dst[idx] = (int32_t)( tmp % mod_q32 );
    }
}


void montgomery_pt_u32_C( int32_t const *src_a,
                          int32_t const *src_b,
                          int32_t *dst,
                          size_t size )
{
    unsigned idx;
    for( idx = 0; idx < size; idx++ )
    {
        int64_t v;
        int32_t hi;
        uint32_t lo, tmp, hi_fix;

        v = 2* (int64_t) src_a[idx] * (int64_t) src_b[idx];

        /* Hi+lo part extraction */
        hi     =  (int32_t)( v >> 32 );
        lo     = (uint32_t)( v >>  0 );

        /* Fixed scalar multiply, lo */
        tmp    = lo * mod_q32_inv_u32;
        /* Fixed scalar multiply, hi */
        hi_fix = ( (uint64_t) tmp * (uint64_t) mod_q32 ) >> 32;

        dst[idx] = (int32_t)( (int64_t) hi - (int64_t) hi_fix );
    }
}

void buf_reduce_u32( int32_t *src, size_t size )
{
    for( unsigned i=0; i < size; i++ )
    {
        src[i] = src[i] % mod_q32;
        if( src[i] < 0 )
            src[i] += mod_q32;
    }
}


int32_t mod_mul( int32_t a, int32_t b, int32_t mod )
{
    int64_t tmp = (int64_t) a * (int64_t) b;
    int32_t res = tmp % mod;
    return( res);
}

int32_t mod_add( int32_t a, int32_t b, int32_t mod )
{
    int64_t tmp = (int64_t) a + (int64_t) b;
    int32_t res = tmp % mod;
    return( res);
}

int32_t mod_sub( int32_t a, int32_t b, int32_t mod )
{
    int64_t tmp = (int64_t) a - (int64_t) b;
    int32_t res = tmp % mod;
    return( res);
}

int32_t mod_pow( int32_t base, unsigned exp, int32_t mod )
{
    int32_t base_pow = base;
    int32_t tmp = 1;
    while( exp != 0 )
    {
        if( exp & 1 )
            tmp = mod_mul( tmp, base_pow, mod );

        base_pow = mod_mul( base_pow, base_pow, mod );
        exp >>= 1;
    }

    return( tmp );
}

int bit_reverse( unsigned val, int width )
{
	unsigned result = 0;
	while( width-- )
	{
		result = ( result << 1 ) + ( val & 1 );
		val >>= 1;
	}
	return( result );
}

void build_roots()
{
    for( unsigned i=0; i < NTT_SIZE; i++ )
    {
        roots[i]         = mod_pow( mod_q32_root, i, mod_q32 );
        roots_twisted[i] = roots[i] * mod_q32_inv_u32;

#if defined(CONFIG_TEST_NTT_VERBOSE)
        debug_printf( "zeta^%u = %u^%u = %u\n",
                      i, (unsigned) mod_q32_root, i,
                      roots[i] );

        debug_printf( "zeta^%u * %u = %u^%u * %u = %u\n",
                      i, mod_q32_inv_u32,
                      (unsigned) mod_q32_root, i, mod_q32_inv_u32,
                      roots_twisted[i] );
#endif /* CONFIG_TEST_NTT_VERBOSE */
    }
}

void ntt_u32_C( int32_t *src )
{
    int32_t res[NTT_SIZE];
    build_roots();

    for( unsigned t=0; t<NTT_LAYER_STRIDE; t++ )
    {
        for( unsigned i=0; i<NTT_INCOMPLETE_SIZE; i++ )
        {
            int32_t tmp = 0;
            /* A negacyclic FFT is half of a full FFT, where we've 'chosen -1'
             * in the first layer. That explains the corrections by NTT_INCOMPLETE_SIZE
             * and +1 here. In a normal FFT, this would just be bit_rev( i, layers ) * stride. */
            unsigned const multiplier =
                bit_reverse( i + NTT_INCOMPLETE_SIZE, NTT_INCOMPLETE_LAYERS + 1 ) * NTT_LAYER_STRIDE;

            for( unsigned j=0; j<NTT_INCOMPLETE_SIZE; j++ )
            {
                int32_t cur;
                unsigned exp = ( multiplier * j ) % ( 2 * NTT_SIZE );
                unsigned sub = ( exp >= NTT_SIZE );
                exp = exp % NTT_SIZE;

#if defined(CONFIG_TEST_NTT_VERBOSE)
                if( t == 0 )
                {
                    debug_printf( "res[%u] += root[%u] * src[%u] = %u * %u\n",
                                  NTT_LAYER_STRIDE*i+t,
                                  exp,
                                  NTT_LAYER_STRIDE*j+t,
                                  roots[exp],
                                  src[NTT_LAYER_STRIDE*j+t]);
                }
#endif /* CONFIG_TEST_NTT_VERBOSE */

                cur = mod_mul( src[NTT_LAYER_STRIDE*j+t],
                               roots[exp],
                               mod_q32 );

                if( !sub )
                    tmp = mod_add( tmp, cur, mod_q32 );
                else
                    tmp = mod_sub( tmp, cur, mod_q32 );
            }
            res[NTT_LAYER_STRIDE*i+t] = tmp;
        }
    }

    memcpy( src, res, sizeof( res ) );
}

uint64_t t0, t1;
uint64_t cycles[NTT_TEST_COUNT];

static int cmp_uint64_t(const void *a, const void *b)
{
    return (int)((*((const uint64_t *)a)) - (*((const uint64_t *)b)));
}

#define NTT_U32_NEON_INCOMPLETE(variant) ntt_u32_incomplete_neon_asm_var_ ## variant
#define NTT_U32_NEON_FULL(variant) ntt_u32_full_neon_asm_var_ ## variant

#if defined(NTT_CHECK_FUNCTIONAL_CORRECTNESS)

void buf_bitrev_4( int32_t *src, size_t size )
{
    for( unsigned i=0; i < size; i += 16 )
    {
        int32_t tmp[16];
        for( unsigned t=0; t < 16; t++ )
            tmp[t] = src[i+t];

        for( unsigned r0=0; t0 < 4; r0++ )
            for( unsigned r1=0; t1 < 4; r1++ )
                src[i+r0*4 + r1] = tmp[r1*4+r0];
    }
}

#define GEN_TEST_NTT_INCOMPLETE(variant)                                \
int test_fwd_ntt_incomplete_var_ ## variant ()                           \
{                                                                       \
    debug_test_start( "NTT: deg 256, 32-bit, forward, 6-layer incomplete" ); \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t src[NTT_SIZE];                                              \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t src_copy[NTT_SIZE];                                         \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t dummy_copy[NTT_SIZE];                                       \
                                                                        \
    rand_init(0);                                                       \
                                                                        \
    /* Setup input */                                                   \
    fill_random_u32( (uint32_t*) src, NTT_SIZE );                       \
    buf_reduce_u32( src, NTT_SIZE );                                    \
                                                                        \
    /* Step 1: Reference NTT */                                         \
    memcpy( src_copy, src, sizeof( src ) );                             \
    ntt_u32_C( src_copy );                                              \
    buf_reduce_u32( src_copy, NTT_SIZE );                               \
                                                                        \
    /* Step 2: NEON-based NTT */                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_U32_NEON_INCOMPLETE(variant)( dummy_copy );                 \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_U32_NEON_INCOMPLETE(variant)( dummy_copy );                 \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    NTT_U32_NEON_INCOMPLETE(variant)( src );                            \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(uint64_t), cmp_uint64_t );    \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                       \
                  cycles[NTT_TEST_COUNT >> 1] );                        \
                                                                        \
    buf_reduce_u32( src, NTT_SIZE );                                    \
                                                                        \
    if( compare_buf_u32( (uint32_t const*) src, (uint32_t const*) src_copy, \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
        debug_print_buf_s32( src_copy, NTT_SIZE, "Reference" );         \
        debug_print_buf_s32( src, NTT_SIZE, "MVE" );                    \
        debug_test_fail();                                              \
        return( 1 );                                                    \
    }                                                                   \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}

#define GEN_TEST_NTT_FULL(variant)                                      \
int test_fwd_ntt_full_var_ ## variant ()                                 \
{                                                                       \
    debug_test_start( "NTT: deg 256, 32-bit, forward, full" );          \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t src[NTT_SIZE];                                              \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t src_copy[NTT_SIZE];                                         \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t dummy_copy[NTT_SIZE];                                       \
                                                                        \
    rand_init(0);                                                       \
                                                                        \
    /* Setup input */                                                   \
    fill_random_u32( (uint32_t*) src, NTT_SIZE );                       \
    buf_reduce_u32( src, NTT_SIZE );                                    \
                                                                        \
    /* Step 1: Reference NTT */                                         \
    memcpy( src_copy, src, sizeof( src ) );                             \
    ntt_u32_C( src_copy );                                              \
    buf_reduce_u32( src_copy, NTT_SIZE );                               \
                                                                        \
    /* Step 2: NEON-based NTT */                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_U32_NEON_FULL(variant)( dummy_copy );                       \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_U32_NEON_FULL(variant)( dummy_copy );                       \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    NTT_U32_NEON_FULL(variant)( src );                                  \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(uint64_t), cmp_uint64_t );   \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                      \
                  cycles[NTT_TEST_COUNT >> 1] );                       \
                                                                        \
    if( NTT_COMPLETE_BITREV4 )                                          \
        buf_bitrev_4( src, NTT_SIZE );                                  \
                                                                        \
    buf_reduce_u32( src, NTT_SIZE );                                    \
                                                                        \
    if( compare_buf_u32( (uint32_t const*) src, (uint32_t const*) src_copy, \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
        debug_print_buf_s32( src_copy, NTT_SIZE, "Reference" );         \
        debug_print_buf_s32( src, NTT_SIZE, "MVE" );                    \
        debug_test_fail();                                              \
        return( 1 );                                                    \
    }                                                                   \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}


#else /* NTT_CHECK_FUNCTIONAL_CORRECTNESS */

#define GEN_TEST_NTT_INCOMPLETE(variant)                                \
int test_fwd_ntt_incomplete_var_ ## variant ()                           \
{                                                                       \
    debug_test_start( "NTT: deg 256, 32-bit, forward, 6-layer incomplete" ); \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t src[NTT_SIZE];                                              \
                                                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_U32_NEON_INCOMPLETE(variant)( src );                        \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_U32_NEON_INCOMPLETE(variant)( src );                        \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(uint64_t), cmp_uint64_t );    \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                       \
                  cycles[NTT_TEST_COUNT >> 1] );                        \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}

#define GEN_TEST_NTT_FULL(variant)                                      \
int test_fwd_ntt_full_var_ ## variant ()                                 \
{                                                                       \
    debug_test_start( "NTT: deg 256, 32-bit, forward, full" );          \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t src[NTT_SIZE];                                              \
                                                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_U32_NEON_FULL(variant)( src );                              \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_U32_NEON_FULL(variant)( src );                              \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(uint64_t), cmp_uint64_t );    \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                       \
                  cycles[NTT_TEST_COUNT >> 1] );                        \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}

#endif /* NTT_CHECK_FUNCTIONAL_CORRECTNESS */

GEN_TEST_NTT_INCOMPLETE(3_3_0)
GEN_TEST_NTT_INCOMPLETE(3_3_1)
GEN_TEST_NTT_INCOMPLETE(3_3_2)
GEN_TEST_NTT_INCOMPLETE(3_3_3)
GEN_TEST_NTT_INCOMPLETE(3_3_4)
GEN_TEST_NTT_INCOMPLETE(3_3_5)

GEN_TEST_NTT_INCOMPLETE(4_2_0_0)

GEN_TEST_NTT_INCOMPLETE(4_2_0_z4_0)
GEN_TEST_NTT_INCOMPLETE(4_2_0_z4_16)
GEN_TEST_NTT_INCOMPLETE(4_2_24_z4_0)
GEN_TEST_NTT_INCOMPLETE(4_2_24_z4_16)

GEN_TEST_NTT_INCOMPLETE(4_2_3_z4_0)
GEN_TEST_NTT_INCOMPLETE(4_2_3_z4_1)
GEN_TEST_NTT_INCOMPLETE(4_2_3_z4_2)
GEN_TEST_NTT_INCOMPLETE(4_2_3_z4_3)
GEN_TEST_NTT_INCOMPLETE(4_2_3_z4_4)
GEN_TEST_NTT_INCOMPLETE(4_2_3_z4_5)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_0)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_1)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_2)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_3)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_4)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_5)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_6)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_8)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_9)
GEN_TEST_NTT_INCOMPLETE(4_2_7_z4_10)

GEN_TEST_NTT_INCOMPLETE(4_2_8_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_9_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_10_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_11_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_12_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_13_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_14_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_15_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_16_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_17_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_18_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_19_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_20_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_21_z4_7)
GEN_TEST_NTT_INCOMPLETE(4_2_22_z4_7)

GEN_TEST_NTT_INCOMPLETE(4_2_22_z4_8)
GEN_TEST_NTT_INCOMPLETE(4_2_22_z4_9)
GEN_TEST_NTT_INCOMPLETE(4_2_22_z4_10)
GEN_TEST_NTT_INCOMPLETE(4_2_22_z4_11)
GEN_TEST_NTT_INCOMPLETE(4_2_22_z4_12)
GEN_TEST_NTT_INCOMPLETE(4_2_22_z4_13)
GEN_TEST_NTT_INCOMPLETE(4_2_22_z4_14)
GEN_TEST_NTT_INCOMPLETE(4_2_22_z4_15)

GEN_TEST_NTT_FULL(4_4_0_0)
GEN_TEST_NTT_FULL(4_4_1_0)
GEN_TEST_NTT_FULL(4_4_2_0)
GEN_TEST_NTT_FULL(4_4_3_0)
GEN_TEST_NTT_FULL(4_4_4_0)
GEN_TEST_NTT_FULL(4_4_5_0)
GEN_TEST_NTT_FULL(4_4_6_0)
GEN_TEST_NTT_FULL(4_4_7_0)
GEN_TEST_NTT_FULL(4_4_8_0)
GEN_TEST_NTT_FULL(4_4_9_0)
GEN_TEST_NTT_FULL(4_4_10_0)
GEN_TEST_NTT_FULL(4_4_11_0)
GEN_TEST_NTT_FULL(4_4_12_0)
GEN_TEST_NTT_FULL(4_4_13_0)
GEN_TEST_NTT_FULL(4_4_14_0)
GEN_TEST_NTT_FULL(4_4_15_0)
GEN_TEST_NTT_FULL(4_4_16_0)
GEN_TEST_NTT_FULL(4_4_17_0)
GEN_TEST_NTT_FULL(4_4_18_0)
GEN_TEST_NTT_FULL(4_4_3_z2_0)
GEN_TEST_NTT_FULL(4_4_3_z2_1)
GEN_TEST_NTT_FULL(4_4_3_z2_2)
GEN_TEST_NTT_FULL(4_4_3_z2_3)
GEN_TEST_NTT_FULL(4_4_3_z2_4)
GEN_TEST_NTT_FULL(4_4_3_z2_5)
GEN_TEST_NTT_FULL(4_4_3_z4_0)
GEN_TEST_NTT_FULL(4_4_3_z4_1)
GEN_TEST_NTT_FULL(4_4_3_z4_2)
GEN_TEST_NTT_FULL(4_4_3_z4_3)
GEN_TEST_NTT_FULL(4_4_3_z4_4)

#define NTT_U32_NEON_DUAL_INCOMPLETE(variant) ntt_u32_incomplete_neon_asm_dual_var_ ## variant

#if defined(NTT_CHECK_FUNCTIONAL_CORRECTNESS)

#define GEN_TEST_NTT_INCOMPLETE_DUAL(variant)   \
int test_fwd_ntt_incomplete_dual_var_ ## variant()                       \
{                                                                       \
    debug_test_start( "NTT dual: deg 256, 32-bit, forward, 6-layer incomplete" ); \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    int32_t src0[NTT_SIZE];                                             \
    int32_t src0_copy[NTT_SIZE];                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t dummy0_copy[NTT_SIZE];                                      \
                                                                        \
    int32_t src1[NTT_SIZE];                                             \
    int32_t src1_copy[NTT_SIZE];                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t dummy1_copy_[NTT_SIZE];                                     \
    int32_t * dummy1_copy = dummy1_copy_ + NTT_DUAL_BUFFER_OFFSET;      \
                                                                        \
    rand_init(0);                                                       \
                                                                        \
    /* Setup input */                                                   \
    fill_random_u32( (uint32_t*) src1, NTT_SIZE );                      \
    buf_reduce_u32( src1, NTT_SIZE );                                   \
    fill_random_u32( (uint32_t*) src0, NTT_SIZE );                      \
    buf_reduce_u32( src0, NTT_SIZE );                                   \
                                                                        \
    /* Step 1: Reference NTT */                                         \
    memcpy( src0_copy, src0, sizeof( src0 ) );                          \
    memcpy( src1_copy, src1, sizeof( src1 ) );                          \
    ntt_u32_C( src0_copy );                                             \
    ntt_u32_C( src1_copy );                                             \
    buf_reduce_u32( src0_copy, NTT_SIZE );                              \
    buf_reduce_u32( src1_copy, NTT_SIZE );                              \
                                                                        \
    /* Step 2: NEON-based NTT */                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_U32_NEON_DUAL_INCOMPLETE(variant)( dummy0_copy, dummy1_copy ); \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_U32_NEON_DUAL_INCOMPLETE(variant)( dummy0_copy, dummy1_copy ); \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    NTT_U32_NEON_DUAL_INCOMPLETE(variant)( src0, src1 );                \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(uint64_t), cmp_uint64_t );   \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                      \
                  cycles[NTT_TEST_COUNT >> 1] );                       \
                                                                        \
    buf_reduce_u32( src0, NTT_SIZE );                                   \
    buf_reduce_u32( src1, NTT_SIZE );                                   \
                                                                        \
    if( compare_buf_u32( (uint32_t const*) src0, (uint32_t const*) src0_copy, \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
       for( unsigned idx=0; idx < NTT_SIZE; idx++ )                     \
           if( src0[idx] != src0_copy[idx] )                            \
               debug_printf( "SRC0[%u]: %d != %d\n",                    \
                             idx, src0[idx], src0_copy[idx] );          \
        debug_test_fail();                                              \
    }                                                                   \
                                                                        \
    if( compare_buf_u32( (uint32_t const*) src1, (uint32_t const*) src1_copy, \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
       for( unsigned idx=0; idx < NTT_SIZE; idx++ )                     \
           if( src1[idx] != src1_copy[idx] )                            \
               debug_printf( "SRC1[%u]: %d != %d\n",                    \
                             idx, src1[idx], src1_copy[idx] );          \
        debug_test_fail();                                              \
        return( 1 );                                                    \
    }                                                                   \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}

#else /* NTT_CHECK_FUNCTIONAL_CORRECTNESS */

#define GEN_TEST_NTT_INCOMPLETE_DUAL(variant)                           \
int test_fwd_ntt_incomplete_dual_var_ ## variant()                       \
{                                                                       \
    debug_test_start( "NTT dual: deg 256, 32-bit, forward, 6-layer incomplete" ); \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t dummy0_copy[NTT_SIZE];                                      \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    int32_t dummy1_copy_[NTT_SIZE];                                     \
    int32_t * dummy1_copy = dummy1_copy_ + NTT_DUAL_BUFFER_OFFSET;      \
                                                                        \
    /* NEON-based NTT */                                                \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_U32_NEON_DUAL_INCOMPLETE(variant)( dummy0_copy, dummy1_copy ); \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                 \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_U32_NEON_DUAL_INCOMPLETE(variant)( dummy0_copy, dummy1_copy ); \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(uint64_t), cmp_uint64_t );    \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                       \
                  cycles[NTT_TEST_COUNT >> 1] );                        \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}

#endif /* NTT_CHECK_FUNCTIONAL_CORRECTNESS */
