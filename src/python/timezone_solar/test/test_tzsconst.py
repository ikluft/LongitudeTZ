#!/usr/bin/env python
"""unit tests for tzsconst"""

import os
import re
import unittest
from datetime import timedelta
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

    @classmethod
    def make_value_test(cls, const_name, expect_value):
        """generate test case function for constant from name and expected value"""
        description = f"check value of constant {const_name}: {expect_value}"
        def check_value(self):
            got_value = TZSConst.get(const_name)
            if const_name.endswith("_FP"):
                # floating point numbers are checked if within FP_EPSILON; equality not reliable
                self.assertTrue(fp_equal(got_value, expect_value), msg=description)
            else:
                # others checked for equality
                self.assertEqual(got_value, expect_value, description)
        check_value.__doc__ = description
        return check_value

    @classmethod
    def make_getattr_test(cls, const_name, expect_value):
        """generate test case function for constant via object access"""
        description = f"check constant via getattr: {const_name} = {expect_value}"
        def check_getattr(self):
            const = TZSConst()
            if expect_value is None:
                with self.assertRaises( AttributeError ):
                    object.__getattribute__(const.__class__, const_name)
                return
            got_value = object.__getattribute__(const.__class__, const_name)
            if const_name.endswith("_FP"):
                # floating point numbers are checked if within FP_EPSILON; equality not reliable
                self.assertTrue(fp_equal(got_value, expect_value), msg=description)
            else:
                # others checked for equality
                self.assertEqual(got_value, expect_value, description)
        check_getattr.__doc__ = description
        return check_getattr

    @classmethod
    def generate_tests(cls):
        """generate test functions for all the items in CONSTANTS dictionary"""

        # test existing values
        testnum = 0
        for name, expect_value in CONSTANTS.items():
            #print( f"generating {name} test..." )
            check_value_func = cls.make_value_test(name, expect_value)
            setattr(cls, f"test_{testnum:03}_const_{name}", check_value_func)
            check_getattr_func = cls.make_getattr_test(name, expect_value)
            setattr(cls, f"test_{testnum:03}_getattr_{name}", check_getattr_func)
            testnum += 1

        # test non-existent value
        bad_name = "NONEXISTENT"
        check_value_func = cls.make_value_test(bad_name, None)
        setattr(cls, f"test_{testnum:03}_const_{bad_name}_none", check_value_func)
        check_getattr_func = cls.make_getattr_test(bad_name, None)
        setattr(cls, f"test_{testnum:03}_getattr_{bad_name}_fails", check_getattr_func)

if __name__ == '__main__':
    from timezone_solar.test.run_tests import main_tests
    main_tests(os.path.basename(__file__))
