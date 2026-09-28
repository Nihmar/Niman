import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
import 'package:path/path.dart' as p;

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.current.createTemp('niman_files_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('sanitizeName', () {
    test('strips path separators and illegal characters', () {
      expect(sanitizeName(r'a/b\c:d*e?f"g<h>i|j', fallback: 'X'), 'abcdefghij');
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

    test(
      'a second collision inside one second gets its own name (#335)',
      () async {
        File(p.join(tempDir.path, 'Note.md')).writeAsStringSync('x');
        final first = await trashFileName(tempDir, 'Note', '.md');
        File(p.join(tempDir.path, first)).writeAsStringSync('y');
        final second = await trashFileName(tempDir, 'Note', '.md');
        expect(second, isNot(first));
        expect(second, endsWith('.md'));
        expect(File(p.join(tempDir.path, second)).existsSync(), isFalse);
      },
    );

    test('a second directory collision gets its own name too (#335)', () async {
      Directory(p.join(tempDir.path, 'Docs')).createSync();
      final first = await trashDirName(tempDir, 'Docs');
      Directory(p.join(tempDir.path, first)).createSync();
      final second = await trashDirName(tempDir, 'Docs');
      expect(second, isNot(first));
      expect(second, startsWith('Docs.'));
      expect(Directory(p.join(tempDir.path, second)).existsSync(), isFalse);
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

    test('isUnder reports descendants at any depth', () {
      expect(isUnder('a/b', 'a/b/c'), isTrue);
      expect(isUnder('a/b', 'a/b/c/d/e.md'), isTrue);
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

    test('the temp file is a dotfile next to the target', () {
      final file = File(p.join(tempDir.path, 'docs/note.md'));
      final temp = atomicTempPath(file, 123);
      // Same directory, so the rename stays on one filesystem...
      expect(temp.parent.path, file.parent.path);
      // ...and a dotfile, so the indexer's hidden-entry rule skips it.
      expect(p.basename(temp.path), startsWith('.'));
      expect(p.basename(temp.path), contains(p.basename(file.path)));
      expect(atomicTempPath(file, 456).path, isNot(temp.path));
    });

    test('the temp name is cut from the path it was given', () {
      // Not joined with `package:path`: that resolves the platform's style,
      // which asks for the working directory — and a write has to work
      // whatever happened to the directory the app was launched from
      // (#319). The path comes back with the separators it had.
      expect(
        atomicTempPath(File('/lib/note.md'), 7).path,
        '/lib/.note.md.niman-tmp-7',
      );
      expect(
        atomicTempPath(File(r'C:\lib\note.md'), 7).path,
        r'C:\lib\.note.md.niman-tmp-7',
      );
    });
  });

  group('sweepStaleTempFiles', () {
    // A temp file old enough that no running write could be what left it.
    void makeStale(File file) {
      file
        ..writeAsStringSync('half-written')
        ..setLastModifiedSync(
          DateTime.now().subtract(const Duration(hours: 1)),
        );
    }

    test('removes the temp files a killed write left, and nothing else', () {
      final note = File(p.join(tempDir.path, 'a.md'))
        ..writeAsStringSync('the note');
      final hidden = File(p.join(tempDir.path, '.hidden'))
        ..writeAsStringSync('not a temp');
      final atomic = File(
        p.join(tempDir.path, '.a.md.niman-tmp-1790060822793600'),
      );
      final sync = File(
        p.join(tempDir.path, '.a.md.niman-tmp-sync-1790060822793601'),
      );
      makeStale(atomic);
      makeStale(sync);

      expect(sweepStaleTempFiles(tempDir.path), 2);

      expect(atomic.existsSync(), isFalse);
      expect(sync.existsSync(), isFalse);
      expect(note.readAsStringSync(), 'the note');
      expect(hidden.existsSync(), isTrue);
    });

    test('keeps a temp file young enough to be a write in flight', () {
      final fresh = File(
        p.join(tempDir.path, '.a.md.niman-tmp-1790060822793602'),
      )..writeAsStringSync('being written');

      expect(sweepStaleTempFiles(tempDir.path), 0);
      expect(fresh.existsSync(), isTrue);
    });

    test('walks the hidden folders a state write leaves its temp in', () {
      final state = Directory(p.join(tempDir.path, '.niman'))..createSync();
      final settings = File(p.join(state.path, 'settings.json'))
        ..writeAsStringSync('{}');
      final temp = File(
        p.join(state.path, '.settings.json.niman-tmp-1790060822793600'),
      );
      makeStale(temp);

      expect(sweepStaleTempFiles(tempDir.path), 1);

      expect(temp.existsSync(), isFalse);
      expect(settings.readAsStringSync(), '{}');
    });

    test('leaves a .git folder — the user keeps it — alone', () {
      final git = Directory(p.join(tempDir.path, '.git'))..createSync();
      final temp = File(
        p.join(git.path, '.notes.md.niman-tmp-1790060822793600'),
      );
      makeStale(temp);

      expect(sweepStaleTempFiles(tempDir.path), 0);
      expect(temp.existsSync(), isTrue);
    });
  });

  group('DiskStamp', () {
    test('matches the file it stamped, and not a changed one', () async {
      final file = File(p.join(tempDir.path, 'stamp.md'))
        ..writeAsStringSync('one two three');
      final stamp = DiskStamp.of(file.path);
      expect(stamp, isNotNull);
      expect(stamp!.matches(file.path), isTrue);

      // A different size.
      file.writeAsStringSync('one two three four');
      expect(stamp.matches(file.path), isFalse);

      // A different time, the same size: what a one-letter swap looks like.
      // The filesystem's stamp has to move, so write, take the stamp, wait,
      // and write again with the same length.
      final kept = DiskStamp.of(file.path)!;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      file.writeAsStringSync('one two three five');
      expect(kept.matches(file.path), isFalse);
    });

    test('a file that is not there does not match', () {
      final stamp = DiskStamp.of(p.join(tempDir.path, 'gone.md'));
      expect(stamp, isNull);
      expect(
        DiskStamp(size: 0, modified: _epoch).matches(tempDir.path),
        isFalse,
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
