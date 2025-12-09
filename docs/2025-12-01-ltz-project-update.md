# LongitudeTZ Project Update: 15-minute narrow time zones

by Ian Kluft
December 1, 2025 (updated December 8, 2025)

The Longitude Time Zones project will be undergoing a major update.

The narrow overlay time zones intended to be hyper-local in scope were originally defined as 1 degree of longitude wide, making each 4 minutes of clock time.
While 1 degree seemed like a mathematically clean definition, it didn't match anything people have in real life.
It has been difficult to try to advocate for that part of the proposal.
That was what caused a re-think of the interval on the narrow overlay time zones.

Actual time zones in effect since 1986 which are not at 1-hour boundaries, all have 30 or 45 minute offsets from the hour. For example, 30-minute time zone offsets are used in South Australia, India, Newfoundland and others. 45-minute time zone offsets are used in Central Australia and Nepal.

Consideration was also given to 5-minute intervals since that would cover other recent history back to 1972. But 15-minute intervals are less to ask of the public, and therefore more likely to be able to successfully advocate for a standard.

With the narrow time zones no longer set at 1 degree intervals of longitude, their names can't use "Lon" as a prefix.
For example, Lon000E would have been equivalent to UTC.
Or fill in the longitude from 180 E to 180 W.

In the interest of simplicity, the new prefix for the narrow time zones is the same "East" or "West" as the hour-based time zones, with 2 additional digits for the minutes of offset: 00, 15, 30 or 45. With 96 in total going from 48 east "East1200" to UTC equivalent "East0000" to 48 west "West1200".

Many changes will be needed:

* Draw a time zone map for the new narrow time zones. (This is not an update because there was no map for 1-degree time zones because there were 360 time zones.)
* Update the code in each programming language implementation to generate the timezone data file.
* Generate the new timezone data file.
* Update the code in each programming language implementation.
* Update the unit tests each programming language implementation.
