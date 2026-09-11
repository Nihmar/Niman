// T-M2-09: image import — content-addressed copy into the library that the
// preview resolves (relative link under the library root).
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/image_import.dart';
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
}
