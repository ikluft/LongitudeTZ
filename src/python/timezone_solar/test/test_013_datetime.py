#!/usr/bin/env python
"""unit tests of timezone_solar package integration with datetime.tzinfo system library"""

import unittest
from datetime import tzinfo
from timezone_solar import TimeZoneSolar

class TestDateTime(unittest.TestCase):
    """unit tests of timezone_solar package integration with datetime.tzinfo system library"""

    @classmethod
    def generate_tests(cls):
        testnum = 0
        # TODO generate tests here


if __name__ == "__main__":
    from timezone_solar.test.run_tests import main_tests_per_file

    main_tests_per_file(__file__)
