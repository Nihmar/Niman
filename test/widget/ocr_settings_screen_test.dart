import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/ocr/ocr_engine_build.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late Directory dir;
  late OcrInstallation ocr;
  final itaFast = ocrLanguageByCode('ita')!.file(OcrQuality.fast)!;
  const system = (
    name: 'libtesseract.so.5',
    source: OcrEngineSource.system,
    version: '5.4.1',
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_ocr_screen_');
  });

  tearDown(() async {
    ocr.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  /// Real files and isolates run outside the fake clock.
  Future<void> real(WidgetTester tester, Future<void> Function() body) =>
      tester.runAsync(body);

  Future<void> open(
    WidgetTester tester, {
    OcrEngineBuild? build,
    OcrEngineLibrary? installed,
  }) async {
    await real(tester, () async {
      File(p.join(dir.path, itaFast.fileName))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);
      ocr = OcrInstallation(
        directory: () async => dir.path,
        build: build,
        findInstalled: () async => installed,
        probe: (_) async => '5.5.3',
      );
      await ocr.load();
    });
    final controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
    tester.view.physicalSize = const Size(900, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsBody(controller: controller, ocr: ocr),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final area = find.byKey(const Key('settings-area-text-recognition'));
    await tester.ensureVisible(area);
    await tester.tap(area);
    await tester.pumpAndSettle();
  }

  testWidgets('the page lists the engine, the choices and the languages', (
    tester,
  ) async {
    await open(tester, installed: system);

    expect(find.text(AppStrings.settingsSectionTextRecognition), findsWidgets);
    expect(find.byKey(const Key('ocr-engine-installed')), findsOne);
    expect(find.text(AppStrings.ocrEngineSystem), findsOne);
    expect(find.text(AppStrings.ocrEngineName('5.4.1')), findsOne);
    final language = find.byKey(const Key('ocr-language-setting'));
    expect(
      find.descendant(of: language, matching: find.text('English')),
      findsOne,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('ocr-also-setting')),
        matching: find.text(AppStrings.ocrAlsoNone),
      ),
      findsOne,
    );
    expect(find.byKey(const Key('ocr-delete-fast/ita')), findsOne);
    expect(find.text(AppStrings.ocrOnDevice(AppStrings.byteSize(3))), findsOne);
    expect(find.byKey(const Key('ocr-download-fast/fra')), findsOne);
  });

  testWidgets('search narrows the languages to download', (tester) async {
    await open(tester, installed: system);
    await tester.enterText(
      find.byKey(const Key('ocr-language-search')),
      'germ',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ocr-download-fast/deu')), findsOne);
    expect(find.byKey(const Key('ocr-download-fast/fra')), findsNothing);
    // The languages on the device stay listed whatever the search.
    expect(find.byKey(const Key('ocr-delete-fast/ita')), findsOne);
  });

  testWidgets('an engine to download, or none for this device', (tester) async {
    await open(
      tester,
      build: const OcrEngineBuild('linux-x64', bytes: 2000000, sha256: 'x'),
    );
    expect(find.byKey(const Key('ocr-download-engine')), findsOne);
    expect(find.byKey(const Key('ocr-engine-unavailable')), findsNothing);
  });

  testWidgets('no build and no engine says so', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('ocr-engine-unavailable')), findsOne);
  });

  testWidgets('Best lists its own languages and is saved', (tester) async {
    await open(tester, installed: system);
    await tester.tap(find.text(AppStrings.ocrQualityBest));
    await tester.pumpAndSettle();
    expect(ocr.settings.quality, OcrQuality.best);
    expect(find.byKey(const Key('ocr-delete-fast/ita')), findsNothing);
    expect(find.byKey(const Key('ocr-download-best/ita')), findsOne);
    await real(tester, () async {
      final saved = await File(
        p.join(dir.path, OcrInstallation.settingsFileName),
      ).readAsString();
      expect(saved, contains('"best"'));
    });
  });

  testWidgets('"Also" picks a second language and dismissing keeps it', (
    tester,
  ) async {
    await open(tester, installed: system);
    final also = find.byKey(const Key('ocr-also-setting'));
    await tester.tap(also);
    await tester.pumpAndSettle();
    await real(tester, () async {
      await tester.tap(find.byKey(const Key('settings-choice-ita')));
    });
    await tester.pumpAndSettle();
    expect(ocr.settings.also, 'ita');

    await tester.tap(also);
    await tester.pumpAndSettle();
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    expect(ocr.settings.also, 'ita');
  });

  testWidgets('deleting a language asks first', (tester) async {
    await open(tester, installed: system);
    await tester.tap(find.byKey(const Key('ocr-delete-fast/ita')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.ocrLanguageDeleteTitle('Italiano')), findsOne);
    await tester.tap(find.byKey(const Key('ocr-delete-confirm')));
    // The delete runs in an isolate: give it real time, and pump so its
    // result reaches the test's zone.
    for (var i = 0; i < 100 && ocr.stateOf(itaFast) is Downloaded; i++) {
      await real(
        tester,
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(File(p.join(dir.path, itaFast.fileName)).existsSync(), isFalse);
    // Back among those to download (the list is lazy: narrow it first).
    await tester.enterText(
      find.byKey(const Key('ocr-language-search')),
      'ital',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ocr-download-fast/ita')), findsOne);
  });
}
