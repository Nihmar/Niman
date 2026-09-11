// T-M6-01: what a million notes cost, measured where the app pays it.
//
// Startup opens the *persisted* index and never walks the disk (design.md,
// Performance strategy), so what decides whether a million-note library is
// usable is what SQLite does with a million rows — not what the
// filesystem does with a million files. That is why the index here is
// built directly, without writing a note: a real million-note library is
// hours of filesystem work and gigabytes of it (`tool/make_fixture.dart`
// writes one; `fixture_10k_test.dart` walks one).
//
// The assertions are machine-speed signal, not benchmarks: they are wide
// enough to pass on a busy laptop and narrow enough to fail on a query
// that reads the whole table. The numbers themselves are printed, and
// those are what a perf round reads.
//
// Default scale is a twentieth of the gate so the suite keeps running
// this every time without holding the machine up — `flutter test` runs
// files in parallel, and the ten-thousand-note scan next door is timing
// itself on the same disk. `NIMAN_SCALE=1000000` is the gate itself.
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value, Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/search/query.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/search/tag_repo.dart';
import 'package:path/path.dart' as p;

/// Notes in the synthetic library; `NIMAN_SCALE=1000000` is the gate.
final int scale =
    int.tryParse(Platform.environment['NIMAN_SCALE'] ?? '') ?? 50000;

/// Notes per folder; the folder count follows from the scale.
const int perFolder = 1000;

String _folderName(int f) => 'f${f.toString().padLeft(4, '0')}';

String _noteName(int f, int n) =>
    '${_folderName(f)}_${n.toString().padLeft(4, '0')}';

void main() {
  // The index file is opened by the builder and again by the controller,
  // which is what a restart does.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory root;
  late File indexFile;
  late IndexDatabase db;
  late NoteDao dao;
  late SearchRepo search;
  late TagRepo tags;
  late int folders;

  /// Fills the index with [scale] notes over folders of [perFolder], plus
  /// the FTS, tag, stem and link rows a real scan would have written.
  Future<void> build() async {
    folders = (scale / perFolder).ceil();
    final clock = Stopwatch()..start();
    var id = 0;
    final folderIds = <int, int>{};
    await db.batch((batch) {
      for (var f = 0; f < folders; f++) {
        folderIds[f] = ++id;
        batch.insert(
          db.notes,
          NotesCompanion.insert(
            id: Value(id),
            path: _folderName(f),
            parent: 0,
            name: _folderName(f),
            isDir: true,
            size: 0,
            modified: DateTime(2026),
          ),
        );
      }
    });
    // One transaction per folder rather than one for the lot: a
    // million-row transaction is a journal the size of the database.
    for (var f = 0; f < folders; f++) {
      final rows = <NotesCompanion>[];
      final fts = <List<Object?>>[];
      final stems = <NoteStemsCompanion>[];
      final noteTags = <NoteTagsCompanion>[];
      final links = <NoteLinksCompanion>[];
      for (var n = 0; n < perFolder && f * perFolder + n < scale; n++) {
        final name = _noteName(f, n);
        final noteId = ++id;
        rows.add(
          NotesCompanion.insert(
            id: Value(noteId),
            path: '${_folderName(f)}/$name.md',
            parent: folderIds[f]!,
            name: '$name.md',
            isDir: false,
            size: 200,
            modified: DateTime(2026),
            title: Value('$name title'),
          ),
        );
        // Every note carries the word "seed" and exactly one note carries
        // its own number, so the two ends of a search — a word in every
        // note and a word in one — are both measurable.
        final body =
            'Body of $name with seed ${f * perFolder + n} and a link to '
            '[[${_noteName((f + 1) % folders, 0)}]].';
        fts.add([noteId, '$name title', body]);
        stems.add(
          NoteStemsCompanion.insert(stem: name, noteId: noteId, source: 'file'),
        );
        noteTags.add(
          NoteTagsCompanion.insert(
            tag: n.isEven ? 'fixture' : 'odd',
            noteId: noteId,
            isFrontmatter: true,
          ),
        );
        // Every note links to the first note of the next folder, so one
        // note has a folder's worth of backlinks.
        links.add(
          NoteLinksCompanion.insert(
            fromNote: noteId,
            toNote: folderIds[(f + 1) % folders]! + 1,
            kind: 'wiki',
          ),
        );
      }
      await db.batch((batch) {
        batch
          ..insertAll(db.notes, rows)
          ..insertAll(db.noteStems, stems)
          ..insertAll(db.noteTags, noteTags)
          ..insertAll(db.noteLinks, links);
      });
      await db.transaction(() async {
        for (final row in fts) {
          await db.customStatement(
            'INSERT INTO notes_fts(rowid, title, body) VALUES (?, ?, ?)',
            row,
          );
        }
      });
    }
    await db.batch((batch) {
      batch.insertAll(db.tags, [
        TagsCompanion.insert(name: 'fixture'),
        TagsCompanion.insert(name: 'odd'),
      ]);
    });
    // What the query planner has after a real scan: the indexer runs no
    // ANALYZE, but SQLite's own stats are what make the plans comparable
    // between a built index and a scanned one.
    await db.customStatement('ANALYZE');
    _say('built $scale notes in ${clock.elapsedMilliseconds} ms');
  }

  setUpAll(() async {
    tmp = await Directory.current.createTemp('niman_scale_');
    root = Directory(p.join(tmp.path, 'library'))..createSync();
    // The library on disk is a stub: this measures the index, and the
    // walk is `fixture_10k_test.dart`'s job.
    File(p.join(root.path, 'a.md')).writeAsStringSync('a');
    indexFile = File(p.join(tmp.path, 'index.db'));
    db = IndexDatabase(NativeDatabase(indexFile));
    dao = NoteDao(db);
    search = SearchRepo(db);
    tags = TagRepo(db);
    await build();
    _say('index file: ${(indexFile.lengthSync() / (1024 * 1024)).round()} MB');
  });

  tearDownAll(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  /// Runs [work], printing and returning how long it took.
  Future<int> timed(String what, Future<void> Function() work) async {
    final clock = Stopwatch()..start();
    await work();
    final ms = clock.elapsedMilliseconds;
    _say('$what: $ms ms');
    return ms;
  }

  test('a library opens from its index without touching the disk', () async {
    final controller = LibraryController(
      () async => AppDatabase(NativeDatabase(File(p.join(tmp.path, 'app.db')))),
      indexDbFactory: (_) async => IndexDatabase(NativeDatabase(indexFile)),
      rescanInterval: const Duration(hours: 1),
      resumeReconcileDelay: const Duration(hours: 1),
    );
    final open = await timed(
      'open to ready',
      () => controller.open(root.path, create: false, blockingScan: false),
    );
    expect(controller.phase, LibraryPhase.ready);
    // The shell's first frame asks for the top of the tree; that read is
    // part of what the user waits for.
    final firstFrame = await timed(
      'first tree read',
      () => controller.children(0),
    );

    expect(open, lessThan(5000), reason: 'open took $open ms');
    expect(firstFrame, lessThan(2000), reason: 'tree read took $firstFrame ms');
    await controller.close();
    await controller.dispose();
  });

  test('the reads behind the tree stay off the whole table', () async {
    final middle = folders ~/ 2;
    final top = await timed('top level', () => dao.topLevel());
    final folder = await dao.find(_folderName(middle));
    final children = await timed(
      'children of a folder',
      () => dao.children(folder!.id),
    );
    final find = await timed(
      'find by path',
      () => dao.find('${_folderName(middle)}/${_noteName(middle, 7)}.md'),
    );
    final tree = await timed(
      'tree with one folder open',
      () => dao.tree([_folderName(middle)]),
    );
    final dirs = await timed('every folder', () => dao.folders());

    expect(top, lessThan(1000), reason: 'top level took $top ms');
    expect(children, lessThan(1000), reason: 'children took $children ms');
    expect(find, lessThan(500), reason: 'find took $find ms');
    expect(tree, lessThan(1500), reason: 'tree took $tree ms');
    expect(dirs, lessThan(1500), reason: 'folders took $dirs ms');
  });

  test('search answers from FTS, and a rare word is instant', () async {
    final rare = await timed('word search, one hit', () async {
      final hits = await search.search(
        buildFtsQuery('${scale ~/ 2}'),
        id: search.begin(),
        limit: 50,
      );
      expect(hits, isNotEmpty);
    });
    // The other end: a word in every note. bm25 has to rank every match,
    // so this is the ceiling rather than the common case.
    final common = await timed('word search, every note', () async {
      await search.search(buildFtsQuery('seed'), id: search.begin(), limit: 50);
    });

    expect(rare, lessThan(1000), reason: 'rare word took $rare ms');
    expect(common, lessThan(5000), reason: 'common word took $common ms');
  });

  test('the tag list is bounded, however many notes carry the tag', () async {
    final counts = await timed('tag counts', () => tags.tagCounts());
    late List<Note> notes;
    final open = await timed('notes of a tag', () async {
      notes = await tags.notesWithTag('fixture');
    });

    expect(counts, lessThan(3000), reason: 'tag counts took $counts ms');
    expect(open, lessThan(1500), reason: 'notes of a tag took $open ms');
    // Half the library carries it; what opening it costs does not grow
    // with the library.
    expect(notes, hasLength(tagNotesLimit));
  });

  // Deliberately not a gate: this measures the one read that does not
  // stay bounded, so the number is on the record and moves when the
  // reconciliation is rewritten to work a directory at a time (T-M6-11).
  // At a million notes it was 9 s and about a gigabyte on 2026-09-10.
  test('reconciliation still holds the whole index at once', () async {
    final before = ProcessInfo.currentRss;
    await timed('every row, as a rescan reads them', () async {
      final all = await dao.allRows();
      final byPath = {for (final row in all) row.path: row};
      _say('rows held: ${byPath.length}');
    });
    _say(
      'rss delta: '
      '${((ProcessInfo.currentRss - before) / (1024 * 1024)).round()} MB',
    );
  });

  test('backlinks and subtree deletes seek instead of scanning', () async {
    final backlinks = await timed('backlinks of one note', () async {
      await db
          .customSelect(
            'SELECT from_note FROM note_links WHERE to_note = ?',
            variables: [const Variable<int>(2)],
          )
          .get();
    });
    final subtree = await timed(
      'read a folder subtree',
      () => dao.subtreeRows(_folderName(0)),
    );
    final deleted = await timed(
      'delete a folder subtree',
      () => dao.deleteSubtree(_folderName(folders - 1)),
    );

    expect(backlinks, lessThan(500), reason: 'backlinks took $backlinks ms');
    expect(subtree, lessThan(1500), reason: 'subtree read took $subtree ms');
    expect(deleted, lessThan(3000), reason: 'delete took $deleted ms');
  });
}

/// Prints a measurement. The numbers are the point of this file, so they
/// go to the console rather than into an assertion message nobody sees.
// ignore: avoid_print
void _say(String line) => print(line);
