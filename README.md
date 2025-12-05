Longitude-based Time Zones
==========================
<img src="docs/dst-opt-out.jpg" align="right" width="50%" />

*Note Dec 1, 2025: the LongitudeTZ project is [overhauling the narrow overlay time zones](docs/2025-12-01-ltz-project-update.md) from 1-degree longitude (4 minutes clock time) to 3.75 degrees longitude (15 minutes clock time). There are no changes to the primary hour-wide time zones.*

See the project web site at [https://ikluft.github.io/LongitudeTZ/](https://ikluft.github.io/LongitudeTZ/)
<br clear="all" />

<a href="docs/world_zone_map.png"><img src="docs/world_zone_map-1200.png" width="100%" title="Natural Time Zones by Longitude" /></a>

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

So far, black box tests have been written and run on the Perl, Python and C++ implementations.

