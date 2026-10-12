// A file a view holds open is renamed, moved and deleted all the same
// (#833): the ops let every view of it go first, then hand it back.
//
// The hold here is what the PDF view's is, an open handle on the file.
// On Windows the handle alone fails the old order (errno 32, a sharing
// violation); elsewhere the release would simply never be asked for, so
// the test checks the order itself: the file is still where it was when
// the view lets go, and already moved when the view takes it back.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/file_holds.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late Indexer indexer;
  late FileHolds holds;
  late NoteOps ops;

  setUp(() async {
    root = await Directory.current.createTemp('niman_holds_');
    dbDir = await Directory.current.createTemp('niman_holds_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    indexer = Indexer(db);
    holds = FileHolds();
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
      holds: holds,
    );
    Directory(p.join(root.path, 'Attachments')).createSync();
    Directory(p.join(root.path, 'Elsewhere')).createSync();
    File(p.join(root.path, 'Attachments', 'paper.pdf')).writeAsBytesSync([1]);
    await indexer.fullScan(root.path);
  });

  tearDown(() async {
    await ops.writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  /// Holds the file at [rel] open as a view does, recording where the
  /// file was at each step.
  Future<List<String>> holdOpen(String rel) async {
    final file = File(p.join(root.path, rel));
    RandomAccessFile? handle = await file.open();
    final events = <String>[];
    holds.hold(
      file.path,
      release: () async {
        events.add('release, there: ${file.existsSync()}');
        await handle?.close();
        handle = null;
      },
      resume: () {
        events.add('resume, there: ${file.existsSync()}');
        if (file.existsSync()) handle = file.openSync();
      },
    );
    addTearDown(() => handle?.close());
    return events;
  }

  test('a file held open is deleted', () async {
    final events = await holdOpen(p.join('Attachments', 'paper.pdf'));

    await ops.delete('Attachments/paper.pdf');

    expect(events, ['release, there: true', 'resume, there: false']);
    expect(
      (await ops.trashItems()).single.originalPath,
      'Attachments/paper.pdf',
    );
  });

  test('a file held open is renamed and moved', () async {
    final events = await holdOpen(p.join('Attachments', 'paper.pdf'));

    final renamed = await ops.rename('Attachments/paper.pdf', 'article');
    expect(renamed.path, 'Attachments/article.pdf');
    expect(events, ['release, there: true', 'resume, there: false']);

    final held = await holdOpen(p.join('Attachments', 'article.pdf'));
    final moved = await ops.move(renamed.path, 'Elsewhere');
    expect(moved.path, 'Elsewhere/article.pdf');
    expect(held, ['release, there: true', 'resume, there: false']);
  });

  test('a folder with a file held open is renamed and deleted', () async {
    final events = await holdOpen(p.join('Attachments', 'paper.pdf'));

    await ops.rename('Attachments', 'Files');
    expect(events, ['release, there: true', 'resume, there: false']);
    expect(File(p.join(root.path, 'Files', 'paper.pdf')).existsSync(), isTrue);

    final held = await holdOpen(p.join('Files', 'paper.pdf'));
    await ops.delete('Files');
    expect(held, ['release, there: true', 'resume, there: false']);
  });

  test('an operation that fails hands the file back where it was', () async {
    final events = await holdOpen(p.join('Attachments', 'paper.pdf'));

    await expectLater(
      ops.move('Attachments', 'Attachments'),
      throwsArgumentError,
    );
    expect(events, ['release, there: true', 'resume, there: true']);
  });

  test('a file nobody holds is not waited for', () async {
    final events = await holdOpen(p.join('Attachments', 'paper.pdf'));
    File(p.join(root.path, 'Elsewhere', 'note.md')).writeAsStringSync('x');
    await indexer.fullScan(root.path);

    await ops.delete('Elsewhere/note.md');
    expect(events, isEmpty);
  });
}
