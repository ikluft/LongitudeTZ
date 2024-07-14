# placeholder for tests directory

.PHONY: all clean

all: test-core

# get common make rules
include ../common.mk

# local settings - either overriding or in addition to common make rules
CXXFLAGS += -Wno-unused-function

test-core: test-core.o ../libtzsolar/libtzsolar.o
test-core.o: test-core.cpp tappp.hpp ../libtzsolar/version.hpp

clean:

