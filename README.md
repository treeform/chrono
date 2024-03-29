<img src="docs/chronoBanner.png">

# Chrono a Timestamps, Calendars, and Timezones library for nim.

`nimble install chrono`

![Github Actions](https://github.com/treeform/chrono/workflows/Github%20Actions/badge.svg)

[API reference](https://treeform.github.io/chrono)

This library has no dependencies other than the Nim standard library.

## About

Works in `c`/`c++` as well as in `javascript`! All calendar manipulations! Include only the timezones and years you need!

The lowest building block should be the Timestamp of a single float64, not a complex calendar object. You should store Timestamp and transfer Timestamp. Timestamps are always in UTC. Calendar should only be used in time calculation like next month, previous week, 60 days from now… its a display/computation object that should be short lived.

Normalizing a calendar is an easy way to work with it. Its fine to add random days, years, months to the calendar. Its ok to have a calendar with 60 days… just normalize it when you are done. It just spills the days into next month. It’s very easy to do calendar math this way, as you can overflow or underflow calendar fields for a while you work with them.

The date-time format should be easy to understand without having documentation. Is `MM` month or minute? Is `ZZ` timezone or seconds? I provide a format that is simple to understand: `{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z`

Adding a timezone to a calendar is complex. There are two ways to do it. They are called apply and shift. Both functions will make your calendar have the new timezone but will effect it differently:
```
applyTimezone: "1970-05-23T21:21:18Z" -> "1970-05-23T14:21:18-07:00"
shiftTimezone: "1970-05-23T21:21:18Z" -> "1970-05-23T21:21:18-07:00"
```
* Apply will not shift your timestamp, so your display time will be different. Useful when some event happens at exact time but you want to display it to different people around the world in their time.
* Shift will not change your display time, while shifting your timestamp. Useful for a calendar meetings for example repeat at 9am every week, then give me exact timestamps for it.

Be aware of timezone files. On some OSes there is a location where you can get timezone information that is up to date, but that is not the case on Windows and JS-Browser mode. That is why I provide a way to generate timezones from the source and ship them with your JS or native app. It’s an important feature for me.

To generate timezone files use the included tool:
```
nim c -r tools/generate.nim json --startYear:2010 --endYear:2030 --includeOnly:"utc,America/Los_Angeles,America/New_York,America/Chicago,Europe/Dublin"
```

You need to include or load the timezones:

```
const tzData = staticRead("../tzdata/tzdata.json")
loadTzData(tzData)
```

## Parse Timestamps

```Nim
var ts = parseTs(
  "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
  "1988-02-09T03:34:12Z"
)
```

## Format Timestamps

```Nim
echo format(
  ts,
  "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
)
```

## Manipulate Calendars

```Nim
var cal = Calendar(year: 2013, month: 12, day: 31, hour: 59, minute: 59, second: 59)
cal.add(Second, 20)
cal.sub(Minute, 15)
cal.add(Day, 40)
cal.sub(Month, 120)
cal.toStartOf(Day)
cal.toEndOf(Month)
```

## Use Timezones

```Nim
echo format(
    ts,
    "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
    tzName = "America/Los_Angeles"
)
```

Include only the timezones and years you need:

```Nim
# The year range you want to include
const startYear = 1970
const endYear = 2030
# Add only time zones you want to include here:
const includeOnly: seq[string] = @[
  "utc",
  "America/Los_Angeles",
  "America/New_York"
]
```
Then just run `nimble generate`

## Only ship the Timezones you use.

Time zone information for the whole world is slightly more then a megabyte. But for most applications support every world time zone from 1970 to 2060 is a bit much. You can easily cut down the data generated by running the generate tool:

```
generate json --startYear:2010 --endYear:2030 --includeOnly:"utc,America/Los_Angeles,America/New_York,America/Chicago,Europe/Dublin"
```

To just a couple of kilobytes. This is really important for JS backend where you ship the information to the clients.
