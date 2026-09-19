/// Zen mode (#69): the desktop window with the note and nothing else.
///
/// The rail, the tree, the tabs, the dock, the note's own row and its
/// status row all go; the note's name stays in a thin bar with the way
/// out, beside the window's own buttons. The window is maximized on the
/// way in (a soft fullscreen: the taskbar stays), and restored on the way
/// out only when Zen was what maximized it.
///
/// It is a writing state, not a setting: kept by the window for as long
/// as it lasts, never stored, so a restart comes back without it. It is
/// independent of typewriter mode (#70), by design — leaving one never
/// touches the other.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/window_controller.dart';

/// Whether the window is in Zen mode, and the window work that goes with
/// entering and leaving it.
final class ZenMode extends ChangeNotifier {
  /// Zen mode over the given window.
  new(this._window);

  final WindowController _window;

  bool _on = false;

  /// Whether Zen maximized the window, so leaving should restore it.
  bool _maximizedByZen = false;

  /// Whether Zen mode is on.
  bool get on => _on;

  /// Enters Zen mode: the chrome goes at once, and the window is
  /// maximized unless it already was.
  Future<void> enter() async {
    if (_on) return;
    _on = true;
    notifyListeners();
    if (!await _window.isMaximized()) {
      _maximizedByZen = true;
      await _window.toggleMaximize();
    }
  }

  /// Leaves Zen mode: the chrome comes back, and the window is restored
  /// if Zen maximized it and it still is.
  Future<void> leave() async {
    if (!_on) return;
    _on = false;
    notifyListeners();
    if (!_maximizedByZen) return;
    _maximizedByZen = false;
    if (await _window.isMaximized()) await _window.toggleMaximize();
  }

  /// Enters Zen mode, or leaves it.
  Future<void> toggle() => _on ? leave() : enter();
}

/// Leaves Zen mode on the app's Esc, which is a [DismissIntent]. It is
/// off while Zen is not what is on screen, so the key goes on to whatever
/// else dismisses.
final class LeaveZenAction extends Action<DismissIntent> {
  /// Leaves [_zen] while [_shown] says it is on screen.
  new(this._zen, this._shown);

  final ZenMode _zen;
  final bool Function() _shown;

  @override
  bool isEnabled(DismissIntent intent) => _shown();

  @override
  void invoke(DismissIntent intent) => unawaited(_zen.leave());
}
