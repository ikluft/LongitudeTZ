"""constants for timezone_solar"""
from datetime import timedelta
import re

class TZSConst:
    """
    class to contain contants for TimeZoneSolar so unit tests can access them
    """
    # constants: time duration
    ZERO = timedelta(0)
    HOUR = timedelta(hours=1)
    SECOND = timedelta(seconds=1)

    # constants: regular expressions for solar time zones
    TZSOLAR_LON_ZONE_STR = '(Lon0[0-9][0-9][EW])|(Lon1[0-7][0-9][EW])|(Lon180[EW])'
    TZSOLAR_HOUR_ZONE_STR = '(East|West)(0[0-9]| 1[0-2])'
    TZSOLAR_ZONE_STR = TZSOLAR_LON_ZONE_STR + "|" + TZSOLAR_HOUR_ZONE_STR
    TZSOLAR_LON_ZONE_RE = re.compile(TZSOLAR_LON_ZONE_STR)
    TZSOLAR_HOUR_ZONE_RE = re.compile(TZSOLAR_HOUR_ZONE_STR)
    TZSOLAR_ZONE_RE = re.compile(TZSOLAR_ZONE_STR)

    # constants: precision
    PRECISION_DIGITS = 6
    PRECISION_FP = (10 ** -PRECISION_DIGITS) / 2.0

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
        """
        keys = []
        for key in cls.__dict__:
            if not key.startswith('__') and not callable(cls.__dict__.get(key)):
                keys.append(key)
        return keys.sort()

    @classmethod
    def get(cls, name):
        """
        returns value of constant by name
        """
        if name is None or name.startswith('__'):
            return None
        value = cls.__dict__.get(name)
        if value is None or callable(value):
            return None
        return value

    def gen_func_float(self, key):
        """
        generate read-accessor function for floating point constant
        """
        def const_float() -> float:
            return float(self.__class__.get(key))
        self.__dict__[key.casefold()] = const_float

    def gen_func_int(self, key):
        """
        generate read-accessor function for integer constant
        """
        def const_int() -> int:
            return int(self.__class__.get(key))
        self.__dict__[key.casefold()] = const_int

    def gen_func_str(self, key):
        """
        generate read-accessor function for string constant
        """
        self.__dict__[key.casefold()] = lambda: str(self.__dict__.get(key))
        def const_str() -> str:
            return str(self.__class__.get(key))
        self.__dict__[key.casefold()] = const_str

    def __init__(self):
        """
        generate read-accessor functions for constants
        """
        for key in self.__dict__:
            if not key.startswith('__') and not callable(self.__dict__.get(key)):
                if re.fullmatch('^.*_FP$', key):
                    self.gen_func_float(key)
                if re.fullmatch('^.*_INT$', key):
                    self.gen_func_int(key)
                else:
                    self.gen_func_str(key)
