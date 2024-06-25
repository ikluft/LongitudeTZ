# Makefile elements common to subdirectories of libtzsolar (C++ implementation of LongitudeTZ)

# flags recommended by Open Source Security Foundation (OpenSSF)
# https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++
OPENSSF_CPPFLAGS=-O2 -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough \
        -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 \
        -D_GLIBCXX_ASSERTIONS \
        -fstrict-flex-arrays=3 \
        -fstack-clash-protection -fstack-protector-strong \
        -Wl,-z,nodlopen -Wl,-z,noexecstack \
        -Wl,-z,relro -Wl,-z,now

# compiler & linker flags
# add DEBUG_FLAGS=-g to make command line in order to build with debugging
DEBUG_FLAGS +=
CPPFLAGS += $(OPENSSF_CPPFLAGS) $(DEBUG_FLAGS)
CXXFLAGS += -std=gnu++17
LDLIBS  +=
LDFLAGS += -Wl,--copy-dt-needed-entries $(DEBUG_FLAGS)

# cleanup targets
.PHONY: clean spotless
clean:
	-[ -n "$(CLEAN_FILES)" ] && rm -f $(CLEAN_FILES)
spotless: clean
	-[ -n "$(SPOTLESS_FILES)" ] && rm -f $(SPOTLESS_FILES)

