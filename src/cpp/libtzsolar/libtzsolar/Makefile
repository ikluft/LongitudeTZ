# libtzsolar core library Makefile

# first target is default build targer
.PHONY: all
all: lon-tz

# get common make rules
include ../common.mk

# local settings - either overriding or in addition to common make rules
LDLIBS += -lboost_program_options

# file lists
CLEAN_FILES = lon-tz lon-tz.o libtzsolar.o
SPOTLESS_FILES = version.hpp

# build targets handled by built-in make rules
lon-tz: lon-tz.o libtzsolar.o
lon-tz.o: lon-tz.cpp CLI.hpp libtzsolar.hpp version.hpp
libtzsolar.o: libtzsolar.cpp libtzsolar.hpp

# build targets with explicit actions
version.hpp: Changes changes2version.pl version.hpp.tt2
	perl changes2version.pl version.hpp.tt2
