/*
 * constants.hpp - solar time zone contants and accessor
 */

#include <unordered_map>
#include <string>
#include <regex>

class Constant {
    const std::regex tzsolar_lon_zone_re = std::regex ( "(Lon0[0-9][0-9][EW]) | (Lon1[0-7][0-9][EW]) | (Lon180[EW])" );
    const std::regex tzsolar_hour_zone_re = std::regex ( "(East|West)(0[0-9] | 1[0-2])" );
    // const std::regex tzsolar_zone_re = std::regex ( "" );
    const int precision_digits = 6;
};
