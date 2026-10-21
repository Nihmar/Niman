/// A file's creation time on a Mac (#759, docs/records/apple-platforms.md).
///
/// APFS keeps a birth time, and the atomic save loses it as Windows' does:
/// the note renamed over is the temp file, born at the save. `dart:io` does
/// not report it — a stat's `changed` is the inode's change time there — so
/// it is read and written through `getattrlist` and `setattrlist`
/// (`ATTR_CMN_CRTIME`), with no plugin, as Windows' goes through `kernel32`.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// [path]'s creation time, or null off macOS or where it cannot be read.
DateTime? macCreationTime(String path) {
  final api = _LibSystem.instance;
  if (api == null) return null;
  return using((arena) {
    final list = _attributeList(arena);
    // The answer: its own length (u_int32), then the timespec, packed.
    final buffer = arena<Uint8>(_answerBytes);
    final failed = api.getattrlist(
      path.toNativeUtf8(allocator: arena),
      list,
      buffer.cast(),
      _answerBytes,
      _noFollow,
    );
    if (failed != 0) return null;
    final data = ByteData.sublistView(buffer.asTypedList(_answerBytes));
    final seconds = data.getInt64(4, Endian.host);
    final nanos = data.getInt64(12, Endian.host);
    return DateTime.fromMicrosecondsSinceEpoch(
      seconds * Duration.microsecondsPerSecond + nanos ~/ 1000,
    );
  });
}

/// Sets [path]'s creation time to [created], leaving its other times
/// alone; answers whether it did. False off macOS.
bool setMacCreationTime(String path, DateTime created) {
  final api = _LibSystem.instance;
  if (api == null) return false;
  return using((arena) {
    final list = _attributeList(arena);
    final micros = created.microsecondsSinceEpoch;
    final time = arena<Int64>(2)
      ..[0] = micros ~/ Duration.microsecondsPerSecond
      ..[1] = (micros % Duration.microsecondsPerSecond) * 1000;
    return api.setattrlist(
          path.toNativeUtf8(allocator: arena),
          list,
          time.cast(),
          _timespecBytes,
          _noFollow,
        ) ==
        0;
  });
}

/// `struct attrlist` asking for the common attribute `ATTR_CMN_CRTIME`:
/// a u_short bitmap count and a reserved u_int16, then five 32-bit groups.
Pointer<Void> _attributeList(Allocator arena) {
  final list = arena<Uint8>(_attributeListBytes);
  ByteData.sublistView(list.asTypedList(_attributeListBytes))
    ..setUint16(0, _attrBitMapCount, Endian.host)
    ..setUint16(2, 0, Endian.host)
    ..setUint32(4, _attrCmnCrtime, Endian.host)
    ..setUint32(8, 0, Endian.host)
    ..setUint32(12, 0, Endian.host)
    ..setUint32(16, 0, Endian.host)
    ..setUint32(20, 0, Endian.host);
  return list.cast();
}

const int _attrBitMapCount = 5;
const int _attrCmnCrtime = 0x00000200;
const int _attributeListBytes = 24;
const int _timespecBytes = 16;
const int _answerBytes = 4 + _timespecBytes;

/// `FSOPT_NOFOLLOW`: a symlink's own times, not its target's.
const int _noFollow = 0x00000001;

typedef _AttrListC = Int32 Function(
  Pointer<Utf8>,
  Pointer<Void>,
  Pointer<Void>,
  Size,
  Uint32,
);
typedef _AttrListDart = int Function(
  Pointer<Utf8>,
  Pointer<Void>,
  Pointer<Void>,
  int,
  int,
);

final class _LibSystem {
  new _(DynamicLibrary lib)
    : getattrlist = lib.lookupFunction<_AttrListC, _AttrListDart>(
        'getattrlist',
      ),
      setattrlist = lib.lookupFunction<_AttrListC, _AttrListDart>(
        'setattrlist',
      );

  static final _LibSystem? instance = Platform.isMacOS
      ? _LibSystem._(DynamicLibrary.process())
      : null;

  final _AttrListDart getattrlist;
  final _AttrListDart setattrlist;
}
