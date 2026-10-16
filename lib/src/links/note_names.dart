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
import 'package:niman/src/links/stem_rank.dart';
import 'package:niman/src/links/stem_row.dart';
import 'package:niman/src/links/stem_rows.dart';
import 'package:niman/src/links/suggestion.dart';

/// Notes and files by name, from the library's `note_stems`.
final class NoteNames {
  /// Reads the stems of [_db].
  const new(this._db, {this.attachmentsFolder});

  final IndexDatabase _db;

  StemRows get _stems => StemRows(_db);

  /// The library's attachments folder, read when an embed is typed: the
  /// setting can change under a running editor. Null lists every attachment
  /// as one.
  final Future<String> Function()? attachmentsFolder;

  /// How many rows the panel is handed.
  static const int limit = 50;

  /// The notes and aliases matching [query], best match first.
  Future<List<NoteSuggestion>> notes(String query) async {
    final q = query.trim().toLowerCase();
    return await _complete(_rank(await _stems.rows(q, StemRows.linkable), q));
  }

  /// What an `![[` embed can name: the attachments folder's files first, the
  /// attachments kept elsewhere, then the notes (#705).
  Future<List<NoteSuggestion>> embeds(String query) async {
    final q = query.trim().toLowerCase();
    final folder = await attachmentsFolder?.call() ?? '';
    // Two reads, the folder's and the rest: one read cut at its cap by path
    // could fill up with attachments elsewhere before it reached the folder.
    final attachments = folder.isEmpty
        ? _rank(await _stems.rows(q, StemRows.attachment), q)
        : [
            ..._rank(
              await _stems.rows(q, StemRows.attachment, under: folder),
              q,
            ),
            ..._rank(
              await _stems.rows(
                q,
                StemRows.attachment,
                under: folder,
                outside: true,
              ),
              q,
            ),
          ];
    // The notes after, while the attachments leave room: an embed of a note
    // transcludes it, and the panel still offers that.
    final rows = await _complete(attachments);
    if (rows.length >= limit) return rows;
    final notes = await _complete(
      _rank(await _stems.rows(q, StemRows.note), q),
    );
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
      LinkPaths.normalizeTarget(displayName(path));

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

  /// [rows] ranked ([rankStems]), those whose name a `[[…]]` target can carry.
  List<_Ranked> _rank(List<StemRow> rows, String q) => [
    for (final r in rankStems(rows, q))
      if (readsBack(r.note.target)) r,
  ];
}

/// A ranked row: the suggestion with its bare target, and the note's path,
/// which qualifies the target when the name is shared.
typedef _Ranked = RankedStem;

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
