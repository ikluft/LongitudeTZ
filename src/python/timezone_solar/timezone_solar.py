"""local solar timezone lookup and utilities including datetime compatibility"""

from datetime import tzinfo, timedelta
import re
from timezone_solar.tzsconst import TZSConst

# instances of each time zone's singleton object
_instances = {}

class TimeZoneSolar(tzinfo):
    """local solar timezone"""

    #
    # utility methods
    #

    # generate a solar time zone name
    # required parameters:
    #   longitude: integer number of degrees of longitude for time zone
    #   use_lon_tz: true=use longitude-based time zones, false=use hour-based time zones
    #   sign: +1 = positive/zero, -1 = negative
    @staticmethod
    def _tz_name(**params):
        prefix = "Lon" if params["use_lon_tz"] else ("East" if params["sign"] > 0 else "West" )
        suffix = "" if not  params["use_lon_tz"] else ("E" if params["sign"] > 0 else "W")
        tz_degree_width = 1 if params["use_lon_tz"] else 15
        tz_digits = 3 if params["use_lon_tz"] else 2
        tz_num = str(int(params["longitude"] / tz_degree_width)).zfill(tz_digits)
        return prefix + tz_num + suffix

    #
    # TimeZoneSolar core class methods
    #

    # get timezone parameters (name and minutes offset) - called by __new__()
    @classmethod
    def _tz_params(cls, tz_params):
        if "longitude" not in tz_params:
            raise Exception( "_tz_params: longitude parameter missing" )

        # set time zone from longitude and latitude
        if "latitude" in tz_params:
            lat_params = cls._tz_params_latitude( tz_params )
            if lat_params is not None:
                return lat_params

        #
        # set time zone from longitude alone
        #

        # safety check on longitude
        const = TZSConst()
        if not re.fullmatch( r'^[-+]?\d+(\.\d+)?$', str(tz_params["longitude"])):
            raise Exception( f"_tz_params: longitude {tz_params['longitude']}" )
        longitude = float(tz_params["longitude"])
        if abs(longitude) > const.max_longitude_fp + const.precision_fp:
            raise Exception( "_tz_params: longitude must be in the range -180 to +180" )

        # set flag for longitude time zones:
        # 0 = hourly 1-hour/15-degree zones, 1 = longitude 4-minute/1-degree zones
        # defaults to hourly time zone ($use_lon_tz=0)
        use_lon_tz = bool(tz_params["use_lon_tz"])
        tz_degree_width = 1 if use_lon_tz else 15

        # handle special case of half-wide tz at positive side of solar date line (180° longitude)
        max_longitude = const.max_longitude_int
        if longitude >= max_longitude - tz_degree_width / 2.0 - const.precision_fp \
            or longitude <= -max_longitude + const.precision_fp:
            tz_name = cls._tz_name(use_lon_tz=use_lon_tz, sign=1, \
                longitude = const.max_longitude_int)
            tz_params["short_name"] = tz_name
            tz_params["name"] = f"Solar/{tz_name}"
            tz_params["offset_min"] = 720

        elif longitude <= -max_longitude + tz_degree_width / 2.0 + const.precision_fp:
            tz_name = cls._tz_name(use_lon_tz=use_lon_tz, sign=-1, longitude=max_longitude)
            tz_params["short_name"] = tz_name
            tz_params["name"] = f"Solar/{tz_name}"
            tz_params["offset_min"] = -720

        else:
            tz_int = int(abs(longitude) / tz_degree_width / 2.0 + const.precision_fp)
            sign = 1 \
                if longitude > -tz_degree_width / 2.0 + const.precision_fp \
                else -1
            offset = sign * tz_int * const.minutes_per_degree_lon * tz_degree_width
            tz_name = cls._tz_name(use_lon_tz=use_lon_tz, sign=sign, longitude=tz_int)
            tz_params["short_name"] = tz_name
            tz_params["name"] = f"Solar/{tz_name}"
            tz_params["offset_min"] = offset

        return tz_params

    # fetch or create a timezone instance for __new__
    @classmethod
    def _tz_instance(cls, params):
        # consistency checks
        const = TZSConst()
        short_name = params["short_name"]
        if short_name is None:
            raise Exception( "_tz_instance: short_name parameter missing" )
        if not re.fullmatch( const.tzsolar_zone_re, short_name):
            raise Exception( "_tz_instance: short_name parameter is not a solar time zone name" )

        # look up class instance, return it if found
        if short_name in _instances:
            # forward lat/lon parameters to existing instance, so tests can see where it came from
            for key in ["latitude", "longitude"]:
                if key in params:
                    _instances[short_name][key] = params[key]
                else:
                    if key in _instances[short_name]:
                        del _instances[short_name][key]
            return _instances[short_name]

        # make and save the singleton instance for that short_name class
        obj = super().__new__(cls, params)
        _instances[short_name] = obj
        return obj

    # return a singleton instance for the requested time zone
    # create a new instance only if it didn't already exist
    def __new__(cls, **kwargs):
        return cls._tz_instance(cls._tz_params(kwargs))

    #
    # implementation of datetime.tzinfo interface
    #

    def utcoffset(self, dt):
        """
        returns a timedelta of the offset from UTC
        """
        return timedelta(minutes = self["offset_min"])

    def dst(self, dt):
        """
        returns Daylight Saving Time flag, always false because solar time zones don't use DST
        """
        return False

    def tzname(self, dt):
        """
        returns short name of time zone
        """
        return self["name"]
