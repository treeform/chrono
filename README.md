# Chrono a Timestamps, Calendars, and Timezones library for nim.

Documentation: https://treeform.github.io/chrono/

Works in c as well as in javascript! All calendar manipulations! Include only the timezones and years you need!

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
cal.add(Second, 20)
cal.sub(Minute, 15)
cal.add(Day, 40)
cal.sub(Month, 120)
cal.toStartOf(Day)
cal.toEndOf(Month)
```

## Use Timezones

```Nim
echo formatTs(
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
Then just run `nim c -r tools/generate`

More: https://treeform.github.io/chrono/
