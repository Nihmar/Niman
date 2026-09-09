import 'package:copist/src/preview/scroll_map.dart';
import 'package:flutter/material.dart';

/// Bidirectional editor ↔ preview scroll sync (M2 T-M2-06).
///
/// Wraps a two-pane child (the shell's editor | preview row). Attaches to
/// both scroll controllers and, on a user scroll in either pane, maps the
/// position through [ScrollMap] and moves the other pane — source line ↔
/// preview block. Programmatic jumps are suppressed (the guard flag), and
/// moves below [deadzone] pixels are ignored (the other pane's own native
/// scroll feedback would otherwise fight the mapping).
final class EditorPreviewScrollSync extends StatefulWidget {
  /// Creates the sync link.
  ///
  /// [editorScroll] is re_editor's vertical scroll controller;
  /// [previewScroll] the preview's [ScrollController]; [map] the scroll map
  /// the preview feeds.
  const new({
    required this.editorScroll,
    required this.previewScroll,
    required this.map,
    required this.child,
    this.deadzone = 8,
    super.key,
  });

  /// re_editor's vertical scroll controller.
  final ScrollController editorScroll;

  /// The preview's scroll controller.
  final ScrollController previewScroll;

  /// The scroll map the preview feeds.
  final ScrollMap map;

  /// The two-pane child this sync wraps.
  final Widget child;

  /// Minimum move (px) before the other pane is repositioned.
  final double deadzone;

  @override
  State<EditorPreviewScrollSync> createState() =>
      _EditorPreviewScrollSyncState();
}

final class _EditorPreviewScrollSyncState
    extends State<EditorPreviewScrollSync> {
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    widget.editorScroll.addListener(_onEditorScroll);
    widget.previewScroll.addListener(_onPreviewScroll);
  }

  @override
  void didUpdateWidget(EditorPreviewScrollSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editorScroll != widget.editorScroll) {
      oldWidget.editorScroll.removeListener(_onEditorScroll);
      widget.editorScroll.addListener(_onEditorScroll);
    }
    if (oldWidget.previewScroll != widget.previewScroll) {
      oldWidget.previewScroll.removeListener(_onPreviewScroll);
      widget.previewScroll.addListener(_onPreviewScroll);
    }
  }

  @override
  void dispose() {
    widget.editorScroll.removeListener(_onEditorScroll);
    widget.previewScroll.removeListener(_onPreviewScroll);
    super.dispose();
  }

  void _onEditorScroll() {
    if (_applying) return;
    final editor = widget.editorScroll.position;
    final preview = widget.previewScroll.position;
    if (!editor.hasContentDimensions || !preview.hasContentDimensions) return;
    final fraction = editor.maxScrollExtent <= 0
        ? 0.0
        : (editor.pixels / editor.maxScrollExtent).clamp(0.0, 1.0);
    final line = ((widget.map.lineCount - 1) * fraction).round();
    final target = widget.map.previewOffsetForLine(
      line,
      maxExtent: preview.maxScrollExtent,
    );
    if (target == null) return;
    _jump(preview, target);
  }

  void _onPreviewScroll() {
    if (_applying) return;
    final editor = widget.editorScroll.position;
    final preview = widget.previewScroll.position;
    if (!editor.hasContentDimensions || !preview.hasContentDimensions) return;
    final line = widget.map.lineForPreviewOffset(
      preview.pixels,
      maxExtent: preview.maxScrollExtent,
    );
    if (line == null) return;
    final fraction = widget.map.lineCount <= 0
        ? 0.0
        : (line / widget.map.lineCount).clamp(0.0, 1.0);
    final target = editor.maxScrollExtent * fraction;
    _jump(editor, target);
  }

  void _jump(ScrollPosition position, double target) {
    final clamped = target.clamp(0.0, position.maxScrollExtent);
    if ((position.pixels - clamped).abs() < widget.deadzone) return;
    _applying = true;
    position.jumpTo(clamped);
    // The jump itself fires the listener again; release the guard after
    // the frame so legitimate user scrolls resume.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applying = false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
