/*
 * lon-tz-boost.cpp
 * command line interface for libtzsolar-boost (BOOST C++ implemenation of LongitudeTZ)
 */

#include "libtzsolar-boost.hpp"
#include "../libtzsolar/CLI.hpp"

namespace ltz = longitude_tz;

// mainline: program entry point
int main(int argc, char* argv[])
{
    return ltz::CLI<ltz::solar_time_zone_base<char>>::mainline_core(argc, argv);
}
