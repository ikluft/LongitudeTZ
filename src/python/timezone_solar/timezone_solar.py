"""
local solar timezone lookup and utilities including datetime compatibility

The timezone_solar package is the Python implementation of Longitude Time Zones.
More information can be found at https://github.com/ikluft/LongitudeTZ .

A general summary is Longitude Time Zones are an alternative based on a location's
longitude which, by their definition, do not use Daylight Saving Time.

There are two variants of the Longitude Time Zones. The ones of primary interest are
hour-based time zones, each 1 hour wide. They are each centered on a meridian at
15 degree intervals, like nautical time zones that ships at sea use.
Besides not using Daylight Saving Time, these have local solar noon near clock noon
on average.

As with Universal Coordinated Time (UTC), the Longitude Time Zones are centered at
the "Prime Meridian", which is zero degrees longitude. It hash been used since 1884
as the international basis of computation of latitude on Earth.

In the Latitude Time Zones, the hour-based time zones are named for the number of hours
offset east or west from UTC.
Positive offsets are east of the Prime Meridian, so East00 to East12.
Negative offsets are west of the Prime Meridian, so West00 to West12.
West00 is the same thing as East00, both zero hours offset from UTC.
East12 and West12 are each half as wide as the other time zones,
and are either side of the Date Line.
The meridian at 180 degrees longitude is the definition of the Date Line for the
Longitude Time Zones because the time zone boundaries in this system are only on
lines of longitude, not legislated boundaries.

The other variants are longitude-based time zones, each 1 degree of longitude wide.
That makes 360 of these time zones at 4 minute intervals of clock time.
These have a niche use for planning events around available daylight, centered on local
solar noon, which can then be converted to more widely-used time zones for communications
with the public.

The longitude-based time zones are named for each meridian at 1 degree intervals.
Positive numbers of degrees are east of the Prime Meridian, so Lon180E to Lon000E.
Negative numbers of degrees are west of the Prime Meridian, so Lon180W to Lon000W.
Lon000E is the same thing as Lon000W, both in the 1-degree-wide time zone centered at
the Prime Meridian.

Once the timezone_solar package is loaded, the standard Python datetime package can
process these time zones.
"""

from datetime import tzinfo, timedelta
import re
from timezone_solar.tzsconst import TZSConst


class TimeZoneSolar(tzinfo):
    """local solar timezone"""

    #
    # utility methods
    #

    # generate a solar time zone name
    # required parameters:
    #   tz_num: integer number for time zone - hourly or longitude based depending on use_lon_tz
    #   use_lon_tz: true=use longitude-based time zones, false=use hour-based time zones
    #   sign: +1 = positive/zero, -1 = negative
    @staticmethod
    def _tz_name(**params) -> str:
        prefix = (
            "Lon"
            if params["use_lon_tz"]
            else ("East" if params["sign"] > 0 else "West")
        )
        suffix = (
            "" if not params["use_lon_tz"] else ("E" if params["sign"] > 0 else "W")
        )
        tz_digits = 3 if params["use_lon_tz"] else 2
        tz_num = str(params["tz_num"]).zfill(tz_digits)
        return prefix + tz_num + suffix

    #
    # TimeZoneSolar core class methods
    #

    # check latitude data and initialize special case for polar regions
    # internal method called by _tz_params()
    @classmethod
    def _tz_params_latitude(cls, tz_params):
        # safety check on latitude
        const = TZSConst()
        if not re.fullmatch(r"^[-+]?\d+(\.\d+)?$", str(tz_params["latitude"])):
            raise Exception(f"_tz_params: latitude {tz_params['latitude']}")
        latitude = float(tz_params["latitude"])
        if abs(latitude) > const.max_latitude_fp + const.precision_fp:
            raise Exception("_tz_params: latitude must be in the range -90 to +90")

        # special case: use East00/Lon000E (equal to UTC) within 10° latitude of poles
        # use UTC at the poles because time zones are too narrow to make sense
        if abs(tz_params["latitude"]) >= const.limit_latitude - const.precision_fp:
            use_lon_tz = bool(tz_params["use_lon_tz"])
            tz_params["short_name"] = "Lon000E" if use_lon_tz else "East00"
            tz_params["name"] = f"Solar/{tz_params['short_name']}"
            tz_params["offset_min"] = 0
            return tz_params

        # no effects on results from latitude between 80° north & south
        return None

    # get timezone parameters (name and minutes offset) - called by __new__()
    @classmethod
    def _tz_params(cls, tz_params) -> dict:
        if "longitude" not in tz_params:
            raise Exception("_tz_params: longitude parameter missing")

        # set time zone from longitude and latitude
        if "latitude" in tz_params:
            lat_params = cls._tz_params_latitude(tz_params)
            if lat_params is not None:
                return lat_params

        #
        # set time zone from longitude alone
        #

        # safety check on longitude
        const = TZSConst()
        if not re.fullmatch(r"^[-+]?\d+(\.\d+)?$", str(tz_params["longitude"])):
            raise Exception(f"_tz_params: longitude {tz_params['longitude']}")
        longitude = float(tz_params["longitude"])
        if abs(longitude) > const.max_longitude_fp + const.precision_fp:
            raise Exception("_tz_params: longitude must be in the range -180 to +180")

        # set flag for longitude time zones:
        # 0 = hourly 1-hour/15-degree zones, 1 = longitude 4-minute/1-degree zones
        # defaults to hourly time zone ($use_lon_tz=0)
        use_lon_tz = bool(tz_params["use_lon_tz"])
        tz_degree_width = 1 if use_lon_tz else 15

        # handle special case of half-wide tz at positive side of solar date line (180° longitude)
        max_longitude = const.max_longitude_int
        if (
            longitude >= max_longitude - tz_degree_width / 2.0 - const.precision_fp
            or longitude <= -max_longitude + const.precision_fp
        ):
            tz_int = int(max_longitude / tz_degree_width)
            tz_name = cls._tz_name(use_lon_tz=use_lon_tz, sign=1, tz_num=tz_int)
            tz_params["short_name"] = tz_name
            tz_params["offset_min"] = 720

        elif longitude <= -max_longitude + tz_degree_width / 2.0 + const.precision_fp:
            tz_int = int(max_longitude / tz_degree_width)
            tz_name = cls._tz_name(use_lon_tz=use_lon_tz, sign=-1, tz_num=tz_int)
            tz_params["short_name"] = tz_name
            tz_params["offset_min"] = -720

        else:
            tz_int = int(abs(longitude) / tz_degree_width + 0.5 + const.precision_fp)
            sign = 1 if longitude > -tz_degree_width / 2.0 + const.precision_fp else -1
            offset_min = sign * tz_int * const.minutes_per_degree_lon * tz_degree_width
            tz_name = cls._tz_name(use_lon_tz=use_lon_tz, sign=sign, tz_num=tz_int)
            tz_params["short_name"] = tz_name
            tz_params["offset_min"] = offset_min
        tz_params["name"] = f"Solar/{tz_params['short_name']}"
        return tz_params

    # create a new instance
    def __new__(cls, **kwargs):
        return super().__new__(cls, kwargs)

    # initialize instance
    def __init__(self, **kwargs):
        self.__dict__.update(self.__class__._tz_params(kwargs))

    #
    # attribute access methods
    #

    # update lat/lon to record source data
    def update_lon_lat(self, params):
        """
        update longitude and optional latitude to record source data for testing/troubleshooting
        """
        for key in ["longitude", "latitude"]:
            if key in params:
                setattr(self, key, params[key])
            else:
                try:
                    delattr(self, key)
                except AttributeError:
                    pass  # no problem if item to be deleted didn't exist

    # get UTC offset
    # implementation of datetime.tzinfo interface
    def utcoffset(self, dt) -> timedelta:
        """
        returns a timedelta of the offset from UTC
        """
        return timedelta(minutes=self.offset_min)

    # get DST adjustment as a timedelta (always 0 for solar time zones)
    # implementation of datetime.tzinfo interface
    def dst(self, dt) -> timedelta:
        """
        returns Daylight Saving Time adjustment as a timedelta, always 0 because we don't use DST
        """
        return timedelta(0)

    # get time zone name string
    # implementation of datetime.tzinfo interface
    def tzname(self, dt) -> str:
        """
        returns long name of time zone
        """
        return self.name
