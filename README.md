# Chrono a Timestamps, Calendars, and Timezones library for nim.


## Format spesification

| Specifier   | Description                                                                        | Example                     |
| ----------- | ---------------------------------------------------------------------------------- | --------------------------- |
| {year}      | Year in as many digits as needed. Can be negative.                                 | ``12012/9/3 -> 12012``      |
| {year/2}    | Two digit year, 0-30 represents 2000-2030 while 30-99 is 1930 to 1999.             | ``2012/9/3 -> 12``          |
| {year/4}    | Four digits of the year. Years 0 - 9999.                                           | ``2012/9/3 -> 2012``        |
| {month}     | Month in digits 1-12                                                               | ``2012/9/3 -> 9``           |
| {month/2}   | Month in two digits 01-12                                                          | ``2012/9/3 -> 09``          |
| {month/n}   | Full name of month                                                                 | ``September -> September``  |
| {month/n/3} | Three letter name of month                                                         | ``September -> Sep``        |
| {day}       | Day in digits 1-31                                                                 | ``2012/9/3 -> 3``           |
| {day/2}     | Day in two digits 01-31                                                            | ``2012/9/3 -> 03``          |
| {hour}      | Hour in digits 0-23                                                                | ``09:08:07 -> 9``           |
| {hour/2}    | Hour in two digits 00-23                                                           | ``09:08:07 -> 09``          |
| {hour/2/ap} | Hour as 12-hour am/pm as digits 1-12                                               | ``13:08:07 -> 1``           |
| {hour/2/ap} | Hour as 12-hour am/pm as two digits 01-12                                          | ``13:08:07 -> 01``          |
| {am/pm}     | Based on hour outputs "am" or "pm"                                                 | ``13:08:07 -> pm``          |
| {minute}    | Minute in digits 0-59                                                              | ``09:08:07 -> 8``           |
| {minute/2}  | Minute in two digits 0-59                                                          | ``09:08:07 -> 08``          |
| {second}    | Second in digits 0-59                                                              | ``09:08:07 -> 7``           |
| {second/2}  | Second in two digits 0-59                                                          | ``09:08:07 -> 07``          |
| {weekday}   | Full name of weekday                                                               | ``Saturday -> Saturday``    |
| {weekday/3} | Three letter of name of weekday                                                    | ``Saturday -> Sat``         |
| {weekday/2} | Two letter of name of weekday                                                      | ``Saturday -> Sa``          |
| {tzName}    | Timezone name (can't be parsed)                                                    | ``America/Los_Angeles``     |
| {dstName}   | Daylight savings name or standard name (can't be parsed)                           | ``PDT``                     |


Any string that is not in {} considered to not be part of the format and is just inserted.
``"{year/4} and {month/2} and {day/2}" -> "1988 and 02 and 09"``


## chrono/timestamps

If you are going to just parse or format dates. I recommend using just the `include chrono/timestamps` module.
It it includes the Timestamp that is enough for most cases involved with times.
I always recommend storing dates as a `float64` number of seconds sence 1970. This is exactly what Timestamp is.
When you need to parse it or display it use `parseTs` or `formatTs`.

```
var ts = parseTs(
    "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
    "1988-02-09T03:34:12Z"
)

echo ts

echo formatTs(
    ts,
    "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
)

```
If you need to parse ISO dates which is a very common format you find all over the internet. You can even use faster optimized versions here:

```
echo isoToTs("2017-11-08T08:01:43Z")

echo tsToIso(Timestamp(1510128103.0))
```


## chrono/calendars

Calendars are more involved they support more features but come with complexity and are mutable.

I do not recommend storing `Calendar` objects in files or databases. Store `Timestamp` instead.

Most useful thing about calendars is that you can add years, months, days, hours, minutes or seconds to them.

```
var cal = Calendar(year: 2013, month: 12, day: 31, hour: 59, minute: 59, second: 59)
echo cal.calendarToIso()
# "2013-12-31T59:59:59Z"

cal.addSeconds(20)
cal.subMinutes(15)
cal.addDays(40)
cal.subMonths(120)
```

It supports same format spesification as `Timestamp`:

```
echo cal.formatCalendar("{month/2}/{day/2}/{year/4} {hour/2}:{minute/2}:{second/2}")
```

If you need extra features that calendars provide I recommending creating a `Calendar` with `tsToCalendar` doing your work and converting back with `calendarToTs`.

```
ts = cal.calendarToTs()
cal = ts.tsToCalendar()
```
Calendars are not ment to be stored or to live for very long unlike in other libraries. All common operations can be done with `Timestamps`.



## chrono/timezones

Timezones can be complicated.
But if you treat them as a presentation level issue sort of like language it becomes easier.
Never store anything as non-UTC.
If you need to store timezone info store it as a `string` plus a `Timestamp`.
When you need to display or parse it use the tzName attribute.

```
var ts = parseTs(
    "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
    "1988-02-09T03:34:12Z",
    tzName = "America/Los_Angeles"
)

echo ts

echo formatTs(
    ts,
    "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
    tzName = "America/Los_Angeles"
)

```

Timezone and daylight savings can and do change unpredictably remember to keep this library up to date.

When you include the library it also includes the daylight savings table in the binary which is about 6MB.
It does not use OS's timezone functions.
You are always guaranteed to game the same result on all platforms.

Many confuse proper time zone names like "America/Los_Angeles" with 3-4 letter time zone abbreviations like "PST" or "PDT".
Time zone abbreviations cannot describe a time zone fully, unless you know what country you are in and its a common one.
It is always recommended to use full timezone names for parsing and storage and only display time zone abbreviations and never parse them.
