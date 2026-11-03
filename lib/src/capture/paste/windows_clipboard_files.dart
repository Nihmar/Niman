/// The files on the Windows clipboard (#1249), read through user32 and
/// shell32 with no plugin: the `CF_HDROP` list Explorer's Copy writes, the
/// same structure a drop hands the runner (`windows/runner/drop_target.cpp`).
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:niman/src/capture/paste/clipboard_files.dart';

/// Reads `CF_HDROP` off the Windows clipboard.
final class WindowsClipboardFiles implements ClipboardFilesReader {
  /// The reader.
  new();

  final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
  final DynamicLibrary _shell32 = DynamicLibrary.open('shell32.dll');

  late final _FormatAvailableDart _formatAvailable = _user32
      .lookupFunction<_FormatAvailableC, _FormatAvailableDart>(
        'IsClipboardFormatAvailable',
      );
  late final _OpenClipboardDart _openClipboard = _user32
      .lookupFunction<_OpenClipboardC, _OpenClipboardDart>('OpenClipboard');
  late final _CloseClipboardDart _closeClipboard = _user32
      .lookupFunction<_CloseClipboardC, _CloseClipboardDart>('CloseClipboard');
  late final _GetDataDart _getData = _user32
      .lookupFunction<_GetDataC, _GetDataDart>('GetClipboardData');
  late final _DragQueryFileDart _dragQueryFile = _shell32
      .lookupFunction<_DragQueryFileC, _DragQueryFileDart>('DragQueryFileW');

  /// `CF_HDROP`: a standard format, the same number everywhere.
  static const int _cfHdrop = 15;

  /// `DragQueryFileW`'s index that asks for the count.
  static const int _count = 0xFFFFFFFF;

  @override
  Future<List<String>> read() async {
    if (_formatAvailable(_cfHdrop) == 0) return const [];
    // Another program may hold the clipboard for a moment — a clipboard
    // manager reading what was just copied: a few tries, a moment apart.
    for (var attempt = 0; attempt < _tries; attempt++) {
      if (_openClipboard(nullptr) != 0) {
        try {
          return _paths();
        } finally {
          _closeClipboard();
        }
      }
      await Future<void>.delayed(_pause);
    }
    return const [];
  }

  /// The list's paths, read while the clipboard is open. The handle is the
  /// clipboard's own: it is read, never freed (`DragFinish` is a drop's).
  List<String> _paths() {
    final drop = _getData(_cfHdrop);
    if (drop == nullptr) return const [];
    final count = _dragQueryFile(drop, _count, nullptr, 0);
    final paths = <String>[];
    for (var i = 0; i < count; i++) {
      final length = _dragQueryFile(drop, i, nullptr, 0);
      if (length <= 0) continue;
      final buffer = calloc<Uint16>(length + 1);
      try {
        if (_dragQueryFile(drop, i, buffer.cast(), length + 1) > 0) {
          paths.add(buffer.cast<Utf16>().toDartString());
        }
      } finally {
        calloc.free(buffer);
      }
    }
    return paths;
  }

  static const int _tries = 5;
  static const Duration _pause = Duration(milliseconds: 20);
}

typedef _FormatAvailableC = Int32 Function(Uint32 format);
typedef _FormatAvailableDart = int Function(int format);
typedef _OpenClipboardC = Int32 Function(Pointer<Void> owner);
typedef _OpenClipboardDart = int Function(Pointer<Void> owner);
typedef _CloseClipboardC = Int32 Function();
typedef _CloseClipboardDart = int Function();
typedef _GetDataC = Pointer<Void> Function(Uint32 format);
typedef _GetDataDart = Pointer<Void> Function(int format);
typedef _DragQueryFileC = Uint32 Function(
  Pointer<Void> drop,
  Uint32 index,
  Pointer<Utf16> file,
  Uint32 length,
);
typedef _DragQueryFileDart = int Function(
  Pointer<Void> drop,
  int index,
  Pointer<Utf16> file,
  int length,
);
