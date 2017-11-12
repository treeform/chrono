# Package

version       = "0.0.1"
author        = "Andre von Houck"
description   = "Calendars, Timestamps and Timezones utilities."
license       = "MIT"

# Dependencies

requires "nim >= 0.17.1"

skipDirs = @["tests"]

task test, "Runs the test suite":
  exec "nim c -r tests/tests"
