import 'dart:io';

import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/core/settings/library_settings.dart'
    show EditorKind, LinkType, TreeSort, defaultListFolder;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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
      // Joined, not spelled with '/': the store builds the path with
      // `package:path`, which uses '\' on Windows.
      expect(store.file.path, p.join(lib.path, '.copist', 'settings.json'));
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

    test('round trips the spell-check dictionaries', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      const config = LibraryConfig(
        trashEnabled: true,
        historyVersions: 10,
        quickNotePath: null,
        listNoteFolder: 'Lists',
        spellDictionaries: ['it_IT', 'en_US'],
      );
      await store.write(config);
      expect((await store.read()).spellDictionaries, ['it_IT', 'en_US']);
      // Clearing writes no key and reads back as the locale default.
      await store.write(config.copyWith(spellDictionaries: const []));
      expect((await store.read()).spellDictionaries, isEmpty);
    });

    test('migrates the legacy single-dictionary key', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.file.parent.create(recursive: true);
      await store.file.writeAsString('{"spellDictionary": "it_IT"}');
      expect((await store.read()).spellDictionaries, ['it_IT']);
    });

    test('an older file reads back as the shipped editor defaults', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      expect((await store.read()).editorKind, EditorKind.source);
      expect((await store.read()).previewEnabled, isTrue);
    });

    test('round trips the editor kind and the preview switch', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      const config = LibraryConfig(
        trashEnabled: true,
        historyVersions: 10,
        quickNotePath: null,
        listNoteFolder: 'Lists',
        editorKind: EditorKind.wysiwyg,
        previewEnabled: false,
      );
      await store.write(config);
      final read = await store.read();
      expect(read.editorKind, EditorKind.wysiwyg);
      expect(read.previewEnabled, isFalse);
    });

    test('round trips a single enabled editor', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      const config = LibraryConfig(
        trashEnabled: true,
        historyVersions: 10,
        quickNotePath: null,
        listNoteFolder: 'Lists',
        enabledEditors: {EditorKind.wysiwyg},
      );
      await store.write(config);
      expect(await store.read(), config);
    });

    test('a file without enabledEditors offers both', () async {
      // Files written before the switch existed always offered both (the
      // status row switched), so the key's absence keeps both on — with
      // the stored current editor untouched.
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync('{"editorKind": "wysiwyg"}');
      final read = await store.read();
      expect(read.editorKind, EditorKind.wysiwyg);
      expect(read.enabledEditors, {EditorKind.source, EditorKind.wysiwyg});
    });

    test('an empty or unknown enabledEditors list offers both', () async {
      Set<EditorKind> enabledOf(Object? raw) =>
          LibraryConfig.fromJsonMap({'enabledEditors': raw}).enabledEditors;
      expect(enabledOf([]), {EditorKind.source, EditorKind.wysiwyg});
      expect(enabledOf(['byVibes']), {EditorKind.source, EditorKind.wysiwyg});
      expect(enabledOf(['wysiwyg', 'wysiwyg']), {EditorKind.wysiwyg});
      expect(enabledOf('wysiwyg'), {EditorKind.source, EditorKind.wysiwyg});
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
      // A directory where the file should be. `read()` opens the path
      // without checking first, so this throws on the read the way a
      // permission error would, and it does so on every platform —
      // unlike `chmod`, which does not exist on Windows and made this
      // test throw a ProcessException instead of skipping.
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await Directory(store.file.path).create(recursive: true);
      expect(await store.read(), LibraryConfig.defaults);
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

    test('the editor settings round trip through the file', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      const config = LibraryConfig(
        trashEnabled: true,
        historyVersions: 10,
        quickNotePath: null,
        listNoteFolder: defaultListFolder,
        lineNumbers: false,
        editorAutofocus: true,
        reminderShowTokens: true,
        treeSort: TreeSort.nameDesc,
        linkType: LinkType.markdown,
        indentWidth: 4,
        editorToolbar: 'link,-bold',
      );
      await store.write(config);
      expect(await store.read(), config);
    });

    test('every setting is written, so the file explains itself', () async {
      // A user opening it in an editor sees the whole set, not only what
      // has been changed away from a default.
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.write(LibraryConfig.defaults);
      final content = store.file.readAsStringSync();
      for (final key in [
        'trashEnabled',
        'historyVersions',
        'listNoteFolder',
        'lineNumbers',
        'editorAutofocus',
        'reminderShowTokens',
        'treeSort',
        'linkType',
        'indentWidth',
        'editorToolbar',
        'enabledEditors',
        'treeWidth',
      ]) {
        expect(content, contains('"$key"'), reason: key);
      }
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

    test('an out-of-range historyVersions reads back as the default', () {
      // The file is hand-editable, so the number in it is an input.
      for (final absurd in [-5, -1, maxHistoryVersions + 1, 100000]) {
        expect(
          LibraryConfig.fromJsonMap({'historyVersions': absurd})
              .historyVersions,
          defaultHistoryVersions,
          reason: '$absurd should not reach the history code',
        );
      }
    });

    test('the ends of the range are kept', () {
      for (final count in [minHistoryVersions, 7, maxHistoryVersions]) {
        expect(
          LibraryConfig.fromJsonMap({'historyVersions': count}).historyVersions,
          count,
        );
      }
    });

    test('a fractional historyVersions truncates, then is ranged', () {
      expect(
        LibraryConfig.fromJsonMap(const {'historyVersions': 4.9})
            .historyVersions,
        4,
      );
      expect(
        LibraryConfig.fromJsonMap(const {'historyVersions': -0.5})
            .historyVersions,
        0,
      );
    });

    test('a hand-written listNoteFolder is sanitized on read', () {
      String folderOf(String raw) =>
          LibraryConfig.fromJsonMap({'listNoteFolder': raw}).listNoteFolder;
      expect(folderOf('/Lists/'), 'Lists');
      expect(folderOf('  Notes/Lists  '), 'Notes/Lists');
      expect(folderOf('../../etc'), 'etc');
      expect(folderOf('//'), defaultListFolder);
      expect(folderOf('  '), defaultListFolder);
    });

    test('a fresh library gets the shipped editor settings', () {
      // T-ML-10: they are the library's own, seeded from these.
      const config = LibraryConfig.defaults;
      expect(config.lineNumbers, isTrue);
      expect(config.editorAutofocus, isFalse);
      expect(config.reminderShowTokens, isFalse);
      expect(config.treeSort, TreeSort.nameAsc);
      expect(config.linkType, LinkType.wikilink);
      expect(config.indentWidth, defaultIndentWidth);
      expect(config.editorToolbar, '');
    });

    test('an out-of-range indentWidth is brought into range', () {
      // Clamped rather than defaulted: 1 and 40 are both plausible things
      // to type, and the nearest legal width is closer to what was meant.
      expect(normalizeIndentWidth(1), minIndentWidth);
      expect(normalizeIndentWidth(40), maxIndentWidth);
      expect(normalizeIndentWidth(4), 4);
      expect(normalizeIndentWidth('four'), defaultIndentWidth);
    });

    test('an out-of-range treeWidth is clamped into range', () {
      expect(normalizeTreeWidth(50), minTreeWidth);
      expect(normalizeTreeWidth(5000), maxTreeWidth);
      expect(normalizeTreeWidth(400), 400);
      expect(normalizeTreeWidth('wide'), defaultTreeWidth);
    });

    test('an unreadable enum falls back to its default', () {
      final config = LibraryConfig.fromJsonMap(const {
        'treeSort': 'byVibes',
        'linkType': 42,
        'lineNumbers': 'yes',
      });
      expect(config.treeSort, TreeSort.nameAsc);
      expect(config.linkType, LinkType.wikilink);
      expect(config.lineNumbers, isTrue);
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
