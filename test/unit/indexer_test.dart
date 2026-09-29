import 'dart:io';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteDao dao;
  late _QueryCounter counter;

  setUp(() async {
    root = await Directory.current.createTemp('niman_index_');
    counter = _QueryCounter();
    db = IndexDatabase(NativeDatabase.memory().interceptWith(counter));
    addTearDown(db.close);
    indexer = Indexer(db);
    dao = indexer.dao;

    File(p.join(root.path, 'note1.md')).writeAsStringSync('hello');
    File(p.join(root.path, 'note2.md')).writeAsStringSync('world');
    final docs = Directory(p.join(root.path, 'docs'));
    await docs.create();
    File(p.join(docs.path, 'doc1.md')).writeAsStringSync('deep note');
    Directory(p.join(root.path, 'empty_folder')).createSync();

    // Hidden content: must never be indexed.
    Directory(p.join(root.path, '.trash')).createSync();
    File(p.join(root.path, '.trash/secret.md')).writeAsStringSync('x');
    File(p.join(root.path, '.hidden.md')).writeAsStringSync('x');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('full scan mirrors the disk tree exactly', () async {
    await indexer.fullScan(root.path);
    final rows = await dao.allRows();
    expect(rows, hasLength(5));

    final paths = rows.map((n) => n.path).toSet();
    expect(paths, {
      'note1.md',
      'note2.md',
      'docs',
      'docs/doc1.md',
      'empty_folder',
    });

    final note1 = rows.firstWhere((n) => n.path == 'note1.md');
    expect(note1.name, 'note1.md');
    expect(note1.isDir, false);
    expect(note1.parent, 0);
    expect(note1.size, 5);
    expect(note1.sha256, isNotNull);
    expect(
      note1.modified,
      toStoredSecond(File(p.join(root.path, 'note1.md')).statSync().modified),
    );

    final docs = rows.firstWhere((n) => n.path == 'docs');
    expect(docs.isDir, true);
    expect(docs.sha256, isNull);
    expect(docs.size, 0);

    final doc1 = rows.firstWhere((n) => n.path == 'docs/doc1.md');
    expect(doc1.parent, docs.id);
    expect(doc1.name, 'doc1.md');

    final empty = rows.firstWhere((n) => n.path == 'empty_folder');
    expect(empty.isDir, true);
    expect(empty.parent, 0);
  });

  group('the first index, the tree first', () {
    test('writes the tree without reading a note, and the scan after it '
        'reads them all', () async {
      expect(await indexer.indexTreeFirst(root.path), isTrue);
      final rows = await dao.allRows();
      expect(rows.map((n) => n.path).toSet(), {
        'note1.md',
        'note2.md',
        'docs',
        'docs/doc1.md',
        'empty_folder',
      });
      // Not read: no digest, and nothing to search.
      expect(rows.every((n) => n.sha256 == null), isTrue);
      final searchable = await db
          .customSelect('SELECT count(*) AS c FROM notes_fts')
          .getSingle();
      expect(searchable.read<int>('c'), 0);

      await indexer.fullScan(root.path);
      final read = await dao.allRows();
      expect(
        read.where((n) => !n.isDir).every((n) => n.sha256 != null),
        isTrue,
      );
      final indexed = await db
          .customSelect('SELECT count(*) AS c FROM notes_fts')
          .getSingle();
      expect(indexed.read<int>('c'), 3);
    });

    test(
      'is the empty index alone: one with rows is scanned as ever',
      () async {
        await indexer.fullScan(root.path);
        final before = await dao.allRows();
        expect(await indexer.indexTreeFirst(root.path), isFalse);
        final after = await dao.allRows();
        expect(
          after.map((n) => n.sha256).toList(),
          before.map((n) => n.sha256).toList(),
          reason: 'the digests the rename pairing keys on are kept',
        );
      },
    );
  });

  test('a scan landing mid-write never indexes the atomic temp file', () async {
    // The temp file as it exists between the write and the rename.
    final target = File(p.join(root.path, 'inflight.md'));
    atomicTempPath(target, 42).writeAsStringSync('partial');

    await indexer.fullScan(root.path);

    final names = (await dao.allRows()).map((n) => n.path).toList();
    expect(names.where((name) => name.contains('niman-tmp')), isEmpty);
    expect(names, isNot(contains('inflight.md')));
  });

  test('a fresh index reproduces the identical tree (rebuildable)', () async {
    await indexer.fullScan(root.path);
    final first = await dao.allRows();

    final db2 = IndexDatabase(NativeDatabase.memory());
    addTearDown(db2.close);
    await Indexer(db2).fullScan(root.path);
    final second = await NoteDao(db2).allRows();

    String norm(Note n) =>
        '${n.path}|${n.name}|${n.isDir}|${n.size}|${n.sha256}';
    expect(second.map(norm).toSet(), first.map(norm).toSet());
  });

  test('a rescan without changes does not rewrite the index', () async {
    await indexer.fullScan(root.path);
    var fired = false;
    indexer.onChanged = () {
      fired = true;
    };
    await indexer.fullScan(root.path);
    expect(fired, isFalse);
  });

  test('rescans keep the ids of every surviving row', () async {
    await indexer.fullScan(root.path);
    final note1 = (await dao.find('note1.md'))!;
    final docs = (await dao.find('docs'))!;
    final doc1 = (await dao.find('docs/doc1.md'))!;

    // Add, remove and change entries on disk, then rescan.
    File(p.join(root.path, 'note3.md')).writeAsStringSync('three');
    File(p.join(root.path, 'note2.md')).deleteSync();
    File(p.join(root.path, 'note1.md')).writeAsStringSync('changed');
    await indexer.fullScan(root.path);

    final note1Again = (await dao.find('note1.md'))!;
    expect(note1Again.id, note1.id);
    expect(note1Again.size, 7);
    expect(note1Again.sha256, isNot(note1.sha256));
    expect((await dao.find('docs'))!.id, docs.id);
    final doc1Again = (await dao.find('docs/doc1.md'))!;
    expect(doc1Again.id, doc1.id);
    expect(doc1Again.parent, docs.id);
    expect(await dao.find('note2.md'), isNull);
    expect(await dao.find('note3.md'), isNotNull);
  });

  test('a subtree resync keeps the root under its indexed parent', () async {
    Directory(p.join(root.path, 'a/b/c')).createSync(recursive: true);
    File(p.join(root.path, 'a/b/c/x.md')).writeAsStringSync('x');
    await indexer.fullScan(root.path);
    final ab = (await dao.find('a/b'))!;

    // The folder moves inside a/b; the resynced destination must come back
    // under a/b, not the library root.
    await Directory(p.join(root.path, 'a/b/c'))
        .rename(p.join(root.path, 'a/b/c2'));
    await indexer.resync(root.path, p.join(root.path, 'a/b/c2'));

    final c2 = (await dao.find('a/b/c2'))!;
    expect(c2.parent, ab.id);
    expect((await dao.find('a/b/c2/x.md'))!.parent, c2.id);
  });

  test('a subtree resync repairs missing parent rows from disk', () async {
    await indexer.fullScan(root.path);
    // The whole chain appears outside the app while the app is open.
    final leaf = Directory(p.join(root.path, 'm/n/o'))
      ..createSync(recursive: true);
    File(p.join(leaf.path, 'z.md')).writeAsStringSync('z');

    await indexer.resync(root.path, leaf.path);

    final m = (await dao.find('m'))!;
    final n = (await dao.find('m/n'))!;
    expect(m.parent, 0);
    expect(n.parent, m.id);
    expect((await dao.find('m/n/o'))!.parent, n.id);
    expect(await dao.find('m/n/o/z.md'), isNotNull);
  });

  test(
    'onChanged fires once per entry point, only when the index wrote',
    () async {
      await indexer.fullScan(root.path);
      var fires = 0;
      indexer.onChanged = () => fires++;

      // A no-change rescan writes nothing and fires nothing.
      await indexer.fullScan(root.path);
      expect(fires, 0);

      final newAbs = p.join(root.path, 'note3.md');
      File(newAbs).writeAsStringSync('new');
      await indexer.applyEvents(root.path, [newAbs]);
      expect(fires, 1);

      // A batch that changes nothing fires nothing.
      await indexer.applyEvents(root.path, [p.join(root.path, 'note1.md')]);
      expect(fires, 1);

      // A directory resync that changes nothing fires nothing.
      await indexer.resync(root.path, p.join(root.path, 'docs'));
      expect(fires, 1);

      // A batch with one prune and one upsert fires once for the batch.
      File(newAbs).deleteSync();
      File(p.join(root.path, 'note4.md')).writeAsStringSync('four');
      await indexer.applyEvents(root.path, [
        newAbs,
        p.join(root.path, 'note4.md'),
      ]);
      expect(fires, 2);
    },
  );

  test('applyEvents picks up external create and delete', () async {
    await indexer.fullScan(root.path);

    final newAbs = p.join(root.path, 'note3.md');
    File(newAbs).writeAsStringSync('new');
    await indexer.applyEvents(root.path, [newAbs]);
    final added = await dao.find('note3.md');
    expect(added, isNotNull);
    expect(added!.name, 'note3.md');
    expect(added.size, 3);

    final oldAbs = p.join(root.path, 'note2.md');
    File(oldAbs).deleteSync();
    await indexer.applyEvents(root.path, [oldAbs]);
    expect(await dao.find('note2.md'), isNull);
  });

  test('applyEvents reconciles a rename by old and new path', () async {
    await indexer.fullScan(root.path);
    final oldAbs = p.join(root.path, 'note1.md');
    final newAbs = p.join(root.path, 'renamed.md');
    await File(oldAbs).rename(newAbs);

    await indexer.applyEvents(root.path, [oldAbs, newAbs]);
    expect(await dao.find('note1.md'), isNull);
    final renamed = await dao.find('renamed.md');
    expect(renamed, isNotNull);
    expect(renamed!.name, 'renamed.md');
  });

  group('the paths a re-index pruned (#289)', () {
    test('a full scan reports the note and the folder it pruned', () async {
      await indexer.fullScan(root.path);
      final removed = <String>{};
      indexer.onRemoved = removed.addAll;

      File(p.join(root.path, 'note1.md')).deleteSync();
      await Directory(p.join(root.path, 'docs')).delete(recursive: true);
      await indexer.fullScan(root.path);

      // The folder comes alone: its notes went with it.
      expect(removed, {'note1.md', 'docs'});
    });

    test(
      'a batch reports a pruned note, and a rename is not a prune',
      () async {
        await indexer.fullScan(root.path);
        var removed = <String>{};
        indexer.onRemoved = (paths) => removed.addAll(paths);

        final goneAbs = p.join(root.path, 'note1.md');
        File(goneAbs).deleteSync();
        await indexer.applyEvents(root.path, [goneAbs]);
        expect(removed, {'note1.md'});

        removed = <String>{};
        final oldAbs = p.join(root.path, 'note2.md');
        final newAbs = p.join(root.path, 'renamed.md');
        await File(oldAbs).rename(newAbs);
        await indexer.applyEvents(root.path, [oldAbs, newAbs]);
        expect(removed, isEmpty, reason: 'a rename is paired, not pruned');
      },
    );

    test('a resync of a gone path reports it pruned', () async {
      await indexer.fullScan(root.path);
      final removed = <String>{};
      indexer.onRemoved = removed.addAll;

      final abs = p.join(root.path, 'note1.md');
      File(abs).deleteSync();
      await indexer.resync(root.path, abs);

      expect(removed, {'note1.md'});
    });
  });

  test('a renamed directory is pruned via the stale path; '
      'the full rescan recovers the destination', () async {
    await indexer.fullScan(root.path);
    await Directory(p.join(root.path, 'docs'))
        .rename(p.join(root.path, 'books'));

    // Mimic the watcher batch when the OS did not report the destination:
    // parent resync + the stale path.
    await indexer.resync(root.path, root.path);
    await indexer.applyEvents(root.path, [p.join(root.path, 'docs')]);

    expect(await dao.find('docs'), isNull);
    expect(await dao.find('books'), isNull);

    // The periodic full rescan is the documented safety net.
    await indexer.fullScan(root.path);
    final books = await dao.find('books');
    expect(books, isNotNull);
    expect(await dao.find('books/doc1.md'), isNotNull);
  });

  test(
    'applyEvents ignores paths outside the library and dot components',
    () async {
      await indexer.fullScan(root.path);
      final outside = await Directory.current.createTemp('niman_outside_');
      addTearDown(() => outside.delete(recursive: true));
      File(p.join(outside.path, 'x.md')).writeAsStringSync('x');

      await indexer.applyEvents(root.path, [
        p.join(outside.path, 'x.md'),
        p.join(root.path, '.trash/secret.md'),
        p.join(root.path, '.hidden.md'),
      ]);
      // Nothing changed: the index still holds exactly the seeded rows.
      expect(await dao.allRows(), hasLength(5));
    },
  );

  test('content change updates size and digest', () async {
    await indexer.fullScan(root.path);
    final initial = (await dao.find('note1.md'))!;
    expect(initial.sha256, isNotNull);

    File(p.join(root.path, 'note1.md')).writeAsStringSync('changed');
    await indexer.applyEvents(root.path, [p.join(root.path, 'note1.md')]);
    final updated = (await dao.find('note1.md'))!;
    expect(updated.size, 7);
    expect(updated.sha256, isNot(initial.sha256));
  });

  group('probePaths', () {
    test('reports file, directory, and missing paths', () {
      final probes = probePaths([
        p.join(root.path, 'note1.md'),
        p.join(root.path, 'docs'),
        p.join(root.path, 'nope.md'),
      ]);
      expect(probes, hasLength(3));
      final file = probes[0];
      expect(file.exists, isTrue);
      expect(file.isDir, isFalse);
      expect(file.size, 5);
      final dir = probes[1];
      expect(dir.exists, isTrue);
      expect(dir.isDir, isTrue);
      expect(dir.size, 0);
      final gone = probes[2];
      expect(gone.exists, isFalse);
      expect(gone.isDir, isFalse);
      expect(gone.size, 0);
    });
  });

  group('note_stems', () {
    test('a full scan indexes one stem per note, none for dirs', () async {
      await indexer.fullScan(root.path);
      final stems = await db.select(db.noteStems).get();
      expect(stems.map((s) => s.stem).toSet(), {'note1', 'note2', 'doc1'});
      expect(stems.every((s) => s.source == 'file'), isTrue);
      final doc1 = (await dao.find('docs/doc1.md'))!;
      expect(stems.singleWhere((s) => s.stem == 'doc1').noteId, doc1.id);
    });

    test('a rename moves the stem rows', () async {
      await indexer.fullScan(root.path);
      File(p.join(root.path, 'note1.md'))
          .renameSync(p.join(root.path, 'renamed.md'));
      await indexer.applyEvents(root.path, [
        p.join(root.path, 'renamed.md'),
        p.join(root.path, 'note1.md'),
      ]);
      final stems = await db.select(db.noteStems).get();
      final texts = stems.map((s) => s.stem).toSet();
      expect(texts, {'renamed', 'note2', 'doc1'});
      final renamed = (await dao.find('renamed.md'))!;
      expect(stems.singleWhere((s) => s.stem == 'renamed').noteId, renamed.id);
    });

    test('a delete wipes the stem rows of the removed note', () async {
      await indexer.fullScan(root.path);
      File(p.join(root.path, 'note2.md')).deleteSync();
      await indexer.applyEvents(root.path, [p.join(root.path, 'note2.md')]);
      final stems = await db.select(db.noteStems).get();
      expect(stems.map((s) => s.stem).toSet(), {'note1', 'doc1'});
    });

    test('a subtree delete wipes stems, tags, links and FTS rows', () async {
      await indexer.fullScan(root.path);
      final doc1 = (await dao.find('docs/doc1.md'))!;
      await db
          .into(db.noteTags)
          .insert(
            NoteTagsCompanion.insert(
              tag: 'x',
              noteId: doc1.id,
              isFrontmatter: true,
            ),
          );
      await db
          .into(db.noteLinks)
          .insert(
            NoteLinksCompanion.insert(
              fromNote: doc1.id,
              toNote: doc1.id,
              kind: 'wiki',
            ),
          );
      // The pipeline already wrote the note's FTS row (title + body copy).
      expect(
        (await db.select(db.noteStems).get()).where((s) => s.noteId == doc1.id),
        hasLength(1),
      );
      expect(
        (await db
                .customSelect(
                  'SELECT count(*) c FROM notes_fts WHERE rowid = ?',
                  variables: [Variable<int>(doc1.id)],
                )
                .getSingle())
            .read<int>('c'),
        1,
      );

      // The whole folder goes away: one deleteSubtree must wipe the note's
      // dependent rows (stems, tags, links, FTS) in the same transaction.
      Directory(p.join(root.path, 'docs')).deleteSync(recursive: true);
      await indexer.applyEvents(root.path, [p.join(root.path, 'docs')]);

      expect(
        (await db.select(db.noteStems).get()).where((s) => s.noteId == doc1.id),
        isEmpty,
      );
      expect(
        (await db.select(db.noteTags).get()).where((s) => s.noteId == doc1.id),
        isEmpty,
      );
      expect(
        (await db.select(db.noteLinks).get()).where(
          (l) => l.fromNote == doc1.id || l.toNote == doc1.id,
        ),
        isEmpty,
      );
      final fts = await db
          .customSelect(
            'SELECT count(*) c FROM notes_fts WHERE rowid = ?1',
            variables: [Variable<int>(doc1.id)],
          )
          .getSingle();
      expect(fts.read<int>('c'), 0);
    });
  });

  group('scan progress', () {
    test('a first index names every note it reads', () async {
      final seen = <IndexProgress>[];
      indexer.onProgress = seen.add;
      await indexer.fullScan(root.path);

      // Three notes on disk; the hidden ones are never walked, so they
      // are never read either.
      expect(seen.map((p) => p.file), hasLength(3));
      expect(seen.map((p) => p.file), containsAll(<String>['note1.md']));
      // The count runs across the whole scan, directory after directory.
      expect(seen.map((p) => p.done), [1, 2, 3]);
      // The denominator is the library's note count when the scan starts;
      // this one starts empty, so each directory reports its own batch.
      expect(seen.map((p) => p.of), [2, 2, 1]);
    });

    test('any content read reports while a callback is set', () async {
      // The indexer reports whenever someone is listening; it is the
      // session that only listens around a first index, so a rescan once
      // a minute pays nothing.
      await indexer.fullScan(root.path);
      final seen = <IndexProgress>[];
      indexer.onProgress = seen.add;
      final added = p.join(root.path, 'note3.md');
      File(added).writeAsStringSync('new');
      await indexer.applyEvents(root.path, [added]);
      expect(seen.map((p) => p.file), ['note3.md']);
    });

    test('a scan with nothing to read reports nothing', () async {
      await indexer.fullScan(root.path);
      final seen = <IndexProgress>[];
      indexer.onProgress = seen.add;
      await indexer.fullScan(root.path);
      expect(seen, isEmpty);
    });
  });

  group('content pipeline (T-M3-03)', () {
    test('a full scan indexes FTS, tags, links and alias stems', () async {
      File(p.join(root.path, 'other.md'))
          .writeAsStringSync('## Other\n\n#othertag\n');
      File(p.join(root.path, 'linked.md')).writeAsStringSync('linked body');
      File(p.join(root.path, 'indexed.md')).writeAsStringSync(
        '---\ntitle: Indexed Title\ntags: [Alpha, beta]\n'
        'aliases: [nickname]\n---\nbody with #gamma and #Alpha\n\n'
        '[[other]] [md](linked.md) [[missing]] [[#Local]] [[indexed|Self]]',
      );
      await indexer.fullScan(root.path);

      final indexed = (await dao.find('indexed.md'))!;
      final other = (await dao.find('other.md'))!;
      final linked = (await dao.find('linked.md'))!;

      // FTS: title and body both searchable, rowid = notes.id.
      final fts = await db
          .customSelect(
            'SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?',
            variables: [const Variable<String>('"Indexed Title"')],
          )
          .get();
      expect(fts.map((r) => r.read<int>('rowid')), contains(indexed.id));
      final bodyHit = await db
          .customSelect(
            'SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?',
            variables: [const Variable<String>('gamma')],
          )
          .get();
      expect(bodyHit.map((r) => r.read<int>('rowid')), contains(indexed.id));

      // Tags: frontmatter (both) + inline (gamma, Alpha), source-tagged.
      final noteTags = await (db.select(
        db.noteTags,
      )..where((t) => t.noteId.equals(indexed.id))).get();
      final asSet = noteTags.map((t) => '${t.tag}:${t.isFrontmatter}').toSet();
      expect(asSet, {'alpha:true', 'beta:true', 'gamma:false', 'alpha:false'});
      final tagRows = await db.select(db.tags).get();
      expect(
        tagRows.map((t) => t.name),
        containsAll(['alpha', 'beta', 'gamma']),
      );

      // Links: resolved edges only — wiki for [[other]], md for the
      // markdown link; missing, #Local and self are skipped.
      final links = await (db.select(
        db.noteLinks,
      )..where((l) => l.fromNote.equals(indexed.id))).get();
      expect(links.map((l) => '${l.toNote}:${l.kind}').toSet(), {
        '${other.id}:wiki',
        '${linked.id}:md',
      });

      // Stems: file stems + the alias row (source alias)
      final stems = await (db.select(
        db.noteStems,
      )..where((s) => s.noteId.equals(indexed.id))).get();
      expect(stems.map((s) => '${s.stem}:${s.source}').toSet(), {
        'indexed:file',
        'nickname:alias',
      });

      // The alias resolves.
      final resolved = await LinkResolver(db).resolveWiki('nickname');
      expect((resolved as ResolvedNote).note.id, indexed.id);
    });

    test('a percent-encoded Markdown href is an edge, as it opens', () async {
      File(p.join(root.path, 'My Note.md')).writeAsStringSync('target');
      File(p.join(root.path, 'src.md'))
          .writeAsStringSync('[x](My%20Note.md#top)');
      await indexer.fullScan(root.path);

      final src = (await dao.find('src.md'))!;
      final target = (await dao.find('My Note.md'))!;
      final edges = await (db.select(
        db.noteLinks,
      )..where((l) => l.fromNote.equals(src.id))).get();
      expect([for (final l in edges) l.toNote], [target.id]);
    });

    group('a note that moved (#491)', () {
      void write(String rel, String text) {
        final file = File(p.join(root.path, p.joinAll(rel.split('/'))));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(text);
      }

      void move(String from, String to) {
        final target = p.join(root.path, p.joinAll(to.split('/')));
        Directory(p.dirname(target)).createSync(recursive: true);
        final source = p.join(root.path, p.joinAll(from.split('/')));
        if (FileSystemEntity.isDirectorySync(source)) {
          Directory(source).renameSync(target);
        } else {
          File(source).renameSync(target);
        }
      }

      Future<void> applyMove(List<String> rels) => indexer.applyEvents(
        root.path,
        [for (final rel in rels) p.join(root.path, p.joinAll(rel.split('/')))],
      );

      Future<Set<String>> targetsOf(String rel) async {
        final from = (await dao.find(rel))!;
        final rows = await (db.select(
          db.noteLinks,
        )..where((l) => l.fromNote.equals(from.id))).get();
        final out = <String>{};
        for (final l in rows) {
          final to = await (db.select(
            db.notes,
          )..where((n) => n.id.equals(l.toNote))).getSingle();
          out.add(to.path);
        }
        return out;
      }

      String title({required bool titled}) =>
          titled ? '---\ntitle: B\n---\n' : '';

      // `../A/a.md` and `[[../A/a]]` name `A/a.md` from `P`, and `P/A/a.md`
      // from `P/Q`.
      void seed({required bool titled}) {
        write('A/a.md', 'root a');
        write('P/A/a.md', 'near a');
        write('P/b.md', '${title(titled: titled)}[x](../A/a.md) [[../A/a]]');
      }

      for (final titled in [true, false]) {
        final kind = titled ? 'with a title' : 'without one';

        test('a note moved one folder deeper reads its links from there, '
            '$kind', () async {
          seed(titled: titled);
          await indexer.fullScan(root.path);
          expect(await targetsOf('P/b.md'), {'A/a.md'});

          move('P/b.md', 'P/Q/b.md');
          await applyMove(['P/b.md', 'P/Q/b.md']);
          expect(await targetsOf('P/Q/b.md'), {'P/A/a.md'});
        });

        test('a link the move makes dead is dropped, $kind', () async {
          seed(titled: titled);
          await indexer.fullScan(root.path);
          move('P/b.md', 'P/Q/R/b.md');
          await applyMove(['P/b.md', 'P/Q/R/b.md']);
          expect(await targetsOf('P/Q/R/b.md'), isEmpty);
        });

        test('a folder moved carries its notes to their new links, '
            '$kind', () async {
          write('Old/c.md', 'old c');
          write('New/c.md', 'new c');
          write('Old/Sub/b.md', '${title(titled: titled)}[x](../c.md)');
          await indexer.fullScan(root.path);
          expect(await targetsOf('Old/Sub/b.md'), {'Old/c.md'});

          move('Old/Sub', 'New/Sub');
          await applyMove(['Old/Sub', 'New/Sub']);
          expect(await targetsOf('New/Sub/b.md'), {'New/c.md'});
        });

        test('a scan that finds it moved reads its links from there, '
            '$kind', () async {
          seed(titled: titled);
          await indexer.fullScan(root.path);
          move('P/b.md', 'P/Q/b.md');
          await indexer.fullScan(root.path);
          expect(await targetsOf('P/Q/b.md'), {'P/A/a.md'});
        });

        test('a scan that reaches its new folder first does the same, '
            '$kind', () async {
          write('A/a.md', 'root a');
          write('Z/A/a.md', 'near a');
          write(
            'Z/Y/b.md',
            '${title(titled: titled)}[x](../A/a.md) [[../A/a]]',
          );
          await indexer.fullScan(root.path);
          expect(await targetsOf('Z/Y/b.md'), {'Z/A/a.md'});

          // The note goes to a folder walked before the one it left; from
          // `Z` the same link names `A/a.md`.
          move('Z/Y/b.md', 'Z/b.md');
          await indexer.fullScan(root.path);
          expect(await targetsOf('Z/b.md'), {'A/a.md'});

          move('Z/b.md', 'B/b.md');
          await indexer.fullScan(root.path);
          expect(await targetsOf('B/b.md'), {'A/a.md'});
        });
      }

      test(
        'a link to a note by its name follows the note that moved',
        () async {
          write('a.md', 'target');
          write('b.md', '[[a]] [x](a.md)');
          await indexer.fullScan(root.path);
          expect(await targetsOf('b.md'), {'a.md'});

          move('a.md', 'Deep/a.md');
          await applyMove(['a.md', 'Deep/a.md']);
          expect(await targetsOf('b.md'), {'Deep/a.md'});
        },
      );
    });

    test('a relative link is an edge to the note it names (#491)', () async {
      void write(String rel, String text) {
        final file = File(p.join(root.path, p.joinAll(rel.split('/'))));
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(text);
      }

      write('Deep/Notes/a.md', 'near');
      write('Notes/a.md', 'far');
      write('Deep/Sub/b.md', '[up](../Notes/a.md) [root](/Notes/a.md)');
      await indexer.fullScan(root.path);

      final b = (await dao.find('Deep/Sub/b.md'))!;
      final near = (await dao.find('Deep/Notes/a.md'))!;
      final far = (await dao.find('Notes/a.md'))!;
      Future<Set<int>> edges() async => {
        for (final l in await (db.select(
          db.noteLinks,
        )..where((l) => l.fromNote.equals(b.id))).get())
          l.toNote,
      };
      // `..` walks from Deep/Sub, the leading `/` from the root.
      expect(await edges(), {near.id, far.id});

      // The same links, written by a rescan of the one note that changed.
      write('Deep/Sub/b.md', '[up](../Notes/a.md) and more');
      await indexer.applyEvents(root.path, [
        p.join(root.path, 'Deep', 'Sub', 'b.md'),
      ]);
      expect(await edges(), {near.id});
    });

    test('a unicode tag is one tag, inline and in frontmatter alike', () async {
      // `#città` used to index as `citt` and `#идея` not at all, so the same
      // tag written inline and in the frontmatter made two rows in `tags` —
      // and a search for either found neither.
      File(p.join(root.path, 'unicode.md')).writeAsStringSync(
        '---\ntags: [città, идея]\n---\nvedi #città e #идея\n',
      );
      await indexer.fullScan(root.path);

      final note = (await dao.find('unicode.md'))!;
      final noteTags = await (db.select(
        db.noteTags,
      )..where((t) => t.noteId.equals(note.id))).get();
      expect(noteTags.map((t) => '${t.tag}:${t.isFrontmatter}').toSet(), {
        'città:true',
        'città:false',
        'идея:true',
        'идея:false',
      });
      expect((await db.select(db.tags).get()).map((t) => t.name).toSet(), {
        'città',
        'идея',
      });
    });

    test(
      'delete db → a fresh rescan reproduces FTS, tags, links, stems',
      () async {
        File(p.join(root.path, 'other.md')).writeAsStringSync('## Other\n');
        File(p.join(root.path, 'source.md'))
            .writeAsStringSync('---\ntags: [x]\n---\nlink [[other]]\n');
        await indexer.fullScan(root.path);
        final before = await _indexState(db, dao);

        final db2 = IndexDatabase(NativeDatabase.memory());
        addTearDown(db2.close);
        final indexer2 = Indexer(db2);
        await indexer2.fullScan(root.path);
        final after = await _indexState(db2, indexer2.dao);
        expect(after, before);
      },
    );

    test(
      'a content-only edit keeps the note id and searches the new text',
      () async {
        File(p.join(root.path, 'note1.md')).writeAsStringSync('old words');
        await indexer.fullScan(root.path);
        final before = (await dao.find('note1.md'))!;

        File(p.join(root.path, 'note1.md'))
            .writeAsStringSync('brand new words');
        // An edit also bumps the mtime, so the digest cannot be reused.
        final stat = File(p.join(root.path, 'note1.md')).statSync();
        if (stat.modified == toStoredSecond(before.modified)) {
          await File(p.join(root.path, 'note1.md'))
              .setLastModified(stat.modified.add(const Duration(seconds: 2)));
        }
        await indexer.applyEvents(root.path, [p.join(root.path, 'note1.md')]);

        final after = (await dao.find('note1.md'))!;
        expect(after.id, before.id);
        final hit = await db
            .customSelect(
              'SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?',
              variables: [const Variable<String>('"brand new"')],
            )
            .get();
        expect(hit.map((r) => r.read<int>('rowid')), contains(after.id));
        expect(
          (await db
                  .customSelect(
                    'SELECT count(*) c FROM notes_fts WHERE rowid = ?',
                    variables: [Variable<int>(after.id)],
                  )
                  .getSingle())
              .read<int>('c'),
          1,
        );
      },
    );

    test('a rename keeps the note id and its FTS rows', () async {
      File(p.join(root.path, 'note1.md'))
          .writeAsStringSync('---\ntitle: Renamable\n---\nbody text here\n');
      await indexer.fullScan(root.path);
      final before = (await dao.find('note1.md'))!;
      expect(await _ftsTitleIs(db, before.id, 'Renamable'), isTrue);

      File(p.join(root.path, 'note1.md'))
          .renameSync(p.join(root.path, 'renamed.md'));
      await indexer.applyEvents(root.path, [
        p.join(root.path, 'renamed.md'),
        p.join(root.path, 'note1.md'),
      ]);

      final after = (await dao.find('renamed.md'))!;
      expect(after.id, before.id); // the rename kept the row id
      expect(await _ftsTitleIs(db, after.id, 'Renamable'), isTrue);
      // And the old stem is gone, the new one present.
      final stems = await db.select(db.noteStems).get();
      expect(stems.map((s) => s.stem).toSet(), containsAll(['renamed']));
      expect(stems.map((s) => s.stem), isNot(contains('note1')));
    });

    test(
      'a rename keeps the alias stems and re-derives the search title',
      () async {
        // A note whose search title is its filename (no frontmatter title) and
        // which carries an alias. Both were wrong after a rename: the alias
        // row was dropped, and the FTS title kept the old filename (#352).
        File(
          p.join(root.path, 'note1.md'),
        ).writeAsStringSync('---\naliases: [nickname]\n---\nbody text here\n');
        await indexer.fullScan(root.path);
        final before = (await dao.find('note1.md'))!;
        final resolved = await LinkResolver(db).resolveWiki('nickname');
        expect((resolved as ResolvedNote).note.id, before.id);

        File(p.join(root.path, 'note1.md'))
            .renameSync(p.join(root.path, 'renamed.md'));
        await indexer.applyEvents(root.path, [
          p.join(root.path, 'renamed.md'),
          p.join(root.path, 'note1.md'),
        ]);

        final after = (await dao.find('renamed.md'))!;
        expect(after.id, before.id); // paired: the id survived the rename

        // (a) The alias was not dropped by the rename: [[nickname]] resolves.
        final still = await LinkResolver(db).resolveWiki('nickname');
        expect((still as ResolvedNote).note.id, after.id);

        // (b) The search title is the new filename, not the old one.
        expect(await _titleHits(db, 'renamed'), 1);
        expect(await _titleHits(db, 'note1'), 0);
      },
    );

    test('a rename keeps the alias stems when the note has a frontmatter '
        'title too', () async {
      // With a frontmatter title the content pass is legitimately skipped on a
      // rename (the title does not move), so the alias rows must survive
      // without it — the rename-pair path alone (#352).
      File(p.join(root.path, 'note1.md')).writeAsStringSync(
        '---\ntitle: Renamable\naliases: [nickname]\n---\nbody text here\n',
      );
      await indexer.fullScan(root.path);
      final before = (await dao.find('note1.md'))!;

      File(p.join(root.path, 'note1.md'))
          .renameSync(p.join(root.path, 'renamed.md'));
      await indexer.applyEvents(root.path, [
        p.join(root.path, 'renamed.md'),
        p.join(root.path, 'note1.md'),
      ]);

      final after = (await dao.find('renamed.md'))!;
      expect(after.id, before.id);
      final resolved = await LinkResolver(db).resolveWiki('nickname');
      expect((resolved as ResolvedNote).note.id, after.id);
      expect(await _ftsTitleIs(db, after.id, 'Renamable'), isTrue);
    });

    test(
      'rescanFiles catches a rewrite the (size, mtime) shortcut misses',
      () async {
        // A same-size rewrite with an unchanged mtime: applyEvents trusts
        // the stored digest and skips it; rescanFiles reads unconditionally.
        File(p.join(root.path, 'note1.md')).writeAsStringSync('hello');
        await indexer.fullScan(root.path);
        final stamp = File(p.join(root.path, 'note1.md')).statSync().modified;

        File(p.join(root.path, 'note1.md')).writeAsStringSync('hullo');
        // Pin the mtime: (size, mtime) now prove nothing changed to the
        // shortcut, whatever the wall clock says.
        await File(p.join(root.path, 'note1.md')).setLastModified(stamp);
        await indexer.applyEvents(root.path, [p.join(root.path, 'note1.md')]);
        var hit = await db
            .customSelect(
              'SELECT count(*) c FROM notes_fts WHERE notes_fts MATCH ?',
              variables: [const Variable<String>('hullo')],
            )
            .getSingle();
        expect(hit.read<int>('c'), 0); // skipped: still the old content

        await indexer.rescanFiles(root.path, [p.join(root.path, 'note1.md')]);
        hit = await db
            .customSelect(
              'SELECT count(*) c FROM notes_fts WHERE notes_fts MATCH ?',
              variables: [const Variable<String>('hullo')],
            )
            .getSingle();
        expect(hit.read<int>('c'), 1);
        hit = await db
            .customSelect(
              'SELECT count(*) c FROM notes_fts WHERE notes_fts MATCH ?',
              variables: [const Variable<String>('hello')],
            )
            .getSingle();
        expect(hit.read<int>('c'), 0);
      },
    );

    test('a v7-era index (tree without content rows) is rebuilt by one '
        'unchanged rescan', () async {
      // A note with a tag, so the rebuild reproduces tags too.
      File(p.join(root.path, 'note1.md'))
          .writeAsStringSync('---\ntags: [marker]\n---\nhello tagged\n');
      await indexer.fullScan(root.path);
      final beforeFts = await db
          .customSelect('SELECT count(*) c FROM notes_fts')
          .getSingle();
      expect(beforeFts.read<int>('c'), 3); // note1, note2, docs/doc1

      // Simulate the migration case: the tree rows exist (v7 index) but
      // the M3 content rows are gone.
      await db.customStatement('DELETE FROM notes_fts');
      await db.customStatement('DELETE FROM note_tags');
      await db.customStatement('DELETE FROM note_links');
      await db.customStatement('DELETE FROM note_stems');

      // The rescan itself changes nothing on disk.
      await indexer.fullScan(root.path);

      final afterFts = await db
          .customSelect('SELECT count(*) c FROM notes_fts')
          .getSingle();
      expect(afterFts.read<int>('c'), 3);
      // Search actually finds the rebuilt content.
      final hit = await db
          .customSelect(
            'SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?',
            variables: [const Variable<String>('tagged')],
          )
          .get();
      expect(hit.map((r) => r.read<int>('rowid')), isNotEmpty);
      // Stems and tags came back with it.
      expect(
        (await db.select(db.noteStems).get()).map((s) => s.stem),
        containsAll(['note1', 'note2', 'doc1']),
      );
      expect(
        (await db.select(db.noteTags).get()).map((t) => t.tag),
        contains('marker'),
      );
    });

    test('a pre-file-stem index (attachments without stems) is repaired by '
        'one unchanged rescan', () async {
      // An attachment (non-md) — the embed target of `![[pic.png]]`.
      File(p.join(root.path, 'pic.png')).writeAsStringSync('img');
      await indexer.fullScan(root.path);
      expect(
        (await db.select(db.noteStems).get()).map((s) => s.stem),
        contains('pic.png'),
      );

      // Simulate an index built before file stems existed: attachment
      // rows have no stem row, but every content row (FTS) is present.
      await db.customStatement(
        'DELETE FROM note_stems WHERE note_id IN '
        '(SELECT id FROM notes WHERE is_dir = 0 AND '
        "lower(substr(name, -3)) != '.md')",
      );
      expect(
        (await db.select(db.noteStems).get()).map((s) => s.stem),
        isNot(contains('pic.png')),
      );

      // The unchanged rescan must notice the gap (files != stems in the
      // completeness check) and write the missing stems back — this is
      // what makes `![[pic.png]]` embeds resolvable after an upgrade.
      await indexer.fullScan(root.path);

      final pic = (await dao.find('pic.png'))!;
      final stems = await (db.select(
        db.noteStems,
      )..where((s) => s.noteId.equals(pic.id))).get();
      expect(stems.map((s) => s.stem), ['pic.png']);
      expect(stems.single.source, 'file');
    });

    test('an unchanged rescan never rewrites content rows', () async {
      File(p.join(root.path, 'note1.md'))
          .writeAsStringSync('---\ntags: [keep]\n---\nstable\n');
      await indexer.fullScan(root.path);
      final row = (await dao.find('note1.md'))!;

      // Touch with identical content: digest unchanged, so the content
      // rows must stay as they are (same tag rows, same FTS title).
      final stat = File(p.join(root.path, 'note1.md')).statSync();
      await File(p.join(root.path, 'note1.md'))
          .setLastModified(stat.modified.add(const Duration(seconds: 5)));
      await indexer.applyEvents(root.path, [p.join(root.path, 'note1.md')]);

      final tags = await (db.select(
        db.noteTags,
      )..where((t) => t.noteId.equals(row.id))).get();
      expect(tags.map((t) => t.tag), ['keep']);
      expect(await _ftsTitleIs(db, row.id, 'note1'), isTrue);
    });
  });

  group('frontmatter fields (T-M4-02)', () {
    /// The `frontmatter_fields` rows of [path] as `key=value` strings.
    Future<List<String>> fieldsOf(String path) async {
      final row = (await dao.find(path))!;
      final rows = await (db.select(
        db.frontmatterFields,
      )..where((f) => f.noteId.equals(row.id))).get();
      return [for (final f in rows) '${f.key}=${f.value}']..sort();
    }

    test('every key is indexed, known and invented alike', () async {
      File(p.join(root.path, 'note1.md')).writeAsStringSync(
        '---\ntitle: Real Title\ntags: [a]\ndate: 2026-03-01\n'
        'pinned: true\nstatus: draft\nprojects: [alpha, beta]\n---\nbody',
      );
      await indexer.fullScan(root.path);

      expect(await fieldsOf('note1.md'), [
        'date=2026-03-01',
        'pinned=true',
        'projects=alpha',
        'projects=beta',
        'status=draft',
        'tags=a',
        'title=Real Title',
      ]);
    });

    test('the known fields land on the note row itself', () async {
      File(p.join(root.path, 'note1.md')).writeAsStringSync(
        '---\ntitle: Real Title\ndate: 2026-03-01\npinned: true\n---\nbody',
      );
      await indexer.fullScan(root.path);

      final row = (await dao.find('note1.md'))!;
      expect(row.title, 'Real Title');
      expect(row.date, DateTime(2026, 3));
      expect(row.pinned, isTrue);

      // A note without a block keeps them empty — the filename is its
      // display name.
      final plain = (await dao.find('note2.md'))!;
      expect(plain.title, isNull);
      expect(plain.date, isNull);
      expect(plain.pinned, isFalse);
    });

    test('a changed key updates the index in one pass', () async {
      final file = File(p.join(root.path, 'note1.md'))
        ..writeAsStringSync('---\nstatus: draft\npinned: true\n---\nbody');
      await indexer.fullScan(root.path);
      expect(await fieldsOf('note1.md'), ['pinned=true', 'status=draft']);

      file.writeAsStringSync('---\nstatus: done\n---\nbody');
      await indexer.applyEvents(root.path, [file.path]);

      expect(await fieldsOf('note1.md'), ['status=done']);
      final row = (await dao.find('note1.md'))!;
      expect(row.pinned, isFalse, reason: 'the key is gone from the block');
    });

    test('removing the block clears the fields and the row columns', () async {
      final file = File(p.join(root.path, 'note1.md'))
        ..writeAsStringSync('---\ntitle: T\ndate: 2026-03-01\n---\nbody');
      await indexer.fullScan(root.path);
      expect(await fieldsOf('note1.md'), isNotEmpty);

      file.writeAsStringSync('just body now');
      await indexer.applyEvents(root.path, [file.path]);

      expect(await fieldsOf('note1.md'), isEmpty);
      final row = (await dao.find('note1.md'))!;
      expect(row.title, isNull);
      expect(row.date, isNull);
    });

    test('a malformed block indexes no fields, and stops nothing', () async {
      File(p.join(root.path, 'note1.md'))
          .writeAsStringSync('---\ntitle: [unclosed\n---\nbody');
      await indexer.fullScan(root.path);

      expect(await fieldsOf('note1.md'), isEmpty);
      // The rest of the library indexed normally.
      expect(await dao.allRows(), hasLength(5));
    });

    test('a file that is not a note never gets frontmatter', () async {
      // A `todo.txt` with a YAML block at the top is still a todo.txt.
      // rescanFiles read whatever it was handed, so pinning one indexed
      // it as a note and put it in the tree's pinned block (user,
      // 2026-09-09).
      final todo = File(p.join(root.path, 'todo.txt'))
        ..writeAsStringSync('---\npinned: true\n---\ntask\n');
      await indexer.fullScan(root.path);
      await indexer.rescanFiles(root.path, [todo.path]);

      final row = (await dao.find('todo.txt'))!;
      expect(row.pinned, isFalse);
      expect(row.title, isNull);
      expect(await fieldsOf('todo.txt'), isEmpty);
    });

    test('frontmatter recorded against a non-note is cleared', () async {
      // The repair for an index written before that was fixed.
      File(p.join(root.path, 'todo.txt')).writeAsStringSync('task\n');
      await indexer.fullScan(root.path);
      final row = (await dao.find('todo.txt'))!;
      await (db.update(db.notes)..where((t) => t.id.equals(row.id))).write(
        const NotesCompanion(title: Value('Todo'), pinned: Value(true)),
      );
      await db
          .into(db.frontmatterFields)
          .insert(
            FrontmatterFieldsCompanion.insert(
              noteId: row.id,
              key: 'pinned',
              value: 'true',
            ),
          );

      // A scan that changes nothing still has to run the repair.
      await indexer.fullScan(root.path);

      final fixed = (await dao.find('todo.txt'))!;
      expect(fixed.pinned, isFalse);
      expect(fixed.title, isNull);
      expect(await fieldsOf('todo.txt'), isEmpty);
    });

    test('a deleted note takes its field rows with it', () async {
      File(p.join(root.path, 'note1.md'))
          .writeAsStringSync('---\nstatus: draft\n---\nbody');
      await indexer.fullScan(root.path);
      expect(await db.select(db.frontmatterFields).get(), isNotEmpty);

      File(p.join(root.path, 'note1.md')).deleteSync();
      await indexer.applyEvents(root.path, [p.join(root.path, 'note1.md')]);

      expect(await db.select(db.frontmatterFields).get(), isEmpty);
    });
  });

  group('the cost of pairing a batch (#360)', () {
    test(
      'a folder of 300 notes moved in one batch pairs at a linear cost',
      () async {
        const notes = 300;
        final src = Directory(p.join(root.path, 'src'))..createSync();
        for (var i = 0; i < notes; i++) {
          File(p.join(src.path, 'n$i.md')).writeAsStringSync('body number $i');
        }
        await indexer.fullScan(root.path);
        final ids = <String, int>{
          for (final row in await dao.allRows())
            if (!row.isDir) row.path: row.id,
        };
        expect(ids.length, notes + 3); // note1, note2, docs/doc1

        // A folder move as the watcher reports it: every old path gone,
        // every new one live, in one batch.
        Directory(p.join(root.path, 'src'))
            .renameSync(p.join(root.path, 'moved'));
        final batch = [
          p.join(root.path, 'src'),
          for (final rel in ids.keys) p.join(root.path, rel),
          p.join(root.path, 'moved'),
          for (var i = 0; i < notes; i++) p.join(root.path, 'moved', 'n$i.md'),
        ];

        counter.reset();
        await indexer.applyEvents(root.path, batch);
        final selects = counter.selects.length;

        // The pairing is unchanged: every note kept its row id, and the
        // old paths are gone.
        for (var i = 0; i < notes; i++) {
          final after = (await dao.find('moved/n$i.md'))!;
          expect(after.id, ids['src/n$i.md']);
          expect(after.parent, (await dao.find('moved'))!.id);
        }
        expect(await dao.find('src'), isNull);
        expect(await dao.find('src/n0.md'), isNull);
        expect(await dao.find('moved/n$notes.md'), isNull);

        // The pairing's own cost: one lookup of the batch's vanished rows,
        // not one `SELECT … WHERE path = ?` per (live × gone) pair, which
        // for this batch is 300 × 301 ≈ 90 000 statements.
        expect(
          selects,
          lessThan(10 * notes),
          reason:
              '$selects SELECT statements for a $notes-note move: the '
              'pairing must cost the batch, not the product',
        );
      },
    );

    test('a candidate set is read across the statement chunking', () async {
      await indexer.fullScan(root.path);
      // More paths than one statement may bind, with the rows the index
      // holds last: they are only found if every chunk is queried.
      final wanted = [
        for (var i = 0; i < 1200; i++) 'missing/n$i.md',
        'note1.md',
        'docs/doc1.md',
      ];
      final rows = await dao.byPaths(wanted);
      expect(rows.keys.toSet(), {'note1.md', 'docs/doc1.md'});
    });
  });
}

/// Counts the statements the index issues, so a test can hold a batch to a
/// cost linear in its size rather than quadratic in it (#360).
final class _QueryCounter extends QueryInterceptor {
  final selects = <String>[];

  void reset() => selects.clear();

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects.add(statement);
    return executor.runSelect(statement, args);
  }
}

/// Whether the full-text row of note [id] has [title] for its title: the
/// table keeps no text to read back, so the question is asked of its index.
Future<bool> _ftsTitleIs(IndexDatabase db, int id, String title) async {
  final rows = await db
      .customSelect(
        'SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?1 AND rowid = ?2',
        variables: [Variable<String>('title : "$title"'), Variable<int>(id)],
      )
      .get();
  return rows.isNotEmpty;
}

/// How many full-text rows match [term] in the title column — the word search
/// a stale title would be found by.
Future<int> _titleHits(IndexDatabase db, String term) async {
  final rows = await db
      .customSelect(
        'SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?1',
        variables: [Variable<String>('title : "$term"')],
      )
      .get();
  return rows.length;
}

/// The index state a rebuild reproduces: per-note content rows.
Future<Map<String, List<String>>> _indexState(
  IndexDatabase db,
  NoteDao dao,
) async {
  final notes = await dao.allRows();
  final state = <String, List<String>>{};
  for (final note in notes.where((n) => !n.isDir)) {
    // The full-text row keeps no text to compare (it is contentless): that
    // it is there, and the title the row says the note has.
    final fts = await db
        .customSelect(
          'SELECT count(*) c FROM notes_fts WHERE rowid = ?',
          variables: [Variable<int>(note.id)],
        )
        .getSingle();
    final tags = await (db.select(
      db.noteTags,
    )..where((t) => t.noteId.equals(note.id))).get();
    final links = await (db.select(
      db.noteLinks,
    )..where((l) => l.fromNote.equals(note.id))).get();
    final stems = await (db.select(
      db.noteStems,
    )..where((s) => s.noteId.equals(note.id))).get();
    state[note.path] = [
      'fts:${fts.read<int>('c')}',
      'title:${note.title}',
      ...tags.map((t) => '${t.tag}:${t.isFrontmatter}'),
      ...links.map((l) => '${l.toNote}:${l.kind}'),
      ...stems.map((s) => '${s.stem}:${s.source}'),
    ]..sort();
  }
  return state;
}
