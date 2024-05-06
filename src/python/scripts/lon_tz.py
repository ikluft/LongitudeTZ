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


def _gen_arg_parser() -> argparse.ArgumentParser:
    """generate argparse parser hierarchy"""

    # define global parser
    top_parser = argparse.ArgumentParser(
        prog=PROG_NAME,
        description="command-line interface for LongitudeTZ tzdata and black box testing",
    )
    top_parser.add_argument("--version", action="version", version=_get_version())

    # TODO
    return top_parser


def main():
    """process command line arguments and run program"""

    # define global parser
    top_parser = _gen_arg_parser()

    # parse arguments and run subcommand functions
    args = vars(top_parser.parse_args())
    err = None
    if "func" not in args:
        top_parser.error("no command was specified")
    try:
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
