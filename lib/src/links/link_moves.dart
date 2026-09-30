/// The files one rename or move carried, indexed once for every note whose
/// links are rewritten after it (#507).
library;

/// How a written target was found among the moved files.
enum MoveMatch {
  /// The candidate is a moved file's whole old path.
  whole,

  /// The candidate is the tail of a moved file's old path, the way the
  /// resolver finds a note anywhere by the end of its path.
  tail,
}

/// Every file that moved, old library-relative path -> new, with its
/// extension (notes and attachments alike).
///
/// Built once per rename and asked once per link: a folder of a hundred
/// thousand files, cited by a thousand notes, is a hash lookup per link and
/// not a walk of the folder per link. Matching is case-insensitive, with or
/// without `.md`, whole or as a tail — the ways the resolver finds a note.
final class LinkMoves {
  /// Indexes [moves], old path -> new path.
  new(Map<String, String> moves) {
    for (final MapEntry(key: old, value: moved) in moves.entries) {
      final key = old.toLowerCase();
      _whole[key] = moved;
      (_byName[_nameOf(key)] ??= []).add((key, moved));
    }
  }

  /// Old path, lowercased -> new path.
  final Map<String, String> _whole = {};

  /// A moved file's own name, lowercased -> its (old path lowercased, new
  /// path) pairs: the few a tail can match, found without a walk.
  final Map<String, List<(String, String)>> _byName = {};

  /// Whether nothing moved.
  bool get isEmpty => _whole.isEmpty;

  /// The new path of the file [candidate] names, and how it was matched —
  /// or null when it names nothing that moved. [tail] also looks for it as
  /// the end of a moved path.
  ({String path, MoveMatch match})? find(String candidate, {bool tail = true}) {
    final c = candidate.toLowerCase();
    final withMd = '$c.md';
    final whole = _whole[c] ?? _whole[withMd];
    if (whole != null) return (path: whole, match: MoveMatch.whole);
    if (!tail) return null;
    for (final written in [c, withMd]) {
      for (final (key, moved)
          in _byName[_nameOf(written)] ?? const <(String, String)>[]) {
        if (key.endsWith('/$written')) {
          return (path: moved, match: MoveMatch.tail);
        }
      }
    }
    return null;
  }

  static String _nameOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash < 0 ? path : path.substring(slash + 1);
  }
}
