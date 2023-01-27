timezone_solar: The Python implementation of Solar time zones
-------------------------------------------------------------
See the [top-level project info](https://github.com/ikluft/LongitudeTZ) for more on solar time zones.

_timezone_solar_ provides lookup and conversion utilities for Solar time zones, which are based on
the longitude of any location on Earth.

It provides an interface compatible with datetime.tzinfo so that solar time zones based on increments
of either an hour or each degree of longitude may be used in time stamps.
There are 24 hour-based time zones and 360 time zones based on each degree of longitude.

More details TBD

Online resources:
* time zones
  * [PEP 615 – Support for the IANA Time Zone Database in the Standard Library](https://peps.python.org/pep-0615/)
  * [datetime — Basic date and time types](https://docs.python.org/3/library/datetime.html) - including tzinfo interface
  * [Time zone and daylight saving time data](https://data.iana.org/time-zones/tz-link.html) at Internet Assigned Numbers Authority (IANA)
* unit testing
  * [unittest package](https://docs.python.org/3/library/unittest.html) - unit testing via Python standard library
  * [Test Anything Protocol (TAP)](https://testanything.org/) - used for testing Solar Time Zones implementations
  * [tap.py package](https://tappy.readthedocs.io/en/latest/) - TAP implementation in Python, with wrapper for unittest
