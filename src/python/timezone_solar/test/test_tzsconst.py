#!/usr/bin/env python
"""unit tests for tzsconst"""

import os
import sys
import re
import unittest
from datetime import timedelta
from tap import TAPTestRunner
from timezone_solar.tzsconst import TZSConst

# constants for comparison, same as in TZSConst for double-checking
TZSOLAR_LON_ZONE_STR = '(Lon0[0-9][0-9][EW])|(Lon1[0-7][0-9][EW])|(Lon180[EW])'
TZSOLAR_HOUR_ZONE_STR = '(East|West)(0[0-9]| 1[0-2])'
TZSOLAR_ZONE_STR = TZSOLAR_LON_ZONE_STR + "|" + TZSOLAR_HOUR_ZONE_STR
TZSOLAR_LON_ZONE_RE = re.compile(TZSOLAR_LON_ZONE_STR)
TZSOLAR_HOUR_ZONE_RE = re.compile(TZSOLAR_HOUR_ZONE_STR)
TZSOLAR_ZONE_RE = re.compile(TZSOLAR_ZONE_STR)
CONSTANTS = {
    "ZERO": timedelta(0),
    "HOUR": timedelta(hours=1),
    "SECOND": timedelta(seconds=1),
    "TZSOLAR_LON_ZONE_STR": TZSOLAR_LON_ZONE_STR,
    "TZSOLAR_HOUR_ZONE_STR": TZSOLAR_HOUR_ZONE_STR,
    "TZSOLAR_ZONE_STR": TZSOLAR_ZONE_STR,
    "TZSOLAR_LON_ZONE_RE": TZSOLAR_LON_ZONE_RE,
    "TZSOLAR_HOUR_ZONE_RE": TZSOLAR_HOUR_ZONE_RE,
    "TZSOLAR_ZONE_RE": TZSOLAR_ZONE_RE,
    "PRECISION_DIGITS": 6,
    "PRECISION_FP": 0.0000005,
    "MAX_DEGREES": 360,
    "MAX_LONGITUDE_INT": 180,
    "MAX_LONGITUDE_FP": 180.0,
    "MAX_LATITUDE_FP": 90.0,
    "POLAR_UTC_AREA": 10,
    "LIMIT_LATITUDE": 80,
    "MINUTES_PER_DEGREE_LON": 4,
}
FP_EPSILON = 2**-24

def fp_equal(fp_x: float, fp_y: float):
    """floating point comparison, not for equality but within FP_EPSILON of each other"""
    return abs( fp_x - fp_y ) < FP_EPSILON

class TestConstants(unittest.TestCase):
    """unit tests for constants in TZSConst"""
    longMessage = True

    @staticmethod
    def make_const_test(const_name, expect_value):
        """generate test case function for constant from name and expected value"""
        def check(self):
            got_value = TZSConst.get(const_name)
            description = f"check constant {const_name}: {expect_value}"
            if const_name.endswith("_FP"):
                # floating point numbers are checked if within FP_EPSILON; equality not reliable
                self.assertTrue(fp_equal(got_value, expect_value), msg=description)
            else:
                # others checked for equality
                self.assertEqual(got_value, expect_value, description)
        return check

    @classmethod
    def generate_tests(cls):
        """generate test functions for all the items in CONSTANTS dictionary"""
        for name, expect_value in CONSTANTS.items():
            #print( f"generating {name} test..." )
            check_func = cls.make_const_test(name, expect_value)
            setattr(cls, f"test_{name}", check_func)

if __name__ == '__main__':
    print( "starting..." )
    TestConstants.generate_tests()
    print( "test functions:" )

    tests_dir = os.path.dirname(os.path.abspath(__file__))
    loader = unittest.TestLoader()
    tests = loader.discover(tests_dir)
    runner = TAPTestRunner()
    runner.set_stream(True)
    runner.set_format("{method_name}: {short_description}")
    result = runner.run(tests)
    sys.exit(0 if result.wasSuccessful() else 1)
