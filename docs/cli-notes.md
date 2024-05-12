# Command-line interface notes

The LongitudeTZ command-line interface defined here must be part of each programming language implementation of the library in order for [generalized black box testing](../test/) to work on all implementations. A secondary purpose is to provide access to all the library's functions from the command line.

The base name "lon-tz" should be followed by a programming-language-specific suffix. The suffixes will generally start with a dot for scripting languages or a dash for compiled languages. For example, it would use *.pl* for Perl, *.py* for Python, *-cpp* for C++ and *-rs* for Rust. In the following specification, the command will be referred to simply as "lon-tz" without a language suffix.

## Command-line options specification

Command-line options listed below must be implemented by all language implementations. They are not complete until this is met.

### --version

    lon-tz --version

prints the program version, the programming language of the implementation, and the version of the language interpreter or compiler.

Processing ends as soon as this is parsed. That makes this mutually exclusive of all other options, ignoring any other options provided.

A shorthand alias '-v' may be used for '--version'.

### --tzfile

    lon-tz --tzfile

generates a timezone database file (see the tzfile(5) Unix manual page for the format) of the LongitudeTZ time zones. The text must be sent to the program's standard output.

This option causes all other options to be ignored, except --version which is higher precedence.

### --tzname

    lon-tz --tzname=Westxx
    lon-tz --tzname=Eastxx
    lon-tz --tzname=LonxxxW
    lon-tz --tzname=LonxxxE

sets the time zone by name. West00 to West12 are 1-hour wide time zones in west longitude. East00 to East12 are 1-hour wide time zones in east longitude. Lon000W to Lon180W are 1-degree wide time zones in west longitude. Lon000E to Lon180E are 1-degree wide time zones in east longitude.

There are some peculiarities. West00 is an alias for and equal to East00. Likewise, Lon000W is and alias for and equal to Lon000E. On the other extreme, the Date Line at 180 degrees longitude makes for half-wide time zones either side of it. For hour-based time zones, East12 and West12 are half-hour wide time zones. For degree-based time zones, Lon180E and Lon180W are half-degree-wide time zones.

### --longitude

    lon-tz --longitude=xxx.xxx

sets the time zone from the longitude provided in the parameter. For example, a longitude setting of -122 (122 degrees west longitude) would correspond to San Francisco, Portland or Seattle.

This option is mutually exclusive with the --tzname option.

### --latitude

    lon-tz --longitude=xxx.xxx --latitude=yy.yyy

sets the latitude from the parameter, which may be used to override the time zone in polar regions.
Outside of polar regions (beyond 80 degrees north or south latitude), it has no effect.
The latitude is optional. If provided and set to a value in the polar region, it will override the time zone to UTC
as East00 in hour-based time zones or Lon000E in degree-based time zones.

### --type

    lon-tz --longitude=xxx.xxx --type=hour
    lon-tz --longitude=xxx.xxx --type=longitude

optionally sets the type of time zone to longitude or hour. The default is hour-wide time zones. --longitude may be abbreviated --lon.

With --type=hour, 24 hour-based time zones are East00 to East12 and West00 to West12.

With --type=longitude, 360 longitude-based time zones are Lon000E to Lon180E and Lon000W to Lon180W.

### --get

    lon-tz --longitude=xxx.xxx --get=fieldname

determines a field of data to output from the specified time zone.

The --get parameter may be combined with other time zone parameters in order to extract data from any of those settings. It is allowed to be specified more than once and, if so, prints each requested field on a separate line on the program's output.

The allowed field names are

* longitude: report the longitude parameter which was used to make the time zone, or the centerline of the time zone if it was created by name
* latitude: return the latitude parameter which was used to make the time zone, or blank if none was provided
* name: full time zone name including the prefix. For example: Solar/West08
* short_name: short time zone name, without the prefix. For example: West08
* long_name: same as "name" field
* offset: offset from UTC in ±hh:mm (+/- hours minutes) string format
* offset_min: offset from UTC in integer minutes
* offset_sec: offset from UTC in integer seconds (for compatibility only - no Solar time zones use resolution smaller than minutes)
* is_utc: 1 (true) if the time zone is equal to UTC, 0 (false) otherwise

