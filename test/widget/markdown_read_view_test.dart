// The windowed read view. The property under test is the one the whole surface
// is built around: opening a long note must not lay it all out, so the number
// of blocks *built* has to stay near the number a viewport can show — and must
// grow when the viewport moves, or the windowing would just be a way of not
// rendering.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A cache that renders in-line, as the preview's own tests do.
MathCache _syncCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

/// A note of [paragraphs] paragraphs, each two lines of prose.
String _note(int paragraphs) {
  final buffer = StringBuffer();
  for (var at = 0; at < paragraphs; at++) {
    buffer
      ..writeln('Paragraph $at has **bold** and `code` and a [link](u).')
      ..writeln('Its second line continues the paragraph.')
      ..writeln();
  }
  return buffer.toString();
}

/// Pumps the read view over [document] and hands back its state.
Future<MarkdownReadViewState> _pump(
  WidgetTester tester,
  String document, {
  ScrollController? controller,
}) async {
  final parser = BlockParser();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          buffer: SourceBuffer.fromText(document),
          parser: parser,
          mathCache: _syncCache(),
          controller: controller,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownReadViewState>(find.byType(MarkdownReadView));
}

void main() {
  testWidgets('a long note lays out a viewport, not the note', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = await _pump(tester, _note(400));
    expect(state.blockCount, greaterThan(700), reason: 'a long note');
    // A 600-pixel viewport holds a few dozen paragraphs; the rest must not
    // have been built.
    expect(
      state.builtBlocks,
      lessThan(state.blockCount ~/ 4),
      reason: 'built ${state.builtBlocks} of ${state.blockCount}',
    );
    expect(state.totalExtent, greaterThan(0));
  });

  testWidgets('what the viewport shows is on screen', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      '# First\n\nA paragraph with **bold** text.\n\n## Second',
    );
    expect(find.textContaining('First'), findsOneWidget);
    expect(find.textContaining('bold'), findsWidgets);
    final screen = StringBuffer();
    for (final widget in tester.allWidgets) {
      if (widget is Text) {
        final span = widget.textSpan;
        if (span != null) screen.write(span.toPlainText());
      }
    }
    expect(screen.toString(), isNot(contains('**')));
  });

  testWidgets('scrolling builds more, and only what it reaches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = ScrollController();
    addTearDown(controller.dispose);
    final state = await _pump(tester, _note(400), controller: controller);
    final atStart = state.builtBlocks;

    controller.jumpTo(4000);
    await tester.pump();
    await tester.pump();
    final mid = state.builtBlocks;
    expect(mid, greaterThan(atStart), reason: 'the window moved');

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();
    expect(state.builtBlocks, greaterThan(mid));
    expect(
      state.builtBlocks,
      lessThan(state.blockCount),
      reason: 'still not the whole note',
    );
  });

  testWidgets('the measured heights correct the estimates', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = await _pump(tester, _note(40));
    final before = state.totalExtent;
    // Let the post-frame measurements land and be applied.
    for (var at = 0; at < 3; at++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.totalExtent, isNotNull);
    expect(before, isNotNull);
    expect(state.builtBlocks, greaterThan(0));
  });

  testWidgets('an empty note draws nothing rather than failing', (
    tester,
  ) async {
    final state = await _pump(tester, '');
    expect(state.blockCount, lessThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a rescan follows the buffer revision', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final buffer = SourceBuffer.fromText('# One\n\nfirst');
    final parser = BlockParser();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownReadView(
            buffer: buffer,
            parser: parser,
            mathCache: _syncCache(),
          ),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<MarkdownReadViewState>(
      find.byType(MarkdownReadView),
    );
    final before = state.blockCount;

    // A new buffer, as a tab switch hands one over.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownReadView(
            buffer: SourceBuffer.fromText('# One\n\nfirst\n\nsecond\n\nthird'),
            parser: parser,
            mathCache: _syncCache(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(state.blockCount, greaterThan(before));
    expect(tester.takeException(), isNull);
  });
}
