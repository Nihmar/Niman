import 'package:flutter/foundation.dart';
import 'package:niman/src/editor/outline.dart';

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

  /// Puts [markdown] at the caret, one undo step: on the caret's line when
  /// it is one line, on lines of its own when it is more (#265).
  void insertAtCaret(String markdown);

  /// Opens the find bar over the note, as Ctrl+F does with the editor
  /// focused; [replace] opens the replace row too. The screen that shows
  /// the note asks when the key was pressed with the focus anywhere else —
  /// a file open on its own takes no focus into the editor by itself.
  /// Nothing happens in preview-only mode, where the editor and its bar are
  /// not on screen.
  void openFind({bool replace = false});
}
