##
## **Chrono a Timestamps, Calendars, and Timezones library for nim.**
##
## Parse timestamps:
##
## .. code-block:: nim
##     var ts = parseTs(
##       "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
##       "1988-02-09T03:34:12Z"
##     )
##
## Format timestamps:
##
## .. code-block:: nim
##     echo formatTs(
##       ts,
##       "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
##     )
##
## Manipulate Calendars:
##
## .. code-block:: nim
##     var cal = Calendar(year: 2013, month: 12, day: 31, hour: 59, minute: 59, second: 59)
##     cal.addSeconds(20)
##     cal.subMinutes(15)
##     cal.addDays(40)
##     cal.subMonths(120)
##
## Use timezones:
##
## .. code-block:: nim
##     echo formatTs(
##         ts,
##         "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
##         tzName = "America/Los_Angeles"
##     )
##

include chrono/calendars
include chrono/timestamps
include chrono/timezones
