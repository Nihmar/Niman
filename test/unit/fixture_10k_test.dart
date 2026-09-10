// T-M3-09: 10k-note fixture — index build and search latencies with
// generous machine-speed assertions (signal, not a benchmark), plus the
// incremental path on it.
//
// The harness needs longer than its 30-second default here, and not
// because the code is slow: writing 10 000 files and walking them is
// minutes of filesystem work on a Windows host with a virus scanner in
// the path, and it happens before the first assertion runs. A test that
// allows a scan 60 seconds cannot be given 30 to finish in.
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/search/query.dart';
import 'package:copist/src/search/search_repo.dart';
import 'package:copist/src/search/tag_repo.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The fixture note count.
const int noteCount = 10000;

void main() {
  late Directory root;
  late IndexDatabase db;
  late Indexer indexer;
  late SearchRepo search;
  late TagRepo tags;

  setUpAll(() async {
    root = await Directory.current.createTemp('copist_10k_');
    // 100 folders (a–z × 4ish), each ~100 notes; deterministic content
    // with a title, a tag and a wikilink, so indexing, search and tags all
    // have real work.
    for (var f = 0; f < 100; f++) {
      final folder = Directory(
        p.join(root.path, 'f${f.toString().padLeft(2, '0')}'),
      )..createSync();
      for (var n = 0; n < noteCount ~/ 100; n++) {
        final name =
            'note${f.toString().padLeft(2, '0')}_'
            '${n.toString().padLeft(3, '0')}';
        File(p.join(folder.path, '$name.md')).writeAsStringSync(
          '---\ntitle: $name title\ntags: [fixture]\n---\n'
          'Body of $name with unique seed ${f * 1000 + n} and a link to '
          '[[note${((f + 1) % 100).toString().padLeft(2, '0')}_000]].\n',
        );
      }
    }
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    indexer = Indexer(db);
    search = SearchRepo(db);
    tags = TagRepo(db);
  });

  tearDownAll(() async {
    await root.delete(recursive: true);
  });

  test('a 10k-note library indexes (walk + content pass) in well under a '
      'minute, with FTS/tags/stems populated', () async {
    final clock = Stopwatch()..start();
    await indexer.fullScan(root.path);
    final elapsed = clock.elapsedMilliseconds;
    // Twenty-odd seconds on this machine with nothing else running, and
    // the bound is twice a minute rather than one: `flutter test` runs
    // files in parallel, and the scale test next door is writing its own
    // hundred thousand rows while this one walks. The assertion is here
    // to catch a scan that reads every body again, not to time a laptop.
    expect(elapsed, lessThan(120000), reason: 'fullScan took $elapsed ms');

    final fts = await db
        .customSelect('SELECT count(*) c FROM notes_fts')
        .getSingle();
    expect(fts.read<int>('c'), noteCount);
    final stems = await db
        .customSelect('SELECT count(*) c FROM note_stems')
        .getSingle();
    expect(stems.read<int>('c'), noteCount);
    final tagRows = await db.select(db.noteTags).get();
    expect(tagRows.map((t) => t.tag), everyElement('fixture'));
  });

  test('word search on the fixture is instant; bm25 ranks the title hit '
      'first', () async {
    final id = search.begin();
    final clock = Stopwatch()..start();
    final hits = await search.search(buildFtsQuery('unique'), id: id, limit: 5);
    final elapsed = clock.elapsedMilliseconds;
    expect(elapsed, lessThan(2000), reason: 'search took $elapsed ms');
    expect(hits, hasLength(5));
    expect(hits.first.snippet, contains('<mark>'));
  });

  test('tag counts and tag→notes are instant on the fixture', () async {
    final clock = Stopwatch()..start();
    final counts = await tags.tagCounts();
    expect(counts.single.name, 'fixture');
    // The count is the whole truth; the list of notes is a page of it
    // (T-M6-01), so a tag on the entire library opens in bounded time.
    expect(counts.single.count, noteCount);
    final notes = await tags.notesWithTag('fixture');
    expect(notes, hasLength(tagNotesLimit));
    expect(clock.elapsedMilliseconds, lessThan(5000));
  });

  test(
    'incremental: one edited note re-indexes without touching the rest',
    () async {
      // The fixture is already indexed: an edit to one note must update its
      // content rows only.
      final target = File(p.join(root.path, 'f00/note00_000.md'))
        ..writeAsStringSync(
          '---\ntitle: edited title\ntags: [fixture, edited]\n---\n'
          'brand new words now\n',
        );
      final clock = Stopwatch()..start();
      await indexer.applyEvents(root.path, [target.path]);
      expect(clock.elapsedMilliseconds, lessThan(10000));

      final hit = await db
          .customSelect(
            'SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?',
            variables: [const Variable<String>('"brand new"')],
          )
          .get();
      expect(hit, hasLength(1));
      final tagsOfNote = await db
          .customSelect(
            'SELECT tag FROM note_tags WHERE note_id = '
            "(SELECT id FROM notes WHERE path = 'f00/note00_000.md') "
            'ORDER BY tag',
          )
          .get();
      expect(tagsOfNote.map((r) => r.read<String>('tag')).toList(), [
        'edited',
        'fixture',
      ]);
    },
  );
}
