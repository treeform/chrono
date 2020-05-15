import snappy

template compress*(src: string): string =
  cast[string](snappy.encode(cast[seq[byte]](src)))

template uncompress*(src: string): string =
  cast[string](snappy.decode(cast[seq[byte]](src)))
