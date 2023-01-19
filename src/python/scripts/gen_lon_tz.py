#!/usr/bin/env python3
"""generate longitude-based time zone info"""
# gen_lon_tz.py - by Ian Kluft
# Python implementation
#
# Open Source licensing under terms of GNU General Public License version 3
# SPDX identifier: GPL-3.0-only
# https://opensource.org/licenses/GPL-3.0
# https://www.gnu.org/licenses/gpl-3.0.en.html

import sys


# generate standard 1-hour-wide (15 degrees longitude) time zones
# input parameter: integer hours from GMT in the range
# These correspond to the GMT+x/GMT-x time zones, except with boundaries defined by longitude lines.
def gen_hour_tz(hour_in):
    """generate standard 1-hour-wide (15 degrees longitude) time zones"""
    hour = int(hour_in)
    if hour < -12 or hour > 12:
        sys.exit("hour parameter must be -12 to +12 inclusive")

    # Hours line up with time zones. So it's a equal to time zone offset.
    sign = "+" if hour >= 0 else "-"
    e_w = "East" if hour >= 0 else "West"
    offset_hr = abs(hour)
    offset_min = 0

    # generate strings from time zone parameters
    zone_abbrev = f"{e_w}{offset_hr:0>2d}"
    zone_name = f"Solar/{zone_abbrev}"
    offset_str = f"{sign}{offset_hr:d}:{offset_min:0>2d}"

    # output time zone data
    print(f"# Solar Time by hourly increment: {sign}{offset_hr}")
    print("# Zone\tNAME\t\tSTDOFF\tRULES\tFORMAT\t[UNTIL]")
    print(f"Zone\t{zone_name}\t{offset_str}\t-\t{zone_abbrev}")
    print("")


# generate longitude-based solar time zone info
# input parameter: integer degrees of longitude in the range 180 to -180,
# Solar Time Zone centered on the meridian, including one half degree either side of the meridian.
# Each time zone is named for its 1-degree-wide range.
# The exception is at the Solar Date Line, where +12 and -12 time zones are one half degree wide.
def gen_lon_tz(deg_in):
    """generate longitude-based solar time zone info"""
    deg = int(deg_in)
    if deg < -180 or deg > 180:
        sys.exit("deg parameter must be -180 to +180 inclusive")

    # deg>=0: positive degrees (east longitude), straightforward assignments of data
    # deg<0: negative degrees (west longitude)
    lon = abs(deg)
    e_w = "E" if deg >= 0 else "W"
    sign = "" if deg >= 0 else "-"

    # derive time zone parameters from 4 minutes of offset for each degree of longitude
    offset = 4 * abs(deg)
    offset_hr = int(abs(offset) / 60)
    offset_min = abs(offset) % 60

    # generate strings from time zone parameters
    zone_abbrev = f"Lon{lon:0>3d}{e_w}"
    zone_name = f"Solar/{zone_abbrev}"
    offset_str = f"{sign}{offset_hr:d}:{offset_min:0>2d}"

    # output time zone data
    print(f"# Solar Time by degree of longitude: {lon} {e_w}")
    print("# Zone\tNAME\t\tSTDOFF\tRULES\tFORMAT\t[UNTIL]")
    print(f"Zone\t{zone_name}\t{offset_str}\t-\t{zone_abbrev}")
    print("")


#
# main
#

# generate solar time zones in increments of 15 degrees of longitude (STHxxE/STHxxW)
# standard 1-hour-wide time zones
for h_zone in range(-12, 12 + 1):
    gen_hour_tz(h_zone)

# generate solar time zones in incrememnts of 4 minutes / 1 degree of longitude (STLxxxE/STxxxW)
# hyperlocal 4-minute-wide time zones for conversion to/from niche uses of local solar time
for d_zone in range(-180, 180 + 1):
    gen_lon_tz(d_zone)
