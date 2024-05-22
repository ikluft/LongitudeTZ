#!/usr/bin/env python3
"""unit tests of timezone_solar package accessors used by command-line interface"""

import unittest
from timezone_solar import TimeZoneSolar
from timezone_solar.tests.utils import LongitudeUtils
from timezone_solar.tests.run_tests import Flags, main_tests_per_file

# constants
PROGNUM = 14
TEST_FIXTURE = [
    {
        # date line +180 degrees longitude, hour-wide tz
        "params": {"longitude": 180.0, "use_lon_tz": False},
        "expect": {"name": "Solar/East12", "short_name": "East12", "long_name": "Solar/East12",
                   "longitude": "180", "latitude": "", "offset": "+12:00", "offset_min": "720",
                   "offset_sec": "43200", "is_utc": "0"},
    },
    {
        # date line +180 degrees longitude, hour-wide tz
        "params": {"tzname": "East12"},
        "expect": {"name": "Solar/East12", "short_name": "East12", "long_name": "Solar/East12",
                   "longitude": "180", "latitude": "", "offset": "+12:00", "offset_min": "720",
                   "offset_sec": "43200", "is_utc": "0"},
    },
    {
        # date line +180 degrees longitude, degree-wide tz
        "params": {"longitude": 180.0, "use_lon_tz": True},
        "expect": {"name": "Solar/Lon180E", "short_name": "Lon180E", "long_name": "Solar/Lon180E",
                   "longitude": "180", "latitude": "", "offset": "+12:00", "offset_min": "720",
                   "offset_sec": "43200", "is_utc": "0"},
    },
    {
        # date line +180 degrees longitude, degree-wide tz
        "params": {"tzname": "Lon180E"},
        "expect": {"name": "Solar/Lon180E", "short_name": "Lon180E", "long_name": "Solar/Lon180E",
                   "longitude": "180", "latitude": "", "offset": "+12:00", "offset_min": "720",
                   "offset_sec": "43200", "is_utc": "0"},
    },
    {
        # date line +180 degrees longitude, +80 degrees latitude, degree-wide tz
        "params": {"longitude": 180.0, "use_lon_tz": True, "latitude": 80},
        "expect": {"name": "Solar/Lon000E", "short_name": "Lon000E", "long_name": "Solar/Lon000E",
                   "longitude": "180", "latitude": "80", "offset": "+00:00", "offset_min": "0",
                   "offset_sec": "0", "is_utc": "1"},
    },
    {
        # near date line +179.99 degrees longitude, degree-wide tz
        "params": {"longitude": 179.99, "use_lon_tz": True},
        "expect": {"name": "Solar/Lon180E", "short_name": "Lon180E", "long_name": "Solar/Lon180E",
                   "longitude": "179.99", "latitude": "", "offset": "+12:00", "offset_min": "720",
                   "offset_sec": "43200", "is_utc": "0"},
    },
    {
        # Portland Int'l Airport PDX: -122.597 longitude, +45.589 latititude, hour-wide tz
        "params": {"longitude": -122.597, "use_lon_tz": False, "latitude": 45.589},
        "expect": {"name": "Solar/West08", "short_name": "West08", "long_name": "Solar/West08",
                   "longitude": "-122.597", "latitude": "45.589", "offset": "-08:00", "offset_min": "-480",
                   "offset_sec": "-28800", "is_utc": "0"},
    },
    {
        # Portland Int'l Airport PDX: -122.597 longitude, +45.589 latititude, hour-wide tz
        "params": {"tzname": "West08"},
        "expect": {"name": "Solar/West08", "short_name": "West08", "long_name": "Solar/West08",
                   "longitude": "-120", "latitude": "", "offset": "-08:00", "offset_min": "-480",
                   "offset_sec": "-28800", "is_utc": "0"},
    },
    {
        # Portland Int'l Airport PDX: -122.597 longitude, +45.589 latititude, degree-wide tz
        "params": {"longitude": -122.597, "use_lon_tz": True, "latitude": 45.589},
        "expect": {"name": "Solar/Lon123W", "short_name": "Lon123W", "long_name": "Solar/Lon123W",
                   "longitude": "-122.597", "latitude": "45.589", "offset": "-08:12", "offset_min": "-492",
                   "offset_sec": "-29520", "is_utc": "0"},
    },
    {
        # Portland Int'l Airport PDX: -122.597 longitude, +45.589 latititude, degree-wide tz
        "params": {"tzname": "Lon123W"},
        "expect": {"name": "Solar/Lon123W", "short_name": "Lon123W", "long_name": "Solar/Lon123W",
                   "longitude": "-123", "latitude": "", "offset": "-08:12", "offset_min": "-492",
                   "offset_sec": "-29520", "is_utc": "0"},
    },
    {
        # near date line -179.99 degrees longitude, hour-wide tz
        "params": {"longitude": -179.99, "use_lon_tz": False},
        "expect": {"name": "Solar/West12", "short_name": "West12", "long_name": "Solar/West12",
                   "longitude": "-179.99", "latitude": "", "offset": "-12:00", "offset_min": "-720",
                   "offset_sec": "-43200", "is_utc": "0"},
    },
    {
        # near date line -179.99 degrees longitude, degree-wide tz
        "params": {"longitude": -179.99, "use_lon_tz": True},
        "expect": {"name": "Solar/Lon180W", "short_name": "Lon180W", "long_name": "Solar/Lon180W",
                   "longitude": "-179.99", "latitude": "", "offset": "-12:00", "offset_min": "-720",
                   "offset_sec": "-43200", "is_utc": "0"},
    },
    {
        # date line -180 degrees longitude, hour-wide tz
        "params": {"tzname": "East12"},
        "expect": {"name": "Solar/East12", "short_name": "East12", "long_name": "Solar/East12",
                   "longitude": "180", "latitude": "", "offset": "+12:00", "offset_min": "720",
                   "offset_sec": "43200", "is_utc": "0"},
    },
    {
        # date line -180 degrees longitude, hour-wide tz
        "params": {"longitude": -180, "use_lon_tz": False},
        "expect": {"name": "Solar/East12", "short_name": "East12", "long_name": "Solar/East12",
                   "longitude": "-180", "latitude": "", "offset": "+12:00", "offset_min": "720",
                   "offset_sec": "43200", "is_utc": "0"},
    },
    {
        # date line -180 degrees longitude, degree-wide tz
        "params": {"longitude": -180, "use_lon_tz": True},
        "expect": {"name": "Solar/Lon180E", "short_name": "Lon180E", "long_name": "Solar/Lon180E",
                   "longitude": "-180", "latitude": "", "offset": "+12:00", "offset_min": "720",
                   "offset_sec": "43200", "is_utc": "0"},
    },
    {
        # date line -180 degrees longitude, degree-wide tz
        "params": {"tzname": "Lon180E"},
        "expect": {"name": "Solar/Lon180E", "short_name": "Lon180E", "long_name": "Solar/Lon180E",
                   "longitude": "180", "latitude": "", "offset": "+12:00", "offset_min": "720",
                   "offset_sec": "43200", "is_utc": "0"},
    },
]


class TestAccessors(unittest.TestCase, LongitudeUtils):
    """unit tests of timezone_solar package accessors used by command-line interface"""

    @classmethod
    def make_field_test(cls, base_func_name: str, fixture: dict, field: str, expect_value: str) -> callable:
        """generate test case function for accessor value within a test fixture"""
        description = f"test {base_func_name}: -> {field} {expect_value}"
        obj = TimeZoneSolar(**fixture["params"])

        # generate check function to be stored as tests for each fixture & field
        def check(self):
            self.assertEqual(str(obj.get(field)), expect_value)
        check.__doc__ = description
        return check

    @classmethod
    def generate_tests(cls) -> None:
        """generate test functions for integration with datetime.tzinfo system library"""
        testnum = 0

        for fixture in TEST_FIXTURE:
            # generate tests based on TEST_FIXTURE array's parameters and expected results
            if "longitude" in fixture["params"] and fixture["params"]["longitude"] is not None:
                lon_str = fixture["params"]["longitude"]
                use_lon_tz = fixture["params"]["use_lon_tz"]
                tz_type = "deg" if use_lon_tz else "hour"
                base_func_name = f"test_{PROGNUM:03}_{testnum:03}_accessor_lon_{lon_str}_{tz_type}"
            elif "tzname" in fixture["params"] and fixture["params"]["tzname"] is not None:
                tzname = fixture["params"]["tzname"]
                base_func_name = f"test_{PROGNUM:03}_{testnum:03}_accessor_tzname_{tzname}"
            else:
                raise ValueError("test fixture should contain one of longitude or tzname field")
            Flags.verbose_print(
                f"generating test {base_func_name}..."
            )

            # generate tests from fixture
            for field in fixture["expect"]:
                expect_value = fixture["expect"][field]

                # generate test case function for accessor value within a test fixture
                check_field_func = cls.make_field_test(base_func_name, fixture, field, expect_value)

                # save check function as a generated test function
                setattr(cls, f"{base_func_name}_{field}", check_field_func)

            testnum += 1


if __name__ == "__main__":
    main_tests_per_file(__file__)
