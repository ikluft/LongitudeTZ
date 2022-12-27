"""run unit tests for timezone_solar"""
import os
import sys
from subprocess import Popen,PIPE
import unittest
from tap import TAPTestRunner

# constants
here = os.path.dirname(__file__)
orig_stdout = sys.stdout

def start_tapview() -> Popen:
    """start pipe to tapview program for abbreviated test results report"""
    pipe_proc = None
    try:
        # pylint: disable=consider-using-with
        pipe_proc = Popen(here + "/tapview", stdin = PIPE, \
            shell = False, text = True )
        sys.stdout = pipe_proc.stdin
    except Exception as exception:
        exception.add_note("failed to redirect stdout to pipe for report")
        raise exception
    return pipe_proc

def close_tapview(pipe_proc) -> None:
    """close tapview pipe and wait for child process to finish"""
    pipe_proc.stdin.close()
    sys.stdout = orig_stdout
    retcode = pipe_proc.wait()
    if retcode != 0:
        raise Exception(f"tapview returned non-zero return code: {retcode}")

def process_file(file, loader, test_suite) -> None:
    """process tests for a single source file - use only files named test*.py"""
    if file.startswith("test") and file.endswith(".py"):
        modname = "timezone_solar.test." + file[:-3]
        try:
            __import__(modname)
        except unittest.SkipTest:
            return
        module = sys.modules[modname]

        # inspect contents of the newly-loaded module for a generate_tests() method
        #mod_name = module.__name__
        for key in dir(module):
            #key_type = type(module.__dict__[key])
            #print( f"module {mod_name} key {key} type {key_type}")
            if not isinstance(module.__dict__[key], type):
                continue
            if "generate_tests" in module.__dict__[key].__dict__:
                # call generate_tests() on the newly-loaded module
                cls = module.__dict__[key]
                cls.generate_tests()
                #print( f"*** generated tests in {key}")

        # let unittest load test functions it finds in the module
        #print(f"testing in {mod_name}", file=sys.stderr)
        test_suite.addTest(loader.loadTestsFromModule(module))

# main test runner
def main_tests(*files) -> None:
    """program main for test directory: run unit tests for timezone_solar"""
    # configure test environment
    if len(files) == 0:
        files = os.listdir(here)

    # collect command-line data
    # The only CLI argument is --tapview. For now, hard-code that. Use a library if more are added.
    tapview_mode = False
    if len(sys.argv) > 1 and sys.argv[1] == "--tapview":
        tapview_mode = True

    # if tapview mode is in effect, start a new pipe for each TAP test runner
    pipe_proc = None
    if tapview_mode:
        pipe_proc = start_tapview()

    # initialize test runner
    runner = TAPTestRunner()
    runner.set_stream(True)
    runner.set_format("{method_name}: {short_description}")
    runner.set_combined(True)
    loader = unittest.defaultTestLoader
    test_suite = unittest.TestSuite()

    # generate test suite from classes, call generate_tests() in classes which have it
    success = True
    try:
        for file in files:
            if not process_file(file, loader, test_suite):
                success = False
    except Exception as exception:
        exception.add_note(f"exception thrown during unit testing in {file}")
        raise exception


    # run the collected test suite from all the modules in the directory
    result = runner.run(test_suite)
    success = success and result.wasSuccessful()
    sys.stdout.flush()

    # close taptest pipe
    if pipe_proc is not None:
        close_tapview(pipe_proc)

    # exit with standard Unix exitcode 0=success nonzero=fail
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    # run tests for all the test*.py files in timezone_solar.test
    main_tests()
