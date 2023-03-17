/*=============================================================================
 * Copyright (c) 2020 by Cryptographic Engineering Research Group (CERG)
 * ECE Department, George Mason University
 * Fairfax, VA, U.S.A.
 * Author: Duc Tri Nguyen
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=============================================================================*/
#include <arm_neon.h>
#include <stddef.h>

#include "../keccak_f1600_variants.h"

#define NROUNDS 24
#define SHA3 0

#define SHAKE128_RATE 168
#define SHAKE256_RATE 136
#define SHA3_256_RATE 136
#define SHA3_512_RATE 72

/*
 * Using vld1q_u64_x4 is consider harmful
 */
#ifndef MEM
#define MEM 0
#endif

// Define NEON operation

// Bitwise-XOR: c = a ^ b
#define vxor(c, a, b) c = veorq_u64(a, b);

#define pack(out, a, b, c, d) \
  out.val[0] = a;             \
  out.val[1] = b;             \
  out.val[2] = c;             \
  out.val[3] = d;

#define unpack(a, b, c, d, out) \
  a = out.val[0];               \
  b = out.val[1];               \
  c = out.val[2];               \
  d = out.val[3];

#if SHA3 == 1

/*
 * At least ARMv8.2-sha3 supported
 */

// Xor chain: out = a ^ b ^ c ^ d ^ e
#define vXOR5(out, a, b, c, d, e) \
  out = veor3q_u64(a, b, c);      \
  out = veor3q_u64(out, d, e);

// Rotate left by 1 bit, then XOR: a ^ ROL(b)
#define vRXOR(c, a, b) c = vrax1q_u64(a, b);

// XOR then Rotate by n bit: c = ROL(a^b, n)
#define vXORR(c, a, b, n) c = vxarq_u64(a, b, n);

// Xor Not And: out = a ^ ( (~b) & c)
#define vXNA(out, a, b, c) out = vbcaxq_u64(a, c, b);

#else

// Rotate left by n bit
#define vROL(out, a, offset)      \
  out = vshlq_n_u64(a, (offset)); \
  out = vsriq_n_u64(out, a, 64 - (offset));

// Xor chain: out = a ^ b ^ c ^ d ^ e
#define vXOR5(out, a, b, c, d, e) \
  out = veorq_u64(a, b);          \
  out = veorq_u64(out, c);        \
  out = veorq_u64(out, d);        \
  out = veorq_u64(out, e);

// Xor Not And: out = a ^ ( (~b) & c)
#define vXNA(out, a, b, c) \
  out = vbicq_u64(c, b);   \
  out = veorq_u64(out, a);

#define vRXOR(c, a, b) \
  vROL(c, b, 1);       \
  vxor(c, c, a);

#define vXORR(c, a, b, n) \
  a = veorq_u64(a, b);    \
  vROL(c, a, 64 - n);

#endif

// End

/* Keccak round constants */
static const uint64_t neon_KeccakF_RoundConstants[NROUNDS] = {
    (uint64_t)0x0000000000000001ULL,
    (uint64_t)0x0000000000008082ULL,
    (uint64_t)0x800000000000808aULL,
    (uint64_t)0x8000000080008000ULL,
    (uint64_t)0x000000000000808bULL,
    (uint64_t)0x0000000080000001ULL,
    (uint64_t)0x8000000080008081ULL,
    (uint64_t)0x8000000000008009ULL,
    (uint64_t)0x000000000000008aULL,
    (uint64_t)0x0000000000000088ULL,
    (uint64_t)0x0000000080008009ULL,
    (uint64_t)0x000000008000000aULL,
    (uint64_t)0x000000008000808bULL,
    (uint64_t)0x800000000000008bULL,
    (uint64_t)0x8000000000008089ULL,
    (uint64_t)0x8000000000008003ULL,
    (uint64_t)0x8000000000008002ULL,
    (uint64_t)0x8000000000000080ULL,
    (uint64_t)0x000000000000800aULL,
    (uint64_t)0x800000008000000aULL,
    (uint64_t)0x8000000080008081ULL,
    (uint64_t)0x8000000000008080ULL,
    (uint64_t)0x0000000080000001ULL,
    (uint64_t)0x8000000080008008ULL};

/*************************************************
 * Name:        KeccakF1600_StatePermutex2
 *
 * Description: The Keccak F1600 Permutation
 *
 * Arguments:   - v128 *state: pointer to input/output Keccak state
 **************************************************/
void keccak_f1600_x2_neon_C_cothan(v128 state[25])
{
  v128 Aba, Abe, Abi, Abo, Abu;
  v128 Aga, Age, Agi, Ago, Agu;
  v128 Aka, Ake, Aki, Ako, Aku;
  v128 Ama, Ame, Ami, Amo, Amu;
  v128 Asa, Ase, Asi, Aso, Asu;
  v128 BCa, BCe, BCi, BCo, BCu; // tmp
  v128 Da, De, Di, Do, Du;      // D
  v128 Eba, Ebe, Ebi, Ebo, Ebu;
  v128 Ega, Ege, Egi, Ego, Egu;
  v128 Eka, Eke, Eki, Eko, Eku;
  v128 Ema, Eme, Emi, Emo, Emu;
  v128 Esa, Ese, Esi, Eso, Esu;

#if MEM == 1
  uint64x2x4_t holder;

  holder = vld1q_u64_x4((uint64_t *)&state[0]);
  unpack(Aba, Abe, Abi, Abo, holder);

  holder = vld1q_u64_x4((uint64_t *)&state[4]);
  unpack(Abu, Aga, Age, Agi, holder);

  holder = vld1q_u64_x4((uint64_t *)&state[8]);
  unpack(Ago, Agu, Aka, Ake, holder);

  holder = vld1q_u64_x4((uint64_t *)&state[12]);
  unpack(Aki, Ako, Aku, Ama, holder);

  holder = vld1q_u64_x4((uint64_t *)&state[16]);
  unpack(Ame, Ami, Amo, Amu, holder);

  holder = vld1q_u64_x4((uint64_t *)&state[20]);
  unpack(Asa, Ase, Asi, Aso, holder);

  Asu = vld1q_u64((uint64_t *)&state[24]);
#else
  Aba = state[0];
  Abe = state[1];
  Abi = state[2];
  Abo = state[3];
  Abu = state[4];
  Aga = state[5];
  Age = state[6];
  Agi = state[7];
  Ago = state[8];
  Agu = state[9];
  Aka = state[10];
  Ake = state[11];
  Aki = state[12];
  Ako = state[13];
  Aku = state[14];
  Ama = state[15];
  Ame = state[16];
  Ami = state[17];
  Amo = state[18];
  Amu = state[19];
  Asa = state[20];
  Ase = state[21];
  Asi = state[22];
  Aso = state[23];
  Asu = state[24];
#endif

  for (int round = 0; round < NROUNDS; round += 2)
  {
    //    prepareTheta
    vXOR5(BCa, Aba, Aga, Aka, Ama, Asa);
    vXOR5(BCe, Abe, Age, Ake, Ame, Ase);
    vXOR5(BCi, Abi, Agi, Aki, Ami, Asi);
    vXOR5(BCo, Abo, Ago, Ako, Amo, Aso);
    vXOR5(BCu, Abu, Agu, Aku, Amu, Asu);

    vRXOR(Da, BCu, BCe);
    vRXOR(De, BCa, BCi);
    vRXOR(Di, BCe, BCo);
    vRXOR(Do, BCi, BCu);
    vRXOR(Du, BCo, BCa);

    vxor(Aba, Aba, Da);
    vXORR(BCe, Age, De, 20);
    vXORR(BCi, Aki, Di, 21);
    vXORR(BCo, Amo, Do, 43);
    vXORR(BCu, Asu, Du, 50);

    vXNA(Eba, Aba, BCe, BCi);
    vxor(Eba, Eba, vld1q_dup_u64(&neon_KeccakF_RoundConstants[round]));
    vXNA(Ebe, BCe, BCi, BCo);
    vXNA(Ebi, BCi, BCo, BCu);
    vXNA(Ebo, BCo, BCu, Aba);
    vXNA(Ebu, BCu, Aba, BCe);

    vXORR(BCa, Abo, Do, 36);
    vXORR(BCe, Agu, Du, 44);
    vXORR(BCi, Aka, Da, 61);
    vXORR(BCo, Ame, De, 19);
    vXORR(BCu, Asi, Di, 3);

    vXNA(Ega, BCa, BCe, BCi);
    vXNA(Ege, BCe, BCi, BCo);
    vXNA(Egi, BCi, BCo, BCu);
    vXNA(Ego, BCo, BCu, BCa);
    vXNA(Egu, BCu, BCa, BCe);

    vXORR(BCa, Abe, De, 63);
    vXORR(BCe, Agi, Di, 58);
    vXORR(BCi, Ako, Do, 39);
    vXORR(BCo, Amu, Du, 56);
    vXORR(BCu, Asa, Da, 46);

    vXNA(Eka, BCa, BCe, BCi);
    vXNA(Eke, BCe, BCi, BCo);
    vXNA(Eki, BCi, BCo, BCu);
    vXNA(Eko, BCo, BCu, BCa);
    vXNA(Eku, BCu, BCa, BCe);

    vXORR(BCa, Abu, Du, 37);
    vXORR(BCe, Aga, Da, 28);
    vXORR(BCi, Ake, De, 54);
    vXORR(BCo, Ami, Di, 49);
    vXORR(BCu, Aso, Do, 8);

    vXNA(Ema, BCa, BCe, BCi);
    vXNA(Eme, BCe, BCi, BCo);
    vXNA(Emi, BCi, BCo, BCu);
    vXNA(Emo, BCo, BCu, BCa);
    vXNA(Emu, BCu, BCa, BCe);

    vXORR(BCa, Abi, Di, 2);
    vXORR(BCe, Ago, Do, 9);
    vXORR(BCi, Aku, Du, 25);
    vXORR(BCo, Ama, Da, 23);
    vXORR(BCu, Ase, De, 62);

    vXNA(Esa, BCa, BCe, BCi);
    vXNA(Ese, BCe, BCi, BCo);
    vXNA(Esi, BCi, BCo, BCu);
    vXNA(Eso, BCo, BCu, BCa);
    vXNA(Esu, BCu, BCa, BCe);

    // Next Round

    //    prepareTheta
    vXOR5(BCa, Eba, Ega, Eka, Ema, Esa);
    vXOR5(BCe, Ebe, Ege, Eke, Eme, Ese);
    vXOR5(BCi, Ebi, Egi, Eki, Emi, Esi);
    vXOR5(BCo, Ebo, Ego, Eko, Emo, Eso);
    vXOR5(BCu, Ebu, Egu, Eku, Emu, Esu);

    // thetaRhoPiChiIotaPrepareTheta(round+1, E, A)
    vRXOR(Da, BCu, BCe);
    vRXOR(De, BCa, BCi);
    vRXOR(Di, BCe, BCo);
    vRXOR(Do, BCi, BCu);
    vRXOR(Du, BCo, BCa);

    vxor(Eba, Eba, Da);
    vXORR(BCe, Ege, De, 20);
    vXORR(BCi, Eki, Di, 21);
    vXORR(BCo, Emo, Do, 43);
    vXORR(BCu, Esu, Du, 50);

    vXNA(Aba, Eba, BCe, BCi);
    vxor(Aba, Aba, vld1q_dup_u64(&neon_KeccakF_RoundConstants[round + 1]));
    vXNA(Abe, BCe, BCi, BCo);
    vXNA(Abi, BCi, BCo, BCu);
    vXNA(Abo, BCo, BCu, Eba);
    vXNA(Abu, BCu, Eba, BCe);

    vXORR(BCa, Ebo, Do, 36);
    vXORR(BCe, Egu, Du, 44);
    vXORR(BCi, Eka, Da, 61);
    vXORR(BCo, Eme, De, 19);
    vXORR(BCu, Esi, Di, 3);

    vXNA(Aga, BCa, BCe, BCi);
    vXNA(Age, BCe, BCi, BCo);
    vXNA(Agi, BCi, BCo, BCu);
    vXNA(Ago, BCo, BCu, BCa);
    vXNA(Agu, BCu, BCa, BCe);

    vXORR(BCa, Ebe, De, 63);
    vXORR(BCe, Egi, Di, 58);
    vXORR(BCi, Eko, Do, 39);
    vXORR(BCo, Emu, Du, 56);
    vXORR(BCu, Esa, Da, 46);

    vXNA(Aka, BCa, BCe, BCi);
    vXNA(Ake, BCe, BCi, BCo);
    vXNA(Aki, BCi, BCo, BCu);
    vXNA(Ako, BCo, BCu, BCa);
    vXNA(Aku, BCu, BCa, BCe);

    vXORR(BCa, Ebu, Du, 37);
    vXORR(BCe, Ega, Da, 28);
    vXORR(BCi, Eke, De, 54);
    vXORR(BCo, Emi, Di, 49);
    vXORR(BCu, Eso, Do, 8);

    vXNA(Ama, BCa, BCe, BCi);
    vXNA(Ame, BCe, BCi, BCo);
    vXNA(Ami, BCi, BCo, BCu);
    vXNA(Amo, BCo, BCu, BCa);
    vXNA(Amu, BCu, BCa, BCe);

    vXORR(BCa, Ebi, Di, 2);
    vXORR(BCe, Ego, Do, 9);
    vXORR(BCi, Eku, Du, 25);
    vXORR(BCo, Ema, Da, 23);
    vXORR(BCu, Ese, De, 62);

    vXNA(Asa, BCa, BCe, BCi);
    vXNA(Ase, BCe, BCi, BCo);
    vXNA(Asi, BCi, BCo, BCu);
    vXNA(Aso, BCo, BCu, BCa);
    vXNA(Asu, BCu, BCa, BCe);
  }

#if MEM == 1
  pack(holder, Aba, Abe, Abi, Abo);
  vst1q_u64_x4((uint64_t *)&state[0], holder);

  pack(holder, Abu, Aga, Age, Agi);
  vst1q_u64_x4((uint64_t *)&state[4], holder);

  pack(holder, Ago, Agu, Aka, Ake);
  vst1q_u64_x4((uint64_t *)&state[8], holder);

  pack(holder, Aki, Ako, Aku, Ama);
  vst1q_u64_x4((uint64_t *)&state[12], holder);

  pack(holder, Ame, Ami, Amo, Amu);
  vst1q_u64_x4((uint64_t *)&state[16], holder);

  pack(holder, Asa, Ase, Asi, Aso);
  vst1q_u64_x4((uint64_t *)&state[20], holder);

  vst1q_u64((uint64_t *)&state[24], Asu);
#else
  state[0] = Aba;
  state[1] = Abe;
  state[2] = Abi;
  state[3] = Abo;
  state[4] = Abu;
  state[5] = Aga;
  state[6] = Age;
  state[7] = Agi;
  state[8] = Ago;
  state[9] = Agu;
  state[10] = Aka;
  state[11] = Ake;
  state[12] = Aki;
  state[13] = Ako;
  state[14] = Aku;
  state[15] = Ama;
  state[16] = Ame;
  state[17] = Ami;
  state[18] = Amo;
  state[19] = Amu;
  state[20] = Asa;
  state[21] = Ase;
  state[22] = Asi;
  state[23] = Aso;
  state[24] = Asu;
#endif
}
