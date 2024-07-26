# Test name - needs to match the directory name
TESTS += helloworld

# All further variables must be prefixed with the capitalized test name

# Platforms this test should run on (matching the directory name in envs/)
HELLOWORLD_PLATFORMS += cross-v8a
HELLOWORLD_PLATFORMS += cross-v84a
HELLOWORLD_PLATFORMS += native-linux-v8a
HELLOWORLD_PLATFORMS += native-linux-v84a
HELLOWORLD_PLATFORMS += native-mac

# C sources required for this test
HELLOWORLD_SOURCES += main.c

# Assembly sources required for this test
HELLOWORLD_ASMS += neon_test.s

