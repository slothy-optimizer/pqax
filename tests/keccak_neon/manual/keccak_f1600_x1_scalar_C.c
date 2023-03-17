/*
 * Copyright (c) 2021-2022 Arm Limited
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
// Author: Hanno Becker <hanno.becker@arm.com>
// Author: Matthias Kannwischer <matthias@kannwischer.eu>
//

// Derived from public domain implementation
// in crypto_hash/keccakc512/simple/ from http://bench.cr.yp.to/supercop.html
// by Ronny Van Keer.

#include "keccak_f1600_variants.h"

#define KECCAK_F1600_ROUNDS 24

static const uint64_t round_constants[KECCAK_F1600_ROUNDS] =
{
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
    (uint64_t)0x8000000080008008ULL
};

/* Note: It should not be necessary to use inline assembly here, but
 *       compilers don't seem to reliably detect potential uses of
 *       EOR-with-ROR and BIC-with-ROR at the time of writing.        */

#if defined(inline)
#undef inline
#endif

#define inline __attribute__((unused)) inline

#define GEN_BIC_ROL(imm)                                               \
static inline uint64_t bic_rol_ ## imm ( uint64_t b, uint64_t a )      \
{                                                                      \
    uint64_t res = 0;                                                  \
    __asm ("bic %[result], %[input_a], %[input_b], ROR #(64-" #imm ")" \
           : [result] "=r" (res)                                       \
           : [input_a] "r" (a), [input_b] "r" (b)                      \
    );                                                                 \
    return( res );                                                     \
}

#define GEN_XOR_ROL(imm)                                               \
static inline uint64_t xor_rol_ ## imm ( uint64_t b, uint64_t a )      \
{                                                                      \
    uint64_t res = 0;                                                  \
    __asm ("eor %[result], %[input_a], %[input_b], ROR #(64-" #imm ")" \
           : [result] "=r" (res)                                       \
           : [input_a] "r" (a), [input_b] "r" (b)                      \
    );                                                                 \
    return( res );                                                     \
}

#define GEN_ROL(imm)                                                   \
static inline uint64_t rol_ ## imm ( uint64_t a )                      \
{                                                                      \
    uint64_t res = 0;                                                  \
    __asm ("ROR %[result], %[input_a], #(64-" #imm  ")"                \
           : [result] "=r" (res)                                       \
           : [input_a] "r" (a)                                         \
    );                                                                 \
    return( res );                                                     \
}

#define GEN_ALL(F)                                                         \
    F(0)     F(1)     F(2)     F(3)     F(4)     F(5)     F(6)     F(7)    \
    F(8)     F(9)     F(10)    F(11)    F(12)    F(13)    F(14)    F(15)   \
    F(16)    F(17)    F(18)    F(19)    F(20)    F(21)    F(22)    F(23)   \
    F(24)    F(25)    F(26)    F(27)    F(28)    F(29)    F(30)    F(31)   \
    F(32)    F(33)    F(34)    F(35)    F(36)    F(37)    F(38)    F(39)   \
    F(40)    F(41)    F(42)    F(43)    F(44)    F(45)    F(46)    F(47)   \
    F(48)    F(49)    F(50)    F(51)    F(52)    F(53)    F(54)    F(55)   \
    F(56)    F(57)    F(58)    F(59)    F(60)    F(61)    F(62)    F(63)

GEN_ALL(GEN_BIC_ROL)
GEN_ALL(GEN_ROL)
GEN_ALL(GEN_XOR_ROL)

void keccak_f1600_x1_scalar_C_v0( uint64_t state[KECCAK_F1600_X1_STATE_SIZE_UINT64] )
{
        int round;

        uint64_t Aba, Abe, Abi, Abo, Abu;
        uint64_t Aga, Age, Agi, Ago, Agu;
        uint64_t Aka, Ake, Aki, Ako, Aku;
        uint64_t Ama, Ame, Ami, Amo, Amu;
        uint64_t Asa, Ase, Asi, Aso, Asu;
        uint64_t BCa, BCe, BCi, BCo, BCu;
        uint64_t Da, De, Di, Do, Du;

        uint64_t tmp0, tmp1;

        Aba = state[ 0]; Abe = state[ 1]; Abi = state[ 2]; Abo = state[ 3];
        Abu = state[ 4]; Aga = state[ 5]; Age = state[ 6]; Agi = state[ 7];
        Ago = state[ 8]; Agu = state[ 9]; Aka = state[10]; Ake = state[11];
        Aki = state[12]; Ako = state[13]; Aku = state[14]; Ama = state[15];
        Ame = state[16]; Ami = state[17]; Amo = state[18]; Amu = state[19];
        Asa = state[20]; Ase = state[21]; Asi = state[22]; Aso = state[23];
        Asu = state[24];

        BCa = Aba^Aga^Aka^Ama^Asa;
        BCe = Abe^Age^Ake^Ame^Ase;
        BCi = Abi^Agi^Aki^Ami^Asi;
        BCo = Abo^Ago^Ako^Amo^Aso;
        BCu = Abu^Agu^Aku^Amu^Asu;

        Da =xor_rol_1(BCe,BCu);
        De =xor_rol_1(BCi,BCa);
        Di =xor_rol_1(BCo,BCe);
        Do =xor_rol_1(BCu,BCi);
        Du =xor_rol_1(BCa,BCo);

        tmp0 = Abe;
        Aba  = Aba ^ Da; Abe  = Age ^ De; Age  = Agu ^ Du; Agu  = Asi ^ Di;
        Asi  = Aku ^ Du; Aku  = Asa ^ Da; Asa  = Abi ^ Di; Abi  = Aki ^ Di;
        Aki  = Ako ^ Do; Ako  = Amu ^ Du; Amu  = Aso ^ Do; Aso  = Ama ^ Da;
        Ama  = Abu ^ Du; Abu  = Asu ^ Du; Asu  = Ase ^ De; Ase  = Ago ^ Do;
        Ago  = Ame ^ De; Ame  = Aga ^ Da; Aga  = Abo ^ Do; Abo  = Amo ^ Do;
        Amo  = Ami ^ Di; Ami  = Ake ^ De; Ake  = Agi ^ Di; Agi  = Aka ^ Da;
        Aka  = tmp0 ^ De;

        tmp0 = Aba ^ rol_43(bic_rol_1(Abe, Abi));
        tmp1 = xor_rol_23(Abe,bic_rol_22(Abi, Abo));
        Abi  = xor_rol_29(Abi,bic_rol_7 (Abo, Abu));
        Abo  = xor_rol_21(Abo,bic_rol_14(Abu, Aba));
        Abu  = xor_rol_34(Abu,bic_rol_20(Aba, Abe));
        Aba  = tmp0;
        Abe  = tmp1;

        tmp0 = xor_rol_25(Aga,bic_rol_17(Age, Agi));
        tmp1 = xor_rol_39(Age,bic_rol_22(Agi, Ago));
        Agi  = xor_rol_6(Agi,bic_rol_48(Ago, Agu));
        Ago  = xor_rol_17(Ago,bic_rol_33(Agu, Aga));
        Agu  = xor_rol_41(Agu,bic_rol_8 (Aga, Age));
        Aga  = tmp0;
        Age  = tmp1;

        tmp0 = xor_rol_40(Aka,bic_rol_45(Ake, Aki));
        tmp1 = xor_rol_62(Ake,bic_rol_17(Aki, Ako));
        Aki  = xor_rol_7(Aki,bic_rol_54(Ako, Aku));
        Ako  = xor_rol_7(Ako,bic_rol_17(Aku, Aka));
        Aku  = xor_rol_12(Aku,bic_rol_59(Aka, Ake));
        Aka  = tmp0;
        Ake  = tmp1;

        tmp0 = xor_rol_17(Ama,bic_rol_26(Ame, Ami));
        tmp1 = xor_rol_21(Ame,bic_rol_59(Ami, Amo));
        Ami  = xor_rol_18(Ami,bic_rol_23(Amo, Amu));
        Amo  = xor_rol_52(Amo,bic_rol_29(Amu, Ama));
        Amu  = xor_rol_20(Amu,bic_rol_55(Ama, Ame));
        Ama  = tmp0;
        Ame  = tmp1;

        tmp0 = xor_rol_23(Asa,bic_rol_16(Ase, Asi));
        tmp1 = xor_rol_14(Ase,bic_rol_62(Asi, Aso));
        Asi  = xor_rol_37(Asi,bic_rol_39(Aso, Asu));
        Aso  = xor_rol_43(Aso,bic_rol_4 (Asu, Asa));
        Asu  = xor_rol_11(Asu,bic_rol_7 (Asa, Ase));
        Asa  = tmp0;
        Ase  = tmp1;

        Aba ^= (uint64_t)round_constants[0];

        for(round = 1; round < KECCAK_F1600_ROUNDS; round++ )
        {

            BCa = xor_rol_14( Asa, Aka);
            BCa = xor_rol_15( BCa, Ama );
            BCa = xor_rol_7 ( BCa, Aga );
            BCa = xor_rol_3 ( BCa, Aba );

            BCe = xor_rol_4 ( Age, Ase );
            BCe = xor_rol_20( BCe, Abe );
            BCe = xor_rol_6 ( BCe, Ame );
            BCe = xor_rol_7 ( BCe, Ake );
            BCe = rol_8( BCe );

            BCi = xor_rol_5 ( Agi, Ami );
            BCi = xor_rol_38( BCi, Aki );
            BCi = xor_rol_4 ( BCi, Abi );
            BCi = xor_rol_12( BCi, Asi );
            BCi = rol_2( BCi );

            BCo = xor_rol_34( Aso, Ago );
            BCo = xor_rol_1 ( BCo, Amo );
            BCo = xor_rol_26( BCo, Ako );
            BCo = xor_rol_1 ( BCo, Abo );

            BCu = xor_rol_11( Asu, Abu );
            BCu = xor_rol_8 ( BCu, Amu );
            BCu = xor_rol_16( BCu, Agu );
            BCu = xor_rol_14( BCu, Aku );
            BCu = rol_6( BCu );

            Da =xor_rol_1(BCe,BCu);
            De =xor_rol_1(BCi,BCa);
            Di =xor_rol_1(BCo,BCe);
            Do =xor_rol_1(BCu,BCi);
            Du =xor_rol_1(BCa,BCo);

            tmp0 = Abe;
            Aba  = Aba ^ Da;

            Abe = xor_rol_45(Age,De);
            Age = xor_rol_20(Agu,Du);
            Agu = xor_rol_2 (Asi,Di);
            Asi = xor_rol_6 (Aku,Du);
            Aku = xor_rol_39(Asa,Da);
            Asa = xor_rol_14(Abi,Di);
            Abi = xor_rol_18(Aki,Di);
            Aki = xor_rol_1 (Ako,Do);
            Ako = xor_rol_36(Amu,Du);
            Amu = xor_rol_62(Aso,Do);
            Aso = xor_rol_10(Ama,Da);
            Ama = xor_rol_44(Abu,Du);
            Abu = xor_rol_55(Asu,Du);
            Asu = xor_rol_41(Ase,De);
            Ase = xor_rol_28(Ago,Do);
            Ago = xor_rol_15(Ame,De);
            Ame = xor_rol_3(Aga,Da);
            Aga = Abo ^ Do;
            Abo = xor_rol_27(Amo,Do);
            Amo = xor_rol_56(Ami,Di);
            Ami = xor_rol_8 (Ake,De);
            Ake = xor_rol_61(Agi,Di);
            Agi = xor_rol_25(Aka,Da);
            Aka = xor_rol_21(tmp0, De);

            tmp0 = xor_rol_43(bic_rol_1(Abe, Abi), Aba );
            tmp1 = xor_rol_23(Abe, bic_rol_22(Abi, Abo) );
            Abi  = xor_rol_29(Abi, bic_rol_7 (Abo, Abu) );
            Abo  = xor_rol_21(Abo, bic_rol_14(Abu, Aba) );
            Abu  = xor_rol_34(Abu, bic_rol_20(Aba, Abe) );
            Aba  = tmp0;
            Abe  = tmp1;

            tmp0 = xor_rol_25(Aga, bic_rol_17(Age, Agi) );
            tmp1 = xor_rol_39(Age, bic_rol_22(Agi, Ago) );
            Agi  = xor_rol_6 (Agi, bic_rol_48(Ago, Agu) );
            Ago  = xor_rol_17(Ago, bic_rol_33(Agu, Aga) );
            Agu  = xor_rol_41(Agu, bic_rol_8 (Aga, Age) );
            Aga  = tmp0;
            Age  = tmp1;

            tmp0 = xor_rol_40(Aka, bic_rol_45(Ake, Aki) );
            tmp1 = xor_rol_62(Ake, bic_rol_17(Aki, Ako) );
            Aki  = xor_rol_7 (Aki, bic_rol_54(Ako, Aku) );
            Ako  = xor_rol_7 (Ako, bic_rol_17(Aku, Aka) );
            Aku  = xor_rol_12(Aku, bic_rol_59(Aka, Ake) );
            Aka  = tmp0;
            Ake  = tmp1;

            tmp0 = xor_rol_17(Ama, bic_rol_26(Ame, Ami) );
            tmp1 = xor_rol_21(Ame, bic_rol_59(Ami, Amo) );
            Ami  = xor_rol_18(Ami, bic_rol_23(Amo, Amu) );
            Amo  = xor_rol_52(Amo, bic_rol_29(Amu, Ama) );
            Amu  = xor_rol_20(Amu, bic_rol_55(Ama, Ame) );
            Ama  = tmp0;
            Ame  = tmp1;

            tmp0 = xor_rol_23(Asa, bic_rol_16(Ase, Asi) );
            tmp1 = xor_rol_14(Ase, bic_rol_62(Asi, Aso) );
            Asi  = xor_rol_37(Asi, bic_rol_39(Aso, Asu) );
            Aso  = xor_rol_43(Aso, bic_rol_4 (Asu, Asa) );
            Asu  = xor_rol_11(Asu, bic_rol_7 (Asa, Ase) );
            Asa  = tmp0;
            Ase  = tmp1;

            Aba ^= (uint64_t)round_constants[round];

        }

        Aga = rol_3 (Aga); Aka = rol_25(Aka); Ama = rol_10(Ama); Asa = rol_39(Asa);
        Abe = rol_21(Abe); Age = rol_45(Age); Ake = rol_8 (Ake); Ame = rol_15(Ame);
        Ase = rol_41(Ase); Abi = rol_14(Abi); Agi = rol_61(Agi); Aki = rol_18(Aki);
        Ami = rol_56(Ami); Asi = rol_2 (Asi); Ago = rol_28(Ago); Ako = rol_1 (Ako);
        Amo = rol_27(Amo); Aso = rol_62(Aso); Abu = rol_44(Abu); Agu = rol_20(Agu);
        Aku = rol_6 (Aku); Amu = rol_36(Amu); Asu = rol_55(Asu);

        state[ 0] = Aba; state[ 1] = Abe; state[ 2] = Abi; state[ 3] = Abo;
        state[ 4] = Abu; state[ 5] = Aga; state[ 6] = Age; state[ 7] = Agi;
        state[ 8] = Ago; state[ 9] = Agu; state[10] = Aka; state[11] = Ake;
        state[12] = Aki; state[13] = Ako; state[14] = Aku; state[15] = Ama;
        state[16] = Ame; state[17] = Ami; state[18] = Amo; state[19] = Amu;
        state[20] = Asa; state[21] = Ase; state[22] = Asi; state[23] = Aso;
        state[24] = Asu;
}

void keccak_f1600_x1_scalar_C_v1( uint64_t state[KECCAK_F1600_X1_STATE_SIZE_UINT64] )
{
        int round;

        uint64_t Aba, Abe, Abi, Abo, Abu;
        uint64_t Aga, Age, Agi, Ago, Agu;
        uint64_t Aka, Ake, Aki, Ako, Aku;
        uint64_t Ama, Ame, Ami, Amo, Amu;
        uint64_t Asa, Ase, Asi, Aso, Asu;
        uint64_t BCa, BCe, BCi, BCo, BCu;
        uint64_t Da, De, Di, Do, Du;

        uint64_t tmp0, tmp1;

        Aba = state[ 0]; Abe = state[ 1]; Abi = state[ 2]; Abo = state[ 3];
        Abu = state[ 4]; Aga = state[ 5]; Age = state[ 6]; Agi = state[ 7];
        Ago = state[ 8]; Agu = state[ 9]; Aka = state[10]; Ake = state[11];
        Aki = state[12]; Ako = state[13]; Aku = state[14]; Ama = state[15];
        Ame = state[16]; Ami = state[17]; Amo = state[18]; Amu = state[19];
        Asa = state[20]; Ase = state[21]; Asi = state[22]; Aso = state[23];
        Asu = state[24];

        BCa = Aba^Aga^Aka^Ama^Asa;
        BCe = Abe^Age^Ake^Ame^Ase;
        BCi = Abi^Agi^Aki^Ami^Asi;
        BCo = Abo^Ago^Ako^Amo^Aso;
        BCu = Abu^Agu^Aku^Amu^Asu;

        Da =xor_rol_1(BCe,BCu);
        De =xor_rol_1(BCi,BCa);
        Di =xor_rol_1(BCo,BCe);
        Do =xor_rol_1(BCu,BCi);
        Du =xor_rol_1(BCa,BCo);

        tmp0 = Abu;
        Agu  = Agu  ^ Du; Abu  = Age  ^ De; Age  = Ame  ^ De; Ame  = Ami  ^ Di;
        Ami  = Aso  ^ Do; Aso  = Abi  ^ Di; Abi  = Asu  ^ Du; Asu  = Ago  ^ Do;
        Ago  = Abo  ^ Do; Abo  = Aba  ^ Da; Aba  = Aki  ^ Di; Aki  = Asa  ^ Da;
        Asa  = Aku  ^ Du; Aku  = Agi  ^ Di; Agi  = Asi  ^ Di; Asi  = Ase  ^ De;
        Ase  = Ama  ^ Da; Ama  = Ake  ^ De; Ake  = Amu  ^ Du; Amu  = Aga  ^ Da;
        Aga  = Aka  ^ Da; Aka  = Ako  ^ Do; Ako  = Abe  ^ De; Abe  = Amo  ^ Do;
        Amo  = tmp0 ^ Du;

        tmp0 = bic_rol_1 (Abu,  Aba );
        tmp0 = xor_rol_43(tmp0, Abo );
        tmp1 = bic_rol_22(Aba,  Abe );
        tmp1 = xor_rol_23(Abu,  tmp1);
        Abu  = bic_rol_20(Abo,  Abu );
        Abu  = xor_rol_34(Abi,  Abu );
        Abo  = bic_rol_14(Abi,  Abo );
        Abo  = xor_rol_21(Abe,  Abo );
        Abi  = bic_rol_7 (Abe,  Abi );
        Abi  = xor_rol_29(Aba,  Abi );
        Aba  = tmp0;
        Abe  = tmp1;

        tmp0 = bic_rol_17(Agu, Aga );
        tmp0 = xor_rol_25(Ago, tmp0);
        tmp1 = bic_rol_22(Aga, Age );
        tmp1 = xor_rol_39(Agu, tmp1);
        Agu  = bic_rol_8 (Ago, Agu );
        Agu  = xor_rol_41(Agi, Agu );
        Ago  = bic_rol_33(Agi, Ago );
        Ago  = xor_rol_17(Age, Ago );
        Agi  = bic_rol_48(Age, Agi );
        Agi  = xor_rol_6 (Aga, Agi );
        Aga  = tmp0;
        Age  = tmp1;

        tmp0 = bic_rol_45(Aku, Aka );
        tmp0 = xor_rol_40(Ako, tmp0);
        tmp1 = bic_rol_17(Aka, Ake );
        tmp1 = xor_rol_62(Aku, tmp1);
        Aku  = bic_rol_59(Ako, Aku );
        Aku  = xor_rol_12(Aki, Aku );
        Ako  = bic_rol_17(Aki, Ako );
        Ako  = xor_rol_7 (Ake, Ako );
        Aki  = bic_rol_54(Ake, Aki );
        Aki  = xor_rol_7 (Aka, Aki );
        Aka  = tmp0;
        Ake  = tmp1;

        tmp0 = bic_rol_26(Amu, Ama );
        tmp0 = xor_rol_17(Amo, tmp0);
        tmp1 = bic_rol_59(Ama, Ame );
        tmp1 = xor_rol_21(Amu, tmp1);
        Amu  = bic_rol_55(Amo, Amu );
        Amu  = xor_rol_20(Ami, Amu );
        Amo  = bic_rol_29(Ami, Amo );
        Amo  = xor_rol_52(Ame, Amo );
        Ami  = bic_rol_23(Ame, Ami );
        Ami  = xor_rol_18(Ama, Ami );
        Ama  = tmp0;
        Ame  = tmp1;

        tmp0 = bic_rol_16(Asu, Asa );
        tmp0 = xor_rol_23(Aso, tmp0);
        tmp1 = bic_rol_62(Asa, Ase );
        tmp1 = xor_rol_14(Asu, tmp1);
        Asu  = bic_rol_7 (Aso, Asu );
        Asu  = xor_rol_11(Asi, Asu );
        Aso  = bic_rol_4 (Asi, Aso );
        Aso  = xor_rol_43(Ase, Aso );
        Asi  = bic_rol_39(Ase, Asi );
        Asi  = xor_rol_37(Asa, Asi );
        Asa  = tmp0;
        Ase  = tmp1;

        Aba ^= (uint64_t)round_constants[0];

        for(round = 1; round < KECCAK_F1600_ROUNDS; round++ ) {

            BCa = xor_rol_14( Asa, Aka);
            BCe = xor_rol_4 ( Age, Ase );
            BCi = xor_rol_5 ( Agi, Ami );
            BCo = xor_rol_34( Aso, Ago );
            BCu = xor_rol_11( Asu, Abu );

            BCa = xor_rol_15( BCa, Ama );
            BCe = xor_rol_20( BCe, Abe );
            BCi = xor_rol_38( BCi, Aki );
            BCo = xor_rol_1 ( BCo, Amo );
            BCa = xor_rol_7 ( BCa, Aga );
            BCu = xor_rol_8 ( BCu, Amu );

            BCa = xor_rol_3 ( BCa, Aba );
            BCe = xor_rol_6 ( BCe, Ame );
            BCi = xor_rol_4 ( BCi, Abi );
            BCo = xor_rol_26( BCo, Ako );
            BCu = xor_rol_16( BCu, Agu );

            BCe = xor_rol_7 ( BCe, Ake );
            BCi = xor_rol_12( BCi, Asi );
            BCo = xor_rol_1 ( BCo, Abo );
            BCu = xor_rol_14( BCu, Aku );

            BCe = rol_8( BCe );
            BCi = rol_2( BCi );
            BCu = rol_6( BCu );

            Da = xor_rol_1(BCe,BCu);
            De = xor_rol_1(BCi,BCa);
            Di = xor_rol_1(BCo,BCe);
            Do = xor_rol_1(BCu,BCi);
            Du = xor_rol_1(BCa,BCo);

            Agu = xor_rol_20(Agu,Du);
            tmp0 = Abu;
            Abu = xor_rol_45(Age,De);
            Age = xor_rol_15(Ame,De);
            Ame = xor_rol_56(Ami,Di);
            Ami = xor_rol_62(Aso,Do);
            Aso = xor_rol_14(Abi,Di);
            Abi = xor_rol_55(Asu,Du);
            Asu = xor_rol_28(Ago,Do);
            Ago = Abo ^ Do;
            Abo = Aba ^ Da;
            Aba = xor_rol_18(Aki,Di);
            Aki = xor_rol_39(Asa,Da);
            Asa = xor_rol_6 (Aku,Du);
            Aku = xor_rol_61(Agi,Di);
            Agi = xor_rol_2 (Asi,Di);
            Asi = xor_rol_41(Ase,De);
            Ase = xor_rol_10(Ama,Da);
            Ama = xor_rol_8 (Ake,De);
            Ake = xor_rol_36(Amu,Du);
            Amu = xor_rol_3(Aga,Da);
            Aga = xor_rol_25(Aka,Da);
            Aka = xor_rol_1 (Ako,Do);
            Ako = xor_rol_21(Abe,De);
            Abe = xor_rol_27(Amo,Do);
            Amo = xor_rol_44(tmp0,Du);


            tmp0 = bic_rol_1 (Abu,  Aba );
            tmp0 = xor_rol_43(tmp0, Abo );
            tmp1 = bic_rol_22(Aba,  Abe );
            tmp1 = xor_rol_23(Abu,  tmp1);
            Abu  = bic_rol_20(Abo,  Abu );
            Abu  = xor_rol_34(Abi,  Abu );
            Abo  = bic_rol_14(Abi,  Abo );
            Abo  = xor_rol_21(Abe,  Abo );
            Abi  = bic_rol_7 (Abe,  Abi );
            Abi  = xor_rol_29(Aba,  Abi );
            Aba  = tmp0;
            Abe  = tmp1;

            tmp0 = bic_rol_17(Agu, Aga );
            tmp0 = xor_rol_25(Ago, tmp0);
            tmp1 = bic_rol_22(Aga, Age );
            tmp1 = xor_rol_39(Agu, tmp1);
            Agu  = bic_rol_8 (Ago, Agu );
            Agu  = xor_rol_41(Agi, Agu );
            Ago  = bic_rol_33(Agi, Ago );
            Ago  = xor_rol_17(Age, Ago );
            Agi  = bic_rol_48(Age, Agi );
            Agi  = xor_rol_6 (Aga, Agi );
            Aga  = tmp0;
            Age  = tmp1;

            tmp0 = bic_rol_45(Aku, Aka );
            tmp0 = xor_rol_40(Ako, tmp0);
            tmp1 = bic_rol_17(Aka, Ake );
            tmp1 = xor_rol_62(Aku, tmp1);
            Aku  = bic_rol_59(Ako, Aku );
            Aku  = xor_rol_12(Aki, Aku );
            Ako  = bic_rol_17(Aki, Ako );
            Ako  = xor_rol_7 (Ake, Ako );
            Aki  = bic_rol_54(Ake, Aki );
            Aki  = xor_rol_7 (Aka, Aki );
            Aka  = tmp0;
            Ake  = tmp1;

            tmp0 = bic_rol_26(Amu, Ama );
            tmp0 = xor_rol_17(Amo, tmp0);
            tmp1 = bic_rol_59(Ama, Ame );
            tmp1 = xor_rol_21(Amu, tmp1);
            Amu  = bic_rol_55(Amo, Amu );
            Amu  = xor_rol_20(Ami, Amu );
            Amo  = bic_rol_29(Ami, Amo );
            Amo  = xor_rol_52(Ame, Amo );
            Ami  = bic_rol_23(Ame, Ami );
            Ami  = xor_rol_18(Ama, Ami );
            Ama  = tmp0;
            Ame  = tmp1;

            tmp0 = bic_rol_16(Asu, Asa );
            tmp0 = xor_rol_23(Aso, tmp0);
            tmp1 = bic_rol_62(Asa, Ase );
            tmp1 = xor_rol_14(Asu, tmp1);
            Asu  = bic_rol_7 (Aso, Asu );
            Asu  = xor_rol_11(Asi, Asu );
            Aso  = bic_rol_4 (Asi, Aso );
            Aso  = xor_rol_43(Ase, Aso );
            Asi  = bic_rol_39(Ase, Asi );
            Asi  = xor_rol_37(Asa, Asi );
            Asa  = tmp0;
            Ase  = tmp1;

            Aba ^= (uint64_t)round_constants[round];

        }

        Aga = rol_3 (Aga); Aka = rol_25(Aka); Ama = rol_10(Ama); Asa = rol_39(Asa);
        Abe = rol_21(Abe); Age = rol_45(Age); Ake = rol_8 (Ake); Ame = rol_15(Ame);
        Ase = rol_41(Ase); Abi = rol_14(Abi); Agi = rol_61(Agi); Aki = rol_18(Aki);
        Ami = rol_56(Ami); Asi = rol_2 (Asi); Ago = rol_28(Ago); Ako = rol_1 (Ako);
        Amo = rol_27(Amo); Aso = rol_62(Aso); Abu = rol_44(Abu); Agu = rol_20(Agu);
        Aku = rol_6 (Aku); Amu = rol_36(Amu); Asu = rol_55(Asu);

        state[ 0] = Aba; state[ 1] = Abe; state[ 2] = Abi; state[ 3] = Abo;
        state[ 4] = Abu; state[ 5] = Aga; state[ 6] = Age; state[ 7] = Agi;
        state[ 8] = Ago; state[ 9] = Agu; state[10] = Aka; state[11] = Ake;
        state[12] = Aki; state[13] = Ako; state[14] = Aku; state[15] = Ama;
        state[16] = Ame; state[17] = Ami; state[18] = Amo; state[19] = Amu;
        state[20] = Asa; state[21] = Ase; state[22] = Asi; state[23] = Aso;
        state[24] = Asu;
}
