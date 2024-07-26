CC=clang
LD=clang


CFLAGS = -march=armv8.4-a+crypto+sha3   \
         -Wall -Wextra -Werror -Wshadow -Wno-unused-parameter -Wno-incompatible-pointer-types

COMMON_INC=../common/inc/
ENV_INC=./inc/
TEST_COMMON=../../tests/common/
SRC_DIR=./src
BUILD_DIR=./build/$(TARGET)


CFLAGS+= -Ofast \
	-I$(COMMON_INC) \
	-I$(ENV_INC) \
	-I$(SRC_DIR) \
	-I$(TESTDIR) \
	-I$(TEST_COMMON) \


CFLAGS += -DPERF_CYCLES



all: $(TARGET)

HAL_SOURCES = $(wildcard $(SRC_DIR)/*.c) $(wildcard $(SRC_DIR)/*/*.c)
OBJECTS_HAL = $(patsubst %.c, $(BUILD_DIR)/%.c.o, $(abspath $(HAL_SOURCES)))
TEST_COMMON_SOURCES = $(wildcard $(TEST_COMMON)/*.c)
OBJECTS_TEST_COMMON = $(patsubst %.c, $(BUILD_DIR)/%.c.o, $(abspath $(TEST_COMMON_SOURCES)))
OBJECTS_SOURCES=$(patsubst %.c, $(BUILD_DIR)/%.c.o, $(abspath $(SOURCES)))
OBJECTS_C = $(OBJECTS_SOURCES) $(OBJECTS_HAL) $(OBJECTS_TEST_COMMON)
OBJECTS_ASM = $(patsubst %.s, $(BUILD_DIR)/%.s.o, $(abspath $(ASMS)))

OBJECTS = $(OBJECTS_C) $(OBJECTS_ASM)

# Compilation
$(OBJECTS_C): $(BUILD_DIR)/%.o: %
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJECTS_ASM): $(BUILD_DIR)/%.o: %
	mkdir -p $(@D)
	$(CC) -x assembler-with-cpp $(CFLAGS) -c -o $@ $<

# Linking
$(TARGET): $(OBJECTS)
	mkdir -p $(@D)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $(TARGET)

# Running
run: $(TARGET)
	sudo ./$(TARGET)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.elf