import 'package:flutter/foundation.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';

/// Text a paste put in a note: where it starts, and the text as the note
/// stored it — its line endings the note's own.
typedef PastedText = ({int start, String text});

/// A note's spelling, as a review lists and fixes it (#712): a pass over
/// the note, the suggestions for a word, a word replaced and a word shown,
/// a word added to the library's dictionary, the words ignored, and what
/// tells of an edit.
///
/// `apply` and `reveal` answer whether they acted: false when the note no
/// longer holds the issue's word where the pass found it (#908), and then
/// they have touched nothing.
typedef SpellReview = ({
  SpellScan Function() start,
  List<String> Function(String word) suggest,
  bool Function(SpellIssue issue, String replacement) apply,
  bool Function(SpellIssue issue) reveal,
  Future<void> Function(String word) addWord,
  Set<String> ignored,
  Listenable edited,
  bool available,
});

/// What of an open note the panels beside it read and drive (#175): the
/// right dock on a wide window, the ⋮ menu's sheets on a phone.
///
/// A note's view implements it; the shell reaches the one it needs
/// through the view's key.
abstract interface class NoteViewHandle {
  /// The note's headings, as the editor last counted them: it changes as
  /// the note is edited, a moment after the typing stops.
  ValueListenable<List<OutlineEntry>> get outline;

  /// The note's text as it is in the editor now, saved or not.
  String get currentText;

  /// Takes the caret to the heading on source [line] and shows it.
  void jumpToHeading(int line);

  /// Whether the note takes Markdown where its caret is: a Markdown note
  /// whose text is on screen, not a kind's own view of it.
  bool get canInsert;

  /// Rewrites the note's frontmatter `type` — the kind its body is built
  /// from — as one undoable edit, saved at once. Null removes the key and
  /// leaves a plain note. The note's ⋮ menu is the caller: a list turns
  /// into a shopping list and back (#309).
  void setNoteKind(String? type);

  /// Replaces the note's whole text with [newText] as one undoable edit,
  /// saved at once: what a kind's own view does to its note, and the ⋮
  /// menu does for it (a deck's question and answer columns, #533).
  void applyKindEdit(String newText);

  /// Puts [markdown] at the caret, one undo step: on the caret's line when
  /// it is one line, on lines of its own when it is more (#265).
  void insertAtCaret(String markdown);

  /// Puts two columns at the caret, on lines of their own, one undo step,
  /// the first column's text selected (#729).
  void insertColumns();

  /// Puts [text] in place of the selection, as a paste does, one undo
  /// step; what the note stored, and where, or null when the note takes
  /// no text there ([canInsert]).
  PastedText? pasteText(String text);

  /// Puts [text] in place of what [pasted] put in, while the note still
  /// says it there: Paste as Markdown's Undo, which leaves the plain text
  /// (#531). Does nothing once that part of the note has changed.
  void replacePasted(PastedText pasted, String text);

  /// Replaces the list at the caret with a `mindmap` fence, one undo step
  /// (#530). Does nothing when the caret is not in a list.
  void convertListToMindMap();

  /// Opens the find bar over the note, as Ctrl+F does with the editor
  /// focused; [replace] opens the replace row too. The screen that shows
  /// the note asks when the key was pressed with the focus anywhere else —
  /// a file open on its own takes no focus into the editor by itself.
  /// Nothing happens in preview-only mode, where the editor and its bar are
  /// not on screen.
  void openFind({bool replace = false});

  /// Puts the keyboard in the note: the editor's caret, or the read pane's
  /// keys in the preview. A note still loading takes it as it appears. The
  /// deck asks it of the note that comes on stage when the keyboard was in
  /// the one that left (#1074).
  void takeFocus();

  /// The path of the note on screen, as the shell gave it.
  String get notePath;

  /// The note's spelling review, for the dock's pane (#712); null where
  /// the note has no spell check.
  SpellReview? get spellReview;

  /// The absolute path a picture's [target] names in this note, or null.
  Future<String?> resolveEmbed(String target);
}
