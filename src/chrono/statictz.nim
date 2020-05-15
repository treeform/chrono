import timezones

import json
const zoneDataJsonData = staticRead("../tzdata/timezones.json")
const dstDataJsonData = staticRead("../tzdata/dstchanges.json")

for jsonZone in parseJson(zoneDataJsonData):
  tzs.add TimeZone(
    id: int16 jsonZone["id"].getInt(),
    name: jsonZone["name"].getStr()
  )
for jsonDst in parseJson(dstDataJsonData):
  dstChanges.add DstChange(
    tzId: int16 jsonDst["tzId"].getInt(),
    name: jsonDst["name"].getStr(),
    start: float64 jsonDst["start"].getFloat(),
    offset: int32 jsonDst["offset"].getInt()
  )
