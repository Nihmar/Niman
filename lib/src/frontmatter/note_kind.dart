import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/kinds/audio_note.dart';
import 'package:niman/src/ui/kinds/flashcards/flashcard_kind.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_kind.dart';
import 'package:niman/src/ui/kinds/list_note.dart';
import 'package:niman/src/ui/kinds/shopping_list_note.dart';
import 'package:niman/src/ui/kinds/slides/slides_kind.dart';

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

  /// The absolute path an embed's [target] names, or null: the pictures
  /// a kind draws from the note's Markdown (a slide's, #534).
  Future<String?> resolveEmbed(String target);

  /// Follows a Markdown link's [href] the way the note's preview does.
  void openLink(BuildContext context, String href);

  /// Follows a wikilink, [inner] being what sits between `[[` and `]]`.
  void openWikiLink(BuildContext context, String inner);

  /// Shows the note's Markdown preview in place of the kind's view, or
  /// null where the screen has no such switch to make.
  VoidCallback? get showMarkdown;
}

/// A note-kind GUI: the dedicated UI for notes whose frontmatter declares
/// `type: <kind>` instead of the plain editor.
abstract interface class NoteKindGUI {
  /// The frontmatter `type` value this GUI handles (e.g. `list`).
  String get type;

  /// The feature that has to be on for this kind to be shown (#1109):
  /// declared by each kind, so none ships without saying which.
  LibraryFeature get feature;

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
  new _();

  static final List<NoteKindGUI> _all = [
    ListKindGui(),
    ShoppingListKindGui(),
    AudioKindGui(),
    SlidesKindGui(),
    FlashcardKindGui(),
    KanbanKindGui(),
  ];

  /// The `type` of every registered kind.
  static List<String> get types => [for (final kind in _all) kind.type];

  /// The GUI for [type], or null for an unknown or absent kind, or one
  /// whose feature is off under [features] (#1109): the note then opens in
  /// the plain editor, its `type:` kept and its bytes untouched.
  static NoteKindGUI? forType(String? type, Features features) {
    final kind = _registered(type);
    if (kind == null || !features.isOn(kind.feature)) return null;
    return kind;
  }

  static NoteKindGUI? _registered(String? type) {
    if (type == null) return null;
    for (final kind in _all) {
      if (kind.type == type) return kind;
    }
    return null;
  }
}

/// The feature a note of `type: [type]` needs, or null for a plain note or
/// a `type` no kind is registered for (#1109).
///
/// Answered by the registry, where each kind names its own, so a new kind
/// cannot be registered without one.
LibraryFeature? featureOfKind(String? type) =>
    NoteKinds._registered(type)?.feature;
