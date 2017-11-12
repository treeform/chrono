import parsecsv
import strutils
import algorithm
import streams

import ../calendars/timestamps
import ../calendars

type
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


proc toArray[A](str: string): A =
  if str.len >= result.len:
    echo str.len
  for i in 0..<result.len:
    if i >= str.len:
      break
    result[i] = str[i]


proc toString[A](arr: A): string =
  result = ""
  for c in arr:
    if c == '\0':
      break
    result &= c


const zoneData = staticRead("../tzdata/timeZones.bin")
const dstData = staticRead("../tzdata/dstChanges.bin")

var timeZones* = newSeq[TimeZone](zoneData.len div sizeof(TimeZone))
var dstChanges* = newSeq[DstChange](dstData.len div sizeof(DstChange))

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
  proc getName(tz: TimeZone): string = toString(tz.name)
  return timeZones.binarySearchValue(tzName, getName)


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


proc tsToCalendar*(ts: Timestamp, tzName: string): Calendar =
  var prevChange: DstChange
  var tz = findTimeZone(tzName)
  if tz.valid:
    for change in findDstChanges(tz):
      if Timestamp(change.start) > ts:
        break
      prevChange = change
    var tzOffset = float64(prevChange.offset)
    return tsToCalendar(ts, tzOffset = tzOffset)


proc tsToIso*(ts: Timestamp, tzName: string): string =
  ## Fastest way to convert Timestamp to an ISO 8601 string representaion
  ## Use this instead of the format function when dealing whith ISO format
  return calendarToIso(tsToCalendar(ts, tzName))
