// The streaming save (docs/dev/huge-notes.md): a note handed to the writer
// in slices, never joined, lands on disk exactly as the joined path leaves
// it.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:path/path.dart' as p;

/// [text] handed over a few lines at a time.
NoteContentProducer producerOf(String text, {int linesPerSlice = 2}) {
  final lines = text.split('\n');
  return (index) async {
    final first = index * linesPerSlice;
    if (first >= lines.length) return null;
    final last = first + linesPerSlice;
    final slice = lines
        .sublist(first, last > lines.length ? lines.length : last)
        .join('\n');
    // A slice but the last carries the newline its lines ended with.
    return Uint8List.fromList(
      utf8.encode(last >= lines.length ? slice : '$slice\n'),
    );
  };
}

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteWriter writer;

  setUp(() async {
    root = await Directory.current.createTemp('niman_stream_');
    dbDir = await Directory.current.createTemp('niman_stream_db_');
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

  test('a note saved in slices is the note on disk', () async {
    const text = '# Title\n\none\ntwo\nthree\nfour\nfive';
    await writer.save('Inbox/Deep/Note.md', producerOf(text));
    expect(read('Inbox/Deep/Note.md'), text);
  });

  test('an empty note still writes a file', () async {
    await writer.save('Empty.md', producerOf(''));
    expect(File(p.join(root.path, 'Empty.md')).existsSync(), isTrue);
    expect(read('Empty.md'), '');
  });

  test('CRLF line endings survive the slices', () async {
    const text = 'a\r\nb\r\nc';
    await writer.save('Crlf.md', producerOf(text, linesPerSlice: 1));
    expect(read('Crlf.md'), text);
  });

  test('a slice that throws leaves the note as it was', () async {
    File(p.join(root.path, 'Kept.md')).writeAsStringSync('before');
    var calls = 0;
    Future<NoteBytes?> failing(int index) async {
      if (calls++ > 0) throw StateError('the buffer went away');
      return Uint8List.fromList(utf8.encode('after'));
    }

    await expectLater(writer.save('Kept.md', failing), throwsA(anything));
    expect(read('Kept.md'), 'before');
    // The temp file the write had opened goes with the failure: the note's
    // folder holds the note and nothing else.
    final names = Directory(root.path)
        .listSync()
        .map((e) => p.basename(e.path));
    expect(names, ['Kept.md']);
  });

  test('the index follows a streamed save', () async {
    const text = '# Indexed\n\nbody words here';
    await writer.save('Indexed.md', producerOf(text));
    await writer.indexed;
    final row = await indexer.dao.find('Indexed.md');
    expect(row, isNotNull);
    expect(row!.size, text.length);
  });

  test('streamed saves of a note land in the order they were made', () async {
    final saves = [
      for (var i = 0; i < 10; i++)
        writer.save('a.md', producerOf('version $i\nsecond line')),
    ];
    await Future.wait(saves);
    expect(read('a.md'), 'version 9\nsecond line');
  });

  test('a producer that never ends is not waited on forever', () async {
    // The producer answers one slice and then never answers again: the
    // save has to stay outstanding (it is the UI isolate's own loop that
    // drives it) rather than resolving with half a note.
    final gate = Completer<NoteBytes?>();
    var first = true;
    Future<NoteBytes?> stalled(int index) {
      if (first) {
        first = false;
        return Future<NoteBytes?>.value(
          Uint8List.fromList(utf8.encode('half')),
        );
      }
      return gate.future;
    }

    final save = writer.save('Stalled.md', stalled);
    var settled = false;
    unawaited(save.then((_) => settled = true));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(settled, isFalse);
    expect(File(p.join(root.path, 'Stalled.md')).existsSync(), isFalse);
    gate.complete(null);
    await save;
    expect(read('Stalled.md'), 'half');
  });
}
