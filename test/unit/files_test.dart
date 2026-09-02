import 'dart:convert';
import 'dart:io';

import 'package:copist/src/core/files.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.current.createTemp('copist_files_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('sanitizeName', () {
    test('strips path separators and illegal characters', () {
      expect(
        sanitizeName(r'a/b\c:d*e?f"g<h>i|j', fallback: 'X'),
        'abcdefghij',
      );
    });

    test('collapses whitespace runs and trims', () {
      expect(
        sanitizeName('  lots   of\tspaces\nmore ', fallback: 'X'),
        'lots of spaces more',
      );
    });

    test('caps the name at 200 characters', () {
      expect(sanitizeName('a' * 300, fallback: 'X').length, 200);
    });

    test('falls back when nothing usable remains', () {
      expect(sanitizeName('???', fallback: 'Untitled'), 'Untitled');
      expect(sanitizeName('   ', fallback: 'Untitled'), 'Untitled');
    });

    test('removes trailing dot runs but keeps leading dots', () {
      expect(sanitizeName('notes...', fallback: 'X'), 'notes');
      expect(sanitizeName('.hidden.', fallback: 'X'), '.hidden.');
    });
  });

  group('uniqueFileName', () {
    test('keeps the name when unused', () async {
      expect(await uniqueFileName(tempDir, 'Note', '.md'), 'Note.md');
    });

    test('appends a numeric suffix on collision', () async {
      File(p.join(tempDir.path, 'Note.md')).writeAsStringSync('x');
      expect(await uniqueFileName(tempDir, 'Note', '.md'), 'Note_1.md');
    });

    test('treats the excluded path as free', () async {
      final selfPath = p.join(tempDir.path, 'Note.md');
      File(selfPath).writeAsStringSync('x');
      final name = await uniqueFileName(
        tempDir,
        'Note',
        '.md',
        exclude: selfPath,
      );
      expect(name, 'Note.md');
    });
  });

  group('uniqueFolderName', () {
    test('keeps the name when unused', () async {
      expect(await uniqueFolderName(tempDir, 'Docs'), 'Docs');
    });

    test('appends a numeric suffix on collision', () async {
      Directory(p.join(tempDir.path, 'Docs')).createSync();
      expect(await uniqueFolderName(tempDir, 'Docs'), 'Docs_1');
    });
  });

  group('trash names', () {
    test('plain name when unused', () async {
      expect(await trashFileName(tempDir, 'Note', '.md'), 'Note.md');
    });

    test('timestamped name on collision', () async {
      File(p.join(tempDir.path, 'Note.md')).writeAsStringSync('x');
      final name = await trashFileName(tempDir, 'Note', '.md');
      expect(name, startsWith('Note.'));
      expect(name, endsWith('.md'));
      expect(name.substring(5, name.length - 3), matches(RegExp(r'^\d{10}$')));
    });

    test('directory names are timestamped on collision', () async {
      Directory(p.join(tempDir.path, 'Docs')).createSync();
      final name = await trashDirName(tempDir, 'Docs');
      expect(name, startsWith('Docs.'));
      expect(name, matches(RegExp(r'^Docs\.\d{10}$')));
    });
  });

  group('path helpers', () {
    test('relPath maps an absolute path to its relative form', () {
      expect(relPath('/a/b/c/note.md', '/a/b'), 'c/note.md');
    });

    test('relPath throws for paths outside the root', () {
      expect(() => relPath('/x/note.md', '/y'), throwsArgumentError);
    });

    test('relPath of the root itself is empty', () {
      expect(relPath('/a/b', '/a/b'), '');
    });

    test('parentOf returns the enclosing relative path', () {
      expect(parentOf('a/b/c'), 'a/b');
      expect(parentOf('c'), '');
    });

    test('resolvePath joins parent and name', () {
      expect(resolvePath('a/b', 'c'), 'a/b/c');
      expect(resolvePath('', 'c'), 'c');
    });

    test('joinRel skips empty segments', () {
      expect(joinRel(['a', 'b']), 'a/b');
      expect(joinRel(['', 'a', 'b']), 'a/b');
      expect(joinRel(<String>[]), '');
    });

    test('stripSegments drops leading segments', () {
      expect(stripSegments('a/b/c/note.md', 2), 'c/note.md');
      expect(stripSegments('a/b', 2), '');
    });

    test('isUnder reports direct descendants only', () {
      expect(isUnder('a/b', 'a/b/c'), isTrue);
      expect(isUnder('a/b', 'a/bc'), isFalse);
      expect(isUnder('', 'note.md'), isTrue);
      expect(isUnder('a/b', 'a/b'), isFalse);
    });
  });

  group('splitFileName', () {
    test('splits base and extension', () {
      final parts = splitFileName('a.b.c.md');
      expect(parts.base, 'a.b.c');
      expect(parts.ext, '.md');
    });

    test('names without an extension have an empty ext', () {
      final parts = splitFileName('archive');
      expect(parts.base, 'archive');
      expect(parts.ext, '');
    });

    test('dotfiles keep their dot in the base', () {
      final parts = splitFileName('.hidden');
      expect(parts.base, '.hidden');
      expect(parts.ext, '');
    });
  });

  group('toStoredSecond', () {
    test('truncates to whole seconds (drift storage precision)', () {
      final dt = DateTime(2025, 1, 2, 3, 4, 5, 999, 999);
      final stored = toStoredSecond(dt);
      expect(stored, DateTime(2025, 1, 2, 3, 4, 5));
      expect(stored.microsecondsSinceEpoch % 1000, 0);
    });
  });

  group('writeFileAtomically', () {
    test('writes the bytes and leaves no temp file behind', () async {
      final file = File(p.join(tempDir.path, 'out.bin'));
      await writeFileAtomically(file, <int>[1, 2, 3]);
      expect(file.readAsBytesSync(), <int>[1, 2, 3]);
      expect(
        tempDir.listSync(followLinks: false).map((e) => e.path).toList(),
        <String>[file.path],
      );
    });

    test('fails when the parent directory does not exist', () async {
      final file = File(p.join(tempDir.path, 'no/such/dir/out.bin'));
      expect(
        () => writeFileAtomically(file, <int>[1]),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('hashFileSha256', () {
    test('hashes the content', () async {
      final file = File(p.join(tempDir.path, 'n.md'))
        ..writeAsStringSync('hello world');
      final expected = sha256.convert(utf8.encode('hello world')).toString();
      expect(await hashFileSha256(file), expected);
    });

    test('handles an empty file', () async {
      final file = File(p.join(tempDir.path, 'empty.md'))
        ..writeAsStringSync('');
      expect(
        await hashFileSha256(file),
        sha256.convert(utf8.encode('')).toString(),
      );
    });
  });
}
