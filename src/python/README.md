Project description
===================

timezone_solar is the Python implementation of Solar time zones.
See the [top-level project info](https://github.com/ikluft/LongitudeTZ) for more on solar time zones.

_timezone_solar_ provides lookup and conversion utilities for Solar time zones, which are based on
the longitude of any location on Earth.

The solar time zones are intended as an alternative to Daylight Saving Time.
Instead of haphazard regulations in each country and region of the world, this uses meridians of longitude to set
time zone boundaries, just like ships at sea use every day.
For those who want an alternative to Daylight Saving Time, we have to build that alternative.

It provides an interface compatible with datetime.tzinfo so that solar time zones based on increments
of either an hour or each degree of longitude may be used in time stamps.
There are 24 hour-based time zones and 360 time zones based on each degree of longitude.

Overview of Solar time zones
----------------------------

Solar time zones are based on the longitude of a location. Each time zone is defined around having local solar noon, on average, the same as noon on the clock.

Solar time zones are always in Standard Time. There are no Daylight Time changes, by definition. The main point is to have a way to opt out of Daylight Saving Time by using solar time.

The Solar time zones build upon existing standards.
* Lines of longitude are a well-established standard.
* Ships at sea use "nautical time" based on time zones 15 degrees of longitude wide.
* Time zones (without daylight saving offsets) are based on average solar noon at the Prime Meridian. Standard Time in each time zone lines up with average solar noon on the meridian at the center of each time zone, at 15-degree of longitude increments.

15 degrees of longitude appears more than once above. That isn't a coincidence. It's derived from 360 degrees of rotation in a day, divided by 24 hours in a day. The result is 15 degrees of longitude representing 1 hour in Earth's rotation. That makes each time zone one hour wide. So Solar time zones use that too.

The Solar Time Zones proposal is intended as a potential de-facto standard which people can use in their local areas, providing for routine computational time conversion to and from local standard or daylight time. In order for the proposal to become a de-facto standard, made in force by the number of people using it, it starts with technical early adopters choosing to use it. At some point it would actually become an official alternative via publication of an Internet RFC and adding the new time zones into the Internet Assigned Numbers Authority (IANA) Time Zone Database files. The Time Zone Database feeds the time zone conversions used by computers including servers, desktops, phones and embedded devices.

There are normal variations of a matter of minutes between local solar noon and clock noon, depending on the latitude and time of year. That variation is always the same number of minutes as local solar noon differs from noon UTC at the same latitude on the Prime Meridian (0° longitude), due to seasonal effects of the tilt in Earth's axis relative to our orbit around the Sun.

The Solaer time zones also have another set of overlay time zones the width of 1 degree of longitude, which puts them in 4-minute intervals of time. These are a hyper-local niche for potential use by outdoor events or activities which must be scheduled around daylight. They can also be used by anyone who wants the middle of the scheduling day to coincide closely with local solar noon.

Online resources
----------------

* time zones
  * [PEP 615 – Support for the IANA Time Zone Database in the Standard Library](https://peps.python.org/pep-0615/)
  * [datetime — Basic date and time types](https://docs.python.org/3/library/datetime.html) - including tzinfo interface
  * [Time zone and daylight saving time data](https://data.iana.org/time-zones/tz-link.html) at Internet Assigned Numbers Authority (IANA)
* unit testing
  * [unittest package](https://docs.python.org/3/library/unittest.html) - unit testing via Python standard library
  * [Test Anything Protocol (TAP)](https://testanything.org/) - used for testing Solar Time Zones implementations
  * [tap.py package](https://tappy.readthedocs.io/en/latest/) - TAP implementation in Python, with wrapper for unittest
