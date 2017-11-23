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
## When you import the library it also statically includes the daylight savings table in the binary which is about 6MB.
## It does not use OS's timezone functions.
## You are always guaranteed to game the same result on all platforms.
##
## Many confuse proper time zone names like **"America/Los_Angeles"** with 3-4 letter time zone abbreviations like **"PST"** or **"PDT"**.
## Time zone abbreviations cannot describe a time zone fully, unless you know what country you are in and its a common one.
## It is always recommended to use full timezone names for parsing and storage and only display time zone abbreviations and never parse them.
##


import parsecsv
import strutils
import algorithm
import streams

import timestamps
import calendars

type
  PackedString[N] = array[N, char]

  DstChange* = object {.packed.}
    ## Day Light Savings time transition
    tzId*: int16
    name*: array[6, char]
    start*: float64
    offset*: int32

  TimeZone* = object {.packed.}
    ## Time Zone information
    id*: int16
    name*: array[32, char]


proc pack[N](str: string): PackedString[N] =
  if str.len >= result.len:
    raise Exception("Can't pack " & str.len & " string into " & result.len)
  for i in 0..<result.len:
    if i >= str.len:
      break
    result[i] = str[i]


proc `$`*[N](ps: PackedString[N]): string =
  result = ""
  for c in ps:
    if c == '\0':
      break
    result &= c


proc `==`[N](a: PackedString[N], b: string): bool =
  for i, c in a:
    if c == '\0':
      return b.len == i
    if c != b[i]:
      return false
  return true


const zoneData = staticRead("../tzdata/timeZones.bin")
const dstData = staticRead("../tzdata/dstChanges.bin")

var timeZones* = newSeq[TimeZone](zoneData.len div sizeof(TimeZone)) ## List of all timezones
var dstChanges* = newSeq[DstChange](dstData.len div sizeof(DstChange)) ## List of all DST changes

var zoneStream = newStringStream(zoneData)
for i in 0..<timeZones.len:
  var dummyZone = TimeZone()
  discard zoneStream.readData(cast[pointer](addr dummyZone), sizeof(TimeZone))
  timeZones[i] = dummyZone

var dstStream = newStringStream(dstData)
for i in 0..<dstChanges.len:
  var dummyDst = DstChange()
  discard dstStream.readData(cast[pointer](addr dummyDst), sizeof(DstChange))
  dstChanges[i] = dummyDst


proc binarySearch[T,K](a: openArray[T], key:K, keyProc: proc (e: T):K): int =
  ## binary search for `element` in `a`. Using a `keyProce` returns an Index or -1
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


proc binarySearchValue[T,K](a: openArray[T], key:K, keyProc: proc (e: T):K): T =
  ## binary search for `element` in `a`. Using a `keyProce`, returns default or a found value
  var index = binarySearch(a, key, keyProc)
  if index >= 0:
    result = a[index]


proc findTimeZone*(tzName: string): TimeZone =
  ## Finds timezone by its name
  proc getName(tz: TimeZone): string = $tz.name
  return timeZones.binarySearchValue(tzName, getName)


proc findTimeZone*(tzId: int): TimeZone =
  ## Finds timezone by its id (slow).
  for tz in timeZones:
    if tz.id == tzId:
      return tz


proc valid*(tz: TimeZone): bool =
  ## Returns true if timezone is valid
  return tz.id > 0


iterator findDstChanges*(tz: TimeZone): DstChange =
  ## Finds timezone dst changes by timezone.
  proc getTzId(dst: DstChange): int16 = dst.tzId
  var index = dstChanges.binarySearch(tz.id, getTzId)
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


proc applyTimezone*(cal: var Calendar, tzName: string) =
  ## take a calendar and apply a timezone to it
  ## this does not change the timestamp of the calendar
  var prevChange: DstChange
  var tz = findTimeZone(tzName)
  var ts = cal.calendarToTs()
  if tz.valid:
    for change in findDstChanges(tz):
      if Timestamp(change.start) > ts:
        break
      prevChange = change
    var tzOffset = float64(prevChange.offset)
    cal.subSeconds(int(cal.tzOffset))
    cal.tzOffset = tzOffset
    cal.addSeconds(prevChange.offset)
    cal.tzName = $tz.name
    cal.dstName = $prevChange.name


proc clearTimezone*(cal: var Calendar) =
  cal.subSeconds(int(cal.tzOffset))
  cal.tzOffset = 0
  cal.tzName = ""
  cal.dstName = ""


proc tsToCalendar*(ts: Timestamp, tzName: string): Calendar =
  ## Convert Timestamp to calendar with a timezone
  var cal = tsToCalendar(ts)
  cal.applyTimezone(tzName)
  return cal


proc tsToIso*(ts: Timestamp, tzName: string): string =
  ## Fastest way to convert Timestamp to an ISO 8601 string representaion
  ## Use this instead of the format function when dealing whith ISO format
  var cal = tsToCalendar(ts)
  cal.applyTimezone(tzName)
  return cal.calendarToIso()


proc parseTs*(fmt: string, value: string, tzName: string): Timestamp =
  ## Parse time using the Chrono format string with timezone nto a Timestamp.
  var cal = parseCalendar(fmt, value)
  cal.applyTimezone(tzName)
  return cal.calendarToTs()


proc formatTs*(ts: Timestamp, fmt: string, tzName: string): string =
  ## Format a Timestamp with timezone using the format string.
  var cal = tsToCalendar(ts)
  cal.applyTimezone(tzName)
  return cal.formatCalendar(fmt)
