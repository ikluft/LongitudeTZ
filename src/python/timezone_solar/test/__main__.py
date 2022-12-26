"""run unit tests for timezone_solar"""
import os
import sys
import subprocess
import unittest
from tap import TAPTestRunner

# configure test environment
here = os.path.dirname(__file__)
loader = unittest.defaultTestLoader

# collect command-line data
# The only CLI argument is --tapview. For now, hard-code that. Use a library if more are added.
pipe_proc = None
if len(sys.argv) > 1 and sys.argv[1] == "--tapview":
    try:
        # pylint: disable=consider-using-with
        pipe_proc = subprocess.Popen(here + "/tapview", stdin = subprocess.PIPE, shell = False, \
            text = True )
        sys.stdout = pipe_proc.stdin
    except Exception as e:
        e.add_note("failed to redirect stdout to pipe for report")
        raise e

# generate test suite from classes, call generate_tests() in classes which have it
success = True
try:
    for func in os.listdir(here):
        # process source files that start with "test"
        if func.startswith("test") and func.endswith(".py"):
            modname = "timezone_solar.test." + func[:-3]
            try:
                __import__(modname)
            except unittest.SkipTest:
                continue
            module = sys.modules[modname]

            # inspect contents of the newly-loaded module for a generate_tests() method
            for key in dir(module):
                mod_name = module.__name__
                key_type = type(module.__dict__[key])
                #print( f"module {mod_name} key {key} type {key_type}")
                if not isinstance(module.__dict__[key], type):
                    continue
                if "generate_tests" in module.__dict__[key].__dict__:
                    # call generate_tests() on the newly-loaded module
                    cls = module.__dict__[key]
                    cls.generate_tests()
                    #print( f"*** generated tests in {key}")

            # let unittest load test functions it finds in the module
            test_suite = unittest.TestSuite()
            test_suite.addTest(loader.loadTestsFromModule(module))

            # run the collected test suite from all the modules in the directory
            runner = TAPTestRunner()
            runner.set_stream(True)
            runner.set_format("{method_name}: {short_description}")
            result = runner.run(test_suite)
            success = success and result.wasSuccessful()
except Exception as e:
    success = False
    e.add_note("failed to redirect stdout to pipe for report")
    raise e

if pipe_proc is not None:
    pipe_proc.stdin.close()
    pipe_proc.wait()
sys.exit(0 if success else 1)
