import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:path/path.dart' as p;

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// Whether [text] holds a UTF-16 code unit without its partner — what a
/// `substring` cut through an astral character leaves behind.
bool _hasLoneSurrogate(String text) {
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit >= 0xDC00 && unit <= 0xDFFF) {
      return true;
    }
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      final next = i + 1 < text.length ? text.codeUnitAt(i + 1) : 0;
      if (next < 0xDC00 || next > 0xDFFF) {
        return true;
      }
      i++;
    }
  }
  return false;
}

/// Whether the filesystem under the working directory treats `Case.md` and
/// `case.md` as one entry.
///
/// Asked of the filesystem rather than of the platform: a case-sensitive
/// volume can sit under any of them.
bool _fsFoldsCase() {
  final dir = Directory.current.createTempSync('niman_case_probe_');
  try {
    File(p.join(dir.path, 'Case.md')).writeAsStringSync('x');
    return File(p.join(dir.path, 'case.md')).existsSync();
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void main() {
  late Directory tempDir;
  // Decided before the tests are declared, because `skip:` is read then. On a
  // case-sensitive filesystem two names differing only in case are two
  // entries, and there is nothing for the guarded tests to prove (#354).
  final caseSkipReason = _fsFoldsCase()
      ? null
      : 'the filesystem keeps Note.md and note.md apart';

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

    test('never lets a reserved device name through (#354)', () {
      // These name a Windows device, not a file: a note or an imported
      // folder spelled that way cannot be opened there.
      for (final reserved in <String>['CON', 'NUL', 'COM1', 'LPT9', 'con']) {
        expect(sanitizeName(reserved, fallback: 'X'), isNot(reserved));
      }
      // The stem decides, whatever follows it.
      expect(sanitizeName('CON.md', fallback: 'X'), isNot('CON.md'));
      expect(sanitizeName('NUL.txt', fallback: 'X'), isNot('NUL.txt'));
      expect(sanitizeName('aux..', fallback: 'X'), isNot('aux'));
    });

    test('leaves names that only look reserved alone (#354)', () {
      expect(sanitizeName('Console', fallback: 'X'), 'Console');
      expect(sanitizeName('COM10', fallback: 'X'), 'COM10');
      expect(sanitizeName('my-CON', fallback: 'X'), 'my-CON');
      expect(sanitizeName('.CON', fallback: 'X'), '.CON');
    });

    test('cuts a long astral name to a utf-8 byte budget (#354)', () {
      // 300 astral characters: 600 UTF-16 units and 1200 bytes. Counting
      // units kept 100 of them — 400 bytes, past the filesystem's 255-byte
      // component limit.
      final name = sanitizeName('𝔘' * 300, fallback: 'X');
      expect(utf8.encode(name).length, lessThanOrEqualTo(255));
      expect(name.runes.length, greaterThan(10));
      expect(name, '𝔘' * name.runes.length);
    });

    test('never cuts a surrogate pair in half (#354)', () {
      // The 200th code unit here is the high half of an astral character, so
      // a code-unit cut leaves a lone surrogate that encoding silently turns
      // into U+FFFD.
      final name = sanitizeName('a' * 199 + '𝔘' * 3, fallback: 'X');
      expect(_hasLoneSurrogate(name), isFalse);
      expect(utf8.encode(name).length, lessThanOrEqualTo(255));
      expect(name.startsWith('a' * 199), isTrue);
    });

    test('falls back when nothing usable remains', () {
      expect(sanitizeName('???', fallback: 'Untitled'), 'Untitled');
      expect(sanitizeName('   ', fallback: 'Untitled'), 'Untitled');
    });

    test('removes trailing dot runs but keeps leading dots', () {
      expect(sanitizeName('notes...', fallback: 'X'), 'notes');
      expect(sanitizeName('.hidden.', fallback: 'X'), '.hidden');
    });

    test('never ends a name with a dot or a space', () {
      // Windows drops both from the end of a component: a folder created as
      // `Draft.` exists as `Draft`, and the index would hold a name the disk
      // does not.
      expect(sanitizeName('Draft.', fallback: 'X'), 'Draft');
      expect(sanitizeName('Draft. .', fallback: 'X'), 'Draft');
      // The byte cap can land just after a space or a dot: what it leaves
      // is trimmed too.
      expect(sanitizeName('${'a' * 199} b', fallback: 'X'), 'a' * 199);
      expect(sanitizeName('${'a' * 199}.b', fallback: 'X'), 'a' * 199);
      expect(sanitizeName('. .', fallback: 'X'), 'X');
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

    test(
      'compares the excluded path as a path, not as a string (#354)',
      () async {
        final selfPath = p.join(tempDir.path, 'Note.md');
        File(selfPath).writeAsStringSync('x');
        final name = await uniqueFileName(
          tempDir,
          'Note',
          '.md',
          exclude: p.join(tempDir.path, '.', 'Note.md'),
        );
        expect(name, 'Note.md');
      },
    );

    test('a rename that only changes case keeps the name (#354)', () async {
      final selfPath = p.join(tempDir.path, 'Note.md');
      File(selfPath).writeAsStringSync('x');
      // On a case-insensitive filesystem the two spellings are one entry,
      // so `Note.md` is not in the way of `note.md`.
      final name = await uniqueFileName(
        tempDir,
        'note',
        '.md',
        exclude: selfPath,
      );
      expect(name, 'note.md');
    }, skip: caseSkipReason);
  });

  group('isExcludedEntry', () {
    // The folding flag and the listing are handed in, so the case a
    // case-sensitive folder on Windows presents — `A.md` and `a.md` side by
    // side — is decided the same on every host, whatever its own
    // filesystem can hold.
    final renamed = p.join('lib', 'A.md');

    test('the entry itself, spelled the same, is free', () {
      expect(
        isExcludedEntry(
          renamed,
          renamed,
          foldsCase: true,
          entryNames: () => const ['A.md', 'a.md'],
        ),
        isTrue,
      );
    });

    test('another spelling is free when the folder folds case', () {
      expect(
        isExcludedEntry(
          p.join('lib', 'a.md'),
          renamed,
          foldsCase: true,
          entryNames: () => const ['A.md'],
        ),
        isTrue,
      );
    });

    test('another spelling the folder holds is somebody else', () {
      // A folder made case-sensitive (WSL, fsutil) on a platform that folds
      // case: renaming `A.md` to `a` must not pick `a.md` as the entry being
      // renamed, or the rename replaces the other note.
      expect(
        isExcludedEntry(
          p.join('lib', 'a.md'),
          renamed,
          foldsCase: true,
          entryNames: () => const ['A.md', 'a.md'],
        ),
        isFalse,
      );
    });

    test('another spelling is somebody else where case is not folded', () {
      expect(
        isExcludedEntry(
          p.join('lib', 'a.md'),
          renamed,
          foldsCase: false,
          entryNames: () => const ['A.md'],
        ),
        isFalse,
      );
    });
  });

  group('excludedEntryIn', () {
    test(
      'a case-only rename asks the folder off the UI isolate (#492)',
      () async {
        final self = p.join(tempDir.path, 'Note.md');
        File(self).writeAsStringSync('x');
        // A folder that folds case leaves `note.md` and `Note.md` one entry, so
        // only the folder's own listing can say whether the exact spelling is
        // held. That walk is O(entries) and must not run on this isolate.
        final lookup = excludedEntryIn(
          tempDir.path,
          p.join(tempDir.path, 'note.md'),
          self,
          foldsCase: true,
        );
        expect(
          IsolateGauge.inFlight,
          greaterThan(0),
          reason: 'the folder is walked on a background isolate, not this one',
        );
        expect(
          await lookup,
          isTrue,
          reason: 'Note.md is the entry being renamed',
        );
        expect(IsolateGauge.inFlight, 0, reason: 'the job is counted back out');
      },
    );

    test('a spelling the folder holds is somebody else (#492)', () async {
      // A case-sensitive folder holding both spellings: the lookup finds the
      // candidate itself and the collision stands. Only the candidate's
      // spelling is written — a folder that folds case (NTFS, APFS) cannot
      // hold both, and writing the second would rewrite the first, so the
      // listing would never show the spelling the lookup has to find.
      File(p.join(tempDir.path, 'a.md')).writeAsStringSync('y');
      expect(
        await excludedEntryIn(
          tempDir.path,
          p.join(tempDir.path, 'a.md'),
          p.join(tempDir.path, 'A.md'),
          foldsCase: true,
        ),
        isFalse,
        reason: 'the folder holds a.md itself',
      );
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

    test('a file of that name is a collision too', () async {
      File(p.join(tempDir.path, 'Docs')).writeAsStringSync('x');
      expect(await uniqueFolderName(tempDir, 'Docs'), 'Docs_1');
    });

    test(
      'a folder rename that only changes case keeps the name (#354)',
      () async {
        final selfPath = p.join(tempDir.path, 'Docs');
        Directory(selfPath).createSync();
        expect(
          await uniqueFolderName(tempDir, 'docs', exclude: selfPath),
          'docs',
        );
      },
      skip: caseSkipReason,
    );
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

    test('a file never takes a name a folder holds', () async {
      // Trashing a file `Note.md` while the trash holds a folder of that
      // name: the rename onto the folder fails, and the delete with it.
      Directory(p.join(tempDir.path, 'Note.md')).createSync();
      final name = await trashFileName(tempDir, 'Note', '.md');
      expect(name, isNot('Note.md'));
      expect(name, endsWith('.md'));
    });

    test('a folder never takes a name a file holds', () async {
      File(p.join(tempDir.path, 'Docs')).writeAsStringSync('x');
      final name = await trashDirName(tempDir, 'Docs');
      expect(name, matches(RegExp(r'^Docs\.\d{10}$')));
    });

    test('a timestamped name held by the other kind is passed over', () async {
      File(p.join(tempDir.path, 'Docs')).writeAsStringSync('x');
      final first = await trashDirName(tempDir, 'Docs');
      File(p.join(tempDir.path, first)).writeAsStringSync('y');
      final second = await trashDirName(tempDir, 'Docs');
      expect(second, isNot(first));
      expect(
        FileSystemEntity.typeSync(p.join(tempDir.path, second)),
        FileSystemEntityType.notFound,
      );
    });

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

    test('pathAfterMove follows the item and, for a folder, its subtree', () {
      expect(
        pathAfterMove('Inbox/x.md', 'Inbox/x.md', 'Done.md', isDir: false),
        'Done.md',
      );
      expect(
        pathAfterMove('Inbox/x.md', 'Inbox', 'Done/x.md', isDir: false),
        'Inbox/x.md',
        reason: 'a file carries only itself',
      );
      expect(
        pathAfterMove('Inbox/x.md', 'Inbox', 'Done', isDir: true),
        'Done/x.md',
      );
      expect(
        pathAfterMove('Inbox/x.md', 'Elsewhere', 'Done', isDir: true),
        'Inbox/x.md',
      );
      expect(pathAfterMove(null, 'a', 'b', isDir: true), isNull);
      expect(pathAfterMove('', 'a', 'b', isDir: true), '');
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
