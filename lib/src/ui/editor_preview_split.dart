import 'package:flutter/material.dart';

/// The editor | preview split (T-M2-08): a draggable divider between the
/// two panes, with the bidirectional scroll sync wrapped around both.
final class EditorPreviewSplit extends StatefulWidget {
  /// Creates the split with [editor] and [preview] panes.
  ///
  /// [fraction] is the editor's share (0..1, clamped to the allowed range);
  /// dragging the divider calls [onFractionChanged] continuously and
  /// [onDragEnd] when the drag lifts (the owner persists it).
  ///
  /// The panes used to be linked: scrolling one scrolled the other, through a
  /// shared line map. That is gone with the unified surface, and its departure
  /// is the point rather than a loss — one engine and one scroll position
  /// cannot be out of step, which is why the feature existed.
  const new({
    required this.editor,
    required this.preview,
    required this.editorScroll,
    required this.previewScroll,
    required this.fraction,
    required this.onFractionChanged,
    this.onDragEnd,
    this.minFraction = 0.2,
    this.maxFraction = 0.8,
    this.dividerWidth = 1,
    super.key,
  });

  /// The editor pane.
  final Widget editor;

  /// The preview pane.
  final Widget preview;

  /// The editor's vertical scroll controller.
  final ScrollController editorScroll;

  /// The preview's scroll controller.
  final ScrollController previewScroll;

  /// The editor's share of the split (before clamping).
  final double fraction;

  /// Live fraction changes during a drag.
  final ValueChanged<double> onFractionChanged;

  /// The divider drag lifted (the owner persists).
  final VoidCallback? onDragEnd;

  /// The drag range.
  final double minFraction;

  /// The drag range's upper bound.
  final double maxFraction;

  /// The divider's pixel width.
  final double dividerWidth;

  @override
  State<EditorPreviewSplit> createState() => _EditorPreviewSplitState();
}

final class _EditorPreviewSplitState extends State<EditorPreviewSplit> {
  late double _fraction = _clamp(widget.fraction);

  double _clamp(double value) =>
      value.clamp(widget.minFraction, widget.maxFraction);

  @override
  void didUpdateWidget(EditorPreviewSplit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fraction != widget.fraction) {
      _fraction = _clamp(widget.fraction);
    }
  }

  /// The row's width and left edge (the Row this split renders), or null
  /// before layout.
  (double left, double width)? _rowGeometry() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final left = box.localToGlobal(Offset.zero).dx;
    return (left, box.size.width);
  }

  void _onDragUpdate(Offset global) {
    final row = _rowGeometry();
    if (row == null) return;
    final next = ((global.dx - row.$1) / row.$2).clamp(
      widget.minFraction,
      widget.maxFraction,
    );
    if (next == _fraction) return;
    setState(() => _fraction = next);
    widget.onFractionChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = _fraction;
    return Row(
      children: [
        Expanded(flex: (1000 * fraction).round(), child: widget.editor),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) =>
              _onDragUpdate(details.globalPosition),
          onHorizontalDragEnd: (_) => widget.onDragEnd?.call(),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: SizedBox(
              // The visual divider stays 1 px; the hit box is wider so
              // fingers (and pointers) can actually grab it.
              width: widget.dividerWidth + 12,
              child: Center(
                child: Container(
                  width: widget.dividerWidth,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
        ),
        Expanded(flex: (1000 * (1 - fraction)).round(), child: widget.preview),
      ],
    );
  }
}
