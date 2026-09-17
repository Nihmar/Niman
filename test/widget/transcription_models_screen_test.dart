import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/transcription/model_state.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/transcription/transcription_models_screen.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late Directory dir;
  late TranscriptionModels models;
  final tiny = transcriptionModelById('tiny')!;
  final base = transcriptionModelById('base')!;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_models_screen_');
  });

  tearDown(() async {
    models.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  /// Real files and isolates: everything that touches them runs outside
  /// the fake clock.
  Future<void> real(WidgetTester tester, Future<void> Function() body) =>
      tester.runAsync(body);

  Future<void> loadWith(
    WidgetTester tester, {
    List<TranscriptionModel> installed = const [],
  }) => real(tester, () async {
    for (final model in installed) {
      await File(p.join(dir.path, model.fileName)).writeAsBytes([1, 2, 3]);
    }
    models = TranscriptionModels(directory: () async => dir.path, phone: true);
    await models.load();
  });

  testWidgets('groups the models and marks the default', (tester) async {
    await loadWith(tester, installed: [tiny]);
    await real(tester, () => models.setDefault(tiny));
    await tester.pumpWidget(
      MaterialApp(home: TranscriptionModelsScreen(models: models)),
    );
    await tester.pump();

    expect(find.text(AppStrings.transcriptionModelsInstalled), findsOne);
    expect(find.text(AppStrings.transcriptionModelsAvailable), findsOne);
    expect(find.text(AppStrings.transcriptionModelsDownloading), findsNothing);
    expect(find.text(AppStrings.transcriptionModelDefault), findsOne);
    expect(find.byKey(const Key('transcription-delete-tiny')), findsOne);
    expect(find.byKey(const Key('transcription-download-base')), findsOne);
    // A phone gets the warning on medium and no large-v3 at all.
    expect(find.text(AppStrings.transcriptionModelSlow), findsOne);
    expect(find.byKey(const Key('transcription-model-large-v3')), findsNothing);
  });

  testWidgets('deleting asks first, then moves the model back', (tester) async {
    await loadWith(tester, installed: [tiny, base]);
    await tester.pumpWidget(
      MaterialApp(home: TranscriptionModelsScreen(models: models)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('transcription-delete-base')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOne);

    await tester.tap(find.byKey(const Key('transcription-delete-confirm')));
    // The delete runs in an isolate: give it real time, and pump so its
    // result reaches the test's zone.
    for (var i = 0; i < 100 && models.stateOf(base) is ModelInstalled; i++) {
      await real(
        tester,
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(models.stateOf(base), isA<ModelAbsent>());
    expect(File(p.join(dir.path, base.fileName)).existsSync(), false);
    expect(find.byKey(const Key('transcription-download-base')), findsOne);
  });

  testWidgets('the settings section reads the model and the language', (
    tester,
  ) async {
    await loadWith(tester, installed: [base]);
    await real(tester, () => models.setDefault(base));
    final controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsBody(controller: controller, transcription: models),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The transcription section sits in the pushed Folders area
    // (issue #104).
    await tester.tap(find.byKey(const Key('settings-area-folders')));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.settingsSectionTranscription), findsOne);
    final modelRow = find.byKey(const Key('transcription-model-setting'));
    expect(
      find.descendant(of: modelRow, matching: find.text('Base')),
      findsOne,
    );
    final languageRow = find.byKey(const Key('transcription-language-setting'));
    expect(
      find.descendant(
        of: languageRow,
        matching: find.text(AppStrings.transcriptionLanguageApp('English')),
      ),
      findsOne,
    );

    await tester.ensureVisible(languageRow);
    await tester.tap(languageRow);
    await tester.pumpAndSettle();
    await real(tester, () async {
      await tester.tap(
        find.byKey(
          const Key('settings-choice-${TranscriptionSettings.detect}'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(models.settings.language, TranscriptionSettings.detect);
    expect(
      find.descendant(
        of: languageRow,
        matching: find.text(AppStrings.transcriptionLanguageDetect),
      ),
      findsOne,
    );
  });
}
