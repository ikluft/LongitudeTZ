/*
 * libtzsolar.cpp - solar time zone library implementation
 */

#include "libtzsolar.hpp"
#include <cstdlib>
#include <stdexcept>
#include <string>
#include <iomanip>
#include <sstream>
#include <cmath>
#include <unordered_map>
#include <functional>
#include <optional>

// generate a solar time zone name
// parameters:
//   tz_num: integer number for time zone - hourly or longitude based depending on use_lon_tz
//   use_lon_tz: true=use longitude-based time zones, false=use hour-based time zones
//   sign: +1 = positive/zero, -1 = negative
std::string TZSolar::tz_name ( const unsigned short tz_num, const bool use_lon_tz, const short sign ) {
    // generate time zone name prefix and suffix
    std::string prefix = use_lon_tz ? "Lon" : ( sign > 0 ? "East" : "West" );
    std::string suffix = use_lon_tz ? "" : ( sign > 0 ? "E" : "W" );

    // generate string for digits in time zone name
    unsigned short num_digits = use_lon_tz ? 3 : 2;
    std::ostringstream ss;
    ss << std::setw( num_digits ) << std::setfill( '0' ) << tz_num;
    std::string tz_numstr = ss.str();

    // return time zone name
    return prefix + tz_numstr + suffix;
}

// check latitude data and initialize special case for polar regions - internal method called by tz_params()
bool TZSolar::tz_params_latitude ( const short longitude, const bool use_lon_tz, const short latitude ) {
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
void TZSolar::tz_params (const short longitude, const bool use_lon_tz, const std::optional<short> opt_latitude ) {
    // if latitude is provided, use UTC within 10° latitude of poles
    if ( ! opt_latitude.has_value() ) {
        if ( this->tz_params_latitude( longitude, use_lon_tz, opt_latitude.value() )) {
            return;
        }
    }

    //
    // set time zone from longitude
    //

    // safety check on longitude
    if ( std::abs( longitude ) > max_longitude_fp + precision_fp ) {
        throw std::out_of_range( "longitude out of range -180 to +180" );
    }

    // set flag for longitude time zones: 0 = hourly 1-hour/15-degree zones, 1 = longitude 4-minute/1-degree zones
    // defaults to hourly time zone ($use_lon_tz=0)
    lon_tz = use_lon_tz;

    // handle special case of half-wide tz at positive side of solar date line (180° longitude)
    if (( longitude >= max_longitude_int - this->tz_degree_width() / 2.0 - precision_fp )
        || ( longitude <= -max_longitude_int + precision_fp ))
    {
        short_name = tz_name(( unsigned short )( max_longitude_int / tz_degree_width()), use_lon_tz, 1 );
        offset_min = 720;
        return;
    }

    // handle special case of half-wide tz at negative side of solar date line (180° longitude)
    if ( longitude <= -max_longitude_int + this->tz_degree_width() / 2.0 + precision_fp ) {
        short_name = tz_name(( unsigned short)( max_longitude_int / tz_degree_width()), use_lon_tz, -1 );
        offset_min = -720;
        return;
    }

    // handle other times zones
    unsigned short tz_num = ( unsigned short )( std::abs (( double ) longitude / tz_degree_width() + 0.5
        + precision_fp ));
    short sign = ( longitude > -tz_degree_width() / 2.0 + precision_fp ) ? 1 : -1;
    short_name = tz_name( tz_num, use_lon_tz, sign );
    offset_min = sign * tz_num * minutes_per_degree_lon * tz_degree_width();
}

    // get offset as a string in ±HH:MM format
std::string TZSolar::str_offset() {
    std::string sign = offset_min >= 0 ? "+" : "-";

    // format hour
    std::ostringstream ss_hour;
    ss_hour << std::setw( 2 ) << std::setfill( '0' ) << abs(offset_min)/60;
    std::string num_hour = ss_hour.str();

    // format hour
    std::ostringstream ss_min;
    ss_min << std::setw( 2 ) << std::setfill( '0' ) << abs(offset_min)%60;
    std::string num_min = ss_min.str();

    return sign + num_hour + ":" + num_min;
}

// general read accessor for implementation of CLI spec
std::string TZSolar::get(const std::string &field) {
    static const std::unordered_map<std::string, std::function<std::string(TZSolar &)>> funcmap =
    {
        {"longitude", [](TZSolar &tzs) { return tzs.str_longitude(); }},
        {"latitude", [](TZSolar &tzs) { return tzs.str_latitude(); }},
        {"name", [](TZSolar &tzs) { return tzs.str_long_name(); }},
        {"short_name", [](TZSolar &tzs) { return tzs.str_short_name(); }},
        {"long_name", [](TZSolar &tzs) { return tzs.str_long_name(); }},
        {"offset", [](TZSolar &tzs) { return tzs.str_offset(); }},
        {"offset_min", [](TZSolar &tzs) { return tzs.str_offset_min(); }},
        {"offset_sec", [](TZSolar &tzs) { return tzs.str_offset_sec(); }},
        {"is_utc", [](TZSolar &tzs) { return tzs.str_is_utc(); }},
    };

    // call function to get field value, or throw std::out_of_range exception for unrecognized field
    auto func = funcmap.at(field);
    return func(*this);
}


