/// The shell's immersive states, split out of `shell.dart` for #710: Zen
/// mode (#69) and the book read in full screen (#621).
///
/// The window is the seam: Zen is per window and never stored, and the
/// full-screen book takes the screen through the window controller or
/// the Android system bars. `possible` is the shell's answer to whether
/// Zen can show at all — a wide window on the notes with one open.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show SystemChrome, SystemUiMode;
import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/ui/zen_mode.dart';

/// The shell's Zen and full-screen states, as the shell drives them.
final class ShellImmersive extends ChangeNotifier {
  /// Creates the states over [window]; [possible] says whether Zen can
  /// show here and now.
  new({required this.window, required this.possible}) {
    zen = ZenMode(window);
    zen.addListener(notifyListeners);
    fullScreen.addListener(_applyFullScreen);
  }

  /// The window the states take and give back.
  final WindowController window;

  /// Whether Zen can show here and now.
  final bool Function() possible;

  /// Zen mode (#69), per window and never stored.
  late final ZenMode zen;

  /// Which book is read in full screen (#621): its pane, or null.
  final ValueNotifier<Object?> fullScreen = ValueNotifier<Object?>(null);

  bool _disposed = false;

  /// Whether Zen is what is on screen.
  bool get inZen => zen.on && possible();

  /// Toggles Zen.
  Future<void> toggleZen() => zen.toggle();

  /// Leaves Zen.
  Future<void> leaveZen() => zen.leave();

  /// Leaves Zen once there is nothing left for it to show — the last tab
  /// closed, another place of the rail chosen, the window narrowed — so
  /// the chrome and the window size come back rather than wait.
  void leaveIfEmpty() {
    if (!zen.on || possible()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && zen.on && !possible()) unawaited(zen.leave());
    });
  }

  /// Takes the screen for the book read in full screen, or gives it back:
  /// the window on the desktops, the system bars on Android.
  void _applyFullScreen() {
    final on = fullScreen.value != null;
    if (Platform.isAndroid) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(
          on ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
        ),
      );
    } else {
      unawaited(window.setFullScreen(on: on));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    zen.removeListener(notifyListeners);
    unawaited(zen.leave());
    zen.dispose();
    fullScreen
      ..removeListener(_applyFullScreen)
      ..dispose();
    super.dispose();
  }
}
