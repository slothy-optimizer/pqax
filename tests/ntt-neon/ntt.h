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

#ifndef SRC_NTT_H_
#define SRC_NTT_H_

#define SIZE 256

#define NTT_NO_CYCLES
#define NTT_INCOMPLETE

#define NTT_CHECK_FUNCTIONAL_CORRECTNESS
#define NTT_TEST_WARMUP 10
#define NTT_TEST_COUNT  10

#define NTT_BUFFER_ALIGN       32
#define NTT_DUAL_BUFFER_OFFSET 16

/* Prime modulus to be used by 32-bit multiplication routines  */
#define MODULUS_Q32              33556993
/* Modular inverse of q32 modulo 2**32                         */
#define MODULUS_Q32_INV_U32      375649793
/* Negative of modular inverse of q32 modulo 2**32             */
#define MODULUS_Q32_INV_U32_NEG  -375649793
/* 512-th root of unity for MODULUS_Q32                        */
#define MODULUS_Q32_BASE_ROOT 28678040

#define NTT_LAYERS             8
#define NTT_SIZE               (1u << NTT_LAYERS)

#if defined(NTT_INCOMPLETE)
#define NTT_INCOMPLETE_LAYERS 6
#define NTT_COMPLETE_BITREV4 0
#else
#define NTT_INCOMPLETE_LAYERS 8
#define NTT_COMPLETE_BITREV4 1
#endif

#define NTT_INCOMPLETE_SIZE    (1u << NTT_INCOMPLETE_LAYERS)

#define NTT_LAYER_GAP          ( NTT_LAYERS - NTT_INCOMPLETE_LAYERS )
#define NTT_LAYER_STRIDE       (1u << NTT_LAYER_GAP )

void ntt_u32_C( int32_t *buf );

void ntt_u32_incomplete_neon_asm_dual_var_3_3_0( int32_t *buf0, int32_t *buf1 );
void ntt_u32_incomplete_neon_asm_dual_var_3_3_1( int32_t *buf0, int32_t *buf1 );
void ntt_u32_incomplete_neon_asm_dual_var_3_3_2( int32_t *buf0, int32_t *buf1 );
void ntt_u32_incomplete_neon_asm_dual_var_3_3_3( int32_t *buf0, int32_t *buf1 );
void ntt_u32_incomplete_neon_asm_dual_var_3_3_4( int32_t *buf0, int32_t *buf1 );
void ntt_u32_incomplete_neon_asm_dual_var_3_3_5( int32_t *buf0, int32_t *buf1 );
void ntt_u32_incomplete_neon_asm_dual_var_3_3_6( int32_t *buf0, int32_t *buf1 );

void ntt_u32_incomplete_neon_asm_var_3_3_0( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_3_3_1( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_3_3_2( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_3_3_3( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_3_3_4( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_3_3_5( int32_t *buf );

void ntt_u32_incomplete_neon_asm_var_4_2_0_0( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_0_z4_0( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_24_z4_0( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_0_z4_16( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_24_z4_16( int32_t *buf );

void ntt_u32_incomplete_neon_asm_var_4_2_3_z4_0( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_3_z4_1( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_3_z4_2( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_3_z4_3( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_3_z4_4( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_3_z4_5( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_0( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_1( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_2( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_3( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_4( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_5( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_6( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_8( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_9( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_7_z4_10( int32_t *buf );

void ntt_u32_incomplete_neon_asm_var_4_2_8_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_9_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_10_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_11_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_12_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_13_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_14_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_15_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_16_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_17_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_18_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_19_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_20_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_21_z4_7( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_22_z4_7( int32_t *buf );

void ntt_u32_incomplete_neon_asm_var_4_2_22_z4_8( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_22_z4_9( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_22_z4_10( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_22_z4_11( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_22_z4_12( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_22_z4_13( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_22_z4_14( int32_t *buf );
void ntt_u32_incomplete_neon_asm_var_4_2_22_z4_15( int32_t *buf );

void ntt_u32_full_neon_asm_var_4_4_0_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_1_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_2_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_4_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_5_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_6_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_7_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_8_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_9_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_10_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_11_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_12_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_13_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_14_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_15_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_16_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_17_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_18_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_19_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_20_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_21_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_22_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z2_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z2_1( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z2_2( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z2_3( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z2_4( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z2_5( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z4_0( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z4_1( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z4_2( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z4_3( int32_t *buf );
void ntt_u32_full_neon_asm_var_4_4_3_z4_4( int32_t *buf );

int test_fwd_ntt_full_var_4_4_0_0(void);
int test_fwd_ntt_full_var_4_4_1_0(void);
int test_fwd_ntt_full_var_4_4_2_0(void);
int test_fwd_ntt_full_var_4_4_3_0(void);
int test_fwd_ntt_full_var_4_4_4_0(void);
int test_fwd_ntt_full_var_4_4_5_0(void);
int test_fwd_ntt_full_var_4_4_6_0(void);
int test_fwd_ntt_full_var_4_4_7_0(void);
int test_fwd_ntt_full_var_4_4_8_0(void);
int test_fwd_ntt_full_var_4_4_9_0(void);
int test_fwd_ntt_full_var_4_4_10_0(void);
int test_fwd_ntt_full_var_4_4_11_0(void);
int test_fwd_ntt_full_var_4_4_12_0(void);
int test_fwd_ntt_full_var_4_4_13_0(void);
int test_fwd_ntt_full_var_4_4_14_0(void);
int test_fwd_ntt_full_var_4_4_15_0(void);
int test_fwd_ntt_full_var_4_4_16_0(void);
int test_fwd_ntt_full_var_4_4_17_0(void);
int test_fwd_ntt_full_var_4_4_18_0(void);
int test_fwd_ntt_full_var_4_4_3_z2_0(void);
int test_fwd_ntt_full_var_4_4_3_z2_1(void);
int test_fwd_ntt_full_var_4_4_3_z2_2(void);
int test_fwd_ntt_full_var_4_4_3_z2_3(void);
int test_fwd_ntt_full_var_4_4_3_z2_4(void);
int test_fwd_ntt_full_var_4_4_3_z2_5(void);
int test_fwd_ntt_full_var_4_4_3_z4_0(void);
int test_fwd_ntt_full_var_4_4_3_z4_1(void);
int test_fwd_ntt_full_var_4_4_3_z4_2(void);
int test_fwd_ntt_full_var_4_4_3_z4_3(void);
int test_fwd_ntt_full_var_4_4_3_z4_4(void);

int test_fwd_ntt_incomplete_var_3_3_0(void);
int test_fwd_ntt_incomplete_var_3_3_1(void);
int test_fwd_ntt_incomplete_var_3_3_2(void);
int test_fwd_ntt_incomplete_var_3_3_3(void);
int test_fwd_ntt_incomplete_var_3_3_4(void);
int test_fwd_ntt_incomplete_var_3_3_5(void);

int test_fwd_ntt_incomplete_var_4_2_0_0(void);
int test_fwd_ntt_incomplete_var_4_2_0_z4_0(void);
int test_fwd_ntt_incomplete_var_4_2_24_z4_16(void);
int test_fwd_ntt_incomplete_var_4_2_24_z4_0(void);
int test_fwd_ntt_incomplete_var_4_2_0_z4_16(void);

int test_fwd_ntt_incomplete_var_4_2_3_z4_0(void);
int test_fwd_ntt_incomplete_var_4_2_3_z4_1(void);
int test_fwd_ntt_incomplete_var_4_2_3_z4_2(void);
int test_fwd_ntt_incomplete_var_4_2_3_z4_3(void);
int test_fwd_ntt_incomplete_var_4_2_3_z4_4(void);
int test_fwd_ntt_incomplete_var_4_2_3_z4_5(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_0(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_1(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_2(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_3(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_4(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_5(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_6(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_8(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_9(void);
int test_fwd_ntt_incomplete_var_4_2_7_z4_10(void);
int test_fwd_ntt_incomplete_var_4_2_8_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_9_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_10_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_11_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_12_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_13_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_14_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_15_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_16_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_17_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_18_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_19_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_20_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_21_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_22_z4_7(void);

int test_fwd_ntt_incomplete_var_4_2_22_z4_7(void);
int test_fwd_ntt_incomplete_var_4_2_22_z4_8(void);
int test_fwd_ntt_incomplete_var_4_2_22_z4_9(void);
int test_fwd_ntt_incomplete_var_4_2_22_z4_10(void);
int test_fwd_ntt_incomplete_var_4_2_22_z4_11(void);
int test_fwd_ntt_incomplete_var_4_2_22_z4_12(void);
int test_fwd_ntt_incomplete_var_4_2_22_z4_13(void);
int test_fwd_ntt_incomplete_var_4_2_22_z4_14(void);
int test_fwd_ntt_incomplete_var_4_2_22_z4_15(void);

int test_fwd_ntt_incomplete_dual_var_3_3_0(void);
int test_fwd_ntt_incomplete_dual_var_3_3_1(void);
int test_fwd_ntt_incomplete_dual_var_3_3_2(void);
int test_fwd_ntt_incomplete_dual_var_3_3_3(void);
int test_fwd_ntt_incomplete_dual_var_3_3_4(void);
int test_fwd_ntt_incomplete_dual_var_3_3_5(void);
int test_fwd_ntt_incomplete_dual_var_3_3_6(void);

#endif /* SRC_NTT_H_ */
