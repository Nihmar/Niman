import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/kinds/audio_note.dart';
import 'package:niman/src/ui/kinds/list_note.dart';

/// The note text as seen and edited by a kind GUI.
abstract interface class NoteKindHost {
  /// The full note text (frontmatter + body).
  String get text;

  /// Applies a byte-stable edit to the note text; the host persists it.
  void applyEdit(String newText);

  /// The library root, or null outside a library (tests).
  ///
  /// Kinds that link files (audio clips) resolve their targets under it.
  String? get libraryRoot;

  /// The note's absolute file path, for resolving note-relative links.
  String get notePath;

  /// The folder (library-relative) new attachments are copied into.
  String get attachmentsFolder;

  /// What new attachment links look like (wikilink or Markdown).
  LinkType get linkType;
}

/// A note-kind GUI: the dedicated UI for notes whose frontmatter declares
/// `type: <kind>` instead of the plain editor.
abstract interface class NoteKindGUI {
  /// The frontmatter `type` value this GUI handles (e.g. `list`).
  String get type;

  /// Builds the kind body over [host]'s note text.
  ///
  /// [focusAddItem] (one-shot, the list widget's "+") asks the body to
  /// focus its add-item input field so a new item can be typed straight
  /// away.
  Widget buildBody(
    BuildContext context,
    NoteKindHost host, {
    bool focusAddItem = false,
  });
}

/// The note-kind registry (T-TK-02).
///
/// Kinds are registered explicitly here — there is no filesystem
/// discovery. A note whose `type` is unknown (or absent) is a plain note:
/// the editor, with no kind GUI. Adding a kind = adding a file here and
/// registering it in [_all].
final class NoteKinds {
  new _();

  static final List<NoteKindGUI> _all = [ListKindGui(), AudioKindGui()];

  /// The GUI for [type], or null for an unknown or absent kind.
  static NoteKindGUI? forType(String? type) {
    if (type == null) return null;
    for (final kind in _all) {
      if (kind.type == type) return kind;
    }
    return null;
  }
}
