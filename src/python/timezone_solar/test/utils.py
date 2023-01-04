#!/usr/bin/env python
"""longitude computation utilities for timezone_solar tests"""

import re
from timezone_solar.tzsconst import TZSConst


class LongitudeUtils:
    """longitude computation utilities for timezone_solar tests"""

    @staticmethod
    def coord2str(num, digits=3) -> str:
        """convert floating point lat or lon coordinate to string for test function name"""
        sign = "P" if num >= 0 else "M"
        numstr = str(abs(num)).zfill(digits)
        numstr = re.sub("[^0-9]+", "_", numstr)
        return sign + numstr

    @staticmethod
    def _tz_prefix(use_lon_tz, sign) -> str:
        return "Lon" if use_lon_tz else ("East" if sign > 0 else "West")

    @staticmethod
    def _tz_suffix(use_lon_tz, sign) -> str:
        return ("E" if sign > 0 else "W") if use_lon_tz else ""

    @classmethod
    def expect_lon2tz(cls, lon, use_lon_tz) -> dict:
        """
        generate expected values for tests at a specific longitude
        """
        const = TZSConst()
        tz_degree_width = 1 if use_lon_tz else 15
        tz_digits = 3 if use_lon_tz else 2

        # generate time zone name and offset
        expect = {}
        if (
            lon >= const.max_longitude_int - tz_degree_width / 2.0 - const.precision_fp
            or lon <= -const.max_longitude_int + const.precision_fp
        ):
            # handle special case of half-wide tz at positive side of date line (180°)
            # special case of -180: expect results for +180
            tz_num_str = str(int(const.max_longitude_int / tz_degree_width)).zfill(tz_digits)
            prefix = cls._tz_prefix(use_lon_tz, 1)
            suffix = cls._tz_suffix(use_lon_tz, 1)
            expect["short_name"] = f"{prefix}{tz_num_str}{suffix}"
            expect["offset_min"] = 720
        elif lon <= (
            -const.max_longitude_int + tz_degree_width / 2.0 + const.precision_fp
        ):
            # handle special case of half-wide tz at negative side of date line (180°)
            tz_num_str = str(int(const.max_longitude_int / tz_degree_width)).zfill(tz_digits)
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
            expect["offset_min"] = (
                sign * tz_int * (const.minutes_per_degree_lon * tz_degree_width)
            )

        # return expected values for tests
        # expand this as needed when adding more tests
        expect["name"] = "Solar/" + expect["short_name"]
        return expect
