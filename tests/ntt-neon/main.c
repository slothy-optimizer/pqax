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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include <hal.h>


#include "ntt.h"

int main(void)
{
    enable_cyclecounter();

#if defined(NTT_INCOMPLETE)
    /* test_fwd_ntt_incomplete_var_3_3_0(); */
    /* test_fwd_ntt_incomplete_var_3_3_1(); */
    /* test_fwd_ntt_incomplete_var_3_3_2(); */
    /* test_fwd_ntt_incomplete_var_3_3_3(); */
    /* test_fwd_ntt_incomplete_var_3_3_4(); */
    test_fwd_ntt_incomplete_var_3_3_5();

    /* test_fwd_ntt_incomplete_var_4_2_0_0(); */
    /* test_fwd_ntt_incomplete_var_4_2_0_z4_0(); */
    /* test_fwd_ntt_incomplete_var_4_2_0_z4_16(); */
    /* test_fwd_ntt_incomplete_var_4_2_24_z4_0(); */
    /* test_fwd_ntt_incomplete_var_4_2_24_z4_16(); */

    /* test_fwd_ntt_incomplete_var_4_2_3_z4_0(); */
    /* test_fwd_ntt_incomplete_var_4_2_3_z4_1(); */
    /* test_fwd_ntt_incomplete_var_4_2_3_z4_2(); */
    /* test_fwd_ntt_incomplete_var_4_2_3_z4_3(); */
    /* test_fwd_ntt_incomplete_var_4_2_3_z4_4(); */
    test_fwd_ntt_incomplete_var_4_2_3_z4_5();

    /* test_fwd_ntt_incomplete_var_4_2_7_z4_0(); */
    /* test_fwd_ntt_incomplete_var_4_2_7_z4_1(); */
    /* test_fwd_ntt_incomplete_var_4_2_7_z4_2(); */
    /* test_fwd_ntt_incomplete_var_4_2_7_z4_3(); */
    /* test_fwd_ntt_incomplete_var_4_2_7_z4_4(); */
    /* test_fwd_ntt_incomplete_var_4_2_7_z4_5(); */
    /* test_fwd_ntt_incomplete_var_4_2_7_z4_6(); */
    /* test_fwd_ntt_incomplete_var_4_2_7_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_7_z4_8(); */
    /* test_fwd_ntt_incomplete_var_4_2_7_z4_9(); */
    test_fwd_ntt_incomplete_var_4_2_7_z4_10();

    /* test_fwd_ntt_incomplete_var_4_2_8_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_9_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_10_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_11_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_12_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_13_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_14_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_15_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_16_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_17_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_18_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_19_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_20_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_21_z4_7(); */
    test_fwd_ntt_incomplete_var_4_2_22_z4_7();

    /* test_fwd_ntt_incomplete_var_4_2_22_z4_7(); */
    /* test_fwd_ntt_incomplete_var_4_2_22_z4_8(); */
    /* test_fwd_ntt_incomplete_var_4_2_22_z4_9(); */
    /* test_fwd_ntt_incomplete_var_4_2_22_z4_10(); */
    /* test_fwd_ntt_incomplete_var_4_2_22_z4_11(); */
    /* test_fwd_ntt_incomplete_var_4_2_22_z4_12(); */
    /* test_fwd_ntt_incomplete_var_4_2_22_z4_13(); */
    /* test_fwd_ntt_incomplete_var_4_2_22_z4_14(); */
    test_fwd_ntt_incomplete_var_4_2_22_z4_15();
#else
    test_fwd_ntt_full_var_4_4_0_0();
    test_fwd_ntt_full_var_4_4_1_0();
    test_fwd_ntt_full_var_4_4_2_0();
    test_fwd_ntt_full_var_4_4_3_0();
    test_fwd_ntt_full_var_4_4_4_0();
    test_fwd_ntt_full_var_4_4_5_0();
    test_fwd_ntt_full_var_4_4_6_0();
    test_fwd_ntt_full_var_4_4_7_0();
    test_fwd_ntt_full_var_4_4_8_0();
    test_fwd_ntt_full_var_4_4_9_0();
    test_fwd_ntt_full_var_4_4_10_0();
    test_fwd_ntt_full_var_4_4_3_z2_0();
    test_fwd_ntt_full_var_4_4_3_z2_1();
    test_fwd_ntt_full_var_4_4_3_z2_2();
    test_fwd_ntt_full_var_4_4_3_z2_3();
    test_fwd_ntt_full_var_4_4_3_z2_4();
    test_fwd_ntt_full_var_4_4_3_z2_5();
    test_fwd_ntt_full_var_4_4_3_z4_0();
    test_fwd_ntt_full_var_4_4_3_z4_1();
    test_fwd_ntt_full_var_4_4_3_z4_2();
    test_fwd_ntt_full_var_4_4_3_z4_3();
    test_fwd_ntt_full_var_4_4_3_z4_4();
#endif /* NTT_INCOMPLETE */
    disable_cyclecounter();
}
