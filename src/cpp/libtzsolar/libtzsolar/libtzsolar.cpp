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
#include <regex>
#include <unordered_map>
#include <functional>
#include <optional>
#include <boost/numeric/conversion/cast.hpp>

// initialize static constants outside the header
const std::string TZSolar::tzsolar_lon_zone_str = std::string ( "(Lon0[0-9][0-9][EW])|(Lon1[0-7][0-9][EW])|(Lon180[EW])" );
const std::string TZSolar::tzsolar_hour_zone_str = std::string ( "(East|West)(0[0-9]|1[0-2])" );
const std::regex TZSolar::tzsolar_lon_zone_re = std::regex ( tzsolar_lon_zone_str, std::regex::icase );
const std::regex TZSolar::tzsolar_hour_zone_re = std::regex ( tzsolar_hour_zone_str, std::regex::icase );
const std::regex TZSolar::tzsolar_zone_re = std::regex ( tzsolar_lon_zone_str + "|" + tzsolar_hour_zone_str,
    std::regex::icase );
const int TZSolar::precision_digits = 6;  // max decimal digits of precision
const double TZSolar::precision_fp = std::pow( 10, -precision_digits ) / 2.0;  // 1/2 width of floating point equality
const int TZSolar::max_degrees = 360;
const int TZSolar::max_longitude_int = max_degrees / 2;  // min/max longitude in integer = 180
const double TZSolar::max_longitude_fp = max_degrees / 2.0;  // min/max longitude in fp = 180.0
const double TZSolar::max_latitude_fp = max_degrees / 4.0;  // min/max latitude in fp = 90.0
const int TZSolar::polar_utc_area = 10;  // latitude near poles to use UTC
const int TZSolar::limit_latitude = int ( max_latitude_fp - polar_utc_area );  // max latitude for solar time zones
const int TZSolar::minutes_per_degree_lon = 4;  // minutes per degree longitude

// initialize static member data
bool TZSolar::debug_flag = false;

// format a float as a string, looking like an int if it would be x.0
const std::string TZSolar::float_cleanup( float num ) {
    long num_int = std::lround( num );

    // format as an integer if it's an x.0 value
    if ( std::abs(num - boost::numeric_cast<float>(num_int)) < precision_fp ) {
        return std::to_string(num_int);
    }

    // format as floating point with defaultfloat format (i.e. to match Perl/Python output, show 123.1 not 123.099998)
    // return std::to_string(num);
    std::ostringstream ss;
    ss << std::defaultfloat << num;
    return ss.str();
}

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
bool TZSolar::tz_params_latitude ( const bool use_lon_tz, const float latitude ) {
    // special case: use East00/Lon000E (equal to UTC) within 10° latitude of poles
    if ( std::abs( latitude ) >= limit_latitude - precision_fp ) {
        // note: for polar latitudes, this must set all fields on behalf of the constructor
        lon_tz = use_lon_tz;
        short_name = lon_tz ? "Lon000E" : "East00";
        return true;
    }

    return false;
}

// get timezone parameters (name and minutes offset) - called by constructor
void TZSolar::tz_params (const float lon, const bool use_lon_tz, const std::optional<float> opt_latitude ) {
    // if latitude is provided, use UTC within 10° latitude of poles
    if ( opt_latitude.has_value() ) {
        if ( this->tz_params_latitude( use_lon_tz, opt_latitude.value() )) {
            return;
        }
        // fall through if latitude was provided but not in the extreme polar regions (so ignore it)
    }

    //
    // set time zone from longitude
    //

    // safety check on longitude
    if ( std::abs( lon ) > max_longitude_fp + precision_fp ) {
        throw std::out_of_range( "longitude out of range -180 to +180" );
    }
    this->longitude = lon;

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

// constructor from time zone name
TZSolar::TZSolar( const std::string &tzname ) {
    // change tzname to lower case
    std::string tzname_lower = tzname;
    std::transform(tzname_lower.begin(), tzname_lower.end(), tzname_lower.begin(),
        [](unsigned char c){ return std::tolower(c); });

    // use regex to check for longitude-based time zone (like Lon180E, Lon123W)
    if (std::regex_search(tzname_lower, tzsolar_lon_zone_re)) {
        bool is_west = tzname_lower.at(6) == 'w';
        float lon = boost::numeric_cast<float>(std::stof(tzname_lower.substr(3,3)) * (is_west ? -1 : 1));
        bool use_lon_tz = true;
        this->tz_params(lon, use_lon_tz, std::nullopt);
        return;
    }

    // use regex to check for hour-based time zone (like East12, West08)
    if (std::regex_search(tzname_lower, tzsolar_hour_zone_re)) {
        bool is_west = tzname_lower.substr(0,4) == "west";
        short hour_num = boost::numeric_cast<short>(std::stoi(tzname_lower.substr(4,2)));
        float lon = boost::numeric_cast<float>(hour_num * 15 * (is_west ? -1 : 1));
        bool use_lon_tz = false;
        this->tz_params(lon, use_lon_tz, std::nullopt);
        return;
    }

    // reject string which didn't match regex patterns of valid solar time zones
    throw std::invalid_argument( "not a valid solar time zone: " + tzname);
}

// get offset as a string in ±HH:MM format
const std::string TZSolar::str_offset() {

    std::string sign = offset_min >= 0 ? "+" : "-";

    // format hour
    std::ostringstream ss_hour;
    ss_hour << std::setw( 2 ) << std::setfill( '0' ) << abs(offset_min)/60;
    std::string num_hour = ss_hour.str();

    // format minutes
    std::ostringstream ss_min;
    ss_min << std::setw( 2 ) << std::setfill( '0' ) << abs(offset_min)%60;
    std::string num_min = ss_min.str();

    return sign + num_hour + ":" + num_min;
}

// general read accessor for implementation of CLI spec
const std::optional<std::string> TZSolar::get(const std::string &field) {
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

    // non-existent field results in a blank response
    if (!funcmap.count(field)) {
        return nullptr;
    }

    // call function to get field value, or throw std::out_of_range exception for unrecognized field
    auto func = funcmap.at(field);
    return std::make_optional<std::string>(func(*this));
}


