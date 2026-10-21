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
    // after it: cancelled there, the reader is killed with two notes to go.
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
}
