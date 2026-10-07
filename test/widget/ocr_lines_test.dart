import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/range_highlight.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_line.dart';
import 'package:niman/src/ocr/ocr_placed_lines.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ocr/ocr_sidecar.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/ocr/ocr_line_layer.dart';
import 'package:niman/src/ui/ocr/ocr_lines_scope.dart';
import 'package:niman/src/ui/ocr/ocr_scan_text.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  OcrLine line(String text, double top, {bool paragraph = false}) => OcrLine(
    text,
    left: 0.1,
    top: top,
    right: 0.9,
    bottom: top + 0.05,
    paragraphStart: paragraph,
  );

  final sidecar = ocrSidecarText(
    fileName: 'scan.pdf',
    languages: 'ita+eng',
    date: DateTime(2026, 10, 7),
    paged: true,
    pages: {
      1: [line('First line', 0.1, paragraph: true), line('Second', 0.2)],
      2: [line('Lost one', 0.1, paragraph: true)],
    },
  );

  testWidgets('the lines of a page are targets; the picked one is tinted', (
    tester,
  ) async {
    final read = readOcrPlacedLines(sidecar);
    final selected = ValueNotifier<OcrPlacedLine?>(null);
    addTearDown(selected.dispose);
    final picked = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OcrLinesScope(
          lines: read,
          selected: selected,
          child: SizedBox(
            width: 400,
            height: 600,
            child: Builder(
              builder: (context) => Stack(
                children: ocrLineOverlays(
                  context,
                  const Rect.fromLTWH(0, 0, 400, 600),
                  1,
                  onPick: (line, _) {
                    picked.add(line.text);
                    selected.value = line;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final second = read.lines[1];
    final box = find.byKey(Key('ocr-line-${second.sourceLine}'));
    expect(find.byType(GestureDetector), findsNWidgets(2));
    expect(tester.getRect(box), const Rect.fromLTWH(40, 120, 320, 30));
    await tester.tap(box);
    await tester.pump();
    expect(picked, ['Second']);
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(of: box, matching: find.byType(DecoratedBox)),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.border, isNotNull);
  });

  testWidgets('a page whose lines lost their places is read again', (
    tester,
  ) async {
    final library = FakeLibrarySession();
    late OcrInstallation installation;
    late OcrQueue queue;
    final again = <(String, int, String)>[];
    await tester.runAsync(() async {
      await library.open('/fake/library', create: true);
      await library.createNote(
        parentPath: '',
        name: 'scan.ocr',
        // Page 2's line split by hand: its comment is on one half only.
        content: sidecar.replaceFirst('Lost one', 'Lost\none'),
      );
      installation = OcrInstallation(
        directory: () async => Directory.systemTemp.path,
        build: null,
        findInstalled: () async => null,
        probe: (_) async => null,
      );
      queue = OcrQueue(installation: installation);
    });
    addTearDown(() {
      queue.dispose();
      installation.dispose();
    });
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OcrScanText(
            actions: OcrFileActions(
              queue: queue,
              root: '/fake/library',
              ops: library,
              recognize: (path, {page, pageCount}) {},
              openNote: (_) {},
              recognizeAgain: (path, page, languages) => again.add((
                path,
                page,
                languages.map((l) => l.code).join('+'),
              )),
            ),
            path: '/fake/library/scan.pdf',
            scan: const Placeholder(),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.ocrLostPlaces(2, 1)), findsOne);
    expect(find.byKey(const Key('ocr-lost-1')), findsNothing);
    await tester.tap(find.byKey(const Key('ocr-recognize-again-2')));
    expect(again, [('scan.pdf', 2, 'ita+eng')]);
    // The pane marks nothing until a line is picked on the scan.
    expect(
      tester.widgetList<RangeHighlight>(find.byType(RangeHighlight)),
      isEmpty,
    );
  });
}
