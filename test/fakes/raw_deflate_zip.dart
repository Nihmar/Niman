import 'dart:convert';
import 'dart:typed_data';

/// A zip holding one entry whose content is the raw deflate stream [deflated]
/// exactly as given (no encoder re-compresses it), with the size the central
/// directory declares set to [declared] — a bomb's shape, or a broken stream,
/// which an encoder would never write.
Uint8List rawDeflateZip(
  String name,
  List<int> deflated, {
  required int declared,
  int method = 8,
}) {
  final nameBytes = utf8.encode(name);
  final local = BytesBuilder()
    ..add(_u32(0x04034b50))
    ..add(_u16(20))
    ..add(_u16(0))
    ..add(_u16(method))
    ..add(_u16(0))
    ..add(_u16(0))
    ..add(_u32(0))
    ..add(_u32(deflated.length))
    ..add(_u32(declared))
    ..add(_u16(nameBytes.length))
    ..add(_u16(0))
    ..add(nameBytes)
    ..add(deflated);
  final central = BytesBuilder()
    ..add(_u32(0x02014b50))
    ..add(_u16(20))
    ..add(_u16(20))
    ..add(_u16(0))
    ..add(_u16(method))
    ..add(_u16(0))
    ..add(_u16(0))
    ..add(_u32(0))
    ..add(_u32(deflated.length))
    ..add(_u32(declared))
    ..add(_u16(nameBytes.length))
    ..add(_u16(0))
    ..add(_u16(0))
    ..add(_u16(0))
    ..add(_u16(0))
    ..add(_u32(0))
    ..add(_u32(0))
    ..add(nameBytes);
  final end = BytesBuilder()
    ..add(_u32(0x06054b50))
    ..add(_u16(0))
    ..add(_u16(0))
    ..add(_u16(1))
    ..add(_u16(1))
    ..add(_u32(central.length))
    ..add(_u32(local.length))
    ..add(_u16(0));
  return (BytesBuilder()
        ..add(local.toBytes())
        ..add(central.toBytes())
        ..add(end.toBytes()))
      .toBytes();
}

Uint8List _u16(int v) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, v, .little);

Uint8List _u32(int v) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, v, .little);

/// A raw deflate stream of [blocks] stored blocks of [size] zero bytes each,
/// none of them final, and then a block of the reserved type: the stream
/// expands to `blocks * size` bytes and is invalid past that. An inflate that
/// runs the stream out fails on the last block; one that stops at a budget
/// before it never reads it. [size] is at most 65535, a stored block's limit.
Uint8List storedZerosThenInvalid({required int blocks, required int size}) {
  final out = BytesBuilder();
  for (var i = 0; i < blocks; i++) {
    // BFINAL = 0, BTYPE = 0 (stored), then LEN and its complement.
    out
      ..addByte(0)
      ..add(_u16(size))
      ..add(_u16(~size & 0xffff))
      ..add(Uint8List(size));
  }
  // BFINAL = 1, BTYPE = 3: the reserved block type.
  out.addByte(0x07);
  return out.toBytes();
}
