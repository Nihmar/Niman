import 'dart:io';

import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/core/settings/library_config_repo.dart';
import 'package:copist/src/core/settings/library_setting.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/core/settings/settings_resolver.dart';
import 'package:copist/src/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late AppDatabase db;
  late AppSettingsRepo app;
  late Directory libA;
  late Directory libB;

  setUp(() async {
    tmp = await Directory.current.createTemp('copist_resolver_');
    db = AppDatabase(NativeDatabase(File(p.join(tmp.path, 'copist.db'))));
    addTearDown(db.close);
    app = AppSettingsRepo(db);
    libA = Directory(p.join(tmp.path, 'A'))..createSync();
    libB = Directory(p.join(tmp.path, 'B'))..createSync();
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  SettingsResolver inA() => SettingsResolver(app, LibraryConfigRepo(libA.path));
  SettingsResolver inB() => SettingsResolver(app, LibraryConfigRepo(libB.path));

  /// A resolver with no library open at all.
  SettingsResolver noLibrary() => SettingsResolver(app, null);

  group('a library that overrides nothing', () {
    test('reads the app value', () async {
      await app.setIndentWidth(6);
      expect(await inA().indentWidth(), 6);
      expect(await inB().indentWidth(), 6);
    });

    test('writes to the app, so every library moves', () async {
      await inA().setIndentWidth(8);
      expect(await app.indentWidth(), 8);
      expect(await inB().indentWidth(), 8);
    });

    test('writes nothing into its settings file', () async {
      await inA().setLineNumbers(enabled: false);
      expect(LibraryConfigStore(libA.path).file.existsSync(), isFalse);
    });

    test('overrides nothing, by its own account', () async {
      expect(await inA().overridden(), isEmpty);
    });
  });

  group('a library that overrides one setting', () {
    test('starts at the app value, so nothing visibly changes', () async {
      await app.setIndentWidth(6);
      await inA().overrideHere(LibrarySetting.indentWidth);
      expect(await inA().indentWidth(), 6);
      expect(await inA().overridden(), {LibrarySetting.indentWidth});
    });

    test('then keeps its own answer', () async {
      await app.setIndentWidth(6);
      await inA().overrideHere(LibrarySetting.indentWidth);
      await inA().setIndentWidth(2);

      expect(await inA().indentWidth(), 2);
      // The app value is untouched, and so is the library that follows it.
      expect(await app.indentWidth(), 6);
      expect(await inB().indentWidth(), 6);
    });

    test('and stops following the app', () async {
      await inA().overrideHere(LibrarySetting.indentWidth);
      await inA().setIndentWidth(2);
      await app.setIndentWidth(8);

      expect(await inA().indentWidth(), 2);
      expect(await inB().indentWidth(), 8);
    });

    test('leaves the other settings following the app', () async {
      await inA().overrideHere(LibrarySetting.indentWidth);
      await app.setLinkType(LinkType.markdown);
      expect(await inA().linkType(), LinkType.markdown);
    });

    test('follows the app again once the override is dropped', () async {
      await inA().overrideHere(LibrarySetting.indentWidth);
      await inA().setIndentWidth(2);
      await app.setIndentWidth(8);

      await inA().followApp(LibrarySetting.indentWidth);
      expect(await inA().overridden(), isEmpty);
      expect(await inA().indentWidth(), 8);
    });

    test('the dropped value is gone, not remembered', () async {
      await inA().overrideHere(LibrarySetting.indentWidth);
      await inA().setIndentWidth(2);
      await inA().followApp(LibrarySetting.indentWidth);
      await inA().overrideHere(LibrarySetting.indentWidth);
      // Seeded from the app again, not from what it used to say.
      expect(await inA().indentWidth(), await app.indentWidth());
    });
  });

  group('every overridable setting round trips', () {
    test('booleans', () async {
      final a = inA();
      for (final setting in [
        LibrarySetting.lineNumbers,
        LibrarySetting.editorAutofocus,
        LibrarySetting.reminderShowTokens,
      ]) {
        await a.overrideHere(setting);
      }
      await a.setLineNumbers(enabled: false);
      await a.setEditorAutofocus(enabled: true);
      await a.setReminderShowTokens(enabled: true);

      final fresh = inA();
      expect(await fresh.lineNumbers(), isFalse);
      expect(await fresh.editorAutofocus(), isTrue);
      expect(await fresh.reminderShowTokens(), isTrue);
      // The app is untouched by all of it.
      expect(await app.lineNumbersEnabled(), isTrue);
      expect(await app.editorAutofocusEnabled(), isFalse);
      expect(await app.reminderShowTokens(), isFalse);
    });

    test('enums', () async {
      final a = inA();
      await a.overrideHere(LibrarySetting.previewMode);
      await a.overrideHere(LibrarySetting.treeSort);
      await a.overrideHere(LibrarySetting.linkType);
      await a.setPreviewMode(PreviewLayoutMode.fullScreen);
      await a.setTreeSort(TreeSort.nameDesc);
      await a.setLinkType(LinkType.markdown);

      final fresh = inA();
      expect(await fresh.previewMode(), PreviewLayoutMode.fullScreen);
      expect(await fresh.treeSort(), TreeSort.nameDesc);
      expect(await fresh.linkType(), LinkType.markdown);
      expect(await inB().previewMode(), PreviewLayoutMode.auto);
    });

    test('numbers and text', () async {
      final a = inA();
      await a.overrideHere(LibrarySetting.splitRatio);
      await a.overrideHere(LibrarySetting.editorToolbar);
      await a.setSplitRatio(0.7);
      await a.setEditorToolbar('link,-bold');

      final fresh = inA();
      expect(await fresh.splitRatio(), 0.7);
      expect(await fresh.editorToolbar(), 'link,-bold');
      expect(await inB().editorToolbar(), '');
    });
  });

  group('the file is user-editable, so its values are inputs', () {
    test('an override that makes no sense reads as no override', () async {
      final store = LibraryConfigStore(libA.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync(
        '{"overrides": {"linkType": "wikilnk", "indentWidth": "four"}}',
      );
      await app.setLinkType(LinkType.markdown);
      await app.setIndentWidth(6);

      expect(await inA().linkType(), LinkType.markdown);
      expect(await inA().indentWidth(), 6);
    });

    test('an out-of-range number is brought into range', () async {
      final store = LibraryConfigStore(libA.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync('{"overrides": {"indentWidth": 400}}');
      expect(await inA().indentWidth(), 8);
    });

    test('a key this build does not know survives a write', () async {
      final store = LibraryConfigStore(libA.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync(
        '{"overrides": {"futureSetting": 1, "indentWidth": 4}}',
      );
      final a = inA();
      expect(await a.indentWidth(), 4);
      await a.setIndentWidth(6);
      expect(store.file.readAsStringSync(), contains('futureSetting'));
    });

    test('it is not counted among the settings this build overrides', () async {
      final store = LibraryConfigStore(libA.path);
      await store.file.create(recursive: true);
      store.file.writeAsStringSync('{"overrides": {"futureSetting": 1}}');
      expect(await inA().overridden(), isEmpty);
    });
  });

  test('with no library open everything reads and writes app-wide', () async {
    final none = noLibrary();
    await none.setIndentWidth(6);
    expect(await app.indentWidth(), 6);
    expect(await none.indentWidth(), 6);
    expect(await none.overridden(), isEmpty);
    // Nothing to override, and asking is not an error.
    await none.overrideHere(LibrarySetting.indentWidth);
    expect(await none.overridden(), isEmpty);
  });
}
