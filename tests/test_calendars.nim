import unittest

import ../chrono/calendars


suite "calendars":

  test "isoToCalendar":
    check isoToCalendar("1970-01-01T00:00:00Z") == Calendar(year: 1970, month: 1, day: 1)
    check isoToCalendar("2017-01-01T00:00:00Z") == Calendar(day: 1, month: 1, year: 2017)
    check isoToCalendar("0000-01-01T00:00:00Z") == Calendar(day: 1, month: 1, year: 0)
    check isoToCalendar("1970-01-01T01:02:03Z") == Calendar(year: 1970, month: 1, day: 1, hour: 1, minute: 2, second: 3)
    check isoToCalendar("9999-12-31T59:59:59Z") == Calendar(year: 9999, month: 12, day: 31, hour: 59, minute: 59, second: 59)

  test "calendarToIso":
    check calendarToIso(Calendar(year: 1970, month: 1, day: 1)) == "1970-01-01T00:00:00Z"
    check calendarToIso(Calendar(year: 1970, month: 1, day: 1, tzOffset: 25200.0)) == "1970-01-01T00:00:00+07:00"
    check calendarToIso(Calendar(day: 1, month: 1, year: 2017)) == "2017-01-01T00:00:00Z"
    check calendarToIso(Calendar(day: 1, month: 1, year: 0)) == "0000-01-01T00:00:00Z"

    check calendarToIso(Calendar(year: 1970, month: 1, day: 1, hour: 1, minute: 2, second: 3)) == "1970-01-01T01:02:03Z"
    check calendarToIso(Calendar(year: 9999, month: 12, day: 31, hour: 59, minute: 59, second: 59)) == "9999-12-31T59:59:59Z"

  test "parseCalendar":

    proc testParse(iso, format, value: string) =
      var cal = parseCalendar(format, value)
      if cal != isoToCalendar(iso):
        echo "format: ", format
        echo "value:  ", value
        echo "---"
        echo "got:    ", calendarToIso(cal)
        echo "expect: ", iso
        fail()

    testParse("1970-01-01T00:00:00Z", "nothing", "nothing")
    testParse("1988-01-01T00:00:00Z", "this is the {year} yes", "this is the 1988 yes")
    testParse("1988-02-09T00:00:00Z", "{year/4} and {month/2} and {day/2}", "1988 and 02 and 09")
    testParse("0788-02-09T00:00:00Z", "{year} and {month} and {day}", "788 and 2 and 9")
    testParse("1988-02-09T00:00:00Z", "{year/2}{month/2}{day/2}", "880209")
    testParse("1888-08-08T00:00:00Z", "{year}-{month}-{day}", "1888-8-8")
    testParse("1988-02-09T03:34:12Z", "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z", "1988-02-09T03:34:12Z")
    testParse("1988-02-09T03:34:12Z", "{year/4}{month/2}{day/2}{hour/2}{minute/2}{second/2}", "19880209033412")

    testParse("1970-01-01T09:08:00Z", "{hour/2/ap}:{minute/2} {am/pm}", "09:08 am")
    testParse("1970-01-01T21:08:00Z", "{hour/2/ap}:{minute/2} {am/pm}", "09:08 pm")
    testParse("1970-01-01T00:08:00Z", "{hour/2/ap}:{minute/2} {am/pm}", "12:08 am")
    testParse("1970-01-01T12:08:00Z", "{hour/2/ap}:{minute/2} {am/pm}", "12:08 pm")

    testParse("1970-01-01T00:00:00Z", "{month/n}", "January")
    testParse("1970-02-01T00:00:00Z", "{month/n/3}", "Feb")

  test "formatCalendar":

    proc testFormat(iso, format, value: string) =
      var formatted = isoToCalendar(iso).formatCalendar(format)
      if formatted != value:
        echo "format: ", format
        echo "cal:    ", iso
        echo "---"
        echo "got:    ", formatted
        echo "expect: ", value
        fail()

    testFormat("1970-01-01T00:00:00Z", "nothing", "nothing")
    testFormat("1988-01-01T00:00:00Z", "this is the {year} yes", "this is the 1988 yes")
    testFormat("1988-02-09T00:00:00Z", "{year/4} and {month/2} and {day/2}", "1988 and 02 and 09")
    testFormat("0788-02-09T00:00:00Z", "{year} and {month} and {day}", "788 and 2 and 9")
    testFormat("1988-02-09T00:00:00Z", "{year/2}{month/2}{day/2}", "880209")
    testFormat("1888-08-08T00:00:00Z", "{year}-{month}-{day}", "1888-8-8")
    testFormat("1988-02-09T03:34:12Z", "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z", "1988-02-09T03:34:12Z")
    testFormat("1988-02-09T03:34:12Z", "{year/4}{month/2}{day/2}{hour/2}{minute/2}{second/2}", "19880209033412")

    testFormat("1970-01-01T09:08:00Z", "{hour/2/ap}:{minute/2} {am/pm}", "09:08 am")
    testFormat("1970-01-01T21:08:00Z", "{hour/2/ap}:{minute/2} {am/pm}", "09:08 pm")
    testFormat("1970-01-01T00:08:00Z", "{hour/2/ap}:{minute/2} {am/pm}", "12:08 am")
    testFormat("1970-01-01T12:08:00Z", "{hour/2/ap}:{minute/2} {am/pm}", "12:08 pm")

    testFormat("1970-01-01T12:08:00Z", "{weekday}", "Thursday")
    testFormat("1988-02-09T12:08:00Z", "{weekday}", "Tuesday")
    testFormat("1970-01-01T12:08:00Z", "{weekday/3}", "Thu")
    testFormat("1988-02-09T12:08:00Z", "{weekday/3}", "Tue")
    testFormat("1970-01-01T12:08:00Z", "{weekday/2}", "Th")
    testFormat("1988-02-09T12:08:00Z", "{weekday/2}", "Tu")

    testFormat("1970-01-01T12:08:00Z", "{month/n}", "January")
    testFormat("1970-02-09T12:08:00Z", "{month/n/3}", "Feb")

  test "weekday":
    check isoToCalendar("1970-01-01T00:00:00Z").weekday == 3
    check isoToCalendar("1999-01-01T00:00:00Z").weekday == 4

  test "leapYear":
    check isoToCalendar("1971-01-01T00:00:00Z").leapYear == false
    check isoToCalendar("2016-01-01T00:00:00Z").leapYear == true

  test "daysInMonth":
    check isoToCalendar("1971-02-01T00:00:00Z").daysInMonth == 28
    check isoToCalendar("2016-02-01T00:00:00Z").daysInMonth == 29
    check isoToCalendar("2010-01-01T00:00:00Z").daysInMonth == 31
    check isoToCalendar("1910-11-01T00:00:00Z").daysInMonth == 30

  test "addSeconds":
    var c: Calendar

    c = Calendar(year: 1970, month: 1, day: 1)
    c.addSeconds(12)
    check Calendar(year: 1970, month: 1, day: 1, second:12) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.addSeconds(12.25)
    check Calendar(year: 1970, month: 1, day: 1, second:12, secondFraction: 0.25) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.addSeconds(112)
    check Calendar(year: 1970, month: 1, day: 1, minute:1, second:52) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.addSeconds(3600 * 7 + 30)
    check Calendar(year: 1970, month: 1, day: 1, hour:7, second:30) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.addSeconds(24 * 3600 * 7)
    check Calendar(year: 1970, month: 1, day: 8) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.addSeconds(24 * 3600 * 40)
    check Calendar(year: 1970, month: 2, day: 10) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.addSeconds(24 * 3600 * 400)
    check Calendar(year: 1971, month: 2, day: 5) == c

  test "addMinutes":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.addMinutes(12345678)
    check Calendar(year: 1993, month: 6, day: 22, hour:9, minute:18) == c

  test "addHours":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.addHours(12345678)
    check Calendar(year: 3378, month: 5, day: 22, hour:6) == c

  test "addDays":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.addDays(1234)
    check Calendar(year: 1973, month: 5, day: 19) == c

  test "addMonths":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.addMonths(1234)
    check Calendar(year: 2072, month: 11, day: 1) == c

  test "addYears":
    var c = Calendar(year: 1000, month: 1, day: 1)
    c.addYears(11000)
    check Calendar(year: 12000, month: 1, day: 1) == c

  test "subSeconds":
    var c: Calendar

    c = Calendar(year: 1970, month: 1, day: 1, second:30)
    c.subSeconds(12)
    check Calendar(year: 1970, month: 1, day: 1, second:18) == c

    c = Calendar(year: 1970, month: 1, day: 1, second:30)
    c.subSeconds(12.25)
    check Calendar(year: 1970, month: 1, day: 1, second:17, secondFraction: 0.75) == c

    c = Calendar(year: 1970, month: 1, day: 10, minute: 10, second: 30)
    c.subSeconds(30)
    check Calendar(year: 1970, month: 1, day: 10, minute: 10, second: 0) == c

    c = Calendar(year: 1970, month: 1, day: 10, minute: 10, second: 30)
    c.subSeconds(31)
    check Calendar(year: 1970, month: 1, day: 10, minute: 9, second: 59) == c

    c = Calendar(year: 1970, month: 1, day: 10, minute: 10, second: 30)
    c.subSeconds(90)
    check Calendar(year: 1970, month: 1, day: 10, minute: 9, second: 0) == c

    c = Calendar(year: 1970, month: 1, day: 10, minute: 1, second: 0)
    c.subSeconds(61)
    check Calendar(year: 1970, month: 1, day: 9, hour: 23, minute: 59, second: 59) == c

    c = Calendar(year: 1970, month: 1, day: 10)
    c.subSeconds(3600 * 7)
    check Calendar(year: 1970, month: 1, day: 9, hour: 17) == c

    c = Calendar(year: 1970, month: 1, day: 10)
    c.subSeconds(3600 * 24 * 5)
    check Calendar(year: 1970, month: 1, day: 5) == c

    c = Calendar(year: 1990, month: 1, day: 10)
    c.subSeconds(3600 * 24 * 11)
    check Calendar(year: 1989, month: 12, day: 30) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.subSeconds(3600 * 24 * 400)
    check Calendar(year: 1968, month: 11, day: 27) == c

  test "subMinutes":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.subMinutes(12345678)
    check Calendar(year: 1946, month: 7, day: 12, hour:14, minute:42) == c

  test "subHours":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.subHours(12345)
    check Calendar(year: 1968, month: 8, day: 4, hour:15) == c

  test "subDays":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.subDays(1234)
    check Calendar(year: 1966, month: 8, day: 16) == c

  test "subMonths":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.subMonths(1234)
    check Calendar(year: 1867, month: 3, day: 1) == c

  test "subYears":
    var c = Calendar(year: 1000, month: 1, day: 1)
    c.subYears(1234)
    check Calendar(year: -234, month: 1, day: 1) == c

  test "tzOffset":
    check isoToCalendar("1970-01-01T00:00:00+07:00") == Calendar(year: 1970, month: 1, day: 1, tzOffset: 25200.0)
    check calendarToIso(Calendar(year: 1970, month: 1, day: 1, tzOffset: 25200.0)) == "1970-01-01T00:00:00+07:00"
