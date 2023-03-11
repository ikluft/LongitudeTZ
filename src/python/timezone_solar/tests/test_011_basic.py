#!/usr/bin/env python
"""unit tests for timezone_solar"""

import unittest
from timezone_solar import TimeZoneSolar
from timezone_solar.tests.utils import LongitudeUtils
from timezone_solar.tests.run_tests import Flags, main_tests_per_file

# constants
PROGNUM = 11


class TestBasic(unittest.TestCase, LongitudeUtils):
    """basic unit tests for TimeZoneSolar"""

    @classmethod
    def make_short_tzname_test(cls, testnum, longitude, use_lon_tz) -> callable:
        """generate test case function for timezone short name at a degree of longitude"""
        expected = cls.expect_lon2tz(longitude, use_lon_tz)
        tz_type = "deg" if use_lon_tz else "hour"
        description = (
            f"test {PROGNUM:03}-{testnum:03}: lon {longitude}, tz by {tz_type} "
            + f"→ short name {expected['short_name']}"
        )

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
        description = (
            f"test {PROGNUM:03}-{testnum:03}: lon {longitude}, tz by {tz_type} "
            + f"→ long name {expected['name']}"
        )

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
        description = (
            f"test {PROGNUM:03}-{testnum:03}: lon {longitude}, tz by {tz_type} "
            + f"→ offset {expected['offset_min']}"
        )

        def check(self):
            obj = TimeZoneSolar(longitude=longitude, use_lon_tz=use_lon_tz)
            self.assertEqual(obj.offset_min, expected["offset_min"])

        check.__doc__ = description
        return check

    @classmethod
    def generate_tests(cls):
        """generate test functions for all degrees of longitude"""
        testnum = 0
        for longitude in range(-180, 180):
            Flags.verbose_print(
                f"generating test {PROGNUM:03}-{testnum:03} lon {longitude:+04}..."
            )
            lon_str = cls.coord2str(longitude)
            for use_lon_tz in [False, True]:
                check_short_name_func = cls.make_short_tzname_test(
                    testnum, longitude, use_lon_tz
                )
                setattr(
                    cls,
                    f"test_{PROGNUM:03}_{testnum:03}_short_name_{lon_str}",
                    check_short_name_func,
                )
                check_long_name_func = cls.make_long_tzname_test(
                    testnum, longitude, use_lon_tz
                )
                setattr(
                    cls,
                    f"test_{PROGNUM:03}_{testnum:03}_long_name_{lon_str}",
                    check_long_name_func,
                )
                check_offset_func = cls.make_offset_test(testnum, longitude, use_lon_tz)
                setattr(
                    cls,
                    f"test_{PROGNUM:03}_{testnum:03}_offset_{lon_str}",
                    check_offset_func,
                )
            testnum += 1


if __name__ == "__main__":
    main_tests_per_file(__file__)
