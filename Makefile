# Tests
include tests/helloworld/helloworld.mk
include tests/keccak-neon/keccak-neon.mk


# TODO: Check if all those are needed
testname = $(shell echo $(1) | tr '[a-z]' '[A-Z]' | tr '-' '_' | tr '/' '_')
testdir = $(addprefix $(2),tests/$(firstword $(subst /, ,$1))/)
testsources = $(addprefix $(2),$(addprefix $(call testdir,$1,),$($(call testname,$(1))_SOURCES)))
testasms = $(addprefix $(2),$(addprefix $(call testdir,$1,),$($(call testname,$(1))_ASMS)))
testother = $(addprefix $(2),$(addprefix $(call testdir,$1,),$($(call testname,$(1))_OTHER)))
testplatforms = $(addsuffix _$(1),$($(call testname,$(1))_PLATFORMS))
testcflags = $($(call testname,$(1))_CFLAGS)
elfname = $(addsuffix -test.elf,$(subst /,-,$1))


platformtests := $(foreach test,$(TESTS), $(call testplatforms,$(test)))

builds          := $(addprefix build-, $(platformtests))
runs            := $(addprefix run-, $(platformtests))
checks          := $(addprefix check-, $(platformtests))
cleans          := $(addprefix clean-, $(platformtests))


.PHONY: all
all: ${builds}

platform = $(firstword $(subst _, ,$*))
test = $(lastword $(subst _, ,$*))

.PHONY: ${builds}
${builds}: build-%:
	make -j$(shell nproc) -C envs/$(platform) build CFLAGS_EXTRA='$(call testcflags,$(test))' SOURCES='$(call testsources,$(test),../../)' ASMS='$(call testasms,$(test),../../)' TARGET=$(call elfname,$(test)) TESTDIR=$(call testdir,$(test),../../)

.PHONY: ${runs}
${runs}: run-%:
	make -C envs/$(platform) run CFLAGS_EXTRA='$(call testcflags,$(test))' SOURCES='$(call testsources,$(test),../../)' ASMS='$(call testasms,$(test),../../)' TARGET=$(call elfname,$(test)) TESTDIR=$(call testdir,$(test),../../)

.PHONY: run
run: ${runs}

.PHONY: ${checks}
${checks}: check-%:
	make -C envs/$(platform) check CFLAGS_EXTRA='$(call testcflags,$(test))' SOURCES='$(call testsources,$(test),../../)' ASMS='$(call testasms,$(test),../../)' TARGET=$(call elfname,$(test)) TESTDIR=$(call testdir,$(test),../../)

.PHONY: check
check: ${checks}

.PHONY: ${cleans}
${cleans}: clean-%:
	make -C envs/$(platform) clean

.PHONY: clean
clean: ${cleans}
