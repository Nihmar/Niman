/// Exact whole-word replace across notes (T-M3-10, the search screen's
/// optional Replace action).
///
/// The replace targets the note FILES — disk is the source of truth, the
/// index is only ever rebuilt from it. Candidate notes come from an FTS
/// phrase lookup (the term as a phrase, no prefix), then every candidate
/// file is read off the UI isolate, the term is replaced only where it
/// stands as whole words, and the file is written back atomically. Each
/// batch of rewritten notes is re-indexed right away through
/// [ReplaceRunner.onNotesReindexed] — the file watcher is unreliable on
/// Android's emulated storage, so waiting for it would leave the search
/// index stale until the periodic rescan. The preview scan runs the same
/// pass without writing, for the screen's live before/after list.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Variable;
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:path/path.dart' as p;

/// One replace run's outcome.
final class ReplaceReport {
  /// Creates a report.
  const new({
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

/// One example match in a note: the raw [match] text with the trimmed
/// surrounding context. The [before]/[after] windows are cut at ±30 chars
/// and carry a leading/trailing `…` when trimmed.
final class ReplaceSample {
  /// Creates a sample.
  const new({required this.before, required this.match, required this.after});

  /// The text right before the match ('' when the match starts the note).
  final String before;

  /// The matched word(s), exactly as found.
  final String match;

  /// The text right after the match ('' when the match ends the note).
  final String after;
}

/// One note's whole-word matches: the [occurrences] count and up to two
/// [samples] (context around the first matches) for the preview list.
final class ReplaceMatchNote {
  /// Creates a match note.
  const new({
    required this.path,
    required this.occurrences,
    required this.samples,
  });

  /// The library-relative note path.
  final String path;

  /// Total whole-word occurrences of the term in the note.
  final int occurrences;

  /// Context samples around the first occurrences (≤ 2).
  final List<ReplaceSample> samples;
}

/// The replace data source the UI talks to; [ReplaceRunner] is the
/// production implementation over the index + disk, widget tests inject a
/// fake.
abstract interface class ReplaceSource {
  /// Scans the candidate notes for whole-word occurrences of [term] and
  /// returns the matching notes (occurrence counts + sample contexts),
  /// read off the UI isolate. [onlyPath] narrows the scan to one note.
  Future<List<ReplaceMatchNote>> previewMatches(
    String term, {
    required bool caseSensitive,
    String? onlyPath,
  });

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
  /// Creates a runner for the library root and index database given to it;
  /// [onNotesReindexed] is invoked with the absolute paths of every note
  /// this run rewrote, right after the batch that rewrote them.
  new(this._db, this._root, {this.onNotesReindexed});

  final IndexDatabase _db;
  final String _root;

  /// Called with the rewritten notes' absolute paths, per write batch, so
  /// the caller can re-index them without waiting for the watcher.
  final Future<void> Function(List<String> absolutePaths)? onNotesReindexed;

  /// How many context characters a preview sample keeps around a match.
  static const int _sampleRadius = 30;

  /// How many samples a preview keeps per note.
  static const int _samplesPerNote = 2;

  @override
  Future<List<ReplaceMatchNote>> previewMatches(
    String term, {
    required bool caseSensitive,
    String? onlyPath,
  }) async {
    final only = onlyPath == null ? null : {onlyPath};
    final candidates = await _candidates(term, only: only);
    const log = AppLogger(name: 'replace');
    final clock = Stopwatch()..start();
    log.debug(
      'preview "$term" (${caseSensitive ? 'case' : 'any case'}, '
      '${onlyPath ?? 'all notes'}): ${candidates.length} candidate(s)',
    );

    final notes = <ReplaceMatchNote>[];
    // Chunked off-isolate passes: file reads never run on the UI isolate.
    final root = _root;
    const chunk = 16;
    for (var i = 0; i < candidates.length; i += chunk) {
      final end = math.min(i + chunk, candidates.length);
      final results = await Isolate.run(
        () => _previewChunk(
          root,
          candidates.sublist(i, end),
          term,
          caseSensitive,
          _sampleRadius,
          _samplesPerNote,
        ),
      );
      for (final note in results) {
        if (note != null) notes.add(note);
      }
      if (end < candidates.length) await Future<void>.delayed(Duration.zero);
    }
    log.debug(
      'preview "$term": ${notes.length} note(s) with '
      '${notes.fold<int>(0, (sum, n) => sum + n.occurrences)} '
      'occurrence(s) in ${clock.elapsedMilliseconds} ms',
    );
    return notes;
  }

  @override
  Future<ReplaceReport> replaceAll({
    required String term,
    required String replacement,
    required bool caseSensitive,
    Set<String>? only,
    Set<String> skip = const {},
  }) async {
    final candidates = await _candidates(term, only: only);
    final todo = <String>[
      for (final rel in candidates)
        if (!skip.contains(rel)) rel,
    ];
    final skipped = <String>[
      for (final rel in candidates)
        if (skip.contains(rel)) rel,
    ];
    const log = AppLogger(name: 'replace');
    final clock = Stopwatch()..start();
    log.debug(
      'replace "$term" -> "$replacement" '
      '(${caseSensitive ? 'case' : 'any case'}): ${todo.length} note(s)',
    );

    // Chunked off-isolate passes: reads and atomic writes never run on the
    // UI isolate (every listSync/stat/read is a FUSE round trip on
    // Android). One isolate per chunk of files.
    var notesChanged = 0;
    var occurrences = 0;
    // The isolate closure must not capture the runner (its drift database
    // is unsendable) — only plain values cross the boundary.
    final root = _root;
    const chunk = 24;
    for (var i = 0; i < todo.length; i += chunk) {
      final rels = todo.sublist(i, math.min(i + chunk, todo.length));
      final results = await Isolate.run(
        () => _replaceChunk(root, rels, term, replacement, caseSensitive),
      );
      final changed = <String>[];
      for (var j = 0; j < results.length; j++) {
        final (wasChanged, count) = results[j];
        if (wasChanged) {
          notesChanged++;
          changed.add(p.join(root, rels[j]));
        }
        occurrences += count;
      }
      // Re-index the rewritten notes right away (per batch, so a long run
      // streams the work): the watcher cannot be relied on here.
      if (changed.isNotEmpty) {
        await onNotesReindexed?.call(changed);
      }
      if (i + chunk < todo.length) await Future<void>.delayed(Duration.zero);
    }
    log.debug(
      'replace "$term": $occurrences occurrence(s) in $notesChanged '
      'note(s), ${clock.elapsedMilliseconds} ms',
    );
    return ReplaceReport(
      notesScanned: todo.length,
      notesChanged: notesChanged,
      occurrences: occurrences,
      skipped: skipped,
    );
  }

  /// The candidate rel paths: [only] when given (md paths only), else
  /// every md note whose text holds [term] as an FTS phrase.
  Future<List<String>> _candidates(String term, {Set<String>? only}) async {
    if (only != null) {
      return [
        for (final rel in only)
          if (p.extension(rel).toLowerCase() == '.md') rel,
      ]..sort();
    }
    final phrase = ftsPhraseOf(term);
    if (phrase == null) return const [];
    final rows = await _db
        .customSelect(
          'SELECT notes.path FROM notes_fts '
          'JOIN notes ON notes.id = notes_fts.rowid '
          'WHERE notes_fts MATCH ?1 ORDER BY notes.path',
          variables: [Variable<String>(phrase)],
        )
        .get();
    return [for (final row in rows) row.read<String>('path')];
  }
}

/// The off-isolate preview entry: whole-word scan of the files at [rels]
/// (absolute under [root]); one match-note per file with occurrences, null
/// for a file without matches.
Future<List<ReplaceMatchNote?>> _previewChunk(
  String root,
  List<String> rels,
  String term,
  bool caseSensitive,
  int radius,
  int samplesPerNote,
) async {
  final out = <ReplaceMatchNote?>[];
  for (final rel in rels) {
    final file = File(p.join(root, rel));
    try {
      final text = file.readAsStringSync();
      final pattern = wholeWordPattern(term, caseSensitive: caseSensitive);
      if (pattern == null) {
        out.add(null);
        continue;
      }
      final samples = <ReplaceSample>[];
      var count = 0;
      for (final match in pattern.allMatches(text)) {
        count++;
        if (samples.length >= samplesPerNote) continue;
        samples.add(_sampleAround(text, match.start, match.end, radius));
      }
      if (count == 0) {
        out.add(null);
        continue;
      }
      out.add(
        ReplaceMatchNote(path: rel, occurrences: count, samples: samples),
      );
    } on Object {
      out.add(null); // Unreadable or gone: leave it out of the preview.
    }
  }
  return out;
}

/// The context around [start]..[end] in [text]: ±[radius] characters,
/// with a `…` marker on each trimmed side.
ReplaceSample _sampleAround(String text, int start, int end, int radius) {
  var from = start - radius;
  var to = end + radius;
  final lead = from > 0 ? '…' : '';
  final trail = to < text.length ? '…' : '';
  if (from < 0) from = 0;
  if (to > text.length) to = text.length;
  return ReplaceSample(
    before: '$lead${text.substring(from, start)}',
    match: text.substring(start, end),
    after: '${text.substring(end, to)}$trail',
  );
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
