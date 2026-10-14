// #712: an export's progress holds the window on a phone, and on a desktop
// is a card in its corner that holds nothing, gone when the export is.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_progress_host.dart';
import 'package:niman/src/export/export_working_dialog.dart';

void main() {
  Future<Completer<void>> start(
    WidgetTester tester, {
    required bool dense,
  }) async {
    final done = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showExportProgress(
              context,
              done: done.future,
              build: (context, {required modal}) => ExportWorkingDialog(
                title: 'note',
                done: done.future,
                closeOnDone: modal,
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    return done;
  }

  testWidgets('a desktop gets a card that leaves the window free', (
    tester,
  ) async {
    final done = await start(tester, dense: true);
    expect(find.byKey(const Key('export-progress-card')), findsOne);
    expect(find.byType(ModalBarrier), findsOne, reason: "the page's own");
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(
      find.byKey(const Key('export-progress-card')),
      findsNWidgets(2),
      reason: 'the button under it still answers',
    );
    done.complete();
    await tester.pump();
    expect(find.byKey(const Key('export-progress-card')), findsNothing);
  });

  testWidgets('a phone gets the dialog', (tester) async {
    final done = await start(tester, dense: false);
    expect(find.byKey(const Key('export-progress-card')), findsNothing);
    expect(find.byKey(const Key('export-working')), findsOne);
    done.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('export-working')), findsNothing);
  });
}
