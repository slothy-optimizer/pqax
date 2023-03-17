#
# Copyright (c) 2022 Arm Limited
# Copyright (c) 2022 Matthias Kannwischer
# SPDX-License-Identifier: MIT
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#

PARAMS ?= sphincs-shake-128f
THASH ?= robust

CC=aarch64-none-linux-gnu-gcc
LD=$(CC)


CORE     ?= X2

# PMU / PERF
CYCLES?= PERF

ifeq ($(CYCLES),PMU)
	CFLAGS += -DPMU_CYCLES
endif

ifeq ($(CYCLES),PERF)
	CFLAGS += -DPERF_CYCLES
endif

ifeq ($(CYCLES),NO)
	CFLAGS += -DNO_CYCLES
endif

DUMMY?=0
WAY?=4

ifeq ($(DUMMY),0)

ifeq ($(WAY),5)

ifeq ($(CORE),X2)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x5_hybrid_asm_v8p
	PLATFORM = v84
else ifeq ($(CORE),A710)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x5_hybrid_asm_v8p
	PLATFORM = v84
else ifeq ($(CORE),A510)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x5_hybrid_asm_v8p
	PLATFORM = v84
else ifeq ($(CORE),X1)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x5_hybrid_asm_v8p
	PLATFORM = v8
else ifeq ($(CORE),A78)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x5_hybrid_asm_v8p
	PLATFORM = v8
else ifeq ($(CORE),A55)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x5_hybrid_asm_v8p
	PLATFORM = v8
endif

else ifeq ($(WAY),4)

ifeq ($(CORE),X2)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x4_hybrid_asm_v4
	PLATFORM = v84
else ifeq ($(CORE),A710)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x4_hybrid_asm_v2
	PLATFORM = v84
else ifeq ($(CORE),A510)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x4_v84a_asm_v1p0
	PLATFORM = v84
else ifeq ($(CORE),X1)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x4_hybrid_asm_v3p
	PLATFORM = v8
else ifeq ($(CORE),A78)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x4_hybrid_asm_v3p
	PLATFORM = v8
else ifeq ($(CORE),A55)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x4_scalar_asm_v5
	PLATFORM = v8
endif

else ifeq ($(WAY),3)

ifeq ($(CORE),X2)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x3_hybrid_asm_v6
	PLATFORM = v84
else ifeq ($(CORE),A710)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x3_hybrid_asm_v6
	PLATFORM = v84
else ifeq ($(CORE),A510)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x3_hybrid_asm_v6
	PLATFORM = v84
else ifeq ($(CORE),X1)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x3_hybrid_asm_v3p
	PLATFORM = v8
else ifeq ($(CORE),A78)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x3_hybrid_asm_v3p
	PLATFORM = v8
else ifeq ($(CORE),A55)
	KECCAK_X1_IMPL?= keccak_f1600_x1_scalar_asm_v5
	KECCAK_X_IMPL?= keccak_f1600_x3_hybrid_asm_v3p
	PLATFORM = v8
endif

endif

else

ifeq ($(CORE),X2)
	KECCAK_X1_IMPL?= keccak_f1600_dummy
	KECCAK_X_IMPL?= keccak_f1600_dummy
	PLATFORM = v84
else ifeq ($(CORE),A710)
	KECCAK_X1_IMPL?= keccak_f1600_dummy
	KECCAK_X_IMPL?= keccak_f1600_dummy
	PLATFORM = v84
else ifeq ($(CORE),A510)
	KECCAK_X1_IMPL?= keccak_f1600_dummy
	KECCAK_X_IMPL?= keccak_f1600_dummy
	PLATFORM = v84
else ifeq ($(CORE),X1)
	KECCAK_X1_IMPL?= keccak_f1600_dummy
	KECCAK_X_IMPL?= keccak_f1600_dummy
	PLATFORM = v8
else ifeq ($(CORE),A78)
	KECCAK_X1_IMPL?= keccak_f1600_dummy
	KECCAK_X_IMPL?= keccak_f1600_dummy
	PLATFORM = v8
else ifeq ($(CORE),A55)
	KECCAK_X1_IMPL?= keccak_f1600_dummy
	KECCAK_X_IMPL?= keccak_f1600_dummy
	PLATFORM = v8
endif

endif

ifeq ($(PLATFORM),v84)
	CFLAGS += -march=armv8.4-a+crypto+sha3
else
	CFLAGS += -march=armv8-a
endif

CFLAGS += -I. -flto -fpic  -Wall -Wextra -Wpedantic -Wmissing-prototypes -O3 \
		  -std=c99 -fomit-frame-pointer -DPARAMS=$(PARAMS) \
                  -DKECCAK_WAY=$(WAY)                \
		  -DKECCAK_X1_IMPL=$(KECCAK_X1_IMPL) \
		  -DKECCAK_X_IMPL=$(KECCAK_X_IMPL) \
		  $(EXTRA_CFLAGS)
LDFLAGS = -static -flto

SRC_DIR=.
BUILD_DIR=build

HEADERS=$(wildcard $(SRC_DIR)/*.h) $(wildcard $(SRC_DIR)/test/*.h)

ifeq ($(DUMMY),0)
ASM_SRC_FILES=keccak_f1600/$(KECCAK_X1_IMPL).s keccak_f1600/$(KECCAK_X_IMPL).s
else
ASM_SRC_FILES=keccak_f1600_dummy.s
endif

ASM_OBJ_FILES=$(patsubst %.s, $(BUILD_DIR)/%.s.o, $(ASM_SRC_FILES))

C_SRC_FILES = address.c fips202.c fips202x.c fors.c hash_shake.c hash_shakex.c merkle.c sign.c utils.c utilsx.c wots.c thash_shake_$(THASH)x.c thash_shake_$(THASH).c
C_SRC_FILES_BENCH=$(C_SRC_FILES) test/benchmark.c test/randombytes.c test/cycles.c
C_OBJ_FILES_BENCH=$(patsubst %.c, $(BUILD_DIR)/%.c.o, $(C_SRC_FILES_BENCH))
OBJ_FILES_BENCH=$(ASM_OBJ_FILES) $(C_OBJ_FILES_BENCH)

C_SRC_FILES_FUNCTEST=$(C_SRC_FILES) test/functest.c test/randombytes.c
C_OBJ_FILES_FUNCTEST=$(patsubst %.c, $(BUILD_DIR)/%.c.o, $(C_SRC_FILES_FUNCTEST))
OBJ_FILES_FUNCTEST=$(ASM_OBJ_FILES) $(C_OBJ_FILES_FUNCTEST)

C_SRC_FILES_TEST=$(C_SRC_FILES) test/thashx.c test/randombytes.c test/cycles.c
C_OBJ_FILES_TEST=$(patsubst %.c, $(BUILD_DIR)/%.c.o, $(C_SRC_FILES_TEST))
OBJ_FILES_TEST=$(ASM_OBJ_FILES) $(C_OBJ_FILES_TEST)



.PHONY: clean libclean
all: benchmark functest

# Compilation
$(BUILD_DIR)/%.c.o: $(SRC_DIR)/%.c $(HEADERS)
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.s.o: $(SRC_DIR)/%.s $(HEADERS)
	mkdir -p $(@D)
	$(CC) -x assembler-with-cpp $(CFLAGS) -c -o $@ $<


# Linking
benchmark: $(OBJ_FILES_BENCH) $(HEADERS)
	mkdir -p $(@D)
	$(LD) $(LDFLAGS) $(OBJ_FILES_BENCH) -o benchmark

# Linking
functest: $(OBJ_FILES_FUNCTEST) $(HEADERS)
	mkdir -p $(@D)
	$(LD) $(LDFLAGS) $(OBJ_FILES_FUNCTEST) -o functest


clean:
	-$(RM) -r build

libclean:
	find . -type f -executable -exec rm '{}' \;
	rm -rf bin
