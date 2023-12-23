/*
 * libtzsolar.hpp - solar time zone library contants and public interface
 */

#include <string>
#include <cmath>
#include <regex>
#include <boost/optional.hpp>
#include <boost/date_time/local_time/local_time.hpp>

// solar time zones class
class TZSolar {
    public:

    // time zone constants: names, regular expressions and numbers
    const std::string tzsolar_lon_zone_str = std::string ( "(Lon0[0-9][0-9][EW])|(Lon1[0-7][0-9][EW])|(Lon180[EW])" );
    const std::string tzsolar_hour_zone_str = std::string ( "(East|West)(0[0-9]|1[0-2])" );
    const std::regex tzsolar_lon_zone_re = std::regex ( tzsolar_lon_zone_str );
    const std::regex tzsolar_hour_zone_re = std::regex ( tzsolar_hour_zone_str );
    const std::regex tzsolar_zone_re = std::regex ( tzsolar_lon_zone_str + "|" + tzsolar_hour_zone_str );
    const int precision_digits = 6;  // max decimal digits of precision
    const double precision_fp = std::pow( 10, -precision_digits ) / 2.0;  // 1/2 width of floating point equality
    const int max_degrees = 360;
    const int max_longitude_int = max_degrees / 2;  // min/max longitude in integer = 180
    const double max_longitude_fp = max_degrees / 2.0;  // min/max longitude in fp = 180.0
    const double max_latitude_fp = max_degrees / 4.0;  // min/max latitude in fp = 90.0
    const int polar_utc_area = 10;  // latitude near poles to use UTC
    const int limit_latitude = max_latitude_fp - polar_utc_area;  // max latitude for solar time zones
    const int minutes_per_degree_lon = 4;  // minutes per degree longitude

    // member data
    protected:

    std::string short_name;  // time zone base name, i.e. Lon000E or East00
    bool lon_tz; // flag: use longitude timezones; if false defaults to hour-based time zones
    int offset_min;  // time zone offset in minutes
    int longitude;   // longitude for time zone position
    boost::optional<short> opt_latitude;  // optional latitude for computing polar exclusion

    // TODO

    // private methods
    private:

    // generate a solar time zone name
    // parameters:
    //   tz_num: integer number for time zone - hourly or longitude based depending on use_lon_tz
    //   use_lon_tz: true=use longitude-based time zones, false=use hour-based time zones
    //   sign: +1 = positive/zero, -1 = negative
    static std::string tz_name ( int tz_num, bool use_lon_tz, short sign );

    // get timezone parameters (name and minutes offset) - called by constructor
    void tz_params_latitude ( short longitude, bool use_lon_tz, short latitude );

    // get timezone parameters (name and minutes offset) - called by constructor
    void tz_params ( short longitude, bool use_lon_tz, boost::optional<short> opt_latitude );

    // TODO: more private methods

    public:

    // constructor
    TZSolar( short longitude, bool use_lon_tz, boost::optional<short> latitude ) {
        this->tz_params( longitude, use_lon_tz, latitude );
    }

    // accessors
    inline std::string get_short_name() {
        return short_name;
    }
    inline int get_offset_min() {
        return offset_min;
    }
    inline int get_longitude() {
        return longitude;
    }
    inline boost::optional<short> get_opt_latitude() {
        return opt_latitude;
    }
    inline bool has_latitude() {
        return opt_latitude != boost::none;
    }
    inline std::string long_name() {
        return "Solar/" + short_name;
    }


};
