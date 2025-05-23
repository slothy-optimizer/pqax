# Test name - needs to match the directory name
TESTS += ntt-dilithium

# All further variables must be prefixed with the capitalized test name

# Platforms this test should run on (matching the directory name in envs/)
NTT_DILITHIUM_PLATFORMS += cross-v8a
NTT_DILITHIUM_PLATFORMS += cross-v84a
NTT_DILITHIUM_PLATFORMS += native-linux-v8a
NTT_DILITHIUM_PLATFORMS += native-linux-v84a
NTT_DILITHIUM_PLATFORMS += native-mac

# C sources required for this test
NTT_DILITHIUM_SOURCES += main.c
NTT_DILITHIUM_SOURCES += pqclean.c
NTT_DILITHIUM_SOURCES += neonntt.c

# Assembly sources required for this test


NTT_DILITHIUM_SLOTHY_DIR = ../../slothy/
NTT_DILITHIUM_SLOTHY_ASM_NAIVE = $(NTT_DILITHIUM_SLOTHY_DIR)/examples/naive/aarch64/dilithium
NTT_DILITHIUM_SLOTHY_ASM_OPT = $(NTT_DILITHIUM_SLOTHY_DIR)/examples/opt/aarch64/dilithium
NTT_DILITHIUM_SLOTHY_ASM_PAPER_OPT = $(NTT_DILITHIUM_SLOTHY_DIR)/paper/opt/neon
NTT_DILITHIUM_SLOTHY_ASM_PAPER_CLEAN = $(NTT_DILITHIUM_SLOTHY_DIR)/paper/clean/neon


NTT_DILITHIUM_ASM_DIR = ../../asm/manual/ntt_dilithium
NTT_DILITHIUM_ASMS += pqclean_asm.s
NTT_DILITHIUM_ASMS += neonntt_asm.s

NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_CLEAN)/ntt_dilithium_1234_5678.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_NAIVE)/intt_dilithium_1234_5678.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_NAIVE)/ntt_dilithium_1234_5678_manual_st4.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/ntt_dilithium_1234_5678_manual_st4_opt_m1_firestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/ntt_dilithium_1234_5678_manual_st4_opt_m1_icestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_CLEAN)/ntt_dilithium_123_45678_manual_st4.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_OPT)/ntt_dilithium_123_45678_manual_st4_opt_a55.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_OPT)/ntt_dilithium_123_45678_manual_st4_opt_a72.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/ntt_dilithium_123_45678_manual_st4_opt_m1_firestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/ntt_dilithium_123_45678_manual_st4_opt_m1_icestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_CLEAN)/ntt_dilithium_123_45678.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_NAIVE)/intt_dilithium_123_45678.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_CLEAN)/ntt_dilithium_123_45678_w_scalar.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_OPT)/ntt_dilithium_123_45678_w_scalar_opt_a55.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/ntt_dilithium_123_45678_w_scalar_opt_m1_icestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_NAIVE)/intt_dilithium_1234_5678_manual_ld4.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_1234_5678_manual_ld4_opt_a55.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_1234_5678_manual_ld4_opt_a72.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_1234_5678_manual_ld4_opt_m1_firestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_1234_5678_manual_ld4_opt_m1_icestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_NAIVE)/intt_dilithium_123_45678_manual_ld4.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_123_45678_manual_ld4_opt_a55.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_123_45678_manual_ld4_opt_a72.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_123_45678_manual_ld4_opt_m1_firestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_123_45678_manual_ld4_opt_m1_icestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_123_45678_opt_a55.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_123_45678_opt_a72.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_123_45678_opt_m1_firestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_123_45678_opt_m1_icestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_1234_5678_opt_a55.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_1234_5678_opt_a72.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_OPT)/ntt_dilithium_1234_5678_opt_a72.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_1234_5678_opt_m1_firestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/ntt_dilithium_1234_5678_opt_m1_firestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/intt_dilithium_1234_5678_opt_m1_icestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_OPT)/ntt_dilithium_123_45678_opt_a55.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_PAPER_OPT)/ntt_dilithium_123_45678_opt_a72.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/ntt_dilithium_123_45678_opt_m1_firestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/ntt_dilithium_123_45678_opt_m1_icestorm.s
NTT_DILITHIUM_ASMS += $(NTT_DILITHIUM_SLOTHY_ASM_OPT)/ntt_dilithium_1234_5678_opt_m1_icestorm.s




