Natural Time Zones by Longitude
===============================
<a href="https://ikluft.github.io/LongitudeTZ/"><img src="docs/dst-opt-out.jpg" align="right" width="50%" /></a>

See the project web site at [https://ikluft.github.io/LongitudeTZ/](https://ikluft.github.io/LongitudeTZ/)

*Note Dec 1, 2025: the LongitudeTZ project is [overhauling the narrow overlay time zones](docs/2025-12-01-ltz-project-update.md) from 1-degree longitude (4 minutes clock time) to 3.75 degrees longitude (15 minutes clock time). There are no changes to the primary hour-wide time zones.*
<br clear="all" />

Briefly, the project is developing time zone data and updates to software libraries to define natural time zones drawn by lines of longitude. Once added to the TZ database, devices using regional legislated time zones can interoperate with ones using natural time zones. In effect, it allows users to opt-out of Daylight Saving Time and just use the local solar time based on their location.

<a href="docs/world_zone_map.png"><img src="docs/world_zone_map-1200.png" width="100%" title="Natural Time Zones by Longitude" /></a>

The LongitudeTZ project also defines narrower overlay time zones over the same areas which are 15 minutes wide instead of the standard hour. This covers areas which use 15, 30 or 45 minute offsets from the hour in their time zones. Areas with such time zones include Newfoundland Canada, India, Central Australia, Nepal and others.

It also allows users to use more localized solar time at a resolution of 15 minutes clock time. For example, events which need to plan around available daylight can use these narrow time zones with noon at local solar noon, and automatically convert to regional time zones for publication of schedules.

<a href="docs/narrow_zone_map.png"><img src="docs/narrow_zone_map-1200.png" width="100%" title="Natural Time Zones by Longitude: 15 minute zones" /></a>

## <a name="implementations">Implementations</a>

Solar TimeZone libraries implementations in different programming languages:

* [Perl](src/perl/) as _TimeZone::Solar_ module
  * [![Perl](https://github.com/ikluft/LongitudeTZ/actions/workflows/test-perl.yml/badge.svg)](https://github.com/ikluft/LongitudeTZ/actions/workflows/test-perl.yml)
  * available on MetaCPAN: https://metacpan.org/pod/TimeZone::Solar
  * adds solar timezones compatible with DateTime::TimeZone module
* [Python](src/python/) - as _timezone_solar_ package
  * [![Python](https://github.com/ikluft/LongitudeTZ/actions/workflows/test-python.yml/badge.svg)](https://github.com/ikluft/LongitudeTZ/actions/workflows/test-python.yml)
  * available on PyPI: https://pypi.org/project/timezone_solar/
  * adds solar timezones compatible with datetime package
* [C++](src/cpp/) - as _libtzsolar_ package
* Rust - TODO
* others coming, code contributions will be considered

Each programming language implementation must follow the [LongitudeTZ Command Line Interface Specification](cli-spec.md) so that [generalized black box testing](test/) can be performed across all the implementations.

Black box tests have been written and so far run on the Perl, Python and C++ implementations.
