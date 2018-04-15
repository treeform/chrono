# Package

version       = "0.0.5"
author        = "Andre von Houck"
description   = "Calendars, Timestamps and Timezones utilities."
license       = "MIT"

# Dependencies

requires "nim >= 0.17.1"
requires "zip >= 0.1.1"

skipDirs = @["tests", "tools"]

task test, "Runs the test suite":
  exec "nim c -r tests/tests"

task generate, "Generate timezone bins from raw data":
  exec "nim c -r tools/generate"
