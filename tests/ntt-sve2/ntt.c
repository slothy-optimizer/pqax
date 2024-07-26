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

#define print_buf   CONCAT2(debug_print_buf_u, BITWIDTH)
#define print_buf_s CONCAT2(debug_print_buf_s, BITWIDTH)
#define compare_buf CONCAT2(compare_buf_u, BITWIDTH)
#define fill_random CONCAT2(fill_random_u, BITWIDTH)

//#define CONFIG_TEST_NTT_VERBOSE

const ssgl_t mod       = MODULUS;
const usgl_t mod_inv   = MODULUS_INV;
const ssgl_t mod_root  = MODULUS_BASE_ROOT;

ALIGN(16) ssgl_t root_base[2*NTT_SIZE]             = { 0 };
ALIGN(16) usgl_t root_base_twisted[2*NTT_SIZE]     = { 0 };
ALIGN(16) ssgl_t inv_root_base[2*NTT_SIZE]         = { 0 };
ALIGN(16) usgl_t inv_root_base_twisted[2*NTT_SIZE] = { 0 };

ssgl_t roots        [NTT_SIZE] = { 0 };
usgl_t roots_twisted[NTT_SIZE] = { 0 };

void mul_q( ssgl_t *src, sdbl_t c, size_t size )
{
    for( unsigned idx = 0; idx < size; idx++ )
    {
        sdbl_t tmp;
        src[idx] = src[idx] % mod;
        if( src[idx] < 0 )
            src[idx] += mod;
        tmp = (sdbl_t) src[idx] * c;
        src[idx] = tmp % mod;
        if( src[idx] < 0 )
            src[idx] += mod;
    }
}

void reduce_q( ssgl_t *src, size_t size )
{
    for( unsigned idx = 0; idx < size; idx++ )
    {
        src[idx] = src[idx] % mod;
        if( src[idx] < 0 )
            src[idx] += mod;
    }
}

void montgomery_pt_C( ssgl_t const *src_a,
                      ssgl_t const *src_b,
                      ssgl_t *dst,
                      size_t size )
{
    unsigned idx;
    for( idx = 0; idx < size; idx++ )
    {
        sdbl_t v;
        ssgl_t hi;
        usgl_t lo, tmp, hi_fix;

        v = 2 * (sdbl_t) src_a[idx] * (sdbl_t) src_b[idx];

        /* Hi+lo part extraction */
        hi     =  (ssgl_t)( v >> 32 );
        lo     = (usgl_t)( v >>  0 );

        /* Fixed scalar multiply, lo */
        tmp    = lo * mod_inv;
        /* Fixed scalar multiply, hi */
        hi_fix = ( (udbl_t) tmp * (udbl_t) mod ) >> 32;

        dst[idx] = (ssgl_t)( (sdbl_t) hi - (sdbl_t) hi_fix );
    }
}

void buf_reduce( ssgl_t *src, size_t size )
{
    for( unsigned i=0; i < size; i++ )
    {
        src[i] = src[i] % mod;
        if( src[i] < 0 )
            src[i] += mod;
    }
}

ssgl_t mod_mul( ssgl_t a, ssgl_t b, ssgl_t modulus )
{
    sdbl_t tmp = (sdbl_t) a * (sdbl_t) b;
    ssgl_t res = tmp % modulus;
    return( res);
}

ssgl_t mod_add( ssgl_t a, ssgl_t b, ssgl_t modulus )
{
    sdbl_t tmp = (sdbl_t) a + (sdbl_t) b;
    ssgl_t res = tmp % modulus;
    return( res);
}

ssgl_t mod_sub( ssgl_t a, ssgl_t b, ssgl_t modulus )
{
    sdbl_t tmp = (sdbl_t) a - (sdbl_t) b;
    ssgl_t res = tmp % modulus;
    return( res);
}

ssgl_t mod_pow( ssgl_t base, unsigned exp, ssgl_t modulus )
{
    ssgl_t base_pow = base;
    ssgl_t tmp = 1;
    while( exp != 0 )
    {
        if( exp & 1 )
            tmp = mod_mul( tmp, base_pow, modulus );

        base_pow = mod_mul( base_pow, base_pow, modulus );
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
        roots[i]         = mod_pow( mod_root, i, mod );
        roots_twisted[i] = roots[i] * mod_inv;

#if defined(CONFIG_TEST_NTT_VERBOSE)
        debug_printf( "zeta^%u = %u^%u = %u\n",
                      i, (unsigned) mod_root, i,
                      roots[i] );

        debug_printf( "zeta^%u * %u = %u^%u * %u = %u\n",
                      i, mod_inv,
                      (unsigned) mod_root, i, mod_inv,
                      roots_twisted[i] );
#endif /* CONFIG_TEST_NTT_VERBOSE */
    }
}

void ntt_C( ssgl_t *src )
{
    ssgl_t res[NTT_SIZE];
    build_roots();

    for( unsigned t=0; t<NTT_LAYER_STRIDE; t++ )
    {
        for( unsigned i=0; i<NTT_INCOMPLETE_SIZE; i++ )
        {
            ssgl_t tmp = 0;
            /* A negacyclic FFT is half of a full FFT, where we've 'chosen -1'
             * in the first layer. That explains the corrections by NTT_INCOMPLETE_SIZE
             * and +1 here. In a normal FFT, this would just be bit_rev( i, layers ) * stride. */
            unsigned const multiplier =
                bit_reverse( i + NTT_INCOMPLETE_SIZE, NTT_INCOMPLETE_LAYERS + 1 ) * NTT_LAYER_STRIDE;

            for( unsigned j=0; j<NTT_INCOMPLETE_SIZE; j++ )
            {
                ssgl_t cur;
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
                               mod );

                if( !sub )
                    tmp = mod_add( tmp, cur, mod );
                else
                    tmp = mod_sub( tmp, cur, mod );
            }
            res[NTT_LAYER_STRIDE*i+t] = tmp;
        }
    }

    memcpy( src, res, sizeof( res ) );
}

udbl_t t0, t1;
udbl_t cycles[NTT_TEST_COUNT];

static int cmp_udbl_t(const void *a, const void *b)
{
    return (int)((*((const udbl_t *)a)) - (*((const udbl_t *)b)));
}

#if BITWIDTH == 32
#define NTT_SVE2_INCOMPLETE(VAR) ntt_u32_incomplete_sve2_asm_var_ ## VAR
#else
#define NTT_SVE2_INCOMPLETE(VAR) ntt_u64_incomplete_sve2_asm_var_ ## VAR
#endif
#define NTT_SVE2_FULL(VAR) CONCAT4(ntt_u,BITWIDTH,_full_sve2_asm_var_,VAR)

#if defined(NTT_CHECK_FUNCTIONAL_CORRECTNESS)

void buf_bitrev_4( ssgl_t *src, size_t size )
{
    for( unsigned i=0; i < size; i += 16 )
    {
        ssgl_t tmp[16];
        for( unsigned t=0; t < 16; t++ )
            tmp[t] = src[i+t];

        for( unsigned r0=0; t0 < 4; r0++ )
            for( unsigned r1=0; t1 < 4; r1++ )
                src[i+r0*4 + r1] = tmp[r1*4+r0];
    }
}

#define GEN_TEST_NTT_INCOMPLETE(variant)                                \
int test_fwd_ntt_incomplete_var_ ## variant ()                          \
{                                                                       \
    debug_test_start( "NTT: deg 256, 32-bit, forward, 6-layer incomplete" ); \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t src[NTT_SIZE];                                               \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t src_copy[NTT_SIZE];                                          \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t dummy_copy[NTT_SIZE];                                        \
                                                                        \
    rand_init(0);                                                       \
                                                                        \
    /* Setup input */                                                   \
    fill_random( (usgl_t*) src, NTT_SIZE );                             \
    buf_reduce( src, NTT_SIZE );                                        \
                                                                        \
    /* Step 1: Reference NTT */                                         \
    memcpy( src_copy, src, sizeof( src ) );                             \
    ntt_C( src_copy );                                                  \
    buf_reduce( src_copy, NTT_SIZE );                                   \
                                                                        \
    /* Step 2: SIMD-based NTT */                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_SVE2_INCOMPLETE(variant)( dummy_copy );                     \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_SVE2_INCOMPLETE(variant)( dummy_copy );                     \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    NTT_SVE2_INCOMPLETE(variant)( src );                                \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(udbl_t), cmp_udbl_t );        \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                       \
                  cycles[NTT_TEST_COUNT >> 1] );                        \
                                                                        \
    buf_reduce( src, NTT_SIZE );                                        \
                                                                        \
    if( compare_buf( (usgl_t const*) src, (usgl_t const*) src_copy,     \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
        print_buf_s( src_copy, NTT_SIZE, "Reference" );                 \
        print_buf_s( src, NTT_SIZE, "MVE" );                            \
        debug_test_fail();                                              \
        return( 1 );                                                    \
    }                                                                   \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}

#define GEN_TEST_NTT_FULL(variant)                                      \
int test_fwd_ntt_full_var_ ## variant ()                                \
{                                                                       \
    debug_test_start( "NTT: deg 256, 32-bit, forward, full" );          \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t src[NTT_SIZE];                                               \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t src_copy[NTT_SIZE];                                          \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t dummy_copy[NTT_SIZE];                                        \
                                                                        \
    rand_init(0);                                                       \
                                                                        \
    /* Setup input */                                                   \
    fill_random( (usgl_t*) src, NTT_SIZE );                             \
    buf_reduce( src, NTT_SIZE );                                        \
                                                                        \
    /* Step 1: Reference NTT */                                         \
    memcpy( src_copy, src, sizeof( src ) );                             \
    ntt_C( src_copy );                                                  \
    buf_reduce( src_copy, NTT_SIZE );                                   \
                                                                        \
    /* Step 2: SIMD-based NTT */                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_SVE2_FULL(variant)( dummy_copy );                           \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_SVE2_FULL(variant)( dummy_copy );                           \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    NTT_SVE2_FULL(variant)( src );                                      \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(udbl_t), cmp_udbl_t );        \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                       \
                  cycles[NTT_TEST_COUNT >> 1] );                        \
                                                                        \
    if( NTT_COMPLETE_BITREV4 )                                          \
        buf_bitrev_4( src, NTT_SIZE );                                  \
                                                                        \
    buf_reduce( src, NTT_SIZE );                                        \
                                                                        \
    if( compare_buf( (usgl_t const*) src, (usgl_t const*) src_copy,     \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
        print_buf( src_copy, NTT_SIZE, "Reference" );                   \
        print_buf( src, NTT_SIZE, "MVE" );                              \
        debug_test_fail();                                              \
        return( 1 );                                                    \
    }                                                                   \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}


#else /* NTT_CHECK_FUNCTIONAL_CORRECTNESS */

#define GEN_TEST_NTT_INCOMPLETE(variant)                                \
int test_fwd_ntt_incomplete_var_ ## variant ()                          \
{                                                                       \
    debug_test_start( "NTT: deg 256, 32-bit, forward, 6-layer incomplete" ); \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t src[NTT_SIZE];                                               \
                                                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_SVE2_INCOMPLETE(variant)( src );                            \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_SVE2_INCOMPLETE(variant)( src );                            \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(udbl_t), cmp_udbl_t );        \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                       \
                  cycles[NTT_TEST_COUNT >> 1] );                        \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}

#define GEN_TEST_NTT_FULL(variant)                                      \
int test_fwd_ntt_full_var_ ## variant ()                                \
{                                                                       \
    debug_test_start( "NTT: deg 256, 32-bit, forward, full" );          \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t src[NTT_SIZE];                                               \
                                                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_SVE2_FULL(variant)( src );                                  \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_SVE2_FULL(variant)( src );                                  \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(udbl_t), cmp_udbl_t );        \
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

#define NTT_SVE2_DUAL_INCOMPLETE(variant) \
    CONCAT4(ntt_u,BITWIDTH,_incomplete_sve2_asm_dual_var_,variant)

#if defined(NTT_CHECK_FUNCTIONAL_CORRECTNESS)

#define GEN_TEST_NTT_INCOMPLETE_DUAL(variant)   \
int test_fwd_ntt_incomplete_dual_var_ ## variant()                       \
{                                                                       \
    debug_test_start( "NTT dual: deg 256, 32-bit, forward, 6-layer incomplete" ); \
    debug_printf( "Variant: %s\n", #variant );                          \
                                                                        \
    ssgl_t src0[NTT_SIZE];                                             \
    ssgl_t src0_copy[NTT_SIZE];                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t dummy0_copy[NTT_SIZE];                                      \
                                                                        \
    ssgl_t src1[NTT_SIZE];                                             \
    ssgl_t src1_copy[NTT_SIZE];                                        \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t dummy1_copy_[NTT_SIZE];                                     \
    ssgl_t * dummy1_copy = dummy1_copy_ + NTT_DUAL_BUFFER_OFFSET;      \
                                                                        \
    rand_init(0);                                                       \
                                                                        \
    /* Setup input */                                                   \
    fill_random( (usgl_t*) src1, NTT_SIZE );                            \
    buf_reduce( src1, NTT_SIZE );                                       \
    fill_random( (usgl_t*) src0, NTT_SIZE );                            \
    buf_reduce( src0, NTT_SIZE );                                       \
                                                                        \
    /* Step 1: Reference NTT */                                         \
    memcpy( src0_copy, src0, sizeof( src0 ) );                          \
    memcpy( src1_copy, src1, sizeof( src1 ) );                          \
    ntt_C( src0_copy );                                                 \
    ntt_C( src1_copy );                                                 \
    buf_reduce( src0_copy, NTT_SIZE );                                  \
    buf_reduce( src1_copy, NTT_SIZE );                                  \
                                                                        \
    /* Step 2: SIMD-based NTT */                                        \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_SVE2_DUAL_INCOMPLETE(variant)( dummy0_copy, dummy1_copy );  \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                  \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_SVE2_DUAL_INCOMPLETE(variant)( dummy0_copy, dummy1_copy );  \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    NTT_SVE2_DUAL_INCOMPLETE(variant)( src0, src1 );                    \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(udbl_t), cmp_udbl_t );        \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                       \
                  cycles[NTT_TEST_COUNT >> 1] );                        \
                                                                        \
    buf_reduce( src0, NTT_SIZE );                                       \
    buf_reduce( src1, NTT_SIZE );                                       \
                                                                        \
    if( compare_buf( (usgl_t const*) src0, (usgl_t const*) src0_copy,   \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
       for( unsigned idx=0; idx < NTT_SIZE; idx++ )                     \
           if( src0[idx] != src0_copy[idx] )                            \
               debug_printf( "SRC0[%u]: %d != %d\n",                    \
                             idx, src0[idx], src0_copy[idx] );          \
        debug_test_fail();                                              \
    }                                                                   \
                                                                        \
    if( compare_buf( (usgl_t const*) src1, (usgl_t const*) src1_copy,   \
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
    ssgl_t dummy0_copy[NTT_SIZE];                                      \
    ALIGN(NTT_BUFFER_ALIGN)                                             \
    ssgl_t dummy1_copy_[NTT_SIZE];                                     \
    ssgl_t * dummy1_copy = dummy1_copy_ + NTT_DUAL_BUFFER_OFFSET;      \
                                                                        \
    /* SIMD-based NTT */                                                \
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )                 \
        NTT_SVE2_DUAL_INCOMPLETE(variant)( dummy0_copy, dummy1_copy );  \
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )                 \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        NTT_SVE2_DUAL_INCOMPLETE(variant)( dummy0_copy, dummy1_copy );  \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = t1 - t0;                                          \
    }                                                                   \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, NTT_TEST_COUNT, sizeof(udbl_t), cmp_udbl_t );    \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  NTT_TEST_COUNT,                                       \
                  cycles[NTT_TEST_COUNT >> 1] );                        \
                                                                        \
    debug_test_ok();                                                    \
    return( 0 );                                                        \
}

#endif /* NTT_CHECK_FUNCTIONAL_CORRECTNESS */

#if BITWIDTH == 64
int test_basemul_u64()
{
    debug_test_start( "Basemul" );

    ALIGN(NTT_BUFFER_ALIGN) ssgl_t dst_sve[NTT_SIZE];
    //ALIGN(NTT_BUFFER_ALIGN) ssgl_t dst_ref[NTT_SIZE];
    ALIGN(NTT_BUFFER_ALIGN) ssgl_t a[NTT_SIZE];
    ALIGN(NTT_BUFFER_ALIGN) ssgl_t b[NTT_SIZE];

    /* SIMD-based basemul */
    for( unsigned cnt=0; cnt < NTT_TEST_WARMUP; cnt++ )
        basemul_u64( dst_sve, a, b, NTT_SIZE );
    for( unsigned cnt=0; cnt < NTT_TEST_COUNT; cnt++ )
    {
        t0 = get_cyclecounter();
        basemul_u64( dst_sve, a, b, NTT_SIZE );
        t1 = get_cyclecounter();
        cycles[cnt] = t1 - t0;
    }

    /* Report median */
    qsort( cycles, NTT_TEST_COUNT, sizeof(udbl_t), cmp_udbl_t );
    debug_printf( "Median after %u NTTs: %lld cycles\n",
                  NTT_TEST_COUNT,
                  cycles[NTT_TEST_COUNT >> 1] );

    debug_test_ok();
    return( 0 );
}
#else
int test_basemul_u64()
{
    /* This is specific to 64-bit, so skip for 32-bit */
    return(0);
}
#endif
