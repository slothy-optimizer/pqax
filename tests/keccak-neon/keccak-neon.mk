# Test name - needs to match the directory name
TESTS += keccak-neon

# All further variables must be prefixed with the capitalized test name

# Platforms this test should run on (matching the directory name in envs/)
KECCAK_NEON_PLATFORMS += cross-v8a
KECCAK_NEON_PLATFORMS += cross-v84a
KECCAK_NEON_PLATFORMS += native-linux-v8a
KECCAK_NEON_PLATFORMS += native-linux-v84a
KECCAK_NEON_PLATFORMS += native-mac

# C sources required for this test
KECCAK_NEON_SOURCES += main.c
KECCAK_NEON_SOURCES += keccak_f1600_tests.c
KECCAK_NEON_SOURCES += ../../asm/manual/keccak_f1600/keccak_f1600_x1_scalar_C.c
KECCAK_NEON_SOURCES += ../../asm/manual/keccak_f1600/third_party/keccakx2_C.c
KECCAK_NEON_SOURCES += ../../asm/manual/keccak_f1600/third_party/keccakx2_cothan.c


# Assembly sources required for this test

KECCAK_NEON_ASM_DIR = ../../asm/manual/keccak_f1600
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/third_party/keccakx2_bas.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x1_scalar_asm_v1.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x1_scalar_asm_v2.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x1_scalar_asm_v3.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x1_scalar_asm_v4.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x1_scalar_asm_v5.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_hybrid_asm_v1.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_hybrid_asm_v2p0.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_hybrid_asm_v2p1.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_hybrid_asm_v2p2.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_hybrid_asm_v2pp0.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_hybrid_asm_v2pp1.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_hybrid_asm_v2pp2.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v1.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v1p0.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2p0.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2p1.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2p2.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2p3.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2p4.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2p5.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2p6.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2pp0.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2pp1.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2pp2.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2pp3.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2pp4.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2pp5.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2pp6.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x2_v84a_asm_v2pp7.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x3_hybrid_asm_v3p.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x3_hybrid_asm_v6.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x3_hybrid_asm_v7.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v1.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v2.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v2p0.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v3.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v3p.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v3pp.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v4.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v4p.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v5.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v5p.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v6.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v7.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_asm_v8.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_scalar_asm_v1.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_scalar_asm_v5.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_v84a_asm_v1p0.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x5_hybrid_asm_v8.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x5_hybrid_asm_v8p.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_slothy.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x4_hybrid_slothy_a55_opt_a55.s
KECCAK_NEON_ASMS += $(KECCAK_NEON_ASM_DIR)/keccak_f1600_x1_scalar_no_symbolic_opt_a55.s