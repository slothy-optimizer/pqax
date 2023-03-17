/*
 * Test for Lenngren's X25519 scalar multiplication implementation
 * https://github.com/Emill/X25519-AArch64
 */

#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <hal.h>
#include <misc.h>
#include <poly.h>

#define WARMUP_ITERATIONS  2
#define ITER_PER_TEST      100
#define TEST_COUNT        10


// Assembler functions

typedef void (*x25519_scalarmult_t)(unsigned char result[32],
                                     const unsigned char scalar[32],
                                     const unsigned char point[32]);

void x25519_scalarmult(unsigned char result[32],
                       const unsigned char scalar[32],
                       const unsigned char point[32]);

void x25519_scalarmult_alt_orig(unsigned char result[32],
                           const unsigned char scalar[32],
                           const unsigned char point[32]);

void x25519_scalarmult_opt(unsigned char result[32],
                                const unsigned char scalar[32],
                                const unsigned char point[32]);

static void x25519_do_all( unsigned char ss_alice[32],
                           unsigned char ss_bob  [32],
                           unsigned char sk_alice[32],
                           unsigned char sk_bob  [32],
                           x25519_scalarmult_t func)

{
    static const unsigned char basepoint[32] = {9};
    unsigned char pk_alice[32], pk_bob[32];
    func(pk_alice, sk_alice, basepoint);
    func(pk_bob, sk_bob, basepoint);
    func(ss_alice, sk_alice, pk_bob);
    func(ss_bob, sk_bob, pk_alice);
}

int test_x25519_kex()
{
    unsigned char sk_alice[32], sk_bob[32];
    unsigned char ss_alice[32], ss_bob[32];
    debug_test_start("X25519 key exchange test");

    fill_random_u8(sk_alice, 32);
    fill_random_u8(sk_bob, 32);

    x25519_do_all( ss_alice, ss_bob, sk_alice, sk_bob, x25519_scalarmult );
    if( compare_buf_u8( ss_alice, ss_bob, 32) != 0)
    {
        debug_test_fail();
        return(1);
    }

    debug_test_ok();
    return(0);
}

#define MAKE_TEST(var,func)                                             \
int test_x25519_scalar_mult_ ## var ()                                  \
{                                                                       \
    unsigned char sk_alice[32], sk_bob[32];                             \
    unsigned char ss_alice[32], ss_bob[32];                             \
    unsigned char ss_alice_alt[32], ss_bob_alt[32];                     \
    debug_test_start("X25519 scalar multiplication test for " #func); \
                                                                        \
    fill_random_u8(sk_alice, 32);                                       \
    fill_random_u8(sk_bob, 32);                                         \
                                                                        \
    x25519_do_all( ss_alice, ss_bob, sk_alice, sk_bob,                  \
                   x25519_scalarmult );                                 \
    x25519_do_all( ss_alice_alt, ss_bob_alt, sk_alice, sk_bob, func );  \
                                                                        \
    if( ( compare_buf_u8( ss_alice, ss_alice_alt, 32) != 0 ) ||         \
        ( compare_buf_u8( ss_bob,   ss_bob_alt,   32) != 0 ) )          \
    {                                                                   \
        debug_test_fail();                                              \
        return(1);                                                      \
    }                                                                   \
                                                                        \
    debug_test_ok();                                                    \
    return(0);                                                          \
}

MAKE_TEST(emil,      x25519_scalarmult)
MAKE_TEST(opt, x25519_scalarmult_opt)

uint64_t t0, t1;
uint64_t cycles[TEST_COUNT];

#define ALIGNED(x) __attribute__((aligned(x)))
static int cmp_uint64_t(const void *a, const void *b)
{
    return (int)((*((const uint64_t *)a)) - (*((const uint64_t *)b)));
}

#define MAKE_BENCH(var,func)                                            \
int bench_x25519_scalar_mult_ ## var ()                                 \
{                                                                       \
    debug_printf( "x25519 scalar multiplication bench for " #func "\n");\
                                                                        \
    unsigned char result[32] ALIGNED(32);                               \
    unsigned char scalar[32] ALIGNED(32);                               \
    unsigned char point [32] ALIGNED(32);                               \
                                                                        \
    fill_random_u8(point, 32);                                          \
    fill_random_u8(scalar, 32);                                         \
                                                                        \
    for( unsigned cnt=0; cnt < WARMUP_ITERATIONS; cnt++ )               \
        (func)( result, scalar, point );                                \
                                                                        \
    for( unsigned cnt=0; cnt < TEST_COUNT; cnt++ )                      \
    {                                                                   \
        t0 = get_cyclecounter();                                        \
        for( unsigned cntp=0; cntp < ITER_PER_TEST; cntp++ )            \
            (func)( result, scalar, point );                            \
        t1 = get_cyclecounter();                                        \
        cycles[cnt] = (t1 - t0) / ITER_PER_TEST;                        \
    }                                                                   \
                                                                        \
    /* Report median */                                                 \
    qsort( cycles, TEST_COUNT, sizeof(uint64_t), cmp_uint64_t );        \
    debug_printf( "Median after %u x25519 scalar mults: %lld cycles\n", \
                  TEST_COUNT,cycles[TEST_COUNT >> 1] );                 \
                                                                        \
    return( 0 );                                                        \
}

MAKE_BENCH(emil,      x25519_scalarmult)
MAKE_BENCH(opt, x25519_scalarmult_opt)

int main( void )
{
    if( test_x25519_kex() != 0 )
        return(1);

    if( test_x25519_scalar_mult_opt() != 0 )
        return(1);

    enable_cyclecounter();
    if( bench_x25519_scalar_mult_emil() != 0 )
        return(1);

    if( bench_x25519_scalar_mult_opt() != 0 )
        return(1);
    disable_cyclecounter();

    return(0);
}
