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
CPPFLAGS = $(OPENSSF_CPPFLAGS)
CXXFLAGS = -std=gnu++17
LDLIBS  = -lboost_program_options
LDFLAGS = -Wl,--copy-dt-needed-entries

# file lists
.PHONY: all clean spotless
CLEAN_FILES = lon-tz lon-tz.o libtzsolar.o
SPOTLESS_FILES = version.hpp

# first target is default build targer
all: lon-tz

# build targets handled by built-in make rules
lon-tz: lon-tz.o libtzsolar.o
libtzsolar.o: libtzsolar.cpp libtzsolar.hpp
lon-tz.o: version.hpp lon-tz.cpp

# build targets with explicit actions
version.hpp: Changes changes2version.pl version.hpp.tt2
	perl changes2version.pl version.hpp.tt2

# cleanup targets
clean:
	-rm -f $(CLEAN_FILES)
spotless: clean
	-rm -f $(SPOTLESS_FILES)
