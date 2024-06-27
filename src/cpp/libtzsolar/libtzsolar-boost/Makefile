# libtzsolar-boost Makefile

# first target is default build targer
.PHONY: all
all: libtzsolar-boost.o

# get common make rules
include ../common.mk

# local settings - either overriding or in addition to common make rules
CPPFLAGS += -I../libtzsolar

# file lists
CLEAN_FILES = libtzsolar-boost.o
SPOTLESS_FILES =

# build targets handled by built-in make rules
libtzsolar-boost.o: libtzsolar-boost.cpp libtzsolar-boost.hpp ../libtzsolar/libtzsolar.hpp
