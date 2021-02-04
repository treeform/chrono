##
## chrono/timezones
## ================
##
## Timezones can be complicated.
## But if you treat them as a presentation level issue sort of like language it becomes easier.
## Never store anything as non-UTC.
## If you need to store timezone info store it as a `string` plus a `Timestamp`.
## When you need to display or parse it use the tzName attribute.
##
## .. code-block:: nim
##     var ts = parseTs(
##         "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
##        "1988-02-09T03:34:12Z",
##         tzName = "America/Los_Angeles"
##     )
##
##     echo ts
##
##     echo formatTs(
##         ts,
##         "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
##         tzName = "America/Los_Angeles"
##     )
##
## Timezone and daylight savings can and do change unpredictably remember to keep this library up to date.
##
## When you import the library it also statically includes compressed daylight savings table in the binary which is about 0.7MB.
## It does not use OS's timezone functions.
## This way, you are always guaranteed to get the same result on all platforms.
##
## Many confuse proper time zone names like **"America/Los_Angeles"** with 3-4 letter time zone abbreviations like **"PST"** or **"PDT"**.
## Time zone abbreviations cannot describe a time zone fully, unless you know what country you are in and its a common one.
## It is always recommended to use full timezone names for parsing and storage and only display time zone abbreviations and never parse them.
##

import algorithm, calendars, json, timestamps

type
  DstChange* = object
    ## Day Light Savings time transition
    tzId*: int16
    name*: string
    start*: float64
    offset*: int32

  TimeZone* = object
    ## Time Zone information
    id*: int16
    name*: string

var tzs*: seq[TimeZone] ## List of all timezones
var dstChanges*: seq[DstChange] ## List of all DST changes

proc binarySearch[T, K](a: openArray[T], key: K, keyProc: proc (e: T): K): int =
  ## binary search for `element` in `a`. Using a `keyProc` returns an Index or -1
  var b = len(a)
  var index = 0
  while index < b:
    var mid = (index + b) div 2
    if cmp(keyProc(a[mid]), key) < 0:
      index = mid + 1
    else:
      b = mid
  if index >= len(a) or keyProc(a[index]) != key:
    return -1
  return index

proc binarySearchValue[T, K](a: openArray[T], key: K, keyProc: proc (e: T): K): T =
  ## binary search for `element` in `a`. Using a `keyProc`, returns default or a found value
  var index = binarySearch(a, key, keyProc)
  if index >= 0:
    result = a[index]

proc findTimeZone*(tzName: string): TimeZone =
  ## Finds timezone by its name
  proc getName(tz: TimeZone): string = $tz.name
  return tzs.binarySearchValue(tzName, getName)

proc findTimeZone*(tzId: int): TimeZone =
  ## Finds timezone by its id (slow).
  for tz in tzs:
    if tz.id == tzId:
      return tz

proc valid*(tz: TimeZone): bool =
  ## Returns true if timezone is valid
  return tz.id > 0

iterator findDstChanges*(tz: TimeZone): DstChange =
  ## Finds timezone dst changes by timezone.
  proc getTzId(dst: DstChange): int16 = dst.tzId
  var index = dstChanges.binarySearch(tz.id, getTzId)
  if index != -1:
    while index < dstChanges.len and dstChanges[index].tzId == tz.id:
      yield dstChanges[index]
      inc index

iterator findTimeZoneFromDstName*(dstName: string): TimeZone =
  ## Finds timezones by its dst name (slow).
  var lastTzId = -1
  for dst in dstChanges:
    if dst.name == dstName:
      if lastTzId != dst.tzId:
        lastTzId = dst.tzId
        yield findTimeZone(dst.tzId)

proc clearTimezone*(cal: var Calendar) =
  ## Removes timezone form calendar
  cal.sub(Second, int(cal.tzOffset))
  cal.tzOffset = 0
  cal.tzName = ""
  cal.dstName = ""

proc applyTimezone*(cal: var Calendar, tzName: string) =
  ## take a calendar and apply a timezone to it
  ## this does *not changes* timestamp of the calendar
  ## but does *change* the hour:minute
  if tzName == "UTC":
    cal.clearTimezone()
    return
  var prevChange: DstChange
  var tz = findTimeZone(tzName)
  var ts = cal.ts
  if tz.valid:
    var first = true
    for change in findDstChanges(tz):
      if first:
        prevChange = change
        first = false
      if Timestamp(change.start) > ts:
        break
      prevChange = change
    var tzOffset = float64(prevChange.offset)
    cal.sub(Second, int(cal.tzOffset))
    cal.tzOffset = tzOffset
    cal.add(Second, prevChange.offset)
    cal.tzName = $tz.name
    cal.dstName = $prevChange.name

proc shiftTimezone*(cal: var Calendar, tzName: string) =
  ## take a calendar and moves it into a timezone
  ## this does *changes* timestamp of the calendar
  ## but does *not change* the hour:minute
  if tzName == "UTC":
    cal.tzOffset = 0
    cal.tzName = ""
    cal.dstName = ""
    return
  var prevChange: DstChange
  var tz = findTimeZone(tzName)
  var ts = cal.ts
  if tz.valid:
    var first = true
    for change in findDstChanges(tz):
      if first:
        prevChange = change
        first = false
      if Timestamp(change.start) > ts:
        break
      prevChange = change
    var tzOffset = float64(prevChange.offset)
    cal.tzOffset = tzOffset
    cal.tzName = $tz.name
    cal.dstName = $prevChange.name
    cal.normalize()

proc normalizeTimezone*(cal: var Calendar) =
  ## After shifting around the calendar, its DST might need to be updated.
  if cal.tzName.len != 0:
    cal.applyTimezone(cal.tzName)

proc calendar*(ts: Timestamp, tzName: string): Calendar =
  ## Convert Timestamp to calendar with a timezone.
  var cal = ts.calendar
  cal.applyTimezone(tzName)
  return cal

proc formatIso*(ts: Timestamp, tzName: string): string =
  ## Fastest way to convert Timestamp to an ISO 8601 string representation.
  ## Use this instead of the format function when dealing with ISO format.
  var cal = ts.calendar
  cal.applyTimezone(tzName)
  return cal.formatIso()

proc parseTs*(fmt: string, value: string, tzName: string): Timestamp =
  ## Parse time using the Chrono format string with timezone nto a Timestamp.
  var cal = parseCalendar(fmt, value)
  cal.applyTimezone(tzName)
  return cal.ts

proc format*(ts: Timestamp, fmt: string, tzName: string): string =
  ## Format a Timestamp with timezone using the format string.
  var cal = ts.calendar
  cal.applyTimezone(tzName)
  return cal.format(fmt)

proc loadTzData*(tzData: string) =
  ## Loads timezone information from tzdata.json file contents.
  ## To statically include time zones in your program:
  ## ```
  ##   loadTzData(staticRead("your-path/tzdata.json"))
  ## ```
  let tzData = parseJson(tzData)
  tzs = tzData["timezones"].to(seq[TimeZone])
  dstChanges = tzData["dstChanges"].to(seq[DstChange])
