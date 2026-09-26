// #266: the first-run welcome's state — the Markdown answer, the editors
// it seeds, and the tour's progress — and the rule that an existing
// library's own choice is never overwritten by it.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/device_settings_store.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:path/path.dart' as p;

void main() {
  group('the answer and the editors', () {
    test('never: the live editor alone, the source not offered', () {
      final defaults = editorDefaultsFor(MarkdownExperience.none);
      expect(defaults.kind, EditorKind.wysiwyg);
      expect(defaults.enabled, {EditorKind.wysiwyg});
    });

    test('a little: the live editor first, both offered', () {
      final defaults = editorDefaultsFor(MarkdownExperience.some);
      expect(defaults.kind, EditorKind.wysiwyg);
      expect(defaults.enabled, {EditorKind.source, EditorKind.wysiwyg});
    });

    test('all the time, and no answer: today\'s default, source first', () {
      for (final answer in [MarkdownExperience.fluent, null]) {
        final defaults = editorDefaultsFor(answer);
        expect(defaults.kind, EditorKind.source);
        expect(defaults.enabled, {EditorKind.source, EditorKind.wysiwyg});
      }
    });

    test('the stored ids round-trip, and a stranger reads as unanswered', () {
      for (final answer in MarkdownExperience.values) {
        expect(MarkdownExperience.fromId(answer.id), answer);
      }
      expect(MarkdownExperience.fromId(null), null);
      expect(MarkdownExperience.fromId('expert'), null);
    });
  });

  group('the database store', () {
    late AppDatabase db;
    late DbWelcomeStore store;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      store = DbWelcomeStore(AppSettingsRepo(db));
    });

    test('starts unseen, unanswered, untoured', () async {
      final state = await store.state();
      expect(state.deckSeen, isFalse);
      expect(state.experience, null);
      expect(state.tourSeen, isFalse);
      expect(state.tourStep, 0);
      expect(state.tourOffer, isFalse);
      expect(await store.firstLibraryEditorKeys(), null);
    });

    test('every field round-trips', () async {
      await store.setDeckSeen(seen: true);
      await store.setExperience(MarkdownExperience.some);
      await store.setTourOffer(offer: true);
      await store.setTourSeen(seen: true);
      await store.setTourStep(4);

      final state = await store.state();
      expect(state.deckSeen, isTrue);
      expect(state.experience, MarkdownExperience.some);
      expect(state.tourOffer, isTrue);
      expect(state.tourSeen, isTrue);
      expect(state.tourStep, 4);

      // And the answer becomes the two device keys.
      final keys = await store.firstLibraryEditorKeys();
      expect(keys, {
        'editorKind': 'wysiwyg',
        'enabledEditors': ['source', 'wysiwyg'],
      });
    });
  });

  group('the memory store', () {
    test('mirrors the database one', () async {
      final store = MemoryWelcomeStore();
      expect((await store.state()).deckSeen, isFalse);

      await store.setDeckSeen(seen: true);
      await store.setExperience(MarkdownExperience.none);
      expect((await store.state()).deckSeen, isTrue);
      expect(await store.firstLibraryEditorKeys(), {
        'editorKind': 'wysiwyg',
        'enabledEditors': ['wysiwyg'],
      });
    });
  });

  group('a library\'s first open on this device', () {
    late Directory library;
    late MemoryDeviceSettingsStore device;

    setUp(() async {
      library = await Directory.current.createTemp('niman_welcome_');
      device = MemoryDeviceSettingsStore();
    });

    tearDown(() => library.delete(recursive: true));

    Future<void> writeSettings(String json) async {
      final file = File(p.join(library.path, '.niman', 'settings.json'));
      await file.parent.create(recursive: true);
      await file.writeAsString(json);
    }

    test('takes the answer when the library says nothing', () async {
      final defaults = editorDefaultsFor(MarkdownExperience.none);
      final store = LibraryConfigStore(
        library.path,
        device: device,
        firstRunDefaults: LibraryConfig.editorDeviceKeys(
          kind: defaults.kind,
          enabled: defaults.enabled,
        ),
      );

      final config = await store.read();

      expect(config.editorKind, EditorKind.wysiwyg);
      expect(config.enabledEditors, {EditorKind.wysiwyg});
      // Written once, as the device's own: the next read is the stored
      // row, not the seed.
      expect(await device.read(library.path), isNotNull);
    });

    test('keeps the library\'s own editor when the file has one', () async {
      await writeSettings('{"editorKind": "source"}');
      final defaults = editorDefaultsFor(MarkdownExperience.none);
      final store = LibraryConfigStore(
        library.path,
        device: device,
        firstRunDefaults: LibraryConfig.editorDeviceKeys(
          kind: defaults.kind,
          enabled: defaults.enabled,
        ),
      );

      final config = await store.read();

      expect(
        config.editorKind,
        EditorKind.source,
        reason: 'a library with a choice of its own keeps it',
      );
      // The key the file did not carry still takes the answer.
      expect(config.enabledEditors, {EditorKind.wysiwyg});
    });

    test('with no answer, the defaults are today\'s', () async {
      final store = LibraryConfigStore(library.path, device: device);
      final config = await store.read();
      expect(config.editorKind, EditorKind.source);
      expect(config.enabledEditors, {EditorKind.source, EditorKind.wysiwyg});
    });
  });
}
