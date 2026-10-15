/// Which links of one note named a file that is about to move (#919).
///
/// A note is rewritten after a move because the index has an edge from it to
/// a moved file; but an edge says that *some* link of the note named it, not
/// which. Two notes may share a name (`a/b.md`, `z/b.md`) and a link by that
/// name, or by a tail of the path, names one of them: following every link
/// that looks like the moved file would retarget the other one's.
///
/// So the question is put to the resolver, before the move, while the index
/// still says what each link named: the links that resolved to a moved file
/// are the ones to follow, and the file each resolved to is the one they
/// follow. Only the links that could name a moved file by their name are
/// asked, so the cost is the links of the notes already visited, never a
/// walk of the library.
library;

import 'package:niman/src/links/link_definitions.dart';
import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/links/link_query.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';

/// The links of a note that resolved to a moved file, each with the old path
/// of the file it resolved to.
///
/// A link is told by its target text and its form (a wikilink or a Markdown
/// href), as the index tells them: the same text written twice in a note
/// names the same file twice.
final class MovedLinks {
  const new _(this._old);

  /// No link of the note resolved to a moved file.
  static const MovedLinks none = MovedLinks._(<(String, bool), String>{});

  /// The links of the note [text], which stood at [from] (library-relative,
  /// where its links were written against), that [resolver] — over the
  /// index as it was before the move — resolves to a file [moves] carries.
  static Future<MovedLinks> of(
    String text, {
    required String from,
    required LinkMoves moves,
    required LinkResolver resolver,
  }) async {
    final asked = <LinkQuery>{};
    // A definition's destination is a link's href: what `[text][label]`
    // names (#972).
    for (final link in [
      ...parseLinks(text, includeEmbeds: true),
      ...linkDefinitionsOf(text),
    ]) {
      final query = linkQueryOf(link, from);
      if (query != null &&
          moves.mayName(query.target, markdown: query.markdown)) {
        asked.add(query);
      }
    }
    if (asked.isEmpty) return none;
    final resolved = await resolver.resolveQueries(asked);
    final old = <(String, bool), String>{};
    for (final MapEntry(key: query, value: outcome) in resolved.entries) {
      if (outcome is ResolvedNote && moves.moved(outcome.note.path)) {
        old[(query.target, query.markdown)] = outcome.note.path;
      }
    }
    return old.isEmpty ? none : MovedLinks._(old);
  }

  final Map<(String, bool), String> _old;

  /// The old path of the moved file the link written [target] resolved to,
  /// or null when it resolved to nothing that moved. [markdown] tells a
  /// Markdown href from a wiki target.
  String? oldPathOf(String target, {required bool markdown}) =>
      _old[(target, markdown)];
}
