import 'dart:io';

import 'package:copist/src/core/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart'
    show WindowListener, WindowManager;

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

  @override
  Future<void> init() async {
    await _manager.ensureInitialized();
    _manager.addListener(_listener);
    _log.info('window controller ready');
  }

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
  Future<void> dispose() async {}
}

/// Creates the platform controller: `window_manager` on the desktops
/// (Linux/Windows), a no-op elsewhere (the Android close path must keep
/// behaving exactly as before — T-PP-11's AC).
WindowController createWindowController() {
  return Platform.isLinux || Platform.isWindows
      ? WindowManagerController()
      : NoopWindowController();
}

/// The single window controller for the app session.
final windowControllerProvider = Provider<WindowController>((ref) {
  final controller = createWindowController();
  ref.onDispose(controller.dispose);
  return controller;
});
