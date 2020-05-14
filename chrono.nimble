# Package
version       = "0.2.0"
author        = "Andre von Houck"
description   = "Calendars, Timestamps and Timezones utilities."
license       = "MIT"

srcDir = "src"

# Dependencies

requires "nim >= 1.2.0"
requires "snappy >= 0.1.0"

skipDirs = @["tests", "tools"]

task generate, "Generate timezone bins from raw data":
  exec "nim c -r tools/generate all"

task docs, "Generate docs":
  exec "nim doc -o:docs/index.html chrono.nim"
