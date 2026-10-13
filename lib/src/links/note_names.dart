/// The names a `[[` target can carry, read off the index (#475).
///
/// The notes and aliases from `note_stems` — one query per keystroke, never a
/// walk of the tree — ranked, and each qualified as far as it takes to name
/// that file alone. Also what turns a path found elsewhere (a heading's note,
/// a block's) into the target a link writes for it.
library;

import 'dart:math' show min;

import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/link_path.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/links/suggestion.dart';
import 'package:path/path.dart' as p;

/// Notes and files by name, from the library's `note_stems`.
final class NoteNames {
  /// Reads the stems of [_db].
  const new(this._db, {this.attachmentsFolder});

  final IndexDatabase _db;

  /// The library's attachments folder, read when an embed is typed: the
  /// setting can change under a running editor. Null lists every attachment
  /// as one.
  final Future<String> Function()? attachmentsFolder;

  /// How many matching rows are fetched before the list is ranked and cut to
  /// [limit]. The indexed prefix query takes this many; the contains query —
  /// which cannot use the stem index (a leading `%`) — is read only while the
  /// prefix rows leave room, so a keystroke is not charged a `%q%` scan the
  /// prefix already answered (#475, #491).
  static const int _fetch = 200;

  /// How many rows the panel is handed.
  static const int limit = 50;

  /// The notes and aliases matching [query], best match first.
  Future<List<NoteSuggestion>> notes(String query) async {
    final q = query.trim().toLowerCase();
    return await _complete(_rank(await _rows(q, _linkable), q));
  }

  /// What an `![[` embed can name: the attachments folder's files first, the
  /// attachments kept elsewhere, then the notes (#705).
  Future<List<NoteSuggestion>> embeds(String query) async {
    final q = query.trim().toLowerCase();
    final folder = await attachmentsFolder?.call() ?? '';
    // Two reads, the folder's and the rest: one read cut at its cap by path
    // could fill up with attachments elsewhere before it reached the folder.
    final attachments = folder.isEmpty
        ? _rank(await _rows(q, _attachment), q)
        : [
            ..._rank(await _rows(q, _attachment, under: folder), q),
            ..._rank(
              await _rows(q, _attachment, under: folder, outside: true),
              q,
            ),
          ];
    // The notes after, while the attachments leave room: an embed of a note
    // transcludes it, and the panel still offers that.
    final rows = await _complete(attachments);
    if (rows.length >= limit) return rows;
    final notes = await _complete(_rank(await _rows(q, _note), q));
    return [...rows, ...notes.take(limit - rows.length)];
  }

  /// The shortest wiki target that names the file at [path] alone (#704).
  Future<String> targetOf(String path) async {
    final sharing = await _sharing({_stemOf(path)});
    return _targetFor(path, sharing[_stemOf(path)] ?? const <String>{});
  }

  /// The shortest wiki target that names each of [paths] alone, by path; a
  /// path whose name no `[[…]]` target can carry (#491) has none.
  Future<Map<String, String>> targetsOf(Set<String> paths) async {
    final targets = await _targetsFor(paths);
    return {
      for (final entry in targets.entries)
        if (readsBack(entry.value)) entry.key: entry.value,
    };
  }

  /// The shortest wiki target that names each of [paths] alone, by path —
  /// one query for the notes that share any of their names. The target is
  /// what the rule produces, whether or not it reads back: the caller drops
  /// the ones it cannot write.
  Future<Map<String, String>> _targetsFor(Iterable<String> paths) async {
    final byStem = <String, List<String>>{};
    for (final path in paths) {
      (byStem[_stemOf(path)] ??= <String>[]).add(path);
    }
    if (byStem.isEmpty) return const <String, String>{};
    final sharing = await _sharing(byStem.keys.toSet());
    final out = <String, String>{};
    for (final entry in byStem.entries) {
      for (final path in entry.value) {
        out[path] = _targetFor(path, sharing[entry.key] ?? const <String>{});
      }
    }
    return out;
  }

  /// The normalized stem a file named [path] is indexed under.
  static String _stemOf(String path) =>
      LinkPaths.normalizeTarget(_displayName(path));

  /// For each of the normalized [stems], the paths of the files that answer
  /// to it, aliases included: one query for the lot.
  Future<Map<String, Set<String>>> _sharing(Set<String> stems) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT s.stem AS stem, n.path AS path '
          'FROM note_stems AS s JOIN notes AS n ON n.id = s.note_id '
          'WHERE s.stem IN (${List.filled(stems.length, '?').join(', ')})',
          variables: [for (final stem in stems) Variable<String>(stem)],
        )
        .get();
    final sharing = <String, Set<String>>{};
    for (final row in rows) {
      (sharing[row.read<String>('stem')] ??= <String>{}).add(
        row.read<String>('path'),
      );
    }
    return sharing;
  }

  /// [ranked] qualified and cut to [limit] rows that read back.
  Future<List<NoteSuggestion>> _complete(List<_Ranked> ranked) async {
    // A row the panel cannot write takes no slot: [limit] rows are cut from
    // the ones that read back, not from the ranking, or a run of names with
    // a `#` at its head would leave the panel short (#491). A name is
    // dropped before its target is qualified; the folder a qualified target
    // adds can break it too, so those are counted after, and the ranking is
    // read on in chunks until the panel is full or it runs out.
    final out = <NoteSuggestion>[];
    var at = 0;
    while (out.length < limit && at < ranked.length) {
      final end = min(at + limit - out.length, ranked.length);
      for (final row in await _qualified(ranked.sublist(at, end))) {
        if (readsBack(row.target)) out.add(row);
      }
      at = end;
    }
    return out;
  }

  /// Whether [target], written between the `[[` and the `]]`, reads back as
  /// itself (#491).
  ///
  /// The link ends at its first `]]`, the editor's own wikilink token holds
  /// no bracket, and the parser splits a target at its first `|` or `#`:
  /// `[[C# tips]]` is target `C` with heading `tips`. A name holding one of
  /// those has no wikilink spelling, so the row would write a link to a note
  /// that is not there — it is left out of the panel instead.
  static bool readsBack(String target) => !_unlinkable.hasMatch(target);

  /// The characters a `[[…]]` target cannot carry: `#` and `|` split it, and
  /// a bracket ends it.
  static final RegExp _unlinkable = RegExp(r'[#|\[\]]');

  /// [ranked] with each target qualified as far as it takes to name that
  /// note alone: the same qualification [targetsOf] makes, before the
  /// read-back filter (the caller counts those it drops).
  Future<List<NoteSuggestion>> _qualified(List<_Ranked> ranked) async {
    if (ranked.isEmpty) return const <NoteSuggestion>[];
    final targets = await _targetsFor([for (final r in ranked) r.path]);
    return [
      for (final r in ranked)
        NoteSuggestion(
          name: r.note.name,
          folder: r.note.folder,
          alias: r.note.alias,
          target: targets[r.path] ?? r.note.target,
        ),
    ];
  }

  /// The shortest tail of [path] (`.md` dropped) that the resolver takes for
  /// this note alone among [candidates], the notes answering to its name:
  /// the bare name when nothing else does, `folder/name` when that settles
  /// it, and so on up to the whole path.
  static String _targetFor(String path, Set<String> candidates) {
    final bare = path.toLowerCase().endsWith('.md')
        ? path.substring(0, path.length - 3)
        : path;
    final segments = bare.split('/');
    for (var take = 1; take <= segments.length; take++) {
      final target = segments.sublist(segments.length - take).join('/');
      final normalized = LinkPaths.normalizeTarget(target);
      final named = candidates.where(
        (candidate) => LinkPaths.pathMatches(candidate, normalized),
      );
      if (named.length <= 1) return target;
    }
    // Two notes whose paths the rule cannot tell apart (`a/x` and `b/a/x`):
    // the whole path is the closest a target gets.
    return bare;
  }

  /// A note, a PDF or an EPUB: the files a `[[…]]` link names, and the
  /// books the `#` half serves. Other attachments are left to embeds.
  static const String _linkable =
      "(lower(substr(n.name, -3)) = '.md' "
      "OR lower(substr(n.name, -4)) = '.pdf' "
      "OR lower(substr(n.name, -5)) = '.epub')";

  /// Every file but a note: what an `![[` embed names first (#705).
  static const String _attachment = "lower(substr(n.name, -3)) <> '.md'";

  /// A note: what an `![[` embed names after the attachments, a PDF or an
  /// EPUB being one of those.
  static const String _note = "lower(substr(n.name, -3)) = '.md'";

  /// The matching `note_stems` rows of the [files] kind joined to their
  /// file, prefix matches first. An empty [q] lists every file, by path; a
  /// non-empty one reads the indexed prefix matches, then the contains
  /// matches only while the cap has room (#491). With [under], only the
  /// files in that folder (at any depth) — or, [outside], only the others.
  Future<List<_StemRow>> _rows(
    String q,
    String files, {
    String? under,
    bool outside = false,
  }) async {
    final scope = under == null
        ? ''
        : " AND n.path ${outside ? 'NOT ' : ''}LIKE ? ESCAPE '\\'";
    final scoped = <Variable<Object>>[
      if (under != null) Variable<String>('${_escapeLike(under)}/%'),
    ];
    final select =
        'SELECT s.stem AS stem, s.source AS source, n.id AS id, n.path AS path '
        'FROM note_stems AS s JOIN notes AS n ON n.id = s.note_id '
        'WHERE n.is_dir = 0 AND $files$scope';
    final List<QueryRow> result;
    if (q.isEmpty) {
      result = await _db
          .customSelect(
            '$select ORDER BY n.path ASC LIMIT ?',
            variables: [...scoped, const Variable<int>(_fetch)],
          )
          .get();
    } else {
      // A prefix match (`q%`) is answered by the stem index, so it is read
      // first and cut by the cap. A contains match (`%q%`) has no index to
      // use — SQLite would evaluate the LIKE against every stem and sort the
      // matches before the LIMIT — so it is read, bounded by what the prefix
      // left, only when the prefix rows do not fill the cap (#491).
      final escaped = _escapeLike(q);
      final prefix = '$escaped%';
      var rows = await _db
          .customSelect(
            "$select AND s.stem LIKE ? ESCAPE '\\' "
            'ORDER BY n.path ASC LIMIT ?',
            variables: [
              ...scoped,
              Variable<String>(prefix),
              const Variable<int>(_fetch),
            ],
          )
          .get();
      if (rows.length < _fetch) {
        rows = [
          ...rows,
          ...await _db
              .customSelect(
                "$select AND s.stem LIKE ? ESCAPE '\\' "
                r"AND s.stem NOT LIKE ? ESCAPE '\' "
                'ORDER BY n.path ASC LIMIT ?',
                variables: [
                  ...scoped,
                  Variable<String>('%$escaped%'),
                  Variable<String>(prefix),
                  Variable<int>(_fetch - rows.length),
                ],
              )
              .get(),
        ];
      }
      result = rows;
    }
    return [
      for (final row in result)
        _StemRow(
          id: row.read<int>('id'),
          path: row.read<String>('path'),
          stem: row.read<String>('stem'),
          source: row.read<String>('source'),
        ),
    ];
  }

  /// Escapes the LIKE wildcards in [s] so a query is matched literally.
  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  /// [rows] grouped by note and ranked: a note whose name or an alias starts
  /// with [q] first, then by path. A note found only through an alias carries
  /// it.
  List<_Ranked> _rank(List<_StemRow> rows, String q) {
    final byNote = <int, List<_StemRow>>{};
    for (final row in rows) {
      (byNote[row.id] ??= <_StemRow>[]).add(row);
    }
    final ranked = <({NoteSuggestion note, String path, bool prefix})>[];
    for (final group in byNote.values) {
      final first = group.first;
      final named = group.where((r) => r.source == 'file').firstOrNull;
      final name = _displayName(first.path);
      final prefix = q.isNotEmpty && group.any((r) => r.stem.startsWith(q));
      final nameMatched =
          q.isEmpty || (named != null && named.stem.contains(q));
      ranked.add((
        note: NoteSuggestion(
          name: name,
          folder: _folderOf(first.path),
          target: name,
          alias: q.isNotEmpty && !nameMatched ? first.stem : null,
        ),
        path: first.path,
        prefix: prefix,
      ));
    }
    ranked.sort((a, b) {
      if (a.prefix != b.prefix) return a.prefix ? -1 : 1;
      final byFolder = a.note.folder.compareTo(b.note.folder);
      return byFolder != 0 ? byFolder : a.note.name.compareTo(b.note.name);
    });
    return [
      for (final r in ranked)
        if (readsBack(r.note.target)) (note: r.note, path: r.path),
    ];
  }

  /// The name shown for [path]: the file's base name, `.md` dropped.
  static String _displayName(String path) {
    final name = p.basename(path);
    return name.toLowerCase().endsWith('.md')
        ? name.substring(0, name.length - 3)
        : name;
  }

  /// The folder of [path] relative to the library; empty at the root.
  static String _folderOf(String path) {
    final dir = p.dirname(path);
    return dir == '.' ? '' : dir;
  }
}

/// A ranked row: the suggestion with its bare target, and the note's path,
/// which qualifies the target when the name is shared.
typedef _Ranked = ({NoteSuggestion note, String path});

/// One `note_stems` row joined to its note.
final class _StemRow {
  const new({
    required this.id,
    required this.path,
    required this.stem,
    required this.source,
  });

  final int id;
  final String path;
  final String stem;
  final String source;
}

/// The one note the wiki [target] names — the shortest path first when
/// several do — or null when it names no indexed note.
Future<Note?> noteNamed(LinkSource source, String target) async {
  final result = await source.resolveWiki(target);
  return switch (result) {
    ResolvedNote(:final note) => note,
    AmbiguousNote(:final candidates) =>
      candidates.isEmpty ? null : candidates.first,
    _ => null,
  };
}
