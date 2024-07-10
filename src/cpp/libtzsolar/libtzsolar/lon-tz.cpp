/*
 * lon-tz.cpp
 */

#include "CLI.hpp"
#include "libtzsolar.hpp"

namespace ltz = longitude_tz;

// mainline: program entry point
int main(int argc, char* argv[])
{
    return ltz::CLI<ltz::TZSolar>::mainline_core(argc, argv);
}
