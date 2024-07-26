# Test name - needs to match the directory name
TESTS += ntt-sve2

# All further variables must be prefixed with the capitalized test name

# Platforms this test should run on (matching the directory name in envs/)
NTT_SVE2_PLATFORMS += cross-v84a
NTT_SVE2_PLATFORMS += native-linux-v84a
NTT_SVE2_PLATFORMS += native-mac

# C sources required for this test
NTT_SVE2_SOURCES += main.c
NTT_SVE2_SOURCES += ntt.c

# Assembly sources required for this test
NTT_SVE2_ASMS += ../../asm/manual/basemul_s64/basemul_64_72057594067788289.s

NTT_SVE2_ASMDIR = ../../asm/auto/ntt_sve2
NTT_SVE2_ASMS += $(NTT_SVE2_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_3_3_0.s
NTT_SVE2_ASMS += $(NTT_SVE2_ASMDIR)/ntt_u64_incomplete_72057594067788289_60277548896192635_var_3_3_0.s
NTT_SVE2_ASMS += $(NTT_SVE2_ASMDIR)/ntt_u64_incomplete_72057594067788289_60277548896192635_var_3_3_1.s
NTT_SVE2_ASMS += $(NTT_SVE2_ASMDIR)/ntt_u64_incomplete_72057594067788289_60277548896192635_var_3_3_2.s