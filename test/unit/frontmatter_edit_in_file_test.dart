// A frontmatter key set or removed on disk, reading the file's head and
// nothing past it (2026-09-24: unpinning the 247 MB note ran a phone out of
// memory). The file it writes is the one the whole-text edit writes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/frontmatter/edit.dart';
import 'package:niman/src/frontmatter/edit_in_file.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('niman-fm-edit'));
  tearDown(() => dir.deleteSync(recursive: true));

  // Past one read of the head, with a character of more than one byte
  // across the boundary: the body is copied as bytes, never decoded.
  final long = '${'è' * 40000}\n${'x' * 70000}';

  final notes = <String, String>{
    'no block': '# Title\n\nbody\n',
    'no block, blank on top': '\n\n  # Title\nbody',
    'a block': '---\ntitle: A\n---\n\n# A\n',
    'pinned, the only key': '---\npinned: true\n---\n\nbody\n',
    'pinned, no blank after': '---\npinned: true\n---\nbody\n',
    'pinned among others': '---\ntitle: A\npinned: true\ntags: [a]\n---\nb\n',
    'CRLF': '---\r\ntitle: A\r\n---\r\n\r\nbody\r\n',
    'closed by dots': '---\ntitle: A\n...\nbody\n',
    'never closed': '---\ntitle: A\nbody\n',
    'a long body': '---\ntitle: A\n---\n\n$long',
    'no block, a long body': long,
    'only a block': '---\npinned: true\n---',
  };

  for (final MapEntry(key: name, value: text) in notes.entries) {
    for (final pin in [true, false]) {
      test('$name, ${pin ? 'pinned' : 'unpinned'}', () async {
        final file = File(p.join(dir.path, 'note.md'))..writeAsStringSync(text);
        final changed = await editFrontmatterKeyInFile(
          file.path,
          'pinned',
          pin ? 'true' : null,
        );
        final whole = pin
            ? setFrontmatterKey(text, 'pinned', 'true')
            : removeFrontmatterKey(text, 'pinned');
        expect(file.readAsStringSync(), whole);
        expect(changed, whole != text);
        // Nothing left beside it.
        expect(dir.listSync(), hasLength(1));
      });
    }
  }

  test('a byte-order mark stays where it was', () async {
    final file = File(p.join(dir.path, 'bom.md'))
      ..writeAsBytesSync([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('---\ntitle: A\n---\nbody\n'),
      ]);
    await editFrontmatterKeyInFile(file.path, 'pinned', 'true');
    final bytes = file.readAsBytesSync();
    expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    expect(
      utf8.decode(bytes.sublist(3)),
      '---\ntitle: A\npinned: true\n---\nbody\n',
    );
  });

  test('a block that does not end in its first 4 MB is refused', () async {
    final file = File(p.join(dir.path, 'open.md'))
      ..writeAsStringSync('---\n${'key: value\n' * 500000}');
    final before = file.lengthSync();
    await expectLater(
      editFrontmatterKeyInFile(file.path, 'pinned', 'true'),
      throwsStateError,
    );
    expect(file.lengthSync(), before, reason: 'the note is left alone');
  });
}
