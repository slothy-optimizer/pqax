#include "neonntt_params.h"
#include <stdint.h>

#define KYBER_NAMESPACE(s) PQCLEAN_KYBER768_AARCH64_##s

#define asymmetric_const KYBER_NAMESPACE(asymmetric_const)
#define constants KYBER_NAMESPACE(constants)
#define streamlined_CT_negacyclic_table_Q1_jump_extended KYBER_NAMESPACE(streamlined_CT_negacyclic_table_Q1_jump_extended)
#define pre_asymmetric_table_Q1_extended KYBER_NAMESPACE(pre_asymmetric_table_Q1_extended)
#define streamlined_inv_GS_negacyclic_table_Q1_jump_extended KYBER_NAMESPACE(streamlined_inv_GS_negacyclic_table_Q1_jump_extended)

extern void PQCLEAN_KYBER768_AARCH64__asm_ntt_SIMD_top(int16_t *, const int16_t *, const int16_t *);
extern void PQCLEAN_KYBER768_AARCH64__asm_ntt_SIMD_bot(int16_t *, const int16_t *, const int16_t *);

extern void PQCLEAN_KYBER768_AARCH64__asm_intt_SIMD_bot(int16_t *, const int16_t *, const int16_t *);
extern void PQCLEAN_KYBER768_AARCH64__asm_intt_SIMD_top(int16_t *, const int16_t *, const int16_t *);

extern void PQCLEAN_KYBER768_AARCH64__asm_point_mul_extended(int16_t *, const int16_t *, const int16_t *, const int16_t *);
extern void PQCLEAN_KYBER768_AARCH64__asm_asymmetric_mul(const int16_t *, const int16_t *, const int16_t *, const int16_t *, int16_t *);
extern void PQCLEAN_KYBER768_AARCH64__asm_asymmetric_mul_montgomery(const int16_t *, const int16_t *, const int16_t *, const int16_t *, int16_t *);

extern
const int16_t asymmetric_const[8];
extern
const int16_t constants[16];

extern
const int16_t streamlined_CT_negacyclic_table_Q1_jump_extended[((NTT_N - 1) + (1 << 0) + (1 << 4) + NTT_N) << 1];

extern
const int16_t pre_asymmetric_table_Q1_extended[ARRAY_N];

extern
const int16_t streamlined_inv_GS_negacyclic_table_Q1_jump_extended[((NTT_N - 1) + (1 << 0) + (1 << 4) + NTT_N) << 1];

#define pqclean_NTT(in) do { \
        PQCLEAN_KYBER768_AARCH64__asm_ntt_SIMD_top(in, streamlined_CT_negacyclic_table_Q1_jump_extended, constants); \
        PQCLEAN_KYBER768_AARCH64__asm_ntt_SIMD_bot(in, streamlined_CT_negacyclic_table_Q1_jump_extended, constants); \
    } while(0)

#define pqclean_iNTT(in) do { \
        PQCLEAN_KYBER768_AARCH64__asm_intt_SIMD_bot(in, streamlined_inv_GS_negacyclic_table_Q1_jump_extended, constants); \
        PQCLEAN_KYBER768_AARCH64__asm_intt_SIMD_top(in, streamlined_inv_GS_negacyclic_table_Q1_jump_extended, constants); \
    } while(0)

#define pqclean_ntt KYBER_NAMESPACE(pqclean_ntt)
void pqclean_ntt(int16_t r[256]);
#define pqclean_invntt KYBER_NAMESPACE(pqclean_invntt)
void pqclean_invntt(int16_t r[256]);