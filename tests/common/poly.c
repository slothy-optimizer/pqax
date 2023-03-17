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

#include <hal.h>
#include <misc.h>
#include <poly.h>

void random_poly( uint16_t *poly, unsigned int len )
{
    fill_random_u16( poly, len );
}

void zero_poly( uint16_t *poly, unsigned int len )
{
    for( ; len; len--, poly++ )
        *poly = 0;
}

int compare_poly( uint16_t const *a, uint16_t const *b, unsigned int len )
{
    return( compare_buf_u16( a, b, len ) );
}

void mask_poly( uint16_t *poly, unsigned int len, unsigned bitwidth )
{
    uint16_t mask = (1u << bitwidth) - 1;
    for( ; len; len--, poly++ )
        *poly &= mask;
}

void copy_poly( uint16_t *dst, uint16_t const *src, unsigned int len )
{
    for( ; len; len--, dst++, src++ )
        *dst = *src;
}

void debug_print_poly(uint16_t *poly, unsigned int len, const char *prefix )
{
    unsigned idx;
    for( idx=0; idx < len; idx += 16 )
    {
        unsigned sub_idx;
        debug_printf( "%s[%03u-%03u]: ", prefix, idx, idx+15 );
        for( sub_idx=0; sub_idx<16; sub_idx++ )
            debug_printf( "%02x ", (unsigned) poly[idx + sub_idx] );
        debug_printf( "\n" );
    }
}

/*
 * Things related to modular arithmetic
 */

/* Scalar operations */

int32_t mod_red_s32( int64_t a, int32_t mod )
{
    int32_t tmp = a % mod;
    if( tmp < 0 )
        tmp += mod;
    return( tmp );
}

int32_t mod_mul_s32( int32_t a, int32_t b, int32_t mod )
{
    int64_t tmp = (int64_t) a * (int64_t) b;
    int32_t res = (int32_t)( tmp % mod );
    return( res );
}

int32_t mod_add_s32( int32_t a, int32_t b, int32_t mod )
{
    int64_t tmp = (int64_t) a + (int64_t) b;
    int32_t res = tmp % mod;
    return( res);
}

int32_t mod_sub_s32( int32_t a, int32_t b, int32_t mod )
{
    int64_t tmp = (int64_t) a - (int64_t) b;
    int32_t res = tmp % mod;
    return( res);
}

int32_t mod_pow_s32( int32_t base, unsigned exp, int32_t mod )
{
    int32_t base_pow = base;
    int32_t tmp = 1;
    while( exp != 0 )
    {
        if( exp & 1 )
            tmp = mod_mul_s32( tmp, base_pow, mod );

        base_pow = mod_mul_s32( base_pow, base_pow, mod );
        exp >>= 1;
    }

    return( tmp );
}

/* Scalar operations */

int16_t mod_red_s16( int64_t a, int16_t mod )
{
    int16_t tmp = a % mod;
    if( tmp < 0 )
        tmp += mod;
    return( tmp );
}

int16_t mod_mul_s16( int16_t a, int16_t b, int16_t mod )
{
    int64_t tmp = (int64_t) a * (int64_t) b;
    int16_t res = (int16_t)( tmp % mod );
    return( res );
}

int16_t mod_add_s16( int16_t a, int16_t b, int16_t mod )
{
    int64_t tmp = (int64_t) a + (int64_t) b;
    int16_t res = tmp % mod;
    return( res);
}

int16_t mod_sub_s16( int16_t a, int16_t b, int16_t mod )
{
    int64_t tmp = (int64_t) a - (int64_t) b;
    int16_t res = tmp % mod;
    return( res);
}

int16_t mod_pow_s16( int16_t base, unsigned exp, int16_t mod )
{
    int16_t base_pow = base;
    int16_t tmp = 1;
    while( exp != 0 )
    {
        if( exp & 1 )
            tmp = mod_mul_s16( tmp, base_pow, mod );

        base_pow = mod_mul_s16( base_pow, base_pow, mod );
        exp >>= 1;
    }

    return( tmp );
}

/* Buffer operations */

void mod_add_buf_u16( uint16_t *src_a, uint16_t *src_b, uint16_t *dst,
                      unsigned size )
{
    for( unsigned i=0; i < size; i++ )
        dst[i] = src_a[i] + src_b[i];
}

void mod_add_buf_s32( int32_t *src_a, int32_t *src_b, int32_t *dst,
                      unsigned size, int32_t modulus )
{
    for( unsigned i=0; i < size; i++ )
        dst[i] = mod_add_s32( src_a[i], src_b[i], modulus );
}

void mod_reduce_buf_s32( int32_t *src, unsigned size, int32_t mod )
{
    for( unsigned i=0; i < size; i++ )
    {
        src[i] = src[i] % mod;
        if( src[i] < 0 )
            src[i] += mod;
    }
}

void mod_reduce_buf_s32_signed( int32_t *src, unsigned size, int32_t mod )
{
    mod_reduce_buf_s32( src, size, mod );
    for( unsigned i=0; i < size; i++ )
    {
        if( src[i] >= ( mod / 2 ) )
            src[i] -= mod;
    }
}

void mod_mul_buf_const_s32( int32_t *src, int32_t factor, int32_t *dst,
                            unsigned size, int32_t mod )
{
    unsigned idx;
    for( idx = 0; idx < size; idx++ )
        dst[idx] = mod_mul_s32( src[idx], factor, mod );
}

void mod_mul_buf_s32( int32_t *src_a, int32_t *src_b, int32_t *dst,
                      unsigned size, int32_t mod )
{
    unsigned idx;
    for( idx = 0; idx < size; idx++ )
        dst[idx] = mod_mul_s32( src_a[idx], src_b[idx], mod );
}

/* Buffer operations */

void mod_add_buf_s16( int16_t *src_a, int16_t *src_b, int16_t *dst,
                      unsigned size, int16_t modulus )
{
    for( unsigned i=0; i < size; i++ )
        dst[i] = mod_add_s16( src_a[i], src_b[i], modulus );
}

void mod_reduce_buf_s16( int16_t *src, unsigned size, int16_t mod )
{
    for( unsigned i=0; i < size; i++ )
    {
        src[i] = src[i] % mod;
        if( src[i] < 0 )
            src[i] += mod;
    }
}

void mod_reduce_buf_s16_signed( int16_t *src, unsigned size, int16_t mod )
{
    mod_reduce_buf_s16( src, size, mod );
    for( unsigned i=0; i < size; i++ )
    {
        if( src[i] >= ( mod / 2 ) )
            src[i] -= mod;
    }
}

void mod_mul_buf_const_s16( int16_t *src, int16_t factor, int16_t *dst,
                            unsigned size, int16_t mod )
{
    unsigned idx;
    for( idx = 0; idx < size; idx++ )
        dst[idx] = mod_mul_s16( src[idx], factor, mod );
}

void mod_mul_buf_s16( int16_t *src_a, int16_t *src_b, int16_t *dst,
                      unsigned size, int16_t mod )
{
    unsigned idx;
    for( idx = 0; idx < size; idx++ )
        dst[idx] = mod_mul_s16( src_a[idx], src_b[idx], mod );
}
