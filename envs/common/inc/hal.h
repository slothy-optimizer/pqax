/*
 * Copyright (c) 2021 Arm Limited
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

#if !defined(TESTS_HAL_H)
#define TESTS_HAL_H

#include <stdint.h>
#include <hal_env.h>

/* Initialize random number generation */
extern void rand_init( unsigned long seed );

/* Request random data. */
extern uint8_t get_random_byte();

/* Debugging stubs
 *
 * Those stubs can either be defined as macros (which is especially
 * useful when debugging shall be disabled and we don't want to waste
 * code space) or as externally defined functions.
 * In case no debugging is desired, just put
 * ```
 * #define debug_test_start(str) do {} while(0)
 * #define debug_printf( ... )   do {} while(0)
 * #define debug_test_ok()       do {} while(0)
 * #define debug_test_fail()     do {} while(0)
 * ```
 * in hal_env.h.
 */
#if !defined(TESTS_HAL_DEBUG_MACRO)
extern void debug_test_start( const char *testname );
extern void debug_printf(const char * restrict format, ... );
extern void debug_test_ok();
extern void debug_test_fail();
#endif /* TESTS_HAL_DEBUG_MACRO */

void enable_cyclecounter();
void disable_cyclecounter();
uint64_t get_cyclecounter();

#endif /* TESTS_HAL_H */
