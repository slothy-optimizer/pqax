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

#ifndef SRC_MISC_H_
#define SRC_MISC_H_

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

#define CONCAT2_(A,B) A ## B
#define CONCAT2(A,B)   CONCAT2_(A,B)

#define CONCAT3_(A,B,C) A ## B ## C
#define CONCAT3(A,B,C) CONCAT3_(A,B,C)

#define CONCAT4_(A,B,C,D) A ## B ## C ## D
#define CONCAT4(A,B,C,D) CONCAT4_(A,B,C,<D)

#define CONCAT5_(A,B,C,D,E) A ## B ## C ## D ## E
#define CONCAT5(A,B,C,D,E) CONCAT5_(A,B,C,D,E)

#define CONCAT6_(A,B,C,D,E,F) A ## B ## C ## D ## E ## F
#define CONCAT6(A,B,C,D,E,F) CONCAT6_(A,B,C,D,E,F)

#define CONCAT7_(A,B,C,D,E,F,G) A ## B ## C ## D ## E ## F ## G
#define CONCAT7(A,B,C,D,E,F,G) CONCAT7_(A,B,C,D,E,F,G)

#define CONCAT8_(A,B,C,D,E,F,G,H) A ## B ## C ## D ## E ## F ## G ## H
#define CONCAT8(A,B,C,D,E,F,G,H) CONCAT8_(A,B,C,D,E,F,G,H)

#define unfold(x) x
#define run(testname) unfold(testname)()

#define uint(bitwidth) CONCAT3( uint, bitwidth, _t)
#define sint(bitwidth) CONCAT3( int, bitwidth, _t)

/* Helper macro for the creation of local or global buffers with
 * specified element width, length, and potentially padding. */
#define MAKE_BUFFER(name,bitwidth,len,padding)                         \
    CONCAT3(uint, bitwidth, _t) CONCAT2(name, _internal)[(padding)+(len)] = { 0 }; \
    CONCAT3(uint, bitwidth, _t) *name = & CONCAT2(name, _internal)[padding];

/* Fill a buffer with random data. */
void fill_random_u8 ( uint8_t  *buf, unsigned len );
void fill_random_u16( uint16_t *buf, unsigned len );
void fill_random_u32( uint32_t *buf, unsigned len );
void fill_random_u64( uint64_t *buf, unsigned len );

/* Copy buffers */
void copy_buf_u8 ( uint8_t  *dst, uint8_t  const *src, unsigned len );
void copy_buf_u16( uint16_t *dst, uint16_t const *src, unsigned len );
void copy_buf_u32( uint32_t *dst, uint32_t const *src, unsigned len );
void copy_buf_u64( uint64_t *dst, uint64_t const *src, unsigned len );

/* Compare buffers
 * Same semantics as memcmp(), but we want to rely on stdlib
 * as little as possible. */
int compare_buf_u8 ( uint8_t  const *src_a, uint8_t  const *src_b, unsigned len );
int compare_buf_u16( uint16_t const *src_a, uint16_t const *src_b, unsigned len );
int compare_buf_u32( uint32_t const *src_a, uint32_t const *src_b, unsigned len );
int compare_buf_u64( uint64_t const *src_a, uint64_t const *src_b, unsigned len );

/* Buffer printing helper */
void debug_print_buf_u8 ( uint8_t  const *buf, unsigned entries, const char *prefix );
void debug_print_buf_u16( uint16_t const *buf, unsigned entries, const char *prefix );
void debug_print_buf_u32( uint32_t const *buf, unsigned entries, const char *prefix );
void debug_print_buf_u64( uint64_t const *buf, unsigned entries, const char *prefix );
void debug_print_buf_s8 ( int8_t   const *buf, unsigned entries, const char *prefix );
void debug_print_buf_s16( int16_t  const *buf, unsigned entries, const char *prefix );
void debug_print_buf_s32( int32_t  const *buf, unsigned entries, const char *prefix );
void debug_print_buf_s64( int64_t  const *buf, unsigned entries, const char *prefix );

/* Transpose buffers */
void buffer_transpose_u8 ( uint8_t *dst, uint8_t const *src,
                           unsigned block_length, unsigned dim_x, unsigned dim_y );
void buffer_transpose_u16( uint16_t *dst, uint16_t const *src,
                           unsigned block_length, unsigned dim_x, unsigned dim_y );
void buffer_transpose_u32( uint32_t *dst, uint32_t const *src,
                           unsigned block_length, unsigned dim_x, unsigned dim_y );
void buffer_transpose_u64( uint64_t *dst, uint64_t const *src,
                           unsigned block_length, unsigned dim_x, unsigned dim_y );

#define ALIGN(x) __attribute__((aligned(x)))

#endif /* SRC_MISC_H_ */
