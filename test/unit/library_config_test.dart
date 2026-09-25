import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show
        EditorKind,
        LinkType,
        TreeSort,
        defaultAnnotationsFolder,
        defaultAttachmentsFolder,
        defaultListFolder;
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.current.createTemp('niman_library_config_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<Directory> makeLibrary() => tempDir.createTemp('lib_');

  group('LibraryConfigStore', () {
    test('writes to <library>/.niman/settings.json', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      // Joined, not spelled with '/': the store builds the path with
      // `package:path`, which uses '\' on Windows.
      expect(store.file.path, p.join(lib.path, '.niman', 'settings.json'));
      expect(store.file.existsSync(), isFalse);
      await store.write(LibraryConfig.defaults);
      expect(store.file.existsSync(), isTrue);
    });

    test(
      'a lost settings file says so, and a new library does not shout',
      () async {
        // #258's second half: the fallback to defaults is not neutral — engine,
        // editors, toolbar and tree all revert — and it used to happen with no
        // line anywhere. A library that has been written to before and has no
        // settings file is a warning; one with no `.niman/` at all is just new.
        final lib = await makeLibrary();
        final store = LibraryConfigStore(lib.path);
        AppLog.clear();
        expect(await store.read(), LibraryConfig.defaults);
        expect(
          AppLog.lines().where((line) => line.contains('WARNING')).length,
          0,
          reason: 'a new library is not a problem: ${AppLog.lines()}',
        );

        await store.write(LibraryConfig.defaults);
        store.file.deleteSync();
        AppLog.clear();
        expect(await store.read(), LibraryConfig.defaults);
        final warnings = AppLog.lines()
            .where((line) => line.contains('WARNING'))
            .toList();
        expect(warnings, hasLength(1));
        expect(warnings.single, contains('settings.json is missing'));
        expect(warnings.single, contains('on defaults'));

        store.file.writeAsStringSync('{ not json');
        AppLog.clear();
        expect(await store.read(), LibraryConfig.defaults);
        expect(
          AppLog.lines().any((line) => line.contains('could not be parsed')),
          isTrue,
          reason: AppLog.lines().join('\n'),
        );
      },
    );

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

    test(
      'round trips the history interval; nonsense reads back as 5',
      () async {
        final lib = await makeLibrary();
        final store = LibraryConfigStore(lib.path);
        const config = LibraryConfig(
          trashEnabled: true,
          historyVersions: 10,
          quickNotePath: null,
          listNoteFolder: 'Lists',
          historyIntervalMinutes: 15,
        );
        await store.write(config);
        expect((await store.read()).historyIntervalMinutes, 15);
        expect(normalizeHistoryIntervalMinutes(0), 5);
        expect(normalizeHistoryIntervalMinutes(61), 5);
        expect(normalizeHistoryIntervalMinutes('10'), 5);
        expect(normalizeHistoryIntervalMinutes(60), 60);
      },
    );

    test('round trips the dead-link note location; nonsense reads back as '
        'the current folder (issue #78)', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      const config = LibraryConfig(
        trashEnabled: true,
        historyVersions: 10,
        quickNotePath: null,
        listNoteFolder: 'Lists',
        missingNoteLocation: MissingNoteLocation.libraryRoot,
      );
      await store.write(config);
      expect(
        (await store.read()).missingNoteLocation,
        MissingNoteLocation.libraryRoot,
      );
    });

    test('the dead-link location defaults to the current folder', () {
      expect(
        LibraryConfig.defaults.missingNoteLocation,
        MissingNoteLocation.currentFolder,
      );
      expect(
        LibraryConfig.fromJsonMap(const <String, Object?>{})
            .missingNoteLocation,
        MissingNoteLocation.currentFolder,
      );
      expect(
        LibraryConfig.fromJsonMap(const <String, Object?>{
          'missingNoteLocation': 'libraryRoot',
        }).missingNoteLocation,
        MissingNoteLocation.libraryRoot,
      );
      expect(
        LibraryConfig.fromJsonMap(const <String, Object?>{
          'missingNoteLocation': 'nonsense',
        }).missingNoteLocation,
        MissingNoteLocation.currentFolder,
      );
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

    test('the lint rules turned off round trip', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      final config = LibraryConfig.defaults.copyWith(
        lintRulesOff: const {'tight-lists', 'closing-fence'},
      );
      await store.write(config);
      expect((await store.read()).lintRulesOff, const {
        'tight-lists',
        'closing-fence',
      });
      // Nothing off writes no key and reads back as every rule on.
      await store.write(LibraryConfig.defaults);
      expect((await store.read()).lintRulesOff, isEmpty);
    });

    test('an unknown or malformed lint rule id is dropped', () async {
      expect(
        LibraryConfig.fromJsonMap(const {
          'lintRulesOff': ['tight-lists', 'byVibes'],
        }).lintRulesOff,
        const {'tight-lists'},
      );
      expect(
        LibraryConfig.fromJsonMap(const {'lintRulesOff': 'tight-lists'})
            .lintRulesOff,
        isEmpty,
      );
    });

    test('an older file reads back as the shipped editor defaults', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      expect((await store.read()).editorKind, EditorKind.source);
    });

    test('the retired engine switch is read and let go (#247)', () async {
      // One engine now: a file written while there were two still opens,
      // and the key is not handed back as an unknown one to keep forever.
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync(
        '{"markdownEngine": "unified", "editorKind": "wysiwyg"}',
      );
      final config = await store.read();
      expect(config.editorKind, EditorKind.wysiwyg);
      await store.write(config);
      expect(store.file.readAsStringSync(), isNot(contains('markdownEngine')));
    });

    test('round trips the editor kind', () async {
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      const config = LibraryConfig(
        trashEnabled: true,
        historyVersions: 10,
        quickNotePath: null,
        listNoteFolder: 'Lists',
        editorKind: EditorKind.wysiwyg,
      );
      await store.write(config);
      final read = await store.read();
      expect(read.editorKind, EditorKind.wysiwyg);
      expect(read, config);
    });

    test('the dropped preview switch is read but never written back', () async {
      // The key stays understood — a file that carries it must not have it
      // handed back as an unknown one to preserve forever — and the preview
      // is part of the app now, so nothing writes it again.
      final lib = await makeLibrary();
      final store = LibraryConfigStore(lib.path);
      await store.file.parent.create(recursive: true);
      await store.file.writeAsString(
        '{"previewEnabled": false, "lineNumbers": false}',
      );
      final read = await store.read();
      expect(read.extra, isNot(contains('previewEnabled')));
      expect(read.lineNumbers, isFalse);
      await store.write(read);
      expect(
        await store.file.readAsString(),
        isNot(contains('previewEnabled')),
      );
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
        readableLineLength: false,
        noteColumnWidth: 900,
        typewriter: true,
        tidyOnClose: false,
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
        'readableLineLength',
        'noteColumnWidth',
        'typewriter',
        'tidyOnClose',
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

    test('the automatic trash empty is off until it is asked for', () {
      // Issue #79: the setting is permission to delete notes for good,
      // so a fresh library, a file without the key and a value nobody
      // can read all mean the same thing — empty nothing.
      int daysOf(Object? raw) =>
          LibraryConfig.fromJsonMap({'trashAutoEmptyDays': raw})
              .trashAutoEmptyDays;
      expect(LibraryConfig.defaults.trashAutoEmptyDays, trashAutoEmptyOff);
      expect(LibraryConfig.fromJsonMap(const {}).trashAutoEmptyDays, 0);
      expect(daysOf(30), 30);
      expect(daysOf(minTrashAutoEmptyDays), minTrashAutoEmptyDays);
      expect(daysOf(maxTrashAutoEmptyDays), maxTrashAutoEmptyDays);
      expect(daysOf(0), trashAutoEmptyOff);
      expect(daysOf(-1), trashAutoEmptyOff);
      expect(daysOf(maxTrashAutoEmptyDays + 1), trashAutoEmptyOff);
      expect(daysOf('30'), trashAutoEmptyOff);
      expect(daysOf(30.5), trashAutoEmptyOff);
      expect(daysOf(null), trashAutoEmptyOff);
    });

    test('the automatic trash empty survives a write and a read', () {
      final written = LibraryConfig.defaults
          .copyWith(trashAutoEmptyDays: 90)
          .toJsonMap();
      expect(written['trashAutoEmptyDays'], 90);
      expect(LibraryConfig.fromJsonMap(written).trashAutoEmptyDays, 90);
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

    test('a hand-written attachmentsFolder is sanitized on read', () {
      String folderOf(String raw) =>
          LibraryConfig.fromJsonMap({'attachmentsFolder': raw})
              .attachmentsFolder;
      expect(folderOf('/Attachments/'), 'Attachments');
      expect(folderOf('  '), defaultAttachmentsFolder);
      expect(
        LibraryConfig.fromJsonMap(const {}).attachmentsFolder,
        defaultAttachmentsFolder,
      );
      expect(LibraryConfig.defaults.attachmentsFolder, 'assets');
    });

    test('the annotations folder round-trips, sanitized on read (#284)', () {
      String folderOf(String raw) =>
          LibraryConfig.fromJsonMap({'annotationsFolder': raw})
              .annotationsFolder;
      expect(folderOf('/Reading/Notes/'), 'Reading/Notes');
      expect(folderOf('  '), defaultAnnotationsFolder);
      expect(LibraryConfig.defaults.annotationsFolder, 'Annotations');
      final config = LibraryConfig.defaults.copyWith(annotationsFolder: 'R');
      expect(
        LibraryConfig.fromJsonMap(config.toJsonMap()).annotationsFolder,
        'R',
      );
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
      // #171: the note is a centred column unless someone says otherwise.
      expect(config.readableLineLength, isTrue);
      expect(config.noteColumnWidth, defaultNoteColumnWidth);
      // #70: typewriter mode is asked for, never assumed.
      expect(config.typewriter, isFalse);
      // A note closed after an edit is tidied unless someone says otherwise.
      expect(config.tidyOnClose, isTrue);
    });

    test('tidyOnClose is on unless the file says false', () {
      bool tidyOf(Object? raw) =>
          LibraryConfig.fromJsonMap({'tidyOnClose': raw}).tidyOnClose;
      expect(LibraryConfig.fromJsonMap(const {}).tidyOnClose, isTrue);
      expect(tidyOf(false), isFalse);
      expect(tidyOf(true), isTrue);
      // A value nobody can read is the default, not "off".
      expect(tidyOf('no'), isTrue);
      expect(tidyOf(0), isTrue);
      final off = LibraryConfig.defaults.copyWith(tidyOnClose: false);
      expect(off.toJsonMap()['tidyOnClose'], isFalse);
      expect(LibraryConfig.fromJsonMap(off.toJsonMap()), off);
      expect(off, isNot(LibraryConfig.defaults));
    });

    test('tidyOnClose travels with the library, not the device', () {
      // It decides how the library's files are written, so every device
      // opening the library must read the same answer.
      final off = LibraryConfig.defaults.copyWith(tidyOnClose: false);
      expect(LibraryConfig.deviceKeys, isNot(contains('tidyOnClose')));
      expect(off.libraryJsonMap()['tidyOnClose'], isFalse);
      expect(off.deviceJsonMap().containsKey('tidyOnClose'), isFalse);
    });

    test('an out-of-range indentWidth is brought into range', () {
      // Clamped rather than defaulted: 1 and 40 are both plausible things
      // to type, and the nearest legal width is closer to what was meant.
      expect(normalizeIndentWidth(1), minIndentWidth);
      expect(normalizeIndentWidth(40), maxIndentWidth);
      expect(normalizeIndentWidth(4), 4);
      expect(normalizeIndentWidth('four'), defaultIndentWidth);
    });

    test('an out-of-range noteColumnWidth is clamped into range', () {
      expect(normalizeNoteColumnWidth(100), minNoteColumnWidth);
      expect(normalizeNoteColumnWidth(9000), maxNoteColumnWidth);
      expect(normalizeNoteColumnWidth(820), 820);
      expect(normalizeNoteColumnWidth(double.nan), defaultNoteColumnWidth);
      expect(normalizeNoteColumnWidth('wide'), defaultNoteColumnWidth);
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
