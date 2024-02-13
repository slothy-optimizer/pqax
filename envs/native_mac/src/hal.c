#include <hal.h>

/* Dependency on standard library:
 * - rand(), srand()
 * - time()
 * - printf()
 * - fflush()
 */
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <time.h>

#include "m1cycles.h"

void rand_init( unsigned long seed )
{
    ((void) seed);
    srand(time(NULL));
}

uint8_t get_random_byte()
{
    return( rand() );
}

/* Debugging stubs */

void debug_test_start( const char *testname )
{
    printf( "%s ... ", testname );
    fflush( stdout );
}

void debug_printf(const char * format, ... )
{
    va_list argp;
    va_start( argp, format );
    vprintf( format, argp );
    va_end( argp );
}

void debug_test_ok()   { printf( "Ok\n"    ); }
void debug_test_fail() { printf( "FAIL!\n" ); }

void enable_cyclecounter() {
    setup_rdtsc();
}
void disable_cyclecounter() {
    return;
}
uint64_t get_cyclecounter() {
    return(rdtsc());
}
