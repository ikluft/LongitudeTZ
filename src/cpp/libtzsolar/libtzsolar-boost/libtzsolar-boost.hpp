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
    class solar_time_zone_base : dt::time_zone_base<pt::ptime, CharT> {
        private:

        // solar time zone
        TZSolar solar_tz;

        public:
        typedef std::basic_string<CharT> string_type;
        typedef pt::ptime time_type;
        typedef dt::time_zone_base<pt::ptime,CharT> base_type;
        typedef typename time_type::date_type::year_type year_type;
        typedef typename time_type::time_duration_type time_duration_type;
        typedef typename base_type::stringstream_type stringstream_type;

        // constructors as wrappers around TZSolar constructors
        solar_time_zone_base(const float longitude, const bool use_lon_tz, const std::optional<float> latitude)
            : solar_tz(longitude, use_lon_tz, latitude) {}
        explicit solar_time_zone_base(const std::string &tzname) : solar_tz(tzname) {}

        // virtual destructor
        virtual ~solar_time_zone_base() {}

        // time_zone_base interface functions

        // for the timezone when in daylight savings (eg: EDT)
        virtual string_type dst_zone_abbrev() const {
            return std::string(""); // not defined because there is no DST in solar time zones
        }
        // for the zone when not in daylight savings (eg: EST)
        virtual string_type std_zone_abbrev() const {
            return const_cast<TZSolar&>(solar_tz).str_short_name();
        }
        // for the timezone when in daylight savings (eg: Eastern Daylight Time)
        virtual string_type dst_zone_name() const {
            return std::string(""); // not defined because there is no DST in solar time zones
        }
        // for the zone when not in daylight savings (eg: Eastern Standard Time)
        virtual string_type std_zone_name() const {
            return const_cast<TZSolar&>(solar_tz).str_long_name();
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
        virtual time_duration_type base_utc_offset() const {
            short offset_part_hr = const_cast<TZSolar&>(solar_tz).get_offset_min() / 60;
            short offset_part_min = const_cast<TZSolar&>(solar_tz).get_offset_min() % 60;
            return time_duration_type(offset_part_hr, offset_part_min, 0);
        }
        // Adjustment forward or back made while DST is in effect
        virtual time_duration_type dst_offset() const {
            return time_duration_type(); // not defined because there is no DST in solar time zones
        }
        // Returns a POSIX time_zone string for this object
        virtual string_type to_posix_string() const  {
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
    };

    typedef solar_time_zone_base<char> solar_time_zone;
}
