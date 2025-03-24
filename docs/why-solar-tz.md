# Why use Solar Time Zones?

The purpose of the LongitudeTZ project is to develop data and libraries to enable any of us to opt out of Daylight Saving Time on devices we own. With time zone definitions that only use Standard Time based on our location's longitude, our devices can automatically convert to/from DST to interoperate with those who still use it.

## Active resistance to Daylight Saving Time (DST)

Everybody where Daylight Savings Time (DST) is in effect wants the clock changes to stop. Standard Time is the natural time at each location's longitude, centered on local solar noon to balance the amount of light between morning and afternoon regardless of the length of the day or time of year.

National or regional governments have been neglecting the wishes of their people by keeping DST in place. We need to make the computer, phone and device configurations available to opt out and just use the natural time for each of our locations' longitudes.

Think of it this way: Governments which set DST laws call it the official time in their territory, but can only enforce its use on government-owned computers. Your personally-owned computer, phone and other devices can be set to natural Standard Time or Solar Time if you want. The problem has been interacting with other people's devices, emails and calendars. If the Solar Time Zones are added to the worldwide "tzdata" database, then everyone can convert to/from the time zone they use. Inside the computer they're all used as an offset from GMT anyway.

## Info for Potential Volunteers and Participants

To accomplish this goal, the project needs to recruit support for a multiple-pronged approach to the problem

1. generate [data for the "tzdata" database](longitude-timezones.tzfile), and get it accepted into the database.
  * this is a key for automatic time conversion with people who still use DST while others advocate for legislation to eliminate DST
2. update libraries for multiple platforms and programming languages so that location data (particularly longitude) can be used to determine the local solar time zone for those who opt in
3. one or a group of us may write an [Internet Draft for submission to the IETF RFC Editor](https://www.rfc-editor.org/pubprocess/) for publication as an Internet RFC

