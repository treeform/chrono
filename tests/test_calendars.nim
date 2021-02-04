import chrono, unittest

suite "calendars":

  test "parseIsoCalendar":
    check parseIsoCalendar("1970-01-01T00:00:00Z") == Calendar(year: 1970,
        month: 1, day: 1)
    check parseIsoCalendar("2017-01-01T00:00:00Z") == Calendar(day: 1, month: 1, year: 2017)
    check parseIsoCalendar("0000-01-01T00:00:00Z") == Calendar(day: 1, month: 1, year: 0)
    check parseIsoCalendar("1970-01-01T01:02:03Z") == Calendar(year: 1970,
        month: 1, day: 1, hour: 1, minute: 2, second: 3)
    check parseIsoCalendar("9999-12-31T59:59:59Z") == Calendar(year: 9999,
        month: 12, day: 31, hour: 59, minute: 59, second: 59)

  test "formatIso":
    check formatIso(Calendar(year: 1970, month: 1, day: 1)) == "1970-01-01T00:00:00Z"
    check formatIso(Calendar(year: 1970, month: 1, day: 1,
        tzOffset: 25200.0)) == "1970-01-01T00:00:00+07:00"
    check formatIso(Calendar(day: 1, month: 1, year: 2017)) == "2017-01-01T00:00:00Z"
    check formatIso(Calendar(day: 1, month: 1, year: 0)) == "0000-01-01T00:00:00Z"

    check formatIso(Calendar(year: 1970, month: 1, day: 1, hour: 1, minute: 2,
        second: 3)) == "1970-01-01T01:02:03Z"
    check formatIso(Calendar(year: 9999, month: 12, day: 31, hour: 59,
        minute: 59, second: 59)) == "9999-12-31T59:59:59Z"

  test "readme":
    var cal = Calendar(year: 2013, month: 12, day: 31, hour: 59, minute: 59, second: 59)
    check $cal == "2013-12-31T59:59:59Z"
    cal.add(Second, 20)
    check $cal == "2014-01-02T12:00:19Z"
    cal.sub(Minute, 15)
    check $cal == "2014-01-02T11:45:19Z"
    cal.add(Day, 40)
    check $cal == "2014-02-11T11:45:19Z"
    cal.sub(Month, 120)
    check $cal == "2004-02-11T11:45:19Z"
    cal.toStartOf(Day)
    check $cal == "2004-02-11T00:00:00Z"
    cal.toEndOf(Month)
    check $cal == "2004-03-01T00:00:00Z"

  test "parseCalendar":
    proc testParse(iso, format, value: string) =
      var cal = parseCalendar(format, value)
      if cal != parseIsoCalendar(iso):
        echo "format: ", format
        echo "value:  ", value
        echo "---"
        echo "got:    ", formatIso(cal)
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

    testParse("1916-09-30T22:59:59Z", "{month/n/3} {day} {hour/2}:{minute/2}:{second/2} {year}", "Sep 30 22:59:59 1916")

    # eat spaces before numbers
    testParse("1916-09-02T22:59:59Z", "{month/n/3} {day} {hour/2}:{minute/2}:{second/2} {year}", "Sep  2 22:59:59  1916")

    # pares but ignore weekdays
    testParse("1916-09-30T22:59:59Z", "{weekday} {month/n/3} {day} {hour/2}:{minute/2}:{second/2} {year}", "Monday Sep 30 22:59:59 1916")
    testParse("1916-09-30T22:59:59Z", "{weekday/3} {month/n/3} {day} {hour/2}:{minute/2}:{second/2} {year}", "Mon Sep 30 22:59:59 1916")

    # secondFraction
    let c = parseCalendar("{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second}.{secondFraction}Z", "2021-02-01T14:28:58.983432014Z")
    doAssert c.secondFraction == 0.983432014

  test "format Calendar":

    proc testFormat(iso, format, value: string) =
      var formatted = parseIsoCalendar(iso).format(format)
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

    doAssert Calendar().format("{secondFraction}") == "0"
    doAssert Calendar(secondFraction: 0.25).format("{secondFraction}") == "25"
    doAssert Calendar(secondFraction: 0.3333333).format("{secondFraction}") == "3333333"

  test "weekday":
    check parseIsoCalendar("1970-01-01T00:00:00Z").weekday == 3
    check parseIsoCalendar("1999-01-01T00:00:00Z").weekday == 4

  test "leapYear":
    check parseIsoCalendar("1971-01-01T00:00:00Z").leapYear == false
    check parseIsoCalendar("2016-01-01T00:00:00Z").leapYear == true

  test "daysInMonth":
    check parseIsoCalendar("1971-02-01T00:00:00Z").daysInMonth == 28
    check parseIsoCalendar("2016-02-01T00:00:00Z").daysInMonth == 29
    check parseIsoCalendar("2010-01-01T00:00:00Z").daysInMonth == 31
    check parseIsoCalendar("1910-11-01T00:00:00Z").daysInMonth == 30

  test "addSeconds":
    var c: Calendar

    c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Second, 12)
    check Calendar(year: 1970, month: 1, day: 1, second: 12) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Second, 12.25)
    check Calendar(year: 1970, month: 1, day: 1, second: 12,
        secondFraction: 0.25) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Second, 112)
    check Calendar(year: 1970, month: 1, day: 1, minute: 1, second: 52) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Second, 3600 * 7 + 30)
    check Calendar(year: 1970, month: 1, day: 1, hour: 7, second: 30) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Second, 24 * 3600 * 7)
    check Calendar(year: 1970, month: 1, day: 8) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Second, 24 * 3600 * 40)
    check Calendar(year: 1970, month: 2, day: 10) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Second, 24 * 3600 * 400)
    check Calendar(year: 1971, month: 2, day: 5) == c

    c = Calendar(year: 1970, month: 2, day: 1)
    c.add(Second, - 3600 * 7)
    check Calendar(year: 1970, month: 1, day: 31, hour: 17) == c

    c = Calendar(year: 2017, month: 9, day: 20, hour: 15, minute: 19,
        second: 42, secondFraction: 0.0)
    c.add(Second, - 3600 * 3)
    check Calendar(year: 2017, month: 9, day: 20, hour: 12, minute: 19,
        second: 42, secondFraction: 0.0) == c

  test "addMinutes":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Minute, 12345678)
    check Calendar(year: 1993, month: 6, day: 22, hour: 9, minute: 18) == c

  test "addHours":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Hour, 12345678)
    check Calendar(year: 3378, month: 5, day: 22, hour: 6) == c

  test "addDays":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Day, 1234)
    check Calendar(year: 1973, month: 5, day: 19) == c

  test "addMonths":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.add(Month, 1234)
    check Calendar(year: 2072, month: 11, day: 1) == c

  test "addYears":
    var c = Calendar(year: 1000, month: 1, day: 1)
    c.add(Year, 11000)
    check Calendar(year: 12000, month: 1, day: 1) == c

  test "subSeconds":
    var c: Calendar

    c = Calendar(year: 1970, month: 1, day: 1, second: 30)
    c.sub(Second, 12)
    check Calendar(year: 1970, month: 1, day: 1, second: 18) == c

    c = Calendar(year: 1970, month: 1, day: 1, second: 30)
    c.sub(Second, 12.25)
    check Calendar(year: 1970, month: 1, day: 1, second: 17,
        secondFraction: 0.75) == c

    c = Calendar(year: 1970, month: 1, day: 10, minute: 10, second: 30)
    c.sub(Second, 30)
    check Calendar(year: 1970, month: 1, day: 10, minute: 10, second: 0) == c

    c = Calendar(year: 1970, month: 1, day: 10, minute: 10, second: 30)
    c.sub(Second, 31)
    check Calendar(year: 1970, month: 1, day: 10, minute: 9, second: 59) == c

    c = Calendar(year: 1970, month: 1, day: 10, minute: 10, second: 30)
    c.sub(Second, 90)
    check Calendar(year: 1970, month: 1, day: 10, minute: 9, second: 0) == c

    c = Calendar(year: 1970, month: 1, day: 10, minute: 1, second: 0)
    c.sub(Second, 61)
    check Calendar(year: 1970, month: 1, day: 9, hour: 23, minute: 59,
        second: 59) == c

    c = Calendar(year: 1970, month: 1, day: 10)
    c.sub(Second, 3600 * 7)
    check Calendar(year: 1970, month: 1, day: 9, hour: 17) == c

    c = Calendar(year: 1970, month: 1, day: 10)
    c.sub(Second, 3600 * 24 * 5)
    check Calendar(year: 1970, month: 1, day: 5) == c

    c = Calendar(year: 1990, month: 1, day: 10)
    c.sub(Second, 3600 * 24 * 11)
    check Calendar(year: 1989, month: 12, day: 30) == c

    c = Calendar(year: 1970, month: 1, day: 1)
    c.sub(Second, 3600 * 24 * 400)
    check Calendar(year: 1968, month: 11, day: 27) == c

  test "subMinutes":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.sub(Minute, 12345678)
    check Calendar(year: 1946, month: 7, day: 12, hour: 14, minute: 42) == c

  test "subHours":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.sub(Hour, 12345)
    check Calendar(year: 1968, month: 8, day: 4, hour: 15) == c

  test "subDays":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.sub(Day, 1234)
    check Calendar(year: 1966, month: 8, day: 16) == c

  test "subMonths":
    var c = Calendar(year: 1970, month: 1, day: 1)
    c.sub(Month, 1234)
    check Calendar(year: 1867, month: 3, day: 1) == c

  test "subYears":
    var c = Calendar(year: 1000, month: 1, day: 1)
    c.sub(Year, 1234)
    check Calendar(year: -234, month: 1, day: 1) == c

  test "tzOffset":
    check parseIsoCalendar("1970-01-01T00:00:00+07:00") == Calendar(year: 1970,
        month: 1, day: 1, tzOffset: 25200.0)
    check formatIso(Calendar(year: 1970, month: 1, day: 1,
        tzOffset: 25200.0)) == "1970-01-01T00:00:00+07:00"

    let dtStr = "1970-01-01 00:00:00 -07:00:00"
    let cal = parseCalendar("{year/4}-{month/2}-{day/2} {hour/2}:{minute/2}:{second/2} {offsetDir}{offsetHour/2}:{offsetMinute/2}:{offsetSecond/2}", dtStr)
    check $cal == "1970-01-01T00:00:00-07:00"

    let dtStr2 = "1970-01-01 00:00:00 -07:13:46"
    let cal2 = parseCalendar("{year/4}-{month/2}-{day/2} {hour/2}:{minute/2}:{second/2} {offsetDir}{offsetHour/2}:{offsetMinute/2}:{offsetSecond/2}", dtStr2)
    check cal2.tzOffset == -26026.0
    check $cal2 == "1970-01-01T00:00:00-07:13"

  test "toStartOf":
    var c: Calendar

    c = parseIsoCalendar("2016-01-01T12:23:45Z")
    c.toStartOf(Minute)
    assert $c == "2016-01-01T12:23:00Z"

    c = parseIsoCalendar("2016-01-01T12:23:45Z")
    c.toStartOf(Hour)
    assert $c == "2016-01-01T12:00:00Z"

    c = parseIsoCalendar("2016-01-01T12:23:00Z")
    c.toStartOf(Day)
    assert $c == "2016-01-01T00:00:00Z"

    c = parseIsoCalendar("2016-01-01T12:23:00Z")
    c.toStartOf(Week)
    assert $c == "2015-12-28T00:00:00Z"

    c = parseIsoCalendar("2016-10-20T12:23:00Z")
    c.toStartOf(Month)
    assert $c == "2016-10-01T00:00:00Z"

    c = parseIsoCalendar("2016-02-20T12:23:00Z")
    c.toStartOf(Quarter)
    assert $c == "2016-01-01T00:00:00Z"

    c = parseIsoCalendar("2016-10-20T12:23:00Z")
    c.toStartOf(Year)
    assert $c == "2016-01-01T00:00:00Z"

  test "toEndOf":
    var c: Calendar

    c = parseIsoCalendar("2016-01-01T12:23:45Z")
    c.toEndOf(Minute)
    assert $c == "2016-01-01T12:24:00Z"

    c = parseIsoCalendar("2016-01-01T12:23:45Z")
    c.toEndOf(Hour)
    assert $c == "2016-01-01T13:00:00Z"

    c = parseIsoCalendar("2016-01-01T12:23:00Z")
    c.toEndOf(Day)
    assert $c == "2016-01-02T00:00:00Z"

    c = parseIsoCalendar("2016-01-01T12:23:00Z")
    c.toEndOf(Week)
    assert $c == "2016-01-04T00:00:00Z"

    c = parseIsoCalendar("2016-10-20T12:23:00Z")
    c.toEndOf(Month)
    assert $c == "2016-11-01T00:00:00Z"

    c = parseIsoCalendar("2016-10-20T12:23:00Z")
    c.toEndOf(Quarter)
    assert $c == "2017-01-01T00:00:00Z"

    c = parseIsoCalendar("2016-10-20T12:23:00Z")
    c.toEndOf(Year)
    assert $c == "2017-01-01T00:00:00Z"
