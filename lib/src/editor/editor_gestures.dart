import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/hit_test.dart';
import 'package:flutter/services.dart';

/// The tap/drag gesture state machine: translates pointer positions (pixels)
/// into caret/selection edits on a [ComposingInput] via a [HitTest]. Pure —
/// the view's gesture recognizers call these with pixel coordinates; no
/// pointer events are parsed here.
///
/// Every method returns whether the selection actually changed: the view
/// pushes the new selection to the IME only in that case (the platform's
/// copy must stay in lockstep, or the next keystroke edits a stale
/// selection), and skips the redundant push on a no-change.
final class EditorGestures {
  /// Wraps the pixel→offset [hitTest] and the [input] it drives.
  EditorGestures({required this.hitTest, required this.input});

  /// Maps a pixel position to a buffer offset.
  final HitTest hitTest;

  /// The caret/selection state machine the gestures edit.
  final ComposingInput input;

  /// Places the caret at pixel (x, y) (a tap).
  bool tapAt(double x, double y) {
    final before = input.selection;
    input.setSelection(TextSelection.collapsed(offset: hitTest.offsetAt(x, y)));
    return input.selection != before;
  }

  /// Long-press at pixel (x, y): selects the word there (the long-press
  /// contract; a following [dragTo] extends the selection).
  bool longPressAt(double x, double y) {
    final before = input.selection;
    input.selectWordAt(hitTest.offsetAt(x, y));
    return input.selection != before;
  }

  /// Begins a drag-select at pixel (x, y): sets the selection anchor there.
  bool dragStartAt(double x, double y) => tapAt(x, y);

  /// Extends the selection to pixel (x, y) (a drag move).
  bool dragTo(double x, double y) {
    final before = input.selection;
    input.extendSelectionTo(hitTest.offsetAt(x, y));
    return input.selection != before;
  }
}
