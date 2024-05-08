#!/usr/bin/python
"""
lon_tz.py - command-line interface for LongitudeTZ Python implementation
including tzdata file generation and black box testing
by Ian Kluft

usage:
    lon_tz.py --version
    lon_tz.py --tzfile > output-file
    lon_tz.py [--longitude=nnn.nn] [--latitude=nnn.nn] fieldname [...]
"""

import sys
import argparse
from importlib.metadata import version, PackageNotFoundError
from pathlib import Path
import lib_programname
from timezone_solar import __version__

# type alias for error strings
ErrStr = str

# package and program name
PKG_NAME = "timezone_solar"
PROG_NAME = (
    Path(sys.modules["__main__"].__file__).name
    if hasattr(sys.modules["__main__"], "__file__")
    else lib_programname.get_path_executed_script().name
)

#
# system functions
#


def _get_version():
    """display version"""
    if __version__ is not None:
        ver = __version__
    else:
        try:
            ver = f"{PKG_NAME} " + str(version(PKG_NAME))
        except PackageNotFoundError:
            ver = f"{PKG_NAME} version not available in development environment"
    return ver

#
# tzdata generation functions
#


# generate standard 1-hour-wide (15 degrees longitude) time zones
# input parameter: integer hours from GMT in the range
# These correspond to the GMT+x/GMT-x time zones, except with boundaries defined by longitude lines.
def _gen_hour_tz(hour_in) -> None:
    """generate standard 1-hour-wide (15 degrees longitude) time zones"""
    hour = int(hour_in)
    if hour < -12 or hour > 12:
        raise ValueError("hour parameter must be -12 to +12 inclusive")

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
def _gen_lon_tz(deg_in):
    """generate longitude-based solar time zone info"""
    deg = int(deg_in)
    if deg < -180 or deg > 180:
        raise ValueError("deg parameter must be -180 to +180 inclusive")

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


def _do_tzfile(_) -> None:
    """generate tzdata file"""

    # generate solar time zones in increments of 15 degrees of longitude (STHxxE/STHxxW)
    # standard 1-hour-wide time zones
    for h_zone in range(-12, 12 + 1):
        _gen_hour_tz(h_zone)

    # generate solar time zones in incrememnts of 4 minutes / 1 degree of longitude (STLxxxE/STxxxW)
    # hyperlocal 4-minute-wide time zones for conversion to/from niche uses of local solar time
    for d_zone in range(-180, 180 + 1):
        _gen_lon_tz(d_zone)

#
# command-line parsing functions
#


def _gen_arg_parser() -> argparse.ArgumentParser:
    """generate argparse parser hierarchy"""

    # define global parser
    top_parser = argparse.ArgumentParser(
        prog=PROG_NAME,
        description="command-line interface for LongitudeTZ tzdata and black box testing",
    )
    top_parser.add_argument("--version", action="version", version=_get_version())
    top_parser.add_argument(
        "--verbose",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="more verbose output",
    )
    top_parser.add_argument(
        "--debug",
        action=argparse.BooleanOptionalAction,
        default=False,
        help="turn on debugging mode",
    )

    # --tzfile/tzdata flag triggers output of tzdata file and ends program
    top_parser.add_argument(
        "--tzfile",
        "--tzdata",
        # action=TZFileAction,
        action='store_const',
        dest="func",
        const=_do_tzfile,
        help="generate solar time zones tzdata text",
    )

    return top_parser

#
# program mainline - this executes first
#


def main():
    """process command line arguments and run program"""

    # define global parser
    top_parser = _gen_arg_parser()

    # parse arguments and run subcommand functions
    args = vars(top_parser.parse_args())
    err = None
    if "func" not in args or args["func"] is None:
        top_parser.print_help()
        top_parser.exit()
    try:
        # call function named in argument parser settings with a dictionary of the CLI arguments
        err = args["func"](args)
    except Exception as exc:
        exc_class = exc.__class__
        if "verbose" in args and args["verbose"]:
            print(f"exception {exc_class} occurred with args: ", args)
        raise exc

    # return success/failure results
    if err is not None:
        top_parser.exit(status=1, message=err + "\n")
    top_parser.exit()


if __name__ == "__main__":
    sys.exit(main())
