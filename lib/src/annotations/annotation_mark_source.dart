/// What a file's pane asks to mark where the file was annotated (#285).
library;

import 'package:niman/src/annotations/annotation_mark.dart';

/// The marks of the open library's files, and the way to their notes.
abstract interface class AnnotationMarkSource {
  /// Where the file at library-relative [path] was annotated.
  Future<List<AnnotationMark>> marksOf(String path);

  /// Fires when a note may have changed: the marks are asked again.
  Stream<Object?> get changes;

  /// Opens the note [mark] is in, at the annotation.
  void open(AnnotationMark mark);
}
