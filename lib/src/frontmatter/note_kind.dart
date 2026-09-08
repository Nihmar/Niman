import 'package:copist/src/ui/kinds/list_note.dart';
import 'package:flutter/widgets.dart';

/// The note text as seen and edited by a kind GUI.
abstract interface class NoteKindHost {
  /// The full note text (frontmatter + body).
  String get text;

  /// Applies a byte-stable edit to the note text; the host persists it.
  void applyEdit(String newText);
}

/// A note-kind GUI: the dedicated UI for notes whose frontmatter declares
/// `type: <kind>` instead of the plain editor.
abstract interface class NoteKindGUI {
  /// The frontmatter `type` value this GUI handles (e.g. `list`).
  String get type;

  /// Builds the kind body over [host]'s note text.
  Widget buildBody(BuildContext context, NoteKindHost host);
}

/// The note-kind registry (T-TK-02).
///
/// Kinds are registered explicitly here — there is no filesystem
/// discovery. A note whose `type` is unknown (or absent) is a plain note:
/// the editor, with no kind GUI. Adding a kind = adding a file here and
/// registering it in [_all].
final class NoteKinds {
  NoteKinds._();

  static final List<NoteKindGUI> _all = [
    ListKindGui(),
  ];

  /// The GUI for [type], or null for an unknown or absent kind.
  static NoteKindGUI? forType(String? type) {
    if (type == null) return null;
    for (final kind in _all) {
      if (kind.type == type) return kind;
    }
    return null;
  }
}
