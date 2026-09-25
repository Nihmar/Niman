// The dialog a note's PDF export shows (#63): the note it is exporting,
// the pages the drawing fallback has done, and the one way to stop it.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/pdf_export_progress_dialog.dart';
import 'package:niman/src/export/pdf_printer.dart';

void main() {
  testWidgets('the dialog follows the export and cancels once', (tester) async {
    final progress = ValueNotifier<PdfExportProgress?>(
      const PdfExportProgress(stage: PdfExportStage.printing),
    );
    final done = Completer<void>();
    var cancelled = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => PdfExportProgressDialog(
                    title: 'Geometria 1',
                    progress: progress,
                    done: done.future,
                    onCancel: () => cancelled++,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pdf-export-progress')), findsOneWidget);
    expect(find.text('Geometria 1'), findsOneWidget);
    // While the engine prints there is no page count: a bar that moves on
    // its own.
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      isNull,
    );

    // The fallback reports pages as it draws them.
    progress.value = const PdfExportProgress(
      stage: PdfExportStage.drawing,
      done: 3,
      total: 10,
    );
    await tester.pump();
    expect(find.text('3 / 10'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.3,
    );

    await tester.tap(find.byKey(const Key('pdf-export-cancel')));
    await tester.pump();
    expect(cancelled, 1);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('pdf-export-cancel')))
          .onPressed,
      isNull,
    );

    done.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('pdf-export-progress')), findsNothing);
    progress.dispose();
  });
}
