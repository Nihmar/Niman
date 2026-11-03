/// The files on the Windows clipboard (#1249), read through user32 and
/// shell32 with no plugin: the `CF_HDROP` list Explorer's Copy writes, the
/// same structure a drop hands the runner (`windows/runner/drop_target.cpp`).
///
/// With no list, a picture with no text beside it — the Snipping Tool's
/// capture, a browser's Copy image — is read as one file: the `PNG` format
/// those write, or else the `CF_DIB` every bitmap is offered as, made a
/// BMP and then a PNG (`clipboard_picture.dart`).
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:niman/src/capture/paste/clipboard_files.dart';
import 'package:niman/src/capture/paste/clipboard_picture.dart';

/// Reads `CF_HDROP`, or a picture, off the Windows clipboard.
final class WindowsClipboardFiles implements ClipboardFilesReader {
  /// The reader.
  new();

  final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
  final DynamicLibrary _shell32 = DynamicLibrary.open('shell32.dll');
  final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

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
  late final _RegisterFormatDart _registerFormat = _user32
      .lookupFunction<_RegisterFormatC, _RegisterFormatDart>(
        'RegisterClipboardFormatW',
      );
  late final _GlobalLockDart _globalLock = _kernel32
      .lookupFunction<_GlobalLockC, _GlobalLockDart>('GlobalLock');
  late final _GlobalUnlockDart _globalUnlock = _kernel32
      .lookupFunction<_GlobalUnlockC, _GlobalUnlockDart>('GlobalUnlock');
  late final _GlobalSizeDart _globalSize = _kernel32
      .lookupFunction<_GlobalSizeC, _GlobalSizeDart>('GlobalSize');

  /// The `PNG` format the Snipping Tool and the browsers write: registered
  /// by name, so its number is this session's.
  late final int _png = _register('PNG');

  int _register(String name) {
    final native = name.toNativeUtf16();
    try {
      return _registerFormat(native);
    } finally {
      calloc.free(native);
    }
  }

  /// `CF_HDROP`: a standard format, the same number everywhere.
  static const int _cfHdrop = 15;

  /// `CF_DIB`, `CF_UNICODETEXT`: standard formats too.
  static const int _cfDib = 8;
  static const int _cfUnicodeText = 13;

  /// `DragQueryFileW`'s index that asks for the count.
  static const int _count = 0xFFFFFFFF;

  @override
  Future<List<String>> read() async {
    if (_formatAvailable(_cfHdrop) != 0) {
      return await _whileOpen(_paths) ?? const [];
    }
    // A spreadsheet's cells come with a picture of themselves: with text
    // beside it, the paste is the text's (#1248).
    if (_formatAvailable(_cfUnicodeText) != 0) return const [];
    final png = _png != 0 && _formatAvailable(_png) != 0;
    if (!png && _formatAvailable(_cfDib) == 0) return const [];
    final bytes = await _whileOpen(() => _block(png ? _png : _cfDib));
    if (bytes == null) return const [];
    final picture = png ? trimmedPng(bytes) : await _pngOfDib(bytes);
    if (picture == null) return const [];
    return [await keepClipboardPicture(picture)];
  }

  Future<Uint8List?> _pngOfDib(Uint8List dib) async {
    final bmp = bmpOfDib(dib);
    return bmp == null ? null : await pngOf(bmp);
  }

  /// [read]'s answer, read while the clipboard is open, or null when it
  /// never opened. Another program may hold the clipboard for a moment — a
  /// clipboard manager reading what was just copied: a few tries, a moment
  /// apart.
  Future<T?> _whileOpen<T>(T Function() read) async {
    for (var attempt = 0; attempt < _tries; attempt++) {
      if (_openClipboard(nullptr) != 0) {
        try {
          return read();
        } finally {
          _closeClipboard();
        }
      }
      await Future<void>.delayed(_pause);
    }
    return null;
  }

  /// A copy of the bytes the clipboard holds in [format], read while it is
  /// open; the handle stays the clipboard's.
  Uint8List? _block(int format) {
    final handle = _getData(format);
    if (handle == nullptr) return null;
    final data = _globalLock(handle);
    if (data == nullptr) return null;
    try {
      final size = _globalSize(handle);
      if (size <= 0) return null;
      return Uint8List.fromList(data.asTypedList(size));
    } finally {
      _globalUnlock(handle);
    }
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
typedef _RegisterFormatC = Uint32 Function(Pointer<Utf16> name);
typedef _RegisterFormatDart = int Function(Pointer<Utf16> name);
typedef _GlobalLockC = Pointer<Uint8> Function(Pointer<Void> memory);
typedef _GlobalLockDart = Pointer<Uint8> Function(Pointer<Void> memory);
typedef _GlobalUnlockC = Int32 Function(Pointer<Void> memory);
typedef _GlobalUnlockDart = int Function(Pointer<Void> memory);
typedef _GlobalSizeC = IntPtr Function(Pointer<Void> memory);
typedef _GlobalSizeDart = int Function(Pointer<Void> memory);
