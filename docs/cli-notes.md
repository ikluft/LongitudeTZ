# Command-line interface notes

The LongitudeTZ command-line interface defined here must be part of each programming language implementation of the library in order for generalized black box testing to work on all implementations. A secondary purpose is to provide access to all the library's functions from the command line.

The base name "lon-tz" should be followed by a programming-language-specific suffix. The suffixes will generally start with a dot for scripting languages or a dash for compiled languages. For example, it would use *.pl* for Perl, *.py* for Python, *-cpp* for C++ and *-rs* for Rust. In the following specification, the command will be referred to simply as "lon-tz" without a language suffix.

## Command-line options specification

Command-line options listed below must be implemented by all language implementations. They are not complete until this is met.

### --version

    lon-tz --version

prints the program version.

Processing ends as soon as this is parsed. That makes this mutually exclusive of all other options, ignoring any other options provided.

A shorthand alias '-v' may be used for '--version'.

### --tzfile

    lon-tz --tzfile

generates a timezone database file (see the tzfile(5) Unix manual page for the format) of the LongitudeTZ time zones. The text must be sent to the program's standard output.

This option causes all other options to be ignored, except --version which is higher precedence.
