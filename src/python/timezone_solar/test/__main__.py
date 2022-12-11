"""run unit tests for timezone_solar"""
import os
import sys
import unittest
from pycotap import TAPTestRunner

here = os.path.dirname(__file__)
loader = unittest.defaultTestLoader

# generate test suite from classes, call generate_tests() in classes which have it
test_suite = unittest.TestSuite()
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
        test_suite.addTest(loader.loadTestsFromModule(module))

# run the collected test suite from all the modules in the directory
TAPTestRunner().run(test_suite)
