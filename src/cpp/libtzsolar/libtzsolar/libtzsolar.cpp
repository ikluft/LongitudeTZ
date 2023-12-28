/*
 * libtzsolar.cpp - solar time zone library implementation
 */

#include "libtzsolar.hpp"
#include <stdlib>
#include <iomanip>
#include <sstream>
#include <cmath>

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

// check latitude data and initialize special case for polar regions - internal method called by tz_params()
bool TZSolar::tz_params_latitude ( short longitude, bool use_lon_tz, short latitude ) {
    // special case: use East00/Lon000E (equal to UTC) within 10° latitude of poles
    if ( abs( latitude ) >= limit_latitude - precision_fp ) {
        // note: for polar latitudes, this must set all fields on behalf of the constructor
        lon_tz = use_lon_tz;
        short_name = lon_tz ? "Lon000E" : "East00";
        return true;
    }

    return false;
}


// get timezone parameters (name and minutes offset) - called by constructor
void TZSolar::tz_params ( short longitude, bool use_lon_tz, boost::optional<short> opt_latitude ) {
    // if latitude is provided, use UTC within 10° latitude of poles
    if ( opt_latitude != boost::none ) {
        if ( this->tz_params_latitude( longitude, use_lon_tz, opt_latitude.get() )) {
            return;
        }
    }

    //
    // set time zone from longitude
    //

    // safety check on longitude
    if ( std::abs( longitude ) > max_longitude_fp + precision_fp ) {
        // TODO
    }

    // TODO
}

