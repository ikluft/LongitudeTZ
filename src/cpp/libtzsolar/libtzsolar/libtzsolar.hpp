/*
 * libtzsolar.hpp - solar time zone library contants and public interface
 */

#pragma once
#include <string>
#include <regex>
#include <optional>
#include <iostream>

namespace longitude_tz {

    // solar time zones class
    class TZSolar {
        public:

        // time zone constants: names, regular expressions and numbers
        static const std::string tzsolar_lon_zone_str;
        static const std::string tzsolar_hour_zone_str;
        static const std::regex tzsolar_lon_zone_re;
        static const std::regex tzsolar_hour_zone_re;
        static const std::regex tzsolar_zone_re;
        static const int precision_digits;
        static const double precision_fp;
        static const int max_degrees;
        static const int max_longitude_int;
        static const double max_longitude_fp;
        static const double max_latitude_fp;
        static const int polar_utc_area;
        static const int limit_latitude;
        static const int minutes_per_degree_lon;

        // private class-static data
        private:
        static bool debug_flag;

        // member data
        protected:

        std::string short_name;  // time zone base name, i.e. Lon000E or East00
        bool lon_tz; // flag: use longitude timezones; if false defaults to hour-based time zones
        int offset_min;  // time zone offset in minutes
        float longitude;   // longitude for time zone position
        std::optional<float> opt_latitude;  // optional latitude for computing polar exclusion

        //
        // protected methods

        // generate a solar time zone name
        // parameters:
        //   tz_num: integer number for time zone - hourly or longitude based depending on use_lon_tz
        //   use_lon_tz: true=use longitude-based time zones, false=use hour-based time zones
        //   sign: +1 = positive/zero, -1 = negative
        static std::string tz_name ( const unsigned short tz_num, const bool use_lon_tz, const short sign );

        // get timezone parameters (name and minutes offset) - called by constructor
        bool tz_params_latitude ( const bool use_lon_tz, const float latitude );

        // get timezone parameters (name and minutes offset) - called by constructor
        void tz_params (const float longitude, const bool use_lon_tz, const std::optional<float> opt_latitude );

        public:

        // accessors for class-static data
        const static inline bool get_debug_flag() { return debug_flag; }
        inline static void set_debug_flag(bool flag_value) { debug_flag = flag_value; }
        const static inline void debug_print(const std::string &msg) { if (debug_flag) { std::cerr << msg << std::endl; } }

        // constructor from time zone parameters
        TZSolar( const float longitude, const bool use_lon_tz, const std::optional<float> latitude ) {
            this->tz_params( longitude, use_lon_tz, latitude );
        }

        // constructor from time zone name
        explicit TZSolar( const std::string &tzname );

        //
        // read accessors

        // time zone offset from GMT in minutes
        constexpr int get_offset_min() {
            return offset_min;
        }

        // longitude used to set time zone
        constexpr float get_longitude() {
            return longitude;
        }

        // optional latitude used to detect if coordinates are too close to poles and use GMT instead
        constexpr inline std::optional<float> get_opt_latitude() {
            return opt_latitude;
        }

        // determine if latitude was used to define the time zone
        const inline bool has_latitude() {
            return opt_latitude.has_value();
        }

        //
        // string read accessors for CLI

        // return string value of longitude
        const inline std::string str_longitude() {
            return float_cleanup(longitude);
        }

        // return string value of latitude, use "" if optional value is not present
        const inline std::string str_latitude() {
            return opt_latitude.has_value() ? float_cleanup(opt_latitude.value()) : "";
        }

        // time zone short/base name (without Solar/)
        const inline std::string str_short_name() {
            return short_name;
        }

        // time zone long name includes Solar/ prefix
        const inline std::string str_long_name() {
            return "Solar/" + short_name;
        }

        // get offset as a string in ±HH:MM format
        const std::string str_offset();

        // get offset minutes as a string
        const inline std::string str_offset_min() {
            return std::to_string(offset_min);
        }

        // get offset seconds as a string
        const inline std::string str_offset_sec() {
            return std::to_string(offset_min*60);
        }

        // get is_utc flag as a string
        const inline std::string str_is_utc() {
            return std::to_string(offset_min == 0 ? 1 : 0);
        }

        // general read accessor for implementation of CLI spec
        const std::optional<std::string> get(const std::string &field);

        private:

        //
        // private internal utility methods

        // format a float as a string, looking like an int if it would be x.0
        static const std::string float_cleanup( float num );

        // time zone width in degrees of longitude differs, 1 if by each degree, 15 if by each hour
        constexpr short tz_degree_width() {
            return lon_tz ? 1 : 15;  // 1 for longitude-based tz, 15 for hour-based tz
        }

        // number of numeric digits for formatting time zone name (3 digits if by degree, 2 digits if by hour)
        constexpr short tz_digits() {
            return lon_tz ? 3 : 2;   // number of digits in time zone name
        }

        // formatting: time zone prefix string
        const inline std::string tz_prefix( short sign ) {
            return std::string( lon_tz ? "Lon" : ( sign > 0 ? "East" : "West" ));
        }

        // formatting: time zone suffix string
        const inline std::string tz_suffix( short sign) {
            return std::string( lon_tz ? ( sign > 0 ? "E" : "W" ) : "" );
        }

    };
}
