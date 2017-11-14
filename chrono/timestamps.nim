##
## chrono/timestamps
## =================
##
## If you are going to just parse or format dates. I recommend using just the ``include chrono/timestamps`` module.
## It it includes the Timestamp that is enough for most cases involved with times.
## I always recommend storing dates as a ``float64`` number of seconds sence 1970. This is exactly what ``Timestamp`` is.
## When you need to parse it or display it use ``parseTs`` or ``formatTs``.
##
## .. code-block:: nim
##     var ts = parseTs(
##       "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
##       "1988-02-09T03:34:12Z"
##     )
##
## echo ts
##
## .. code-block:: nim
##     echo formatTs(
##       ts,
##       "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
##     )
##
##
## If you need to parse ISO dates which is a very common format you find all over the internet. You can even use faster optimized versions here:
##
## .. code-block:: nim
##     echo isoToTs("2017-11-08T08:01:43Z")
##     echo tsToIso(Timestamp(1510128103.0))
##

import strutils
import calendars

type
  Timestamp* = distinct float64 ## Always seconds since 1970 UTC

proc `==`*(a, b: Timestamp): bool =
  ## Compare timestamps
  float64(a) == float64(b)

proc `>`*(a, b: Timestamp): bool =
  ## Compare timestamps
  float64(a) > float64(b)

proc `<`*(a, b: Timestamp): bool =
  ## Compare timestamps
  float64(a) < float64(b)

proc `<=`*(a, b: Timestamp): bool =
  ## Compare timestamps
  float64(a) <= float64(b)

proc `>=`*(a, b: Timestamp): bool =
  ## Compare timestamps
  float64(a) >= float64(b)

proc `$`*(a: Timestamp): string =
  ## Display a timestamps as a float64
  $float64(a)


proc tsToCalendar*(ts: Timestamp): Calendar =
  ## Converts a Timestamp to a Calendar
  var tss: int64 = int(ts)

  if float64(ts) < 0:
    # TODO this works but is kind of a hack to support negative ts
    tss += 62167132800 # seconds from 0 to 1970
    if tss < 0:
      return

  result.secondFraction = float64(ts) - float64(tss)
  var s = tss mod 86400
  tss = tss div 86400
  var h = s div 3600
  var m = s div 60 mod 60
  s = s mod 60
  var
    x = (tss * 4 + 102032) div 146097 + 15
    b = tss + 2442113 + x - (x div 4)
    c = (b * 20 - 2442) div 7305
    d = b - 365 * c - c div 4
    e = d * 1000 div 30601
    f = d - e * 30 - e * 601 div 1000
  result.second = int s
  result.minute = int m
  result.hour = int h
  result.day = int f
  if e < 14:
    result.month = int e - 1
    result.year = int c - 4716
  else:
    result.month = int e - 13
    result.year = int c - 4715

  if float64(ts) < 0:
    # TODO this works but is kind of a hack to support negative ts
    result.year -= 1970


proc calendarToTs*(cal: Calendar): Timestamp =
  ## Converts Calendar to a Timestamp

  var m = cal.month
  var y = cal.year
  if m <= 2:
     y -= 1
     m += 12
  var yearMonthPart = 365 * y + y div 4 - y div 100 + y div 400 + 3 * (m + 1) div 5 + 30 * m
  var tss = (yearMonthPart + cal.day - 719561) * 86400 + 3600 * cal.hour + 60 * cal.minute + cal.second
  return Timestamp(float64(tss) + cal.secondFraction - cal.tzOffset)


proc tsToCalendar*(ts: Timestamp, tzOffset: float64): Calendar =
  ## Converts a Timestamp to a Calendar with a tz offset. Does not deal with DST.

  var tsTz = float64(ts) + tzOffset
  result = tsToCalendar(Timestamp(tsTz))
  result.tzOffset = tzOffset


proc tsToIso*(ts: Timestamp): string =
  ## Fastest way to convert Timestamp to an ISO 8601 string representaion
  ## Use this instead of the format function when dealing whith ISO format
  return calendarToIso(tsToCalendar(ts))


proc tsToIso*(ts: Timestamp, tzOffset: float64): string =
  ## Fastest way to convert Timestamp to an ISO 8601 string representaion
  ## Use this instead of the format function when dealing whith ISO format
  return calendarToIso(tsToCalendar(ts, tzOffset))


proc isoToTs*(iso: string): Timestamp =
  ## Fastest way to convert an ISO 8601 string representaion to a Timestamp.
  ## Use this instead of the parseTimestamp function when dealing whith ISO format
  return calendarToTs(isoToCalendar(iso))


proc parseTs*(fmt: string, value: string): Timestamp =
  ## Parse time using the Chrono format string into a Timestamp.
  parseCalendar(fmt, value).calendarToTs()


proc formatTs*(ts: Timestamp, fmt: string): string =
  ## Format a Timestamp using the format string.
  tsToCalendar(ts).formatCalendar(fmt)
