// The packs committed under `test/fixtures/dictionary/` are what
// `fixture_packs.dart` writes: edit the data there, write the packs again,
// and commit both.
//
// Every file is compared byte for byte, but the `.dict.dz`: what zlib
// compresses to depends on the build of it (SIMD paths differ by CPU), so its
// inflated data is compared, which also checks the gzip trailer's CRC.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'fixture_packs.dart';

void main() {
  test('the committed fixture packs are what the helper writes', () async {
    final root = Directory.systemTemp.createTempSync('niman_fixture');
    addTearDown(() => root.deleteSync(recursive: true));
    final written = await writeFixturePacks(root.path);
    for (final directory in written) {
      final id = p.basename(directory);
      final committed = Directory(p.join(fixturePacksDirectory, id));
      expect(committed.existsSync(), isTrue, reason: '$id is not committed');
      final names = [
        for (final file in Directory(directory).listSync())
          p.basename(file.path),
      ]..sort();
      final committedNames = [
        for (final file in committed.listSync()) p.basename(file.path),
      ]..sort();
      expect(committedNames, names, reason: id);
      for (final name in names) {
        var expected = File(p.join(directory, name)).readAsBytesSync();
        var actual = File(p.join(committed.path, name)).readAsBytesSync();
        if (name.endsWith('.dict.dz')) {
          expected = Uint8List.fromList(gzip.decode(expected));
          actual = Uint8List.fromList(gzip.decode(actual));
        }
        expect(actual, expected, reason: '$id/$name');
      }
    }
  });
}
