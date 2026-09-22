// The tray menu on Windows, opened the way the platform needs it opened.
//
// nativeapi opens the tray's menu with `TrackPopupMenu` owned by its host
// window, and that window is message-only (`HWND_MESSAGE`): it can never be the
// foreground window. A menu whose owner is not in the foreground is closed the
// moment the foreground changes — and a click on the tray leaves the taskbar
// there — so the menu flashed its border and was gone (0.0.8, Windows). What
// Microsoft documents for a notification-area menu is an owner that *can* take
// the foreground: `SetForegroundWindow` on it, then `TrackPopupMenu`, then a
// `WM_NULL` posted to it so the menu closes when the user clicks elsewhere.
//
// The menu is still nativeapi's (its `HMENU`, its items); only the owner and
// the call are this file's. The choice comes back from `TrackPopupMenu` itself
// (`TPM_RETURNCMD`), so no `WM_COMMAND` goes anywhere and the caller runs the
// item.
import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// A cursor position, as `GetCursorPos` fills it.
final class _Point extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;
}

typedef _GetCursorPosC = Int32 Function(Pointer<_Point> point);
typedef _GetCursorPosDart = int Function(Pointer<_Point> point);
typedef _HwndC = Int32 Function(Pointer<Void> hwnd);
typedef _HwndDart = int Function(Pointer<Void> hwnd);
typedef _TrackPopupMenuC = Int32 Function(
  Pointer<Void> menu,
  Uint32 flags,
  Int32 x,
  Int32 y,
  Int32 reserved,
  Pointer<Void> hwnd,
  Pointer<Void> rect,
);
typedef _TrackPopupMenuDart = int Function(
  Pointer<Void> menu,
  int flags,
  int x,
  int y,
  int reserved,
  Pointer<Void> hwnd,
  Pointer<Void> rect,
);
typedef _PostMessageC = Int32 Function(
  Pointer<Void> hwnd,
  Uint32 message,
  IntPtr wParam,
  IntPtr lParam,
);
typedef _PostMessageDart = int Function(
  Pointer<Void> hwnd,
  int message,
  int wParam,
  int lParam,
);
typedef _CreateWindowExC = Pointer<Void> Function(
  Uint32 exStyle,
  Pointer<Utf16> className,
  Pointer<Utf16> windowName,
  Uint32 style,
  Int32 x,
  Int32 y,
  Int32 width,
  Int32 height,
  Pointer<Void> parent,
  Pointer<Void> menu,
  Pointer<Void> instance,
  Pointer<Void> param,
);
typedef _CreateWindowExDart = Pointer<Void> Function(
  int exStyle,
  Pointer<Utf16> className,
  Pointer<Utf16> windowName,
  int style,
  int x,
  int y,
  int width,
  int height,
  Pointer<Void> parent,
  Pointer<Void> menu,
  Pointer<Void> instance,
  Pointer<Void> param,
);

const int _wsExToolWindow = 0x00000080;
const int _wsPopup = 0x80000000;
const int _tpmRightButton = 0x0002;
const int _tpmBottomAlign = 0x0020;
const int _tpmNoNotify = 0x0080;
const int _tpmReturnCmd = 0x0100;
const int _wmNull = 0x0000;

/// Opens a menu at the cursor from an owner that can take the foreground.
final class WindowsTrayMenu {
  new _(
    this._owner,
    this._getCursorPos,
    this._setForeground,
    this._track,
    this._post,
    this._destroy,
  );

  /// The popup for this process, or null when user32 could not give one.
  static WindowsTrayMenu? create() {
    final user32 = DynamicLibrary.open('user32.dll');
    final createWindow = user32
        .lookupFunction<_CreateWindowExC, _CreateWindowExDart>(
          'CreateWindowExW',
        );
    final className = 'STATIC'.toNativeUtf16();
    final name = ''.toNativeUtf16();
    // A top-level window, never shown: a tool window stays off the taskbar,
    // and a predefined class needs no window procedure of its own.
    final owner = createWindow(
      _wsExToolWindow,
      className,
      name,
      _wsPopup,
      0,
      0,
      0,
      0,
      nullptr,
      nullptr,
      nullptr,
      nullptr,
    );
    calloc
      ..free(className)
      ..free(name);
    if (owner == nullptr) return null;
    return WindowsTrayMenu._(
      owner,
      user32.lookupFunction<_GetCursorPosC, _GetCursorPosDart>('GetCursorPos'),
      user32.lookupFunction<_HwndC, _HwndDart>('SetForegroundWindow'),
      user32.lookupFunction<_TrackPopupMenuC, _TrackPopupMenuDart>(
        'TrackPopupMenu',
      ),
      user32.lookupFunction<_PostMessageC, _PostMessageDart>('PostMessageW'),
      user32.lookupFunction<_HwndC, _HwndDart>('DestroyWindow'),
    );
  }

  final Pointer<Void> _owner;
  final _GetCursorPosDart _getCursorPos;
  final _HwndDart _setForeground;
  final _TrackPopupMenuDart _track;
  final _PostMessageDart _post;
  final _HwndDart _destroy;

  /// Opens [menu] (an `HMENU`) at the cursor and waits for the choice: the
  /// chosen item's id, or 0 when the menu was dismissed.
  int open(Pointer<Void> menu) {
    final point = calloc<_Point>();
    try {
      _getCursorPos(point);
      _setForeground(_owner);
      final chosen = _track(
        menu,
        _tpmRightButton | _tpmBottomAlign | _tpmNoNotify | _tpmReturnCmd,
        point.ref.x,
        point.ref.y,
        0,
        _owner,
        nullptr,
      );
      // So the next click outside the menu closes it (the `TrackPopupMenu`
      // remarks).
      _post(_owner, _wmNull, 0, 0);
      return chosen;
    } finally {
      calloc.free(point);
    }
  }

  /// Releases the owner window.
  void dispose() => _destroy(_owner);
}
