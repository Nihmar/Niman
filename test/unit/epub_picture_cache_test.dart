// The cache a book's pictures are extracted to (#1311): a picture is whole
// under its name or not there, the folders of the books are kept within a
// bound, the least recently used going first and the book in use never.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_picture_cache.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

const List<int> _png = [0x89, 0x50, 0x4E, 0x47, 1, 2, 3, 4, 5, 6];

void main() {
  late Directory dir;
  late String cache;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_epub_cache_');
    cache = p.join(dir.path, 'epub');
    Directory(cache).createSync();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// A book folder of [bytes] bytes, last used [ago] before [now].
  String folder(String name, int bytes, Duration ago, DateTime now) {
    final path = p.join(cache, name);
    Directory(path).createSync();
    File(p.join(path, '0.png')).writeAsBytesSync(List.filled(bytes, 1));
    File(p.join(path, '.used'))
      ..writeAsBytesSync(const [])
      ..setLastModifiedSync(now.subtract(ago));
    return path;
  }

  List<String> left() =>
      Directory(cache).listSync().map((e) => p.basename(e.path)).toList()
        ..sort();

  File book() => writeTestEpub(
    p.join(dir.path, 'pic.epub'),
    title: 'Pic',
    chapters: const [
      (path: 'ch1.xhtml', body: '<p><img src="pic.png" alt="P"/></p>'),
    ],
    files: {'OEBPS/pic.png': _png},
  );

  group('pruning the cache', () {
    test('the least recently used folders past the size go', () {
      final now = DateTime.now();
      for (var i = 0; i < 5; i++) {
        folder('b$i', 10, Duration(hours: 5 - i), now);
      }
      // b0 is the oldest, b4 the newest; 50 bytes held, 25 allowed.
      pruneEpubCache(cache, keep: p.join(cache, 'b4'), maxBytes: 25);
      expect(left(), ['b3', 'b4']);
    });

    test('the folder in use stays, though it is the oldest', () {
      final now = DateTime.now();
      for (var i = 0; i < 4; i++) {
        folder('b$i', 10, Duration(hours: 5 - i), now);
      }
      pruneEpubCache(cache, keep: p.join(cache, 'b0'), maxBytes: 20);
      expect(left(), ['b0', 'b3']);
    });

    test('the folders past the count go, oldest first', () {
      final now = DateTime.now();
      for (var i = 0; i < 6; i++) {
        folder('b$i', 1, Duration(hours: 6 - i), now);
      }
      pruneEpubCache(cache, keep: p.join(cache, 'b5'), maxFolders: 4);
      expect(left(), ['b2', 'b3', 'b4', 'b5']);
    });

    test('a cache within its bound is left whole; a missing one is fine', () {
      final now = DateTime.now();
      folder('a', 10, const Duration(hours: 2), now);
      folder('b', 10, const Duration(hours: 1), now);
      pruneEpubCache(cache, keep: p.join(cache, 'b'));
      expect(left(), ['a', 'b']);
      pruneEpubCache(p.join(dir.path, 'none'), keep: 'x');
    });

    test('a folder with no marker is as old as its own time', () {
      final now = DateTime.now();
      folder('marked', 10, const Duration(hours: 1), now);
      final bare = p.join(cache, 'bare');
      Directory(bare).createSync();
      File(p.join(bare, '0.png')).writeAsBytesSync(List.filled(10, 1));
      // Its folder was last changed just now: the marked one is older.
      pruneEpubCache(cache, keep: p.join(cache, 'x'), maxBytes: 10);
      expect(left(), ['bare']);
    });
  });

  group('opening a book', () {
    test('a book opened again is the folder used most recently', () async {
      final file = book();
      final mine = pictureDirOf(file.path, cache);
      final now = DateTime.now();
      folder('other', 10, const Duration(hours: 1), now);
      await openEpub(file.path, cache);
      final marker = File(p.join(mine, '.used'))
        ..setLastModifiedSync(now.subtract(const Duration(days: 3)));
      // A book read again marks its folder: it outlives the one used since.
      readEpub(file.path, mine);
      expect(
        marker.statSync().modified.isAfter(
          now.subtract(const Duration(days: 1)),
        ),
        isTrue,
      );
      pruneEpubCache(cache, keep: p.join(cache, 'x'), maxFolders: 1);
      expect(left(), [p.basename(mine)]);
    });

    test('it prunes the cache past its count, its own folder kept', () async {
      final file = book();
      final now = DateTime.now();
      for (var i = 0; i < epubCacheMaxFolders + 5; i++) {
        folder('old$i', 1, Duration(days: 10 + i), now);
      }
      final document = await openEpub(file.path, cache);
      expect(left(), hasLength(epubCacheMaxFolders));
      expect(left(), contains(p.basename(pictureDirOf(file.path, cache))));
      expect(left(), isNot(contains('old${epubCacheMaxFolders + 4}')));
      expect(File(document.pictures.values.single).readAsBytesSync(), _png);
    });
  });

  group('a picture is whole under its name', () {
    test('a temp file left by a crash is not taken for the picture', () {
      final file = book();
      final mine = pictureDirOf(file.path, cache);
      Directory(mine).createSync(recursive: true);
      final half = atomicTempPath(File(p.join(mine, '0.png')), 1)
        ..writeAsBytesSync(_png.sublist(0, 3));
      final document = readEpub(file.path, mine);
      final picture = File(document.pictures.values.single);
      expect(p.basename(picture.path), '0.png');
      expect(picture.readAsBytesSync(), _png);
      // Not old enough to be a dead write's: it may be another pane's.
      expect(half.existsSync(), isTrue);
    });

    test('a stale temp file of a dead write is removed', () {
      final file = book();
      final mine = pictureDirOf(file.path, cache);
      Directory(mine).createSync(recursive: true);
      final stale = atomicTempPath(File(p.join(mine, '0.png')), 1)
        ..writeAsBytesSync(_png.sublist(0, 3))
        ..setLastModifiedSync(DateTime.now().subtract(staleTempMinimumAge * 2));
      readEpub(file.path, mine);
      expect(stale.existsSync(), isFalse);
    });

    test('writing leaves no temp file, and a picture found is kept', () {
      final target = File(p.join(dir.path, '0.png'));
      writePictureWhole(target, _png);
      expect(target.readAsBytesSync(), _png);
      expect(
        dir.listSync().map((e) => p.basename(e.path)).where(isTempFileName),
        isEmpty,
      );
    });
  });
}
