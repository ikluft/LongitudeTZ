libtzsolar C++ library
======================

The _libtzsolar_ library is the C++ implementation of the Longitude Time Zones project. Each library integration has its own corresponding implementation of the LongitudeTZ command-line interface (CLI) spec so that black box tests can be performed on it. In addition, library specific unit tests should be implemented.

## "libtzsolar" - the core LongitudeTZ library

There is a "libtzsolar" library which provides the basic API functions of LongitudeTZ in C++. Within that library, the lon-tz program implements the LongitudeTZ CLI spec in order to perform black box testing. But it also makes computations of the API functions available from the command line.

## Current integration libraries

The other libraries in the C++ implementation depend on libtzsolar. Each adds functionality for a specific system or library, isolating the external dependencies within that library.

The "libtzsolar-boost" library uses the BOOST C++ library to implement a custom time zone under the date_time package.

## Possible future integration libraries

Other possible C++ language integrations are being considered, examining feasibility and planning how to add custom time zone's by each library's proper usage.

* [date library ](https://github.com/HowardHinnant/date) for C++11/14/17
* [C++20 time zone library](https://en.cppreference.com/w/cpp/chrono#Time_zone)
* [ICU4C](https://unicode-org.github.io/icu/userguide/icu4c/) - International Components for Unicode (ICU) C++ library

_TODO_: more info in progress
