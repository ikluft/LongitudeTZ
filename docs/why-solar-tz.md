# Why use Solar Time Zones?

The purpose of the LongitudeTZ project is to develop data and libraries to enable any of us to opt out of Daylight Saving Time on devices we own. With time zone definitions that exclude DST, our devices can also automatically convert to/from DST to interoperate with those who still use it.

To accomplish this goal, the project needs to recruit support for a two-pronged approach to the problem

* generate data for the "tzdata" database, and get it accepted into it
  * this is a key for automatic time conversion with people who still use DST while others advocate for legislation to eliminate DST
* update libraries for multiple platforms and programming languages so that location data (particularly longitude) can be used to determine the local solar time zone for those who opt in