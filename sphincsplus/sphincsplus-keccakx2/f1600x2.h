#ifndef SPX_F1600X2_H
#define SPX_F1600X2_H

#include <stdint.h>

#if defined(KECCAK_X2_IMPL_C)
void keccak_f1600_x2_C(uint64_t state[2*25]);
#define f1600x2(s) keccak_f1600_x2_scalar_C(s)
#elif defined(KECCAK_X2_IMPL_COTHAN)
#include <arm_neon.h>
void keccak_f1600_x2_neon_C_cothan(uint64_t state[2*25]);
#define f1600x2(s) keccak_f1600_x2_neon_C_cothan(s)
#elif defined(KECCAK_X2_IMPL_BAS)
extern void keccak_f1600_x2_bas(uint64_t* a);
#define f1600x2(s) keccak_f1600_x2_bas(s)
#endif

#endif
