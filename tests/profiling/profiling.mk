# Test name - needs to match the directory name
TESTS += profiling

# All further variables must be prefixed with the capitalized test name

# Platforms this test should run on (matching the directory name in envs/)
PROFILING_PLATFORMS += cross-v8a
PROFILING_PLATFORMS += cross-v84a
PROFILING_PLATFORMS += cross-v9a

# C sources required for this test
PROFILING_SOURCES += main.c
PROFILING_SOURCES += profiler.c
PROFILING_SOURCES += profiling.c

# Assembly sources required for this test
PROFILING_ASMS += prefix_ubenchs.s
PROFILING_ASMS += ubenchs.s

