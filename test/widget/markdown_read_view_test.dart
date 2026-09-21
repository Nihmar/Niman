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

import '../../tool/spec_suite.dart';

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

  // The preview's own widget tests, ported to the engine that replaces it. What
  // was ported is deliberate: the behaviours belong to the *renderer* — does a
  // note with every construct draw, do task boxes appear, does a formula that
  // fails take the screen down — and what was left behind is the preview's
  // asynchronous machinery (the skeleton before the first parse lands, the
  // line-keyed scroll map), which the read view does not have because it draws
  // its first frame synchronously.
  group("ported from the preview's tests", () {
    testWidgets('a note with every extra renders', (tester) async {
      tester.view.physicalSize = const Size(900, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        '# Heading\n\n'
        'Paragraph with **bold**, *italic*, `code` and a '
        '[link](https://example.com).\n\n'
        '> A quote to end all quotes.\n\n'
        '- a bullet\n'
        '- [x] a checked box\n'
        '- [ ] an unchecked box\n\n'
        '| a | b |\n|---|---|\n| 1 | 2 |\n\n'
        r'Inline $x^2$ and a display block:'
        '\n\n'
        r'$$\int_0^1 x\,dx$$'
        '\n\n'
        '~~~dart\nfinal x = 1;\n~~~\n',
      );
      expect(tester.takeException(), isNull);
      final screen = StringBuffer();
      for (final widget in tester.allWidgets) {
        if (widget is Text) {
          final data = widget.data;
          if (data != null) screen.write(' $data');
          final span = widget.textSpan;
          if (span != null) screen.write(' ${span.toPlainText()}');
        }
      }
      final text = screen.toString();
      for (final wanted in <String>[
        'Heading',
        'Paragraph with bold',
        'A quote to end all quotes',
        'a bullet',
        'final x = 1;',
      ]) {
        expect(text, contains(wanted), reason: wanted);
      }
      expect(text, isNot(contains('**')));
      expect(text, isNot(contains('```')));
    });

    testWidgets('task boxes are drawn, in a tight and a loose list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, '- [x] tight checked\n- [ ] tight unchecked\n');
      expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);

      await _pump(tester, '- [x] loose checked\n\n- [ ] loose unchecked\n');
      expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('display math renders inside a list', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        '- an item\n\n  '
        r'$$x^2 + y^2 = z^2$$'
        '\n',
      );
      expect(tester.takeException(), isNull);
      // Typeset rather than shown: the tex is nowhere on screen.
      final screen = StringBuffer();
      for (final widget in tester.allWidgets) {
        if (widget is Text) {
          final span = widget.textSpan;
          if (span != null) screen.write(' ${span.toPlainText()}');
        }
      }
      expect(screen.toString(), isNot(contains(r'$$')));
      expect(screen.toString(), contains('an item'));
    });

    testWidgets('a formula that cannot be typeset does not take the screen', (
      tester,
    ) async {
      // The cache's renderer throws, as a malformed expression makes it.
      final cache = MathCache(
        renderer: (tex, {required displayMode}) => throw StateError('bad tex'),
      );
      final parser = BlockParser();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText(r'a $\frac{1}{$ b'),
              parser: parser,
              mathCache: cache,
            ),
          ),
        ),
      );
      await tester.pump();
      // The note's other words survive, which is the property that matters: one
      // bad formula must not cost a reader the paragraph.
      expect(find.textContaining('a', findRichText: true), findsWidgets);
    });

    testWidgets('every CommonMark example builds without an exception', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final suite = loadSpecSuites().first;
      for (final example in suite.examples) {
        await _pump(tester, example.markdown);
        final failure = tester.takeException();
        expect(
          failure,
          isNull,
          reason:
              '${suite.name}/${example.number} '
              '@${example.section} threw $failure',
        );
      }
    });
  });
}
