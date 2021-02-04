##
## chrono/timestamps
## =================
##
## If you are going to just parse or format dates. I recommend using just the ``import chrono/timestamps`` module.
## It it imports the Timestamp that is enough for most cases involved with times.
## I always recommend storing dates as a ``float64`` number of seconds since 1970. This is exactly what ``Timestamp`` is.
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
##     echo parseIsoTs("2017-11-08T08:01:43Z")
##     echo Timestamp(1510128103.0).formatIso()
##

import calendars, math

type
  Timestamp* = distinct float64 ## Always seconds since 1970 UTC.

proc `==`*(a, b: Timestamp): bool =
  ## Compare timestamps.
  float64(a) == float64(b)

proc `>`*(a, b: Timestamp): bool =
  ## Compare timestamps.
  float64(a) > float64(b)

proc `<`*(a, b: Timestamp): bool =
  ## Compare timestamps.
  float64(a) < float64(b)

proc `<=`*(a, b: Timestamp): bool =
  ## Compare timestamps.
  float64(a) <= float64(b)

proc `>=`*(a, b: Timestamp): bool =
  ## Compare timestamps.
  float64(a) >= float64(b)

proc `$`*(a: Timestamp): string =
  ## Display a timestamps as a float64.
  $float64(a)

proc sign(a: float64): float64 =
  ## Float point sign, why because javascript ints.
  if a < 0:
    -1
  else:
    +1

proc `div`(a, b: float64): float64 =
  ## Integer division with floats, why because javascript ints.
  floor(abs(a) / abs(b)) * sign(a) * sign(b)

proc calendar*(ts: Timestamp): Calendar =
  ## Converts a Timestamp to a Calendar.
  var tss = float64(ts)

  if float64(ts) < 0:
    # TODO: This works but is kind of a hack to support negative ts.
    tss += 62167132800.0 # Seconds from 0 to 1970.
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
    # TODO: This works but is kind of a hack to support negative ts.
    result.year -= 1970

proc ts*(cal: Calendar): Timestamp =
  ## Converts Calendar to a Timestamp.
  var m = float64(cal.month)
  var y = float64(cal.year)
  if m <= 2:
    y -= 1
    m += 12
  var yearMonthPart = 365 * y + y div 4 - y div 100 +
    y div 400 + 3 * (m + 1) div 5 + 30 * m
  var tss = (yearMonthPart + cal.day.float64 - 719561) * 86400 +
    3600 * cal.hour.float64 + 60 * cal.minute.float64 + cal.second.float64
  return Timestamp(float64(tss) + cal.secondFraction - cal.tzOffset)

proc calendar*(ts: Timestamp, tzOffset: float64): Calendar =
  ## Converts a Timestamp to a Calendar with a tz offset.
  ## Does not deal with DST.
  var tsTz = float64(ts) + tzOffset
  result = Timestamp(tsTz).calendar
  result.tzOffset = tzOffset

proc formatIso*(ts: Timestamp): string =
  ## Fastest way to convert Timestamp to an ISO 8601 string representation.
  ## Use this instead of the format function when dealing with ISO format.
  return ts.calendar.formatIso

proc formatIso*(ts: Timestamp, tzOffset: float64): string =
  ## Fastest way to convert Timestamp to an ISO 8601 string representation.
  ## Use this instead of the format function when dealing with ISO format.
  return ts.calendar(tzOffset).formatIso

proc parseIsoTs*(iso: string): Timestamp =
  ## Fastest way to convert an ISO 8601 string representation to a Timestamp.
  ## Use this instead of the parseTimestamp function when dealing with ISO
  ## format.
  return parseIsoCalendar(iso).ts

proc parseTs*(fmt: string, value: string): Timestamp =
  ## Parse time using the Chrono format string into a Timestamp.
  parseCalendar(fmt, value).ts

proc format*(ts: Timestamp, fmt: string): string =
  ## Format a Timestamp using the format string.
  ts.calendar.format(fmt)

proc toStartOf*(ts: Timestamp, timeScale: TimeScale): Timestamp =
  ## Move the time stamp to a start of a time scale.
  var cal = ts.calendar
  cal.toStartOf(timeScale)
  return cal.ts

proc toEndOf*(ts: Timestamp, timeScale: TimeScale): Timestamp =
  ## Move the time stamp to an end of a time scale.
  var cal = ts.calendar
  cal.toEndOf(timeScale)
  return cal.ts

proc add*(ts: Timestamp, timeScale: TimeScale, number: int): Timestamp =
  ## Add Seconds, Minutes, Hours, Days ... to Timestamp.
  var cal = ts.calendar
  cal.add(timeScale, number)
  return cal.ts

proc sub*(ts: Timestamp, timeScale: TimeScale, number: int): Timestamp =
  ## Subtract Seconds, Minutes, Hours, Days ... to Timestamp.
  var cal = ts.calendar
  cal.sub(timeScale, number)
  return cal.ts
