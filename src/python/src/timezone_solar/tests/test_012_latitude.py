#!/usr/bin/env python
"""unit tests of latitude-based computation in timezone_solar"""

import unittest
from timezone_solar.tzsconst import TZSConst
from timezone_solar import TimeZoneSolar
from timezone_solar.tests.utils import LongitudeUtils
from timezone_solar.tests.run_tests import Flags, main_tests_per_file

# constants
PROGNUM = 12
test_point_longitudes = [
    180.0,
    179.99999,
    -7.5,
    -7.49999,
    0.0,
    7.49999,
    7.5,
    -180.0,
    -179.99999,
    60.0,
    90.0,
    89.5,
    89.49999,
    120.0,
]
test_point_latitudes = [80.0, 79.99999, -80.0, -79.99999]


class TestLatitude(unittest.TestCase, LongitudeUtils):
    """unit tests of latitude-based computation in timezone_solar"""

    @staticmethod
    def gen_polar_test_points() -> list:
        """generate polar test points array with lat/lon coordinates"""
        polar_test_points = []
        for use_lon_tz in [False, True]:
            for longitude in test_point_longitudes:
                for latitude in test_point_latitudes:
                    polar_test_points.append(
                        {
                            "longitude": longitude,
                            "latitude": latitude,
                            "use_lon_tz": use_lon_tz,
                        }
                    )
        return polar_test_points

    @classmethod
    def make_key_check(cls, testnum, key, expected) -> callable:
        """generate test case function for specific lat/lon coordinate"""
        tz_type = "deg" if expected["use_lon_tz"] else "hour"
        description = (
            f"test {PROGNUM:03}-{testnum:03}: lat={expected['latitude']},"
            + f"lon={expected['longitude']},{tz_type} "
            + f"→ {key}={expected[key]}"
        )
        Flags.verbose_print(f"make test: {description}")

        def check(self):
            obj = TimeZoneSolar(
                longitude=expected["longitude"],
                latitude=expected["latitude"],
                use_lon_tz=expected["use_lon_tz"],
            )
            self.assertEqual(expected[key], getattr(obj, key))

        check.__doc__ = description
        return check

    @classmethod
    def generate_tests(cls):
        """generate test functions for various latitudes at all degrees of longitude"""
        const = TZSConst()
        polar_test_points = TestLatitude.gen_polar_test_points()
        testnum = 0
        for test_point in polar_test_points:
            # set up expected values for tests
            Flags.verbose_print(f"generate_tests: {test_point}")
            expect_lon = (
                test_point["longitude"]
                if abs(test_point["latitude"])
                <= const.limit_latitude - const.precision_fp
                else 0
            )
            expected = cls.expect_lon2tz(expect_lon, test_point["use_lon_tz"])
            expected["longitude"] = test_point["longitude"]
            expected["latitude"] = test_point["latitude"]
            expected["use_lon_tz"] = test_point["use_lon_tz"]

            # generate test
            lon_str = cls.coord2str(expected["longitude"])
            lat_str = cls.coord2str(expected["latitude"])
            func_name_base = (
                f"test_{PROGNUM:03}_{testnum:03}_lon_{lon_str}_lat_{lat_str}"
            )
            for key in [
                "longitude",
                "latitude",
                "short_name",
                "name",
                "offset_min",
                "use_lon_tz",
            ]:
                func_name = f"{func_name_base}_key_{key}"
                Flags.verbose_print(
                    f"generating test {PROGNUM:03}-{testnum:03} as {func_name}..."
                )
                check_func = cls.make_key_check(testnum, key, expected)
                setattr(cls, func_name, check_func)
            testnum += 1


if __name__ == "__main__":
    main_tests_per_file(__file__)
