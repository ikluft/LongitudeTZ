"""local solar timezone lookup and utilities including datetime compatibility"""

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
        const = TZSConst()
        prefix = "Lon" if params["use_lon_tz"] else ("East" if params["sign"] > 0 else "West" )
        suffix = "" if not params["use_lon_tz"] else ("E" if params["sign"] > 0 else "W")
        tz_degree_width = 1 if params["use_lon_tz"] else 15
        tz_digits = 3 if params["use_lon_tz"] else 2
        tz_num = str(params["tz_num"]).zfill(tz_digits)
        return prefix + tz_num + suffix

    #
    # TimeZoneSolar core class methods
    #

    # get timezone parameters (name and minutes offset) - called by __new__()
    @classmethod
    def _tz_params(cls, tz_params) -> dict:
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
            tz_int = max_longitude / tz_degree_width
            tz_name = cls._tz_name(use_lon_tz=use_lon_tz, sign=1, tz_num=tz_int)
            tz_params["short_name"] = tz_name
            tz_params["offset_min"] = 720

        elif longitude <= -max_longitude + tz_degree_width / 2.0 + const.precision_fp:
            tz_int = max_longitude / tz_degree_width
            tz_name = cls._tz_name(use_lon_tz=use_lon_tz, sign=-1, tz_num=tz_int)
            tz_params["short_name"] = tz_name
            tz_params["offset_min"] = -720

        else:
            tz_int = int(abs(longitude) / tz_degree_width + 0.5 + const.precision_fp)
            sign = 1 \
                if longitude > -tz_degree_width / 2.0 + const.precision_fp \
                else -1
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
                    pass # no problem if item to be deleted didn't exist

    # get UTC offset
    # implementation of datetime.tzinfo interface
    def utcoffset(self, dt) -> timedelta:
        """
        returns a timedelta of the offset from UTC
        """
        return timedelta(minutes = self.offset_min)

    # get DST flag (always false for solar time zones)
    # implementation of datetime.tzinfo interface
    def dst(self, dt) -> bool:
        """
        returns Daylight Saving Time flag, always false because solar time zones don't use DST
        """
        return False

    # get time zone name string
    # implementation of datetime.tzinfo interface
    def tzname(self, dt) -> str:
        """
        returns short name of time zone
        """
        return self.name
