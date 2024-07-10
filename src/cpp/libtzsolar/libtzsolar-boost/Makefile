# libtzsolar-boost Makefile

# first target is default build targer
.PHONY: all
all: lon-tz-boost

# get common make rules
include ../common.mk

# local settings - either overriding or in addition to common make rules
LDLIBS += -lboost_program_options
CPPFLAGS += -I../libtzsolar

# file lists
CLEAN_FILES = lon-tz-boost lon-tz-boost.o
SPOTLESS_FILES =

# build targets handled by built-in make rules
lon-tz-boost: lon-tz-boost.o ../libtzsolar/libtzsolar.o
lon-tz-boost.o: lon-tz-boost.cpp libtzsolar-boost.hpp ../libtzsolar/libtzsolar.hpp ../libtzsolar/CLI.hpp ../libtzsolar/version.hpp
../libtzsolar/libtzsolar.o:
	(cd ../libtzsolar; make libtzsolar.o)
