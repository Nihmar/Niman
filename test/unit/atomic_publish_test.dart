// The last step of every atomic write (#1058): the temp file is flushed to
// storage before it is renamed over the note. A rename makes the new bytes
// the file for any reader, but not durable: without the flush, a power cut
// after it can bring the note back empty.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:path/path.dart' as p;

import '../fakes/recording_file.dart';

void main() {
  late Directory dir;
  late String target;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_publish');
    target = p.join(dir.path, 'note.md');
    File(target).writeAsStringSync('the good copy');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// The steps of [log] that touch the temp file (a dotfile beside the note),
  /// the temp's name made the same in each.
  List<String> steps(FileLog log) => [
    for (final step in log)
      step.replaceAll(RegExp(r'\.note\.md\.niman-tmp-\d+'), '<temp>'),
  ];

  const flushThenRename = ['flush <temp>', 'rename <temp> -> note.md'];

  test('writeFileAtomically flushes the temp file, then renames it', () async {
    final log = <String>[];
    await recordingFiles(
      log,
      () => writeFileAtomically(File(target), utf8.encode('the new copy')),
    );
    expect(steps(log), flushThenRename);
    expect(File(target).readAsStringSync(), 'the new copy');
    expect(dir.listSync().length, 1, reason: 'no temp file left behind');
  });

  test('the streaming writer flushes the temp file, then renames it', () async {
    final log = <String>[];
    final slices = [utf8.encode('one\n'), utf8.encode('two\n')];
    // The writer runs on this isolate, so the zone's I/O overrides reach it:
    // a spawned isolate never inherits them.
    await recordingFiles(
      log,
      () => saveNoteStream(
        root: dir.path,
        rel: 'note.md',
        produce: (index) async =>
            index < slices.length ? Uint8List.fromList(slices[index]) : null,
        spawnWriter: (spawn) async {
          runNoteStreamWriter(spawn);
          return null;
        },
      ),
    );
    expect(steps(log), flushThenRename);
    expect(File(target).readAsStringSync(), 'one\ntwo\n');
    expect(dir.listSync().length, 1, reason: 'no temp file left behind');
  });

  test('a flush that fails leaves the good copy and no temp file', () async {
    final blocked = Directory(p.join(dir.path, 'folder.md'))..createSync();
    // Renaming a file over a directory fails: the note is not replaced, and
    // the temp file is removed.
    await expectLater(
      writeFileAtomically(File(blocked.path), utf8.encode('x')),
      throwsA(isA<FileSystemException>()),
    );
    expect(blocked.existsSync(), isTrue);
    expect(File(target).readAsStringSync(), 'the good copy');
    expect(dir.listSync().map((e) => p.basename(e.path)).toSet(), {
      'note.md',
      'folder.md',
    });
  });

  test('both writers publish through the one shared helper', () {
    // The helper is the last step of both, so the two cannot drift apart
    // again: the streaming writer once lost the flush the joined path had.
    String source(String file) =>
        File(p.join('lib', 'src', file)).readAsStringSync();
    final stream = source(p.join('library', 'note_write_stream.dart'));
    expect(stream, contains('publishTempFile('));
    expect(stream, isNot(contains('.rename(')), reason: 'no rename of its own');
    final files = source(p.join('core', 'files.dart'));
    final joined = files.substring(
      files.indexOf('Future<void> writeFileAtomically('),
    );
    expect(
      joined.substring(0, joined.indexOf('\n}\n')),
      allOf(contains('publishTempFile('), isNot(contains('.rename('))),
    );
  });
}
