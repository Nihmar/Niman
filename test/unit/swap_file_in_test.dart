// Issue #103: the attachment swap, on the calling isolate. It is what a
// sync download lands with, so what matters is that it puts the right
// bytes in place, reports correctly whether the file is new, and never
// leaves the temp behind — including when the rename cannot happen.
// Issue #369: the copy that stands in for the hung rename lands on a temp
// of its own, so the live path never holds half a file either.
import 'dart:io';
import 'dart:typed_data';

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

  /// The sizes [target] is seen at while [copy] runs: one before it starts,
  /// one polled from the event loop until it returns, one after — so both
  /// ends of the range are caught however the poll and the copy interleave.
  ///
  /// A missing file counts as -1: a write that has not landed yet is not a
  /// size, and calling it zero would let a truncated write pass for one.
  Future<List<int>> sizesWhileCopying(String target, Future<void> copy) async {
    int size() {
      final stat = FileStat.statSync(target);
      return stat.type == FileSystemEntityType.notFound ? -1 : stat.size;
    }

    final seen = <int>[size()];
    var copying = true;
    final poller = Future<void>(() async {
      while (copying) {
        seen.add(size());
        await Future<void>.delayed(Duration.zero);
      }
    });
    final copySettled = copy.then((_) {}, onError: (Object _) {});
    await copySettled;
    copying = false;
    await poller;
    seen.add(size());
    return seen;
  }

  group('the copy that stands in for a rename that hangs (issue #103)', () {
    test('puts the bytes in place and takes the temp with it', () async {
      final target = p.join(root.path, 'clip.wav');
      final source = await temp('.clip.wav.niman-tmp-copy-1', 'audio bytes');

      await copyFileOver(target, source);

      expect(File(target).readAsStringSync(), 'audio bytes');
      expect(File(source).existsSync(), isFalse);
    });

    test('overwrites an existing file', () async {
      final target = p.join(root.path, 'clip.wav');
      await File(target).writeAsString('old');
      final source = await temp('.clip.wav.niman-tmp-copy-2', 'new');

      await copyFileOver(target, source);

      expect(File(target).readAsStringSync(), 'new');
    });

    test(
      'a temp that is gone fails instead of writing an empty file',
      () async {
        final target = p.join(root.path, 'clip.wav');
        final source = p.join(root.path, '.clip.wav.niman-tmp-copy-3');

        await expectLater(
          copyFileOver(target, source),
          throwsA(isA<FileSystemException>()),
        );

        expect(File(target).existsSync(), isFalse);
      },
    );

    // Issue #369: the copy used to land on the target itself, so the live
    // file was the half-written one. It now goes to a temp of its own next
    // to the target and is renamed on, which is what these three watch.
    test(
      'the live file only ever holds the old bytes or all of the new ones',
      () async {
        final target = p.join(root.path, 'clip.wav');
        const oldSize = 1 << 20;
        const newSize = 32 << 20;
        await File(target).writeAsBytes(Uint8List(oldSize));
        final source = p.join(root.path, '.clip.wav.niman-tmp-copy-4');
        await File(source)
            .writeAsBytes(Uint8List(newSize)..fillRange(0, newSize, 0x62));

        final seen = await sizesWhileCopying(
          target,
          copyFileOver(target, source),
        );

        expect(
          seen.where((size) => size != oldSize && size != newSize),
          isEmpty,
          reason: 'a half copy under the real name is what #369 is: $seen',
        );
        expect(seen, contains(oldSize), reason: 'the poll sees the old file');
        expect(seen, contains(newSize), reason: 'and the copy land');
        expect(
          seen.length,
          greaterThan(20),
          reason: 'the poll has to have run while the copy did',
        );
      },
    );

    test('a target that is not there yet only appears whole', () async {
      final target = p.join(root.path, 'clip.wav');
      const newSize = 32 << 20;
      final source = p.join(root.path, '.clip.wav.niman-tmp-copy-5');
      await File(source)
          .writeAsBytes(Uint8List(newSize)..fillRange(0, newSize, 0x62));

      final seen = await sizesWhileCopying(
        target,
        copyFileOver(target, source),
      );

      expect(
        seen.where((size) => size != -1 && size != newSize),
        isEmpty,
        reason:
            'a truncated attachment under its real name is what #369 is: '
            '$seen',
      );
      expect(seen, contains(-1));
      expect(seen, contains(newSize));
    });

    test('a copy that fails leaves the live file exactly as it was', () async {
      final target = p.join(root.path, 'clip.wav');
      final before = Uint8List(1 << 16)..fillRange(0, 1 << 16, 0x61);
      await File(target).writeAsBytes(before);
      // Nothing at that path: the source is what is most likely to be gone —
      // a download the run never finished, or a temp a crash left behind.
      final source = p.join(root.path, '.clip.wav.niman-tmp-copy-6');

      await expectLater(
        copyFileOver(target, source),
        throwsA(isA<FileSystemException>()),
      );

      expect(File(target).readAsBytesSync(), before);
      expect(
        Directory(root.path).listSync().map((entry) => p.basename(entry.path)),
        [p.basename(target)],
        reason: 'no half copy is left lying next to the file either',
      );
    });
  });

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
