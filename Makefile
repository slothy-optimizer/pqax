
CODEGEN_DIR=asm

MANUAL_SRCS_DIR=$(CODEGEN_DIR)/manual
MANUAL_SRCS_KECCAK_NEON_DIR=$(MANUAL_SRCS_DIR)/keccak_f1600
MANUAL_SRCS_NTT_KYBER_DIR=$(MANUAL_SRCS_DIR)/ntt_kyber/
MANUAL_SRCS_NTT_DILITHIUM_DIR=$(MANUAL_SRCS_DIR)/ntt_dilithium/
MANUAL_SRCS_X25519_DIR=$(MANUAL_SRCS_DIR)/x25519/
MANUAL_SRCS_BASEMUL_S64_DIR=$(MANUAL_SRCS_DIR)/basemul_s64

AUTOGEN_SRCS_DIR=$(CODEGEN_DIR)/auto
AUTOGEN_SRCS_NTT_NEON_DIR=$(AUTOGEN_SRCS_DIR)/ntt_neon
AUTOGEN_SRCS_NTT_SVE2_DIR=$(AUTOGEN_SRCS_DIR)/ntt_sve2

AUTOGEN_SRCS_ALL=$(wildcard $(AUTOGEN_SRCS_DIR)/*.s)     \
                 $(wildcard $(AUTOGEN_SRCS_DIR)/*/*.s)   \
                 $(wildcard $(AUTOGEN_SRCS_DIR)/*/*/*.s) \
                 $(wildcard $(AUTOGEN_SRCS_DIR)/*/*/*/*/*.s)

MANUAL_SRCS_ALL=$(wildcard $(MANUAL_SRCS_DIR)/*.s)     \
                $(wildcard $(MANUAL_SRCS_DIR)/*/*.s)   \
                $(wildcard $(MANUAL_SRCS_DIR)/*/*/*.s) \
                $(wildcard $(MANUAL_SRCS_DIR)/*/*/*/*/*.s)

AUTOGEN_SRCS_NTT_NEON_ALL=$(wildcard $(AUTOGEN_SRCS_NTT_NEON_DIR)/*.s)     \
                          $(wildcard $(AUTOGEN_SRCS_NTT_NEON_DIR)/*/*.s)   \
                          $(wildcard $(AUTOGEN_SRCS_NTT_NEON_DIR)/*/*/*.s) \
                          $(wildcard $(AUTOGEN_SRCS_NTT_NEON_DIR)/*/*/*/*.s)

AUTOGEN_SRCS_NTT_SVE2_ALL=$(wildcard $(AUTOGEN_SRCS_NTT_SVE2_DIR)/*.s)     \
                          $(wildcard $(AUTOGEN_SRCS_NTT_SVE2_DIR)/*/*.s)   \
                          $(wildcard $(AUTOGEN_SRCS_NTT_SVE2_DIR)/*/*/*.s) \
                          $(wildcard $(AUTOGEN_SRCS_NTT_SVE2_DIR)/*/*/*/*.s)

MANUAL_SRCS_NTT_SVE2_ALL=$(wildcard $(MANUAL_SRCS_BASEMUL_S64_DIR)/*.[sch])

MANUAL_SRCS_KECCAK_NEON_ALL=$(wildcard $(MANUAL_SRCS_KECCAK_NEON_DIR)/*.[sch])     \
                      $(wildcard $(MANUAL_SRCS_KECCAK_NEON_DIR)/*/*.[sch])   \
                      $(wildcard $(MANUAL_SRCS_KECCAK_NEON_DIR)/*/*/*.[sch]) \
                      $(wildcard $(MANUAL_SRCS_KECCAK_NEON_DIR)/*/*/*/*.[sch])

MANUAL_SRCS_NTT_KYBER_ALL=$(wildcard $(MANUAL_SRCS_NTT_KYBER_DIR)/*.[sch])     \
                      $(wildcard $(MANUAL_SRCS_NTT_KYBER_DIR)/*/*.[sch])   \
                      $(wildcard $(MANUAL_SRCS_NTT_KYBER_DIR)/*/*/*.[sch]) \
                      $(wildcard $(MANUAL_SRCS_NTT_KYBER_DIR)/*/*/*/*.[sch])

MANUAL_SRCS_NTT_DILITHIUM_ALL=$(wildcard $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/*.[sch])\
                      $(wildcard $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/*/*.[sch])   \
                      $(wildcard $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/*/*/*.[sch]) \
                      $(wildcard $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/*/*/*/*.[sch])

MANUAL_SRCS_X25519_ALL=$(wildcard $(MANUAL_SRCS_X25519_DIR)/*.[schi])     \
                      $(wildcard $(MANUAL_SRCS_X25519_DIR)/*/*.[schi])   \
                      $(wildcard $(MANUAL_SRCS_X25519_DIR)/*/*/*.[schi]) \
                      $(wildcard $(MANUAL_SRCS_X25519_DIR)/*/*/*/*.[schi])

TEST_BASE_DIR=tests

# Directory and sources for Helloworld dummy test
TEST_HELLOWORLD_DIR=$(TEST_BASE_DIR)/helloworld
TEST_HELLOWORLD_SOURCES_AUTO_DIR=$(TEST_HELLOWORLD_DIR)/auto
TEST_HELLOWORLD_SRC_C=$(wildcard $(TEST_HELLOWORLD_DIR)/*.c) \
                      $(wildcard $(TEST_HELLOWORLD_DIR)/*/*.c)
TEST_HELLOWORLD_SRC_ALL=$(TEST_HELLOWORLD_SRC_C)

# Directory and sources for Profiling dummy test
TEST_PROFILING_DIR=$(TEST_BASE_DIR)/profiling
TEST_PROFILING_SRC_C=$(wildcard $(TEST_PROFILING_DIR)/*.c) \
                      $(wildcard $(TEST_PROFILING_DIR)/*/*.c)
TEST_PROFILING_SRC_ALL=$(TEST_PROFILING_SRC_C)

# Directory and sources for Neon-NTT test
TEST_NTT_NEON_DIR=$(TEST_BASE_DIR)/ntt_neon
TEST_NTT_NEON_SOURCES_AUTO_DIR=$(TEST_NTT_NEON_DIR)/auto
TEST_NTT_NEON_SRC_C=$(wildcard $(TEST_NTT_NEON_DIR)/*.c) \
                    $(wildcard $(TEST_NTT_NEON_DIR)/*/*.c)
TEST_NTT_NEON_SRC_AUTO=$(patsubst $(AUTOGEN_SRCS_NTT_NEON_DIR)/%.s,      \
                                  $(TEST_NTT_NEON_SOURCES_AUTO_DIR)/%.s, \
                                  $(AUTOGEN_SRCS_NTT_NEON_ALL))
TEST_NTT_NEON_SRC_ALL=$(TEST_NTT_NEON_SRC_C) $(TEST_NTT_NEON_SRC_AUTO)

# Directory and sources for SVE2-NTT test
TEST_NTT_SVE2_DIR=$(TEST_BASE_DIR)/ntt_sve2
TEST_NTT_SVE2_SOURCES_AUTO_DIR=$(TEST_NTT_SVE2_DIR)/auto
TEST_NTT_SVE2_SOURCES_MANUAL_DIR=$(TEST_NTT_SVE2_DIR)/manual
TEST_NTT_SVE2_SRC_C=$(wildcard $(TEST_NTT_SVE2_DIR)/*.c) \
                    $(wildcard $(TEST_NTT_SVE2_DIR)/*/*.c)
TEST_NTT_SVE2_SRC_AUTO=$(patsubst $(AUTOGEN_SRCS_NTT_SVE2_DIR)/%.s,      \
                                  $(TEST_NTT_SVE2_SOURCES_AUTO_DIR)/%.s, \
                                  $(AUTOGEN_SRCS_NTT_SVE2_ALL))
TEST_NTT_SVE2_SRC_MANUAL=$(patsubst $(MANUAL_SRCS_BASEMUL_S64_DIR)/%.s,      \
                                  $(TEST_NTT_SVE2_SOURCES_MANUAL_DIR)/%.s, \
                                  $(MANUAL_SRCS_NTT_SVE2_ALL))
TEST_NTT_SVE2_SRC_ALL=$(TEST_NTT_SVE2_SRC_C) $(TEST_NTT_SVE2_SRC_AUTO) $(TEST_NTT_SVE2_SRC_MANUAL)

# Directory and sources for KECCAK test
TEST_KECCAK_NEON_DIR=$(TEST_BASE_DIR)/keccak_neon
TEST_KECCAK_NEON_SRC_C=$(wildcard $(TEST_KECCAK_NEON_DIR)/*.c) \
                       $(wildcard $(TEST_KECCAK_NEON_DIR)/*/*.c)
TEST_KECCAK_NEON_SOURCES_MANUAL_DIR=$(TEST_KECCAK_NEON_DIR)/manual
TEST_KECCAK_NEON_SRC_MANUAL__=$(patsubst $(MANUAL_SRCS_KECCAK_NEON_DIR)/%.s,    \
                                  $(TEST_KECCAK_NEON_SOURCES_MANUAL_DIR)/%.s, \
                                  $(MANUAL_SRCS_KECCAK_NEON_ALL))
TEST_KECCAK_NEON_SRC_MANUAL_=$(patsubst $(MANUAL_SRCS_KECCAK_NEON_DIR)/%.c,    \
                                  $(TEST_KECCAK_NEON_SOURCES_MANUAL_DIR)/%.c, \
                                  $(TEST_KECCAK_NEON_SRC_MANUAL__))
TEST_KECCAK_NEON_SRC_MANUAL=$(patsubst $(MANUAL_SRCS_KECCAK_NEON_DIR)/%.h,    \
                                  $(TEST_KECCAK_NEON_SOURCES_MANUAL_DIR)/%.h, \
                                  $(TEST_KECCAK_NEON_SRC_MANUAL_))

TEST_KECCAK_NEON_SRC_ALL=$(TEST_KECCAK_NEON_SRC_C) $(TEST_KECCAK_NEON_SRC_MANUAL)

TEST_NTT_KYBER_DIR=$(TEST_BASE_DIR)/ntt_kyber
TEST_NTT_KYBER_SRC_C=$(wildcard $(TEST_NTT_KYBER_DIR)/*.c) \
                       $(wildcard $(TEST_NTT_KYBER_DIR)/*/*.c)
TEST_NTT_KYBER_SOURCES_MANUAL_DIR=$(TEST_NTT_KYBER_DIR)/manual
TEST_NTT_KYBER_SRC_MANUAL__=$(patsubst $(MANUAL_SRCS_NTT_KYBER_DIR)/%.s,    \
                                  $(TEST_NTT_KYBER_SOURCES_MANUAL_DIR)/%.s, \
                                  $(MANUAL_SRCS_NTT_KYBER_ALL))
TEST_NTT_KYBER_SRC_MANUAL_=$(patsubst $(MANUAL_SRCS_NTT_KYBER_DIR)/%.c,    \
                                  $(TEST_NTT_KYBER_SOURCES_MANUAL_DIR)/%.c, \
                                  $(TEST_NTT_KYBER_SRC_MANUAL__))
TEST_NTT_KYBER_SRC_MANUAL=$(patsubst $(MANUAL_SRCS_NTT_KYBER_DIR)/%.h,    \
                                  $(TEST_NTT_KYBER_SOURCES_MANUAL_DIR)/%.h, \
                                  $(TEST_NTT_KYBER_SRC_MANUAL_))

TEST_NTT_KYBER_SRC_ALL=$(TEST_NTT_KYBER_SRC_C) $(TEST_NTT_KYBER_SRC_MANUAL)

TEST_NTT_DILITHIUM_DIR=$(TEST_BASE_DIR)/ntt_dilithium
TEST_NTT_DILITHIUM_SRC_C=$(wildcard $(TEST_NTT_DILITHIUM_DIR)/*.c) \
                       $(wildcard $(TEST_NTT_DILITHIUM_DIR)/*/*.c)
TEST_NTT_DILITHIUM_SOURCES_MANUAL_DIR=$(TEST_NTT_DILITHIUM_DIR)/manual
TEST_NTT_DILITHIUM_SRC_MANUAL__=$(patsubst $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/%.s,    \
                                  $(TEST_NTT_DILITHIUM_SOURCES_MANUAL_DIR)/%.s, \
                                  $(MANUAL_SRCS_NTT_DILITHIUM_ALL))
TEST_NTT_DILITHIUM_SRC_MANUAL_=$(patsubst $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/%.c,    \
                                  $(TEST_NTT_DILITHIUM_SOURCES_MANUAL_DIR)/%.c, \
                                  $(TEST_NTT_DILITHIUM_SRC_MANUAL__))
TEST_NTT_DILITHIUM_SRC_MANUAL=$(patsubst $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/%.h,    \
                                  $(TEST_NTT_DILITHIUM_SOURCES_MANUAL_DIR)/%.h, \
                                  $(TEST_NTT_DILITHIUM_SRC_MANUAL_))

TEST_NTT_DILITHIUM_SRC_ALL=$(TEST_NTT_DILITHIUM_SRC_C) $(TEST_NTT_DILITHIUM_SRC_MANUAL)

TEST_X25519_DIR=$(TEST_BASE_DIR)/x25519
TEST_X25519_SRC_C=$(wildcard $(TEST_X25519_DIR)/*.c) \
                       $(wildcard $(TEST_X25519_DIR)/*/*.c)
TEST_X25519_SOURCES_MANUAL_DIR=$(TEST_X25519_DIR)/manual
TEST_X25519_SRC_MANUAL___=$(patsubst $(MANUAL_SRCS_X25519_DIR)/%.i,    \
                                  $(TEST_X25519_SOURCES_MANUAL_DIR)/%.i, \
                                  $(MANUAL_SRCS_X25519_ALL))
TEST_X25519_SRC_MANUAL__=$(patsubst $(MANUAL_SRCS_X25519_DIR)/%.s,    \
                                  $(TEST_X25519_SOURCES_MANUAL_DIR)/%.s, \
                                  $(TEST_X25519_SRC_MANUAL___))
TEST_X25519_SRC_MANUAL_=$(patsubst $(MANUAL_SRCS_X25519_DIR)/%.c,    \
                                  $(TEST_X25519_SOURCES_MANUAL_DIR)/%.c, \
                                  $(TEST_X25519_SRC_MANUAL__))
TEST_X25519_SRC_MANUAL=$(patsubst $(MANUAL_SRCS_X25519_DIR)/%.h,    \
                                  $(TEST_X25519_SOURCES_MANUAL_DIR)/%.h, \
                                  $(TEST_X25519_SRC_MANUAL_))

TEST_X25519_SRC_ALL=$(TEST_X25519_SRC_C) $(TEST_X25519_SRC_MANUAL)


# All sources
TEST_SRC_AUTO_ALL= $(TEST_NTT_NEON_SRC_AUTO) $(TEST_KECCAK_NEON_SRC_MANUAL) $(TEST_NTT_KYBER_SRC_MANUAL) $(TEST_NTT_DILITHIUM_SRC_MANUAL) $(TEST_X25519_SRC_MANUAL)

#
# Test environments
#

TEST_ENVS_BASE_DIR=envs

# QEMU test environment
TEST_ENV_CROSS_BASE=$(TEST_ENVS_BASE_DIR)/cross
TEST_ENV_CROSS_SRC=$(TEST_ENV_CROSS_BASE)/src
TEST_ENV_CROSS_SYMLINK=$(TEST_ENV_CROSS_SRC)/test_src

# Native test environment for mac
TEST_ENV_NATIVE_MAC_BASE=$(TEST_ENVS_BASE_DIR)/native_mac
TEST_ENV_NATIVE_MAC_SRC=$(TEST_ENV_NATIVE_MAC_BASE)/src
TEST_ENV_NATIVE_MAC_SYMLINK=$(TEST_ENV_NATIVE_MAC_SRC)/test_src

# Native test environment for linux
TEST_ENV_NATIVE_LINUX_BASE=$(TEST_ENVS_BASE_DIR)/native_linux
TEST_ENV_NATIVE_LINUX_SRC=$(TEST_ENV_NATIVE_LINUX_BASE)/src
TEST_ENV_NATIVE_LINUX_SYMLINK=$(TEST_ENV_NATIVE_LINUX_SRC)/test_src

# Code generation files
PYTHON_SRCS=$(wildcard $(CODEGEN_DIR)/*.py)          \
            $(wildcard $(CODEGEN_DIR)/*/*.py)        \
            $(wildcard $(CODEGEN_DIR)/*/*/*.py)      \
            $(wildcard $(CODEGEN_DIR)/*/*/*/*/*.py)

.PHONY: all
all: codegen $(TEST_SRC_AUTO_ALL)

.PHONY: clean
clean:
	make clean -C $(TEST_ENV_CROSS_BASE)
	make clean -C $(TEST_ENV_NATIVE_MAC_BASE)
	make clean -C $(TEST_ENV_NATIVE_LINUX_BASE)
	rm -f $(TEST_SRC_AUTO_ALL)
	rm -f $(TEST_ENV_CROSS_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_MAC_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	rm -f $(TEST_ENV_CROSS_BASE)/test_loaded_*
	rm -f $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_*
	rm -f $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_*

.PHONY: cleanasm
cleanasm:
	make clean -C $(CODEGEN_DIR)

.PHONY: cleanall
cleanall: clean cleanasm

$(AUTOGEN_SRCS_ALL): $(PYTHON_SRCS)
	make -C $(CODEGEN_DIR)

$(TEST_NTT_NEON_SRC_AUTO): $(TEST_NTT_NEON_SOURCES_AUTO_DIR)/%.s: $(AUTOGEN_SRCS_NTT_NEON_DIR)/%.s
	mkdir -p $(@D)
	cp $< $@

$(TEST_NTT_SVE2_SRC_AUTO): $(TEST_NTT_SVE2_SOURCES_AUTO_DIR)/%.s: $(AUTOGEN_SRCS_NTT_SVE2_DIR)/%.s
	mkdir -p $(@D)
	cp $< $@
$(info XXX: $(TEST_NTT_SVE2_SRC_MANUAL))
$(info YYY: $(TEST_NTT_SVE2_SRC_MANUAL))
$(TEST_NTT_SVE2_SRC_MANUAL): $(TEST_NTT_SVE2_SOURCES_MANUAL_DIR)/%.s: $(MANUAL_SRCS_BASEMUL_S64_DIR)/%.s
	mkdir -p $(@D)
	cp $< $@

$(TEST_KECCAK_NEON_SRC_MANUAL): $(TEST_KECCAK_NEON_SOURCES_MANUAL_DIR)/%.c: $(MANUAL_SRCS_KECCAK_NEON_DIR)/%.c
	mkdir -p $(@D)
	cp $< $@
$(TEST_KECCAK_NEON_SRC_MANUAL): $(TEST_KECCAK_NEON_SOURCES_MANUAL_DIR)/%.s: $(MANUAL_SRCS_KECCAK_NEON_DIR)/%.s
	mkdir -p $(@D)
	cp $< $@
$(TEST_KECCAK_NEON_SRC_MANUAL): $(TEST_KECCAK_NEON_SOURCES_MANUAL_DIR)/%.h: $(MANUAL_SRCS_KECCAK_NEON_DIR)/%.h
	mkdir -p $(@D)
	cp $< $@

$(TEST_NTT_KYBER_SRC_MANUAL): $(TEST_NTT_KYBER_SOURCES_MANUAL_DIR)/%.c: $(MANUAL_SRCS_NTT_KYBER_DIR)/%.c
	mkdir -p $(@D)
	cp $< $@
$(TEST_NTT_KYBER_SRC_MANUAL): $(TEST_NTT_KYBER_SOURCES_MANUAL_DIR)/%.s: $(MANUAL_SRCS_NTT_KYBER_DIR)/%.s
	mkdir -p $(@D)
	cp $< $@
$(TEST_NTT_KYBER_SRC_MANUAL): $(TEST_NTT_KYBER_SOURCES_MANUAL_DIR)/%.h: $(MANUAL_SRCS_NTT_KYBER_DIR)/%.h
	mkdir -p $(@D)
	cp $< $@

$(TEST_NTT_DILITHIUM_SRC_MANUAL): $(TEST_NTT_DILITHIUM_SOURCES_MANUAL_DIR)/%.c: $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/%.c
	mkdir -p $(@D)
	cp $< $@
$(TEST_NTT_DILITHIUM_SRC_MANUAL): $(TEST_NTT_DILITHIUM_SOURCES_MANUAL_DIR)/%.s: $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/%.s
	mkdir -p $(@D)
	cp $< $@
$(TEST_NTT_DILITHIUM_SRC_MANUAL): $(TEST_NTT_DILITHIUM_SOURCES_MANUAL_DIR)/%.h: $(MANUAL_SRCS_NTT_DILITHIUM_DIR)/%.h
	mkdir -p $(@D)
	cp $< $@

$(TEST_X25519_SRC_MANUAL): $(TEST_X25519_SOURCES_MANUAL_DIR)/%.i: $(MANUAL_SRCS_X25519_DIR)/%.i
	mkdir -p $(@D)
	cp $< $@
$(TEST_X25519_SRC_MANUAL): $(TEST_X25519_SOURCES_MANUAL_DIR)/%.c: $(MANUAL_SRCS_X25519_DIR)/%.c
	mkdir -p $(@D)
	cp $< $@
$(TEST_X25519_SRC_MANUAL): $(TEST_X25519_SOURCES_MANUAL_DIR)/%.s: $(MANUAL_SRCS_X25519_DIR)/%.s
	mkdir -p $(@D)
	cp $< $@
$(TEST_X25519_SRC_MANUAL): $(TEST_X25519_SOURCES_MANUAL_DIR)/%.h: $(MANUAL_SRCS_X25519_DIR)/%.h
	mkdir -p $(@D)
	cp $< $@

.PHONY: codegen
codegen:
	make codegen -C $(CODEGEN_DIR)

# Template on CROSS

TEST_ENV_CROSS_LINK_HELLOWORLD = $(TEST_ENV_CROSS_BASE)/test_loaded_helloworld
$(TEST_ENV_CROSS_LINK_HELLOWORLD):
	rm -f $(TEST_ENV_CROSS_SYMLINK)
	ln -s ../../../$(TEST_HELLOWORLD_DIR) $(TEST_ENV_CROSS_SYMLINK)
	rm -f $(TEST_ENV_CROSS_BASE)/test_loaded_*
	make -C $(TEST_ENV_CROSS_BASE) clean
	touch $@

.PHONY: build-cross-helloworld
build-cross-helloworld: $(TEST_ENV_CROSS_LINK_HELLOWORLD)
	make -C $(TEST_ENV_CROSS_BASE)

.PHONY: run-cross-helloworld
run-cross-helloworld: $(TEST_ENV_CROSS_LINK_HELLOWORLD)
	make run -C $(TEST_ENV_CROSS_BASE)

# Profiling on CROSS

TEST_ENV_CROSS_LINK_PROFILING = $(TEST_ENV_CROSS_BASE)/test_loaded_profiling
$(TEST_ENV_CROSS_LINK_PROFILING):
	rm -f $(TEST_ENV_CROSS_SYMLINK)
	ln -s ../../../$(TEST_PROFILING_DIR) $(TEST_ENV_CROSS_SYMLINK)
	rm -f $(TEST_ENV_CROSS_BASE)/test_loaded_*
	make -C $(TEST_ENV_CROSS_BASE) clean
	touch $@

.PHONY: build-cross-profiling
build-cross-profiling: $(TEST_ENV_CROSS_LINK_PROFILING)
	make -C $(TEST_ENV_CROSS_BASE)

.PHONY: run-cross-profiling
run-cross-profiling: $(TEST_ENV_CROSS_LINK_PROFILING)
	make run -C $(TEST_ENV_CROSS_BASE)

# NTT test on cross

TEST_ENV_CROSS_LINK_NTT_NEON = $(TEST_ENV_CROSS_BASE)/test_loaded_ntt_neon
$(TEST_ENV_CROSS_LINK_NTT_NEON): $(TEST_NTT_NEON_SRC_AUTO)
	rm -f $(TEST_ENV_CROSS_SYMLINK)
	ln -s ../../../$(TEST_NTT_NEON_DIR) $(TEST_ENV_CROSS_SYMLINK)
	rm -f $(TEST_ENV_CROSS_BASE)/test_loaded_*
	make -C $(TEST_ENV_CROSS_BASE) clean
	touch $@

.PHONY: build-cross-ntt_neon
build-cross-ntt_neon: $(TEST_ENV_CROSS_LINK_NTT_NEON)
	make -C $(TEST_ENV_CROSS_BASE)

.PHONY: run-cross-ntt_neon
run-cross-ntt_neon: $(TEST_ENV_CROSS_LINK_NTT_NEON)
	make run -C $(TEST_ENV_CROSS_BASE)

.PHONY: debug-cross-ntt_neon
debug-cross-ntt_neon: $(TEST_ENV_CROSS_LINK_NTT_NEON)
	make debug -C $(TEST_ENV_CROSS_BASE)

# Keccak on CROSS

TEST_ENV_CROSS_LINK_KECCAK_NEON = $(TEST_ENV_CROSS_BASE)/test_loaded_keccak_neon
$(TEST_ENV_CROSS_LINK_KECCAK_NEON): $(TEST_KECCAK_NEON_SRC_MANUAL)
	rm -f $(TEST_ENV_CROSS_SYMLINK)
	ln -s ../../../$(TEST_KECCAK_NEON_DIR) $(TEST_ENV_CROSS_SYMLINK)
	rm -f $(TEST_ENV_CROSS_BASE)/test_loaded_*
	make -C $(TEST_ENV_CROSS_BASE) clean
	touch $@

.PHONY: build-cross-keccak_neon
build-cross-keccak_neon: $(TEST_ENV_CROSS_LINK_KECCAK_NEON)
	make -C $(TEST_ENV_CROSS_BASE)

.PHONY: run-cross-keccak_neon
run-cross-keccak_neon: $(TEST_ENV_CROSS_LINK_KECCAK_NEON)
	make run -C $(TEST_ENV_CROSS_BASE)

# Kyber NTT on CROSS

TEST_ENV_CROSS_LINK_NTT_KYBER = $(TEST_ENV_CROSS_BASE)/test_loaded_ntt_kyber
$(TEST_ENV_CROSS_LINK_NTT_KYBER): $(TEST_NTT_KYBER_SRC_MANUAL)
	rm -f $(TEST_ENV_CROSS_SYMLINK)
	ln -s ../../../$(TEST_NTT_KYBER_DIR) $(TEST_ENV_CROSS_SYMLINK)
	rm -f $(TEST_ENV_CROSS_BASE)/test_loaded_*
	make -C $(TEST_ENV_CROSS_BASE) clean
	touch $@

.PHONY: build-cross-ntt_kyber
build-cross-ntt_kyber: $(TEST_ENV_CROSS_LINK_NTT_KYBER)
	make -C $(TEST_ENV_CROSS_BASE)

.PHONY: run-cross-ntt_kyber
run-cross-ntt_kyber: $(TEST_ENV_CROSS_LINK_NTT_KYBER)
	make run -C $(TEST_ENV_CROSS_BASE)

# Dilithium NTT on CROSS

TEST_ENV_CROSS_LINK_NTT_DILITHIUM = $(TEST_ENV_CROSS_BASE)/test_loaded_ntt_dilithium
$(TEST_ENV_CROSS_LINK_NTT_DILITHIUM): $(TEST_NTT_DILITHIUM_SRC_MANUAL)
	rm -f $(TEST_ENV_CROSS_SYMLINK)
	ln -s ../../../$(TEST_NTT_DILITHIUM_DIR) $(TEST_ENV_CROSS_SYMLINK)
	rm -f $(TEST_ENV_CROSS_BASE)/test_loaded_*
	make -C $(TEST_ENV_CROSS_BASE) clean
	touch $@

.PHONY: build-cross-ntt_dilithium
build-cross-ntt_dilithium: $(TEST_ENV_CROSS_LINK_NTT_DILITHIUM)
	make -C $(TEST_ENV_CROSS_BASE)

.PHONY: run-cross-ntt_dilithium
run-cross-ntt_dilithium: $(TEST_ENV_CROSS_LINK_NTT_DILITHIUM)
	make run -C $(TEST_ENV_CROSS_BASE)

# X25519 on CROSS

TEST_ENV_CROSS_LINK_X25519 = $(TEST_ENV_CROSS_BASE)/test_loaded_x25519
$(TEST_ENV_CROSS_LINK_X25519): $(TEST_X25519_SRC_MANUAL)
	rm -f $(TEST_ENV_CROSS_SYMLINK)
	ln -s ../../../$(TEST_X25519_DIR) $(TEST_ENV_CROSS_SYMLINK)
	rm -f $(TEST_ENV_CROSS_BASE)/test_loaded_*
	make -C $(TEST_ENV_CROSS_BASE) clean
	touch $@

.PHONY: build-cross-x25519
build-cross-x25519: $(TEST_ENV_CROSS_LINK_X25519)
	make -C $(TEST_ENV_CROSS_BASE)

.PHONY: run-cross-x25519
run-cross-x25519: $(TEST_ENV_CROSS_LINK_X25519)
	make run -C $(TEST_ENV_CROSS_BASE)

# NTT-SVE2 test on CROSS

TEST_ENV_CROSS_LINK_NTT_SVE2 = $(TEST_ENV_CROSS_BASE)/test_loaded_ntt_sve2
$(TEST_ENV_CROSS_LINK_NTT_SVE2): $(TEST_NTT_SVE2_SRC_AUTO) $(TEST_NTT_SVE2_SRC_MANUAL)
	rm -f $(TEST_ENV_CROSS_SYMLINK)
	ln -s ../../../$(TEST_NTT_SVE2_DIR) $(TEST_ENV_CROSS_SYMLINK)
	rm -f $(TEST_ENV_CROSS_BASE)/test_loaded_*
	make -C $(TEST_ENV_CROSS_BASE) clean
	touch $@

.PHONY: build-cross-ntt_sve2
build-cross-ntt_sve2: $(TEST_ENV_CROSS_LINK_NTT_SVE2)
	PLATFORM=v84a make -C $(TEST_ENV_CROSS_BASE)

.PHONY: run-cross-ntt_sve2
run-cross-ntt_sve2: $(TEST_ENV_CROSS_LINK_NTT_SVE2)
	make run -C $(TEST_ENV_CROSS_BASE)

.PHONY: debug-cross-ntt_sve2
debug-cross-ntt_sve2: $(TEST_ENV_CROSS_LINK_NTT_SVE2)
	make debug -C $(TEST_ENV_CROSS_BASE)

# HelloWorld native

TEST_ENV_NATIVE_MAC_LINK_HELLOWORLD = $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_helloworld
$(TEST_ENV_NATIVE_MAC_LINK_HELLOWORLD):
	rm -f $(TEST_ENV_NATIVE_MAC_SYMLINK)
	ln -s ../../../$(TEST_HELLOWORLD_DIR) $(TEST_ENV_NATIVE_MAC_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_MAC_BASE) clean
	touch $@

.PHONY: build-native_mac-helloworld
build-native_mac-helloworld: $(TEST_ENV_NATIVE_MAC_LINK_HELLOWORLD)
	make -C $(TEST_ENV_NATIVE_MAC_BASE)

.PHONY: run-native_mac-helloworld
run-native_mac-helloworld: $(TEST_ENV_NATIVE_MAC_LINK_HELLOWORLD)
	make run -C $(TEST_ENV_NATIVE_MAC_BASE)

# Profiling native

TEST_ENV_NATIVE_MAC_LINK_PROFILING = $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_profiling
$(TEST_ENV_NATIVE_MAC_LINK_PROFILING):
	rm -f $(TEST_ENV_NATIVE_MAC_SYMLINK)
	ln -s ../../../$(TEST_PROFILING_DIR) $(TEST_ENV_NATIVE_MAC_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_MAC_BASE) clean
	touch $@

.PHONY: build-native_mac-profiling
build-native_mac-profiling: $(TEST_ENV_NATIVE_MAC_LINK_PROFILING)
	make -C $(TEST_ENV_NATIVE_MAC_BASE)

.PHONY: run-native_mac-profiling
run-native_mac-profiling: $(TEST_ENV_NATIVE_MAC_LINK_PROFILING)
	make run -C $(TEST_ENV_NATIVE_MAC_BASE)

# Keccak native_mac
TEST_ENV_NATIVE_MAC_LINK_KECCAK_NEON = $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_keccak_neon
$(TEST_ENV_NATIVE_MAC_LINK_KECCAK_NEON): $(TEST_KECCAK_NEON_SRC_MANUAL)
	rm -f $(TEST_ENV_NATIVE_MAC_SYMLINK)
	ln -s ../../../$(TEST_KECCAK_NEON_DIR) $(TEST_ENV_NATIVE_MAC_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_MAC_BASE) clean
	touch $@

.PHONY: build-native_mac-keccak_neon
build-native_mac-keccak_neon: $(TEST_ENV_NATIVE_MAC_LINK_KECCAK_NEON)
	make -C $(TEST_ENV_NATIVE_MAC_BASE)

.PHONY: run-native_mac-keccak_neon
run-native_mac-keccak_neon: $(TEST_ENV_NATIVE_MAC_LINK_KECCAK_NEON)
	make run -C $(TEST_ENV_NATIVE_MAC_BASE)

# Kyber NTT native_mac
TEST_ENV_NATIVE_MAC_LINK_NTT_KYBER = $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_ntt_kyber
$(TEST_ENV_NATIVE_MAC_LINK_NTT_KYBER): $(TEST_NTT_KYBER_SRC_MANUAL)
	rm -f $(TEST_ENV_NATIVE_MAC_SYMLINK)
	ln -s ../../../$(TEST_NTT_KYBER_DIR) $(TEST_ENV_NATIVE_MAC_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_MAC_BASE) clean
	touch $@

.PHONY: build-native_mac-ntt_kyber
build-native_mac-ntt_kyber: $(TEST_ENV_NATIVE_MAC_LINK_NTT_KYBER)
	make -C $(TEST_ENV_NATIVE_MAC_BASE)

.PHONY: run-native_mac-ntt_kyber
run-native_mac-ntt_kyber: $(TEST_ENV_NATIVE_MAC_LINK_NTT_KYBER)
	make run -C $(TEST_ENV_NATIVE_MAC_BASE)

# Dilithium NTT native_mac
TEST_ENV_NATIVE_MAC_LINK_NTT_DILITHIUM = $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_ntt_dilithium
$(TEST_ENV_NATIVE_MAC_LINK_NTT_DILITHIUM): $(TEST_NTT_DILITHIUM_SRC_MANUAL)
	rm -f $(TEST_ENV_NATIVE_MAC_SYMLINK)
	ln -s ../../../$(TEST_NTT_DILITHIUM_DIR) $(TEST_ENV_NATIVE_MAC_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_MAC_BASE) clean
	touch $@

.PHONY: build-native_mac-ntt_dilithium
build-native_mac-ntt_dilithium: $(TEST_ENV_NATIVE_MAC_LINK_NTT_DILITHIUM)
	make -C $(TEST_ENV_NATIVE_MAC_BASE)

.PHONY: run-native_mac-ntt_dilithium
run-native_mac-ntt_dilithium: $(TEST_ENV_NATIVE_MAC_LINK_NTT_DILITHIUM)
	make run -C $(TEST_ENV_NATIVE_MAC_BASE)

# X25519 native_mac
TEST_ENV_NATIVE_MAC_LINK_X25519 = $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_x25519
$(TEST_ENV_NATIVE_MAC_LINK_X25519): $(TEST_X25519_SRC_MANUAL)
	rm -f $(TEST_ENV_NATIVE_MAC_SYMLINK)
	ln -s ../../../$(TEST_X25519_DIR) $(TEST_ENV_NATIVE_MAC_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_MAC_BASE) clean
	touch $@

.PHONY: build-native_mac-x25519
build-native_mac-x25519: $(TEST_ENV_NATIVE_MAC_LINK_X25519)
	make -C $(TEST_ENV_NATIVE_MAC_BASE)

.PHONY: run-native_mac-x25519
run-native_mac-x25519: $(TEST_ENV_NATIVE_MAC_LINK_X25519)
	make run -C $(TEST_ENV_NATIVE_MAC_BASE)

# NTT Neon native_mac

TEST_ENV_NATIVE_MAC_LINK_NTT_NEON = $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_ntt_neon
$(TEST_ENV_NATIVE_MAC_LINK_NTT_NEON): $(TEST_NTT_NEON_SRC_AUTO)
	rm -f $(TEST_ENV_NATIVE_MAC_SYMLINK)
	ln -s ../../../$(TEST_NTT_NEON_DIR) $(TEST_ENV_NATIVE_MAC_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_MAC_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_MAC_BASE) clean
	touch $@

.PHONY: build-native_mac-ntt_neon
build-native_mac-ntt_neon: $(TEST_ENV_NATIVE_MAC_LINK_NTT_NEON)
	make -C $(TEST_ENV_NATIVE_MAC_BASE)

.PHONY: run-native_mac-ntt_neon
run-native_mac-ntt_neon: $(TEST_ENV_NATIVE_MAC_LINK_NTT_NEON)
	make run -C $(TEST_ENV_NATIVE_MAC_BASE)


# HelloWorld native_linux

TEST_ENV_NATIVE_LINUX_LINK_HELLOWORLD = $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_helloworld
$(TEST_ENV_NATIVE_LINUX_LINK_HELLOWORLD):
	rm -f $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	ln -s ../../../$(TEST_HELLOWORLD_DIR) $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_LINUX_BASE) clean
	touch $@

.PHONY: build-native_linux-helloworld
build-native_linux-helloworld: $(TEST_ENV_NATIVE_LINUX_LINK_HELLOWORLD)
	make -C $(TEST_ENV_NATIVE_LINUX_BASE)

.PHONY: run-native_linux-helloworld
run-native_linux-helloworld: $(TEST_ENV_NATIVE_LINUX_LINK_HELLOWORLD)
	make run -C $(TEST_ENV_NATIVE_LINUX_BASE)

# Keccak native_linux
TEST_ENV_NATIVE_LINUX_LINK_KECCAK_NEON = $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_keccak_neon
$(TEST_ENV_NATIVE_LINUX_LINK_KECCAK_NEON): $(TEST_KECCAK_NEON_SRC_MANUAL)
	rm -f $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	ln -s ../../../$(TEST_KECCAK_NEON_DIR) $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_LINUX_BASE) clean
	touch $@

.PHONY: build-native_linux-keccak_neon
build-native_linux-keccak_neon: $(TEST_ENV_NATIVE_LINUX_LINK_KECCAK_NEON)
	make -C $(TEST_ENV_NATIVE_LINUX_BASE)

.PHONY: run-native_linux-keccak_neon
run-native_linux-keccak_neon: $(TEST_ENV_NATIVE_LINUX_LINK_KECCAK_NEON)
	make run -C $(TEST_ENV_NATIVE_LINUX_BASE)

# Kyber NTT native_linux
TEST_ENV_NATIVE_LINUX_LINK_NTT_KYBER = $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_ntt_kyber
$(TEST_ENV_NATIVE_LINUX_LINK_NTT_KYBER): $(TEST_NTT_KYBER_SRC_MANUAL)
	rm -f $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	ln -s ../../../$(TEST_NTT_KYBER_DIR) $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_LINUX_BASE) clean
	touch $@

.PHONY: build-native_linux-ntt_kyber
build-native_linux-ntt_kyber: $(TEST_ENV_NATIVE_LINUX_LINK_NTT_KYBER)
	make -C $(TEST_ENV_NATIVE_LINUX_BASE)

.PHONY: run-native_linux-ntt_kyber
run-native_linux-ntt_kyber: $(TEST_ENV_NATIVE_LINUX_LINK_NTT_KYBER)
	make run -C $(TEST_ENV_NATIVE_LINUX_BASE)

# Dilithium NTT native_linux
TEST_ENV_NATIVE_LINUX_LINK_NTT_DILITHIUM = $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_ntt_dilithium
$(TEST_ENV_NATIVE_LINUX_LINK_NTT_DILITHIUM): $(TEST_NTT_DILITHIUM_SRC_MANUAL)
	rm -f $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	ln -s ../../../$(TEST_NTT_DILITHIUM_DIR) $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_LINUX_BASE) clean
	touch $@

.PHONY: build-native_linux-ntt_dilithium
build-native_linux-ntt_dilithium: $(TEST_ENV_NATIVE_LINUX_LINK_NTT_DILITHIUM)
	make -C $(TEST_ENV_NATIVE_LINUX_BASE)

.PHONY: run-native_linux-ntt_dilithium
run-native_linux-ntt_dilithium: $(TEST_ENV_NATIVE_LINUX_LINK_NTT_DILITHIUM)
	make run -C $(TEST_ENV_NATIVE_LINUX_BASE)

# X25519 on native_linux
TEST_ENV_NATIVE_LINUX_LINK_X25519 = $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_x25519
$(TEST_ENV_NATIVE_LINUX_LINK_X25519): $(TEST_X25519_SRC_MANUAL)
	rm -f $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	ln -s ../../../$(TEST_X25519_DIR) $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_LINUX_BASE) clean
	touch $@

.PHONY: build-native_linux-x25519
build-native_linux-x25519: $(TEST_ENV_NATIVE_LINUX_LINK_X25519)
	make -C $(TEST_ENV_NATIVE_LINUX_BASE)

.PHONY: run-native_linux-x25519
run-native_linux-x25519: $(TEST_ENV_NATIVE_LINUX_LINK_X25519)
	make run -C $(TEST_ENV_NATIVE_LINUX_BASE)

# NTT Neon native_linux

TEST_ENV_NATIVE_LINUX_LINK_NTT_NEON = $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_ntt_neon
$(TEST_ENV_NATIVE_LINUX_LINK_NTT_NEON): $(TEST_NTT_NEON_SRC_AUTO)
	rm -f $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	ln -s ../../../$(TEST_NTT_NEON_DIR) $(TEST_ENV_NATIVE_LINUX_SYMLINK)
	rm -f $(TEST_ENV_NATIVE_LINUX_BASE)/test_loaded_*
	make -C $(TEST_ENV_NATIVE_LINUX_BASE) clean
	touch $@

.PHONY: build-native_linux-ntt_neon
build-native_linux-ntt_neon: $(TEST_ENV_NATIVE_LINUX_LINK_NTT_NEON)
	make -C $(TEST_ENV_NATIVE_LINUX_BASE)

.PHONY: run-native_linux-ntt_neon
run-native_linux-ntt_neon: $(TEST_ENV_NATIVE_LINUX_LINK_NTT_NEON)
	make run -C $(TEST_ENV_NATIVE_LINUX_BASE)
