"""local solar timezone lookup and utilities including datetime compatibility"""

__version__ = "0.1"

from datetime import tzinfo, timedelta, datetime
from timezone_solar import tzsconst

class TimeZoneSolar(tzinfo):
    """local solar timezone"""

    def __init__(self, longitude: float, latitude: float = None):
        # TODO
        pass

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
