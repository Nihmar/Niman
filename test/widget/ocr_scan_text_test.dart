import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/ocr/ocr_file_controls.dart';
import 'package:niman/src/ui/ocr/ocr_result_sheet.dart';
import 'package:niman/src/ui/ocr/ocr_scan_text.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession library;
  late OcrInstallation installation;
  late OcrQueue queue;
  final opened = <String>[];

  const sidecar = '''
---
ocr: "[[scan.pdf]]"
language: eng
recognized: 2026-10-07
---

## p. 1

Recognized words <!-- ocr 0.100 0.100 0.500 0.130 -->
''';

  Future<void> setUpLibrary(WidgetTester tester, {bool withText = true}) =>
      tester.runAsync(() async {
        library = FakeLibrarySession();
        await library.open('/fake/library', create: true);
        if (withText) {
          await library.createNote(
            parentPath: '',
            name: 'scan.ocr',
            content: sidecar,
          );
        }
        installation = OcrInstallation(
          directory: () async => Directory.systemTemp.path,
          build: null,
          findInstalled: () async => null,
          probe: (_) async => null,
        );
        queue = OcrQueue(installation: installation);
      });

  tearDown(() {
    queue.dispose();
    installation.dispose();
    opened.clear();
  });

  OcrFileActions actions() => OcrFileActions(
    queue: queue,
    root: '/fake/library',
    ops: library,
    recognize: (path, {page, pageCount}) {},
    openNote: opened.add,
    recognizeAgain: (path, page, languages) {},
  );

  Future<void> show(WidgetTester tester, {required double width}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ocr = actions();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OcrScanText(
            actions: ocr,
            path: '/fake/library/scan.pdf',
            scan: Column(
              children: [
                const Expanded(child: Placeholder(key: Key('scan'))),
                OcrFileControls(actions: ocr, path: '/fake/library/scan.pdf'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('wide: the text beside the scan, hidden from the bar', (
    tester,
  ) async {
    await setUpLibrary(tester);
    await show(tester, width: 1200);
    expect(find.byKey(const Key('scan')), findsOne);
    expect(find.byKey(const Key('ocr-text-pane')), findsOne);
    expect(find.textContaining('Recognized words'), findsOne);
    expect(find.textContaining('<!--'), findsNothing);

    await tester.tap(find.byKey(const Key('ocr-text-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ocr-text-pane')), findsNothing);
    expect(find.byTooltip(AppStrings.ocrShowText), findsOne);

    await tester.tap(find.byKey(const Key('ocr-text-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ocr-open-as-note')));
    expect(opened, ['scan.ocr.md']);
  });

  testWidgets('narrow: a Scan | Text switch', (tester) async {
    await setUpLibrary(tester);
    await show(tester, width: 400);
    expect(find.byKey(const Key('ocr-scan-text-switch')), findsOne);
    expect(find.byKey(const Key('ocr-text-toggle')), findsNothing);
    await tester.tap(find.text(AppStrings.ocrTextTitle));
    await tester.pumpAndSettle();
    expect(find.textContaining('Recognized words'), findsOne);
  });

  testWidgets('a file with no text is just its scan', (tester) async {
    await setUpLibrary(tester, withText: false);
    await show(tester, width: 1200);
    expect(find.byKey(const Key('ocr-text-pane')), findsNothing);
    expect(find.byKey(const Key('ocr-scan-text-switch')), findsNothing);
    expect(find.byKey(const Key('ocr-text-toggle')), findsNothing);
  });

  testWidgets("a picture's text: copied, or opened", (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    await setUpLibrary(tester, withText: false);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showOcrResultSheet(
              context,
              words: 2,
              savedAs: 'assets/board.ocr.md',
              text: 'Sprint 14',
              onOpen: () => opened.add('board'),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.ocrRecognized(2)), findsOne);
    expect(find.text('Sprint 14'), findsOne);
    await tester.tap(find.byKey(const Key('ocr-result-copy')));
    await tester.pumpAndSettle();
    expect(copied, ['Sprint 14']);
    expect(find.byKey(const Key('ocr-result-sheet')), findsNothing);
  });
}
