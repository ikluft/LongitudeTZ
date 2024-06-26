libtzsolar C++ library
======================

The _libtzsolar_ library is the C++ implementation of the Longitude Time Zones project.

There is a "libtzsolar" library which provides the basic API functions of LongitudeTZ in C++. Within that library, the lon-tz program implements the LongitudeTZ CLI spec in order to perform black box testing. But it also makes computations of the API functions available from the command line.

The other libraries in the C++ implementation depend on libtzsolar. Each adds functionality for a specific system or library, isolating the external dependencies within that library.

The "libtzsolar-boost" library uses the BOOST C++ library to implement a custom time zone under the date_time package.

_TODO_: more info in progress
