#!/usr/bin/env python
"""unit tests for tzsconst"""

import unittest
from datetime import timedelta
import re
from ..tzsconst import TZSConst

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

    def test_values(self):
        """check constant values"""

        keys = CONSTANTS.keys().sort()
        subtest=1
        for name in keys:
            with self.subTest(i=subtest):
                value = TZSConst.get(name)
                if name.endswith("_FP"):
                    self.assertTrue(fp_equal(value, CONSTANTS[name]))
                else:
                    self.assertEqual(value, CONSTANTS[name])
            subtest += 1

if __name__ == "__main__":
    unittest.main()
