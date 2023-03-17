/*
 * Copyright (c) 2022 Arm Limited
 * Copyright (c) 2022 Matthias Kannwischer
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

//
// This implementation is based on the public domain implementation of SPHINCS+
// available on https://github.com/sphincs/sphincsplus
//

#include <stdint.h>
#include <string.h>

#include "address.h"
#include "params.h"
#include "fips202x.h"
#include "hashx.h"
#include "f1600x.h"

#define KeccakF1600_StatePermutex keccakx_asm

/*************************************************
 * Name:        load64
 *
 * Description: Load 8 bytes into uint64_t in little-endian order
 *
 * Arguments:   - const uint8_t *x: pointer to input byte array
 *
 * Returns the loaded 64-bit unsigned integer
 **************************************************/
static uint64_t load64(const uint8_t *x) {
    uint64_t r = 0;
    for (size_t i = 0; i < 8; ++i) {
        r |= (uint64_t)x[i] << 8 * i;
    }

    return r;
}

/*************************************************
 * Name:        store64
 *
 * Description: Store a 64-bit integer to a byte array in little-endian order
 *
 * Arguments:   - uint8_t *x: pointer to the output byte array
 *              - uint64_t u: input 64-bit unsigned integer
 **************************************************/
static void store64(uint8_t *x, uint64_t u) {
    for (size_t i = 0; i < 8; ++i) {
        x[i] = (uint8_t) (u >> 8 * i);
    }
}


/*
 * 4-way parallel version of prf_addr; takes 4x as much input and output
 */
void prf_addrx(unsigned char *out[KECCAK_WAY],
                const spx_ctx *ctx,
                const uint32_t addrx[KECCAK_WAY*8]) {
    /* As we write and read only a few quadwords, it is more efficient to
     * build and extract from the five-way SHAKE256 state by hand. */
    // first 2 states interleaved; last three not interleaved
    uint64_t state[KECCAK_WAY*25] = {0};


    for (int i = 0; i < SPX_N/8; i++) {
        uint64_t x = load64(ctx->pub_seed + 8*i);
        for( int j=0; j < KECCAK_WAY; j++ )
            state[STATE_IDX(j,i)] = x;
    }
    for (int i = 0; i < 4; i++) {
        for( int j=0; j < KECCAK_WAY; j++ )
            state[STATE_IDX(j,SPX_N/8 + i)] = (((uint64_t)addrx[j*8+1+2*i]) << 32)
                                              | (uint64_t)addrx[j*8  +2*i];
    }
    for (int i = 0; i < SPX_N/8; i++) {
        uint64_t x = load64(ctx->sk_seed + 8*i);
        for( int j=0; j < KECCAK_WAY; j++ )
            state[STATE_IDX(j, SPX_N/8+i+4)] = x;
    }


    /* SHAKE domain separator and padding. */
    for( int j=0; j < KECCAK_WAY; j++ )
        state[STATE_IDX(j,SPX_N/4+4)] = 0x1f;

    for( int j=0; j < KECCAK_WAY; j++ )
        state[STATE_IDX(j, 16)] = 0x80ll << 56;

    KeccakF1600_StatePermutex(state);

    for (int i = 0; i < SPX_N/8; i++) {
        for( int j=0; j < KECCAK_WAY; j++ )
            store64(out[j] + 8*i, state[STATE_IDX(j,i)]);
    }
}
