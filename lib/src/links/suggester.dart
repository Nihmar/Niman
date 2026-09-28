/// What the wikilink suggester panel offers (#475), and where the app reads
/// it from.
///
/// While a wikilink is typed the panel lists the library's notes after `[[`
/// and a note's headings after `#`. Everything comes from what the app
/// already keeps: the notes and their aliases from `note_stems` (one query,
/// never a walk of the tree), a note's headings from the same block scan the
/// outline reads ([outlineOfText]), and a book's place forms from the target
/// itself. Nothing here scans the library to fill the panel.
library;

import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

/// One row the panel can show.
sealed class SuggestEntry {
  /// Creates an entry.
  const new();
}

/// A note a `[[` target can name.
final class NoteSuggestion extends SuggestEntry {
  /// Creates a note row: [name] shown, [folder] dimmed, [target] written.
  const new({
    required this.name,
    required this.folder,
    required this.target,
    this.alias,
  });

  /// The name shown — the file's stem, its case as on disk (`.md` dropped).
  final String name;

  /// The folder the note sits in, relative to the library; empty at the root.
  final String folder;

  /// What completing the link writes: the stem, `.md` dropped. The folder is
  /// what tells two same-named notes apart on screen, not in the target, so a
  /// bare name is written as the drawing shows.
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
  /// library from the top.
  Future<List<NoteSuggestion>> notes(String query);

  /// The headings of the note named by the wiki [target] — `note`,
  /// `folder/note` — or none when it does not resolve or cannot be read.
  Future<List<HeadingSuggestion>> headings(String target);

  /// The place forms the book named by [target] offers, or none when the
  /// target is not a PDF or an EPUB.
  Future<List<BookSuggestion>> bookPlaces(String target);
}

/// The panel's suggestions, read off the library's index.
///
/// One class, so every read the panel makes is one place: the notes from
/// `note_stems`, a named note's headings from its own file through [readNote]
/// and the outline's scan, and a book's forms from the target's extension.
final class IndexWikilinkSuggester implements WikilinkSuggester {
  /// Creates a suggester over [_db], reading a named note through [readNote]
  /// (the session's own read of a library-relative path; null when it is
  /// gone).
  new(this._db, {required this.readNote}) : _resolver = LinkResolver(_db);

  final IndexDatabase _db;

  /// Reads a library-relative note path's text, or null when it is gone.
  final Future<String?> Function(String path) readNote;

  final LinkResolver _resolver;

  /// How many matching rows one query fetches before the list is ranked and
  /// cut to [limit]. Bounds a contains query, which cannot use the stem
  /// index (a leading `%`), at a fixed cost per keystroke (#475).
  static const int _fetch = 200;

  /// How many rows the panel is handed.
  static const int limit = 50;

  @override
  Future<List<NoteSuggestion>> notes(String query) async {
    final q = query.trim().toLowerCase();
    return _rank(await _rows(q), q);
  }

  /// The matching `note_stems` rows joined to their file, prefix matches
  /// first. An empty [q] lists every file, by path.
  Future<List<_StemRow>> _rows(String q) async {
    // A note, a PDF or an EPUB: the files a `[[…]]` link names, and the
    // books the `#` half serves. Other attachments are left to embeds.
    const files =
        "(lower(substr(n.name, -3)) = '.md' "
        "OR lower(substr(n.name, -4)) = '.pdf' "
        "OR lower(substr(n.name, -5)) = '.epub')";
    const select =
        'SELECT s.stem AS stem, s.source AS source, n.id AS id, n.path AS path '
        'FROM note_stems AS s JOIN notes AS n ON n.id = s.note_id '
        'WHERE n.is_dir = 0 AND $files';
    final List<QueryRow> result;
    if (q.isEmpty) {
      result = await _db
          .customSelect(
            '$select ORDER BY n.path ASC LIMIT ?',
            variables: const [Variable<int>(_fetch)],
          )
          .get();
    } else {
      // A prefix match (`q%`) can use the stem index; a contains match
      // (`%q%`) cannot, and is what the fetch cap bounds.
      final escaped = _escapeLike(q);
      result = await _db
          .customSelect(
            "$select AND s.stem LIKE ? ESCAPE '\\' "
            r"ORDER BY (s.stem LIKE ? ESCAPE '\') DESC, n.path ASC LIMIT ?",
            variables: [
              Variable<String>('%$escaped%'),
              Variable<String>('$escaped%'),
              const Variable<int>(_fetch),
            ],
          )
          .get();
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
  List<NoteSuggestion> _rank(List<_StemRow> rows, String q) {
    final byNote = <int, List<_StemRow>>{};
    for (final row in rows) {
      (byNote[row.id] ??= <_StemRow>[]).add(row);
    }
    final ranked = <({NoteSuggestion note, bool prefix})>[];
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
        prefix: prefix,
      ));
    }
    ranked.sort((a, b) {
      if (a.prefix != b.prefix) return a.prefix ? -1 : 1;
      final byFolder = a.note.folder.compareTo(b.note.folder);
      return byFolder != 0 ? byFolder : a.note.name.compareTo(b.note.name);
    });
    return [for (final r in ranked.take(limit)) r.note];
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
    final text = await readNote(note.path);
    if (text == null) return const <HeadingSuggestion>[];
    return [
      for (final heading in outlineOfText(text))
        HeadingSuggestion(heading.text),
    ];
  }

  @override
  Future<List<BookSuggestion>> bookPlaces(String target) async {
    final note = await _resolved(target);
    switch (p.extension(note?.path ?? target).toLowerCase()) {
      case '.pdf':
        return const <BookSuggestion>[
          BookSuggestion(form: 'page=', hint: 'type a number'),
        ];
      case '.epub':
        return const <BookSuggestion>[
          BookSuggestion(form: 'chapter=', hint: 'name a file in the book'),
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
