import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteWriter writer;

  setUp(() async {
    root = await Directory.current.createTemp('niman_writer_');
    dbDir = await Directory.current.createTemp('niman_writer_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    addTearDown(db.close);
    indexer = Indexer(db);
    writer = NoteWriter(root: root.path, indexer: indexer);
  });

  tearDown(() async {
    await writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  String read(String rel) => File(p.join(root.path, rel)).readAsStringSync();

  test('writes the text and creates missing folders', () async {
    await writer.save('Inbox/Deep/Note.md', 'hello');
    expect(read('Inbox/Deep/Note.md'), 'hello');
  });

  test('overwrites an existing note', () async {
    File(p.join(root.path, 'a.md')).writeAsStringSync('old');
    await writer.save('a.md', 'new', editSession: 3);
    expect(read('a.md'), 'new');
  });

  test('saves of one note land in the order they were made', () async {
    final saves = [
      for (var i = 0; i < 20; i++) writer.save('a.md', 'version $i'),
    ];
    await Future.wait(saves);
    expect(read('a.md'), 'version 19');
  });

  group('tidy', () {
    test('tidies the note as its last save left it', () async {
      await writer.save('a.md', '#  Heading   \n\n\n\ntext  ');
      expect(await writer.tidy('a.md'), isTrue);
      expect(read('a.md'), '# Heading\n\ntext\n');
      expect(await writer.tidy('a.md'), isFalse, reason: 'tidy already');
    });

    test('a save asked for after the tidy is not written over', () async {
      // The tidy of a closed note, and the note opened again and typed in
      // before the tidy lands: the typing is what the note says after.
      await writer.save('a.md', 'one\n\n\n\ntwo');
      final tidy = writer.tidy('a.md');
      final save = writer.save('a.md', 'typed after');
      expect(await tidy, isTrue);
      await save;
      expect(read('a.md'), 'typed after');
    });

    test('a Windows line ending alone is not a reason to rewrite', () async {
      File(p.join(root.path, 'crlf.md')).writeAsStringSync('one\r\ntwo\r\n');
      expect(await writer.tidy('crlf.md'), isFalse);
      expect(read('crlf.md'), 'one\r\ntwo\r\n');
    });

    test('a note past the limit is left as it is', () async {
      final big = '${'word  \n' * (NoteWriter.tidyLimit ~/ 7 + 1)}\n\n';
      File(p.join(root.path, 'big.md')).writeAsStringSync(big);
      expect(await writer.tidy('big.md'), isFalse);
      expect(read('big.md'), big);
    });

    test('a note that is gone is nothing to tidy', () async {
      expect(await writer.tidy('gone.md'), isFalse);
    });
  });

  group('the digest the write made', () {
    // A reindex after a save hashed the note again: 1.9 s of the 247 MB
    // stress note's 10.6 (`docs/dev/huge-notes.md`, item 8), for bytes the
    // write had in hand.
    late NoteWriter waiting;

    setUp(() {
      waiting = NoteWriter(
        root: root.path,
        indexer: indexer,
        quietBeforeReindex: (_) => const Duration(hours: 1),
      );
    });

    Future<String?> indexedSha(String rel) async =>
        (await indexer.dao.find(rel))?.sha256;

    String shaOf(String rel) => sha256
        .convert(File(p.join(root.path, rel)).readAsBytesSync())
        .toString();

    test('is the digest of what was written', () async {
      await waiting.save('a.md', 'first');
      await waiting.indexed;
      await waiting.save('a.md', 'second, and longer');
      await waiting.indexed;
      expect(await indexedSha('a.md'), shaOf('a.md'));
    });

    test('is taken while the file is the one written', () async {
      await waiting.save('a.md', 'first');
      await waiting.indexed;
      await waiting.save('a.md', 'the text');
      // Changed behind the writer's back as no editor would, same length
      // and same time: proof the reindex took the write's digest, not the
      // file's.
      final file = File(p.join(root.path, 'a.md'));
      final time = file.lastModifiedSync();
      file
        ..writeAsStringSync('THE TEXT')
        ..setLastModifiedSync(time);
      await waiting.indexed;
      expect(
        await indexedSha('a.md'),
        sha256.convert(utf8.encode('the text')).toString(),
      );
    });

    Future<List<String>> indexedTags(String rel) async {
      final row = (await indexer.dao.find(rel))!;
      final tags = await (db.select(
        db.noteTags,
      )..where((t) => t.noteId.equals(row.id))).get();
      return [for (final tag in tags) tag.tag];
    }

    test('the tags and links the editor kept are taken with it', () async {
      // Reading them was 5.1 s of the stress note's reindex; the editor has
      // them block by block. A tag the text does not have proves the index
      // took the editor's.
      const kept = NoteReferences(tags: ['from-the-editor'], links: []);
      await waiting.save('a.md', 'first');
      await waiting.indexed;
      await waiting.save('a.md', 'the #text', references: kept);
      await waiting.indexed;
      expect(await indexedTags('a.md'), ['from-the-editor']);

      // Changed on disk since: read from the file.
      await waiting.save('a.md', 'the #text again', references: kept);
      File(p.join(root.path, 'a.md')).writeAsStringSync('now #mine');
      await waiting.indexed;
      expect(await indexedTags('a.md'), ['mine']);
    });

    test('is not taken once the file changed', () async {
      await waiting.save('a.md', 'first');
      await waiting.indexed;
      await waiting.save('a.md', 'the text');
      File(p.join(root.path, 'a.md')).writeAsStringSync('another text');
      await waiting.indexed;
      expect(await indexedSha('a.md'), shaOf('a.md'));
    });
  });

  test('the index follows the save', () async {
    await writer.save('Indexed.md', '# Title\n\nbody words');
    await writer.indexed;
    final row = await indexer.dao.find('Indexed.md');
    expect(row, isNotNull);
    expect(row!.size, '# Title\n\nbody words'.length);
  });

  test('a large note is reindexed once it is left alone', () async {
    // The stress note's reindex was 15 to 34 s a save, one after another
    // while the writer typed. A note past the threshold waits to be quiet.
    final quiet = NoteWriter(
      root: root.path,
      indexer: indexer,
      quietBeforeReindex: (_) => const Duration(milliseconds: 300),
    );
    await quiet.save('Big.md', 'first');
    await quiet.indexed;
    expect((await indexer.dao.find('Big.md'))!.size, 'first'.length);
    for (var i = 0; i < 3; i++) {
      await quiet.save('Big.md', 'second ${'x' * i}');
    }
    expect(
      (await indexer.dao.find('Big.md'))!.size,
      'first'.length,
      reason: 'saved and saved again: not read back yet',
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await quiet.indexed;
    expect((await indexer.dao.find('Big.md'))!.size, 'second xx'.length);
  });

  test('asking for the index runs a reindex that waits to be quiet', () async {
    final quiet = NoteWriter(
      root: root.path,
      indexer: indexer,
      quietBeforeReindex: (_) => const Duration(hours: 1),
    );
    await quiet.save('Big.md', 'first');
    await quiet.save('Big.md', 'the second, longer');
    await quiet.indexed;
    expect(
      (await indexer.dao.find('Big.md'))!.size,
      'the second, longer'.length,
    );
  });

  test('the default waits only for large notes', () {
    expect(NoteWriter.defaultQuietBeforeReindex(1 << 20), Duration.zero);
    expect(
      NoteWriter.defaultQuietBeforeReindex(4 << 20),
      const Duration(seconds: 5),
    );
    expect(
      NoteWriter.defaultQuietBeforeReindex(250 << 20),
      const Duration(seconds: 30),
    );
  });

  test('saves while a reindex runs leave the index on the last one', () async {
    // The reindexes are folded — one running, one more after it — so what
    // matters is that the one after reads what the last save wrote.
    final saves = [
      for (var i = 0; i < 20; i++) writer.save('Busy.md', 'x' * (i + 1)),
    ];
    await Future.wait(saves);
    await writer.indexed;
    expect((await indexer.dao.find('Busy.md'))!.size, 20);
  });

  test('an equal-size edit in the same second still re-indexes', () async {
    await writer.save('Same.md', 'aaaa');
    await writer.indexed;
    final before = (await indexer.dao.find('Same.md'))!.sha256;
    await writer.save('Same.md', 'bbbb');
    await writer.indexed;
    final after = (await indexer.dao.find('Same.md'))!.sha256;
    expect(after, isNot(before));
  });

  test(
    'a failed save reaches the caller and does not block the next',
    () async {
      // A file where the note's folder should be: the write cannot land.
      File(p.join(root.path, 'Blocked')).writeAsStringSync('not a folder');
      await expectLater(writer.save('Blocked/Note.md', 'x'), throwsA(anything));
      await writer.save('Free.md', 'fine');
      expect(read('Free.md'), 'fine');
    },
  );

  test('NoteOps.saveNote writes through the writer', () async {
    final ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    await ops.saveNote('Via ops.md', 'from ops', editSession: 1);
    await ops.writer.indexed;
    expect(read('Via ops.md'), 'from ops');
    expect(await ops.find('Via ops.md'), isNotNull);
  });
}
