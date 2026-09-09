import 'dart:io';

import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/core/settings/library_settings.dart'
    show defaultListFolder;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.current.createTemp('copist_library_config_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<Directory> makeLibrary() => tempDir.createTemp('lib_');

  group('LibraryConfigStore', () {
    test('writes to <library>/.copist/settings.json', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      expect(store.file.path, '${lib.path}/.copist/settings.json');
      expect(store.file.existsSync(), isFalse);
      await store.write(LibraryConfig.defaults);
      expect(store.file.existsSync(), isTrue);
    });

    test('round trips a config through the file', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      const config = LibraryConfig(
        trashEnabled: false,
        historyVersions: 3,
        quickNotePath: 'Inbox/Quick note.md',
        listNoteFolder: 'Notes/Lists',
      );
      await store.write(config);
      expect(await store.read(), config);
    });

    test('a config without a quick note round trips as default', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.write(
        const LibraryConfig(
          trashEnabled: false,
          historyVersions: 25,
          quickNotePath: null,
          listNoteFolder: 'Lists',
        ),
      );
      expect(
        await store.read(),
        const LibraryConfig(
          trashEnabled: false,
          historyVersions: 25,
          quickNotePath: null,
          listNoteFolder: 'Lists',
        ),
      );
    });

    test('a missing file gives the defaults', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      expect(await store.read(), LibraryConfig.defaults);
    });

    test('an empty object gives the defaults', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync('{}');
      expect(await store.read(), LibraryConfig.defaults);
    });

    test('a malformed file does not throw and gives the defaults', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync('{ not json ,,');
      expect(await store.read(), LibraryConfig.defaults);
    });

    test('a non-object JSON value gives the defaults', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync('[1, 2, 3]');
      expect(await store.read(), LibraryConfig.defaults);
    });

    test('a wrong-typed known key falls back to the default', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync(
        '{"trashEnabled": "no", "historyVersions": "ten", '
        '"quickNotePath": 42, "listNoteFolder": 7}',
      );
      expect(await store.read(), LibraryConfig.defaults);
    });

    test('an unreadable file gives the defaults', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync('{"trashEnabled": false}');
      // `dart:io` has no chmod; use the shell one where available.
      final hide = await Process.run('chmod', ['000', store.file.path]);
      if (hide.exitCode != 0) return; // no shell chmod: nothing to verify.
      try {
        expect(await store.read(), LibraryConfig.defaults);
      } finally {
        await Process.run('chmod', ['644', store.file.path]);
      }
    });

    test('an unknown key survives a write', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      // Hand-written by a "newer build" the app does not understand.
      await store.file.create(recursive: true);
      store.file.writeAsStringSync(
        '{"trashEnabled": false, "historyVersions": 4, '
        '"futureSetting": {"a": 1}}',
      );
      final read = await store.read();
      expect(read.trashEnabled, isFalse);
      expect(read.extra['futureSetting'], isNotNull);

      await store.write(read);
      // Read straight from disk: the key is still there.
      final content = store.file.readAsStringSync();
      expect(content, contains('"futureSetting"'));
      expect(content, contains('"a"'));
      expect(await store.read(), read);
    });

    test('preserves unknown keys through repeated writes', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      const config = LibraryConfig(
        trashEnabled: true,
        historyVersions: 10,
        quickNotePath: null,
        listNoteFolder: defaultListFolder,
        extra: {'editorTheme': 'dark'},
      );
      await store.write(config);
      await store.write(
        config.copyWith(trashEnabled: false, historyVersions: 2),
      );
      final read = await store.read();
      expect(read.trashEnabled, isFalse);
      expect(read.historyVersions, 2);
      expect(read.extra, {'editorTheme': 'dark'});
    });

    test('writes indented, human-readable JSON', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.write(LibraryConfig.defaults);
      final content = store.file.readAsStringSync();
      expect(content, contains('\n  "trashEnabled": true'));
    });
  });

  group('LibraryConfig', () {
    test('defaults match a fresh library', () {
      expect(LibraryConfig.defaults.trashEnabled, isTrue);
      expect(LibraryConfig.defaults.historyVersions, 10);
      expect(LibraryConfig.defaults.quickNotePath, isNull);
      expect(LibraryConfig.defaults.listNoteFolder, defaultListFolder);
    });

    test('value equality', () {
      expect(
        const LibraryConfig(
          trashEnabled: false,
          historyVersions: 3,
          quickNotePath: 'q.md',
          listNoteFolder: 'L',
        ),
        const LibraryConfig(
          trashEnabled: false,
          historyVersions: 3,
          quickNotePath: 'q.md',
          listNoteFolder: 'L',
        ),
      );
    });
  });
}
