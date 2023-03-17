/*
 * Copyright (c) 2022 Arm Limited
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
 *
 * Author: Hanno Becker <hannobecker@posteo.de>
 */

#define TEST_FOO
#define BENCH_FOO

/*
 * Some external references to auto-generated assembly.
 */

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define WARMUP_ITERATIONS 1000
#define ITER_PER_TEST      100
#define TEST_COUNT         100

/* Add declarationa for ASM NTTs here */
void ntt_kyber_123_4567(int16_t *);

#define NTT_LAYERS             8
#define NTT_SIZE               (1u << NTT_LAYERS)
#define NTT_ROOT_ORDER         (2 * NTT_SIZE)
#define NTT_INCOMPLETE_LAYERS  7
#define NTT_INCOMPLETE_SIZE    (1u << NTT_INCOMPLETE_LAYERS)
#define NTT_LAYER_GAP          ( NTT_LAYERS - NTT_INCOMPLETE_LAYERS )
#define NTT_LAYER_STRIDE       (1u << NTT_LAYER_GAP )

#include <hal.h>
#include <misc.h>
#include <poly.h>

/*
 * Test cases
 */

int16_t base_root        = 17;
int16_t modulus          = 3329;
uint16_t modulus_inv_u16 = 62209;

int16_t  roots        [NTT_ROOT_ORDER / 2] __attribute__((aligned(16))) = { 0 };
uint16_t roots_twisted[NTT_ROOT_ORDER / 2] __attribute__((aligned(16))) = { 0 };

void build_roots()
{
    for( unsigned i=0; i < NTT_ROOT_ORDER / 2; i++ )
    {
        roots[i]         = mod_pow_s16( base_root, i, modulus );
        roots_twisted[i] = roots[i] * modulus_inv_u16;
    }
}

unsigned bit_reverse( unsigned in, unsigned width )
{
    unsigned out = 0;
    while( width-- )
    {
        out <<= 1;
        out |= ( in % 2 );
        in >>= 1;
    }
    return( out );
}

static int cmp_uint64_t(const void *a, const void *b)
{
    return (int)((*((const uint64_t *)a)) - (*((const uint64_t *)b)));
}

void ntt_s16_C( int16_t *src )
{
    int16_t res[NTT_SIZE];
    build_roots();

    for( unsigned t=0; t<NTT_LAYER_STRIDE; t++ )
    {
        for( unsigned i=0; i<NTT_INCOMPLETE_SIZE; i++ )
        {
            int16_t tmp = 0;
            /* A negacyclic FFT is half of a full FFT, where we've 'chosen -1'
             * in the first layer. That explains the corrections by NTT_INCOMPLETE_SIZE
             * and +1 here. In a normal FFT, this would just be bit_rev( i, layers ) * stride. */
            unsigned const multiplier =
                bit_reverse( i + NTT_INCOMPLETE_SIZE, NTT_INCOMPLETE_LAYERS + 1 ) * NTT_LAYER_STRIDE;

            for( unsigned j=0; j<NTT_INCOMPLETE_SIZE; j++ )
            {
                int16_t cur;
                unsigned exp = ( ( multiplier * j ) % NTT_ROOT_ORDER ) / 2;
                unsigned sub = ( exp >= ( NTT_ROOT_ORDER / 2 ) );
                exp = exp % ( NTT_ROOT_ORDER / 2 );

                cur = mod_mul_s16( src[NTT_LAYER_STRIDE*j+t],
                                   roots[exp],
                                   modulus );

                if( !sub )
                    tmp = mod_add_s16( tmp, cur, modulus );
                else
                    tmp = mod_sub_s16( tmp, cur, modulus );
            }
            res[NTT_LAYER_STRIDE*i+t] = tmp;
        }
    }

    memcpy( src, res, sizeof( res ) );
}

void buf_bitrev_4( int16_t *src )
{
    int32_t *src_ = (int32_t*) src;
    for( unsigned i=0; i < NTT_SIZE/2; i += 16 )
    {
        int32_t tmp[16];
        for( unsigned t=0; t < 16; t++ )
            tmp[t] = src_[i+t];

        for( unsigned t0=0; t0 < 4; t0++ )
            for( unsigned t1=0; t1 < 4; t1++ )
                src_[i+t0*4 + t1] = tmp[t1*4+t0];
    }
}

#define MAKE_TEST_FWD(var,func,rev4)                                    \
int test_ntt_ ## var ()                                                 \
{                                                                       \
    debug_test_start( "NTT s16 for " #func );                           \
    int16_t src[NTT_SIZE]      __attribute__((aligned(16)));            \
    int16_t src_copy[NTT_SIZE] __attribute__((aligned(16)));            \
                                                                        \
    /* Setup input */                                                   \
    fill_random_u16( (uint16_t*) src, NTT_SIZE );                       \
    mod_reduce_buf_s16( src, NTT_SIZE, modulus );                       \
                                                                        \
    /* Step 1: Reference NTT */                                         \
    memcpy( src_copy, src, sizeof( src ) );                             \
    ntt_s16_C( src_copy );                                              \
    mod_reduce_buf_s16( src_copy, NTT_SIZE, modulus );                  \
                                                                        \
    if( rev4 )                                                          \
        buf_bitrev_4( src_copy );                                       \
                                                                        \
    /* Step 2: Neon-based NTT */                                        \
    (func)( src );                                                      \
                                                                        \
    mod_reduce_buf_s16( src, NTT_SIZE, modulus );                       \
    if( compare_buf_u16( (uint16_t const*) src, (uint16_t const*) src_copy, \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
        debug_print_buf_s16( src_copy, NTT_SIZE, "Reference" );         \
        debug_print_buf_s16( src, NTT_SIZE, "Neon" );                   \
        debug_test_fail();                                              \
        return( 1 );                                                    \
    }                                                                   \
    debug_test_ok();                                                    \
                                                                        \
    return( 0 );                                                        \
}

MAKE_TEST_FWD(asm,ntt_kyber_123_4567,1)

uint64_t t0, t1;
uint64_t cycles[TEST_COUNT];

#define MAKE_BENCH(var,func)                                            \
int bench_ntt_ ## var ()                                                \
{                                                                       \
    int16_t src[NTT_SIZE]      __attribute__((aligned(16)));            \
                                                                        \
    for( unsigned cnt=0; cnt < WARMUP_ITERATIONS; cnt++ )               \
        (func)( src );                                                  \
                                                                        \
    for( unsigned cnt=0; cnt < TEST_COUNT; cnt++ )                      \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        for( unsigned cntp=0; cntp < ITER_PER_TEST; cntp++ )            \
            (func)( src );                                              \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = (t1 - t0) / ITER_PER_TEST;                        \
    }                                                                   \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, TEST_COUNT, sizeof(uint64_t), cmp_uint64_t );        \
    debug_printf( "Median after %u NTTs: %lld cycles\n",                \
                  TEST_COUNT,cycles[TEST_COUNT >> 1] );                 \
                                                                        \
    return( 0 );                                                        \
}

MAKE_BENCH(asm,ntt_kyber_123_4567)

int main( void )
{
    debug_test_start("Kyber NTT test");

    /* Benchs */
    bench_ntt_asm();

    /* Tests */
    if( test_ntt_asm()!= 0 )
        return(1);

    debug_test_ok();
    return(0);
}
