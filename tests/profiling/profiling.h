#ifndef PROFILING_H
#define PROFILING_H

#include <hal.h>

typedef void (*ubench_t)(void*,void*,void*,void*,void*);

extern const unsigned int num_ubenchs_snippet;
extern const ubench_t ubenchs_snippet;

#define WARMUP_ITERATIONS 100
#define ITER_PER_TEST     100
#define TEST_COUNT        10

#define UBENCH_PATTERN_REPEATS 80

unsigned int measure(ubench_t func);
void profile_full();

#define MAKE_PROFILE(func)                                      \
void ubench_ ## func (void*, void*, void*, void*, void*);       \
void profile_ ## func ()                                        \
{                                                               \
    unsigned int median = measure(ubench_ ## func);             \
    debug_printf( "[" #func "]: %lld cycles\n", median );       \
}

#endif
