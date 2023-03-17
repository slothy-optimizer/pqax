#ifndef SPX_CYCLES_H
#define SPX_CYCLES_H

#include <stdint.h>

#if !defined(EXTERNAL_CYCLES) && !defined(PERF_CYCLES) && !defined(PMU_CYCLES) && !defined(NO_CYCLES)
#define NO_CYCLES
#endif

void enable_cyclecounter(void);
void disable_cyclecounter(void);
uint64_t get_cyclecounter(void);
void reset_cpucycles(void);
int is_cpucycles_overflow(void);


#define init_cpucycles enable_cyclecounter
#define cpucycles get_cyclecounter


#endif
