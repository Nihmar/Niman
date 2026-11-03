// The attachments folder: T-M2-09's image import — a content-addressed copy
// into the library that the preview resolves (relative link under the
// library root) — and the bytes a web capture downloads (#531).
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/attachment_store.dart';
import 'package:path/path.dart' as p;

void main() {
  test('copies into <library>/assets/ with a content-addressed name', () async {
    final dir = await Directory.systemTemp.createTemp('niman_img_');
    final source = File(p.join(dir.path, 'photo.png'));
    final bytes = List<int>.generate(64, (i) => i * 7 % 256);
    await source.writeAsBytes(bytes);

    final relative = await importImageToLibrary(
      libraryRoot: dir.path,
      sourcePath: source.path,
    );

    final digest = sha256.convert(bytes).toString();
    expect(relative, 'assets/$digest.png');
    final copied = File(p.join(dir.path, relative));
    expect(copied.existsSync(), isTrue);
    expect(await copied.readAsBytes(), bytes);

    // The same image again: same path, single file, no duplicate.
    final again = await importImageToLibrary(
      libraryRoot: dir.path,
      sourcePath: source.path,
    );
    expect(again, relative);
    final assets = Directory(p.join(dir.path, 'assets'));
    expect(assets.listSync().length, 1);

    await dir.delete(recursive: true);
  });

  test('different content gets its own file', () async {
    final dir = await Directory.systemTemp.createTemp('niman_img2_');
    final source = File(p.join(dir.path, 'a.png'));
    await source.writeAsBytes(const [1, 2, 3]);
    final other = File(p.join(dir.path, 'b.png'));
    await other.writeAsBytes(const [9, 9, 9]);

    final first = await importImageToLibrary(
      libraryRoot: dir.path,
      sourcePath: source.path,
    );
    final second = await importImageToLibrary(
      libraryRoot: dir.path,
      sourcePath: other.path,
    );
    expect(first, isNot(second));
    expect(File(p.join(dir.path, first)).existsSync(), isTrue);
    expect(File(p.join(dir.path, second)).existsSync(), isTrue);

    await dir.delete(recursive: true);
  });

  test('a configured attachments folder receives the copy', () async {
    final dir = await Directory.systemTemp.createTemp('niman_img3_');
    final source = File(p.join(dir.path, 'a.png'));
    await source.writeAsBytes(const [1, 2, 3]);

    final relative = await importImageToLibrary(
      libraryRoot: dir.path,
      sourcePath: source.path,
      attachmentsFolder: 'Attachments',
    );
    expect(relative.startsWith('Attachments/'), isTrue);
    expect(File(p.join(dir.path, relative)).existsSync(), isTrue);

    await dir.delete(recursive: true);
  });

  test('downloaded bytes land under their hash, once', () async {
    final dir = await Directory.systemTemp.createTemp('niman_bytes_');
    addTearDown(() => dir.delete(recursive: true));
    const bytes = [4, 5, 6];
    final relative = await storeAttachmentBytes(
      libraryRoot: dir.path,
      bytes: bytes,
      extension: '.webp',
      attachmentsFolder: 'files',
    );
    expect(relative, 'files/${sha256.convert(bytes)}.webp');
    expect(File(p.join(dir.path, relative)).readAsBytesSync(), bytes);
    final again = await storeAttachmentBytes(
      libraryRoot: dir.path,
      bytes: bytes,
      extension: '.webp',
      attachmentsFolder: 'files',
    );
    expect(again, relative);
    expect(Directory(p.join(dir.path, 'files')).listSync(), hasLength(1));
  });

  // Windows device log, 2026-11-03: the same picture dropped while its last
  // drop was still copying was copied three times at once, each copy renamed
  // onto the one name, and the rename behind the antivirus' read of the file
  // took 6 s. One at a time, the later ones find the file there.
  test('the same file imported at once is copied once', () async {
    final dir = await Directory.systemTemp.createTemp('niman_img_race_');
    addTearDown(() => dir.delete(recursive: true));
    final source = File(p.join(dir.path, 'shot.png'));
    await source.writeAsBytes(List<int>.generate(4096, (i) => i % 251));
    AppLog.clear();
    addTearDown(AppLog.clear);

    final stored = await Future.wait([
      for (var i = 0; i < 3; i++)
        importImageToLibrary(libraryRoot: dir.path, sourcePath: source.path),
    ]);

    expect(stored.toSet(), hasLength(1));
    final imports = AppLog.lines().where((l) => l.contains('[image] import'));
    expect(imports, hasLength(3));
    expect(
      imports.where((l) => l.contains('already in the library')),
      hasLength(2),
      reason: 'the second and third wait for the first and reuse its file',
    );
    expect(Directory(p.join(dir.path, 'assets')).listSync(), hasLength(1));
  });
}
