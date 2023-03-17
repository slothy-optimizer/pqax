PARAMS = sphincs-shake-128f
THASH = robust

CC=aarch64-none-linux-gnu-gcc
LD=$(CC)

PLATFORM ?= v84

# PMU / PERF
CYCLES ?= PERF
ifeq ($(CYCLES),PMU)
	CFLAGS += -DPMU_CYCLES
endif

ifeq ($(CYCLES),PERF)
	CFLAGS += -DPERF_CYCLES
endif

ifeq ($(CYCLES),NO)
	CFLAGS += -DNO_CYCLES
endif


CFLAGS += -I. -flto -fpic -Wall -Wextra -Wpedantic -Wmissing-prototypes -O3 -std=c99 -fomit-frame-pointer -DPARAMS=$(PARAMS) $(EXTRA_CFLAGS)
LDFLAGS = -static -flto

SRC_DIR=.
BUILD_DIR=build

HEADERS=$(wildcard $(SRC_DIR)/*.h) $(wildcard $(SRC_DIR)/test/*.h)

# C / BAS / COTHANV8 / COTHANV84
KECCAK_X2_IMPL ?= BAS

ifeq ($(KECCAK_X2_IMPL),C)
	ASM_SRC_FILES=
	C_SRC_FILES=keccak_f1600_x2/keccakx2_C.c
	CFLAGS += -DKECCAK_X2_IMPL_C
else ifeq ($(KECCAK_X2_IMPL),BAS)
	ASM_SRC_FILES=keccak_f1600_x2/keccakx2_bas.s
	C_SRC_FILES=
	CFLAGS += -DKECCAK_X2_IMPL_BAS
else ifeq ($(KECCAK_X2_IMPL),COTHANV8)
	ASM_SRC_FILES=
	C_SRC_FILES=keccak_f1600_x2/keccakx2_cothan.c
	CFLAGS += -DKECCAK_X2_IMPL_COTHAN
	CFLAGS_COTHAN= $(CFLAGS) -march=armv8-a
else ifeq ($(KECCAK_X2_IMPL),COTHANV84)
	ASM_SRC_FILES=
	C_SRC_FILES=keccak_f1600_x2/keccakx2_cothan.c
	CFLAGS += -DKECCAK_X2_IMPL_COTHAN
	CFLAGS_COTHAN= $(CFLAGS) -march=armv8.4-a+crypto+sha3
endif
ifeq ($(PLATFORM),v84)
	CFLAGS += -march=armv8.4-a+crypto+sha3
else
	CFLAGS += -march=armv8-a
endif
ASM_OBJ_FILES=$(patsubst %.s, $(BUILD_DIR)/%.s.o, $(ASM_SRC_FILES))

C_SRC_FILES+= address.c fips202.c fips202x2.c fors.c hash_shake.c hash_shakex2.c merkle.c sign.c utils.c utilsx2.c wots.c thash_shake_$(THASH)x2.c
C_SRC_FILES_BENCH=$(C_SRC_FILES) test/benchmark.c test/randombytes.c test/cycles.c
C_OBJ_FILES_BENCH=$(patsubst %.c, $(BUILD_DIR)/%.c.o, $(C_SRC_FILES_BENCH))
OBJ_FILES_BENCH=$(ASM_OBJ_FILES) $(C_OBJ_FILES_BENCH)

.PHONY: clean libclean

all: benchmark

# Compilation
$(BUILD_DIR)/keccak_f1600_x2/keccakx2_cothan.c.o: $(SRC_DIR)/keccak_f1600_x2/keccakx2_cothan.c $(HEADERS)
	mkdir -p $(@D)
	$(CC) $(CFLAGS_COTHAN) -c -o $@ $<

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

clean:
	-$(RM) -r build

libclean:
	find . -type f -executable -exec rm '{}' \;
