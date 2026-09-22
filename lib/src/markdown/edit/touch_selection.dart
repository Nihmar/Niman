/// Selecting by touch on the source surface: the two handles and the toolbar
/// (#245, phase 3 — "under the phone's selection handles").
///
/// A phone has no mouse to drag with and no Shift key, so a selection is made
/// the way every Android text field makes one: a long press takes a word,
/// two handles move its ends, and a toolbar offers what to do with it. The
/// handles and the toolbar are Material's own — the same teardrops and the
/// same buttons as a `TextField` — so the note selects like everything else
/// on the device.
///
/// Where they go is the surface's answer, never a metric kept beside it: each
/// handle hangs from the caret rectangle the line's own paragraph gives for
/// that end of the selection, the same rectangle the caret is drawn in, and a
/// dragged handle lands through the same hit test a tap does. So a handle is
/// where the selection's end is drawn, by construction.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Which end of the selection a handle holds.
enum SelectionHandle {
  /// The start, drawn on the left of the first character.
  start,

  /// The end, drawn on the right of the last character.
  end,
}

/// The handles and the toolbar over a selection, in the overlay's
/// coordinates.
final class TouchSelectionOverlay extends StatelessWidget {
  /// Handles at [start] and [end] (caret rectangles, null when that end's
  /// line is not on screen) and, with [showToolbar], the [buttons] above them.
  const new({
    required this.start,
    required this.end,
    required this.showHandles,
    required this.showToolbar,
    required this.buttons,
    required this.onHandleDrag,
    required this.onHandleDragEnd,
    super.key,
  });

  /// The caret rectangle at the selection's start, or null.
  final Rect? start;

  /// The caret rectangle at the selection's end, or null.
  final Rect? end;

  /// Whether the handles are drawn (a range is selected by touch).
  final bool showHandles;

  /// Whether the toolbar is drawn.
  final bool showToolbar;

  /// What the toolbar offers.
  final List<ContextMenuButtonItem> buttons;

  /// A handle was dragged to a point — the middle of the line the finger is
  /// pointing at, in global coordinates.
  final void Function(SelectionHandle handle, Offset point) onHandleDrag;

  /// A handle was let go.
  final VoidCallback onHandleDragEnd;

  @override
  Widget build(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject();
    // The rectangles are global; the overlay may not start at the window's
    // corner (a nested navigator, a desktop title bar).
    Offset toOverlay(Offset global) => overlay is RenderBox && overlay.hasSize
        ? overlay.globalToLocal(global)
        : global;
    final first = start;
    final last = end;
    final children = <Widget>[
      if (showHandles && first != null)
        _Handle(
          which: SelectionHandle.start,
          caret: first.shift(toOverlay(Offset.zero) - Offset.zero),
          global: first,
          onDrag: onHandleDrag,
          onDragEnd: onHandleDragEnd,
        ),
      if (showHandles && last != null)
        _Handle(
          which: SelectionHandle.end,
          caret: last.shift(toOverlay(Offset.zero) - Offset.zero),
          global: last,
          onDrag: onHandleDrag,
          onDragEnd: onHandleDragEnd,
        ),
    ];
    final anchorRect = first ?? last;
    if (showToolbar && anchorRect != null && buttons.isNotEmpty) {
      final top = first ?? last!;
      final bottom = last ?? first!;
      final left = toOverlay(top.topLeft);
      final right = toOverlay(bottom.bottomRight);
      final middle = (left.dx + right.dx) / 2;
      children.add(
        AdaptiveTextSelectionToolbar.buttonItems(
          anchors: TextSelectionToolbarAnchors(
            primaryAnchor: Offset(middle, left.dy - 8),
            // Below the handles when there is no room above.
            secondaryAnchor: Offset(middle, right.dy + 32),
          ),
          buttonItems: buttons,
        ),
      );
    }
    return Stack(children: children);
  }
}

/// One of Material's selection handles, hanging from [caret].
final class _Handle extends StatefulWidget {
  const new({
    required this.which,
    required this.caret,
    required this.global,
    required this.onDrag,
    required this.onDragEnd,
  });

  final SelectionHandle which;

  /// The caret rectangle in the overlay's coordinates.
  final Rect caret;

  /// The same rectangle in global coordinates, where the drag is reported.
  final Rect global;

  final void Function(SelectionHandle handle, Offset point) onDrag;
  final VoidCallback onDragEnd;

  @override
  State<_Handle> createState() => _HandleState();
}

final class _HandleState extends State<_Handle> {
  /// From the finger to the middle of the line the handle holds, taken when
  /// the drag starts, so the text under the handle does not jump to the
  /// finger.
  Offset _grab = Offset.zero;

  TextSelectionHandleType get _type => widget.which == SelectionHandle.start
      ? TextSelectionHandleType.left
      : TextSelectionHandleType.right;

  @override
  Widget build(BuildContext context) {
    final controls = materialTextSelectionControls;
    final lineHeight = widget.caret.height;
    final size = controls.getHandleSize(lineHeight);
    final anchor = controls.getHandleAnchor(_type, lineHeight);
    // The handle's anchor sits at the bottom of the line, at the caret — what
    // Flutter's own selection overlay does with the same two numbers.
    final point = Offset(widget.caret.left, widget.caret.bottom);
    // A finger needs more than the teardrop to aim at: the target is padded
    // to the platform's minimum, around the drawn handle.
    const padding = 12.0;
    return Positioned(
      left: point.dx - anchor.dx - padding,
      top: point.dy - anchor.dy - padding,
      child: GestureDetector(
        key: ValueKey<SelectionHandle>(widget.which),
        behavior: HitTestBehavior.translucent,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (details) {
          _grab = widget.global.centerLeft - details.globalPosition;
        },
        onPanUpdate: (details) =>
            widget.onDrag(widget.which, details.globalPosition + _grab),
        onPanEnd: (_) => widget.onDragEnd(),
        onPanCancel: widget.onDragEnd,
        child: Padding(
          padding: const EdgeInsets.all(padding),
          child: SizedBox.fromSize(
            size: size,
            child: controls.buildHandle(context, _type, lineHeight),
          ),
        ),
      ),
    );
  }
}
