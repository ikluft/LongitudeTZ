#!/usr/bin/env python
"""unit tests of timezone_solar package integration with datetime.tzinfo system library"""

import unittest
from datetime import datetime, timedelta, timezone
from timezone_solar import TimeZoneSolar
from timezone_solar.tests.utils import LongitudeUtils
from timezone_solar.tests.run_tests import Flags, main_tests_per_file


# constants
PROGNUM = 13
TEST_TIME = {"year": 2023, "month": 1, "day": 3, "hour": 12, "minute": 0}


class TestDateTime(unittest.TestCase, LongitudeUtils):
    """unit tests of timezone_solar package integration with datetime.tzinfo system library"""

    @classmethod
    def make_name_check(cls, testnum, longitude, use_lon_tz) -> callable:
        """generate test case function for datetime tz name"""
        obj_expected = TimeZoneSolar(
            longitude=longitude,
            use_lon_tz=use_lon_tz,
        )
        expected_name = obj_expected.name
        description = (
            f"test {PROGNUM:03}-{testnum:03}: longitude={longitude} use_lon_tz={use_lon_tz} "
            + f"→ name={expected_name}"
        )

        def check(self):
            tz_test = TimeZoneSolar(
                longitude=longitude,
                use_lon_tz=use_lon_tz,
            )
            dt_test = datetime(
                TEST_TIME["year"],
                TEST_TIME["month"],
                TEST_TIME["day"],
                TEST_TIME["hour"],
                TEST_TIME["minute"],
                tzinfo=tz_test,
            )
            test_name = dt_test.tzname()
            self.assertEqual(test_name, expected_name)

        check.__doc__ = description
        return check

    @classmethod
    def make_offset_check(cls, testnum, longitude, use_lon_tz) -> callable:
        """generate test case function for datetime offset from UTC"""
        obj_expected = TimeZoneSolar(
            longitude=longitude,
            use_lon_tz=use_lon_tz,
        )
        expected_offset = timedelta(minutes=obj_expected.offset_min)
        description = (
            f"test {PROGNUM:03}-{testnum:03}: longitude={longitude} use_lon_tz={use_lon_tz} "
            + f"→ offset={obj_expected.offset_min}"
        )

        def check(self):
            tz_test = TimeZoneSolar(
                longitude=longitude,
                use_lon_tz=use_lon_tz,
            )
            dt_test = datetime(
                TEST_TIME["year"],
                TEST_TIME["month"],
                TEST_TIME["day"],
                TEST_TIME["hour"],
                TEST_TIME["minute"],
                tzinfo=tz_test,
            )
            dt_utc = datetime(
                TEST_TIME["year"],
                TEST_TIME["month"],
                TEST_TIME["day"],
                TEST_TIME["hour"],
                TEST_TIME["minute"],
                tzinfo=timezone.utc,
            )
            offset_delta = dt_utc - dt_test
            self.assertEqual(offset_delta, expected_offset)

        check.__doc__ = description
        return check

    @classmethod
    def make_dst_check(cls, testnum, longitude, use_lon_tz) -> callable:
        """generate test case function for datetime DST delta, which is always zero"""
        expected_dst = timedelta(0)
        description = (
            f"test {PROGNUM:03}-{testnum:03}: longitude={longitude} use_lon_tz={use_lon_tz} "
            + "→ dst=0"
        )

        def check(self):
            tz_test = TimeZoneSolar(
                longitude=longitude,
                use_lon_tz=use_lon_tz,
            )
            dt_test = datetime(
                TEST_TIME["year"],
                TEST_TIME["month"],
                TEST_TIME["day"],
                TEST_TIME["hour"],
                TEST_TIME["minute"],
                tzinfo=tz_test,
            )
            test_dst = dt_test.dst()
            self.assertEqual(test_dst, expected_dst)

        check.__doc__ = description
        return check

    @classmethod
    def make_astimezone_check(cls, testnum, longitude, use_lon_tz) -> callable:
        """generate test case function for datetime astimezone method"""
        description = (
            f"test {PROGNUM:03}-{testnum:03}: longitude={longitude} use_lon_tz={use_lon_tz} "
            + "→ astimezone match"
        )

        def check(self):
            tz_test = TimeZoneSolar(
                longitude=longitude,
                use_lon_tz=use_lon_tz,
            )
            dt_utc = datetime(
                TEST_TIME["year"],
                TEST_TIME["month"],
                TEST_TIME["day"],
                TEST_TIME["hour"],
                TEST_TIME["minute"],
                tzinfo=timezone.utc,
            )
            dt_test = dt_utc.astimezone(tz_test)
            self.assertEqual(dt_test, dt_utc)

        check.__doc__ = description
        return check

    @classmethod
    def generate_tests(cls):
        """generate test functions for integration with datetime.tzinfo system library"""
        testnum = 0
        for longitude in range(-180, 181, 3):
            lon_str = cls.coord2str(longitude)
            for use_lon_tz in [0, 1]:
                # generate tests for datetime tests from timezone_solar object
                tz_type = "deg" if use_lon_tz else "hour"
                base_func_name = (
                    f"test_{PROGNUM:03}_{testnum:03}_lon_{lon_str}_{tz_type}"
                )

                # test getting UTC offset back from datetime
                Flags.verbose_print(
                    f"generating test {PROGNUM:03}-{testnum:03} as {base_func_name}_offset..."
                )
                check_offset_func = cls.make_offset_check(
                    testnum, longitude, use_lon_tz
                )
                setattr(cls, base_func_name + "_offset", check_offset_func)

                # test getting timezone name back from datetime
                Flags.verbose_print(
                    f"generating test {PROGNUM:03}-{testnum:03} as {base_func_name}_name..."
                )
                check_name_func = cls.make_name_check(testnum, longitude, use_lon_tz)
                setattr(cls, base_func_name + "_name", check_name_func)

                # test getting timezone dst delta back from datetime
                Flags.verbose_print(
                    f"generating test {PROGNUM:03}-{testnum:03} as {base_func_name}_dst..."
                )
                check_dst_func = cls.make_dst_check(testnum, longitude, use_lon_tz)
                setattr(cls, base_func_name + "_dst", check_dst_func)

                # test getting datetime astimezone() equality test between any time zone and UTC
                Flags.verbose_print(
                    f"generating test {PROGNUM:03}-{testnum:03} as "
                    + f"{base_func_name}_astimezone..."
                )
                check_astimezone_func = cls.make_astimezone_check(
                    testnum, longitude, use_lon_tz
                )
                setattr(cls, base_func_name + "_astimezone", check_astimezone_func)

                testnum += 1


if __name__ == "__main__":
    main_tests_per_file(__file__)
