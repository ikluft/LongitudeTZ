
/*
 * libtzsolar-boost.hpp - C++ solar time zone library using BOOST date_time
 */

#pragma once
#include "../libtzsolar/libtzsolar.hpp"
#include "boost/date_time/local_time/local_time.hpp"
#include "boost/date_time/time_zone_base.hpp"

class TZSolar_Boost : TZSolar {
    private:

    // Boost custom time zone


    public:

    // constructor as wrapper around parent constructor
    TZSolar_Boost : public TZSolar(longitude, use_lon_tz, latitude) {
        boost::date_time::time_zone_names tzn(this->str_long_name(), this->str_short_name());
        auto offset_hr = std::int(this->offset_min() / 60);
        time_duration utc_offset(this->offset(),0,0);
    };
};
