// #535: the opening lines the Home's journal tile shows.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/home/note_preview.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_preview_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  void write(String name, String text) =>
      File(p.join(root.path, name)).writeAsStringSync(text);

  test('leaves out the frontmatter and a leading heading', () async {
    write(
      'a.md',
      '---\ndate: 2026-10-09\n---\n\n# Thursday\n\nWoke up.\nCoffee.',
    );
    expect(await notePreview(root.path, 'a.md'), 'Woke up.\nCoffee.');
  });

  test('keeps a note with neither as it is', () async {
    write('b.md', 'First line\nsecond');
    expect(await notePreview(root.path, 'b.md'), 'First line\nsecond');
  });

  test('reads only the start, cut at a whole line', () async {
    write('c.md', '${'word ' * 10}\n${'x' * 5000}');
    expect(
      await notePreview(root.path, 'c.md', bytes: 100),
      ('word ' * 10).trim(),
    );
  });

  test('is empty for a note that is not there', () async {
    expect(await notePreview(root.path, 'missing.md'), '');
  });
}
