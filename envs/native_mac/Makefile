# Armv8-A test environment based on QEMU
#
# Copyright (c) 2021 Arm Limited (or its affiliates). All rights reserved.
# Use, modification and redistribution of this file is subject to your possession of a
# valid End User License Agreement for the Arm Product of which these examples are part of
# and your compliance with all applicable terms and conditions of such licence agreement.

################################################################################
###                                                                          ###
###                         USER CONFIGURATION                               ###
###                             ADAPT THIS                                   ###
###                                                                          ###
################################################################################

#
# See README.md for setup instructions
#

LD=clang
CC=clang

CFLAGS = -march=armv8.4-a+crypto+sha3   \
         -Wall -Wextra -Werror -Wshadow -Wno-unused-parameter -Wno-incompatible-pointer-types

################################################################################
###                                                                          ###
###                   END OF USER CONFIGURATION                              ###
###                                                                          ###
################################################################################

# Final image
TARGET=test

INC_DIR=./inc
INC_DIR_TEST=$(INC_DIR)/test_inc -I$(SRC_DIR)/test_src/manual -I$(SRC_DIR)/test_src/auto
BUILD_DIR=./build
SRC_DIR=./src

# Scatter files before/after preprocessing

CFLAGS+= -Ofast -I$(INC_DIR)              \
         -I$(INC_DIR_TEST)

CYCLES?=NO # PERF

ifeq ($(CYCLES),PERF)
	CFLAGS += -DPERF_CYCLES
endif

ifeq ($(CYCLES),NO)
	CFLAGS += -DNO_CYCLES
endif

C_SRC_FILES_PRE=$(wildcard $(SRC_DIR)/*.c) $(wildcard $(SRC_DIR)/*/*.c) $(wildcard $(SRC_DIR)/*/*/*.c $(SRC_DIR)/*/*/*/*.c)
C_SRC_FILES=$(patsubst $(SRC_DIR)/%.c, %.c, $(C_SRC_FILES_PRE))
ASM_SRC_FILES_PRE=$(wildcard $(SRC_DIR)/*/*.s) $(wildcard $(SRC_DIR)/*.s) $(wildcard $(SRC_DIR)/*/*/*.s) $(wildcard $(SRC_DIR)/*/*/*/*.s)
ASM_SRC_FILES=$(patsubst $(SRC_DIR)/%.s, %.s, $(ASM_SRC_FILES_PRE))

HEADER_FILES_PRE=$(wildcard $(SRC_DIR)/*.h) $(wildcard $(SRC_DIR)/*/*.h) $(wildcard $(SRC_DIR)/*/*/*.h)

ASM_OBJ_FILES=$(patsubst %.s, $(BUILD_DIR)/%.o, $(ASM_SRC_FILES))
C_OBJ_FILES=$(patsubst %.c, $(BUILD_DIR)/%.o, $(C_SRC_FILES))
OBJ_FILES=$(ASM_OBJ_FILES) $(C_OBJ_FILES) $(CMSIS_OBJ_FILES)

.phony: all clean debug run

all: $(TARGET)

# Compilation
$(C_OBJ_FILES): $(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HEADER_FILES_PRE)
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<
$(ASM_OBJ_FILES): $(BUILD_DIR)/%.o: $(SRC_DIR)/%.s $(HEADER_FILES_PRE)
	mkdir -p $(@D)
	$(CC) -x assembler-with-cpp $(CFLAGS) -c -o $@ $<

# Linking
$(TARGET): $(OBJS_DIR) $(OBJ_FILES)
	mkdir -p $(@D)
	$(LD) $(OBJ_FILES) -o $(TARGET)

# Running
run: $(TARGET)
	./$(TARGET)

clean:
	rm -rf $(OBJ_FILES)
	rm -rf $(TARGET)
