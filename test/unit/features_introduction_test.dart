// #1109: which introduction a library has still to show — the card of a
// library being created (a folder with no settings file when it was opened),
// the card of one that existed before the switches did, or none once
// `featuresReviewed` is in its settings — and that the flag is written by
// markFeaturesReviewed and by nothing else.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/feature_preset.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:path/path.dart' as p;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory root;
  late LibraryController controller;

  setUp(() async {
    tmp = await Directory.current.createTemp('niman_intro_');
    root = Directory(p.join(tmp.path, 'library'))..createSync();
    File(p.join(root.path, 'a.md')).writeAsStringSync('a');
    controller = LibraryController(
      () async =>
          AppDatabase(NativeDatabase(File(p.join(tmp.path, 'niman.db')))),
      indexDbFactory: (path) async => IndexDatabase(
        NativeDatabase(File(p.join(tmp.path, '${p.basename(path)}.db'))),
      ),
      rescanInterval: const Duration(hours: 1),
    );
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    await tmp.delete(recursive: true);
  });

  File settings() => File(p.join(root.path, '.niman', 'settings.json'));

  Map<String, Object?> settingsJson() =>
      jsonDecode(settings().readAsStringSync()) as Map<String, Object?>;

  test('a folder with no settings file is a library being created', () async {
    await controller.open(root.path, create: false);
    expect(controller.phase.name, 'ready');
    expect(await controller.featuresIntroduction, FeaturesIntroduction.created);
    // Asking writes nothing.
    expect(settings().existsSync(), isFalse);
  });

  test(
    'a library with settings and no flag existed before the switches',
    () async {
      Directory(p.join(root.path, '.niman')).createSync();
      settings().writeAsStringSync('{"trashEnabled": true}');
      await controller.open(root.path, create: false);
      expect(
        await controller.featuresIntroduction,
        FeaturesIntroduction.existing,
      );
      expect(settingsJson().containsKey('featuresReviewed'), isFalse);
    },
  );

  test('the flag in the settings means none', () async {
    Directory(p.join(root.path, '.niman')).createSync();
    settings().writeAsStringSync('{"featuresReviewed": true}');
    await controller.open(root.path, create: false);
    expect(await controller.featuresIntroduction, FeaturesIntroduction.none);
  });

  test('markFeaturesReviewed writes the flag, and only it', () async {
    await controller.open(root.path, create: false);
    await controller.markFeaturesReviewed();

    expect(await controller.featuresIntroduction, FeaturesIntroduction.none);
    expect(settingsJson()['featuresReviewed'], isTrue);
    expect(settingsJson().containsKey('features'), isFalse);
  });

  test('the flag survives a reopen, and a created library asks once', () async {
    await controller.open(root.path, create: false);
    await controller.markFeaturesReviewed();
    await controller.close();

    await controller.open(root.path, create: false);
    expect(await controller.featuresIntroduction, FeaturesIntroduction.none);
  });

  test('a library that was never marked asks again on its next open', () async {
    await controller.open(root.path, create: false);
    await controller.setFeatures(
      const Features().withPreset(FeaturePreset.notesOnly),
    );
    await controller.close();

    // The switches written, the screen never left: the file exists now, so
    // the card is the one a library with settings gets.
    await controller.open(root.path, create: false);
    expect(
      await controller.featuresIntroduction,
      FeaturesIntroduction.existing,
    );
    expect(
      controller.features.value,
      const Features().withPreset(FeaturePreset.notesOnly),
    );
  });
}
