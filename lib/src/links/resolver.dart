/// Wiki-target and Markdown-href resolution (design.md: links/resolver.dart).
///
/// Resolution runs against the index only — `note_stems` is a
/// `COLLATE NOCASE` keyed table, so a lookup is O(log n) and never walks
/// the tree. Resolution order (M3 plan): exact stem → unique? → path-prefix
/// filter (the target itself qualifies the stem) → the caller's ambiguous
/// picker.
library;

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/percent.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:path/path.dart' as p;

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
  new(this._db);

  final IndexDatabase _db;

  @override
  Future<ResolveResult> resolveWiki(String target, {String? from}) {
    return _resolvePath(target, from: from, beside: false);
  }

  @override
  Future<ResolveResult> resolveMarkdown(String href, {String? from}) {
    final h = href.trim();
    if (h.isEmpty) return Future.value(UnresolvedNote(target: href));
    if (hasScheme(h)) return Future.value(ExternalLink(url: h));
    if (h.startsWith('#')) {
      return Future.value(LocalAnchor(heading: h.substring(1)));
    }
    final read = _markdownPath(h);
    // A file: a note, or one that is not (a PDF, a book, a picture).
    if (read == null) return Future.value(UnresolvedNote(target: h));
    return _resolvePath(read, from: from, beside: true);
  }

  /// The href [h] (trimmed, no scheme, not an anchor) as a path to resolve:
  /// its path percent-decoded, as Obsidian writes a Markdown link
  /// (`My%20Note.md`), its fragment left alone, a book's place (#282)
  /// decoding its own parts. Null when it names no file (no extension).
  /// Opening a link and indexing it read it through this one function.
  static String? _markdownPath(String h) {
    final hash = h.indexOf('#');
    final path = percentDecoded(hash == -1 ? h : h.substring(0, hash));
    if (p.url.extension(path).isEmpty) return null;
    return hash == -1 ? path : path + h.substring(hash);
  }

  /// Whether the note at [path] is one a target naming [target] — already
  /// normalized, `.md` dropped (`folder/note`) — qualifies among the notes
  /// that share its stem: the whole path, or its tail after a `/`.
  ///
  /// For a `.md` note the target's extension was stripped, so the note is
  /// matched as `$target.md`; a non-md target (an embed, `foo.png`) keeps
  /// its extension and matches as it is. The suggester (#475) writes the
  /// shortest target this admits for exactly one note, so what it writes is
  /// what this resolves.
  ///
  /// A Windows device stem answers as it is and as `sanitizeName` moved it
  /// aside: the note `[[Aux]]` creates is `_Aux.md`, and the link has to
  /// find it (#491).
  ///
  /// With [exact] the target is the whole path and nothing else qualifies:
  /// what a leading `/` or a `..` names (#491).
  static bool pathMatches(String path, String target, {bool exact = false}) {
    final lower = path.toLowerCase();
    for (final t in _targetVariants(target)) {
      final withMd = '$t.md';
      if (lower == t || lower == withMd) return true;
      if (!exact && (lower.endsWith('/$t') || lower.endsWith('/$withMd'))) {
        return true;
      }
    }
    return false;
  }

  /// [target] and, when its last segment's stem names a Windows device, the
  /// same target with that segment moved aside (`Aux` → `_Aux`): the name
  /// the file the app created for it has.
  static Iterable<String> _targetVariants(String target) sync* {
    yield target;
    final cut = target.lastIndexOf('/');
    final segment = cut == -1 ? target : target.substring(cut + 1);
    final moved = withoutReservedStem(segment);
    if (moved != segment) {
      yield cut == -1 ? moved : '${target.substring(0, cut + 1)}$moved';
    }
  }

  /// Whether [s] starts with a URI scheme (`http://`, `https://`, …).
  static bool hasScheme(String s) =>
      RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(s);

  /// Normalizes a target for matching: backslashes to slashes, `./` and
  /// whitespace trimmed, lowercased. The `.md` extension and any
  /// `#fragment` are handled by [_resolvePath], in that order.
  static String normalizeTarget(String target) => _clean(target).toLowerCase();

  /// Whether [target], written in a note, names something that depends on
  /// the folder the note is in: a Markdown path is tried beside the note
  /// first, and a wiki target that starts with `/`, or has a `.` or `..`
  /// segment, is walked from it (#491). A bare wiki name is not: it is found
  /// by its name wherever the note is.
  static bool dependsOnLocation(String target, {required bool markdown}) {
    if (markdown) return true;
    final kept = _clean(target);
    final hash = kept.indexOf('#');
    final path = hash == -1 ? kept : kept.substring(0, hash);
    return path.startsWith('/') ||
        path.split('/').any((s) => s == '.' || s == '..');
  }

  /// [target] trimmed, its backslashes slashes, its leading `./` gone.
  static String _clean(String target) {
    var t = target.trim().replaceAll(r'\', '/');
    while (t.startsWith('./')) {
      t = t.substring(2);
    }
    return t;
  }

  /// [raw] read into what it names ([_Spec]): its target normalized
  /// ([normalizeTarget], `.md` dropped, its path walked by [_walk]) and its
  /// `#fragment`, null when empty. The fragment keeps its case: a heading is
  /// found by its slug whatever its case, and a place in a book (#282) names
  /// a file in it, whose name has one.
  ///
  /// [from] is the linking note's path when it is known, and [beside] asks
  /// a plain path to be tried next to it first (Markdown links; a wiki
  /// target is a name, not a path). Null when the target names nothing: it
  /// climbs out of the library.
  static _Spec? _split(String raw, {required bool beside, String? from}) {
    final kept = _clean(raw);
    final hash = kept.indexOf('#');
    var target = (hash == -1 ? kept : kept.substring(0, hash)).toLowerCase();
    if (target.endsWith('.md')) target = target.substring(0, target.length - 3);
    final fragment = hash == -1 || hash == kept.length - 1
        ? null
        : kept.substring(hash + 1);
    if (target.isEmpty) {
      return (t: '', heading: fragment, exact: false, near: null);
    }
    final segments = target.split('/');
    if (!target.startsWith('/') &&
        !segments.any((s) => s == '.' || s == '..')) {
      // A plain path: found as its tail wherever it sits, and — for a
      // Markdown link — first exactly where the note beside it would have it.
      final folder = beside ? _folderOf(from) : null;
      return (
        t: target,
        heading: fragment,
        exact: false,
        near: folder == null ? null : [...folder, target].join('/'),
      );
    }
    final walked = _walk(segments, from, rooted: target.startsWith('/'));
    if (walked == null) return null;
    return (t: walked, heading: fragment, exact: true, near: null);
  }

  /// The folder segments of the note at library-relative [from], lowercased
  /// (a target is); null when [from] is not known.
  static List<String>? _folderOf(String? from) {
    if (from == null) return null;
    final segments = [
      for (final s in from.replaceAll(r'\', '/').toLowerCase().split('/'))
        if (s.isNotEmpty && s != '.') s,
    ];
    if (segments.isNotEmpty) segments.removeLast();
    return segments;
  }

  /// The library-relative path [segments] name (#491): a leading `/` starts
  /// at the library root, anything else at the folder of the note at [from].
  /// `.` stays where it is and `..` goes up a folder. Null when the path
  /// names nothing: it climbs out of the library, or ends at the root
  /// itself.
  ///
  /// With no [from] a relative path starts at the root and what climbs past
  /// it is dropped, as it always was: there is no note to walk from.
  static String? _walk(
    List<String> segments,
    String? from, {
    required bool rooted,
  }) {
    final path = <String>[if (!rooted) ...?_folderOf(from)];
    for (final segment in segments) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment != '..') {
        path.add(segment);
        continue;
      }
      if (path.isNotEmpty) {
        path.removeLast();
      } else if (rooted || from != null) {
        return null;
      }
    }
    return path.isEmpty ? null : path.join('/');
  }

  /// Resolves a path-style target: exact stem first (indexed, O(log n)),
  /// then the same-stem candidates filtered by the target's own path
  /// prefix — the "shortest unique path prefix" rule — so `[[a/note]]`
  /// beats `[[note]]` when both `a/note.md` and `b/note.md` exist.
  ///
  /// A `#fragment` (markdown hrefs) is split off first and rides along on
  /// the result.
  Future<ResolveResult> _resolvePath(
    String raw, {
    required String? from,
    required bool beside,
  }) async {
    if (_clean(raw).isEmpty) return UnresolvedNote(target: raw);
    final spec = _split(raw, from: from, beside: beside);
    if (spec == null) return UnresolvedNote(target: raw);
    final t = spec.t;
    if (t.isEmpty) {
      return LocalAnchor(heading: spec.heading ?? '');
    }
    final stem = t.contains('/') ? t.substring(t.lastIndexOf('/') + 1) : t;
    final stems = await (_db.select(
      _db.noteStems,
    )..where((s) => s.stem.isIn(_stemVariants(stem)))).get();
    if (stems.isEmpty) return UnresolvedNote(target: raw);
    final ids = <int>{for (final s in stems) s.noteId};
    final notes = await (_db.select(
      _db.notes,
    )..where((n) => n.id.isIn(ids))).get();
    return _resolveFromCandidates(raw: raw, spec: spec, notes: notes);
  }

  /// The stems [segment] — a target's last segment — can be indexed under:
  /// itself, and the reserved-stem name `sanitizeName` would have given the
  /// file ([withoutReservedStem], #491).
  static Set<String> _stemVariants(String segment) {
    final moved = withoutReservedStem(segment);
    return moved == segment ? {segment} : {segment, moved};
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
    final byStem = <String, List<(LinkQuery, _Spec)>>{};
    for (final query in queries) {
      if (out.containsKey(query)) continue;
      final written = query.target;
      // A Markdown href is read as opening it reads it: percent-decoded.
      final raw = query.markdown ? _markdownPath(written.trim()) : written;
      if (raw == null || _clean(raw).isEmpty) {
        out[query] = UnresolvedNote(target: written);
        continue;
      }
      final spec = _split(raw, from: query.from, beside: query.markdown);
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
      (byStem[stem] ??= <(LinkQuery, _Spec)>[]).add((query, spec));
    }
    for (final MapEntry(key: stem, value: group) in byStem.entries) {
      final stems = await (_db.select(
        _db.noteStems,
      )..where((s) => s.stem.isIn(_stemVariants(stem)))).get();
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
    required _Spec spec,
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
        if (pathMatches(n.path, near, exact: true)) {
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
          if (pathMatches(n.path, t, exact: true)) n,
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
        if (pathMatches(n.path, t)) n,
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

/// A link target read: `t` the normalized path (lowercased, `.md` dropped,
/// `.` and `..` walked), `heading` its `#fragment`, and how `t` is matched.
///
/// `exact` — the target names one whole path, from the root (a leading `/`
/// or a `..`); otherwise it is a tail, matched wherever it sits. `near` — a
/// whole path to try first, the one beside the note a Markdown link is
/// written in. An empty `t` is the note itself (`#heading`).
typedef _Spec = ({String t, String? heading, bool exact, String? near});
