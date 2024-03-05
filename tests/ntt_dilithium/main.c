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

/*
 * Some external references to auto-generated assembly.
 */

#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#define WARMUP_ITERATIONS 1000
#define ITER_PER_TEST      100
#define TEST_COUNT         100

/* Add declarationa for ASM NTTs here */
// base
void ntt_dilithium_123_45678(int32_t *);
void ntt_dilithium_123_45678_w_scalar(int32_t *);
void ntt_dilithium_123_45678_manual_st4(int32_t *);
void ntt_dilithium_1234_5678(int32_t *);
// A55
void ntt_dilithium_123_45678_opt_a55(int32_t *);
void ntt_dilithium_123_45678_manual_st4_opt_a55(int32_t *);
void ntt_dilithium_123_45678_w_scalar_opt_a55(int32_t *);
// A72
void ntt_dilithium_123_45678_opt_a72(int32_t *);
void ntt_dilithium_123_45678_manual_st4_opt_a72(int32_t *);
void ntt_dilithium_1234_5678_opt_a72(int32_t *);
// M1 Firestorm
void ntt_dilithium_123_45678_opt_m1(int32_t *);
void ntt_dilithium_123_45678_manual_st4_opt_m1(int32_t *);
void ntt_dilithium_123_45678_w_scalar_opt_m1(int32_t *);
// M1 Icestorm
void ntt_dilithium_123_45678_opt_m1_icestorm(int32_t *);

#define NTT_LAYERS             8
#define NTT_SIZE               (1u << NTT_LAYERS)
#define NTT_ROOT_ORDER         (2 * NTT_SIZE)

#define T int32_t
#define T2 int64_t

#include <hal.h>
#include <misc.h>
#include <poly.h>
#include "neonntt.h"
/*
 * Test cases
 */

int32_t  base_root        = 1753;
int32_t  modulus          = 8380417;
int32_t  ninvR            = 16382;
uint32_t modulus_inv_u32  = 58728449;
int32_t  base_root_inv    = 731434;

int32_t  roots        [NTT_ROOT_ORDER / 2] __attribute__((aligned(16))) = { 0 };

static int cmp_uint64_t(const void *a, const void *b)
{
    return (int)((*((const uint64_t *)a)) - (*((const uint64_t *)b)));
}

// NTT FFT reference code form
// https://github.com/mkannwischer/polymul/blob/072248095f5ef14f874e73772525cab68fb9d454/C/05fft.c
// slightly modified

/**
 * @brief Bitreverse an array of length n inplace
 *
 * @param src array
 * @param n length of array
 */
void bitreverse(int32_t *src, size_t n){
    for(size_t i = 0, j = 0; i < n; i++){
        if(i < j){
            src[i] += src[j];
            src[i] -= (src[j] = (src[i] - src[j]));
        }
        for(size_t k = n >> 1; (j ^= k) < k; k >>=1);
    }
}

/**
 * @brief Precomputes the required twiddle factors for a negacyclic Cooley--Tukey FFT
 * First layer: [-1] = [root^(n/2)]
 * Second layer: [sqrt(-1), -sqrt(-1)] = [root^(n/4), root^(3n/4)]
 * Third layer: [sqrt(root^(n/4)), -sqrt(root^(n/4)), sqrt(root^(3n/4)), -sqrt(root^(3n/4))]
 *             =[root^(n/8), root^(5n/8), root^(3n/8), root^(7n/8)]
 * ...
 *
 * @param twiddles output buffer for the twiddles. needs to hold n-1 twiddles
 * @param n size of the NTT (number of coefficients)
 * @param root 2n-th primitive root of unity modulo q
 * @param q modulus
 * @return int 1 if there is an error, 0 otherwise
 */
static int precomp_ct_negacyclic(int32_t *twiddles, size_t n, int32_t root, int32_t q){

    int32_t powers[n];
    powers[0] = 1;
    for(size_t i=1;i<n;i++){
        powers[i] = ((int64_t) powers[i-1]*root) % q;
    }
    bitreverse(powers, n);

    for(size_t i=0; i<n-1;i++){
        twiddles[i] = powers[i+1];
    }
    return 0;
}

/**
 * @brief Computes a Cooley--Tukey FFT
 *
 * Expects twiddles to be computed by `precomp_ct_cyclic` or `precomp_ct_negacyclic`
 * Each layer computes a split of
 * Z_q[x]/(x^n - c^2) to Z_q[x]/(x^(n/2) - c) x Z_q[x]/(x^(n/2) + c)
 * using the CT butterfly:
 * ```
 *   a_i' = a_i + c*a_j
 *   a_j' = a_i - c*a_j
 * ```
 *
 * @param a polynomial with n coefficients to be transformed to NTT domain
 */
static void ntt_u32_C(int32_t *a){
    precomp_ct_negacyclic(roots, NTT_SIZE, base_root, modulus);
    size_t logn = log2(NTT_SIZE);
    int32_t *twiddles = roots;
    for(size_t i=0; i < logn; i++){
        size_t distance = 1U<< (logn - 1 -i);
        for(size_t j=0; j<(1U<<i); j++){
            int32_t twiddle = *twiddles;
            twiddles++;
            // Note: in the cyclic case many of the twiddles are 1;
            // could optimize those multiplications away
            for(size_t k =0; k<distance; k++){
                size_t idx0 = 2*j*distance + k;
                size_t idx1 = idx0 + distance;
                int32_t a0  = a[idx0];
                int32_t a1  = ((int64_t) a[idx1] * twiddle) % modulus;
                a[idx0] = (a0 + a1) % modulus;
                a[idx1] = (a0 + modulus - a1) % modulus;
            }
        }

    }
}



/**
 * @brief Precomputes the required twiddle factors for a negacyclic Gentleman--Sande inverse FFT
 *
 * The twiddles correspond to the inverses of the ones computed in `precomp_ct_negacyclic`.
 * Note that the twiddle factors repeat. In a real implementation one would
 * not store them repeatedly.
 *
 * @param twiddles output buffer for the twiddles. needs to hold n-1 twiddles
 * @param n size of the NTT (number of coefficients)
 * @param root 2n-th primitive root of unity modulo q
 * @param q modulus
 * @return int 1 if there is an error, 0 otherwise
 */
/*static int precomp_gs_negacyclic(T *twiddles, size_t n, T root, T q){
    //powers = [pow(root, -(i+1), q) for i in range(n)]
    T powers[n];
    T rootInverse = base_root_inv;
    powers[0] = rootInverse;
    for(size_t i=1;i<n;i++){
        powers[i] = ((T2)powers[i-1]*rootInverse) % q;
    }
    bitreverse(powers, n);
    for(size_t i=0;i<n-1;i++){
        twiddles[i] = powers[i];
    }
    return 0;
}*/

/**
 * @brief Computes a Gentleman--Sande inverse FFT
 *
 * Expects twiddles to be computed by `precomp_gs_cyclic` or `precomp_gs_negacyclic`
 * Each layer computes the CRT of
 * `Z_q[x]/(x^(n/2) - c) x Z_q[x]/(x^(n/2) + c)` to recover an element in `Z_q[x]/(x^n - c^2)`
 * using the GS butterfly:
 * ```
 *   a_i' = 1/2 * (a_i + a_j)
 *   a_j' = 1/2 * 1/c * (a_i - a_j)
 * ```
 * The scaling by 1/2 is usually delayed until the very end, i.e., multiplication by 1/n.
 * Output in Montgomery domain.
 *
 * @param a input in NTT domain
 * @param twiddles twiddle factors computed by `precomp_gs_cyclic` or `precomp_gs_negacyclic`
 * @param n size of the input
 * @param q modulus
 */
/*static void invntt_u32_tomont_C(T *a){
    size_t logn = log2(NTT_SIZE);
    precomp_gs_negacyclic(roots, NTT_SIZE, base_root, modulus);
    int32_t *twiddles = roots;
    // printf("\n");
    for(size_t i=0; i < logn; i++){
        // printf("layer: %ld\n", i+1);
        size_t distance = 1<<i;
        for(size_t j=0; j<(1U<<(logn - 1 -i)); j++){
            T twiddle = *twiddles;
            // printf("%d\n", twiddle);
            twiddles++;
            // Note: in the cyclic case many of the twiddles are 1;
            // could optimize those multiplications away
            for(size_t k =0; k<distance; k++){
                size_t idx0 = 2*j*distance + k;
                size_t idx1 = idx0 + distance;
                // printf("aidx0 = %d\n", a[idx0]);
                // printf("aidx1 = %d\n", a[idx1]);
                T a0  = (a[idx0] + a[idx1]) % modulus;
                T a1  = (a[idx0] + modulus - a[idx1]) % modulus;
                a[idx0] = a0;
                a[idx1] = ((T2)a1*twiddle) % modulus;
            }
        }

    }

    // Note: Half of these multiplications can be merged into the last
    // layer of butterflies by pre-computing (twiddle*ninv)%q
    // includes multiplication by Montgomery factor
    for(size_t i=0;i<NTT_SIZE;i++){
        a[i] = ((T2)a[i]*ninvR)%modulus;
    }
}*/

void buf_bitrev_4( int32_t *src, size_t size )
{
    for( unsigned i=0; i < size; i += 16 )
    {
        int32_t tmp[16];
        for( unsigned t=0; t < 16; t++ )
        {
            tmp[t] = src[i+t];
        }

        for( unsigned r0=0; r0 < 4; r0++ )
        {
            for( unsigned r1=0; r1 < 4; r1++ )
            {
                src[i+r0*4 + r1] = tmp[r1*4+r0];
            }
        }
    }
}

#define MAKE_TEST(var,inv,func,ref_func,rev4,includes_reduction)        \
int test_ntt_ ## var ()                                                 \
{                                                                       \
    debug_printf( "test ntt_dilithium %-50s ", #func "\0");             \
                                                                        \
    int32_t src[NTT_SIZE]      __attribute__((aligned(16)));            \
    int32_t src_copy[NTT_SIZE] __attribute__((aligned(16)));            \
                                                                        \
    /* Setup input */                                                   \
    /*fill_random_u32( (uint32_t*) src, NTT_SIZE );*/                       \
    for(uint32_t i = 0; i< NTT_SIZE; i++){src[i] = (i * i * 137 + 1234) % modulus;} \
    mod_reduce_buf_s32( src, NTT_SIZE, modulus );                       \
                                                                        \
    /* Step 1: Reference NTT */                                         \
    memcpy( src_copy, src, sizeof( src ) );                             \
    (ref_func)( src_copy );                                             \
    mod_reduce_buf_s32_signed( src_copy, NTT_SIZE, modulus );           \
                                                                        \
    if( rev4 && !inv )                                                  \
        buf_bitrev_4( src_copy, NTT_SIZE );                             \
                                                                        \
    /* Step 2: Neon-based NTT */                                        \
    if( rev4 &&  inv )                                                  \
        buf_bitrev_4( src, NTT_SIZE );                                  \
    (func)( src );                                                      \
    if( !(includes_reduction ) )                                        \
        mod_reduce_buf_s32_signed( src, NTT_SIZE, modulus );            \
                                                                        \
    if( compare_buf_u32( (uint32_t const*) src, (uint32_t const*) src_copy, \
                         NTT_SIZE ) != 0 )                              \
    {                                                                   \
        debug_print_buf_s32( src_copy, NTT_SIZE, "Reference" );         \
        debug_print_buf_s32( src, NTT_SIZE, "Neon" );                   \
        debug_printf("FAIL!\n");                                        \
        return( 1 );                                                    \
    }                                                                   \
    debug_printf("OK!\n");                                              \
    return( 0 );                                                        \
}

// base
MAKE_TEST(asm_123_45678,0,ntt_dilithium_123_45678,ntt_u32_C,0,0)
MAKE_TEST(asm_123_45678_w_scalar,0,ntt_dilithium_123_45678_w_scalar,ntt_u32_C,0,0)
MAKE_TEST(asm_123_45678_manual_st4,0,ntt_dilithium_123_45678_manual_st4,ntt_u32_C,0,0)
MAKE_TEST(asm_1234_5678,0,ntt_dilithium_1234_5678,ntt_u32_C,0,0)
// A55
MAKE_TEST(asm_123_45678_opt_a55,0,ntt_dilithium_123_45678_opt_a55,ntt_u32_C,0,0)
MAKE_TEST(asm_123_45678_manual_st4_opt_a55,0,ntt_dilithium_123_45678_manual_st4_opt_a55,ntt_u32_C,0,0)
MAKE_TEST(asm_123_45678_w_scalar_opt_a55,0,ntt_dilithium_123_45678_w_scalar_opt_a55,ntt_u32_C,0,0)
// A72
MAKE_TEST(asm_123_45678_opt_a72,0,ntt_dilithium_123_45678_opt_a72,ntt_u32_C,0,0)
MAKE_TEST(asm_123_45678_manual_st4_opt_a72,0,ntt_dilithium_123_45678_manual_st4_opt_a72,ntt_u32_C,0,0)
MAKE_TEST(asm_1234_5678_opt_a72,0,ntt_dilithium_1234_5678_opt_a72,ntt_u32_C,0,0)
// M1
MAKE_TEST(asm_123_45678_opt_m1,0,ntt_dilithium_123_45678_opt_m1,ntt_u32_C,0,0)
MAKE_TEST(asm_123_45678_manual_st4_opt_m1,0,ntt_dilithium_123_45678_manual_st4_opt_m1,ntt_u32_C,0,0)
MAKE_TEST(asm_123_45678_w_scalar_opt_m1,0,ntt_dilithium_123_45678_w_scalar_opt_m1,ntt_u32_C,0,0)
// M1 Icestorm
MAKE_TEST(asm_123_45678_opt_m1_icestorm,0,ntt_dilithium_123_45678_opt_m1_icestorm,ntt_u32_C,0,0)
// Other
MAKE_TEST(neonntt_fwd,0,ntt,ntt_u32_C,0,0)

uint64_t t0, t1;
uint64_t cycles[TEST_COUNT];

#define MAKE_BENCH(var,func)                                            \
int bench_ntt_ ## var ()                                                \
{                                                                       \
    debug_printf( "bench ntt_dilithium %-50s", #func "\0" ) ;            \
    int32_t src[NTT_SIZE]      __attribute__((aligned(16)));            \
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

// base
MAKE_BENCH(asm_123_45678,ntt_dilithium_123_45678)
MAKE_BENCH(asm_123_45678_w_scalar,ntt_dilithium_123_45678_w_scalar)
MAKE_BENCH(asm_123_45678_manual_st4,ntt_dilithium_123_45678_manual_st4)
MAKE_BENCH(asm_1234_5678,ntt_dilithium_1234_5678)
// A55
MAKE_BENCH(asm_123_45678_opt_a55,ntt_dilithium_123_45678_opt_a55)
MAKE_BENCH(asm_123_45678_manual_st4_opt_a55,ntt_dilithium_123_45678_manual_st4_opt_a55)
MAKE_BENCH(asm_123_45678_w_scalar_opt_a55,ntt_dilithium_123_45678_w_scalar_opt_a55)
// A72
MAKE_BENCH(asm_123_45678_opt_a72,ntt_dilithium_123_45678_opt_a72)
MAKE_BENCH(asm_123_45678_manual_st4_opt_a72,ntt_dilithium_123_45678_manual_st4_opt_a72)
MAKE_BENCH(asm_1234_5678_opt_a72,ntt_dilithium_1234_5678_opt_a72)
// M1
MAKE_BENCH(asm_123_45678_opt_m1,ntt_dilithium_123_45678_opt_m1)
MAKE_BENCH(asm_123_45678_manual_st4_opt_m1,ntt_dilithium_123_45678_manual_st4_opt_m1)
MAKE_BENCH(asm_123_45678_w_scalar_opt_m1,ntt_dilithium_123_45678_w_scalar_opt_m1)
// M1
MAKE_BENCH(asm_123_45678_opt_m1_icestorm,ntt_dilithium_123_45678_opt_m1_icestorm)
// Other
MAKE_BENCH(neonntt_fwd,ntt)

int main( void )
{
    debug_test_start("Dilithium NTT");
    debug_printf("\n");
    /* Benchs */
    debug_printf("Benchmarks:\n");
    enable_cyclecounter();
    // base
    bench_ntt_asm_123_45678();
    bench_ntt_asm_123_45678_w_scalar();
    bench_ntt_asm_123_45678_manual_st4();
    bench_ntt_asm_1234_5678();
    // A55
    bench_ntt_asm_123_45678_opt_a55();
    bench_ntt_asm_123_45678_manual_st4_opt_a55();
    bench_ntt_asm_123_45678_w_scalar_opt_a55();
    // A72
    bench_ntt_asm_123_45678_opt_a72();
    bench_ntt_asm_123_45678_manual_st4_opt_a72();
    bench_ntt_asm_1234_5678_opt_a72();
    // M1
    bench_ntt_asm_123_45678_opt_m1();
    bench_ntt_asm_123_45678_manual_st4_opt_m1();
    bench_ntt_asm_123_45678_w_scalar_opt_m1();
    // M1 Icestorm
    bench_ntt_asm_123_45678_opt_m1_icestorm();
    // other
    bench_ntt_neonntt_fwd();
    disable_cyclecounter();

    // Tests
    debug_printf("Tests:\n");
    // base
    if (test_ntt_asm_123_45678() != 0)
    {
        return 1;
    }
    if (test_ntt_asm_123_45678_w_scalar() != 0)
    {
        return 1;
    }
    if (test_ntt_asm_123_45678_manual_st4() != 0)
    {
        return 1;
    }
    if (test_ntt_asm_1234_5678() != 0)
    {
        return 1;
    }
    // A55
    if (test_ntt_asm_123_45678_opt_a55() != 0)
    {
        return 1;
    }
    if (test_ntt_asm_123_45678_manual_st4_opt_a55() != 0)
    {
        return 1;
    }
    if (test_ntt_asm_123_45678_w_scalar_opt_a55() != 0)
    {
        return 1;
    }
    // A72
    if (test_ntt_asm_123_45678_opt_a72() != 0)
    {
        return 1;
    }
    if (test_ntt_asm_123_45678_manual_st4_opt_a72() != 0)
    {
        return 1;
    }
    if (test_ntt_asm_1234_5678_opt_a72() != 0)
    {
        return 1;
    }
    // M1
    if (test_ntt_asm_123_45678_opt_m1() != 0)
    {
        return 1;
    }
    if (test_ntt_asm_123_45678_manual_st4_opt_m1() != 0)
    {
        return 1;
    }
    if (test_ntt_asm_123_45678_w_scalar_opt_m1() != 0)
    {
        return 1;
    }
    // M1 Icestorm
    if (test_ntt_asm_123_45678_opt_m1_icestorm() != 0)
    {
        return 1;
    }
    // other
    if (test_ntt_neonntt_fwd() != 0)
    {
        return 1;
    }

    return(0);
}
