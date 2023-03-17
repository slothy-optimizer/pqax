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

 #include <misc.h>
 #include <hal.h>

 #define GEN_FILL_RANDOM( bits )                                       \
 void fill_random_u ## bits ( uint(bits) *buf, unsigned int len )      \
 {                                                                     \
     unsigned byte_len = len * sizeof(*buf);                           \
     uint8_t *byte_buf = (uint8_t*) buf;                               \
     for( ; byte_len; byte_buf++, byte_len-- )                         \
     {                                                                 \
         uint8_t cur_byte;                                             \
         cur_byte = get_random_byte();                                 \
         *byte_buf = cur_byte;                                         \
     }                                                                 \
 }
 GEN_FILL_RANDOM(8)
 GEN_FILL_RANDOM(16)
 GEN_FILL_RANDOM(32)
 #undef GEN_FILL_RANDOM

 #define GEN_COPY( bits )                                              \
 void copy_buf_u ## bits ( uint(bits) *dst,                            \
                           uint(bits) const *src, unsigned int len )   \
 {                                                                     \
     for( ; len; dst++, src++, len-- )                                 \
         *dst = *src;                                                  \
 }
 GEN_COPY(8)
 GEN_COPY(16)
 GEN_COPY(32)
 #undef GEN_COPY

 #define GEN_COMPARE_BUF( bits )                                       \
 int compare_buf_u ## bits ( uint(bits) const *src_a,                  \
                            uint(bits) const *src_b,                   \
                            unsigned len )                             \
 {                                                                     \
     uint(bits) res = 0;                                               \
     for( ; len; src_a++, src_b++, len-- )                             \
         res |= ( (*src_a) ^ (*src_b) );                               \
     return( res );                                                    \
 }
 GEN_COMPARE_BUF(8)
 GEN_COMPARE_BUF(16)
 GEN_COMPARE_BUF(32)
 #undef GEN_COMPARE_BUF

 #define GEN_PRINT_BUF( bits )                                         \
 void debug_print_buf_u ## bits ( uint(bits) const *buf,               \
                            unsigned entries,                          \
                            const char *prefix )                       \
 {                                                                     \
     unsigned idx;                                                     \
     for( idx = 0; idx < entries; idx += 8 )                           \
     {                                                                 \
         debug_printf( "%s [%#04x-%#04x]: %#04x %#04x %#04x %#04x %#04x %#04x %#04x %#04x\n",        \
                       prefix, idx, idx+8,                             \
                       buf[idx+0], buf[idx+1], buf[idx+2], buf[idx+3], \
                       buf[idx+4], buf[idx+5], buf[idx+6], buf[idx+7] ); \
     }                                                                 \
 }
 GEN_PRINT_BUF(8)
 GEN_PRINT_BUF(16)
 GEN_PRINT_BUF(32)
 #undef GEN_PRINT_BUF

 #define GEN_PRINT_BUF_S( bits )                                       \
 void debug_print_buf_s ## bits ( sint(bits) const *buf,               \
                            unsigned entries,                          \
                            const char *prefix )                       \
 {                                                                     \
     unsigned idx;                                                     \
     for( idx = 0; idx < entries; idx += 8 )                           \
     {                                                                 \
         debug_printf( "%s [%u-%u]: %d %d %d %d %d %d %d %d\n",        \
                       prefix, idx, idx+8,                             \
                       buf[idx+0], buf[idx+1], buf[idx+2], buf[idx+3], \
                       buf[idx+4], buf[idx+5], buf[idx+6], buf[idx+7] ); \
     }                                                                 \
 }
 GEN_PRINT_BUF_S(8)
GEN_PRINT_BUF_S(16)
GEN_PRINT_BUF_S(32)
#undef GEN_PRINT_BUF_S

/* Helper to transpose buffers in case this is needed for  input preparation. */
#define GEN_BUFFER_TRANSPOSE(bitwidth)                                  \
void CONCAT3(buffer_transpose_, u, bitwidth)                            \
    ( uint(bitwidth) *dst, uint(bitwidth) const *src,                   \
      unsigned block_length, unsigned dim_x, unsigned dim_y )           \
{                                                                   \
    unsigned i,j,k,idx_load,idx_store;                              \
                                                                    \
    for( i=0; i<dim_x; i++ )                                        \
    {                                                               \
        for( j=0; j<dim_y; j++ )                                    \
        {                                                           \
            for( k=0; k<block_length; k++ )                         \
            {                                                       \
                idx_load  = block_length * (j*dim_x + i) + k;       \
                idx_store = block_length * (i*dim_y + j) + k;       \
                dst[idx_store] = src[idx_load];                     \
            }                                                       \
        }                                                           \
    }                                                               \
}
GEN_BUFFER_TRANSPOSE(8)
GEN_BUFFER_TRANSPOSE(16)
GEN_BUFFER_TRANSPOSE(32)
#undef GEN_BUFFER_TRANSPOSE
