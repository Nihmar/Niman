/// A note's creation time kept across the atomic save (#759).
///
/// Every save writes a temp file and renames it over the note. On Windows
/// the renamed file is the temp file, creation time and all — `MoveFileEx`
/// replacing an existing file does not carry the old one's over — so each
/// save made an old note brand new, and the tree's "Date created" order
/// (which reads the creation time Windows keeps, `createdOf`) put it first.
///
/// The fix is the one the rename leaves room for: just before it, the
/// note's creation time is written onto the temp file, through `kernel32`
/// with no plugin. A Mac loses it the same way and keeps it the same way,
/// through `setattrlist` (creation_time_mac.dart). Linux and Android keep
/// no creation time `dart:io` reports (the order falls back to the
/// modification time there), so on them [keepCreationTime] does nothing.
///
/// The calls are synchronous and run on whichever isolate saves, the UI's
/// included (the todo files, the attachment swap): three `kernel32` calls on
/// a local file, microseconds against the milliseconds an isolate to run
/// them would cost. A decided exception to the no-blocking-call rule
/// (#1143), listed with its reason in `test/unit/ui_isolate_io_test.dart`.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:niman/src/core/creation_time_mac.dart';

/// Writes [target]'s creation time onto [replacement], the file about to be
/// renamed over it, so the rename keeps it (#759).
///
/// Windows and macOS, and best effort: where [target] does not exist yet
/// (a new note) or either call fails, [replacement] keeps its own time and
/// the save goes on — a creation time is worth less than the save itself.
void keepCreationTime({required String target, required String replacement}) {
  if (Platform.isMacOS) {
    final created = macCreationTime(target);
    if (created != null) setMacCreationTime(replacement, created);
    return;
  }
  if (!Platform.isWindows) return;
  final created = readCreationTime(target);
  if (created == null) return;
  writeCreationTime(replacement, created);
}

/// The creation time of [path] as a Windows `FILETIME` (100 ns ticks since
/// 1601), or null where it cannot be read. Windows only.
int? readCreationTime(String path) {
  final api = _kernel32;
  return using((arena) {
    final data = arena<Uint32>(_attributeDataWords);
    final ok = api.getFileAttributesEx(
      path.toNativeUtf16(allocator: arena),
      _getFileExInfoStandard,
      data.cast(),
    );
    if (ok == 0) return null;
    // WIN32_FILE_ATTRIBUTE_DATA: the attributes, then ftCreationTime as
    // its low and high halves.
    return data[1] | (data[2] << 32);
  });
}

/// Sets the creation time of [path] to [fileTime] (a Windows `FILETIME`),
/// leaving its other times alone; answers whether it did. Windows only.
bool writeCreationTime(String path, int fileTime) {
  final api = _kernel32;
  return using((arena) {
    final handle = api.createFile(
      path.toNativeUtf16(allocator: arena),
      _fileWriteAttributes,
      _fileShareAll,
      nullptr,
      _openExisting,
      _fileAttributeNormal,
      nullptr,
    );
    if (handle.address == _invalidHandle) return false;
    try {
      final time = arena<Uint32>(2)
        ..[0] = fileTime & 0xFFFFFFFF
        ..[1] = (fileTime >> 32) & 0xFFFFFFFF;
      return api.setFileTime(handle, time.cast(), nullptr, nullptr) != 0;
    } finally {
      api.closeHandle(handle);
    }
  });
}

const int _getFileExInfoStandard = 0;

/// `WIN32_FILE_ATTRIBUTE_DATA` in 32-bit words: the attributes, three
/// `FILETIME`s and the size's two halves.
const int _attributeDataWords = 9;
const int _fileWriteAttributes = 0x100;
const int _fileShareAll = 0x1 | 0x2 | 0x4;
const int _openExisting = 3;
const int _fileAttributeNormal = 0x80;

/// `INVALID_HANDLE_VALUE`, -1 as a pointer-sized address.
final int _invalidHandle = sizeOf<IntPtr>() == 8 ? -1 : 0xFFFFFFFF;

typedef _GetAttributesC = Int32 Function(
  Pointer<Utf16> path,
  Int32 level,
  Pointer<Void> data,
);
typedef _GetAttributesDart = int Function(
  Pointer<Utf16> path,
  int level,
  Pointer<Void> data,
);
typedef _CreateFileC = Pointer<Void> Function(
  Pointer<Utf16> path,
  Uint32 access,
  Uint32 share,
  Pointer<Void> security,
  Uint32 disposition,
  Uint32 flags,
  Pointer<Void> template,
);
typedef _CreateFileDart = Pointer<Void> Function(
  Pointer<Utf16> path,
  int access,
  int share,
  Pointer<Void> security,
  int disposition,
  int flags,
  Pointer<Void> template,
);
typedef _SetFileTimeC = Int32 Function(
  Pointer<Void> handle,
  Pointer<Void> created,
  Pointer<Void> accessed,
  Pointer<Void> written,
);
typedef _SetFileTimeDart = int Function(
  Pointer<Void> handle,
  Pointer<Void> created,
  Pointer<Void> accessed,
  Pointer<Void> written,
);
typedef _CloseHandleC = Int32 Function(Pointer<Void> handle);
typedef _CloseHandleDart = int Function(Pointer<Void> handle);

/// The four `kernel32` calls, looked up once per isolate on first use —
/// only ever on Windows.
final _Kernel32 _kernel32 = _Kernel32(DynamicLibrary.open('kernel32.dll'));

final class _Kernel32 {
  new(DynamicLibrary library)
    : getFileAttributesEx = library
          .lookupFunction<_GetAttributesC, _GetAttributesDart>(
            'GetFileAttributesExW',
          ),
      createFile = library.lookupFunction<_CreateFileC, _CreateFileDart>(
        'CreateFileW',
      ),
      setFileTime = library.lookupFunction<_SetFileTimeC, _SetFileTimeDart>(
        'SetFileTime',
      ),
      closeHandle = library.lookupFunction<_CloseHandleC, _CloseHandleDart>(
        'CloseHandle',
      );

  final _GetAttributesDart getFileAttributesEx;
  final _CreateFileDart createFile;
  final _SetFileTimeDart setFileTime;
  final _CloseHandleDart closeHandle;
}
