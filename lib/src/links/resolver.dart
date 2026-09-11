/// Wiki-target and Markdown-href resolution (design.md: links/resolver.dart).
///
/// Resolution runs against the index only — `note_stems` is a
/// `COLLATE NOCASE` keyed table, so a lookup is O(log n) and never walks
/// the tree. Resolution order (M3 plan): exact stem → unique? → path-prefix
/// filter (the target itself qualifies the stem) → the caller's ambiguous
/// picker.
library;

import 'package:niman/src/db/index_database.dart';

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
  Future<ResolveResult> resolveWiki(String target);

  /// Resolves a markdown `[text](href)`.
  Future<ResolveResult> resolveMarkdown(String href);
}

/// Resolves wiki targets (`[[…]]` target part) and markdown hrefs against
/// the note index. Not a DAO and not stateful: callers create one per use.
final class LinkResolver implements LinkSource {
  /// Creates a resolver over the drift [IndexDatabase].
  new(this._db);

  final IndexDatabase _db;

  @override
  Future<ResolveResult> resolveWiki(String target) {
    return _resolvePath(target);
  }

  @override
  Future<ResolveResult> resolveMarkdown(String href) {
    final h = href.trim();
    if (h.isEmpty) return Future.value(UnresolvedNote(target: href));
    if (hasScheme(h)) return Future.value(ExternalLink(url: h));
    if (h.startsWith('#')) {
      return Future.value(LocalAnchor(heading: h.substring(1)));
    }
    if (!h.contains('.md')) return Future.value(UnresolvedNote(target: h));
    return _resolvePath(h);
  }

  /// Whether [s] starts with a URI scheme (`http://`, `https://`, …).
  static bool hasScheme(String s) =>
      RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(s);

  /// Normalizes a target for matching: backslashes to slashes, `./` and
  /// whitespace trimmed, lowercased. The `.md` extension and any
  /// `#fragment` are handled by [_resolvePath], in that order.
  static String normalizeTarget(String target) {
    var t = target.trim().replaceAll(r'\\', '/');
    while (t.startsWith('./')) {
      t = t.substring(2);
    }
    return t.toLowerCase();
  }

  /// Resolves a path-style target: exact stem first (indexed, O(log n)),
  /// then the same-stem candidates filtered by the target's own path
  /// prefix — the "shortest unique path prefix" rule — so `[[a/note]]`
  /// beats `[[note]]` when both `a/note.md` and `b/note.md` exist.
  ///
  /// A `#fragment` (markdown hrefs) is split off first and rides along on
  /// the result.
  Future<ResolveResult> _resolvePath(String raw) async {
    final t0 = normalizeTarget(raw);
    if (t0.isEmpty) return UnresolvedNote(target: raw);
    final hash = t0.indexOf('#');
    var t = hash == -1 ? t0 : t0.substring(0, hash);
    final heading = hash == -1 || hash == t0.length - 1
        ? null
        : t0.substring(hash + 1);
    if (t.endsWith('.md')) t = t.substring(0, t.length - 3);
    if (t.isEmpty) {
      return LocalAnchor(heading: heading ?? '');
    }
    final stem = t.contains('/') ? t.substring(t.lastIndexOf('/') + 1) : t;
    final stems = await (_db.select(
      _db.noteStems,
    )..where((s) => s.stem.equals(stem))).get();
    if (stems.isEmpty) return UnresolvedNote(target: raw);
    final ids = <int>{for (final s in stems) s.noteId};
    final notes = await (_db.select(
      _db.notes,
    )..where((n) => n.id.isIn(ids))).get();
    return _resolveFromCandidates(
      raw: raw,
      t: t,
      heading: heading,
      notes: notes,
    );
  }

  /// Resolves many targets in a few queries (the indexer's content pass:
  /// one stems lookup for every distinct last segment, one notes lookup,
  /// then the same per-target rules — exact stem → unique? → path-prefix
  /// filter → ambiguous — applied in Dart). Same results as calling
  /// [resolveWiki] per target, at a fraction of the query count.
  Future<Map<String, ResolveResult>> resolveBatch(
    Iterable<String> targets,
  ) async {
    final out = <String, ResolveResult>{};
    final byStem = <String, List<String>>{}; // stem -> raw targets
    final specs = <String, (String t, String? heading)>{}; // raw -> normalized
    for (final raw in targets) {
      if (out.containsKey(raw)) continue;
      final t0 = normalizeTarget(raw);
      if (t0.isEmpty) {
        out[raw] = UnresolvedNote(target: raw);
        continue;
      }
      final hash = t0.indexOf('#');
      var t = hash == -1 ? t0 : t0.substring(0, hash);
      final heading = hash == -1 || hash == t0.length - 1
          ? null
          : t0.substring(hash + 1);
      if (t.endsWith('.md')) t = t.substring(0, t.length - 3);
      if (t.isEmpty) {
        out[raw] = LocalAnchor(heading: heading ?? '');
        continue;
      }
      final stem = t.contains('/') ? t.substring(t.lastIndexOf('/') + 1) : t;
      (byStem[stem] ??= <String>[]).add(raw);
      specs[raw] = (t, heading);
    }
    for (final group in byStem.values) {
      final spec0 = specs[group.first]!;
      final lastSegment = spec0.$1.contains('/')
          ? spec0.$1.substring(spec0.$1.lastIndexOf('/') + 1)
          : spec0.$1;
      final stems = await (_db.select(
        _db.noteStems,
      )..where((s) => s.stem.equals(lastSegment))).get();
      final ids = <int>{for (final s in stems) s.noteId};
      final notes = ids.isEmpty
          ? <Note>[]
          : await (_db.select(_db.notes)..where((n) => n.id.isIn(ids))).get();
      for (final raw in group) {
        final spec = specs[raw]!;
        if (notes.isEmpty || ids.isEmpty) {
          out[raw] = UnresolvedNote(target: raw);
        } else {
          out[raw] = _resolveFromCandidates(
            raw: raw,
            t: spec.$1,
            heading: spec.$2,
            notes: notes,
          );
        }
      }
    }
    return out;
  }

  /// The pure resolution tail over gathered candidates: same rules for the
  /// single-target and batched paths.
  ResolveResult _resolveFromCandidates({
    required String raw,
    required String t,
    required String? heading,
    required List<Note> notes,
  }) {
    // Shortest path first (a bare `[[note]]` picks the closest name); ties
    // in length are alphabetical.
    notes.sort((a, b) {
      final byLen = a.path.length.compareTo(b.path.length);
      return byLen != 0 ? byLen : a.path.compareTo(b.path);
    });
    if (notes.length == 1) {
      return ResolvedNote(note: notes.single, heading: heading);
    }
    // Same-stem candidates: qualify by the target's path prefix. For a
    // `.md` target the extension was already stripped, so the candidate
    // name is `$t.md`; for non-md targets (embeds — `foo.png`) the target
    // keeps its extension and matches as-is.
    final withMd = '$t.md';
    final qualified = <Note>[
      for (final n in notes)
        if (n.path.toLowerCase() == t ||
            n.path.toLowerCase() == withMd ||
            n.path.toLowerCase().endsWith('/$t') ||
            n.path.toLowerCase().endsWith('/$withMd'))
          n,
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
