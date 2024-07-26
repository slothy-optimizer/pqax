# Test name - needs to match the directory name
TESTS += ntt-kyber

# All further variables must be prefixed with the capitalized test name

# Platforms this test should run on (matching the directory name in envs/)
NTT_KYBER_PLATFORMS += cross-v8a
NTT_KYBER_PLATFORMS += cross-v84a

# C sources required for this test
NTT_KYBER_SOURCES += main.c
NTT_KYBER_SOURCES += pqclean.c
NTT_KYBER_SOURCES += neonntt.c

# Assembly sources required for this test
NTT_KYBER_ASMS += neonntt_asm.s
NTT_KYBER_ASMS += pqclean_asm.s

NTT_KYBER_ASMDIR = ../../asm/manual/ntt_kyber
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567_manual_ld4_opt_a55.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567_manual_ld4_opt_a72.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567_manual_ld4_opt_m1_firestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567_manual_ld4_opt_m1_icestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567_manual_ld4.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567_opt_a55.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567_opt_a72.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567_opt_m1_firestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567_opt_m1_icestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/intt_kyber_123_4567.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_manual_st4_opt_a55.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_manual_st4_opt_a72.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_manual_st4_opt_m1_firestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_manual_st4_opt_m1_icestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_manual_st4.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_opt_a55.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_opt_a72.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_opt_m1_firestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_opt_m1_icestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load_opt_a55.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load_opt_a72.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load_opt_m1_firestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load_opt_m1_icestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load_store_opt_a55.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load_store_opt_a72.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load_store_opt_m1_firestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load_store_opt_m1_icestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load_store.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_load.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_store_opt_a55.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_store_opt_a72.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_store_opt_m1_firestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_store_opt_m1_icestorm.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567_scalar_store.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_123_4567.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_1234_567_opt_a72.s
NTT_KYBER_ASMS += $(NTT_KYBER_ASMDIR)/ntt_kyber_1234_567.s