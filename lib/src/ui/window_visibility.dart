/// Whether the app's window is on screen (#512).
///
/// A hidden window is nobody's to see, and nothing in it should draw: the
/// editor's caret blink is a frame source on its own, and a window sitting in
/// the tray kept laying out, painting and rasterizing at its pace. Held
/// statically, like the key map and the close-to-tray setting, because the
/// editor sits deep under the shell that owns the window — and it is read,
/// not owned, by whoever wants to stop drawing.
library;

import 'package:flutter/foundation.dart';

/// The window's visibility, for the parts of the app that draw on a timer.
final class WindowVisibility {
  const new _();

  /// Whether the window is on screen. True until the close-to-tray path hides
  /// it, and true again when the tray brings it back.
  static final ValueNotifier<bool> shown = ValueNotifier<bool>(true);

  /// The window was hidden to the tray.
  static void hide() => shown.value = false;

  /// The window is on screen again.
  static void show() => shown.value = true;
}
