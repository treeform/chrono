import timezones

when not defined(js):
  import streams, snappyutils

  const zoneDataZip = staticRead("../tzdata/timezones.bin")
  const dstDataZip = staticRead("../tzdata/dstchanges.bin")

  var zoneData = uncompress(zoneDataZip)
  var dstData = uncompress(dstDataZip)

  timezones.tzs = newSeq[TimeZone](zoneData.len div sizeof(TimeZone)) ## List of all timezones
  timezones.dstChanges = newSeq[DstChange](dstData.len div sizeof(DstChange)) ## List of all DST changes

  var zoneStream = newStringStream(zoneData)
  for i in 0 ..< timezones.tzs.len:
    var dummyZone = TimeZone()
    discard zoneStream.readData(cast[pointer](addr dummyZone), sizeof(TimeZone))
    timezones.tzs[i] = dummyZone

  var dstStream = newStringStream(dstData)
  for i in 0..<dstChanges.len:
    var dummyDst = DstChange()
    discard dstStream.readData(cast[pointer](addr dummyDst), sizeof(DstChange))
    dstChanges[i] = dummyDst

else:
  import json
  const zoneDataJsonData = staticRead("../tzdata/timezones.json")
  const dstDataJsonData = staticRead("../tzdata/dstchanges.json")

  for jsonZone in parseJson(zoneDataJsonData):
    tzs.add TimeZone(
      id: int16 jsonZone["id"].getInt(),
      name: pack[32](jsonZone["name"].getStr())
    )
  for jsonDst in parseJson(dstDataJsonData):
    dstChanges.add DstChange(
      tzId: int16 jsonDst["tzId"].getInt(),
      name: pack[6](jsonDst["name"].getStr()),
      start: float64 jsonDst["start"].getFloat(),
      offset: int32 jsonDst["offset"].getInt()
    )
