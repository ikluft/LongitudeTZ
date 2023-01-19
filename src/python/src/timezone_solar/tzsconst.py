"""constants for timezone_solar"""
from datetime import timedelta
import re


class TZSConst:
    """
    TZSConst is a class that contains contants for TimeZoneSolar so unit tests can access them.
    """

    # constants: time duration
    ZERO = timedelta(0)
    HOUR = timedelta(hours=1)
    SECOND = timedelta(seconds=1)

    # constants: regular expressions for solar time zones
    TZSOLAR_LON_ZONE_STR = "(Lon0[0-9][0-9][EW])|(Lon1[0-7][0-9][EW])|(Lon180[EW])"
    TZSOLAR_HOUR_ZONE_STR = "(East|West)(0[0-9]| 1[0-2])"
    TZSOLAR_ZONE_STR = TZSOLAR_LON_ZONE_STR + "|" + TZSOLAR_HOUR_ZONE_STR
    TZSOLAR_LON_ZONE_RE = re.compile(TZSOLAR_LON_ZONE_STR)
    TZSOLAR_HOUR_ZONE_RE = re.compile(TZSOLAR_HOUR_ZONE_STR)
    TZSOLAR_ZONE_RE = re.compile(TZSOLAR_ZONE_STR)

    # constants: precision
    PRECISION_DIGITS = 6
    PRECISION_FP = (10**-PRECISION_DIGITS) / 2.0

    # constants: location
    MAX_DEGREES = 360
    POLAR_UTC_AREA = 10
    MAX_LONGITUDE_INT = MAX_DEGREES / 2
    MAX_LONGITUDE_FP = MAX_DEGREES / 2.0
    MAX_LATITUDE_FP = MAX_DEGREES / 4.0
    LIMIT_LATITUDE = MAX_LATITUDE_FP - POLAR_UTC_AREA
    MINUTES_PER_DEGREE_LON = 4

    @classmethod
    def keys(cls):
        """
        returns a list of names of available constants

        input: none

        output: list of names of constants, which can be read with the get method
        """
        keys = []
        for key in cls.__dict__:
            if not key.startswith("__") and not callable(cls.__dict__.get(key)):
                keys.append(key)
        return keys.sort()

    @classmethod
    def get(cls, name):
        """
        returns value of constant by name

        input: string with name of constant to read

        output: value of constant, which may be an integer number, floating point number or string
        """
        if name is None or name.startswith("__"):
            return None
        value = cls.__dict__.get(name)
        if value is None or callable(value):
            return None
        return value

    def __getattr__(self, name):
        """
        accessor for class constants - __getattr__ is the Python class method for when a get
        operation on an object fails. This changes the name to upper case and tries again,
        since the constants are all upper case.

        input: string with name of constant to read

        output: value of constant, which may be an integer number, floating point number or string
        """
        up_name = name.upper()
        value = self.__class__.get(up_name)
        if value is None:
            raise AttributeError(f"module {__name__!r} has no attribute {up_name!r}")
        return value
