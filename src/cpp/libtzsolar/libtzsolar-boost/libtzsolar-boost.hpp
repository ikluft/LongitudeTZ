/*
 * libtzsolar-boost.hpp - C++ solar time zone library using BOOST date_time
 */

#pragma once
#include <string>
#include <sstream>
#include "boost/date_time/local_time/local_time.hpp"
#include "../libtzsolar/libtzsolar.hpp"

namespace pt = boost::posix_time;
namespace dt = boost::date_time;

namespace longitude_tz {
    template<class CharT>
    class solar_time_zone_base : public dt::time_zone_base<pt::ptime, CharT>, public TZSolar {
        // This class uses multiple inheritance.
        // TZSolar provides constructors and accessors for solar time zones
        // time_zone_base provides accessor interface for compatibility with BOOST date_time
        public:
        typedef std::basic_string<CharT> string_type;
        typedef pt::ptime time_type;
        typedef dt::time_zone_base<pt::ptime,CharT> base_type;
        typedef typename time_type::date_type::year_type year_type;
        typedef typename time_type::time_duration_type time_duration_type;
        typedef typename base_type::stringstream_type stringstream_type;

        // constructors as wrappers around TZSolar constructors
        solar_time_zone_base(const float longitude, const bool use_lon_tz, const std::optional<float> latitude)
            : TZSolar(longitude, use_lon_tz, latitude) {}
        explicit solar_time_zone_base(const std::string &tzname) : TZSolar(tzname) {}

        // virtual destructor
        virtual ~solar_time_zone_base() {}

        // time_zone_base interface functions

        // for the timezone when in daylight savings (eg: EDT)
        virtual string_type dst_zone_abbrev() const {
            return std::string(""); // not defined because there is no DST in solar time zones
        }

        // for the zone when not in daylight savings (eg: EST)
        virtual string_type std_zone_abbrev() const {
            return str_short_name();
        }

        // for the timezone when in daylight savings (eg: Eastern Daylight Time)
        virtual string_type dst_zone_name() const {
            return std::string(""); // not defined because there is no DST in solar time zones
        }

        // for the zone when not in daylight savings (eg: Eastern Standard Time)
        virtual string_type std_zone_name() const {
            return str_long_name();
        }

        // True if zone uses daylight savings adjustments otherwise false
        virtual bool has_dst() const {
            return false;
        }

        // Local time that DST starts -- undefined if has_dst is false
        virtual time_type dst_local_start_time(year_type y) const {
            return pt::ptime(); // not defined because there is no DST in solar time zones
        }

        // Local time that DST ends -- undefined if has_dst is false
        virtual time_type dst_local_end_time(year_type y) const {
            return pt::ptime(); // not defined because there is no DST in solar time zones
        }

        // Base offset from UTC for zone (eg: -07:30:00)
        virtual time_duration_type base_utc_offset() const;

        // Adjustment forward or back made while DST is in effect
        virtual time_duration_type dst_offset() const {
            return time_duration_type(); // not defined because there is no DST in solar time zones
        }

        // Returns a POSIX time_zone string for this object
        virtual string_type to_posix_string() const;

        // TZSolar virtual interface

        // time zone short/base name (without Solar/)
        const std::string str_short_name() override {
            return std_zone_abbrev();
        }

        // time zone long name includes Solar/ prefix
        const std::string str_long_name() override {
            return std_zone_name();
        }

        // get offset as a string in ±HH:MM format
        const std::string str_offset() override;

        // get offset minutes as a string
        const std::string str_offset_min() override {
            return std::to_string((unsigned short)(base_utc_offset().total_seconds()/60));
        }

        // get offset seconds as a string
        const std::string str_offset_sec() override {
            return std::to_string((unsigned short)(base_utc_offset().total_seconds()));
        }

        // get is_utc flag as a string
        const std::string str_is_utc() override {
            return std::to_string((unsigned short)(base_utc_offset().total_seconds()/60) == 0 ? 1 : 0);
        }
    };

    typedef solar_time_zone_base<char> solar_time_zone;
}
