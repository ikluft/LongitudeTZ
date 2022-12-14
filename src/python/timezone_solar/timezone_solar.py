"""local solar timezone lookup and utilities including datetime compatibility"""

from tzsconst import TZSConst
from datetime import tzinfo, timedelta, datetime
import re

class TimeZoneSolar(tzinfo):
    """local solar timezone"""

    # instances of each time zone's singleton object
    _instances = {}

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
        if not re.fullmatch( r'^[-+]?\d+(\.\d+)?$', tz_params["longitude"]):
            raise Exception( f"_tz_params: longitude {tz_params['longitude']}" )
        if abs(tz_params["longitude"]) > TZSConst.get("MAX_LONGITUDE_FP") + \
                TZSConst.get("PRECISION_FP"):
            raise Exception( "_tz_params: longitude must be in the range -180 to +180" )

        # TODO
        return tz_params

    # fetch or create a timezone instance for __new__
    @classmethod
    def _tz_instance(cls, tz_params):
        # TODO
        pass

    @classmethod
    def __new__(cls, **args):
        return cls._tz_instance(cls._tz_params(args))

    #
    # implementation of datetime.tzinfo interface
    #

    def utcoffset(self, dt):
        """
        returns a timedelta of the offset from UTC
        """
        # TODO
        return timedelta(0)

    def dst(self, dt):
        """
        returns Daylight Saving Time flag, always false because solar time zones don't use DST
        """
        return False

    def tzname(self, dt):
        # TODO
        pass
