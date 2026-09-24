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
// posted to it after — and retrieved, because that thread has no message loop
// of its own to do it (`core/tray_menu_thread.dart`). The menu is still
// nativeapi's `HMENU` with its items; the choice comes back from
// `TrackPopupMenu` itself (`TPM_RETURNCMD`), so no `WM_COMMAND` goes anywhere
// and the caller runs the item.
//
// A classic menu draws in the light theme unless the process asks otherwise,
// and the only way to ask is uxtheme's `SetPreferredAppMode` (ordinal 135,
// Windows 10 1903 and later), with `FlushMenuThemes` (136) so a menu already
// drawn once is drawn again in the new mode. Both are exported by ordinal only
// — Explorer and the browsers use them for their own dark menus — and the
// mode is the *app's* theme, not the system's, so the menu matches the window.
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:niman/src/core/tray_menu_thread.dart';

export 'package:niman/src/core/tray_menu_thread.dart' show TrayMenuChoice;

/// The theme a menu is drawn in: the app's own choice, or the system's.
enum TrayMenuTheme {
  /// Whatever Windows is set to.
  system(1),

  /// Dark, whatever Windows is set to.
  dark(2),

  /// Light, whatever Windows is set to.
  light(3);

  new(this.appMode);

  /// uxtheme's `PreferredAppMode`: `AllowDark`, `ForceDark`, `ForceLight`.
  final int appMode;
}

/// Opens the menu [menuAddress] (an `HMENU`'s address) at the cursor, on a
/// thread of its own, drawn in [theme], and completes with the choice.
Future<TrayMenuChoice> openWindowsTrayMenu(
  int menuAddress, {
  TrayMenuTheme theme = TrayMenuTheme.system,
}) {
  // The cursor where the click was, read here: by the time the isolate runs,
  // the pointer may have moved.
  final getCursorPos = DynamicLibrary.open('user32.dll')
      .lookupFunction<_GetCursorPosC, _GetCursorPosDart>('GetCursorPos');
  final point = calloc<_Point>();
  getCursorPos(point);
  final (x, y) = (point.ref.x, point.ref.y);
  calloc.free(point);
  final mode = theme.appMode;
  final themed = _windowsBuild() >= 18362;
  return Isolate.run(
    () => _track(menuAddress, x, y, themed ? mode : null),
    debugName: 'tray menu',
  );
}

/// The Windows build number, or 0 when it cannot be read.
int _windowsBuild() {
  final match = RegExp(r'Build (\d+)')
      .firstMatch(Platform.operatingSystemVersion);
  return int.tryParse(match?.group(1) ?? '') ?? 0;
}

/// Asks uxtheme for [mode] and redraws the menus in it; false when the two
/// ordinals are not there.
bool _setMenuTheme(int mode) {
  final kernel32 = DynamicLibrary.open('kernel32.dll');
  final loadLibrary = kernel32.lookupFunction<_LoadLibraryC, _LoadLibraryDart>(
    'LoadLibraryW',
  );
  final getProc = kernel32.lookupFunction<_GetProcC, _GetProcDart>(
    'GetProcAddress',
  );
  final name = 'uxtheme.dll'.toNativeUtf16();
  final uxtheme = loadLibrary(name);
  calloc.free(name);
  if (uxtheme == nullptr) return false;
  // By ordinal: the "name" is the number itself (`MAKEINTRESOURCEA`).
  final setMode = getProc(uxtheme, Pointer<Utf8>.fromAddress(135));
  final flush = getProc(uxtheme, Pointer<Utf8>.fromAddress(136));
  if (setMode == nullptr || flush == nullptr) return false;
  setMode.cast<NativeFunction<_SetAppModeC>>().asFunction<_SetAppModeDart>()(
    mode,
  );
  flush.cast<NativeFunction<_FlushC>>().asFunction<_FlushDart>()();
  return true;
}

/// Makes an owner window on this thread and tracks the menu from it, drawn in
/// uxtheme's app [mode] when there is one to ask for.
TrayMenuChoice _track(int menuAddress, int x, int y, int? mode) {
  final themed = mode != null && _setMenuTheme(mode);
  final thread = _Win32MenuThread();
  try {
    return trackTrayMenu(
      thread,
      menuAddress,
      x,
      y,
      theme: themed ? 'mode $mode' : 'default',
    );
  } finally {
    thread.release();
  }
}

/// [TrayMenuThread] over user32, on the calling thread.
final class _Win32MenuThread implements TrayMenuThread {
  final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');

  late final _CreateWindowExDart _createWindow = _user32
      .lookupFunction<_CreateWindowExC, _CreateWindowExDart>('CreateWindowExW');
  late final _HwndDart _destroyWindow = _user32
      .lookupFunction<_HwndC, _HwndDart>('DestroyWindow');
  late final _HwndDart _setForeground = _user32
      .lookupFunction<_HwndC, _HwndDart>('SetForegroundWindow');
  late final _TrackPopupMenuDart _track = _user32
      .lookupFunction<_TrackPopupMenuC, _TrackPopupMenuDart>('TrackPopupMenu');
  late final _PostMessageDart _post = _user32
      .lookupFunction<_PostMessageC, _PostMessageDart>('PostMessageW');
  late final _PeekMessageDart _peek = _user32
      .lookupFunction<_PeekMessageC, _PeekMessageDart>('PeekMessageW');
  late final _MsgDart _translate = _user32.lookupFunction<_MsgC, _MsgDart>(
    'TranslateMessage',
  );
  late final _MsgDart _dispatch = _user32.lookupFunction<_MsgC, _MsgDart>(
    'DispatchMessageW',
  );
  late final _LastErrorDart _lastError = DynamicLibrary.open('kernel32.dll')
      .lookupFunction<_LastErrorC, _LastErrorDart>('GetLastError');

  /// The one message [dispatchOne] reads into, freed by [release].
  final Pointer<_Msg> _msg = calloc<_Msg>();

  @override
  int createOwner() {
    final className = 'STATIC'.toNativeUtf16();
    final name = ''.toNativeUtf16();
    // A top-level window, never shown: a tool window stays off the taskbar,
    // and a predefined class needs no window procedure of its own.
    final owner = _createWindow(
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
    return owner.address;
  }

  @override
  int lastError() => _lastError();

  @override
  bool setForeground(int owner) =>
      _setForeground(Pointer<Void>.fromAddress(owner)) != 0;

  @override
  int track(int menu, int x, int y, int owner) => _track(
    Pointer<Void>.fromAddress(menu),
    _tpmRightButton | _tpmBottomAlign | _tpmNoNotify | _tpmReturnCmd,
    x,
    y,
    0,
    Pointer<Void>.fromAddress(owner),
    nullptr,
  );

  @override
  void postNull(int owner) =>
      _post(Pointer<Void>.fromAddress(owner), _wmNull, 0, 0);

  @override
  bool dispatchOne() {
    if (_peek(_msg, nullptr, 0, 0, _pmRemove) == 0) return false;
    _translate(_msg);
    _dispatch(_msg);
    return true;
  }

  @override
  void destroy(int owner) => _destroyWindow(Pointer<Void>.fromAddress(owner));

  /// Frees the message buffer.
  void release() => calloc.free(_msg);
}

/// A queued message, as `PeekMessageW` fills it.
final class _Msg extends Struct {
  external Pointer<Void> hwnd;

  @Uint32()
  external int message;

  @IntPtr()
  external int wParam;

  @IntPtr()
  external int lParam;

  @Uint32()
  external int time;

  external _Point pt;

  @Uint32()
  external int lPrivate;
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
typedef _LoadLibraryC = Pointer<Void> Function(Pointer<Utf16> name);
typedef _LoadLibraryDart = Pointer<Void> Function(Pointer<Utf16> name);
typedef _GetProcC = Pointer<Void> Function(
  Pointer<Void> module,
  Pointer<Utf8> name,
);
typedef _GetProcDart = Pointer<Void> Function(
  Pointer<Void> module,
  Pointer<Utf8> name,
);
typedef _SetAppModeC = Int32 Function(Int32 mode);
typedef _SetAppModeDart = int Function(int mode);
typedef _FlushC = Void Function();
typedef _FlushDart = void Function();
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
typedef _PeekMessageC = Int32 Function(
  Pointer<_Msg> msg,
  Pointer<Void> hwnd,
  Uint32 first,
  Uint32 last,
  Uint32 remove,
);
typedef _PeekMessageDart = int Function(
  Pointer<_Msg> msg,
  Pointer<Void> hwnd,
  int first,
  int last,
  int remove,
);
typedef _MsgC = IntPtr Function(Pointer<_Msg> msg);
typedef _MsgDart = int Function(Pointer<_Msg> msg);
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
const int _pmRemove = 0x0001;
