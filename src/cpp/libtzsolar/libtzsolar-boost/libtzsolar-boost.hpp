/*
 * libtzsolar-boost.hpp - C++ solar time zone library using BOOST date_time
 */

#pragma once
#include <string>
#include <sstream>
#include "boost/date_time/local_time/local_time.hpp"
#include "../libtzsolar/libtzsolar.hpp"
#include <boost/numeric/conversion/cast.hpp>

namespace pt = boost::posix_time;
namespace dt = boost::date_time;

namespace longitude_tz {
    template<class CharT>
    class solar_time_zone_base : public dt::time_zone_base<pt::ptime, CharT> {

        private:

        // solar time zone data around which this class provides a BOOST date_time query interface
        TZSolar tz;

        public:

        // This class uses multiple inheritance.
        // TZSolar provides constructors and accessors for solar time zones
        // time_zone_base provides accessor interface for compatibility with BOOST date_time
        typedef std::basic_string<CharT> string_type;
        typedef pt::ptime time_type;
        typedef dt::time_zone_base<pt::ptime,CharT> base_type;
        typedef typename time_type::date_type::year_type year_type;
        typedef typename time_type::time_duration_type time_duration_type;
        typedef typename base_type::stringstream_type stringstream_type;

        // constructors as wrappers around TZSolar constructors
        solar_time_zone_base(const float longitude, const bool use_lon_tz, const std::optional<float> latitude)
            : tz(longitude, use_lon_tz, latitude) {}
        explicit solar_time_zone_base(const std::string &tzname) : tz(tzname) {}

        // virtual destructor
        virtual ~solar_time_zone_base() {}

        // time_zone_base interface functions

        // for the timezone when in daylight savings (eg: EDT)
        virtual string_type dst_zone_abbrev() const override {
            return string_type(""); // not defined because there is no DST in solar time zones
        }

        // for the zone when not in daylight savings (eg: EST)
        virtual string_type std_zone_abbrev() const override {
            return (string_type) tz.str_short_name();
        }

        // for the timezone when in daylight savings (eg: Eastern Daylight Time)
        virtual string_type dst_zone_name() const override {
            return string_type(""); // not defined because there is no DST in solar time zones
        }

        // for the zone when not in daylight savings (eg: Eastern Standard Time)
        virtual string_type std_zone_name() const override {
            return (string_type) tz.str_long_name();
        }

        // True if zone uses daylight savings adjustments otherwise false
        virtual bool has_dst() const override {
            return false;
        }

        // Local time that DST starts -- undefined if has_dst is false
        virtual time_type dst_local_start_time(year_type /* y */) const override {
            return pt::ptime(); // not defined because there is no DST in solar time zones
        }

        // Local time that DST ends -- undefined if has_dst is false
        virtual time_type dst_local_end_time(year_type /* y */)const  override {
            return pt::ptime(); // not defined because there is no DST in solar time zones
        }

        // Base offset from UTC for zone (eg: -07:30:00)
        virtual time_duration_type base_utc_offset() const override {
            short offset_part_hr = boost::numeric_cast<short>(tz.get_offset_min() / 60);
            short offset_part_min = boost::numeric_cast<short>(tz.get_offset_min() % 60);
            return solar_time_zone_base<CharT>::time_duration_type(offset_part_hr, offset_part_min, 0);
        }

        // Adjustment forward or back made while DST is in effect
        virtual time_duration_type dst_offset() const override {
            return time_duration_type(); // not defined because there is no DST in solar time zones
        }

        // Returns a POSIX time_zone string for this object
        virtual string_type to_posix_string() const override {
            // std offset dst [offset],start[/time],end[/time] - w/o spaces
            stringstream_type ss;
            ss.fill('0');

            // std
            ss << std_zone_abbrev();

            // offset
            if (base_utc_offset().is_negative()) {
                // inverting the sign guarantees we get two digits
                ss << '-' << std::setw(2) << base_utc_offset().invert_sign().hours();
            } else {
                ss << '+' << std::setw(2) << base_utc_offset().hours();
            }
            if(base_utc_offset().minutes() != 0 || base_utc_offset().seconds() != 0) {
                ss << ':' << std::setw(2) << base_utc_offset().minutes();
                if(base_utc_offset().seconds() != 0) {
                    ss << ':' << std::setw(2) << base_utc_offset().seconds();
                }
            }
            // skip DST offset because solar time zones never have DST
            return ss.str();
        }

        // TZSolar compatible interface for use by CLI template

        // accessors for TZSolar debug flag
        static inline bool get_debug_flag() { return TZSolar::get_debug_flag(); }
        inline static void set_debug_flag(bool flag_value) { return TZSolar::set_debug_flag(flag_value); }

        // time zone short/base name (without Solar/)
        const std::string str_short_name() const {
            return std::string(std_zone_abbrev());
        }

        // time zone long name includes Solar/ prefix
        const std::string str_long_name() const {
            return std::string(std_zone_name());
        }

        // get offset as a string in ±HH:MM format
        const std::string str_offset() const {
            short dt_offset_min = base_utc_offset().total_seconds()/60;
            std::string sign = dt_offset_min >= 0 ? "+" : "-";

            // format hour
            std::ostringstream ss_hour;
            ss_hour << std::setw( 2 ) << std::setfill( '0' ) << abs(dt_offset_min)/60;
            std::string num_hour = ss_hour.str();

            // format minutes
            std::ostringstream ss_min;
            ss_min << std::setw( 2 ) << std::setfill( '0' ) << abs(dt_offset_min)%60;
            std::string num_min = ss_min.str();

            return sign + num_hour + ":" + num_min;
        }

        // get offset minutes as a string
        const std::string str_offset_min() const {
            return std::to_string((unsigned short)(base_utc_offset().total_seconds()/60));
        }

        // get offset seconds as a string
        const std::string str_offset_sec() const {
            return std::to_string((unsigned short)(base_utc_offset().total_seconds()));
        }

        // get is_utc flag as a string
        const std::string str_is_utc() const {
            return std::to_string((unsigned short)(base_utc_offset().total_seconds()/60) == 0 ? 1 : 0);
        }

        // get named field as string
        const std::optional<std::string> get(const std::string &field) {
            return tz.get(field);
        }
    };

    typedef solar_time_zone_base<char> solar_time_zone;
}
