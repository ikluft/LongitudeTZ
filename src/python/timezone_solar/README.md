timezone_solar: The Python implementation of Solar time zones
-------------------------------------------------------------

Source files:
* __init__.py - initialization for sources in timezone_solar module directory, loads the module
* timezone_solar.py - core of the timezone_solar module
* tzsconst.py - constants used by the timezone_solar module and its unit tests
* test (directory) - containts unit tests
  * __main__.py - allows running all the tests by running the test module/directory as a Python script
  * test_010_tzsconst.py - unit tests for constants in tzsconst
  * test_011_basic.py - basic unit tests of timezone_solar time zones for each longitude or hourly zone
  * test_012_latitude.py - unit tests of timezone_solar time zones, verify use of UTC at polar laitudes
  * test_013_datetime.py - unit tests of timezone_solar time zones integration with Python datetime/tzinfo
  * utils.py - time zone computation functions used by multiple test scripts
