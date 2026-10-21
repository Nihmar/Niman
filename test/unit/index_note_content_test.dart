import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_note_content.dart';
import 'package:niman/src/db/read_cancel.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_note_content_');
    for (final name in ['a.md', 'b.md', 'c.md']) {
      File(p.join(root.path, name)).writeAsStringSync('# $name\n\n#tag [[x]]');
    }
  });

  tearDown(() => root.delete(recursive: true));

  test('a batch reads every note', () async {
    final read = await readBatchOnIsolate(
      root.path,
      ['a.md', 'b.md'],
      null,
      const {},
      ReadCancel(),
    );
    expect([for (final c in read) c.rel], ['a.md', 'b.md']);
    expect(read.first.inlineTags, ['tag']);
  });

  test('a cancelled batch stops where it is and answers empty', () async {
    // The reader reports each note before it reads it, and the report of
    // the first reaches this isolate before anything the reader sends
    // after it: cancelled there, the reader stops with notes to go.
    final cancel = ReadCancel();
    final progress = ReceivePort();
    addTearDown(progress.close);
    progress.listen((_) => cancel.cancel());
    final read = await readBatchOnIsolate(
      root.path,
      ['a.md', 'b.md', 'c.md'],
      progress.sendPort,
      const {},
      cancel,
    );
    expect(read, isEmpty);
  });

  test('a batch cancelled before it starts reads nothing', () async {
    final read = await readBatchOnIsolate(
      root.path,
      ['a.md'],
      null,
      const {},
      ReadCancel()..cancel(),
    );
    expect(read, isEmpty);
  });

  // A save of a note replaces its file by a rename and deletes nothing it
  // has not renamed: with the file still open by a killed reader, Windows
  // refuses both.
  Future<void> expectFreeToReplace(String name) async {
    final note = File(p.join(root.path, name));
    File(p.join(root.path, '$name.tmp'))
      ..writeAsStringSync('saved')
      ..renameSync(note.path);
    expect(note.readAsStringSync(), 'saved');
    note.deleteSync();
  }

  test('a batch cancelled while it reads leaves every note free', () async {
    final cancel = ReadCancel();
    final progress = ReceivePort();
    addTearDown(progress.close);
    progress.listen((_) => cancel.cancel());
    final read = await readBatchOnIsolate(
      root.path,
      ['a.md', 'b.md', 'c.md'],
      progress.sendPort,
      const {},
      cancel,
    );
    expect(read, isEmpty);
    await cancel.released;
    for (final name in ['a.md', 'b.md', 'c.md']) {
      await expectFreeToReplace(name);
    }
  });

  test('a batch cancelled while it parses is killed holding no file', () async {
    // Two notes of a megabyte: a parse long enough to be cut, and the
    // cancel lands at its first instant, which is where the reader says it
    // holds no file.
    final big = '# big\n\n${'word #tag [[x]] ' * 70000}';
    for (final name in ['a.md', 'b.md']) {
      File(p.join(root.path, name)).writeAsStringSync(big);
    }
    final cancel = ReadCancel();
    var parsing = 0;
    cancel.onParsing = () {
      parsing++;
      cancel.cancel();
    };
    final read = await readBatchOnIsolate(
      root.path,
      ['a.md', 'b.md'],
      null,
      const {},
      cancel,
    );
    expect(read, isEmpty);
    expect(parsing, 1);
    await cancel.released;
    for (final name in ['a.md', 'b.md']) {
      await expectFreeToReplace(name);
    }
  });

  test('released completes at once when no read holds a file', () async {
    final cancel = ReadCancel();
    await cancel.released;
    await readBatchOnIsolate(root.path, ['a.md'], null, const {}, cancel);
    await cancel.released;
  });

  test('released waits for a read that holds a file', () async {
    final cancel = ReadCancel();
    final release = cancel.holdFiles();
    var released = false;
    unawaited(cancel.released.then((_) => released = true));
    cancel.cancel();
    await pumpEventQueue();
    expect(released, isFalse);
    release();
    release(); // a second call does nothing
    await pumpEventQueue();
    expect(released, isTrue);
  });
}
