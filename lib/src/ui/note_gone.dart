/// A save found the note's file gone (#1321).
library;

/// The note on screen was deleted or moved away — by another program, by a
/// sync, by a delete elsewhere in the app — while the editor still holds
/// text for it.
///
/// A save does not write that text to the old path: that would bring a
/// deleted note back, and the delete would have achieved nothing. The text
/// stays in the editor, the note reads as unsaved, and the user is told and
/// can save it again — which creates the note afresh.
final class NoteGoneException implements Exception {
  /// The note at [path] is not on disk.
  const new(this.path);

  /// The note's absolute path.
  final String path;

  @override
  String toString() => 'NoteGoneException: "$path" is not on disk';
}
