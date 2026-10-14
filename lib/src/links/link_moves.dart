/// The files one rename or move carried, indexed once for every note whose
/// links are rewritten after it (#507).
library;

import 'package:niman/src/links/link_path.dart';

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

  /// Whether the file at [oldPath] (any case) is one that moved.
  bool moved(String oldPath) => _whole.containsKey(oldPath.toLowerCase());

  /// Whether a link written [target] could name a moved file, judged by the
  /// name it ends with alone: a cheap test that never says no to a link that
  /// does (a false yes is settled by resolving the link).
  ///
  /// [target] is a wiki target as written, or — with [markdown] — a Markdown
  /// href, whose path is read percent-decoded and without its `#fragment`.
  bool mayName(String target, {required bool markdown}) {
    final path = markdown
        ? LinkPaths.markdownTarget(target.trim())?.path
        : target;
    if (path == null) return false;
    final cleaned = LinkPaths.clean(path);
    final name = cleaned.substring(cleaned.lastIndexOf('/') + 1).toLowerCase();
    if (name.isEmpty) return false;
    for (final variant in LinkPaths.stemVariants(name)) {
      if (_byName.containsKey(variant) || _byName.containsKey('$variant.md')) {
        return true;
      }
    }
    return false;
  }

  /// The new path of the file [candidate] names, and how it was matched —
  /// or null when it names nothing that moved. [tail] also looks for it as
  /// the end of a moved path.
  ///
  /// With [only], an old path (any case), no other moved file counts: the
  /// link is known to have resolved to that one, and a same-named file that
  /// moved with it is not what it named.
  ({String path, MoveMatch match})? find(
    String candidate, {
    bool tail = true,
    String? only,
  }) {
    final c = candidate.toLowerCase();
    final withMd = '$c.md';
    final wanted = only?.toLowerCase();
    for (final key in [c, withMd]) {
      if (wanted != null && key != wanted) continue;
      final whole = _whole[key];
      if (whole != null) return (path: whole, match: MoveMatch.whole);
    }
    if (!tail) return null;
    for (final written in [c, withMd]) {
      for (final (key, moved)
          in _byName[_nameOf(written)] ?? const <(String, String)>[]) {
        if (wanted != null && key != wanted) continue;
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
