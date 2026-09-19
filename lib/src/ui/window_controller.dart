import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:window_manager/window_manager.dart'
    show TitleBarStyle, WindowListener, WindowManager;

/// What the close guard (T-PP-11) needs from the platform window: keep
/// the close from landing while the app still holds unsaved edits, learn
/// when the user asked to close anyway, and close for real once the
/// decision is in.
abstract interface class WindowController {
  /// Connects the platform side (must land before any close can arrive).
  Future<void> init();

  /// While [prevent] is on, the OS refuses the close request and reports
  /// it through [onCloseRequested] instead of closing the window.
  Future<void> setPreventClose({required bool prevent});

  /// The current close-request handler, or null while nothing guards.
  void Function()? get onCloseRequested;

  /// The user asked to close the window and the OS refused it (prevent
  /// was on). Null clears.
  set onCloseRequested(void Function()? handler);

  /// Closes the window for real. Only meaningful with prevent off.
  Future<void> close();

  /// Brings the window back to the front (the tray icon's activation).
  Future<void> show();

  /// Whether this platform gets the app's own title bar instead of the
  /// system one. Both desktops (T-PP-22); Android has no window to own.
  bool get customTitleBar;

  /// Hands the title bar to Flutter: the system bar goes, the app draws
  /// its own. What that takes differs per desktop, see the implementation.
  Future<void> applyCustomTitleBar();

  /// Minimizes the window (the title bar's button).
  Future<void> minimize();

  /// Maximizes or restores the window (the title bar's button).
  Future<void> toggleMaximize();

  /// Whether the window is maximized (the title bar's button icon).
  ValueListenable<bool> get maximized;

  /// Asks the platform whether the window is maximized right now: Zen
  /// mode (#69) must know whether the maximizing was its own to undo.
  Future<bool> isMaximized();

  /// Releases the platform side.
  Future<void> dispose();
}

/// The controller over `window_manager` (the T-PP-16 spike winner: the
/// only candidate with a runtime-verified close-request event on a real
/// Plasma/Wayland session).
final class WindowManagerController implements WindowController {
  static const AppLogger _log = AppLogger(name: 'window');

  final WindowManager _manager = WindowManager.instance;

  /// The listener bridge (created with the controller; outlives the guard
  /// that owns the handler).
  late final _WindowCloseListener _listener = _WindowCloseListener(this);

  /// The guard's handler, called on every refused close request.
  @override
  void Function()? onCloseRequested;

  final ValueNotifier<bool> _maximized = ValueNotifier<bool>(false);

  @override
  bool get customTitleBar => Platform.isLinux || Platform.isWindows;

  @override
  ValueListenable<bool> get maximized => _maximized;

  @override
  Future<void> init() async {
    await _manager.ensureInitialized();
    _manager.addListener(_listener);
    if (customTitleBar) await applyCustomTitleBar();
    _log.info('window controller ready');
  }

  @override
  Future<void> applyCustomTitleBar() async {
    // The two desktops need different calls, and on Windows the
    // difference is not cosmetic.
    //
    // Linux (GTK): `setAsFrameless` undecorates the window and
    // `setTitleBarStyle` hides the header bar the runner installs
    // (`linux/runner/my_application.cc`). Both, in this order.
    //
    // Windows (Win32): the hidden style only. The plugin treats
    // "frameless" and "hidden title bar" as two exclusive modes — the
    // second call clears the first's flag — and only the hidden one
    // adjusts `WM_NCCALCSIZE`. That adjustment is what keeps the resize
    // margins at the window's edges and what trims the borders when the
    // window is maximized, so it fills the work area instead of
    // overhanging it by the frame width. The frameless mode does
    // neither. Keeping the window's real frame styles is also what
    // leaves Aero Snap and Win+Arrow working, since both hang off the
    // system caption the app is only painting over.
    if (Platform.isLinux) await _manager.setAsFrameless();
    await _manager.setTitleBarStyle(TitleBarStyle.hidden);
    _log.info('custom title bar applied');
  }

  @override
  Future<void> minimize() => _manager.minimize();

  @override
  Future<void> toggleMaximize() async {
    if (await _manager.isMaximized()) {
      await _manager.unmaximize();
    } else {
      await _manager.maximize();
    }
  }

  @override
  Future<bool> isMaximized() => _manager.isMaximized();

  @override
  Future<void> setPreventClose({required bool prevent}) {
    return _manager.setPreventClose(prevent);
  }

  @override
  Future<void> close() {
    return _manager.close();
  }

  @override
  Future<void> show() async {
    await _manager.show();
    await _manager.focus();
  }

  @override
  Future<void> dispose() async {
    _manager.removeListener(_listener);
    _maximized.dispose();
    _log.info('window controller disposed');
  }
}

/// The [WindowListener] bridge: the platform emits
/// [WindowListener.onWindowClose] when a close request was refused
/// (prevent on), and this hands it to the controller's
/// [WindowController.onCloseRequested].
final class _WindowCloseListener extends WindowListener {
  new(this._controller);

  final WindowManagerController _controller;

  @override
  void onWindowClose() => _controller.onCloseRequested?.call();

  @override
  void onWindowMaximize() => _controller._maximized.value = true;

  @override
  void onWindowUnmaximize() => _controller._maximized.value = false;
}

/// The off-desktop controller: no platform close surface to guard
/// (Android closes through its own lifecycle), so every call is inert.
final class NoopWindowController implements WindowController {
  @override
  Future<void> init() async {}

  @override
  void Function()? onCloseRequested;

  @override
  Future<void> setPreventClose({required bool prevent}) async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> show() async {}

  @override
  bool get customTitleBar => false;

  @override
  final ValueNotifier<bool> maximized = ValueNotifier<bool>(false);

  @override
  Future<void> applyCustomTitleBar() async {}

  @override
  Future<void> minimize() async {}

  @override
  Future<void> toggleMaximize() async {}

  @override
  Future<bool> isMaximized() async => false;

  @override
  Future<void> dispose() async {
    maximized.dispose();
  }
}

/// Creates the platform controller: `window_manager` on the desktops
/// (Linux/Windows), a no-op elsewhere (the Android close path must keep
/// behaving exactly as before — T-PP-11's AC).
///
/// [isDesktop] overrides the host platform so a plain test can cover the
/// branch that does not run here (T-PP-01).
WindowController createWindowController({bool? isDesktop}) {
  return (isDesktop ?? (Platform.isLinux || Platform.isWindows))
      ? WindowManagerController()
      : NoopWindowController();
}

/// The single window controller for the app session.
final windowControllerProvider = Provider<WindowController>((ref) {
  final controller = createWindowController();
  ref.onDispose(controller.dispose);
  return controller;
});
