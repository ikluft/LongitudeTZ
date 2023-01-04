"""run unit tests for timezone_solar"""
import os
import sys
import argparse
import tempfile
import shutil
import unittest
from tap import TAPTestRunner

# constants
HERE = os.path.dirname(__file__)
TEMP_PREFIX = "timezone_solar_tap_"


# globals
class Flags:
    """global flags: verbose and debug"""

    debug_mode = False
    verbose_mode = False

    @classmethod
    def debug_flag(cls, value=None) -> bool:
        """debug-mode flag read/write accessor: sets value if provided, returns value"""
        if value is not None:
            cls.debug_mode = bool(value)
        return cls.debug_mode

    @classmethod
    def verbose_flag(cls, value=None) -> bool:
        """verbose-mode flag read/write accessor: sets value if provided, returns value"""
        if value is not None:
            cls.verbose_mode = bool(value)
        return cls.verbose_mode

    @classmethod
    def debug_print(cls, mesg, file=sys.stderr) -> None:
        """print message if in debug mode"""
        if cls.debug_mode:
            print(mesg, file=file)

    @classmethod
    def verbose_print(cls, mesg, file=sys.stderr) -> None:
        """print message if in verbose or debug modes"""
        if cls.verbose_mode or cls.debug_mode:
            print(mesg, file=file)


# parse command line arguments
def _ingest_argv() -> None:
    description = "run tests for timezone_solar"
    epilog = "runs tests from a specific test script or from the entire test directory"
    parser = argparse.ArgumentParser(description=description, epilog=epilog)
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        default=False,
        help="set verbose mode",
    )
    parser.add_argument(
        "-d",
        "--debug",
        action="store_true",
        default=False,
        help="set debug mode",
    )

    # pass arguments after the command name (in slot 0) to argparse
    args = parser.parse_args(sys.argv[1:])
    if args.debug:
        Flags.debug_flag(args.debug)
    if args.verbose:
        Flags.verbose_flag(args.verbose)


def _process_file(file, loader, test_suite) -> None:
    """process tests for a single source file - use only files named test*.py"""
    if file.startswith("test") and file.endswith(".py"):
        modname = "timezone_solar.test." + file[:-3]
        try:
            __import__(modname)
        except unittest.SkipTest:
            return
        module = sys.modules[modname]

        # inspect contents of the newly-loaded module for a generate_tests() method
        mod_name = module.__name__
        for key in sorted(dir(module)):
            key_type = type(module.__dict__[key])
            Flags.verbose_print(f"module {mod_name} key {key} type {key_type}")
            if not isinstance(module.__dict__[key], type):
                continue
            if "generate_tests" in module.__dict__[key].__dict__:
                # call generate_tests() on the newly-loaded module
                cls = module.__dict__[key]
                cls.generate_tests()
                Flags.verbose_print(f"*** generated tests in {key}")

        # let unittest load test functions it finds in the module
        Flags.verbose_print(f"testing in {mod_name}", file=sys.stderr)
        test_suite.addTest(loader.loadTestsFromModule(module))


# wrapper function for main_tests()
def main_tests_per_file(file) -> None:
    """wrapper function for main_tests() so files don't need "import os" dependency"""
    main_tests(os.path.basename(file))


# main test runner
def main_tests(*files) -> None:
    """program main for test directory: run unit tests for timezone_solar"""
    # configure test environment
    if len(files) == 0:
        files = os.listdir(HERE)

    # collect command-line data
    _ingest_argv()

    # generate temporary directory for TAP test result files
    tmpdirname = tempfile.mkdtemp(prefix=TEMP_PREFIX)

    # initialize test runner
    runner = TAPTestRunner()
    runner.set_outdir(tmpdirname)
    runner.set_format("{method_name}: {short_description}")
    loader = unittest.defaultTestLoader
    test_suite = unittest.TestSuite()

    # generate test suite from classes, call generate_tests() in classes which have it
    try:
        for file in sorted(files):
            _process_file(file, loader, test_suite)
    except Exception as exception:
        exception.add_note(f"exception thrown during unit testing in {file}")
        raise exception

    # run the collected test suite from all the modules in the directory
    result = runner.run(test_suite)
    is_ok = result.wasSuccessful()

    # remove TAP result temporary directory except in debug mode - then keep it for inspection
    if not Flags.debug_flag():
        shutil.rmtree(tmpdirname)

    # return standard Unix exitcode 0=success nonzero=error
    print("result: " + ("success" if is_ok else "failed"))
    sys.exit(0 if is_ok else 1)


if __name__ == "__main__":
    # run tests for all the test*.py files in timezone_solar.test
    main_tests()
