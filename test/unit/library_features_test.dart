// #1109: the library's features — the switches, their dependencies, the
// presets, and how they live in `.niman/settings.json`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_features.dart';

void main() {
  Set<LibraryFeature> on(Features features) => {
    for (final feature in LibraryFeature.values)
      if (features.own(feature)) feature,
  };

  group('the ids', () {
    test('are the ones settings.json stores, each once', () {
      expect(
        [for (final feature in LibraryFeature.values) feature.id],
        [
          'search',
          'quickNote',
          'templates',
          'capture',
          'todo',
          'journal',
          'calendar',
          'kinds.list',
          'kinds.shopping',
          'kinds.audio',
          'transcription',
          'kinds.slides',
          'kinds.flashcards',
          'readers',
          'annotations',
          'ocr',
          'home',
          'widgets',
        ],
      );
    });

    test('are found again, and an unknown one is not', () {
      for (final feature in LibraryFeature.values) {
        expect(LibraryFeature.fromId(feature.id), feature);
      }
      expect(LibraryFeature.fromId('study'), isNull);
    });

    test('name the three dependencies, and no other', () {
      expect(
        {
          for (final feature in LibraryFeature.values)
            if (feature.parent case final parent?) feature.id: parent.id,
        },
        {
          'kinds.shopping': 'kinds.list',
          'transcription': 'kinds.audio',
          'annotations': 'readers',
        },
      );
    });
  });

  group('Features', () {
    test('an empty value has every feature on', () {
      const features = Features();
      for (final feature in LibraryFeature.values) {
        expect(features.own(feature), isTrue, reason: feature.id);
        expect(features.isOn(feature), isTrue, reason: feature.id);
      }
    });

    test('an id missing from the map reads as on', () {
      const features = Features({'todo': false});
      expect(features.own(LibraryFeature.todo), isFalse);
      expect(features.own(LibraryFeature.journal), isTrue);
    });

    test('a switch changes only itself', () {
      final features = const Features().withSwitch(
        LibraryFeature.ocr,
        on: false,
      );
      expect(
        on(features),
        {...LibraryFeature.values}..remove(LibraryFeature.ocr),
      );
      expect(
        features.withSwitch(LibraryFeature.ocr, on: true),
        const Features(),
      );
    });

    test('a child keeps its own value under a parent that is off', () {
      final features = const Features().withSwitch(
        LibraryFeature.kindAudio,
        on: false,
      );
      expect(features.own(LibraryFeature.transcription), isTrue);
      expect(features.isOn(LibraryFeature.transcription), isFalse);
      expect(features.isOn(LibraryFeature.kindAudio), isFalse);
      // Back on: the child is as it was.
      final back = features.withSwitch(LibraryFeature.kindAudio, on: true);
      expect(back.isOn(LibraryFeature.transcription), isTrue);
    });

    test('a child that is off stays off under a parent that is on', () {
      final features = const Features().withSwitch(
        LibraryFeature.annotations,
        on: false,
      );
      expect(features.isOn(LibraryFeature.readers), isTrue);
      expect(features.isOn(LibraryFeature.annotations), isFalse);
    });

    test('a parent is not turned off by its child', () {
      final features = const Features().withSwitch(
        LibraryFeature.transcription,
        on: false,
      );
      expect(features.isOn(LibraryFeature.kindAudio), isTrue);
    });

    test('writes only the switches that are off', () {
      expect(const Features().toJson(), isEmpty);
      // An explicit on is the default: it is not written.
      expect(const Features({'search': true}).toJson(), isEmpty);
      expect(
        const Features().withSwitch(LibraryFeature.todo, on: false).toJson(),
        {'todo': false},
      );
    });

    test('keeps the ids this build does not know, and writes them back', () {
      final features = Features.fromJson(const {
        'study': false,
        'future': true,
        'todo': false,
      });
      expect(features.own(LibraryFeature.todo), isFalse);
      expect(features.toJson(), {
        'todo': false,
        'future': true,
        'study': false,
      });
      // A switch changed here leaves them where they were.
      final changed = features.withSwitch(LibraryFeature.search, on: false);
      expect(changed.toJson(), {
        'search': false,
        'todo': false,
        'future': true,
        'study': false,
      });
      expect(features.withPreset(FeaturePreset.everything).toJson(), {
        'future': true,
        'study': false,
      });
    });

    test('reads anything but an object as every feature on', () {
      for (final json in <Object?>[
        null,
        'off',
        3,
        true,
        <Object?>['todo'],
      ]) {
        expect(Features.fromJson(json), const Features(), reason: '$json');
      }
    });

    test('drops a switch that is not a boolean', () {
      final features = Features.fromJson(const {
        'todo': 'no',
        'journal': false,
      });
      expect(features.own(LibraryFeature.todo), isTrue);
      expect(features.own(LibraryFeature.journal), isFalse);
    });

    test('compares by what is on, not by how the map was spelled', () {
      expect(const Features({'search': true}), const Features());
      expect(
        const Features({'search': true}).hashCode,
        const Features().hashCode,
      );
      expect(
        Features.fromJson(const {'todo': false, 'home': false}),
        Features.fromJson(const {'home': false, 'todo': false}),
      );
      expect(
        Features.fromJson(const {'todo': false, 'home': false}).hashCode,
        Features.fromJson(const {'home': false, 'todo': false}).hashCode,
      );
      expect(const Features({'todo': false}), isNot(const Features()));
      expect(
        const Features({'future': true}),
        isNot(const Features()),
        reason: 'an id kept is part of the value',
      );
    });
  });

  group('the presets', () {
    test('Everything is every feature on', () {
      expect(on(const Features().withPreset(FeaturePreset.everything)), {
        ...LibraryFeature.values,
      });
    });

    test('Writing is search, templates and the readers', () {
      expect(on(const Features().withPreset(FeaturePreset.writing)), {
        LibraryFeature.search,
        LibraryFeature.templates,
        LibraryFeature.readers,
      });
    });

    test('Notes only is search', () {
      expect(on(const Features().withPreset(FeaturePreset.notesOnly)), {
        LibraryFeature.search,
      });
    });

    test('Tasks and journal is todo, journal, calendar and Home', () {
      expect(on(const Features().withPreset(FeaturePreset.tasksAndJournal)), {
        LibraryFeature.todo,
        LibraryFeature.journal,
        LibraryFeature.calendar,
        LibraryFeature.home,
      });
    });

    test('a preset only writes switches, over whatever was there', () {
      final custom = const Features()
          .withSwitch(LibraryFeature.todo, on: false)
          .withSwitch(LibraryFeature.ocr, on: false);
      final applied = custom.withPreset(FeaturePreset.everything);
      expect(applied, const Features());
      expect(applied.toJson(), isEmpty);
    });

    test('presetOf answers the preset the switches match', () {
      for (final preset in FeaturePreset.values) {
        expect(
          FeaturePreset.of(const Features().withPreset(preset)),
          preset,
          reason: preset.name,
        );
      }
      expect(FeaturePreset.of(const Features()), FeaturePreset.everything);
    });

    test('presetOf answers null, Custom, for switches that match none', () {
      final custom = const Features()
          .withPreset(FeaturePreset.notesOnly)
          .withSwitch(LibraryFeature.ocr, on: true);
      expect(FeaturePreset.of(custom), isNull);
      expect(
        FeaturePreset.of(
          const Features().withSwitch(LibraryFeature.home, on: false),
        ),
        isNull,
      );
    });

    test('presetOf reads the own switches, not the effective ones', () {
      // Audio off with Transcription on matches nothing, though both read
      // as off.
      final features = const Features()
          .withPreset(FeaturePreset.notesOnly)
          .withSwitch(LibraryFeature.transcription, on: true);
      expect(FeaturePreset.of(features), isNull);
    });

    test('presetOf is not affected by ids this build does not know', () {
      final features = Features.fromJson(const {'study': false})
          .withPreset(FeaturePreset.writing);
      expect(FeaturePreset.of(features), FeaturePreset.writing);
    });
  });

  group('in LibraryConfig', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.current.createTemp('niman_features_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) await tempDir.delete(recursive: true);
    });

    Future<LibraryConfigStore> store() async {
      final lib = await tempDir.createTemp('lib_');
      return LibraryConfigStore(lib.path);
    }

    Map<String, Object?> written(LibraryConfigStore store) =>
        jsonDecode(store.file.readAsStringSync()) as Map<String, Object?>;

    test('a config with no features key has every feature on, unreviewed', () {
      final config = LibraryConfig.fromJsonMap(const {});
      expect(config.features, const Features());
      expect(config.featuresReviewed, isFalse);
      expect(config, LibraryConfig.defaults);
    });

    test('a library with no features key writes none', () async {
      final s = await store();
      await s.write(LibraryConfig.defaults);
      final json = written(s);
      expect(json.containsKey('features'), isFalse);
      expect(json.containsKey('featuresReviewed'), isFalse);
      // Read and written back, the file is the same bytes.
      final before = s.file.readAsStringSync();
      await s.write(await s.read());
      expect(s.file.readAsStringSync(), before);
    });

    test(
      'a settings.json from before the keys is rewritten as it was',
      () async {
        final s = await store();
        await s.write(LibraryConfig.defaults);
        final before = s.file.readAsStringSync();
        final config = await s.read();
        expect(await s.write(config), isFalse, reason: 'nothing to write');
        expect(s.file.readAsStringSync(), before);
      },
    );

    test('the switches that are off survive a round trip', () async {
      final s = await store();
      final features = const Features()
          .withSwitch(LibraryFeature.todo, on: false)
          .withSwitch(LibraryFeature.kindAudio, on: false);
      await s.write(
        LibraryConfig.defaults.copyWith(
          features: features,
          featuresReviewed: true,
        ),
      );
      expect(written(s)['features'], {'kinds.audio': false, 'todo': false});
      expect(written(s)['featuresReviewed'], isTrue);
      final config = await s.read();
      expect(config.features, features);
      expect(config.featuresReviewed, isTrue);
      expect(config.features.isOn(LibraryFeature.transcription), isFalse);
      expect(config.features.own(LibraryFeature.transcription), isTrue);
    });

    test('ids this build does not know survive the file', () async {
      final s = await store();
      s.file.parent.createSync(recursive: true);
      s.file.writeAsStringSync(
        jsonEncode({
          'features': {'study': false, 'todo': false},
          'featuresReviewed': true,
          'somethingElse': 1,
        }),
      );
      final config = await s.read();
      expect(config.features.own(LibraryFeature.todo), isFalse);
      // Changing a switch writes the unknown id back.
      await s.write(
        config.copyWith(
          features: config.features.withSwitch(LibraryFeature.home, on: false),
        ),
      );
      expect(written(s)['features'], {
        'home': false,
        'todo': false,
        'study': false,
      });
      expect(written(s)['somethingElse'], 1);
    });

    test('features is a library key: it goes in the shared file', () {
      final config = LibraryConfig.defaults.copyWith(
        features: const Features({'search': false}),
        featuresReviewed: true,
      );
      expect(
        config.libraryJsonMap(),
        containsPair('features', {'search': false}),
      );
      expect(config.libraryJsonMap(), containsPair('featuresReviewed', true));
      expect(config.deviceJsonMap().containsKey('features'), isFalse);
      expect(config.deviceJsonMap().containsKey('featuresReviewed'), isFalse);
    });

    test('equality and copyWith follow the two fields', () {
      const off = Features({'search': false});
      final config = LibraryConfig.defaults.copyWith(features: off);
      expect(config, isNot(LibraryConfig.defaults));
      expect(config.hashCode, isNot(LibraryConfig.defaults.hashCode));
      expect(config, LibraryConfig.defaults.copyWith(features: off));
      expect(
        config.copyWith(features: const Features()),
        LibraryConfig.defaults,
      );
      final reviewed = LibraryConfig.defaults.copyWith(featuresReviewed: true);
      expect(reviewed, isNot(LibraryConfig.defaults));
      expect(reviewed.copyWith().featuresReviewed, isTrue);
      expect(config.copyWith(featuresReviewed: true).features, off);
    });

    test('the keys are not handed back as unknown ones', () {
      final config = LibraryConfig.fromJsonMap(const {
        'features': {'todo': false},
        'featuresReviewed': true,
      });
      expect(config.extra, isEmpty);
    });

    test('the repo lets listeners follow the features', () async {
      final lib = await tempDir.createTemp('lib_');
      final repo = LibraryConfigRepo(lib.path);
      final seen = <Features>[];
      repo.features.addListener(() => seen.add(repo.features.value));
      expect(repo.features.value, const Features());

      // The first read publishes the file's value; defaults change nothing.
      await repo.config;
      expect(seen, isEmpty);

      const off = Features({'todo': false});
      await repo.update((c) => c.copyWith(features: off));
      expect(repo.features.value, off);
      expect(seen, [off]);

      // A write that changes no feature does not notify.
      await repo.update((c) => c.copyWith(featuresReviewed: true));
      expect(seen, [off]);

      // The file replaced from outside (a sync download), then reloaded.
      LibraryConfigStore(lib.path).file.writeAsStringSync(
        jsonEncode({
          'features': {'home': false},
        }),
      );
      await repo.reload();
      expect(repo.features.value, const Features({'home': false}));
      expect(seen, [
        off,
        const Features({'home': false}),
      ]);
    });
  });
}
