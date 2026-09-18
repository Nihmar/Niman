import 'package:flutter/foundation.dart';

/// Where a note was left in its tab (issue #23): enough to put the reader
/// back — caret, selection, scroll, which editor, whether the preview was
/// up — for a tab whose editor is no longer mounted, or after a restart.
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
    this.scrollOffset,
    this.editorKind,
    this.preview,
  });

  /// Reads one written by [toJson]; anything malformed reads as absent.
  factory fromJson(Object? json) {
    if (json is! Map) return const NoteMemento();
    int? integer(Object? raw) => raw is int && raw >= 0 ? raw : null;
    final scroll = json['scroll'];
    final kind = json['editor'];
    final preview = json['preview'];
    return NoteMemento(
      selectionBase: integer(json['base']),
      selectionExtent: integer(json['extent']),
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

  /// How far the note was scrolled, in logical pixels.
  final double? scrollOffset;

  /// Which editor the note was in (`source` or `wysiwyg`).
  final String? editorKind;

  /// Whether the preview was showing.
  final bool? preview;

  /// Whether it remembers nothing.
  bool get isEmpty =>
      selectionBase == null &&
      selectionExtent == null &&
      scrollOffset == null &&
      editorKind == null &&
      preview == null;

  /// The fields that are set, under short keys.
  Map<String, Object> toJson() => {
    'base': ?selectionBase,
    'extent': ?selectionExtent,
    'scroll': ?scrollOffset,
    'editor': ?editorKind,
    'preview': ?preview,
  };

  @override
  bool operator ==(Object other) =>
      other is NoteMemento &&
      other.selectionBase == selectionBase &&
      other.selectionExtent == selectionExtent &&
      other.scrollOffset == scrollOffset &&
      other.editorKind == editorKind &&
      other.preview == preview;

  @override
  int get hashCode => Object.hash(
    selectionBase,
    selectionExtent,
    scrollOffset,
    editorKind,
    preview,
  );
}
