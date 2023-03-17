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
#include <assert.h>

#include "fips202.h"
#include "fips202x.h"
#include "f1600x.h"

#define NROUNDS 24
#define ROL(a, offset) ((a << offset) ^ (a >> (64-offset)))

static uint64_t load64(const unsigned char *x)
{
  unsigned long long r = 0, i;

  for (i = 0; i < 8; ++i) {
    r |= (unsigned long long)x[i] << 8 * i;
  }
  return r;
}

static void store64(uint8_t *x, uint64_t u)
{
  unsigned int i;

  for(i=0; i<8; ++i) {
    x[i] = u;
    u >>= 8;
  }
}




#define KeccakF1600_StatePermutex keccakx_asm

static void keccak_absorbx(uint64_t s[KECCAK_WAY*25],
                           unsigned int r,
                           unsigned char const * m[KECCAK_WAY],
                           unsigned long long int mlen,
                           unsigned char p)
{
  unsigned long long i;
  unsigned char t[KECCAK_WAY][200];

  while (mlen >= r)
  {
    for (i = 0; i < r / 8; ++i)
    {
        for( int j=0; j < KECCAK_WAY; j++ )
            s[STATE_IDX(j,i)] ^= load64(m[j] + 8 * i);
    }

    KeccakF1600_StatePermutex(s);
    mlen -= r;
    for( int j=0; j < KECCAK_WAY; j++ )
        m[j] += r;
  }

  for( int j=0; j < KECCAK_WAY; j++ )
  {
      for (i = 0; i < r; ++i)
          t[j][i] = 0;
      for (i = 0; i < mlen; ++i)
          t[j][i] = m[j][i];
      t[j][i] = p;
      t[j][r - 1] |= 128;
  }

  for (i = 0; i < r / 8; ++i)
  {
    for( int j=0; j < KECCAK_WAY; j++ )
        s[STATE_IDX(j,i)]  ^= load64(t[j] + 8 * i);
  }
}


static void keccak_squeezeblocksx(unsigned char * h[KECCAK_WAY],
                                  unsigned long long int nblocks,
                                  uint64_t s[KECCAK_WAY*25],
                                  unsigned int r)
{
  unsigned int i;

  while(nblocks > 0)
  {
      KeccakF1600_StatePermutex(s);
      for(i=0;i<(r>>3);i++)
      {
          for( int j=0; j < KECCAK_WAY; j++ )
              store64(h[j]+8*i, s[STATE_IDX(j,i)]);
      }
      for( int j=0; j < KECCAK_WAY; j++ )
          h[j] += r;
      nblocks--;
  }
}



void shake128x(unsigned char       * const out[KECCAK_WAY], unsigned long long outlen,
               unsigned char const * const in [KECCAK_WAY], unsigned long long inlen)
{
  uint64_t s[KECCAK_WAY*25];
  unsigned char t[KECCAK_WAY][SHAKE128_RATE];
  unsigned char *t_ptr[KECCAK_WAY];
  unsigned char const * inc [KECCAK_WAY];
  unsigned char       * outc[KECCAK_WAY];
  for( int j=0; j<KECCAK_WAY; j++ )
  {
      /* keccak_absorbx and keccak_squeezeblocksx shift the input
       * pointers, but in/out are const arrays for uniformity with
       * the non-batched SHAKE API.
       *
       * Note that this, ultimately, shouldn't be any less efficient --
       * we're basically making explicit that the input addresses have
       * to be loaded from memory into local variables (registers). */
      inc[j]   = in[j];
      outc[j]  = out[j];
      t_ptr[j] = &t[j][0];
  }

  unsigned int i;

  /* zero state */
  for(i=0;i<KECCAK_WAY*25;i++)
    s[i] = 0;

  /* absorb N message of identical length in parallel */
  keccak_absorbx(s, SHAKE128_RATE, inc, inlen, 0x1F);

  /* Squeeze output */
  keccak_squeezeblocksx(outc, outlen/SHAKE128_RATE, s, SHAKE128_RATE);

  if(outlen%SHAKE128_RATE)
  {
    keccak_squeezeblocksx(t_ptr, 1, s, SHAKE128_RATE);
    for(i=0;i<outlen%SHAKE128_RATE;i++)
        for( int j=0; j < KECCAK_WAY; j++ )
            outc[j][i] = t[j][i];
  }
}


void shake256x(unsigned char       * const out[KECCAK_WAY], unsigned long long outlen,
               unsigned char const * const in [KECCAK_WAY], unsigned long long inlen)
{
  uint64_t s[KECCAK_WAY*25];
  unsigned char t[KECCAK_WAY][SHAKE256_RATE];

  unsigned char *t_ptr[KECCAK_WAY];
  unsigned char const * inc [KECCAK_WAY];
  unsigned char       * outc[KECCAK_WAY];
  for( int j=0; j<KECCAK_WAY; j++ )
  {
      /* keccak_absorbx and keccak_squeezeblocksx shift the input
       * pointers, but in/out are const arrays for uniformity with
       * the non-batched SHAKE API.
       *
       * Note that this, ultimately, shouldn't be any less efficient --
       * we're basically making explicit that the input addresses have
       * to be loaded from memory into local variables (registers). */
      inc[j]   = in[j];
      outc[j]  = out[j];
      t_ptr[j] = &t[j][0];
  }

  unsigned int i;

  /* zero state */
  for(i=0;i<KECCAK_WAY*25;i++)
    s[i] = 0;

  /* absorb KECCAK_WAY message of identical length in parallel */
  keccak_absorbx(s, SHAKE256_RATE, inc, inlen, 0x1F);

  /* Squeeze output */
  keccak_squeezeblocksx(outc, outlen/SHAKE256_RATE, s, SHAKE256_RATE);

  if(outlen%SHAKE256_RATE)
  {
      keccak_squeezeblocksx(t_ptr, 1, s, SHAKE256_RATE);
      for(i=0;i<outlen%SHAKE256_RATE;i++)
          for( int j=0; j < KECCAK_WAY; j++ )
              outc[j][i] = t[j][i];
  }
}
