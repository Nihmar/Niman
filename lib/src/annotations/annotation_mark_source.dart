/// What a file's pane asks to mark where the file was annotated (#285),
/// and to highlight it (#626).
library;

import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';

/// The marks of the open library's files, the way to their notes, and
/// what changes a highlight.
abstract interface class AnnotationMarkSource {
  /// Where the file at library-relative [path] was annotated.
  Future<List<AnnotationMark>> marksOf(String path);

  /// Fires when a note may have changed: the marks are asked again.
  Stream<Object?> get changes;

  /// Opens the note [mark] is in, at the annotation.
  void open(AnnotationMark mark);

  /// Highlights [annotation]'s passage in the colour last chosen.
  Future<void> highlight(Annotation annotation);

  /// Gives the highlight [mark] [colour], which becomes the one last
  /// chosen.
  Future<void> recolour(AnnotationMark mark, HighlightColour colour);

  /// Takes the highlight [mark] out of its note.
  Future<void> removeHighlight(AnnotationMark mark);

  /// Turns the highlight [mark] into an annotation saying [comment].
  Future<void> annotateHighlight(AnnotationMark mark, String comment);
}
