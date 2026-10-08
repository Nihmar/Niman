/// The clipboard's HTML on Windows (#531), read through user32 and
/// kernel32 with no plugin: the `HTML Format` block the browsers write,
/// its offsets and its `SourceURL` read by `cf_html.dart`.
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:niman/src/capture/paste/cf_html.dart';
import 'package:niman/src/capture/paste/clipboard_html.dart';

/// Reads the `HTML Format` block off the Windows clipboard.
final class WindowsClipboardHtml implements ClipboardHtmlReader {
  /// The reader.
  new();

  final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
  final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

  late final _RegisterFormatDart _registerFormat = _user32
      .lookupFunction<_RegisterFormatC, _RegisterFormatDart>(
        'RegisterClipboardFormatW',
      );
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
  late final _GlobalLockDart _globalLock = _kernel32
      .lookupFunction<_GlobalLockC, _GlobalLockDart>('GlobalLock');
  late final _GlobalUnlockDart _globalUnlock = _kernel32
      .lookupFunction<_GlobalUnlockC, _GlobalUnlockDart>('GlobalUnlock');
  late final _GlobalSizeDart _globalSize = _kernel32
      .lookupFunction<_GlobalSizeC, _GlobalSizeDart>('GlobalSize');

  /// The format's number, the same for every process of the session.
  late final int _format = _register();

  int _register() {
    final name = 'HTML Format'.toNativeUtf16();
    try {
      return _registerFormat(name);
    } finally {
      calloc.free(name);
    }
  }

  @override
  Future<ClipboardHtml?> read() async {
    if (_format == 0 || _formatAvailable(_format) == 0) return null;
    // Another program may hold the clipboard for a moment — a clipboard
    // manager reading what was just copied: a few tries, a moment apart.
    for (var attempt = 0; attempt < _tries; attempt++) {
      if (_openClipboard(nullptr) != 0) {
        final Uint8List? bytes;
        try {
          bytes = _block();
        } finally {
          _closeClipboard();
        }
        if (bytes == null) return null;
        final block = parseCfHtml(bytes);
        return block == null ? null : clipboardHtmlOf(block);
      }
      await Future<void>.delayed(_pause);
    }
    return null;
  }

  /// The block's bytes, copied out of the clipboard's memory while it is
  /// open; null when it holds none.
  Uint8List? _block() {
    final handle = _getData(_format);
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

  static const int _tries = 5;
  static const Duration _pause = Duration(milliseconds: 20);
}

typedef _RegisterFormatC = Uint32 Function(Pointer<Utf16> name);
typedef _RegisterFormatDart = int Function(Pointer<Utf16> name);
typedef _FormatAvailableC = Int32 Function(Uint32 format);
typedef _FormatAvailableDart = int Function(int format);
typedef _OpenClipboardC = Int32 Function(Pointer<Void> owner);
typedef _OpenClipboardDart = int Function(Pointer<Void> owner);
typedef _CloseClipboardC = Int32 Function();
typedef _CloseClipboardDart = int Function();
typedef _GetDataC = Pointer<Void> Function(Uint32 format);
typedef _GetDataDart = Pointer<Void> Function(int format);
typedef _GlobalLockC = Pointer<Uint8> Function(Pointer<Void> memory);
typedef _GlobalLockDart = Pointer<Uint8> Function(Pointer<Void> memory);
typedef _GlobalUnlockC = Int32 Function(Pointer<Void> memory);
typedef _GlobalUnlockDart = int Function(Pointer<Void> memory);
typedef _GlobalSizeC = IntPtr Function(Pointer<Void> memory);
typedef _GlobalSizeDart = int Function(Pointer<Void> memory);
