#!/usr/bin/env python
"""unit tests for timezone_solar"""

import os
import sys
import unittest
from datetime import timedelta
from tap import TAPTestRunner
from timezone_solar.tzsconst import TZSConst
from timezone_solar import TimeZoneSolar

class TestBasic(unittest.TestCase):
    """basic unit tests for TimeZoneSolar"""

    @staticmethod
    def _tz_prefix(use_lon_tz, sign) -> str:
        return "Lon" if use_lon_tz else ( "East" if sign > 0 else "West" )

    @staticmethod
    def _tz_suffix(use_lon_tz, sign) -> str:
        return ( "E" if sign > 0 else "W" ) if use_lon_tz else ""

    @classmethod
    def expect_lon2tz(cls, lon, use_lon_tz) -> dict:
        """
        generate expected values for tests at a specific longitude
        """
        const = TZSConst()
        tz_degree_width = 1 if use_lon_tz else 15
        tz_digits = 3 if use_lon_tz else 2

        # generate time zone name and offset
        expect = dict()
        if lon >= const.max_longitude_int - tz_degree_width / 2.0 - const.precision_fp \
                or lon <= -const.max_longitude_int + const.precision_fp:
            # handle special case of half-wide tz at positive side of date line (180°)
            # special case of -180: expect results for +180
            tz_num_str = str(const.max_longitude_int/tz_degree_width).zfill(tz_digits)
            prefix = cls._tz_prefix(use_lon_tz, 1)
            suffix = cls._tz_suffix(use_lon_tz, 1)
            expect["short_name"] = f"{prefix}{tz_num_str}{suffix}"
            expect["offset_min"] = 720
        elif lon <= ( -const.max_longitude_int + tz_degree_width / 2.0 + const.precision_fp ):
            # handle special case of half-wide tz at negative side of date line (180°)
            tz_num_str = str(const.max_longitude_int/tz_degree_width).zfill(tz_digits)
            prefix = cls._tz_prefix(use_lon_tz, -1)
            suffix = cls._tz_suffix(use_lon_tz, -1)
            expect["short_name"] = f"{prefix}{tz_num_str}{suffix}"
            expect["offset_min"] = -720
        else:
            # handle all other times zones
            tz_int = int(abs(lon) / tz_degree_width + 0.5 + const.precision_fp)
            tz_num_str = str(tz_int).zfill(tz_digits)
            sign = 1 if lon > -tz_degree_width / 2.0 + const.precision_fp else -1
            prefix = cls._tz_prefix(use_lon_tz, sign)
            suffix = cls._tz_suffix(use_lon_tz, sign)
            expect["short_name"] = f"{prefix}{tz_num_str}{suffix}"
            expect["offset_min"] = sign * tz_int * (const.minutes_per_degree_lon * tz_degree_width)

        # return expected values for tests
        # expand this as needed when adding more tests
        expect["name"] = "Solar/" + expect["short_name"]
        return expect

    @classmethod
    def make_short_tzname_test(cls, testnum, longitude, use_lon_tz) -> callable:
        """generate test case function for timezone short name at a degree of longitude"""
        expected = cls.expect_lon2tz(longitude, use_lon_tz)
        tz_type = "deg" if use_lon_tz else "hour"
        description = f"test {testnum:03}: lon {longitude}, tz by {tz_type} " \
            + f"→ short name {expected['short_name']}"
        def check(self):
            obj = TimeZoneSolar(longitude=longitude, use_lon_tz=use_lon_tz)
            self.assertEqual(obj.short_name, expected["short_name"])
        check.__doc__ = description
        return check

    @classmethod
    def make_long_tzname_test(cls, testnum, longitude, use_lon_tz) -> callable:
        """generate test case function for timezone long name at a degree of longitude"""
        expected = cls.expect_lon2tz(longitude, use_lon_tz)
        tz_type = "deg" if use_lon_tz else "hour"
        description = f"test {testnum:03}: lon {longitude}, tz by {tz_type} " \
            + f"→ long name {expected['name']}"
        def check(self):
            obj = TimeZoneSolar(longitude=longitude, use_lon_tz=use_lon_tz)
            self.assertEqual(obj.name, expected["name"])
        check.__doc__ = description
        return check

    @classmethod
    def make_offset_test(cls, testnum, longitude, use_lon_tz) -> callable:
        """generate test case function for offset at a degree of longitude"""
        expected = cls.expect_lon2tz(longitude, use_lon_tz)
        tz_type = "deg" if use_lon_tz else "hour"
        description = f"test {testnum:03}: lon {longitude}, tz by {tz_type} " \
            + f"→ offset {expected['offset_min']}"
        def check(self):
            obj = TimeZoneSolar(longitude=longitude, use_lon_tz=use_lon_tz)
            self.assertEqual(obj.offset_min, expected["offset_min"])
        check.__doc__ = description
        return check

    @classmethod
    def generate_tests(cls):
        """generate test functions for all degrees of longitude """
        testnum = 0
        for longitude in range(-180, 180):
            #print( f"generating test {testnum:03} lon {longitude:+04}..." )
            for use_lon_tz in [0,1]:
                check_short_name_func = cls.make_short_tzname_test(testnum, longitude, use_lon_tz)
                setattr(cls, f"test_{testnum:03}_short_name_{longitude:+04}", check_short_name_func)
                check_long_name_func = cls.make_long_tzname_test(testnum, longitude, use_lon_tz)
                setattr(cls, f"test_{testnum:03}_long_name_{longitude:+04}", check_long_name_func)
                check_offset_func = cls.make_offset_test(testnum, longitude, use_lon_tz)
                setattr(cls, f"test_{testnum:03}_offset_{longitude:+04}", check_offset_func)
            testnum += 1

if __name__ == '__main__':
    from timezone_solar.test.run_tests import main_tests
    main_tests(os.path.basename(__file__))
