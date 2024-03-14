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
CXXFLAGS = -std=c++17

libtzsolar.o: libtzsolar.cpp libtzsolar.hpp

.PHONY: clean
clean:
	-rm -f libtzsolar.o
