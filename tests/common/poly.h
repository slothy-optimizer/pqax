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

#if !defined(PQAX_TEST_POLY_INC)
#define PQAX_TEST_POLY_INC

#include <stdint.h>

#include "poly.h"

int  compare_poly( uint16_t const *src_a, uint16_t const *src_b,
                   unsigned int dim );
void random_poly ( uint16_t *a, unsigned int dim );
void zero_poly   ( uint16_t *a, unsigned int dim );
void mask_poly   ( uint16_t *a, unsigned int dim, unsigned bitwidth );
void copy_poly   ( uint16_t *dst, uint16_t const *src, unsigned int dim );
void debug_print_poly  ( uint16_t *a, unsigned int dim, const char *prefix );

/*
 * Helpers for modular multiplication and reduction.
 */

/* Scalar operations */
int32_t mod_red_s32( int64_t a, int32_t mod );
int32_t mod_mul_s32( int32_t a, int32_t b, int32_t mod );
int32_t mod_add_s32( int32_t a, int32_t b, int32_t mod );
int32_t mod_sub_s32( int32_t a, int32_t b, int32_t mod );
int32_t mod_pow_s32( int32_t base, unsigned exp, int32_t mod );

/* Scalar operations */
int16_t mod_red_s16( int64_t a, int16_t mod );
int16_t mod_mul_s16( int16_t a, int16_t b, int16_t mod );
int16_t mod_add_s16( int16_t a, int16_t b, int16_t mod );
int16_t mod_sub_s16( int16_t a, int16_t b, int16_t mod );
int16_t mod_pow_s16( int16_t base, unsigned exp, int16_t mod );

/* Buffer operations */
void mod_reduce_buf_s32   ( int32_t *src, unsigned size, int32_t modulus );
void mod_reduce_buf_s32_signed( int32_t *src, unsigned size, int32_t modulus );
void mod_mul_buf_const_s32( int32_t *src, int32_t factor, int32_t *dst,
                            unsigned size, int32_t mod );
void mod_add_buf_u16( uint16_t *src_a, uint16_t *src_b, uint16_t *dst,
                      unsigned size );
void mod_add_buf_s32( int32_t *src_a, int32_t *src_b, int32_t *dst,
                      unsigned size, int32_t modulus );
void mod_mul_buf_s32      ( int32_t *src_a, int32_t *src_b, int32_t *dst,
                            unsigned size, int32_t modulus );

/* Buffer operations */
void mod_reduce_buf_s16   ( int16_t *src, unsigned size, int16_t modulus );
void mod_reduce_buf_s16_signed( int16_t *src, unsigned size, int16_t modulus );
void mod_mul_buf_const_s16( int16_t *src, int16_t factor, int16_t *dst,
                            unsigned size, int16_t mod );
void mod_add_buf_u16( uint16_t *src_a, uint16_t *src_b, uint16_t *dst,
                      unsigned size );
void mod_add_buf_s16( int16_t *src_a, int16_t *src_b, int16_t *dst,
                      unsigned size, int16_t modulus );
void mod_mul_buf_s16      ( int16_t *src_a, int16_t *src_b, int16_t *dst,
                            unsigned size, int16_t modulus );

#endif /* PQAX_TEST_POLY_INC */
