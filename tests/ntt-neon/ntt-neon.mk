# Test name - needs to match the directory name
TESTS += ntt-neon

# All further variables must be prefixed with the capitalized test name

# Platforms this test should run on (matching the directory name in envs/)
NTT_NEON_PLATFORMS += cross-v8a
NTT_NEON_PLATFORMS += cross-v84a
NTT_NEON_PLATFORMS += native-linux-v8a
NTT_NEON_PLATFORMS += native-linux-v84a
NTT_NEON_PLATFORMS += native-mac

# C sources required for this test
NTT_NEON_SOURCES += main.c
NTT_NEON_SOURCES += ntt.c

# Assembly sources required for this test
NTT_NEON_ASMDIR = ../../asm/auto/ntt_neon
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_0_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_1_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_2_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z2_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z2_1.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z2_2.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z2_3.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z2_4.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z2_5.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z4_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z4_1.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z4_2.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z4_3.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_3_z4_4.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_4_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_5_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_6_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_7_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_8_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_9_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_10_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_11_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_12_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_13_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_14_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_15_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_16_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_17_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_full_33556993_28678040_var_4_4_18_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_3_3_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_3_3_1.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_3_3_2.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_3_3_3.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_3_3_4.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_3_3_5.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_0_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_0_z4_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_0_z4_16.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_3_z4_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_3_z4_1.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_3_z4_2.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_3_z4_3.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_3_z4_4.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_3_z4_5.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_1.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_2.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_3.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_4.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_5.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_6.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_8.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_9.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_7_z4_10.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_8_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_9_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_10_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_11_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_12_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_13_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_14_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_15_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_16_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_17_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_18_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_19_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_20_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_21_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_22_z4_7.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_22_z4_8.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_22_z4_9.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_22_z4_10.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_22_z4_11.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_22_z4_12.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_22_z4_13.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_22_z4_14.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_22_z4_15.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_24_z4_0.s
NTT_NEON_ASMS += $(NTT_NEON_ASMDIR)/ntt_u32_incomplete_33556993_28678040_var_4_2_24_z4_16.s