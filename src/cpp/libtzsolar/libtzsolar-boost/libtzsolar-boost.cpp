/*
 * libtzsolar-boost.cpp - C++ solar time zone library using BOOST date_time
 */

#include "libtzsolar-boost.hpp"
#include "boost/date_time/local_time/local_time.hpp"

// namespace ltz = longitude_tz;
namespace longitude_tz {

    // Base offset from UTC for zone (eg: -07:30:00)
    template<typename CharT>
    typename solar_time_zone_base<CharT>::time_duration_type solar_time_zone_base<CharT>::base_utc_offset() const {
        short offset_part_hr = const_cast<TZSolar&>(solar_tz).get_offset_min() / 60;
        short offset_part_min = const_cast<TZSolar&>(solar_tz).get_offset_min() % 60;
        return solar_time_zone_base<CharT>::time_duration_type(offset_part_hr, offset_part_min, 0);
    }

    // Returns a POSIX time_zone string for this object
    template<class CharT>
    typename solar_time_zone_base<CharT>::string_type solar_time_zone_base<CharT>::to_posix_string() const {
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
}
