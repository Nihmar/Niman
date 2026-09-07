/// Exact whole-word replace across notes (T-M3-10, the search screen's
/// optional Replace action).
///
/// The replace targets the note FILES — disk is the source of truth, the
/// index is only ever rebuilt from it. Candidate notes come from an FTS
/// phrase lookup (the term as a phrase, no prefix), then every candidate
/// file is read off the UI isolate, the term is replaced only where it
/// stands as whole words, and the file is written back atomically. The
/// file watcher picks the writes up and re-indexes, so FTS/tags/stems
/// catch up by themselves.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:copist/src/core/files.dart';
import 'package:copist/src/db/database.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:path/path.dart' as p;

/// One replace run's outcome.
final class ReplaceReport {
  /// Creates a report.
  const ReplaceReport({
    required this.notesScanned,
    required this.notesChanged,
    required this.occurrences,
    required this.skipped,
  });

  /// Candidate notes actually read (skip excluded).
  final int notesScanned;

  /// Notes where at least one replacement happened.
  final int notesChanged;

  /// Total whole-word occurrences replaced.
  final int occurrences;

  /// Library-relative paths deliberately left alone (open notes).
  final List<String> skipped;
}

/// The replace data source the UI talks to; [ReplaceRunner] is the
/// production implementation over the index + disk, widget tests inject a
/// fake.
abstract interface class ReplaceSource {
  /// How many notes contain [term] as a phrase (an FTS approximation —
  /// case-insensitive; the disk scan reports exact numbers).
  Future<int> countNotes(String term);

  /// Replaces whole-word occurrences of [term] with [replacement] in the
  /// matching notes under the library root.
  ///
  /// [only] narrows the run to those library-relative paths (the
  /// single-note replace); [skip] paths are never touched (open notes).
  Future<ReplaceReport> replaceAll({
    required String term,
    required String replacement,
    required bool caseSensitive,
    Set<String>? only,
    Set<String> skip,
  });
}

/// The production [ReplaceSource] over the library index and disk (see the
/// class docs at the top of this file).
final class ReplaceRunner implements ReplaceSource {
  /// Creates a runner for the library root and index database given to it.
  ReplaceRunner(this._db, this._root);

  final CopistDatabase _db;
  final String _root;

  @override
  Future<int> countNotes(String term) async {
    final phrase = ftsPhraseOf(term);
    if (phrase == null) return 0;
    final row = await _db
        .customSelect(
          'SELECT count(*) c FROM notes_fts WHERE notes_fts MATCH ?1',
          variables: [Variable<String>(phrase)],
        )
        .getSingle();
    return row.read<int>('c');
  }

  @override
  Future<ReplaceReport> replaceAll({
    required String term,
    required String replacement,
    required bool caseSensitive,
    Set<String>? only,
    Set<String> skip = const {},
  }) async {
    // Candidates: the requested paths when scoping to one note, else every
    // md note whose text holds the term as a phrase.
    final List<String> candidates;
    if (only != null) {
      candidates = [
        for (final rel in only)
          if (p.extension(rel).toLowerCase() == '.md') rel,
      ]..sort();
    } else {
      final phrase = ftsPhraseOf(term);
      if (phrase == null) {
        return const ReplaceReport(
          notesScanned: 0,
          notesChanged: 0,
          occurrences: 0,
          skipped: [],
        );
      }
      final rows = await _db
          .customSelect(
            'SELECT notes.path FROM notes_fts '
            'JOIN notes ON notes.id = notes_fts.rowid '
            'WHERE notes_fts MATCH ?1 ORDER BY notes.path',
            variables: [Variable<String>(phrase)],
          )
          .get();
      candidates = [for (final row in rows) row.read<String>('path')];
    }
    final todo = <String>[
      for (final rel in candidates)
        if (!skip.contains(rel)) rel,
    ];
    final skipped = <String>[
      for (final rel in candidates)
        if (skip.contains(rel)) rel,
    ];

    // Chunked off-isolate passes: reads and atomic writes never run on the
    // UI isolate (every listSync/stat/read is a FUSE round trip on
    // Android). One isolate per chunk of files.
    var notesChanged = 0;
    var occurrences = 0;
    const chunk = 24;
    // The isolate closure must not capture the runner (its drift database
    // is unsendable) — only plain values cross the boundary.
    final root = _root;
    for (var i = 0; i < todo.length; i += chunk) {
      final end = math.min(i + chunk, todo.length);
      final results = await Isolate.run(
        () => _replaceChunk(
          root,
          todo.sublist(i, end),
          term,
          replacement,
          caseSensitive,
        ),
      );
      for (final (changed, count) in results) {
        if (changed) notesChanged++;
        occurrences += count;
      }
      if (end < todo.length) await Future<void>.delayed(Duration.zero);
    }
    return ReplaceReport(
      notesScanned: todo.length,
      notesChanged: notesChanged,
      occurrences: occurrences,
      skipped: skipped,
    );
  }
}

/// The off-isolate entry: replaces the term in every file of [rels]
/// (absolute under [root]); one `(changed, occurrences)` per file.
Future<List<(bool, int)>> _replaceChunk(
  String root,
  List<String> rels,
  String term,
  String replacement,
  bool caseSensitive,
) async {
  final out = <(bool, int)>[];
  for (final rel in rels) {
    final file = File(p.join(root, rel));
    var changed = false;
    var count = 0;
    try {
      final original = file.readAsStringSync();
      final result = replaceWholeWords(
        original,
        term,
        replacement,
        caseSensitive: caseSensitive,
      );
      count = result.$1;
      if (count > 0) {
        await writeFileAtomically(file, utf8.encode(result.$2));
        changed = true;
      }
    } on Object {
      // Unreadable or gone (a scan can race a delete): leave it alone.
      changed = false;
      count = 0;
    }
    out.add((changed, count));
  }
  return out;
}

/// The whole-word pattern for [term] (multi-word terms match with any
/// whitespace between the words), or null when [term] has no word.
///
/// A word is a run of unicode letters, digits or `_` — the same character
/// class the slug and stem rules use — so `cat` never matches inside
/// `concatenate`, `cats` or `cat!` but always matches `cat`, `cat,` and
/// `(cat)`.
RegExp? wholeWordPattern(String term, {required bool caseSensitive}) {
  final tokens = term
      .trim()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return null;
  final body = tokens.map(RegExp.escape).join(r'\s+');
  return RegExp(
    '(?<![\\p{L}\\p{N}_])$body(?![\\p{L}\\p{N}_])',
    unicode: true,
    caseSensitive: caseSensitive,
  );
}

/// Replaces whole-word occurrences of [term] in [text]; returns
/// `(occurrences, new text)`.
(int, String) replaceWholeWords(
  String text,
  String term,
  String replacement, {
  required bool caseSensitive,
}) {
  final pattern = wholeWordPattern(term, caseSensitive: caseSensitive);
  if (pattern == null) return (0, text);
  var count = 0;
  final buffer = StringBuffer();
  var cursor = 0;
  for (final match in pattern.allMatches(text)) {
    buffer
      ..write(text.substring(cursor, match.start))
      ..write(replacement);
    count++;
    cursor = match.end;
  }
  buffer.write(text.substring(cursor));
  return (count, buffer.toString());
}

/// The FTS phrase form of [term]: the whole term inside one quoted phrase
/// (internal quotes doubled), so its tokens must be adjacent — the index
/// approximation of the disk's whole-word rule. Null for an empty term.
String? ftsPhraseOf(String term) {
  final t = term.trim();
  if (t.isEmpty) return null;
  return '"${t.replaceAll('"', '""')}"';
}
