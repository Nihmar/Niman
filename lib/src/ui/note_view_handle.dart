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
}
