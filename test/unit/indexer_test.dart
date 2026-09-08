import 'dart:io';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/db/dao.dart';
import 'package:copist/src/db/database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/links/resolver.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late CopistDatabase db;
  late Indexer indexer;
  late NoteDao dao;

  setUp(() async {
    root = await Directory.current.createTemp('copist_index_');
    db = CopistDatabase(NativeDatabase.memory());
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

  test('a scan landing mid-write never indexes the atomic temp file', () async {
    // The temp file as it exists between the write and the rename.
    final target = File(p.join(root.path, 'inflight.md'));
    atomicTempPath(target, 42).writeAsStringSync('partial');

    await indexer.fullScan(root.path);

    final names = (await dao.allRows()).map((n) => n.path).toList();
    expect(names.where((name) => name.contains('copist-tmp')), isEmpty);
    expect(names, isNot(contains('inflight.md')));
  });

  test('a fresh index reproduces the identical tree (rebuildable)', () async {
    await indexer.fullScan(root.path);
    final first = await dao.allRows();

    final db2 = CopistDatabase(NativeDatabase.memory());
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
      final outside = await Directory.current.createTemp('copist_outside_');
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
            'SELECT rowid, title FROM notes_fts WHERE notes_fts MATCH ?',
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

    test(
      'delete db → a fresh rescan reproduces FTS, tags, links, stems',
      () async {
        File(p.join(root.path, 'other.md')).writeAsStringSync('## Other\n');
        File(p.join(root.path, 'source.md'))
            .writeAsStringSync('---\ntags: [x]\n---\nlink [[other]]\n');
        await indexer.fullScan(root.path);
        final before = await _indexState(db, dao);

        final db2 = CopistDatabase(NativeDatabase.memory());
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
      final ftsBefore = await db
          .customSelect(
            'SELECT title FROM notes_fts WHERE rowid = ?',
            variables: [Variable<int>(before.id)],
          )
          .getSingle();
      expect(ftsBefore.read<String>('title'), 'Renamable');

      File(p.join(root.path, 'note1.md'))
          .renameSync(p.join(root.path, 'renamed.md'));
      await indexer.applyEvents(root.path, [
        p.join(root.path, 'renamed.md'),
        p.join(root.path, 'note1.md'),
      ]);

      final after = (await dao.find('renamed.md'))!;
      expect(after.id, before.id); // the rename kept the row id
      final ftsAfter = await db
          .customSelect(
            'SELECT title FROM notes_fts WHERE rowid = ?',
            variables: [Variable<int>(after.id)],
          )
          .getSingle();
      expect(ftsAfter.read<String>('title'), 'Renamable');
      // And the old stem is gone, the new one present.
      final stems = await db.select(db.noteStems).get();
      expect(stems.map((s) => s.stem).toSet(), containsAll(['renamed']));
      expect(stems.map((s) => s.stem), isNot(contains('note1')));
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
      final title = await db
          .customSelect(
            'SELECT title FROM notes_fts WHERE rowid = ?',
            variables: [Variable<int>(row.id)],
          )
          .getSingle();
      expect(title.read<String>('title'), 'note1');
    });
  });
}

/// The index state a rebuild reproduces: per-note content rows.
Future<Map<String, List<String>>> _indexState(
  CopistDatabase db,
  NoteDao dao,
) async {
  final notes = await dao.allRows();
  final state = <String, List<String>>{};
  for (final note in notes.where((n) => !n.isDir)) {
    final fts = await db
        .customSelect(
          'SELECT title FROM notes_fts WHERE rowid = ?',
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
      fts.read<String>('title'),
      ...tags.map((t) => '${t.tag}:${t.isFrontmatter}'),
      ...links.map((l) => '${l.toNote}:${l.kind}'),
      ...stems.map((s) => '${s.stem}:${s.source}'),
    ]..sort();
  }
  return state;
}
