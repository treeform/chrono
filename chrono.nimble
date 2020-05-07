# Package
version       = "0.1.0"
author        = "Andre von Houck"
description   = "Calendars, Timestamps and Timezones utilities."
license       = "MIT"

srcDir = "src"

# Dependencies

requires "nim >= 0.17.1"
requires "zip >= 0.1.1"
requires "miniz >= 0.1.0"

skipDirs = @["tests", "tools"]

task generate, "Generate timezone bins from raw data":
  exec "nim c -r tools/generate"

task docs, "Generate docs":
  exec "nim doc -o:docs/index.html chrono.nim"
