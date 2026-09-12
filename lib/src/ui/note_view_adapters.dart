/// Adapter views over one open note (#51): the unsaved registry and the
/// kind GUIs talk to these instead of the note view's state, through
/// explicit getters and callbacks — so the state file grows no public
/// surface for them.
library;

import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// The [UnsavedNote] view over a note view's revision pair (T-PP-11): no
/// text copy, so the dirty bit cannot drift from the buffer.
final class UnsavedNoteAdapter implements UnsavedNote {
  /// Creates an adapter reading the note's live state through getters,
  /// saving through [saveForClose].
  const new({
    required this.notePath,
    required this.loading,
    required this.revision,
    required this.lastSavedRevision,
    required this.saveForClose,
  });

  /// The open note's path.
  final String Function() notePath;

  /// Whether a load is in flight.
  final bool Function() loading;

  /// The text-edit counter; the disk matches [lastSavedRevision].
  final int Function() revision;

  /// The revision the disk matches.
  final int Function() lastSavedRevision;

  /// Saves for close.
  final Future<void> Function() saveForClose;

  @override
  String get path => notePath();

  @override
  // While a load is in flight the buffer holds the outgoing note and the
  // incoming one has nothing to save yet: not dirty, so a close landing on
  // the swap cannot write stale text under the new path.
  bool get unsaved => !loading() && revision() != lastSavedRevision();

  @override
  Future<void> save() => saveForClose();
}

/// The kind GUIs' window onto the note (T-TK-02): the buffer text, and
/// byte-stable edits that persist through the regular save path.
final class NoteKindHostAdapter implements NoteKindHost {
  /// Creates a host reading [noteText] and applying [applyNoteEdit].
  const new({required this.noteText, required this.applyNoteEdit});

  /// The full note text (frontmatter + body).
  final String Function() noteText;

  /// Applies a byte-stable edit to the note text; the host persists it.
  final void Function(String newText) applyNoteEdit;

  @override
  String get text => noteText();

  @override
  void applyEdit(String newText) => applyNoteEdit(newText);
}
