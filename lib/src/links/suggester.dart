/// What the wikilink suggester panel offers (#475), and where the app reads
/// it from.
///
/// While a wikilink is typed the panel lists the library's notes after
/// `[[`, its attachments after `![[` (#705), and a note's headings after
/// `#`. Everything comes from what the app already keeps: the notes, the
/// attachments and the aliases from `note_stems` (one query, never a walk
/// of the tree), a note's headings from its own file — read and
/// outlined off the UI isolate, once per revision of it (#491) — and a
/// book's place forms from the target itself. Nothing here scans the library
/// to fill the panel.
library;

import 'dart:async' show unawaited;
import 'dart:math' show min;

import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// One row the panel can show.
sealed class SuggestEntry {
  /// Creates an entry.
  const new();
}

/// A note a `[[` target can name, or a file an `![[` embed can.
final class NoteSuggestion extends SuggestEntry {
  /// Creates a note row: [name] shown, [folder] dimmed, [target] written.
  const new({
    required this.name,
    required this.folder,
    required this.target,
    this.alias,
  });

  /// The name shown — the file's name, its case as on disk (`.md` dropped,
  /// any other extension kept: `photo.png`).
  final String name;

  /// The folder the note sits in, relative to the library; empty at the root.
  final String folder;

  /// What completing the link writes: the stem, `.md` dropped, when that
  /// names this note alone; otherwise the shortest tail of its path that
  /// does (`work/Meeting`), the way the resolver qualifies a shared name. A
  /// bare name shared by two notes resolves to neither of them for sure, so
  /// the row the user picked would not be the note the link opens.
  final String target;

  /// The alias the note was found through, when its own name did not match
  /// the query; null when the name matched, or the query is empty.
  final String? alias;
}

/// A heading a `#` target can name.
final class HeadingSuggestion extends SuggestEntry {
  /// Creates a heading row.
  const new(this.heading);

  /// The heading text, as the outline reads it.
  final String heading;
}

/// A place form a book target offers after `#` — `page=` for a PDF,
/// `chapter=` for an EPUB (docs/user/links.md).
final class BookSuggestion extends SuggestEntry {
  /// Creates a place row: the text to insert and what still has to be typed.
  const new({required this.form, required this.hint});

  /// What completing the row writes, e.g. `page=`.
  final String form;

  /// The dimmed note beside it, e.g. `type a number`.
  final String hint;
}

/// The library the panel reads: the notes after `[[`, a note's headings after
/// `#`, and a book's place forms. [IndexWikilinkSuggester] is the production
/// implementation over the drift index; a widget test injects a fake.
abstract interface class WikilinkSuggester {
  /// The notes and aliases matching [query], best match first: prefix
  /// matches before contains, then by path. An empty [query] lists the
  /// library from the top. A note a `[[…]]` target cannot carry (#491) is
  /// left out: the row would write a link the parser reads back as another
  /// note.
  Future<List<NoteSuggestion>> notes(String query);

  /// What an `![[` embed can name, matching [query] (#705): the files of the
  /// attachments folder first — pictures, audio, video, PDFs, whatever is
  /// there — then the attachments kept elsewhere (a picture beside its
  /// note), then the notes, which an embed transcludes. Ranked within each
  /// as [notes] ranks; a target keeps its extension (`photo.png`).
  Future<List<NoteSuggestion>> embeds(String query);

  /// The headings of the note named by the wiki [target] — `note`,
  /// `folder/note` — or none when it does not resolve or cannot be read.
  /// The list is the note's own headings, as the outline reads them; the
  /// panel filters it for the heading being typed.
  Future<List<HeadingSuggestion>> headings(String target);

  /// The place forms the book named by [target] offers, or none when the
  /// target is not a PDF or an EPUB.
  Future<List<BookSuggestion>> bookPlaces(String target);
}

/// The panel's suggestions, read off the library's index.
///
/// One class, so every read the panel makes is one place: the notes from
/// `note_stems`, a named note's headings through [readHeadings] — kept by
/// note and revision, so a run of keystrokes after `#` reads the target
/// once (#491) — and a book's forms from the target's extension.
final class IndexWikilinkSuggester implements WikilinkSuggester {
  /// Creates a suggester over [_db], reading a named note's headings through
  /// [readHeadings] (the session's own read and scan of a library-relative
  /// path, off the UI isolate; null when it is gone).
  ///
  /// [attachmentsFolder] names the library's attachments folder, whose
  /// files an embed lists first; null lists every attachment as one.
  new(this._db, {required this.readHeadings, this.attachmentsFolder})
    : _resolver = LinkResolver(_db);

  final IndexDatabase _db;

  /// The library's attachments folder, read when an embed is typed: the
  /// setting can change under a running editor.
  final Future<String> Function()? attachmentsFolder;

  /// The headings of a library-relative note path, in document order, or
  /// null when it is gone. The whole note is read, decoded and walked, so
  /// the implementation runs it off the UI isolate.
  final Future<List<String>?> Function(String path) readHeadings;

  final LinkResolver _resolver;

  /// The headings already read, by note and revision. A run of keystrokes
  /// after `#` names the same target each time and the panel filters the
  /// list locally, so one read answers them all; only the note's own
  /// revision (its mtime and size, as the index records it) can make the
  /// list stale.
  final Map<(int, DateTime, int), List<HeadingSuggestion>> _headingsByNote = {};

  /// The reads under way, by the same key: what a key typed while one runs
  /// waits for instead of starting another.
  final Map<(int, DateTime, int), Future<List<HeadingSuggestion>>> _reading =
      {};

  /// How many notes' headings are kept. More than the run of keystrokes
  /// needs, so moving between a few targets does not re-read; bounded, so a
  /// long session cannot keep a novel's outline per note it ever named.
  static const int _headingCacheNotes = 8;

  /// How many matching rows are fetched before the list is ranked and cut to
  /// [limit]. The indexed prefix query takes this many; the contains query —
  /// which cannot use the stem index (a leading `%`) — is read only while the
  /// prefix rows leave room, so a keystroke is not charged a `%q%` scan the
  /// prefix already answered (#475, #491).
  static const int _fetch = 200;

  /// How many rows the panel is handed.
  static const int limit = 50;

  @override
  Future<List<NoteSuggestion>> notes(String query) async {
    final q = query.trim().toLowerCase();
    return await _complete(_rank(await _rows(q, _linkable), q));
  }

  @override
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
        if (_readsBack(row.target)) out.add(row);
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
  static bool _readsBack(String target) => !_unlinkable.hasMatch(target);

  /// The characters a `[[…]]` target cannot carry: `#` and `|` split it, and
  /// a bracket ends it.
  static final RegExp _unlinkable = RegExp(r'[#|\[\]]');

  /// [ranked] with each target qualified as far as it takes to name that
  /// note alone: one query for the notes that share any of their names,
  /// then [_targetFor] each.
  Future<List<NoteSuggestion>> _qualified(List<_Ranked> ranked) async {
    if (ranked.isEmpty) return const <NoteSuggestion>[];
    final stems = {
      for (final r in ranked) LinkResolver.normalizeTarget(r.note.target),
    };
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
    return [
      for (final r in ranked)
        NoteSuggestion(
          name: r.note.name,
          folder: r.note.folder,
          alias: r.note.alias,
          target: _targetFor(
            r.path,
            sharing[LinkResolver.normalizeTarget(r.note.target)] ??
                const <String>{},
          ),
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
      final normalized = LinkResolver.normalizeTarget(target);
      final named = candidates.where(
        (candidate) => LinkResolver.pathMatches(candidate, normalized),
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
        if (_readsBack(r.note.target)) (note: r.note, path: r.path),
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

  @override
  Future<List<HeadingSuggestion>> headings(String target) async {
    final note = await _resolved(target);
    if (note == null) return const <HeadingSuggestion>[];
    final key = (note.id, note.modified, note.size);
    final kept = _headingsByNote[key];
    if (kept != null) return kept;
    // A read under way answers every ask for the same revision that comes
    // before it lands: a slow note is still being read when the next key
    // does, and the keys would each start a read of their own.
    final reading = _reading[key] ??= _read(key, note.path);
    return await reading;
  }

  /// One read of the note at [path], kept under [key] once it lands and
  /// forgotten as a read under way however it ends. Empty when the note is
  /// gone, which is not kept: it may come back.
  Future<List<HeadingSuggestion>> _read(
    (int, DateTime, int) key,
    String path,
  ) async {
    try {
      final texts = await readHeadings(path);
      if (texts == null) return const <HeadingSuggestion>[];
      final rows = [for (final text in texts) HeadingSuggestion(text)];
      if (_headingsByNote.length >= _headingCacheNotes) {
        _headingsByNote.remove(_headingsByNote.keys.first);
      }
      _headingsByNote[key] = rows;
      return rows;
    } finally {
      unawaited(_reading.remove(key));
    }
  }

  @override
  Future<List<BookSuggestion>> bookPlaces(String target) async {
    final note = await _resolved(target);
    // The hint beside the form is a label, written when the panel is drawn:
    // it follows the language the app speaks.
    switch (p.extension(note?.path ?? target).toLowerCase()) {
      case '.pdf':
        return <BookSuggestion>[
          BookSuggestion(form: 'page=', hint: AppStrings.suggesterPageHint),
        ];
      case '.epub':
        return <BookSuggestion>[
          BookSuggestion(
            form: 'chapter=',
            hint: AppStrings.suggesterChapterHint,
          ),
        ];
      default:
        return const <BookSuggestion>[];
    }
  }

  /// The one note [target] names, shortest path first when it is ambiguous,
  /// or null when it names no indexed note.
  Future<Note?> _resolved(String target) async {
    final result = await _resolver.resolveWiki(target);
    return switch (result) {
      ResolvedNote(:final note) => note,
      AmbiguousNote(:final candidates) =>
        candidates.isEmpty ? null : candidates.first,
      _ => null,
    };
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
