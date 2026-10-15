// The keyed JSON file of `.niman/` that the reading positions and the review
// states share (#951): updates queued, every step off the UI isolate, the
// entries of a moved or removed file followed by path.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/library_state_file.dart';
import 'package:path/path.dart' as p;

const String _path = '.niman/things.json';

void main() {
  late Directory root;
  late LibraryStateFile file;
  setUp(() {
    root = Directory.systemTemp.createTempSync('niman_state_file_');
    file = LibraryStateFile(root.path, _path);
  });
  tearDown(() => root.deleteSync(recursive: true));

  File kept() => File(p.join(root.path, _path));
  Map<String, Object?> onDisk() =>
      (jsonDecode(kept().readAsStringSync()) as Map).cast<String, Object?>();
  Future<bool> put(String key, Object? value) => file.update((entries) {
    entries[key] = value;
    return true;
  });

  test('reads nothing from a file never written', () async {
    expect(await file.readAll(), isEmpty);
    expect(await file.read(['a.md']), isEmpty);
    expect(kept().existsSync(), isFalse);
  });

  test('writes an object keyed by path, and reads it back', () async {
    expect(await put('a.md', {'x': 1}), isTrue);
    expect(onDisk(), {
      'a.md': {'x': 1},
    });
    expect(kept().readAsStringSync(), endsWith('\n'));
    expect(await file.readAll(), {
      'a.md': {'x': 1},
    });
  });

  test('reads only the entries asked for', () async {
    await put('a.md', 1);
    await put('b.md', 2);
    await put('c.md', 3);
    expect(await file.read(['a.md', 'c.md', 'none.md']), {
      'a.md': 1,
      'c.md': 3,
    });
    expect(await file.read(const []), isEmpty);
  });

  test('writes nothing when the change says it changed nothing', () async {
    await put('a.md', 1);
    final text = kept().readAsStringSync();
    final modified = kept().lastModifiedSync();
    expect(await file.update((entries) => false), isFalse);
    expect(kept().readAsStringSync(), text);
    expect(kept().lastModifiedSync(), modified);
  });

  test('queues updates issued together, none lost', () async {
    await Future.wait([
      for (var i = 0; i < 12; i++) put('a $i', i),
      for (var i = 0; i < 12; i++)
        LibraryStateFile(root.path, _path).update((entries) {
          entries['b $i'] = i;
          return true;
        }),
    ]);
    expect(await file.readAll(), hasLength(24));
  });

  test('runs the change off the isolate that asked', () async {
    // The change runs on a background isolate: it sees a copy of what it
    // captured, so a mutation of a captured list never comes back.
    final seen = <String>[];
    await file.update((entries) {
      seen.add('changed');
      return false;
    });
    expect(seen, isEmpty);
  });

  test('a file that does not read is read as empty and written over', () async {
    Directory(p.join(root.path, '.niman')).createSync();
    kept().writeAsStringSync('{ not json');
    expect(await file.readAll(), isEmpty);
    await put('a.md', 1);
    expect(onDisk(), {'a.md': 1});
    kept().writeAsStringSync('[1, 2]');
    expect(await file.readAll(), isEmpty);
  });

  test(
    'a file that is there but cannot be opened is left alone (#955)',
    () async {
      // A directory where the file belongs opens for nobody: the same fault as
      // a lock held while the sync swaps the file, on every platform without a
      // permission call. It is not "no file yet", so nothing may be written.
      Directory(p.join(root.path, _path)).createSync(recursive: true);
      final marker = File(p.join(root.path, 'change-ran'));
      final markerPath = marker.path;

      expect(
        LibraryStateFile.readBlocking(root.path, _path).problem,
        isNotNull,
      );
      expect(await file.readAll(), isEmpty);
      final wrote = await file.update((entries) {
        File(markerPath).writeAsStringSync('ran');
        entries['a.md'] = 1;
        return true;
      });
      expect(wrote, isFalse);
      expect(marker.existsSync(), isFalse, reason: 'the change never ran');
      expect(await file.moved('a.md', 'b.md'), isFalse);
      expect(await file.removed(['a.md']), isFalse);
      expect(FileSystemEntity.isDirectorySync(kept().path), isTrue);
    },
  );

  test(
    'a missing file is no problem, and the first update creates it',
    () async {
      expect(LibraryStateFile.readBlocking(root.path, _path).problem, isNull);
      // The folder of the file is missing too.
      expect(await put('a.md', 1), isTrue);
      expect(onDisk(), {'a.md': 1});
    },
  );

  test(
    'keeps the entries an update did not touch, whatever they hold',
    () async {
      Directory(p.join(root.path, '.niman')).createSync();
      kept().writeAsStringSync(
        jsonEncode({
          'a.md': 'odd',
          'b.md': null,
          'c.md': [1],
        }),
      );
      await put('d.md', 4);
      expect(onDisk(), {
        'a.md': 'odd',
        'b.md': null,
        'c.md': [1],
        'd.md': 4,
      });
    },
  );

  group('moved', () {
    setUp(() async {
      await put('Studio/Verbs.md', 1);
      await put('Studio/Sub/Nouns.md', 2);
      await put('Studio 2/Verbs.md', 3);
    });

    test('carries the entry of a renamed or moved file', () async {
      expect(await file.moved('Studio/Verbs.md', 'Archive/Old.md'), isTrue);
      expect(await file.read(['Studio/Verbs.md']), isEmpty);
      expect(await file.read(['Archive/Old.md']), {'Archive/Old.md': 1});
    });

    test('carries every file under a moved folder, and only them', () async {
      await file.moved('Studio', 'Lessons');
      expect((await file.readAll()).keys, [
        'Studio 2/Verbs.md',
        'Lessons/Verbs.md',
        'Lessons/Sub/Nouns.md',
      ]);
    });

    test('writes nothing when no entry moves', () async {
      final before = kept().readAsStringSync();
      expect(await file.moved('Elsewhere', 'Somewhere'), isFalse);
      expect(await file.moved('Studio/Ver', 'Studio/Other'), isFalse);
      expect(kept().readAsStringSync(), before);
    });
  });

  group('removed', () {
    setUp(() async {
      await put('Studio/Verbs.md', 1);
      await put('Studio/Sub/Nouns.md', 2);
      await put('Studio 2/Verbs.md', 3);
    });

    test('drops a file, or a folder and every file under it', () async {
      expect(await file.removed(['Studio/Verbs.md']), isTrue);
      expect((await file.readAll()).keys, [
        'Studio/Sub/Nouns.md',
        'Studio 2/Verbs.md',
      ]);
      await file.removed(['Studio']);
      expect((await file.readAll()).keys, ['Studio 2/Verbs.md']);
    });

    test('drops by whole folders, at any depth, and by file', () async {
      await put('Studio/Sub/Deep/More.md', 4);
      await put('Studio/', 5);
      expect(await file.removed(['Studio/Sub', 'Studio 2/Verbs.md']), isTrue);
      expect((await file.readAll()).keys, ['Studio/Verbs.md', 'Studio/']);
    });

    test('a removed library root drops everything', () async {
      expect(await file.removed(['']), isTrue);
      expect(await file.readAll(), isEmpty);
    });

    test('does nothing for nothing', () async {
      expect(await file.removed(const []), isFalse);
      expect(await file.removed(['Missing.md']), isFalse);
      expect(await file.readAll(), hasLength(3));
    });
  });
}
