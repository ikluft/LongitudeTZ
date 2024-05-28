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

    if (vm.count("tzfile")) {
        if (vm.count("tzname") || vm.count("longitude")) {
            std::cerr << "Mutually exclusive arguments: --tzfile cannot be combined with --tzname or --longitude";
            std::cerr << desc;
            return 1;
        }
        // TODO
        return 0;
    }

    if (vm.count("tzname")) {
        if (vm.count("longitude")) {
            std::cerr << "Mutually exclusive arguments: --tzname cannot be combined with --longitude";
            std::cerr << desc;
            return 1;
        }
        // TODO
        return 0;
    }

    if (!vm.count("longitude")) {
        std::cerr << "One argument of --tzfile, --tzname or --longitude is required";
        std::cerr << desc;
        return 1;
    }

    // TODO
    return 0;
}
