# Black Box Testing
The [LongitudeTZ Command Line Interface (CLI) Specification](../docs/cli-spec.md) in common among all the programming language implementations is used for black box testing. It runs the same set of tests on each of the implementations to make sure they perform correctly.

The tests performed are

* Validity tests for both longitude and hour-based time zones
  * at 45-degree intervals
  * at the Date Line at -180, -179.75, +179.75, +180
  * request each field separately and together as a group to compare with valid results
* generation of the tzdata file from scratch, compared with a known good copy

## Per-language Black Box tests

The wrapper for the tests [cli-test.pl](cli-test.pl) is written in Perl because the reference implementation is in Perl, and it fits easily with the "prove" program which collects [Test Anything Protocol (TAP)](https://testanything.org/) results from all the language implementations' outputs. Each of the language-specific tesst scripts runs cli-test.pl with parameters pointing to the program in that language implementation which serves the CLI role and whose results are used to perform black box tests.

* Perl black box tests are launched by [cli-test-perl.t](cli-test-perl.t)
* Python black box tests are launched by [cli-test-python.t](cli-test-python.t)
* C++ black box tests are split by libraries
  * C++ core black box tests are launched by [cli-test-cpp.t](cli-test-cpp.t)
  * C++ BOOST black box tests are launched by [cli-test-cpp-boost.t](cli-test-cpp-boost.t) - symlink to cli-test-cpp.t
