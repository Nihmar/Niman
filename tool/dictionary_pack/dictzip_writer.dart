// dictzip, in pure Dart: a gzip file whose header lists where each chunk of
// the compressed data starts, so a reader inflates one chunk and not the file.
//
// dictzip compresses each chunk with zlib's Z_FULL_FLUSH: the chunk ends on a
// byte boundary, and the next one back-references nothing before it. `dart:io`
// only offers a sync flush, which keeps the window, but a *fresh* deflater per
// chunk starts with an empty one, and its sync flush ends in the same empty
// stored block (`00 00 FF FF`) a full flush writes. Each chunk is therefore
// inflatable alone, and the chunks run together are one valid deflate stream:
// a final empty block closes it, so `gunzip` and `dictunzip` read the file too.
import 'dart:io';
import 'dart:typed_data';

import 'record_io.dart';

/// What dictzip writes: 58315 bytes is the chunk size of the original tool,
/// the one whose worst-case compressed chunk still fits the table's 16 bits.
const int dictzipChunkLength = 58315;

/// The most a compressed chunk may take: its size is a 16-bit number.
const int _maxCompressedChunk = 0xffff;

/// The final empty block (fixed Huffman, nothing in it) that ends the stream.
const List<int> _finalBlock = [0x03, 0x00];

/// What [writeDictzip] wrote.
typedef DictzipResult = ({int uncompressed, int compressed, int chunks});

/// Compresses [source] into [target] as dictzip, streaming one chunk at a
/// time, and returns the sizes. [chunkLength] is the uncompressed size of a
/// chunk; the header's table holds at most 32762 chunks, so a file the
/// default chunk would overflow gets bigger chunks.
DictzipResult writeDictzip(
  File source,
  File target, {
  int chunkLength = dictzipChunkLength,
  String name = '',
}) {
  final length = source.lengthSync();
  const maxChunks = 32762;
  var size = chunkLength;
  if ((length + size - 1) ~/ size > maxChunks) {
    size = (length + maxChunks - 1) ~/ maxChunks;
  }
  if (size > 65000) {
    throw StateError('$length bytes do not fit a dictzip file.');
  }
  final chunks = length == 0 ? 1 : (length + size - 1) ~/ size;
  // The sizes are not known before the data is compressed: the data goes to
  // a file of its own, and the header is written ahead of it afterwards.
  final body = File('${target.path}.body');
  final sizes = <int>[];
  var crc = 0;
  final input = source.openSync();
  final out = BufferedFileWriter(body);
  try {
    final buffer = Uint8List(size);
    for (var index = 0; index < chunks; index++) {
      final read = _readFully(input, buffer);
      final chunk = Uint8List.sublistView(buffer, 0, read);
      crc = _crc32(chunk, crc);
      var packed = _deflateChunk(chunk);
      if (index == chunks - 1) {
        packed = Uint8List.fromList([...packed, ..._finalBlock]);
      }
      if (packed.length > _maxCompressedChunk) {
        throw StateError('A chunk of $read bytes packs to ${packed.length}.');
      }
      sizes.add(packed.length);
      out.write(packed);
    }
  } finally {
    input.closeSync();
    out.close();
  }
  final header = _header(size, sizes, name);
  final result = BufferedFileWriter(target)..write(header);
  final packedInput = body.openSync();
  try {
    final copy = Uint8List(1 << 20);
    for (;;) {
      final read = packedInput.readIntoSync(copy);
      if (read == 0) break;
      result.write(Uint8List.sublistView(copy, 0, read));
    }
  } finally {
    packedInput.closeSync();
  }
  final trailer = ByteData(8)
    ..setUint32(0, crc, Endian.little)
    ..setUint32(4, length & 0xffffffff, Endian.little);
  result
    ..write(trailer.buffer.asUint8List())
    ..close();
  body.deleteSync();
  return (
    uncompressed: length,
    compressed: target.lengthSync(),
    chunks: chunks,
  );
}

/// Fills [buffer] from [file], or as far as the file goes.
int _readFully(RandomAccessFile file, Uint8List buffer) {
  var filled = 0;
  while (filled < buffer.length) {
    final read = file.readIntoSync(buffer, filled);
    if (read == 0) break;
    filled += read;
  }
  return filled;
}

/// One chunk as raw deflate that ends on a byte boundary, standing alone.
Uint8List _deflateChunk(Uint8List chunk) {
  final filter = RawZLibFilter.deflateFilter(level: 9, raw: true)
    ..process(chunk, 0, chunk.length);
  final out = BytesBuilder(copy: false);
  for (;;) {
    final part = filter.processed();
    if (part == null || part.isEmpty) break;
    out.add(part);
  }
  return out.takeBytes();
}

/// The gzip header with dictzip's `RA` extra field and the file's [name].
Uint8List _header(int chunkLength, List<int> sizes, String name) {
  final fieldLength = 6 + 2 * sizes.length;
  final extraLength = 4 + fieldLength;
  final nameBytes = name.codeUnits;
  final bytes = BytesBuilder(copy: false)
    ..add([
      0x1f,
      0x8b,
      8,
      if (nameBytes.isEmpty) 4 else 4 | 8,
      0,
      0,
      0,
      0,
      0,
      3,
    ]);
  final extra = ByteData(10 + 2 * sizes.length)
    ..setUint16(0, extraLength, Endian.little)
    ..setUint8(2, 0x52)
    ..setUint8(3, 0x41)
    ..setUint16(4, fieldLength, Endian.little)
    ..setUint16(6, 1, Endian.little)
    ..setUint16(8, chunkLength, Endian.little);
  // Bytes 10 and 11 of the field hold the chunk count; the sizes follow.
  final table = ByteData(2 + 2 * sizes.length)
    ..setUint16(0, sizes.length, Endian.little);
  for (var i = 0; i < sizes.length; i++) {
    table.setUint16(2 + 2 * i, sizes[i], Endian.little);
  }
  bytes
    ..add(extra.buffer.asUint8List(0, 10))
    ..add(table.buffer.asUint8List());
  if (nameBytes.isNotEmpty) bytes.add([...nameBytes, 0]);
  return bytes.takeBytes();
}

/// A dictzip file's table, read back: what a reader of the format sees.
typedef DictzipTable = ({int chunkLength, List<int> sizes, int dataStart});

/// Reads the `RA` field of the dictzip file [bytes] begin with (its header
/// only is needed), or throws when it has none.
DictzipTable readDictzipTable(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  if (bytes.length < 12 || bytes[0] != 0x1f || bytes[1] != 0x8b) {
    throw const FormatException('Not a gzip file.');
  }
  final flags = bytes[3];
  if (flags & 4 == 0) throw const FormatException('No extra field.');
  final extraLength = data.getUint16(10, Endian.little);
  if (bytes[12] != 0x52 || bytes[13] != 0x41) {
    throw const FormatException('No RA subfield.');
  }
  final count = data.getUint16(20, Endian.little);
  final sizes = [
    for (var i = 0; i < count; i++) data.getUint16(22 + 2 * i, Endian.little),
  ];
  var end = 12 + extraLength;
  if (flags & 8 != 0) {
    while (bytes[end] != 0) {
      end++;
    }
    end++;
  }
  return (
    chunkLength: data.getUint16(18, Endian.little),
    sizes: sizes,
    dataStart: end,
  );
}

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 != 0 ? 0xedb88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

/// CRC-32 of [data], continuing from [crc] (0 to begin).
int _crc32(Uint8List data, int crc) {
  var c = crc ^ 0xffffffff;
  for (final byte in data) {
    c = _crcTable[(c ^ byte) & 0xff] ^ (c >> 8);
  }
  return c ^ 0xffffffff;
}
