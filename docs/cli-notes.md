# Command-line interface notes

The LongitudeTZ command-line interface defined here must be part of each programming language implementation of the library in order for generalized black box testing to work on all implementations. A secondary purpose is to provide access to all the library's functions from the command line.

The base name "lon-tz" should be followed by a programming-language-specific suffix. The suffixes will generally start with a dot for scripting languages or a dash for compiled languages. For example, it would use *.pl* for Perl, *.py* for Python, *-cpp* for C++ and *-rs* for Rust.