// The tray menu on Windows, opened where it can stay open.
//
// nativeapi opens the tray's menu with `TrackPopupMenu` on the thread the tray
// event arrives on, which is Flutter's. The menu's modal loop then runs the
// engine's own messages and tasks too, and one of them dismisses it: the menu
// flashed its border and closed (0.0.8, Windows). Opened the same way from
// the same thread with an owner of its own, it still closed, 11 ms after the
// click with no error (`result 0, error 0` in the log) — the menu came up and
// was cancelled — while the same call in a process with no Flutter in it stays
// open until the user chooses.
//
// So the menu is opened on a thread of its own: a background isolate, which
// the VM runs on its own OS thread, makes an owner window there and runs
// `TrackPopupMenu` against it. What Microsoft documents for a notification-
// area menu is kept: `SetForegroundWindow` on the owner first, a `WM_NULL`
// posted to it after. The menu is still nativeapi's `HMENU` with its items; the
// choice comes back from `TrackPopupMenu` itself (`TPM_RETURNCMD`), so no
// `WM_COMMAND` goes anywhere and the caller runs the item.
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

/// What opening the menu gave: the chosen item's id, or 0 when it was
/// dismissed, and a line for the log.
typedef TrayMenuChoice = ({int chosen, String report});

/// Opens the menu [menuAddress] (an `HMENU`'s address) at the cursor, on a
/// thread of its own, and completes with the choice.
Future<TrayMenuChoice> openWindowsTrayMenu(int menuAddress) {
  // The cursor where the click was, read here: by the time the isolate runs,
  // the pointer may have moved.
  final getCursorPos = DynamicLibrary.open('user32.dll')
      .lookupFunction<_GetCursorPosC, _GetCursorPosDart>('GetCursorPos');
  final point = calloc<_Point>();
  getCursorPos(point);
  final (x, y) = (point.ref.x, point.ref.y);
  calloc.free(point);
  return Isolate.run(() => _track(menuAddress, x, y), debugName: 'tray menu');
}

/// Makes an owner window on this thread and tracks the menu from it.
TrayMenuChoice _track(int menuAddress, int x, int y) {
  final user32 = DynamicLibrary.open('user32.dll');
  final createWindow = user32
      .lookupFunction<_CreateWindowExC, _CreateWindowExDart>('CreateWindowExW');
  final destroyWindow = user32.lookupFunction<_HwndC, _HwndDart>(
    'DestroyWindow',
  );
  final setForeground = user32.lookupFunction<_HwndC, _HwndDart>(
    'SetForegroundWindow',
  );
  final track = user32.lookupFunction<_TrackPopupMenuC, _TrackPopupMenuDart>(
    'TrackPopupMenu',
  );
  final post = user32.lookupFunction<_PostMessageC, _PostMessageDart>(
    'PostMessageW',
  );
  final lastError = DynamicLibrary.open('kernel32.dll')
      .lookupFunction<_LastErrorC, _LastErrorDart>('GetLastError');
  final className = 'STATIC'.toNativeUtf16();
  final name = ''.toNativeUtf16();
  // A top-level window, never shown: a tool window stays off the taskbar, and
  // a predefined class needs no window procedure of its own.
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
  if (owner == nullptr) {
    return (chosen: 0, report: 'no owner window (error ${lastError()})');
  }
  try {
    final foreground = setForeground(owner);
    final chosen = track(
      Pointer<Void>.fromAddress(menuAddress),
      _tpmRightButton | _tpmBottomAlign | _tpmNoNotify | _tpmReturnCmd,
      x,
      y,
      0,
      owner,
      nullptr,
    );
    final error = lastError();
    // So the next click outside a menu closes it (the `TrackPopupMenu`
    // remarks).
    post(owner, _wmNull, 0, 0);
    return (
      chosen: chosen,
      report: 'at $x,$y, foreground $foreground, result $chosen, error $error',
    );
  } finally {
    destroyWindow(owner);
  }
}

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
typedef _LastErrorC = Uint32 Function();
typedef _LastErrorDart = int Function();
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
