// A stamp is size and modification time, and a modification time is only as
// fine as the file system's clock (#1365): another program that writes the
// same number of bytes within the tick the file was written in leaves the
// same stamp. Within that tick the content vouches for the stamp.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/disk_stamp.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/ui/note_disk.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('niman_stamp_tick'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// A file of [text] last written at [modified].
  File fileAt(String name, String text, DateTime modified) {
    return File(p.join(dir.path, name))
      ..writeAsStringSync(text)
      ..setLastModifiedSync(modified);
  }

  /// A time well ahead of now: any stat of such a file is taken before its
  /// time, so its stamp is ambiguous.
  const ahead = Duration(hours: -1);

  /// A time [ago] before now, to the millisecond, as a fine clock writes it.
  DateTime fine(Duration ago) => DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().subtract(ago).millisecondsSinceEpoch,
  );

  group('whether a stamp is ambiguous', () {
    final modified = DateTime.utc(2026, 11, 27, 10, 0, 0, 417);

    test('a stamp taken within a fine tick of the file time is', () {
      final stamp = DiskStamp(
        size: 3,
        modified: modified,
        taken: modified.add(const Duration(milliseconds: 5)),
      );
      expect(stamp.isAmbiguous, isTrue);
    });

    test('one taken a fine tick or more after is not', () {
      final stamp = DiskStamp(
        size: 3,
        modified: modified,
        taken: modified.add(DiskStamp.fineTick),
      );
      expect(stamp.isAmbiguous, isFalse);
    });

    test('a time with no fraction of a second is a coarse clock: two '
        'seconds', () {
      final whole = DateTime.utc(2026, 11, 27, 10);
      expect(
        DiskStamp(
          size: 3,
          modified: whole,
          taken: whole.add(const Duration(seconds: 1)),
        ).isAmbiguous,
        isTrue,
      );
      expect(
        DiskStamp(
          size: 3,
          modified: whole,
          taken: whole.add(const Duration(seconds: 2)),
        ).isAmbiguous,
        isFalse,
      );
    });

    test('a stamp that does not know when it was taken, and one taken before '
        'the file time, are', () {
      expect(DiskStamp(size: 3, modified: modified).isAmbiguous, isTrue);
      expect(
        DiskStamp(
          size: 3,
          modified: modified,
          taken: modified.subtract(const Duration(seconds: 1)),
        ).isAmbiguous,
        isTrue,
      );
    });
  });

  group('an outside change of the same size and time', () {
    test('is seen when the stamp is ambiguous', () async {
      // A file time in the stat's future (a skewed clock, a time kept by a
      // sync) is always ambiguous: deterministic, where a file written "just
      // now" depends on how fast the test runs.
      final file = fileAt('a.md', 'first', fine(ahead));
      final loaded = loadNoteSync(file.path) as LoadedNote;
      final stamp = loaded.stamp!;
      expect(stamp.isAmbiguous, isTrue);
      expect(stamp.digest, isNotNull);
      expect(await stamp.matchesAsync(file.path), isTrue);

      // Another program: five other bytes, and the time put back.
      final modified = file.lastModifiedSync();
      file
        ..writeAsStringSync('other')
        ..setLastModifiedSync(modified);
      expect(
        DiskStamp.of(file.path)!.sameAs(stamp),
        isTrue,
        reason: 'the stat alone cannot tell',
      );
      expect(await stamp.matchesAsync(file.path), isFalse);
      expect(stamp.matches(file.path), isFalse);
    });

    test('is seen by the note on screen: it is not "unchanged"', () async {
      final file = fileAt('b.md', 'first', fine(ahead));
      final disk = NoteDisk(readNote: () => null);
      final opened = await disk.open(file.path);
      disk.adoptOpened(opened);
      expect(await disk.unchanged(file.path), isTrue);

      final modified = file.lastModifiedSync();
      file
        ..writeAsStringSync('other')
        ..setLastModifiedSync(modified);
      expect(await disk.unchanged(file.path), isFalse);
    });

    test('a stamp that is not ambiguous is not hashed', () async {
      final file = fileAt('c.md', 'first', fine(const Duration(hours: 1)));
      final loaded = loadNoteSync(file.path) as LoadedNote;
      expect(loaded.stamp!.isAmbiguous, isFalse);
      expect(loaded.stamp!.digest, isNull, reason: 'no hash on every open');
      expect(await loaded.stamp!.matchesAsync(file.path), isTrue);
    });

    test('a file of the same size and time with the same bytes is the same '
        'file', () async {
      final file = fileAt('d.md', 'first', fine(ahead));
      final stamp = (loadNoteSync(file.path) as LoadedNote).stamp!;
      final modified = file.lastModifiedSync();
      file
        ..writeAsStringSync('first')
        ..setLastModifiedSync(modified);
      expect(await stamp.matchesAsync(file.path), isTrue);
    });

    test('an ambiguous stamp with no digest vouches for nothing', () async {
      final file = fileAt('e.md', 'first', fine(ahead));
      final stamp = DiskStamp.of(file.path)!;
      expect(stamp.isAmbiguous, isTrue);
      expect(stamp.digest, isNull);
      expect(await stamp.matchesAsync(file.path), isFalse);
    });

    test('the digest is the sha256 of the bytes', () {
      expect(
        DiskStamp.digestOfBytes(const <int>[]),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });
  });
}
