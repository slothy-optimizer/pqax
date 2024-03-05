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

#define DO_TEST
#define DO_BENCH

/*
 * Some external references to auto-generated assembly.
 */
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define WARMUP_ITERATIONS  1000
#define ITER_PER_TEST      1000
#define TEST_COUNT         100

/* Add declarationa for ASM NTTs here */
// base
void ntt_kyber_123_4567(int16_t *);
void ntt_kyber_123_4567_scalar_load(int16_t *);
void ntt_kyber_123_4567_scalar_load_store(int16_t *);
void ntt_kyber_123_4567_scalar_store(int16_t *);
void ntt_kyber_1234_567(int16_t *);
// A55
void ntt_kyber_123_4567_manual_st4_opt_a55(int16_t *);
void ntt_kyber_123_4567_opt_a55(int16_t *);
void ntt_kyber_123_4567_scalar_load_opt_a55(int16_t *);
void ntt_kyber_123_4567_scalar_load_store_opt_a55(int16_t *);
void ntt_kyber_123_4567_scalar_store_opt_a55(int16_t *);
// A72
void ntt_kyber_123_4567_manual_st4_opt_a72(int16_t *);
void ntt_kyber_123_4567_opt_a72(int16_t *);
void ntt_kyber_123_4567_scalar_load_opt_a72(int16_t *);
void ntt_kyber_123_4567_scalar_load_store_opt_a72(int16_t *);
void ntt_kyber_123_4567_scalar_store_opt_a72(int16_t *);
// M1 Firestorm
void ntt_kyber_123_4567_opt_m1_firestorm(int16_t *);
void ntt_kyber_123_4567_scalar_load_opt_m1_firestorm(int16_t *);
void ntt_kyber_123_4567_scalar_load_store_opt_m1_firestorm(int16_t *);
void ntt_kyber_123_4567_manual_st4_opt_m1_firestorm(int16_t *);
void ntt_kyber_123_4567_scalar_store_opt_m1_firestorm(int16_t *);
/* void ntt_kyber_1234_567_opt_m1_firestorm(int16_t *); */
/* void ntt_kyber_1234_567_manual_st4_opt_m1_firestorm(int16_t *); */

// M1 Icestorm
void ntt_kyber_123_4567_manual_st4_opt_m1_icestorm(int16_t *);
void ntt_kyber_123_4567_scalar_load_opt_m1_icestorm(int16_t *);
void ntt_kyber_123_4567_opt_m1_icestorm(int16_t *);
void ntt_kyber_123_4567_scalar_load_store_opt_m1_icestorm(int16_t *);
void ntt_kyber_123_4567_scalar_store_opt_m1_icestorm(int16_t *);
/* void ntt_kyber_1234_567_opt_m1_icestorm(int16_t *); */
/* void ntt_kyber_1234_567_manual_st4_opt_m1_icestorm(int16_t *); */

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
#include "neonntt.h"
#include "pqclean.h"

#define T int16_t
#define T2 int32_t

/*
 * Test cases
*/

int16_t base_root        = 17;
int16_t modulus          = 3329;
uint16_t modulus_inv_u16 = 62209;
int16_t  ninvR            = 2285; // TODO FIX
int16_t  base_root_inv    = 1175;

int16_t  roots        [NTT_ROOT_ORDER / 2] __attribute__((aligned(16))) = { 0 };
uint16_t roots_twisted[NTT_ROOT_ORDER / 2] __attribute__((aligned(16))) = { 0 };

// void build_roots()
// {
//     for( unsigned i=0; i < NTT_ROOT_ORDER / 2; i++ )
//     {
//         roots[i]         = mod_pow_s16( base_root, i, modulus );
//         roots_twisted[i] = roots[i] * modulus_inv_u16;
//     }
// }

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

// NTT FFT reference code form
// https://github.com/mkannwischer/polymul/blob/072248095f5ef14f874e73772525cab68fb9d454/C/07incomplete.c
// slightly modified

/**
 * @brief Bitreverse an array of length n inplace
 *
 * @param src array
 * @param n length of array
 */
void bitreverse(T *src, size_t n){
    for(size_t i = 0, j = 0; i < n; i++){
        if(i < j){
            src[i] += src[j];
            src[i] -= (src[j] = (src[i] - src[j]));
        }
        for(size_t k = n >> 1; (j ^= k) < k; k >>=1);
    }
}

/**
 * @brief Precompute the required twiddle factors for a incomplete negacyclic Cooley--Tukey FFT
 *
 * First layer: [-1] = [root^(n/2)]
 * Second layer: [sqrt(-1), -sqrt(-1)] = [root^(n/4), root^(3n/4)]
 * Third layer: [sqrt(root^(n/4)), -sqrt(root^(n/4)), sqrt(root^(3n/4)), -sqrt(root^(3n/4))]
                =[root^(n/8), root^(5n/8), root^(3n/8), root^(7n/8)]
 * ...
 *
 * @param twiddles output buffer for the twiddles. needs to hold (2^numLayers)-1 twiddles
 * @param n number of coefficients in polynomials (not size of the NTT)
 * @param root 2*(2^numLayers)-th primitive root of unity modulo q
 * @param q modulus
 * @param numLayers number of layers in the NTT. Needs to be <= log n
 * @return int 1 if there is an error, 0 otherwise
 */
static int precomp_ct_negacyclic(T *twiddles, size_t n, T root, T q, size_t numLayers){
    //powers = [pow(root, i, q) for i in range(2**numLayers//2)]
    T powers[(1<<numLayers)];
    powers[0] = 1;
    for(size_t i=1;i<(1U<<numLayers);i++){
        powers[i] = ((T2) powers[i-1]*root) % q;
    }
    bitreverse(powers, 1<<numLayers);

    for(size_t i = 0; i < (1U<<numLayers)-1; i++){
        twiddles[i] = powers[i+1];
    }
    return 0;
}

/**
 * @brief Precompute the required twiddle factors for a incomplete negacyclic Gentleman--Sande inverse FFT
 *
 * The twiddles correspond to the inverses of the ones computed in `precomp_ct_negacyclic`.
 *
 * @param twiddles output buffer for the twiddles. needs to hold (2^numLayers) twiddles
 * @param n number of coefficients in polynomials (not size of the NTT)
 * @param root 2*(2^numLayers)-th primitive root of unity modulo q
 * @param q modulus
 * @param numLayers number of layers in the NTT. Needs to be <= log n
 * @return int 1 if there is an error, 0 otherwise
 */
// static int precomp_gs_negacyclic(T *twiddles, size_t n, T root, T q, size_t numLayers){
//     //powers = [pow(root, -(i+1), q) for i in range(2**numLayers)]
//     T powers[(1<<numLayers)];
//     T rootInverse = base_root_inv;
//     powers[0] = rootInverse;
//     for(size_t i=1;i< 1U<<numLayers;i++){
//         powers[i] = ((T2) powers[i-1]*rootInverse) % q;
//     }
//     bitreverse(powers, 1<<numLayers);
//     for(size_t i=0;i<(1U<<numLayers)-1;i++){
//         twiddles[i] = powers[i];
//     }
//     return 0;
// }

/**
 * @brief Compute a Cooley--Tukey FFT. Stop after numLayers
 *
 * Expects twiddles to be computed by `precomp_ct_cyclic` or `precomp_ct_negacyclic`
 * Each layer computes a split of
 * `Z_q[x]/(x^n - c^2)` to `Z_q[x]/(x^(n/2) - c) x Z_q[x]/(x^(n/2) + c)`
 * using the CT butterfly:
 * ```
 * a_i' = a_i + c*a_j
 * a_j' = a_i - c*a_j
 * ```
 * @param a polynomial with n coefficients to be transformed to NTT domain
 * @param twiddles twiddle factors computed by `precomp_ct_cyclic` or `precomp_ct_negacyclic`
 * @param n number of coefficients in a
 * @param q modulus
 * @param numLayers number of layers in the NTT. Needs to be <= log n
 */
static void ntt_ct(T *a){
    precomp_ct_negacyclic(roots, NTT_SIZE, base_root, modulus, NTT_INCOMPLETE_LAYERS);
    size_t logn = log2(NTT_SIZE);
    T *twiddles = roots;

    for(size_t i=0; i < NTT_INCOMPLETE_LAYERS; i++){
        size_t distance = 1U<< (logn - 1 -i);
        for(size_t j=0; j<(1U<<i); j++){
            T twiddle = *twiddles;
            twiddles++;
            // Note: in the cyclic case many of the twiddles are 1;
            // could optimize those multiplications away
            for(size_t k =0; k<distance; k++){
                size_t idx0 = 2*j*distance + k;
                size_t idx1 = idx0 + distance;
                T a0  = a[idx0];
                T a1  = ((T2) a[idx1] * twiddle) % modulus;
                a[idx0] = (a0 + a1) % modulus;
                a[idx1] = (a0 + modulus - a1) % modulus;
            }
        }
    }
}

/**
 * @brief Compute a Gentleman--Sande inverse FFT. Stop after numLayers
 *
 * Expects twiddles to be computed by `precomp_gs_cyclic` or `precomp_gs_negacyclic`
 * Each layer computes the CRT of
 * Z_q[x]/(x^(n/2) - c) x Z_q[x]/(x^(n/2) + c) to recover an element in Z_q[x]/(x^n - c^2)
 * using the GS butterfly:
 * ```
 * a_i' = 1/2 * (a_i + a_j)
 * a_j' = 1/2 * 1/c * (a_i - a_j)
 * ```
 * The scaling by 1/2 is usually delayed until the very end, i.e., multiplication by 1/(2^numLayers).
 *
 * @param a input in NTT domain. To be transformed back to normal domain
 * @param twiddles twiddle factors computed by `precomp_gs_cyclic` or `precomp_gs_negacyclic`
 * @param n number of coefficients in a
 * @param q modulus
 * @param numLayers number of layers in the NTT. Needs to be <= log n
 */
// static void invntt_gs(T *a){
//     size_t logn = log2(NTT_SIZE);
//     precomp_gs_negacyclic(roots, NTT_SIZE, base_root, modulus, NTT_INCOMPLETE_LAYERS);
//     int32_t *twiddles = roots;
//     for(size_t i=logn-NTT_INCOMPLETE_LAYERS; i < logn; i++){
//         size_t distance = 1<<i;
//         for(size_t j=0; j<(1U<<(logn - 1 -i)); j++){
//             T twiddle = *twiddles;
//             twiddles++;
//             // Note: in the cyclic case many of the twiddles are 1;
//             // could optimize those multiplications away
//             for(size_t k =0; k<distance; k++){
//                 size_t idx0 = 2*j*distance + k;
//                 size_t idx1 = idx0 + distance;
//                 T a0  = (a[idx0] + a[idx1]) % modulus;
//                 T a1  = (a[idx0] + modulus - a[idx1]) % modulus;
//                 a[idx0] = a0;
//                 a[idx1] = ((T2)a1*twiddle) % modulus;
//             }
//         }
//     }

//     // Note: Half of these multiplications can be merged into the last
//     // layer of butterflies by pre-computing (twiddle*ninv)%q
//     for(size_t i=0;i<NTT_SIZE;i++){
//         a[i] = ((T2)a[i]*ninvR)%modulus;
//     }
// }

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

#define MAKE_TEST_FWD(var,func,ref_func,rev4,reduction_included)                 \
int test_ntt_ ## var ()                                                 \
{                                                                       \
    debug_printf( "test ntt_kyber %-50s ", #func "\0");                 \
    int16_t src[NTT_SIZE]      __attribute__((aligned(16)));            \
    int16_t src_copy[NTT_SIZE] __attribute__((aligned(16)));            \
                                                                        \
    /* Setup input */                                                   \
    fill_random_u16( (uint16_t*) src, NTT_SIZE );                       \
    mod_reduce_buf_s16_signed( src, NTT_SIZE, modulus );                \
                                                                        \
    /* Step 1: Reference NTT */                                         \
    memcpy( src_copy, src, sizeof( src ) );                             \
    (ref_func)( src_copy );                                                 \
    mod_reduce_buf_s16_signed( src_copy, NTT_SIZE, modulus );           \
                                                                        \
    if( rev4 )                                                          \
        buf_bitrev_4( src_copy );                                       \
                                                                        \
    /* Step 2: Neon-based NTT */                                        \
    (func)( src );                                                      \
                                                                        \
    if( (reduction_included) == 0 )                                     \
        mod_reduce_buf_s16_signed( src, NTT_SIZE, modulus );            \
    if( compare_buf_u16( (uint16_t const*) src, (uint16_t const*) src_copy, \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
        debug_print_buf_s16( src_copy, NTT_SIZE, "Reference" );         \
        debug_print_buf_s16( src, NTT_SIZE, "Neon" );                   \
        debug_printf("FAIL!\n");                                        \
        return( 1 );                                                    \
    }                                                                   \
    debug_printf("OK!\n");                                              \
    return( 0 );                                                        \
}

MAKE_TEST_FWD(asm, ntt_kyber_123_4567, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_load, ntt_kyber_123_4567_scalar_load, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_load_store, ntt_kyber_123_4567_scalar_load_store, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_store, ntt_kyber_123_4567_scalar_store, ntt_ct,0,1)
MAKE_TEST_FWD(asm_1234_567, ntt_kyber_1234_567, ntt_ct,0,1)
// A55
MAKE_TEST_FWD(asm_123_4567_manual_st4_opt_a55, ntt_kyber_123_4567_manual_st4_opt_a55, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_opt_a55, ntt_kyber_123_4567_opt_a55, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_load_opt_a55, ntt_kyber_123_4567_scalar_load_opt_a55, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_load_store_opt_a55, ntt_kyber_123_4567_scalar_load_store_opt_a55, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_store_opt_a55, ntt_kyber_123_4567_scalar_store_opt_a55, ntt_ct,0,1)
// A72
MAKE_TEST_FWD(asm_123_4567_manual_st4_opt_a72, ntt_kyber_123_4567_manual_st4_opt_a72, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_opt_a72, ntt_kyber_123_4567_opt_a72, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_load_opt_a72, ntt_kyber_123_4567_scalar_load_opt_a72, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_load_store_opt_a72, ntt_kyber_123_4567_scalar_load_store_opt_a72, ntt_ct,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_store_opt_a72, ntt_kyber_123_4567_scalar_store_opt_a72, ntt_ct,0,1)
// M1 Firestorm
MAKE_TEST_FWD(asm_123_4567_opt_m1_firestorm, ntt_kyber_123_4567_opt_m1_firestorm,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_load_opt_m1_firestorm, ntt_kyber_123_4567_scalar_load_opt_m1_firestorm,0,1)
/* MAKE_TEST_FWD(asm_1234_567_opt_m1_firestorm, ntt_kyber_1234_567_opt_m1_firestorm,0,1) */
MAKE_TEST_FWD(asm_123_4567_scalar_load_store_opt_m1_firestorm, ntt_kyber_123_4567_scalar_load_store_opt_m1_firestorm,0,1)
MAKE_TEST_FWD(asm_123_4567_manual_st4_opt_m1_firestorm, ntt_kyber_123_4567_manual_st4_opt_m1_firestorm,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_store_opt_m1_firestorm, ntt_kyber_123_4567_scalar_store_opt_m1_firestorm,0,1)
/* MAKE_TEST_FWD(asm_1234_567_manual_st4_opt_m1_firestorm, ntt_kyber_1234_567_manual_st4_opt_m1_firestorm,0,1) */
// M1 Icestorm
MAKE_TEST_FWD(asm_123_4567_manual_st4_opt_m1_icestorm, ntt_kyber_123_4567_manual_st4_opt_m1_icestorm,0,1)
MAKE_TEST_FWD(asm_123_4567_opt_m1_icestorm, ntt_kyber_123_4567_opt_m1_icestorm,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_load_opt_m1_icestorm, ntt_kyber_123_4567_scalar_load_opt_m1_icestorm,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_load_store_opt_m1_icestorm, ntt_kyber_123_4567_scalar_load_store_opt_m1_icestorm,0,1)
MAKE_TEST_FWD(asm_123_4567_scalar_store_opt_m1_icestorm, ntt_kyber_123_4567_scalar_store_opt_m1_icestorm,0,1)
/* MAKE_TEST_FWD(asm_1234_567_opt_m1_icestorm, ntt_kyber_1234_567_opt_m1_icestorm,0,1) */
/* MAKE_TEST_FWD(asm_1234_567_manual_st4_opt_m1_icestorm, ntt_kyber_1234_567_manual_st4_opt_m1_icestorm,0,1) */
// other
MAKE_TEST_FWD(neonntt,ntt, ntt_ct,0,1)
MAKE_TEST_FWD(pqclean,pqclean_ntt,0,1)

uint64_t t0, t1;
uint64_t cycles[TEST_COUNT];

#define MAKE_BENCH(var,func)                                            \
int bench_ntt_ ## var ()                                                \
{                                                                       \
    debug_printf( "bench ntt_kyber %-50s", #func "\0" ) ;               \
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
    debug_printf( "%4lld cycles %3u repeats\n",                           \
                  cycles[TEST_COUNT >> 1], TEST_COUNT );                \
                                                                        \
    return( 0 );                                                        \
}

MAKE_BENCH(asm_123_4567, ntt_kyber_123_4567)
MAKE_BENCH(asm_123_4567_scalar_load, ntt_kyber_123_4567_scalar_load)
MAKE_BENCH(asm_123_4567_scalar_load_store, ntt_kyber_123_4567_scalar_load_store)
MAKE_BENCH(asm_123_4567_scalar_store, ntt_kyber_123_4567_scalar_store)
MAKE_BENCH(asm_1234_567, ntt_kyber_1234_567)
// A55
MAKE_BENCH(asm_123_4567_manual_st4_opt_a55, ntt_kyber_123_4567_manual_st4_opt_a55)
MAKE_BENCH(asm_123_4567_opt_a55, ntt_kyber_123_4567_opt_a55)
MAKE_BENCH(asm_123_4567_scalar_load_opt_a55, ntt_kyber_123_4567_scalar_load_opt_a55)
MAKE_BENCH(asm_123_4567_scalar_load_store_opt_a55, ntt_kyber_123_4567_scalar_load_store_opt_a55)
MAKE_BENCH(asm_123_4567_scalar_store_opt_a55, ntt_kyber_123_4567_scalar_store_opt_a55)
// A72
MAKE_BENCH(asm_123_4567_manual_st4_opt_a72, ntt_kyber_123_4567_manual_st4_opt_a72)
MAKE_BENCH(asm_123_4567_opt_a72, ntt_kyber_123_4567_opt_a72)
MAKE_BENCH(asm_123_4567_scalar_load_opt_a72, ntt_kyber_123_4567_scalar_load_opt_a72)
MAKE_BENCH(asm_123_4567_scalar_load_store_opt_a72, ntt_kyber_123_4567_scalar_load_store_opt_a72)
MAKE_BENCH(asm_123_4567_scalar_store_opt_a72, ntt_kyber_123_4567_scalar_store_opt_a72)
// M1 Firestorm
MAKE_BENCH(asm_123_4567_opt_m1_firestorm, ntt_kyber_123_4567_opt_m1_firestorm)
MAKE_BENCH(asm_123_4567_scalar_load_opt_m1_firestorm, ntt_kyber_123_4567_scalar_load_opt_m1_firestorm)
/* MAKE_BENCH(asm_1234_567_opt_m1_firestorm, ntt_kyber_1234_567_opt_m1_firestorm) */
MAKE_BENCH(asm_123_4567_scalar_load_store_opt_m1_firestorm, ntt_kyber_123_4567_scalar_load_store_opt_m1_firestorm)
MAKE_BENCH(asm_123_4567_manual_st4_opt_m1_firestorm, ntt_kyber_123_4567_manual_st4_opt_m1_firestorm)
MAKE_BENCH(asm_123_4567_scalar_store_opt_m1_firestorm, ntt_kyber_123_4567_scalar_store_opt_m1_firestorm)
/* MAKE_BENCH(asm_1234_567_manual_st4_opt_m1_firestorm, ntt_kyber_1234_567_manual_st4_opt_m1_firestorm) */
// M1 Icestorm
MAKE_BENCH(asm_123_4567_manual_st4_opt_m1_icestorm, ntt_kyber_123_4567_manual_st4_opt_m1_icestorm)
MAKE_BENCH(asm_123_4567_opt_m1_icestorm, ntt_kyber_123_4567_opt_m1_icestorm)
MAKE_BENCH(asm_123_4567_scalar_load_opt_m1_icestorm, ntt_kyber_123_4567_scalar_load_opt_m1_icestorm)
MAKE_BENCH(asm_123_4567_scalar_load_store_opt_m1_icestorm, ntt_kyber_123_4567_scalar_load_store_opt_m1_icestorm)
MAKE_BENCH(asm_123_4567_scalar_store_opt_m1_icestorm, ntt_kyber_123_4567_scalar_store_opt_m1_icestorm)
/* MAKE_BENCH(asm_1234_567_opt_m1_icestorm, ntt_kyber_1234_567_opt_m1_icestorm) */
/* MAKE_BENCH(asm_1234_567_manual_st4_opt_m1_icestorm, ntt_kyber_1234_567_manual_st4_opt_m1_icestorm) */
// other
MAKE_BENCH(neonntt,ntt)
MAKE_BENCH(pqclean,pqclean_ntt)

int main( void )
{
    debug_printf( "=========== Kyber NTT Test ===============\n" );

    debug_printf( "- Enable cycle counter ..." );
    enable_cyclecounter();
    debug_printf( "ok\n" );

#if defined(DO_TEST)
    if (test_ntt_asm() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_scalar_load() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_scalar_load_store() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_scalar_store() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_1234_567() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_manual_st4_opt_a55() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_opt_a55() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_scalar_load_opt_a55() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_scalar_load_store_opt_a55() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_scalar_store_opt_a55() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_manual_st4_opt_a72() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_opt_a72() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_scalar_load_opt_a72() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_scalar_load_store_opt_a72() != 0)
    {
        return (1);
    }

    if (test_ntt_asm_123_4567_scalar_store_opt_a72() != 0)
    {
        return (1);
    }
    // M1 Firestorm
    if(test_ntt_asm_123_4567_opt_m1_firestorm() != 0){return (1);}
    if(test_ntt_asm_123_4567_scalar_load_opt_m1_firestorm() != 0){return (1);}
    if(test_ntt_asm_123_4567_scalar_load_store_opt_m1_firestorm() != 0){return (1);}
    if(test_ntt_asm_123_4567_manual_st4_opt_m1_firestorm() != 0){return (1);}
    if(test_ntt_asm_123_4567_scalar_store_opt_m1_firestorm() != 0){return (1);}
    /* if(test_ntt_asm_1234_567_opt_m1_firestorm() != 0){return (1);} */
    /* if(test_ntt_asm_1234_567_manual_st4_opt_m1_firestorm() != 0){return (1);} */

    // M1 Icestorm
    if(test_ntt_asm_123_4567_manual_st4_opt_m1_icestorm() != 0){return (1);}
    if(test_ntt_asm_123_4567_opt_m1_icestorm() != 0){return (1);}
    if(test_ntt_asm_123_4567_scalar_load_opt_m1_icestorm() != 0){return (1);}
    if(test_ntt_asm_123_4567_scalar_load_store_opt_m1_icestorm() != 0){return (1);}
    if(test_ntt_asm_123_4567_scalar_store_opt_m1_icestorm() != 0){return (1);}
    /* if(test_ntt_asm_1234_567_opt_m1_icestorm() != 0){return (1);} */
    /* if(test_ntt_asm_1234_567_manual_st4_opt_m1_icestorm() != 0){return (1);} */

    if( test_ntt_neonntt()!= 0 )
        return(1);
    if( test_ntt_pqclean()!= 0 )
        return(1);
#endif /* DO_TEST */

#if defined(DO_BENCH)
    /* Benchs */
    bench_ntt_asm_123_4567();
    bench_ntt_asm_123_4567_scalar_load();
    bench_ntt_asm_123_4567_scalar_load_store();
    bench_ntt_asm_123_4567_scalar_store();
    bench_ntt_asm_1234_567();
    bench_ntt_asm_123_4567_manual_st4_opt_a55();
    bench_ntt_asm_123_4567_opt_a55();
    bench_ntt_asm_123_4567_scalar_load_opt_a55();
    bench_ntt_asm_123_4567_scalar_load_store_opt_a55();
    bench_ntt_asm_123_4567_scalar_store_opt_a55();
    bench_ntt_asm_123_4567_manual_st4_opt_a72();
    bench_ntt_asm_123_4567_opt_a72();
    bench_ntt_asm_123_4567_scalar_load_opt_a72();
    bench_ntt_asm_123_4567_scalar_load_store_opt_a72();
    bench_ntt_asm_123_4567_scalar_store_opt_a72();
    // M1 Firestorm
    bench_ntt_asm_123_4567_opt_m1_firestorm();
    bench_ntt_asm_123_4567_scalar_load_opt_m1_firestorm();
    bench_ntt_asm_123_4567_scalar_load_store_opt_m1_firestorm();
    bench_ntt_asm_123_4567_manual_st4_opt_m1_firestorm();
    bench_ntt_asm_123_4567_scalar_store_opt_m1_firestorm();
    /* bench_ntt_asm_1234_567_opt_m1_firestorm(); */
    /* bench_ntt_asm_1234_567_manual_st4_opt_m1_firestorm(); */
    // M1 Icestorm
    bench_ntt_asm_123_4567_manual_st4_opt_m1_icestorm();
    bench_ntt_asm_123_4567_opt_m1_icestorm();
    bench_ntt_asm_123_4567_scalar_load_opt_m1_icestorm();
    bench_ntt_asm_123_4567_scalar_load_store_opt_m1_icestorm();
    bench_ntt_asm_123_4567_scalar_store_opt_m1_icestorm();
    /* bench_ntt_asm_1234_567_opt_m1_icestorm(); */
    /* bench_ntt_asm_1234_567_manual_st4_opt_m1_icestorm(); */

    bench_ntt_neonntt();
    bench_ntt_pqclean();
#endif /* DO_BENCH */

    debug_printf( "- Disable cycle counter ..." );
    disable_cyclecounter();
    debug_printf( "ok\n" );

    debug_printf( "\nDone!\n" );
    return(0);
}
