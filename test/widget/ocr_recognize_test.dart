import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_job.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_line.dart';
import 'package:niman/src/ocr/ocr_page_source.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/ocr/ocr_job_status.dart';
import 'package:niman/src/ui/ocr/recognize_text_sheet.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late Directory dir;
  late OcrInstallation ocr;
  final eng = ocrLanguageByCode('eng')!;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_ocr_ui_');
  });

  tearDown(() async {
    ocr.dispose();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<void> load(WidgetTester tester, {bool englishInstalled = true}) =>
      tester.runAsync(() async {
        if (englishInstalled) {
          File(p.join(dir.path, eng.file(OcrQuality.fast)!.fileName))
            ..parent.createSync(recursive: true)
            ..writeAsBytesSync([1]);
        }
        ocr = OcrInstallation(
          directory: () async => dir.path,
          build: null,
          findInstalled: () async => (
            name: 'libtesseract.so.5',
            source: OcrEngineSource.system,
            version: '5.5.3',
          ),
          probe: (_) async => '5.5.3',
        );
        await ocr.load();
      });

  Future<OcrRequest?> ask(
    WidgetTester tester, {
    int? pageCount,
    int? page,
    Future<void> Function()? choose,
  }) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final answer = Completer<OcrRequest?>();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answer.complete(
              await showRecognizeTextSheet(
                context,
                installation: ocr,
                path: 'Contratti/scan.pdf',
                pageCount: pageCount,
                page: page,
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await choose?.call();
    await tester.tap(find.byKey(const Key('recognize-start')));
    await tester.pumpAndSettle();
    return await answer.future;
  }

  testWidgets('says where the text goes, and asks for every page', (
    tester,
  ) async {
    await load(tester);
    final request = await ask(
      tester,
      pageCount: 4,
      page: 2,
      choose: () async {
        expect(find.text('Contratti / scan.ocr.md'), findsOne);
        expect(find.text(AppStrings.ocrPagesAll(4)), findsOne);
        expect(find.text(AppStrings.ocrPagesThis(2)), findsOne);
        // English is on the device: nothing to download first.
        expect(find.byKey(const Key('recognize-download')), findsNothing);
        expect(find.text(AppStrings.ocrRecognizeAction), findsWidgets);
      },
    );
    expect(request!.languages, [eng]);
    expect(request.pages, isNull);
  });

  testWidgets('this page, a second language, and what it downloads', (
    tester,
  ) async {
    await load(tester);
    final request = await ask(
      tester,
      pageCount: 4,
      page: 2,
      choose: () async {
        await tester.tap(find.byKey(const Key('recognize-pages-current')));
        await tester.tap(find.byKey(const Key('recognize-also')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Afrikaans').last);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('recognize-download')), findsOne);
        expect(find.text(AppStrings.ocrDownloadAndRecognize), findsOne);
      },
    );
    expect(request!.languages, [eng, ocrLanguageByCode('afr')]);
    expect(request.pages, [2]);
  });

  testWidgets('a range of pages, clamped to the document', (tester) async {
    await load(tester);
    final request = await ask(
      tester,
      pageCount: 4,
      choose: () async {
        await tester.enterText(find.byKey(const Key('recognize-from')), '3');
        await tester.enterText(find.byKey(const Key('recognize-to')), '9');
        await tester.pump();
      },
    );
    expect(request!.pages, [3, 4]);
  });

  testWidgets('a picture asks no pages', (tester) async {
    await load(tester);
    final request = await ask(
      tester,
      choose: () async {
        expect(find.byKey(const Key('recognize-pages-all')), findsNothing);
      },
    );
    expect(request!.pages, isNull);
  });

  testWidgets('a job in progress shows its page, and cancels', (tester) async {
    await load(tester);
    final hold = Completer<void>();
    late OcrQueue queue;
    final library = FakeLibrarySession();
    await tester.runAsync(() async {
      await library.open('/fake/library', create: true);
    });
    queue = OcrQueue(
      installation: ocr,
      openPages: (_) async => (
        count: 3,
        render: (int page) async => throw UnimplementedError(),
        close: () async {},
      ),
      startRecognizer:
          ({required engine, required datapath, required languages}) async {
            await hold.future;
            return (
              recognize: (OcrPixels _) async => const <OcrLine>[],
              close: () {},
            );
          },
    );
    addTearDown(queue.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OcrJobStatus(queue: queue),
              OcrJobStatus(queue: queue, path: 'scan.pdf'),
            ],
          ),
        ),
      ),
    );
    final job = queue.enqueue(
      path: 'scan.pdf',
      languages: [eng],
      writer: (
        root: '/fake/library',
        ops: library,
        before: () async {},
        after: (_) {},
      ),
    );
    // The job scans the downloads first, on a real isolate (#606): let its
    // reply in, then run what it completes, until the pages start.
    for (var i = 0; i < 500 && job.phase != OcrJobPhase.recognizing; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pump();
    expect(find.text(AppStrings.ocrRecognizing(1, 3)), findsNWidgets(2));
    expect(find.byKey(const Key('ocr-strip')), findsOne);
    expect(find.text('scan.pdf'), findsOne);
    await tester.tap(find.byKey(Key('ocr-cancel-${job.id}')).first);
    hold.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ocr-strip')), findsNothing);
    expect(find.byKey(const Key('ocr-job-status')), findsNothing);
  });
}
