/*
 * libtzsolar.hpp - solar time zone library contants and public interface
 */

#include <unordered_map>
#include <string>
#include <cmath>
#include <regex>

class TZSolar {
    public:

    // time zone name regular expressions
    const std::regex tzsolar_lon_zone_re = std::regex ( "(Lon0[0-9][0-9][EW]) | (Lon1[0-7][0-9][EW]) | (Lon180[EW])" );
    const std::regex tzsolar_hour_zone_re = std::regex ( "(East|West)(0[0-9] | 1[0-2])" );
    // const std::regex tzsolar_zone_re = std::regex ( "" );
    const int precision_digits = 6;  // max decimal digits of precision
    const double precision_fp = std::pow( 10, -precision_digits ) / 2.0;  // 1/2 width of floating point equality
    const int max_degrees = 360;
    const int max_longitude_int = max_degrees / 2;  // min/max longitude in integer = 180
    const double max_longitude_fp = max_degrees / 2.0;  // min/max longitude in fp = 180.0
    const double max_latitude_fp = max_degrees / 4.0;  // min/max latitude in fp = 90.0
    const int polar_utc_area = 10;  // latitude near poles to use UTC
    const int limit_latitude = max_latitude_fp - polar_utc_area;  // max latitude for solar time zones
    const int minutes_per_degree_lon = 4;  // minutes per degree longitude
};
