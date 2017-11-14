# Chrono a Timestamps, Calendars, and Timezones library for nim.

Documentation: https://treeform.github.io/chrono/

## Parse Timestamps

```Nim
var ts = parseTs(
  "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
  "1988-02-09T03:34:12Z"
)
```

## Format Timestamps

```Nim
echo formatTs(
  ts,
  "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
)
```

## Manipulate Calendars

```Nim
var cal = Calendar(year: 2013, month: 12, day: 31, hour: 59, minute: 59, second: 59)
cal.addSeconds(20)
cal.subMinutes(15)
cal.addDays(40)
cal.subMonths(120)
```

## Use Timezones

```Nim
echo formatTs(
    ts,
    "{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second/2}Z",
    tzName = "America/Los_Angeles"
)
```

More: https://treeform.github.io/chrono/
