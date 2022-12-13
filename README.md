# Longitude-based Time Zones
Many people are tired of changing their clocks twice a year for daylight time. DST is an antiquated tradition [which we now know doesn't do any good](https://www.webmd.com/sleep-disorders/news/20211105/harmful-effects-of-daylight-savings). Anyone can look up sunrise and sunset times for events that need to be scheduled around daylight.

The only way we'll have the choice to opt-out of Daylight Saving Time is if there's an alternative standard allowing us to stay on Standard Time. This is intended to make such an alternative. I'm running the idea up the flagpole. We'll see how many salutes it gets. Meanwhile I'm writing code in various programming languages toward enabling the possibility.

National and regional governments continue to cling to daylight saving time partly because almost everyone else has such a standard. In this age where our computers and cell phones are integral to scheduling, we really only need a de-facto standard. _It is possible to just stop using DST_, and let our computers convert the times to and from others who continue to use DST. Fortunately, there are standards we can build upon.
* Lines of longitude are a well-established standard.
* Ships at sea use "nautical time" based on time zones 15 degrees of longitude wide.
* Time zones (without daylight saving offsets) are based on average solar noon at the Prime Meridian. Standard Time in each time zone lines up with average solar noon on the meridian at the center of each time zone, at 15-degree of longitude increments.

15 degrees of longitude appears more than once above. That isn't a coincidence. It's derived from 360 degrees of rotation in a day, divided by 24 hours in a day. The result is 15 degrees of longitude representing 1 hour in Earth's rotation. That makes each time zone one hour wide. So we'll use that too.

With those items as its basis, this project is to establish "Solar Time Zone" data for use with the Internet Assigned Numbers Authority's [TZ database](https://www.iana.org/time-zones), and eventually submit it for inclusion in the database and a paper with the definition, perhaps as an Internet RFC.

The project also makes and accepts contributions of code in various programming languages for anything necessary to implement this standard. That includes computing a Solar Time Zone from a latitude/longitude coordinates. Once part of the TZ Database, computers and phones which use it will be able to automatically convert times to and from the Solar Time Zones.

The project also makes another set of overlay time zones the width of 1 degree of longitude, which puts them in 4-minute intervals of time. These are a hyper-local niche for potential use by outdoor events. These may be used by those who would like to have the middle of the scheduling day coincide with local solar noon. 

## Implementations
Solar TimeZone libraries implementations in different programming languages:
* [Perl](src/perl/) as _TimeZone::Solar_ module
  * [![Perl](https://github.com/ikluft/LongitudeTZ/actions/workflows/test-perl.yml/badge.svg)](https://github.com/ikluft/LongitudeTZ/actions/workflows/test-perl.yml)
  * available on MetaCPAN: https://metacpan.org/pod/TimeZone::Solar
* [Python](src/python/) - as _timezone_solar_ package
* Rust - TODO
* others coming, code contributions accepted

## The Solar Time Zones Definition
The Solar time zones definition includes the following rules.
* There are 24 hour-based Solar Time Zones, named West12, West11, West10, West09 through East12. East00 is equivalent to UTC. West00 is an alias for East00.
  * Hour-based time zones are spaced in one-hour time increments, or 15 degrees of longitude.
  * Each hour-based time zone is centered on a meridian at a multiple of 15 degrees. In positive and negative integers, these are 0, 15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165 and 180.
  * Each hour-based time zone spans the area ±7.5 degrees of longitude either side of its meridian.
* There are 360 longitude-based Solar Time Zones, named Lon180W for 180 degrees West through Lon180E for 180 degrees East. Lon000E is equivalent to UTC. Lon000W is an alias for Lon000E.
  * Longitude-based time zones are spaced in 4-minute time increments, or 1 degree of longitude.
  * Each longitude-based time zone is centered on the meridian of an integer degree of longitude.
  * Each longitude-based time zone spans the area ±0.5 degrees of longitude either side of its meridian.
* In both hourly and longitude-based time zones, there is a limit to their usefulness at the poles. Beyond 80 degrees north or south, the definition uses UTC (East00 or Lon000E). This boundary is the only reason to include latitude in the computation of the time zone.
* When converting coordinates to a time zone, each time zone includes its boundary meridian at the lower end of its absolute value, which is in the direction toward 0 (UTC). The exception is at exactly ±180.0 degrees, which would be excluded from both sides by this rule. That case is arbitrarily set as +180 just to pick one.
* The category "Solar" is used for the longer names for these time zones. The names listed above are the short names. The full long name of each time zone is prefixed with "Solar/" such as "Solar/East00" or "Solar/Lon000E".
