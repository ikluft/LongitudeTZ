/*
 * lon-tz.cpp
 */

#include "libtzsolar.hpp"
#include "version.hpp"
#include <string>
#include <iostream>
#include <boost/program_options.hpp>

namespace po = boost::program_options;

// convert an int to a string with zero-padding
std::string zeropad(const std::size_t length, const int value)
{
    std::string result = std::to_string(value);
    result.insert(0, length - result.length(), '0');
    return result;
}

// generate standard 1-hour-wide (15 degrees longitude) time zones
// input parameter: integer hours from GMT in the range
// These correspond to the GMT+x/GMT-x time zones, except with boundaries defined by longitude lines.
void gen_hour_tz(const short hour) {
    // validate parameter
    if (hour<-12 || hour>12) {
        std::cerr << "gen_hour_tz: hour parameter must be -12 to +12 inclusive" << std::endl;
        std::exit(1);
    }

    // Hours line up with time zones. So it's a equal to time zone offset.
    std::string sign = (hour >= 0) ? "+" : "-";
    std::string e_w = (hour >= 0) ? "East" : "West";
    unsigned short offset_hr = std::abs(hour);
    unsigned short offset_min = 0;

    // generate strings from time zone parameters
    std::string zone_abbrev = e_w + zeropad(2, hour);
    std::string zone_name = "Solar/" + zone_abbrev;
    std::string offset_str = sign + std::to_string(offset_hr) + zeropad(2, offset_min);

    // output time zone data
    std::cout << std::string("# Solar Time by hourly increment: ") << sign << offset_hr << std::endl;
    std::cout << "# Zone\tNAME\t\tSTDOFF\tRULES\tFORMAT\t[UNTIL]" << std::endl;
    std::cout << "Zone\t" << zone_name << "\t" << offset_str << "\t-\t" << zone_abbrev << std::endl;
    std::cout << std::endl;
    return;
}

// generate longitude-based solar time zone info
// input parameter: integer degrees of longitude in the range 180 to -180,
// Solar Time Zone centered on the meridian, including one half degree either side of the meridian.
// Each time zone is named for its 1-degree-wide range.
// The exception is at the Solar Date Line, where +12 and -12 time zones are one half degree wide.
void gen_lon_tz(const short deg) {
    // validate parameter
    if (deg<-180 || deg>180) {
        std::cerr << "gen_lon_tz: longitude parameter must be -180 to +180 inclusive" << std::endl;
        std::exit(1);
    }

    // use integer degrees to compute time zone parameters: longitude, east/west sign and minutes offset
    // $deg>=0: positive degrees (east longitude), straightforward assignments of data
    // $deg<0: negative degrees (west longitude)
    unsigned short lon = std::abs(deg);
    std::string e_w = (deg > 0) ? "E" : "W";
    std::string sign = (deg >= 0) ? "+" : "-";

    // derive time zone parameters from 4 minutes of offset for each degree of longitude
    unsigned short offset = 4 * lon;
    unsigned short offset_hr = int(offset/60);
    unsigned short offset_min = offset%60;

    // generate strings from time zone parameters
    std::string zone_abbrev = std::string("Lon") + zeropad(3, lon) + e_w;
    std::string zone_name = std::string("Solar/") + zone_abbrev;
    std::string offset_str = sign + std::to_string(offset_hr) + ":" + zeropad(2, offset_min);

    // output time zone data
    std::cout << std::string("# Solar Time by hourly increment: ") << sign << offset_hr << std::endl;
    std::cout << "# Zone\tNAME\t\tSTDOFF\tRULES\tFORMAT\t[UNTIL]" << std::endl;
    std::cout << "Zone\t" << zone_name << "\t" << offset_str << "\t-\t" << zone_abbrev << std::endl;
    std::cout << std::endl;
    return;
}

// generate and print tzfile data on standard output
void do_tzfile()
{
    // generate solar time zones in increments of 15 degrees of longitude (EastXX or WestXX)
    // standard 1-hour-wide time zones
    for (short h_zone = -12; h_zone <= 12; h_zone++) {
        gen_hour_tz(h_zone);
    }

    // generate solar time zones in incrememnts of 4 minutes / 1 degree of longitude (LonXXXE or LonXXXW)
    // hyperlocal 4-minute-wide time zones for conversion to/from niche uses of local solar time
    for (short d_zone = -180; d_zone <= 180; d_zone++) {
        gen_lon_tz(d_zone);
    }
}

// mainline: program entry point
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
        std::cerr << "Mutually exclusive arguments: one and only one of --tzfile, --tzname or --longitude allowed"
            << std::endl;
        std::cerr << desc;
        return 1;
    }

    // output tzfile time zone data
    if ( has_tzfile ) {
        do_tzfile();
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
