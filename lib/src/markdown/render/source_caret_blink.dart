import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/ui/window_visibility.dart';

/// The source view's caret blink: whether the caret is drawn right now, and
/// the timer that turns it on and off.
///
/// Only a caret someone can see blinks (#512): a window in the tray is
/// nobody's to see, and a note the keys are not going to is not being typed
/// in. In either the caret stays drawn, steady, and draws no frame.
final class SourceCaretBlink {
  /// The blink of a caret whose view has the keys while [_focused] says so.
  new({required this._focused});

  /// Whether the view has the keyboard focus.
  final bool Function() _focused;

  /// Whether the caret is drawn (it blinks).
  final ValueNotifier<bool> on = ValueNotifier<bool>(true);

  Timer? _blink;

  /// Whether the caret is blinking right now.
  bool get blinking => _blink != null;

  /// Shows the caret and starts its blink over.
  ///
  /// Every move does this, the way every text field does: a caret that moved
  /// during the half of the blink it spends hidden stays invisible for up to
  /// 550 ms, which reads as a tap that took that long to land.
  void restart() {
    on.value = true;
    _blink?.cancel();
    // A window in the tray is nobody's to see, and a note the keys are not
    // going to is not being typed in: in either, the blink would repaint at
    // its own pace and nothing else would ever stop it (#512). The caret
    // stays drawn, steady.
    _blink = WindowVisibility.shown.value && _focused()
        ? Timer.periodic(const Duration(milliseconds: 550), (_) {
            on.value = !on.value;
          })
        : null;
  }

  /// Stops the blink.
  void dispose() {
    _blink?.cancel();
    on.dispose();
  }
}
