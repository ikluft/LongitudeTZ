/*
 * libtzsolar.cpp - solar time zone library implementation
 */

#include "libtzsolar.hpp"

// generate a solar time zone name
// parameters:
//   tz_num: integer number for time zone - hourly or longitude based depending on use_lon_tz
//   use_lon_tz: true=use longitude-based time zones, false=use hour-based time zones
//   sign: +1 = positive/zero, -1 = negative
std::string TZSolar::tz_name ( int tz_num, bool use_lon_tz, short sign ) {
    // generate time zone name prefix and suffix
    std::string prefix = use_lon_tz ? "Lon" : ( sign > 0 ? "East" : "West" );
    std::string suffix = use_lon_tz ? "" : ( sign > 0 ? "E" : "W" );

    // generate string for digits in time zone name
    int tz_digits = use_lon_tz ? 3 : 2;
    std::ostringstream ss;
    ss << std::setw( tz_digits ) << std::setfill( '0' ) << tz_num;
    std::string tz_numstr = ss.str();

    // return time zone name
    return prefix + tz_numstr + suffix;
}

    // get timezone parameters (name and minutes offset) - called by constructor
    void tz_params ( short longitude, bool use_lon_tz, boost::optional<short> latitude ) {
        // if latitude is provided, use UTC within 10° latitude of poles
        if ( latitude != boost::none ) {
            // TODO
        }
        // TODO
    }

