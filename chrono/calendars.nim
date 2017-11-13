import math
import strutils


# my philosophy is that timestamp is king. Not the calendars.

##
## Format spesification
##
## ===========  =================================================================================  ================================================
## Specifier    Description                                                                        Example
## ===========  =================================================================================  ================================================
## {year}       Year in as many digits as needed. Can be negative.                                 ``12012/9/3 -> 12012``
## {year/2}     Two digit year, 0-30 represents 2000-2030 while 30-99 is 1930 to 1999.             ``2012/9/3 -> 12``
## {year/4}     Four digits of the year. Years 0 - 9999.                                           ``2012/9/3 -> 2012``
## {month}      Month in digits 1-12                                                               ``2012/9/3 -> 9``
## {month/2}    Month in two digits 01-12                                                          ``2012/9/3 -> 09``
## {month/n}    Full name of month                                                                 ``September -> September``
## {month/n/3}  Three letter name of month                                                         ``September -> Sep``
## {day}        Day in digits 1-31                                                                 ``2012/9/3 -> 3``
## {day/2}      Day in two digits 01-31                                                            ``2012/9/3 -> 03``
## {hour}       Hour in digits 0-23                                                                ``09:08:07 -> 9``
## {hour/2}     Hour in two digits 00-23                                                           ``09:08:07 -> 09``
## {hour/2/ap}  Hour as 12-hour am/pm as digits 1-12                                               ``13:08:07 -> 1``
## {hour/2/ap}  Hour as 12-hour am/pm as two digits 01-12                                          ``13:08:07 -> 01``
## {am/pm}      Based on hour outputs "am" or "pm"                                                 ``13:08:07 -> pm``
## {minute}     Minute in digits 0-59                                                              ``09:08:07 -> 8``
## {minute/2}   Minute in two digits 0-59                                                          ``09:08:07 -> 08``
## {second}     Second in digits 0-59                                                              ``09:08:07 -> 7``
## {second/2}   Second in two digits 0-59                                                          ``09:08:07 -> 07``
## {weekday}    Full name of weekday                                                               ``Saturday -> Saturday``
## {weekday/3}  Three letter of name of weekday                                                    ``Saturday -> Sat``
## {weekday/2}  Two letter of name of weekday                                                      ``Saturday -> Sa``
## ============ =================================================================================  ================================================
##
## Any string that is not in {} considered to not be part of the format and is just inserted.
## ``"{year/4} and {month/2} and {day/2}" -> "1988 and 02 and 09"``
##



type
  Calendar* = object
    year*: int
    month*: int
    day*: int
    hour*: int
    minute*: int
    second*: int
    secondFraction*: float64
    tzOffset*: float64
    tzName*: string


const weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saterday", "Sunday"]
const months = ["January", "February", "March", "April", "May", "June", "July", "August", "August", "October", "November", "December"]


proc calendarToIso*(cal: Calendar): string =
  ## Fastest way to convert Calendar to an ISO 8601 string representaion
  ## Use this instead of the format function when dealing whith ISO format
  ## Warning does minimal checking for speed. Make sure your calendar is valid.

  proc f(n: int): char = char(ord('0') + n)

  if cal.tzOffset == 0:
    result = "0000-00-00T00:00:00Z"
  else:
    result = "0000-00-00T00:00:00+00:00"
    var tzOffset = cal.tzOffset
    if tzOffset < 0:
      result[19] = '-'
      tzOffset = -tzOffset

    var tzOffsetMinute = int(tzOffset) div 60 mod 60
    var tzOffsetHour = int(tzOffset) div 3600 mod 60

    result[20] = f tzOffsetHour div 10
    result[21] = f tzOffsetHour mod 10

    result[23] = f tzOffsetMinute div 10
    result[24] = f tzOffsetMinute mod 10

  result[0] = f cal.year div 1000
  result[1] = f cal.year div 100 mod 10
  result[2] = f cal.year div 10 mod 10
  result[3] = f cal.year mod 10

  result[5] = f cal.month div 10
  result[6] = f cal.month mod 10

  result[8] = f cal.day div 10
  result[9] = f cal.day mod 10

  result[11] = f cal.hour div 10
  result[12] = f cal.hour mod 10

  result[14] = f cal.minute div 10
  result[15] = f cal.minute mod 10

  result[17] = f cal.second div 10
  result[18] = f cal.second mod 10


proc isoToCalendar*(iso: string): Calendar =
  ## Fastest way to convert an ISO 8601 string representaion to a Calendar.
  ## Use this instead of the parseTimestamp function when dealing whith ISO format
  ## Warning does no error checking for speed. If you want error checking use parseTs.

  proc f(i: int): int = ord(iso[i]) - ord('0')

  result.year  = f(0) * 1000
  result.year += f(1) * 100
  result.year += f(2) * 10
  result.year += f(3)

  result.month = f(5) * 10
  result.month += f(6)

  result.day = f(8) * 10
  result.day += f(9)

  result.hour = f(11) * 10
  result.hour += f(12)

  result.minute = f(14) * 10
  result.minute += f(15)

  result.second = f(17) * 10
  result.second += f(18)

  if iso[19] != 'Z':
    var tzOffsetHour = f(20) * 10
    tzOffsetHour += f(21)

    var tzOffsetMinute = f(23) * 10
    tzOffsetMinute += f(24)

    result.tzOffset = float64(tzOffsetMinute * 60 + tzOffsetHour * 3600)
    if iso[19] == '-':
      result.tzOffset = -result.tzOffset


proc weekday*(cal: Calendar): int =
  ## Get number of a weekday 0..6. Monday being 0
  var r = cal.day
  r += ((153 * (cal.month + 12 * ((14 - cal.month) div 12) - 3) + 2) div 5)
  r += (365 * (cal.year + 4800 - ((14 - cal.month) div 12)))
  r += ((cal.year + 4800 - ((14 - cal.month) div 12)) div 4)
  r -= ((cal.year + 4800 - ((14 - cal.month) div 12)) div 100)
  r += ((cal.year + 4800 - ((14 - cal.month) div 12)) div 400)
  r -= 32045
  return r mod 7


proc leapYear(year: int): bool =
  if year mod 4 == 0:
    if year mod 100 == 0:
      if year mod 400 == 0:
        return true
      else:
        return false
    else:
      return true
  else:
    return false


proc leapYear*(cal: Calendar): bool =
  ## Is the calendar in a leap year
  leapYear(cal.year)


proc daysInMonth(m: int, year: int): int =
  if m == 1 or m == 3 or m == 5 or m == 7 or m == 8 or m == 10 or m == 12:
    return 31
  elif m == 4 or m == 6 or m == 9 or m == 11:
    return 30
  elif m == 2:
    if leapYear(year):
      return 29
    else:
      return 28


proc daysInMonth*(cal: Calendar): int =
  ## Get number of days in a calendar month
  daysInMonth(cal.month, cal.year)


proc normalize*(cal: var Calendar) =
  ## Fixes any issues with calendar such as extra hours, extra days, negative months

  if cal.secondFraction > 1:
    cal.second += int(cal.secondFraction)
    cal.secondFraction -= float64(int(cal.secondFraction))

  if cal.secondFraction < 0:
    var subSeconds = int(cal.secondFraction - 1)
    cal.second += subSeconds
    cal.secondFraction = cal.secondFraction - float64(subSeconds)

  if cal.second >= 60:
    cal.minute += cal.second div 60
    cal.second = cal.second mod 60

  if cal.second < 0:
    var qut = (-cal.second) div 60
    var rem = -cal.second mod 60
    cal.minute -= qut
    if rem > 0:
      dec cal.minute
      cal.second = 60 - rem
    else:
      cal.second = 0

  if cal.minute >= 60:
    cal.hour += cal.minute div 60
    cal.minute  = cal.minute mod 60

  if cal.minute < 0:
    var qut = (-cal.minute) div 60
    var rem = -cal.minute mod 60
    cal.hour -= qut
    if rem > 0:
      dec cal.hour
      cal.minute = 60 - rem
    else:
      cal.minute = 0

  if cal.hour >= 24:
    cal.day += cal.hour div 24
    cal.hour = cal.hour mod 24

  if cal.hour < 0:
    var qut = (-cal.hour) div 24
    var rem = -cal.hour mod 24
    cal.day -= qut
    if rem > 0:
      dec cal.day
      cal.hour = 24 - rem
    else:
      cal.hour = 0

  if cal.day < 1 or cal.month < 1:
    dec cal.month # use 0-based for calcualtions
    dec cal.day # use 0-based for calcualtions

    if cal.month < 0:
      var qut = (-cal.month) div 12
      var rem = (-cal.month) mod 12
      cal.year -= qut
      if rem > 0:
        dec cal.year
        cal.month = 12 - rem
      else:
        cal.month = 0

    while cal.day < 0:
      dec cal.month
      if cal.month < 0:
        cal.month = 11
        dec cal.year
      var monthDays = daysInMonth(cal.month+1, cal.year)
      cal.day += monthDays

    inc cal.month # back to 1-based months
    inc cal.day # back to 1-based days


  if cal.day > cal.daysInMonth or cal.month > 12:
    dec cal.month # use 0-based for calcualtions
    dec cal.day # use 0-based for calcualtions

    if cal.month >= 12:
      cal.year += cal.month div 12
      cal.month = cal.month mod 12

    var monthDays = daysInMonth(cal.month + 1, cal.year)
    while cal.day >= monthDays:
      cal.day -= monthDays
      inc cal.month
      if cal.month >= 12:
        inc cal.year
        cal.month = 0
      monthDays = daysInMonth(cal.month + 1, cal.year)

    inc cal.month # back to 1-based months
    inc cal.day # back to 1-based days


proc addSeconds*(cal: var Calendar, seconds: float64) =
  ## Add float point seconds to this calendar
  cal.secondFraction += seconds
  cal.normalize()


proc addSeconds*(cal: var Calendar, seconds: int) =
  ## Add seconds to this calendar
  cal.second += seconds
  cal.normalize()


proc addMinutes*(cal: var Calendar, minutes: int) =
  ## Add minutes to this calendar
  cal.minute += minutes
  cal.normalize()


proc addHours*(cal: var Calendar, hours: int) =
  ## Add hours to this calendar
  cal.hour += hours
  cal.normalize()


proc addDays*(cal: var Calendar, days: int) =
  ## Add days to this calendar
  cal.day += days
  cal.normalize()


proc addMonths*(cal: var Calendar, months: int) =
  ## Add months to this calendar
  cal.month += months
  cal.normalize()


proc addYears*(cal: var Calendar, years: int) =
  ## Add years to this calendar
  cal.year += years


proc subSeconds*(cal: var Calendar, seconds: float64) =
  ## Subtracts float point seconds to this calendar
  cal.secondFraction -= seconds
  cal.normalize()


proc subSeconds*(cal: var Calendar, seconds: int) =
  ## Subtracts seconds to this calendar
  cal.second -= seconds
  cal.normalize()


proc subMinutes*(cal: var Calendar, minutes: int) =
  ## Subtracts minutes to this calendar
  cal.minute -= minutes
  cal.normalize()


proc subHours*(cal: var Calendar, hours: int) =
  ## Subtracts hours to this calendar
  cal.hour -= hours
  cal.normalize()


proc subDays*(cal: var Calendar, days: int) =
  ## Subtracts days to this calendar
  cal.day -= days
  cal.normalize()


proc subMonths*(cal: var Calendar, months: int) =
  ## Subtracts months to this calendar
  cal.month -= months
  cal.normalize()


proc subYears*(cal: var Calendar, years: int) =
  ## Subtracts years to this calendar
  cal.year -= years


proc parseCalendar*(format: string, value: string): Calendar =
  ## Parses calendars from a string based on the format spesification
  ## Note that not all valid formats can be parsed, things such as weeekdays or am/pm stuff without hours or am/pm marker.

  result = Calendar(year: 1970, month: 1, day: 1)
  var i = 0
  var j = 0

  proc getNumber(): int =
    var num = ""
    while isDigit(value[j]):
      num &= value[j]
      inc j
    if num.len == 0:
      raise newException(ValueError, "Number not found")
    return parseInt(num)

  proc getNumber(digits: int): int =
    var num = ""
    for d in 0..<digits:
      if isDigit(value[j]):
        num &= value[j]
        inc j
      else:
        raise newException(ValueError, "Not a digit")
    return parseInt(num)

  proc getStr(chars: int): string =
    result = value[j..<j + chars]
    j += chars

  proc nextMatch(match: string): bool =
    if value[j..<j + match.len].toLower() == match.toLower():
      j += match.len
      return true
    return false

  while true:
    if i == format.len and j == value.len:
      return
    if i == format.len or j == value.len:
      raise newException(ValueError, "Format and value string length did not match")

    if format[i] == '{':
      var token = ""
      inc i
      while format[i] != '}':
        token &= format[i]
        inc i
      inc i

      case token:
        of "year":
          result.year = getNumber()
        of "year/2":
          result.year = getNumber(2)
          if result.year > 30:
            result.year += 1900
          else:
            result.year += 2000
        of "year/4":
          result.year = getNumber(4)

        of "month":
          result.month = getNumber()
        of "month/2":
          result.month = getNumber(2)
        of "month/n":
          for k, m in months:
            if nextMatch(m):
              result.month = k + 1
        of "month/n/3":
          for k, m in months:
            if nextMatch(m[0..2]):
              result.month = k + 1
        of "day":
          result.day = getNumber()
        of "day/2":
          result.day = getNumber(2)

        of "hour":
          result.hour = getNumber()
        of "hour/2":
          result.hour = getNumber(2)

        of "hour/ap":
          result.hour = getNumber()

        of "hour/2/ap":
          result.hour = getNumber(2)

        of "am/pm":
          if result.hour == 12:
            result.hour = 0
          if nextMatch("am"):
            discard
          elif nextMatch("pm"):
            result.hour += 12
          else:
            raise newException(ValueError, "Can't parse am/pm")

        of "minute":
          result.minute = getNumber()
        of "minute/2":
          result.minute = getNumber(2)

        of "second":
          result.second = getNumber()
        of "second/2":
          result.second = getNumber(2)

        else:
          raise newException(ValueError, "Invalid token: " & token)

    elif format[i] == value[j]:
      inc i
      inc j

    else:
      raise newException(ValueError, "Not match")


proc formatCalendar*(cal: Calendar, format: string): string =
  ## Formats calendars to a string based on the format spesification

  var i = 0
  var output = ""

  proc putNumber(num: int) =
    output &= $num

  proc putNumber(num: int, digits: int) =
    output &= align($num, digits, '0')

  while i < format.len:

    if format[i] == '{':
      var token = ""
      inc i
      while format[i] != '}':
        token &= format[i]
        inc i

      case token:
        of "year":
          putNumber(cal.year)
        of "year/2":
          if cal.year < 1930 or cal.year > 2030:
            raise newException(ValueError, "Can't format year as two digits")
          if cal.year >= 2000:
            putNumber(cal.year - 2000, 2)
          else:
            putNumber(cal.year - 1900, 2)
        of "year/4":
          if cal.year < 0 or cal.year > 9999:
            raise newException(ValueError, "Can't format year as 4 digits")
          putNumber(cal.year, 4)

        of "month":
          putNumber(cal.month)
        of "month/2":
          putNumber(cal.month, 2)
        of "month/n":
          output &= months[cal.month - 1]
        of "month/n/3":
          output &= months[cal.month - 1][0..2]


        of "day":
          putNumber(cal.day)
        of "day/2":
          putNumber(cal.day, 2)

        of "hour":
          putNumber(cal.hour)
        of "hour/2":
          putNumber(cal.hour, 2)

        of "hour/ap":
          var h = int cal.hour mod 12
          if h == 0: h = 12
          putNumber(h)

        of "hour/2/ap":
          var h = int cal.hour mod 12
          if h == 0: h = 12
          putNumber(h, 2)

        of "am/pm":
          if cal.hour < 12:
            output &= "am"
          else:
            output &= "pm"

        of "minute":
          putNumber(cal.minute)
        of "minute/2":
          putNumber(cal.minute, 2)

        of "second":
          putNumber(cal.second)
        of "second/2":
          putNumber(cal.second, 2)

        of "weekday":
          output &= weekdays[cal.weekday]
        of "weekday/3":
          output &= weekdays[cal.weekday][0..2]
        of "weekday/2":
          output &= weekdays[cal.weekday][0..1]

        else:
          raise newException(ValueError, "Invalid token: " & token)

    else:
      output &= format[i]

    inc i

  return output
