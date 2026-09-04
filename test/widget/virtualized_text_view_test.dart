// Widget tests for the virtualized read-only view (M2a E2). The
// benchmark test prints timings (no assertions, house style for
// benchmarks: the flatness is read from the log).
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:copist/src/editor/line_buffer.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:copist/src/editor/virtualized_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String _fixture1mb = 'test/fixtures/markdown/fixture-1mb.md';

Widget _wrap(RowModel model, ScrollController? controller) {
  return MaterialApp(
    home: Scaffold(
      body: VirtualizedTextView(model: model, scrollController: controller),
    ),
  );
}

void main() {
  testWidgets('renders the buffer content', (tester) async {
    final buffer = LineBuffer.fromText('alpha\n${'b' * 60}\ngamma');
    final model = RowModel(buffer, columns: 30);
    await tester.pumpWidget(_wrap(model, null));
    await tester.pump();

    expect(find.text('alpha'), findsOneWidget);
    // The 60-char line wraps into two identical 30-char rows.
    expect(find.text('b' * 30), findsNWidgets(2));
    expect(find.text('gamma'), findsOneWidget);
  });

  testWidgets('renders only viewport-bounded rows of a 1 MB buffer', (
    tester,
  ) async {
    final text = File(_fixture1mb).readAsStringSync();
    final buffer = LineBuffer.fromText(text);
    final model = RowModel(buffer, columns: 60);
    await tester.pumpWidget(_wrap(model, null));
    await tester.pump();

    // The default test surface is 800x600: ~28 rows at 21 px each.
    expect(model.rowCount, greaterThan(10000));
    final built = find.byType(Text).evaluate().length;
    expect(built, greaterThan(20));
    expect(built, lessThan(100));
  });

  testWidgets('scrolling to the end shows the last rows', (tester) async {
    final text = File(_fixture1mb).readAsStringSync();
    final buffer = LineBuffer.fromText(text);
    final model = RowModel(buffer, columns: 60);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_wrap(model, controller));
    await tester.pump();

    var line = buffer.lineCount - 1;
    while (line > 0 && buffer.lineAt(line).isEmpty) {
      line--;
    }
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    expect(find.text(buffer.lineAt(line)), findsWidgets);
    final built = find.byType(Text).evaluate().length;
    expect(built, lessThan(100));
  });

  // Benchmark for the M2a E2 acceptance criterion: steady-state per-frame
  // cost is flat in the buffer size.
  testWidgets('benchmark: frame cost is flat vs buffer size', (tester) async {
    for (final label in ['200KB', '1MB']) {
      final path = label == '1MB'
          ? _fixture1mb
          : 'test/fixtures/markdown/fixture-200kb.md';
      final text = File(path).readAsStringSync();
      final buffer = LineBuffer.fromText(text);
      final model = RowModel(buffer, columns: 60);
      final controller = ScrollController();
      await tester.pumpWidget(_wrap(model, controller));
      await tester.pump();
      final sw = Stopwatch()..start();
      for (var i = 1; i <= 10; i++) {
        controller.jumpTo(
          controller.position.maxScrollExtent * (i / 10),
        );
        await tester.pump();
      }
      sw.stop();
      print(
        '  virtualized scroll x10: ${label.padRight(5)} '
        '${(sw.elapsedMicroseconds / 1000.0 / 10).toStringAsFixed(2)} ms/step',
      );
      controller.dispose();
    }
  });
}
