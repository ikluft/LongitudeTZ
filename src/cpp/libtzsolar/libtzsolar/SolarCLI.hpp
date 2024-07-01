/*
 * SolarCLI.hpp
 * command line interface core/common routines for libtzsolar (C++ implementation of LongitudeTZ)
 */

#include <string>
#include <iostream>
#include <boost/program_options.hpp>
#include <boost/algorithm/string.hpp>

namespace po = boost::program_options;
namespace alg = boost::algorithm;

// convert an int to a string with zero-padding
inline std::string zeropad(const std::size_t length, const unsigned short value)
{
    std::string num = std::to_string(value);
    if (num.length() > length) {
        return num;
    }
    std::string pad(std::size_t(length - num.length()), '0');
    return pad + num;
}


// generate standard 1-hour-wide (15 degrees longitude) time zones
// input parameter: integer hours from GMT in the range
// These correspond to the GMT+x/GMT-x time zones, except with boundaries defined by longitude lines.
inline void gen_hour_tz(const short hour) {
    // validate parameter
    if (hour<-12 || hour>12) {
        std::cerr << "gen_hour_tz: hour parameter must be -12 to +12 inclusive" << std::endl;
        std::exit(1);
    }

    // Hours line up with time zones. So it's a equal to time zone offset.
    std::string sign = (hour >= 0) ? "+" : "-";
    std::string e_w = (hour >= 0) ? "East" : "West";

    // generate strings from time zone parameters
    unsigned short offset_hr = std::abs(hour);
    unsigned short offset_min = 0;
    std::string zone_abbrev = e_w + zeropad(2, offset_hr);
    std::string zone_name = std::string("Solar/") + zone_abbrev;
    std::string offset_str = sign + std::to_string(offset_hr) + ":" + zeropad(2, offset_min);

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
inline void gen_lon_tz(const short deg) {
    // validate parameter
    if (deg<-180 || deg>180) {
        std::cerr << "gen_lon_tz: longitude parameter must be -180 to +180 inclusive" << std::endl;
        std::exit(1);
    }

    // use integer degrees to compute time zone parameters: longitude, east/west sign and minutes offset
    // $deg>=0: positive degrees (east longitude), straightforward assignments of data
    // $deg<0: negative degrees (west longitude)
    std::string sign = (deg >= 0) ? "" : "-";
    std::string e_w = (deg >= 0) ? "E" : "W";

    // derive time zone parameters from 4 minutes of offset for each degree of longitude
    unsigned short lon = std::abs(deg);
    unsigned short offset = 4 * lon;
    unsigned short offset_hr = int(offset/60);
    unsigned short offset_min = offset%60;

    // generate strings from time zone parameters
    std::string zone_abbrev = std::string("Lon") + zeropad(3, lon) + e_w;
    std::string zone_name = std::string("Solar/") + zone_abbrev;
    std::string offset_str = sign + std::to_string(offset_hr) + ":" + zeropad(2, offset_min);

    // output time zone data
    std::cout << std::string("# Solar Time by degree of longitude: ") << lon << " " << e_w << std::endl;
    std::cout << "# Zone\tNAME\t\tSTDOFF\tRULES\tFORMAT\t[UNTIL]" << std::endl;
    std::cout << "Zone\t" << zone_name << "\t" << offset_str << "\t-\t" << zone_abbrev << std::endl;
    std::cout << std::endl;
    return;
}

// generate and print tzfile data on standard output
inline void do_tzfile()
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


