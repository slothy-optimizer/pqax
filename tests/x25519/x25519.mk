# Test name - needs to match the directory name
TESTS += x25519

# All further variables must be prefixed with the capitalized test name

# Platforms this test should run on (matching the directory name in envs/)
X25519_PLATFORMS += cross-v8a
X25519_PLATFORMS += cross-v84a
X25519_PLATFORMS += native-linux-v8a
X25519_PLATFORMS += native-linux-v84a
X25519_PLATFORMS += native-mac

# C sources required for this test
X25519_SOURCES += main.c




X25519_SLOTHY_DIR = ../../slothy/
X25519_SLOTHY_ASM_OPT = $(X25519_SLOTHY_DIR)/examples/opt/aarch64/x25519


# Assembly sources required for this test
X25519_ASMS += ../../asm/manual/x25519/X25519-AArch64.s
X25519_ASMS += $(X25519_SLOTHY_ASM_OPT)/X25519-AArch64-simple_opt.s

