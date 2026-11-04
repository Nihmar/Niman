import 'dart:async';

import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/search/tag_repo.dart';
import 'package:niman/src/templates/repo.dart';

/// What the open library's surfaces read the index through: the search,
/// the replace, the tags, the fields, the templates, the links and the
/// wikilink suggestions.
///
/// Each reads the session's current state through the getters it is given
/// — a source asked for while no library is open is null — and the ones
/// worth keeping (the search connection, the links and their caches) are
/// built once per open library, until the session drops them
/// ([forgetLinks], [releaseSearch]).
final class LibrarySources {
  /// Sources over the session's [root], [indexDb], [indexer] and [ops],
  /// with the search connection from [searchDbFactory] and the index's
  /// writes announced on [indexChanges].
  new({
    required this.root,
    required this.indexDb,
    required this.indexer,
    required this.ops,
    required this.searchDbFactory,
    required this.indexChanges,
  });

  /// The open library's root, or null while none is open.
  final String? Function() root;

  /// The open library's index, or null while none is open.
  final IndexDatabase? Function() indexDb;

  /// The open library's indexer, or null while none is open.
  final Indexer? Function() indexer;

  /// The open library's ops, or null while none is open.
  final NoteOps? Function() ops;

  /// The search connection; the index connection itself in tests, the
  /// background-isolate one in the app.
  final Future<IndexDatabase> Function(String libraryPath) searchDbFactory;

  /// Fires on an index write only, not on the session's own bumps: what
  /// the links re-resolve on (#867).
  final Stream<void> indexChanges;

  /// The cached search source; the background-isolate worker connection is
  /// created once per open library and reused (see [searchSource]).
  SearchSource? _searchSource;

  /// The search connection when it is a distinct database from the index
  /// one; closed with the library, since it is that library's file.
  IndexDatabase? _searchDb;

  /// The open library's links, built once for the library and the files it
  /// reads: every surface that asks gets the object whose caches the others
  /// fill (#842, #846, #847).
  LibraryLinks? _links;
  IndexDatabase? _linksDb;
  NoteOps? _linksOps;

  /// The open library's search.
  Future<SearchSource?> get searchSource async {
    // The search connection is background-isolate backed: the MATCH work
    // for large result sets never runs on the UI isolate. One connection
    // per open library, created
    // once: a fresh connection per call leaked one worker isolate per
    // SearchScreen mount (drift keeps the worker alive until closed) and
    // left nothing to recover when its startup failed. It is dropped with
    // the library, since it is a connection to that library's own file.
    final root = this.root();
    final indexDb = this.indexDb();
    if (root == null || indexDb == null) return null;
    var source = _searchSource;
    if (source == null) {
      final db = await searchDbFactory(root);
      _searchDb = identical(db, indexDb) ? null : db;
      source = SearchRepo(db, root: root);
      _searchSource = source;
    }
    return source;
  }

  /// The open library's search and replace.
  Future<ReplaceSource?> get replaceSource async {
    // Bound to the current root + indexer: rewritten notes are re-indexed
    // through applyEvents as each write batch lands, so search reflects a
    // replace without waiting on the (Android-unreliable) watcher or the
    // periodic rescan.
    final root = this.root();
    final indexer = this.indexer();
    final db = indexDb();
    if (root == null || indexer == null || db == null) return null;
    final history = ops()?.history;
    return ReplaceRunner(
      db,
      root,
      onNotesReindexed: (paths) => indexer.rescanFiles(root, paths),
      historyRequest: history == null
          ? null
          : () => history.requestFor('', forced: HistoryReason.replace),
    );
  }

  /// The open library's tags.
  Future<TagSource?> get tagSource async {
    final db = indexDb();
    if (db == null) return null;
    return TagRepo(db);
  }

  /// The open library's frontmatter fields.
  Future<FieldSource?> get fieldSource async {
    final db = indexDb();
    if (db == null) return null;
    return FieldRepo(db);
  }

  /// The open library's templates.
  Future<TemplateSource?> get templateSource async {
    final indexer = this.indexer();
    final ops = this.ops();
    if (indexer == null || ops == null) return null;
    return TemplateRepo(indexer.dao, ops);
  }

  /// The open library's links.
  Future<LibraryLinks?> get linkSource async {
    final db = indexDb();
    if (db == null) return null;
    final reader = ops();
    final kept = _links;
    if (kept != null &&
        identical(_linksDb, db) &&
        identical(_linksOps, reader)) {
      return kept;
    }
    _linksDb = db;
    _linksOps = reader;
    return _links = IndexLibraryLinks(
      db,
      // The library announces every index change; a note on screen resolves
      // its dead links again when one lands (#847).
      changes: indexChanges,
      // What the notes that link to a note say about it, and the beginning of
      // one for a preview card, are read off their files on a background
      // isolate, a row at a time (#842, #846).
      readPreview: reader == null
          ? null
          : (path) async {
              try {
                return await reader.notePreview(path);
              } on Object {
                return null;
              }
            },
      readSpots: reader == null
          ? null
          : (path, from) async {
              try {
                return await reader.noteLinkSpotSlice(path, from);
              } on Object {
                return null;
              }
            },
    );
  }

  /// The open library's wikilink suggestions.
  Future<WikilinkSuggester?> get wikilinkSuggester async {
    final db = indexDb();
    if (db == null) return null;
    final reader = ops();
    return IndexWikilinkSuggester(
      db,
      attachmentsFolder: reader == null ? null : () => reader.attachmentsFolder,
      // A named note's headings are read off the note itself, on a
      // background isolate (a novel's read and outline is seconds of work);
      // a note gone since the panel named it answers null rather than
      // throwing.
      readHeadings: (path) async {
        if (reader == null) return null;
        try {
          return await reader.noteHeadings(path);
        } on Object {
          return null;
        }
      },
      // The same for a note's block ids (#844).
      readBlocks: (path) async {
        if (reader == null) return null;
        try {
          return await reader.noteBlocks(path);
        } on Object {
          return null;
        }
      },
    );
  }

  /// Drops the links built for the library that is closing.
  void forgetLinks() {
    _links = null;
    _linksDb = null;
    _linksOps = null;
  }

  /// Drops the search source, and hands back its connection for the
  /// caller to close when it is not the index connection itself.
  IndexDatabase? releaseSearch() {
    final searchDb = _searchDb;
    _searchSource = null;
    _searchDb = null;
    return searchDb;
  }
}
