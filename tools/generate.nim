import ../chrono/snappyutils, algorithm, json, os, osproc, parsecsv, parseopt,
    streams, strutils

include ../chrono/calendars
include ../chrono/timestamps
include ../chrono/timezones

const doc = """

Generate your own packed timezone file.

Generate all timezones in bin and json:

  generate all

Generate only the years you want:

  generate all --startYear:2010 --endYear:2030

Generate only the timezones you want

  generate all --includeOnly:"utc,America/Los_Angeles,America/New_York,America/Chicago,Europe/Dublin"

Generate only the json data files:

  generate json

All together:

  generate.nim json --startYear:2010 --endYear:2030 --includeOnly:"utc,America/Los_Angeles,America/New_York,America/Chicago,Europe/Dublin"
"""

var startYearTs = Calendar(year: 1970, month: 1, day: 1).ts
var endYearTs = Calendar(year: 2060, month: 1, day: 1).ts
var includeOnly: seq[string] = @[]

const timeZoneFiles = @[
  "africa",
  "antarctica",
  "asia",
  "australasia",
  "europe",
  "northamerica",
  "southamerica",
  # "pacificnew", # some leagal thing
    # "etcetera",   # mostly present for historical reasons
    # "backward",   # historical renames
    # "backzone"    # historical timezones pre-1970
]

proc runCommand(cmd: string) =
  echo "running: ", cmd
  let ret = execCmdEx(cmd)
  if ret.exitCode != 0:
    echo "Command failed:"
    echo ret.output
    quit()

proc catCommand(cmd: string): string =
  echo "running: ", cmd
  let ret = execCmdEx(cmd)
  if ret.exitCode != 0:
    echo "Command failed:"
    echo ret.output
    quit()
  return ret.output

proc fetchAndCompileTzDb() =
  if not dirExists("tz"):
    echo "It looks like you don't have https://github.com/eggert/tz checkedout"
    runCommand("git clone https://github.com/eggert/tz")
  else:
    runCommand("cd tz; git pull origin master")

  if not dirExists("tz/zic") or not dirExists("tz/zdump"):
    runCommand("cd tz; make")

  runCommand("cd tz; zic -d zic_out " & timeZoneFiles.join(" "))

proc dumpToCsvFiles() =
  let timezones = open("tzdata/timezones.csv", fmWrite)
  let dstchanges = open("tzdata/dstchanges.csv", fmWrite)

  var files = newSeq[string]()
  for file in walkDirRec("tz/zic_out/"):

    if not file[11..^1].contains("/"):
      # ignore non contenental timezones
      #CET CST6CDT EET EST EST5EDT ...
      continue

    files.add(file)
  files.sort(system.cmp)

  for tzId, file in files:
    timezones.write("\"" & $tzId & "\",\"" & "" & "\",\"" & file[11..^1] & "\"\n")
    var prevDstName = ""
    var prevOffset = 0
    # zdump can only do absolute paths
    let output = catCommand("tz/zdump -v -c 2060 " & getCurrentDir() & "/" & file)

    for rawLine in output.split("\L"):
      let line = rawLine.replace(getCurrentDir() & "/tz/zic_out/", "")
      if "NULL" in line or line.len == 0:
        continue
      let parts = line.splitWhitespace()
      let dstName = parts[13]
      let offset = parseInt(parts[15].split("=")[1])
      let date = parts[2..5].join(" ")
      let isDst = parseInt(parts[14].split("=")[1])
      if prevDstName == dstName and prevOffset == offset:
        continue
      let ts = parseTs("{month/n/3} {day} {hour/2}:{minute/2}:{second/2} {year}", date)
      let csvLine = "\"" & $tzId & "\",\"" & dstName & "\",\"" & $(int64(ts)) &
          "\",\"" & $offset & "\",\"" & $isDst & "\"\n"

      dstchanges.write(csvLine)

      prevDstName = dstName
      prevOffset = offset

  timezones.close()
  dstchanges.close()

iterator readCvs*(fileName: string, readHeader = false): CsvRow =
  var p: CsvParser
  p.open(fileName)
  if readHeader:
    p.readHeaderRow()
  while p.readRow():
    yield p.row
  p.close()

proc csvToBin() =
  var timeZones = newSeq[TimeZone]()
  var dstChanges = newSeq[DstChange]()

  block:
    for row in readCvs("tzdata/timezones.csv"):
      timeZones.add TimeZone(
        id: int16 parseInt(row[0]),
        name: pack[32](row[2]),
        )

    timeZones.sort do (x, y: TimeZone) -> int:
      result = cmp($x.name, $y.name)

    var f = newStringStream()
    f.writeData(cast[pointer](addr timeZones[0]), timeZones.len * sizeOf(TimeZone))
    f.setPosition(0)
    let zdata = compress(f.readAll())
    writeFile("tzdata/timezones.bin", zdata)
    echo "written file tzdata/timezones.bin ", zdata.len div 1024, "k"

  block:
    var prevDst = DstChange()
    var dst = DstChange()
    var zoneDsts = newSeq[DstChange]()

    proc dumpZone() =
      var startI = 0
      var endI = zoneDsts.len
      for i, innerDst in zoneDsts:
        if Timestamp(innerDst.start) < startYearTs:
          startI = i
        if Timestamp(dst.start) > endYearTs and endI > i:
          endI = i
      if startI > 0:
        dec startI
      for innerDst in zoneDsts[startI..<endI]:
        dstChanges.add(innerDst)

      zoneDsts = newSeq[DstChange]()

    for row in readCvs("tzdata/dstchanges.csv"):
      dst = DstChange(
        tzId: int16 parseInt(row[0]),
        name: pack[6](row[1]),
        start: float64 parseFloat(row[2]),
        offset: int32 parseInt(row[3])
      )

      if prevDst.tzId != dst.tzId:
        dumpZone()

      zoneDsts.add(dst)
      prevDst = dst

    dumpZone()

    echo "dst transitoins: ", dstChanges.len

    var f = newStringStream()
    f.writeData(cast[pointer](addr dstChanges[0]), dstChanges.len * sizeOf(DstChange))
    f.setPosition(0)
    let zdata = compress(f.readAll())
    writeFile("tzdata/dstchanges.bin", zdata)
    echo "written file tzdata/dstchanges.bin ", zdata.len div 1024, "k"

proc csvToJson() =
  type TimeZoneWithStr = object
    id: int
    name: string
  type DstChangeWithStr = object
    tzId: int
    name: string
    start: float
    offset: int

  var timeZones = newSeq[TimeZoneWithStr]()
  var dstChanges = newSeq[DstChangeWithStr]()
  var zoneIds = newSeq[int]()

  block:
    for row in readCvs("tzdata/timezones.csv"):
      if includeOnly.len == 0 or row[2] in includeOnly:
        timeZones.add TimeZoneWithStr(
          id: parseInt(row[0]),
          name: row[2],
          )
        zoneIds.add(parseInt(row[0]))

    timeZones.sort do (x, y: TimeZoneWithStr) -> int:
      result = cmp(x.name, y.name)

    let timeZonesJsonData = $ %*(timeZones)
    writeFile("tzdata/timezones.json", timeZonesJsonData)
    echo "written file tzdata/timezones.json ", timeZonesJsonData.len div 1024, "k"

  block:
    var prevDst = DstChangeWithStr()
    var dst = DstChangeWithStr()
    var zoneDsts = newSeq[DstChangeWithStr]()

    proc dumpZone() =
      var startI = 0
      var endI = zoneDsts.len
      for i, innerDst in zoneDsts:
        if Timestamp(innerDst.start) < startYearTs:
          startI = i
        if Timestamp(innerDst.start) > endYearTs and endI > i:
          endI = i
      if startI > 0:
        dec startI
      for innerDst in zoneDsts[startI..<endI]:
        dstChanges.add(innerDst)

      zoneDsts = newSeq[DstChangeWithStr]()

    for row in readCvs("tzdata/dstchanges.csv"):
      dst = DstChangeWithStr(
        tzId: parseInt(row[0]),
        name: row[1],
        start: parseFloat(row[2]),
        offset: parseInt(row[3])
      )

      if prevDst.tzId != dst.tzId:
        dumpZone()

      zoneDsts.add(dst)
      prevDst = dst

    dumpZone()

    var dstChangesAllowed = newSeq[DstChangeWithStr]()
    for dst in dstChanges:
      if dst.tzId in zoneIds:
        dstChangesAllowed.add(dst)

    echo "dst transitoins: ", dstChangesAllowed.len

    let dstJsonData = $ %*dstChangesAllowed
    writeFile("tzdata/dstchanges.json", dstJsonData)
    echo "written file tzdata/dstchanges.json ", dstJsonData.len div 1024, "k"

when isMainModule:
  var action = "all"
  for kind, key, val in getopt():
    if kind == cmdArgument:
      action = key
    if kind == cmdLongOption:
      case key
      of "startYear":
        startYearTs = Calendar(year: parseInt(val), month: 1, day: 1).ts
      of "endYear":
        endYearTs = Calendar(year: parseInt(val), month: 1, day: 1).ts
      of "includeOnly":
        includeOnly = val.split(",")
      else:
        quit("invalid option " & key)
    if kind == cmdShortOption:
      quit(doc)
  case action:
  of "help":
    quit(doc)
  of "all":
    fetchAndCompileTzDb()
    dumpToCsvFiles()
    csvToBin()
    csvToJson()
  of "fetch":
    fetchAndCompileTzDb()
  of "dump":
    dumpToCsvFiles()
  of "bin":
    csvToBin()
  of "json":
    csvToJson()
  else:
    quit("invalid action " & action)
