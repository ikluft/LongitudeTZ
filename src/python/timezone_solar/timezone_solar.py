"""local solar timezone lookup and utilities including datetime compatibility"""

from tzsconst import TZSConst
from datetime import tzinfo, timedelta, datetime

class TimeZoneSolar(tzinfo):
    """local solar timezone"""

    # instances of each time zone's singleton object
    _instances = {}

    # get timezone parameters (name and minutes offset) - called by __new__()
    @classmethod
    def _tz_params(cls, tz_params):
        # TODO
        pass

    @classmethod
    def _tz_instance(cls, tz_params):
        # TODO
        pass

    @classmethod
    def __new__(cls, **args):
        return cls._tz_instance(cls._tz_params(args))

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
