/// Wiki-target and Markdown-href resolution (design.md: links/resolver.dart).
///
/// Resolution runs against the index only — `note_stems` is a
/// `COLLATE NOCASE` keyed table, so a lookup is O(log n) and never walks
/// the tree. Resolution order (M3 plan): exact stem → unique? → path-prefix
/// filter (the target itself qualifies the stem) → the caller's ambiguous
/// picker.
library;

import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/link_path.dart';

/// The normalized stem of a note file name: lowercased, with the `.md`
/// extension (case-insensitive) stripped. `My Note.md` → `my note`.
///
/// The indexer stores these in `note_stems` (source `file`) on
/// insert/rename/delete; the resolver looks them up with the same function,
/// so both sides agree on the text.
String noteStem(String name) {
  var n = name.toLowerCase();
  if (n.endsWith('.md')) n = n.substring(0, n.length - 3);
  return n;
}

/// The outcome of resolving a link target.
sealed class ResolveResult {
  /// Creates a result.
  const new();
}

/// The target is one note (exactly one candidate).
final class ResolvedNote extends ResolveResult {
  /// Creates a resolved result for [note], optionally with a heading
  /// anchor (`note.md#Heading`).
  const new({required this.note, this.heading});

  /// The resolved note row.
  final Note note;

  /// The anchor text after `#` (null when there is none).
  final String? heading;
}

/// The target is a heading anchor in the current note (`#Heading`).
final class LocalAnchor extends ResolveResult {
  /// Creates a local-anchor result for [heading].
  const new({required this.heading});

  /// The anchor text.
  final String heading;
}

/// The target matches more than one note; the caller shows a picker.
final class AmbiguousNote extends ResolveResult {
  /// Creates an ambiguous result with [candidates] (shortest path first).
  const new({required this.candidates});

  /// Candidate note rows.
  final List<Note> candidates;
}

/// No note matches the target (a dead link — M3 has no dead-link UI yet).
final class UnresolvedNote extends ResolveResult {
  /// Creates an unresolved result for the raw [target] text.
  const new({required this.target});

  /// The target as the user wrote it.
  final String target;
}

/// The link points outside the library (an http/https or other URL).
final class ExternalLink extends ResolveResult {
  /// Creates an external result for [url].
  const new({required this.url});

  /// The URL to open.
  final String url;
}

/// Resolves wiki targets (`[[…]]` target part) and markdown hrefs against
/// the note index — the source the UI talks to; [LinkResolver] is the
/// production implementation over drift, widget tests inject a fake.
abstract interface class LinkSource {
  /// Resolves a wiki target (the `[[…]]` content without brackets, e.g.
  /// `note`, `folder/note`, `note.md`).
  ///
  /// [from] is the library-relative path of the note the link is written
  /// in, when it is known: a `..` in the target walks from that note's
  /// folder (#491). A leading `/` is the library root whatever [from] is.
  Future<ResolveResult> resolveWiki(String target, {String? from});

  /// Resolves a markdown `[text](href)`.
  ///
  /// [from] is as for [resolveWiki]; here it also makes a plain relative
  /// path (`a.md`, `sub/a.md`) prefer the note beside the linking one, the
  /// way Markdown reads a path.
  Future<ResolveResult> resolveMarkdown(String href, {String? from});
}

/// One link to resolve in a batch ([LinkResolver.resolveQueries]): the
/// `target` as written, the library-relative path of the note it is written
/// in (`from`, null when unknown), and whether it is a Markdown href rather
/// than a wiki target.
typedef LinkQuery = ({String target, String? from, bool markdown});

/// Resolves wiki targets (`[[…]]` target part) and markdown hrefs against
/// the note index. Not a DAO and not stateful: callers create one per use.
final class LinkResolver implements LinkSource {
  /// Creates a resolver over the drift [IndexDatabase].
  const new(this._db);

  final IndexDatabase _db;

  @override
  Future<ResolveResult> resolveWiki(String target, {String? from}) {
    return _resolvePath(
      target,
      LinkPaths.read(target, from: from, beside: false),
    );
  }

  @override
  Future<ResolveResult> resolveMarkdown(String href, {String? from}) {
    final h = href.trim();
    if (h.isEmpty) return Future.value(UnresolvedNote(target: href));
    if (LinkPaths.hasScheme(h)) return Future.value(ExternalLink(url: h));
    if (h.startsWith('#')) {
      return Future.value(LocalAnchor(heading: h.substring(1)));
    }
    final read = LinkPaths.markdownTarget(h);
    // A file: a note, or one that is not (a PDF, a book, a picture).
    if (read == null) return Future.value(UnresolvedNote(target: h));
    return _resolvePath(
      _written(read),
      LinkPaths.readPath(
        read.path,
        fragment: read.fragment,
        from: from,
        beside: true,
      ),
    );
  }

  /// A Markdown target as one text, for a result to name what was asked:
  /// the path, then `#` and the fragment. Only for naming — it is never
  /// read back, the two parts are kept apart to resolve.
  static String _written(MarkdownTarget target) => target.fragment == null
      ? target.path
      : '${target.path}#${target.fragment}';

  /// Resolves a path-style target: exact stem first (indexed, O(log n)),
  /// then the same-stem candidates filtered by the target's own path
  /// prefix — the "shortest unique path prefix" rule — so `[[a/note]]`
  /// beats `[[note]]` when both `a/note.md` and `b/note.md` exist.
  ///
  /// [raw] is the target as asked, to name it in an unresolved result; [spec]
  /// is it read ([LinkPaths.read]), null when it names nothing. A
  /// `#fragment` (markdown hrefs) is already split off and rides along on
  /// the result.
  Future<ResolveResult> _resolvePath(String raw, LinkSpec? spec) async {
    if (LinkPaths.clean(raw).isEmpty) return UnresolvedNote(target: raw);
    if (spec == null) return UnresolvedNote(target: raw);
    final t = spec.t;
    if (t.isEmpty) {
      return LocalAnchor(heading: spec.heading ?? '');
    }
    final stem = t.contains('/') ? t.substring(t.lastIndexOf('/') + 1) : t;
    final stems = await (_db.select(
      _db.noteStems,
    )..where((s) => s.stem.isIn(LinkPaths.stemVariants(stem)))).get();
    if (stems.isEmpty) return UnresolvedNote(target: raw);
    final ids = <int>{for (final s in stems) s.noteId};
    final notes = await (_db.select(
      _db.notes,
    )..where((n) => n.id.isIn(ids))).get();
    return _resolveFromCandidates(raw: raw, spec: spec, notes: notes);
  }

  /// Resolves many targets in a few queries (the indexer's content pass:
  /// one stems lookup for every distinct last segment, one notes lookup,
  /// then the same per-target rules — exact stem → unique? → path-prefix
  /// filter → ambiguous — applied in Dart). Same results as calling
  /// [resolveWiki] per target, at a fraction of the query count.
  ///
  /// Every target is read as written in the note at [from] (null when not
  /// known), as a Markdown href when [markdown] is set; the result is keyed
  /// by the target. Links from several notes go through [resolveQueries].
  Future<Map<String, ResolveResult>> resolveBatch(
    Iterable<String> targets, {
    String? from,
    bool markdown = false,
  }) async {
    final queries = [
      for (final t in targets) (target: t, from: from, markdown: markdown),
    ];
    final resolved = await resolveQueries(queries);
    return {for (final q in queries) q.target: resolved[q]!};
  }

  /// Resolves many links, each with the note it is written in, in as few
  /// queries as [resolveBatch]: one stems lookup per distinct last segment,
  /// one notes lookup, then the per-link rules in Dart (#491).
  Future<Map<LinkQuery, ResolveResult>> resolveQueries(
    Iterable<LinkQuery> queries,
  ) async {
    final out = <LinkQuery, ResolveResult>{};
    final byStem = <String, List<(LinkQuery, LinkSpec)>>{};
    for (final query in queries) {
      if (out.containsKey(query)) continue;
      final written = query.target;
      // A Markdown href is read as opening it reads it: percent-decoded,
      // its path and its fragment kept apart.
      final LinkSpec? spec;
      if (query.markdown) {
        final read = LinkPaths.markdownTarget(written.trim());
        spec = read == null || LinkPaths.clean(read.path).isEmpty
            ? null
            : LinkPaths.readPath(
                read.path,
                fragment: read.fragment,
                from: query.from,
                beside: true,
              );
      } else {
        spec = LinkPaths.clean(written).isEmpty
            ? null
            : LinkPaths.read(written, from: query.from, beside: false);
      }
      if (spec == null) {
        out[query] = UnresolvedNote(target: written);
        continue;
      }
      if (spec.t.isEmpty) {
        out[query] = LocalAnchor(heading: spec.heading ?? '');
        continue;
      }
      final t = spec.t;
      final stem = t.contains('/') ? t.substring(t.lastIndexOf('/') + 1) : t;
      (byStem[stem] ??= <(LinkQuery, LinkSpec)>[]).add((query, spec));
    }
    for (final MapEntry(key: stem, value: group) in byStem.entries) {
      final stems = await (_db.select(
        _db.noteStems,
      )..where((s) => s.stem.isIn(LinkPaths.stemVariants(stem)))).get();
      final ids = <int>{for (final s in stems) s.noteId};
      final notes = ids.isEmpty
          ? <Note>[]
          : await (_db.select(_db.notes)..where((n) => n.id.isIn(ids))).get();
      for (final (query, spec) in group) {
        out[query] = notes.isEmpty
            ? UnresolvedNote(target: query.target)
            : _resolveFromCandidates(
                raw: query.target,
                spec: spec,
                notes: notes,
              );
      }
    }
    return out;
  }

  /// The pure resolution tail over gathered candidates: same rules for the
  /// single-target and batched paths.
  ResolveResult _resolveFromCandidates({
    required String raw,
    required LinkSpec spec,
    required List<Note> notes,
  }) {
    final (:t, :heading, :exact, :near) = spec;
    // Shortest path first (a bare `[[note]]` picks the closest name); ties
    // in length are alphabetical.
    notes.sort((a, b) {
      final byLen = a.path.length.compareTo(b.path.length);
      return byLen != 0 ? byLen : a.path.compareTo(b.path);
    });
    // A Markdown path is the note beside the linking one when there is one.
    if (near != null) {
      for (final n in notes) {
        if (LinkPaths.pathMatches(n.path, near, exact: true)) {
          return ResolvedNote(note: n, heading: heading);
        }
      }
    }
    // A leading `/` or a `..` names one path, whole: there is no tail, and
    // no bare stem for the shortcut below to hand to an unrelated note
    // (#330).
    if (exact) {
      final named = <Note>[
        for (final n in notes)
          if (LinkPaths.pathMatches(n.path, t, exact: true)) n,
      ];
      if (named.isEmpty) return UnresolvedNote(target: raw);
      return named.length == 1
          ? ResolvedNote(note: named.single, heading: heading)
          : AmbiguousNote(candidates: named);
    }
    // A bare stem with one candidate resolves to it; a target that names a
    // path still has to name it — with a single candidate the shortcut used
    // to hand back the only note there was, so a stale `[[a/note]]` opened
    // an unrelated `xa/note.md` (#330).
    if (notes.length == 1 && !t.contains('/')) {
      return ResolvedNote(note: notes.single, heading: heading);
    }
    // Same-stem candidates: qualify by the target's path prefix.
    final qualified = <Note>[
      for (final n in notes)
        if (LinkPaths.pathMatches(n.path, t)) n,
    ];
    if (qualified.length == 1) {
      return ResolvedNote(note: qualified.single, heading: heading);
    }
    if (qualified.length > 1) {
      return AmbiguousNote(candidates: qualified);
    }
    // A path-qualified target that matches no note is a dead link; a bare
    // stem target still gets the picker over all of its candidates.
    return t.contains('/')
        ? UnresolvedNote(target: raw)
        : AmbiguousNote(candidates: notes);
  }
}
