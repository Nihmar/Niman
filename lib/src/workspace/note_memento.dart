import 'package:flutter/foundation.dart';

/// Where a note was left in its tab (issue #23): enough to put the reader
/// back — caret, selection, scroll, which editor, whether the preview was
/// up — for a tab whose editor is no longer mounted, or after a restart.
///
/// The scroll is a place in the note, not a distance: the source line at the
/// top of whichever pane showed the note, and how far into it (#1077).
/// Pixels mean nothing once the window, the text size or the note column
/// changes, nor across the editor and the preview.
///
/// Not the undo history: that lives in the editor, and only a tab kept
/// alive keeps it (the plan on #23, decision 4).
@immutable
final class NoteMemento {
  /// A memento; every field is optional, and a missing one means "as the
  /// note opens by default".
  const new({
    this.selectionBase,
    this.selectionExtent,
    this.scrollLine,
    this.scrollFraction,
    this.scrollOffset,
    this.editorKind,
    this.preview,
  });

  /// Reads one written by [toJson]; anything malformed reads as absent.
  factory fromJson(Object? json) {
    if (json is! Map) return const NoteMemento();
    int? integer(Object? raw) => raw is int && raw >= 0 ? raw : null;
    double? fraction(Object? raw) =>
        raw is num && raw.isFinite && raw >= 0 ? raw.toDouble() : null;
    final scroll = json['scroll'];
    final kind = json['editor'];
    final preview = json['preview'];
    final line = integer(json['line']);
    return NoteMemento(
      selectionBase: integer(json['base']),
      selectionExtent: integer(json['extent']),
      // A place needs its line; the fraction into it is optional.
      scrollLine: line,
      scrollFraction: line == null
          ? null
          : (fraction(json['into']) ?? 0.0).clamp(0.0, 1.0),
      // What a build before #1077 wrote: pixels, still read.
      scrollOffset: scroll is num && scroll.isFinite && scroll >= 0
          ? scroll.toDouble()
          : null,
      editorKind: kind is String && kind.isNotEmpty ? kind : null,
      preview: preview is bool ? preview : null,
    );
  }

  /// The selection's anchor, as a character offset into the note.
  final int? selectionBase;

  /// The selection's moving end (the caret), as a character offset.
  final int? selectionExtent;

  /// The source line at the top of the pane the note was left in (#1077).
  final int? scrollLine;

  /// How far into [scrollLine] the pane was scrolled: 0 at its top.
  final double? scrollFraction;

  /// How far the note was scrolled, in logical pixels: what a memento
  /// written before [scrollLine] holds, and read for it. Nothing writes it
  /// now.
  final double? scrollOffset;

  /// Which editor the note was in (`source` or `wysiwyg`).
  final String? editorKind;

  /// Whether the preview was showing.
  final bool? preview;

  /// Whether it knows where the note was scrolled to.
  bool get hasScroll => scrollLine != null || scrollOffset != null;

  /// A copy with the given fields replaced.
  NoteMemento copyWith({String? editorKind, bool? preview}) => NoteMemento(
    selectionBase: selectionBase,
    selectionExtent: selectionExtent,
    scrollLine: scrollLine,
    scrollFraction: scrollFraction,
    scrollOffset: scrollOffset,
    editorKind: editorKind ?? this.editorKind,
    preview: preview ?? this.preview,
  );

  /// This memento, with [previous]'s scroll where this one knows none: a
  /// view torn down before it was laid out cannot say where it was, and that
  /// is not a note scrolled back to the top (#1075).
  NoteMemento keepingScrollOf(NoteMemento previous) =>
      hasScroll || !previous.hasScroll
      ? this
      : NoteMemento(
          selectionBase: selectionBase,
          selectionExtent: selectionExtent,
          scrollLine: previous.scrollLine,
          scrollFraction: previous.scrollFraction,
          scrollOffset: previous.scrollOffset,
          editorKind: editorKind,
          preview: preview,
        );

  /// Whether it remembers nothing.
  bool get isEmpty =>
      selectionBase == null &&
      selectionExtent == null &&
      !hasScroll &&
      editorKind == null &&
      preview == null;

  /// The fields that are set, under short keys.
  Map<String, Object> toJson() => {
    'base': ?selectionBase,
    'extent': ?selectionExtent,
    'line': ?scrollLine,
    if (scrollLine != null) 'into': scrollFraction ?? 0.0,
    'scroll': ?scrollOffset,
    'editor': ?editorKind,
    'preview': ?preview,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteMemento &&
      other.selectionBase == selectionBase &&
      other.selectionExtent == selectionExtent &&
      other.scrollLine == scrollLine &&
      other.scrollFraction == scrollFraction &&
      other.scrollOffset == scrollOffset &&
      other.editorKind == editorKind &&
      other.preview == preview;

  @override
  int get hashCode => Object.hash(
    selectionBase,
    selectionExtent,
    scrollLine,
    scrollFraction,
    scrollOffset,
    editorKind,
    preview,
  );
}
