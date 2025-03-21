# Why use Solar Time Zones?

The purpose of the LongitudeTZ project is to develop data and libraries to enable any of us to opt out of Daylight Saving Time on devices we own. With time zone definitions that only use Standard Time based on our location's longitude, our devices can automatically convert to/from DST to interoperate with those who still use it.

Everybody where Daylight Savings Time (DST) is in effect wants the clock changes to stop. Standard Time is the natural time at each location's longitude, centered on local solar noon to balance the amount of light between morning and afternoon regardless of the length of the day or time of year.

National or regional governments have been neglecting the wishes of their people by keeping DST in place. We need to make the computer, phone and device configurations available to opt out and just use the natural time for each of our locations' longitudes.

## Info for Potential Volunteers and Participants

To accomplish this goal, the project needs to recruit support for a two-pronged approach to the problem

* generate data for the "tzdata" database, and get it accepted into it
  * this is a key for automatic time conversion with people who still use DST while others advocate for legislation to eliminate DST
* update libraries for multiple platforms and programming languages so that location data (particularly longitude) can be used to determine the local solar time zone for those who opt in