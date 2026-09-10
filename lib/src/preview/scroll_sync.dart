import 'package:copist/src/preview/editor_lines.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:flutter/material.dart';

/// Bidirectional editor ↔ preview scroll sync (M2 T-M2-06).
///
/// Wraps a two-pane child (the shell's editor | preview row). On a user
/// scroll in either pane it maps the position through [ScrollMap] and moves
/// the other pane — source line ↔ preview block. Programmatic jumps are
/// suppressed (the guard flag), and moves below [deadzone] pixels are
/// ignored (the other pane's own native scroll feedback would otherwise
/// fight the mapping).
///
/// The editor's side of the mapping is its *top visible line*, read from
/// [lines]. Its scroll pixels cannot give one: re_editor sizes the scroll
/// extent by counting every line below the viewport as a single row, so
/// the extent grows as wrapped lines come into view and the same fraction
/// means a different line at every position. Without [lines] the sync
/// falls back to that fraction, which is right only while no line wraps.
final class EditorPreviewScrollSync extends StatefulWidget {
  /// Creates the sync link.
  ///
  /// [editorScroll] is re_editor's vertical scroll controller;
  /// [previewScroll] the preview's [ScrollController]; [map] the scroll map
  /// the preview feeds; [lines] the editor's laid-out source lines.
  const new({
    required this.editorScroll,
    required this.previewScroll,
    required this.map,
    required this.child,
    this.lines,
    this.deadzone = 8,
    super.key,
  });

  /// re_editor's vertical scroll controller.
  final ScrollController editorScroll;

  /// The preview's scroll controller.
  final ScrollController previewScroll;

  /// The scroll map the preview feeds.
  final ScrollMap map;

  /// The editor's visible source lines; null falls back to the pixel
  /// fraction (see the class doc).
  final EditorLineView? lines;

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

  /// The editor was last moved by the preview: its next layout is that
  /// move's echo, not a scroll to follow.
  bool _fromPreview = false;

  /// The line the preview asked the editor to show, until it shows it.
  int? _wantedLine;

  /// Attempts spent on [_wantedLine] (the editor's own line geometry only
  /// covers what is on screen, so a distant line is reached by estimate,
  /// then corrected).
  int _wantedTries = 0;

  /// Whether a post-frame pass over the editor's new lines is booked.
  bool _linesPending = false;

  /// Tries allowed before a wanted line is given up on.
  static const int _maxSeekTries = 4;

  @override
  void initState() {
    super.initState();
    widget.editorScroll.addListener(_onEditorScroll);
    widget.previewScroll.addListener(_onPreviewScroll);
    widget.lines?.addListener(_onEditorLines);
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
    if (oldWidget.lines != widget.lines) {
      oldWidget.lines?.removeListener(_onEditorLines);
      widget.lines?.addListener(_onEditorLines);
    }
  }

  @override
  void dispose() {
    widget.editorScroll.removeListener(_onEditorScroll);
    widget.previewScroll.removeListener(_onPreviewScroll);
    widget.lines?.removeListener(_onEditorLines);
    super.dispose();
  }

  /// The editor's line geometry, or null while it has none (no editor
  /// attached, or nothing laid out yet).
  EditorLineView? get _lines {
    final lines = widget.lines;
    return lines != null && lines.hasLines ? lines : null;
  }

  /// The editor published the lines it just laid out. The publication comes
  /// from inside its layout, so the other pane is moved once the frame is
  /// over.
  void _onEditorLines() {
    if (_linesPending) return;
    _linesPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _linesPending = false;
      if (!mounted) return;
      if (_wantedLine != null) {
        _seekEditor();
        return;
      }
      // The editor moved because the preview moved it: following that back
      // would only round-trip the mapping.
      if (_fromPreview) {
        _fromPreview = false;
        return;
      }
      if (_applying) return;
      _previewFollowEditor();
    });
  }

  /// Editor → preview, from the editor's top visible line.
  void _previewFollowEditor() {
    final lines = _lines;
    if (lines == null) return;
    final line = lines.topLine();
    if (line == null) return;
    final preview = widget.previewScroll.position;
    if (!preview.hasContentDimensions) return;
    final target = widget.map.previewOffsetForLine(
      line,
      maxExtent: preview.maxScrollExtent,
    );
    if (target == null) return;
    _jump(preview, target);
  }

  void _onEditorScroll() {
    if (_applying) return;
    // With the editor's own line geometry in hand, its layout drives the
    // sync (_onEditorLines) — pixels would only guess at the line.
    if (_lines != null) return;
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
    if (_lines != null) {
      _wantedLine = line;
      _wantedTries = 0;
      _seekEditor();
      return;
    }
    final fraction = widget.map.lineCount <= 0
        ? 0.0
        : (line / widget.map.lineCount).clamp(0.0, 1.0);
    _jump(editor, editor.maxScrollExtent * fraction);
  }

  /// Puts [_wantedLine] at the top of the editor.
  ///
  /// The editor only measures the lines it has laid out, so a line already
  /// on screen is placed exactly and a distant one is reached by the
  /// unwrapped-row estimate — which undershoots by whatever wraps in
  /// between, so the next layout runs this again, a few times at most.
  void _seekEditor() {
    final line = _wantedLine;
    final lines = _lines;
    if (line == null || lines == null) {
      _wantedLine = null;
      return;
    }
    final editor = widget.editorScroll.position;
    if (!editor.hasContentDimensions) {
      _wantedLine = null;
      return;
    }
    final exact = lines.offsetOf(line);
    final double target;
    if (exact != null) {
      target = editor.pixels + exact;
      _wantedLine = null;
    } else {
      final anchor = lines.topLine();
      final row = lines.rowHeight;
      if (anchor == null || row == null) {
        _wantedLine = null;
        return;
      }
      target = editor.pixels + (line - anchor) * row;
      if (++_wantedTries >= _maxSeekTries) _wantedLine = null;
    }
    _fromPreview = true;
    // Already there (the move is inside the deadzone): stop seeking.
    if (!_jump(editor, target)) _wantedLine = null;
  }

  /// Moves [position] to [target]; false when the move was too small to
  /// make.
  bool _jump(ScrollPosition position, double target) {
    final clamped = target.clamp(0.0, position.maxScrollExtent);
    if ((position.pixels - clamped).abs() < widget.deadzone) return false;
    _applying = true;
    position.jumpTo(clamped);
    // The jump itself fires the listener again; release the guard after
    // the frame so legitimate user scrolls resume.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applying = false;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
