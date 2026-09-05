import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/hit_test.dart';
import 'package:flutter/services.dart';

/// The tap/drag gesture state machine: translates pointer positions (pixels)
/// into caret/selection edits on a [ComposingInput] via a [HitTest]. Pure —
/// the view's gesture recognizers call these with pixel coordinates; no
/// pointer events are parsed here.
final class EditorGestures {
  /// Wraps the pixel→offset [hitTest] and the [input] it drives.
  EditorGestures({required this.hitTest, required this.input});

  /// Maps a pixel position to a buffer offset.
  final HitTest hitTest;

  /// The caret/selection state machine the gestures edit.
  final ComposingInput input;

  /// Places the caret at pixel (x, y) (a tap).
  void tapAt(double x, double y) {
    input.setSelection(
      TextSelection.collapsed(offset: hitTest.offsetAt(x, y)),
    );
  }

  /// Begins a drag-select at pixel (x, y): sets the selection anchor there.
  void dragStartAt(double x, double y) => tapAt(x, y);

  /// Extends the selection to pixel (x, y) (a drag move).
  void dragTo(double x, double y) {
    input.extendSelectionTo(hitTest.offsetAt(x, y));
  }

  /// Ends the drag-select: collapses the selection to the caret at the last
  /// drag position.
  void dragEnd() => input.collapseSelection();
}
