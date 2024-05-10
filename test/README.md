# Black Box Testing
The [command line interface (CLI) definition](../docs/cli-notes.md) in common among all the programming language implementations is used for black box testing. It runs the same set of tests on each of the implementations to make sure they perform correctly.

The tests performed are

* Validity tests for both longitude and hour-based time zones
  * at 30-degree intervals
  * at the Date Line at -180 and -179.75
* generation of the tzdata file from scratch, compared with a known good copy

The wrapper for the tests is written in Perl because the reference implementation is in Perl, and it fits easily with the "prove" program which collects [Test Anything Protocol (TAP)](https://testanything.org/) results from all the language implementations' outputs.