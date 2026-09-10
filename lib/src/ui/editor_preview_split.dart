import 'package:copist/src/preview/editor_lines.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:copist/src/preview/scroll_sync.dart';
import 'package:flutter/material.dart';

/// The editor | preview split (T-M2-08): a draggable divider between the
/// two panes, with the bidirectional scroll sync wrapped around both.
final class EditorPreviewSplit extends StatefulWidget {
  /// Creates the split with [editor] and [preview] panes.
  ///
  /// [editorScroll]/[previewScroll] are the controllers the scroll sync
  /// links; [map] is the shared scroll map the preview feeds. [fraction] is
  /// the editor's share (0..1, clamped to the allowed range); dragging the
  /// divider calls [onFractionChanged] continuously and [onDragEnd] when
  /// the drag lifts (the owner persists it).
  const new({
    required this.editor,
    required this.preview,
    required this.editorScroll,
    required this.previewScroll,
    required this.map,
    required this.lines,
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

  /// The scroll map the preview feeds.
  final ScrollMap map;

  /// The editor's visible source lines (the sync's editor side).
  final EditorLineView lines;

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
    return EditorPreviewScrollSync(
      editorScroll: widget.editorScroll,
      previewScroll: widget.previewScroll,
      map: widget.map,
      lines: widget.lines,
      child: Row(
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
          Expanded(
            flex: (1000 * (1 - fraction)).round(),
            child: widget.preview,
          ),
        ],
      ),
    );
  }
}
