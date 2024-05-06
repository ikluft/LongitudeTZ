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

import argparse


def _gen_arg_parser() -> argparse.ArgumentParser:
    """generate argparse parser hierarchy"""
    # TODO


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
