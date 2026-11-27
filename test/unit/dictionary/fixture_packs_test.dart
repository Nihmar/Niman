// The packs committed under `test/fixtures/dictionary/` are what
// `fixture_packs.dart` writes, byte for byte: edit the data there, write the
// packs again, and commit both.
import 'dart:io';

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
        expect(
          File(p.join(committed.path, name)).readAsBytesSync(),
          File(p.join(directory, name)).readAsBytesSync(),
          reason: '$id/$name',
        );
      }
    }
  });
}
