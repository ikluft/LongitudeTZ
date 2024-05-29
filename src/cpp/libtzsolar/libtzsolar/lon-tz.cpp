/*
 * lon-tz.cpp
 */

#include "libtzsolar.hpp"
#include "version.hpp"
#include <string>
#include <iostream>
#include <boost/program_options.hpp>

namespace po = boost::program_options;

int main(int argc, char* argv[])
{
    po::options_description desc("lon-tz longitude time zones tool usage");

    // define options
    desc.add_options()
    ("help", "Display this help message")
    ("version", "Display the version number")
    ("tzfile", "Generate timezone database file")
    ("tzname", po::value<std::string>(), "Select a solar time zone by name")
    ("longitude", po::value<float>(), "Set the longitude parameter for a solar time zone")
    ("latitude", po::value<float>(), "Set the optional latitude parameter for a solar time zone")
    ("type", po::value<std::string>(), "Set the type of a solar time zone as 'longitude' or 'hour', defaults to hour")
    ("get", po::value<std::string>(), "Specify field(s) to print from a solar time zone")
    ;

    // process options
    po::variables_map vm;
    po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
    po::notify(vm);

    // print help
    if (vm.count("help")) {
        std::cout << desc;
        return 0;
    }

    // print version
    if (vm.count("version")) {
        std::cout << "Longitude time zones library, C++ implementation version " << lon_tz_version.full;
        return 0;
    }

    // check that one and only one of the mutually-exclusive arguments was provided
    bool has_tzfile = vm.count("tzfile") > 0;
    bool has_tzname = vm.count("tzname") > 0;
    bool has_lon = vm.count("longitude") > 0;
    if ((has_tzfile ? 1 : 0) + (has_tzname ? 1 : 0) + (has_lon ? 1 : 0) != 1 ) {
        std::cerr << "Mutually exclusive arguments: one and only one of --tzfile, --tzname or --longitude allowed";
        std::cerr << desc;
        return 1;
    }

    // output tzfile time zone data
    if ( has_tzfile ) {
        // TODO
        return 0;
    }

    // process time zone queries specified from --tzname or --longitude
    if ( has_tzname ) {
        // TODO
    } else if ( has_lon ) {
        // TODO
    }

    // TODO
    return 0;
}
