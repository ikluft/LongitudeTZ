# libtzsolar core library Makefile

# first target is default build targer
.PHONY: all
all: lon-tz

# get common make rules
include ../common.mk

# local settings - either overriding or in addition to common make rules
LDLIBS  = -lboost_program_options $(LDLIBS)

# file lists
CLEAN_FILES = lon-tz lon-tz.o libtzsolar.o
SPOTLESS_FILES = version.hpp

# build targets handled by built-in make rules
lon-tz: lon-tz.o libtzsolar.o
libtzsolar.o: libtzsolar.cpp libtzsolar.hpp
lon-tz.o: version.hpp lon-tz.cpp

# build targets with explicit actions
version.hpp: Changes changes2version.pl version.hpp.tt2
	perl changes2version.pl version.hpp.tt2
