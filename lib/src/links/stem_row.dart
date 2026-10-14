/// One `note_stems` row joined to its note.
final class StemRow {
  /// The row of the stem [stem] (`source`: [source]) of the note [id] at
  /// [path].
  const new({
    required this.id,
    required this.path,
    required this.stem,
    required this.source,
  });

  /// The note's id in the index.
  final int id;

  /// The note's library-relative path.
  final String path;

  /// The normalized name the row indexes: the file's own or an alias.
  final String stem;

  /// Where [stem] comes from: `file` for the file's own name.
  final String source;
}
