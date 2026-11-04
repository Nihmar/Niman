/// Text put into the open note from outside the editor's own keys: a paste,
/// the links of attached files, and what the selection holds (issue #100
/// moved them out of `note_view.dart`).
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/note_paste.dart';
import 'package:niman/src/ui/note_view_handle.dart';

/// Reads and writes the selection of the note on the editor surface, through
/// the surface's own door: each edit is one undo step, saved like any other.
final class NoteInserts {
  /// Inserts into the note on [surface].
  const new({
    required this.surface,
    required this.canInsert,
    required this.mounted,
    required this.focus,
    required this.onInserted,
  });

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// Whether the note takes an edit from outside the editor.
  final bool Function() canInsert;

  /// Whether the view is still mounted.
  final bool Function() mounted;

  /// Gives the editor the keyboard.
  final VoidCallback focus;

  /// Attachment links went in: the statistics and the preview follow.
  final VoidCallback onInserted;

  /// The text the selection covers, or empty when it is collapsed or the
  /// note takes no insert.
  String get selectedText {
    final surface = this.surface();
    if (!canInsert() || surface == null) return '';
    final at = surface.selection.clampTo(surface.buffer.length);
    return at.isCollapsed ? '' : surface.buffer.substring(at.start, at.end);
  }

  /// Puts the attachment links [text] in place of the selection; false when
  /// the note takes no insert.
  bool insertAttachmentLinks(String text) {
    final surface = this.surface();
    if (!mounted() || !canInsert() || surface == null) return false;
    surface.replaceSelection(text);
    focus();
    onInserted();
    return true;
  }

  /// The two units either side of the selection, or null with no note.
  SelectionSurroundings? surroundings() {
    final surface = this.surface();
    if (surface == null) return null;
    final buffer = surface.buffer;
    final at = surface.selection.clampTo(buffer.length);
    return (
      before: buffer.substring(at.start < 2 ? 0 : at.start - 2, at.start),
      after: buffer.substring(
        at.end,
        at.end + 2 > buffer.length ? buffer.length : at.end + 2,
      ),
    );
  }

  /// Pastes [text] in place of the selection, and answers where it went and
  /// what the note stored of it; null when the note takes no insert.
  PastedText? pasteText(String text) {
    final surface = this.surface();
    if (!canInsert() || surface == null) return null;
    final buffer = surface.buffer;
    final at = surface.selection.clampTo(buffer.length);
    final before = buffer.length;
    surface.replaceSelection(text);
    // What the note stored, which a Windows clipboard's `\r\n` pasted into
    // an LF note is shorter than.
    final stored = buffer.length - before + (at.end - at.start);
    focus();
    return (
      start: at.start,
      text: buffer.substring(at.start, at.start + stored),
    );
  }

  /// Replaces the [pasted] text with [text], when the note still holds it
  /// where it went.
  void replacePasted(PastedText pasted, String text) {
    final surface = this.surface();
    if (surface == null) return;
    final buffer = surface.buffer;
    final end = pasted.start + pasted.text.length;
    if (end > buffer.length) return;
    if (buffer.substring(pasted.start, end) != pasted.text) return;
    surface.replaceRange(pasted.start, end, text);
    focus();
  }
}
