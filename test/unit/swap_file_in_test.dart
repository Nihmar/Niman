// Issue #103: the attachment swap, on the calling isolate. It is what a
// sync download lands with, so what matters is that it puts the right
// bytes in place, reports correctly whether the file is new, and never
// leaves the temp behind — including when the rename cannot happen.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('niman_swap_');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  Future<String> temp(String name, String content) async {
    final file = File(p.join(root.path, name));
    await file.writeAsString(content);
    return file.path;
  }

  test('a new file is created and reported as new', () async {
    final target = p.join(root.path, 'Attachments', 'clip.wav');
    final source = await temp('.clip.wav.niman-tmp-sync-1', 'audio');

    final created = await swapFileIn(target, source);

    expect(created, isTrue);
    expect(File(target).readAsStringSync(), 'audio');
    expect(File(source).existsSync(), isFalse, reason: 'the temp is consumed');
  });

  test('an existing file is replaced and reported as not new', () async {
    final target = p.join(root.path, 'clip.wav');
    await File(target).writeAsString('old');
    final source = await temp('.clip.wav.niman-tmp-sync-2', 'new');

    final created = await swapFileIn(target, source);

    expect(created, isFalse);
    expect(File(target).readAsStringSync(), 'new');
  });

  test('missing folders are created on the way', () async {
    final target = p.join(root.path, 'a', 'b', 'c', 'clip.wav');
    final source = await temp('.clip.wav.niman-tmp-sync-3', 'deep');

    await swapFileIn(target, source);

    expect(File(target).readAsStringSync(), 'deep');
  });

  test(
    'a rename that cannot happen throws and takes the temp with it',
    () async {
      final source = await temp('.clip.wav.niman-tmp-sync-4', 'doomed');
      // A directory already sits on the target path, so the rename fails.
      final target = p.join(root.path, 'taken');
      await Directory(target).create();
      await File(p.join(target, 'occupant')).writeAsString('in the way');

      await expectLater(swapFileIn(target, source), throwsA(isA<Object>()));

      expect(
        File(source).existsSync(),
        isFalse,
        reason: 'a failed swap leaves no temp file behind',
      );
    },
  );
}
