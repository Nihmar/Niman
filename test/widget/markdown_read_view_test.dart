// The windowed read view. The property under test is the one the whole surface
// is built around: opening a long note must not lay it all out, so the number
// of blocks *built* has to stay near the number a viewport can show — and must
// grow when the viewport moves, or the windowing would just be a way of not
// rendering.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex/katex.dart' show KatexBoxPainter;
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

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
  NoteColumn column = NoteColumn.off,
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
          column: column,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownReadViewState>(find.byType(MarkdownReadView));
}

void main() {
  group('a code block too long to lay out whole', () {
    /// A fence of [lines] numbered lines, between two paragraphs.
    String fence(int lines) {
      final out = StringBuffer('before\n\n```dart\n');
      for (var at = 0; at < lines; at++) {
        out.writeln('var line$at = $at;');
      }
      out.write('```\n\nafter\n');
      return out.toString();
    }

    testWidgets(
      'is drawn in pieces, fences out, as the viewport reaches them',
      (tester) async {
        final state = await _pump(tester, fence(5000));
        // Only the pieces on screen are built, not five thousand lines.
        final pieces = tester.widgetList<CodePieceView>(
          find.byType(CodePieceView),
        );
        expect(pieces, isNotEmpty);
        expect(pieces.length, lessThan(5));
        final first = pieces.first;
        expect(first.first, isTrue);
        final text = tester
            .widgetList<RichText>(
              find.descendant(
                of: find.byWidget(first),
                matching: find.byType(RichText),
              ),
            )
            .single
            .text
            .toPlainText();
        expect(text, startsWith('var line0 = 0;'), reason: 'the fence is out');
        const lines = MarkdownReadViewState.pieceLines;
        expect(text.split('\n'), hasLength(lines - 1));
        expect(state.mounted, isTrue);
      },
    );

    testWidgets(
      'its last piece ends at the closing fence, and the note goes on',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await _pump(tester, fence(5000), controller: controller);
        final clock = Stopwatch()..start();
        for (var pass = 0; pass < 20; pass++) {
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();
        }
        clock.stop();
        final last = tester
            .widgetList<CodePieceView>(find.byType(CodePieceView))
            .where((piece) => piece.last)
            .single;
        final text = tester
            .widgetList<RichText>(
              find.descendant(
                of: find.byWidget(last),
                matching: find.byType(RichText),
              ),
            )
            .single
            .text
            .toPlainText();
        expect(text, endsWith('var line4999 = 4999;'), reason: 'fence out');
        expect(find.text('after', findRichText: true), findsOneWidget);
        // Generous for a test host; the whole block laid out took seconds.
        expect(clock.elapsedMilliseconds, lessThan(5000));
      },
    );

    testWidgets('a short block is still one block', (tester) async {
      await _pump(tester, fence(50));
      expect(find.byType(CodePieceView), findsNothing);
    });
  });

  group("a quote's content is drawn as blocks", () {
    // Drawn as one text, a quote showed a quote inside it as a paragraph
    // with no bar of its own, and a list inside it as its dashes.
    Future<void> pump(
      WidgetTester tester,
      String note, {
      void Function(int line)? onToggleTask,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText(note),
              parser: BlockParser(),
              mathCache: _syncCache(),
              onToggleTask: onToggleTask,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    int bars(WidgetTester tester) =>
        tester.widgetList<Container>(find.byType(Container)).where((box) {
          final decoration = box.decoration;
          return decoration is BoxDecoration &&
              decoration.border is Border &&
              (decoration.border! as Border).left.width > 0;
        }).length;

    testWidgets('a quote inside a quote has a bar of its own', (tester) async {
      await pump(tester, '> outer\n>\n> > inner\n> > > deepest\n');
      expect(bars(tester), 3);
      expect(find.textContaining('deepest', findRichText: true), findsOne);
      expect(find.textContaining('>', findRichText: true), findsNothing);
    });

    testWidgets('a list inside a quote has its bullets and boxes', (
      tester,
    ) async {
      await pump(tester, '> text\n>\n> - item\n> - [ ] task\n');
      expect(find.text('•'), findsOne);
      expect(find.byIcon(Icons.check_box_outline_blank), findsOne);
      expect(find.textContaining('- item', findRichText: true), findsNothing);
    });

    testWidgets("a task inside a quote is ticked on the note's own line", (
      tester,
    ) async {
      final ticked = <int>[];
      await pump(
        tester,
        'before\n\n> text\n>\n> - [ ] task\n',
        onToggleTask: ticked.add,
      );
      await tester.tap(find.byIcon(Icons.check_box_outline_blank));
      expect(ticked, [4]);
    });
  });

  testWidgets('the note column centres the text, as the preview does', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, 'a paragraph\n', column: const NoteColumn(width: 600));
    final left = tester.getTopLeft(find.textContaining('a paragraph')).dx;
    // (1400 - 600 - 2 * 16) / 2 of side space, then the 16 px inset.
    expect(left, 384 + 16);
  });

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

  testWidgets('a far jump builds a viewport, not what it passes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = ScrollController();
    addTearDown(controller.dispose);
    final state = await _pump(tester, _note(400), controller: controller);
    final atStart = state.builtBlocks;
    expect(atStart, lessThan(120), reason: 'a viewport at the top');

    // Jumping most of the way down the note. `SliverList` built every block it
    // passed — 2 772 ms and 3 156 of 7 530 blocks on the geometry note (#251) —
    // because it cannot place a child it has not laid out. This sliver places
    // them from the height map, so it builds what the viewport shows.
    controller.jumpTo(controller.position.maxScrollExtent * 0.9);
    await tester.pump();
    await tester.pump();
    expect(
      state.builtBlocks - atStart,
      lessThan(120),
      reason: 'built ${state.builtBlocks - atStart} blocks for one jump',
    );

    // And it really is the end of the note down there.
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Paragraph 399'), findsWidgets);
  });

  testWidgets('a block taller than its estimate is drawn whole', (
    tester,
  ) async {
    // One paragraph, one source line, a dozen visual ones at this width: the
    // shape a source-line estimate gets wrong, and what a device found (#250) —
    // the sliver *forced* each child to the estimate, so this paragraph showed
    // its first line and lost the rest, with a gap where the next block begins.
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final long = List.filled(20, 'wrapping words').join(' ');
    await _pump(tester, '$long\n\nAfter.');

    final blocks = find.byType(BlockView);
    expect(blocks, findsWidgets);
    final first = tester.getSize(blocks.at(0));
    expect(
      first.height,
      greaterThan(150),
      reason: 'the wrapped paragraph is drawn ${first.height} px tall',
    );
    // And the block after it starts below it rather than over it.
    expect(
      tester.getTopLeft(blocks.at(1)).dy,
      greaterThanOrEqualTo(tester.getTopLeft(blocks.at(0)).dy + first.height),
    );
  });

  testWidgets('what a frame laid out is remembered', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = await _pump(tester, _note(40));
    expect(state.builtBlocks, greaterThan(0));
    // The measurements are the estimator's only feed: without them, the height
    // of the part of the note no frame has laid out is pure guesswork.
    for (var at = 0; at < 3; at++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.measuredBlocks, greaterThan(0));
    expect(state.totalExtent, greaterThan(0));
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

  group('a long note is scanned in the background', () {
    setUp(() => MarkdownReadViewState.backgroundLines = 20);
    tearDown(() => MarkdownReadViewState.backgroundLines = 50000);

    /// Waits for the isolate, then for the frame that draws its answer.
    Future<void> settle(WidgetTester tester) async {
      for (var round = 0; round < 50; round++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        final state = tester.state<MarkdownReadViewState>(
          find.byType(MarkdownReadView),
        );
        // The answer can land during the pump, after its build: one more.
        if (!state.scanning) {
          await tester.pump();
          return;
        }
      }
    }

    Widget view(SourceBuffer buffer, BlockParser parser) => MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          buffer: buffer,
          parser: parser,
          mathCache: _syncCache(),
        ),
      ),
    );

    testWidgets('the first look waits for the scan, then draws it', (
      tester,
    ) async {
      final parser = BlockParser();
      await tester.pumpWidget(
        view(SourceBuffer.fromText('${_note(20)}[^1]\n\n[^1]: a note'), parser),
      );
      expect(find.byKey(const Key('read-view-scanning')), findsOneWidget);
      await settle(tester);
      final state = tester.state<MarkdownReadViewState>(
        find.byType(MarkdownReadView),
      );
      expect(state.blockCount, greaterThan(20));
      expect(find.textContaining('Paragraph 0', findRichText: true), findsOne);
      // The definitions came back with the blocks, and belong to the note.
      expect(parser.scope?.footnotes.single.body, 'a note');
    });

    testWidgets("each revision's definitions are the ones drawn", (
      tester,
    ) async {
      // Each revision comes as its own buffer, which is what the pane is
      // handed while a note is being edited: the live buffer is snapshotted
      // for the page ([SourceBuffer.snapshot]) rather than read in place.
      final parser = BlockParser();
      final first = SourceBuffer.fromText(
        '${_note(20)}[^1]\n\n[^1]: a note\n\n[ref]: https://x.test\n',
      );
      await tester.pumpWidget(view(first, parser));
      await settle(tester);
      expect(parser.scope?.footnotes.single.body, 'a note');
      expect(parser.scope?.links['ref']?.destination, 'https://x.test');

      // An edit somewhere else: one line added at the head.
      final second = SourceBuffer.fromText(
        'one more line to read\n${_note(20)}[^1]\n\n[^1]: a note\n\n'
        '[ref]: https://x.test\n',
      );
      await tester.pumpWidget(view(second, parser));
      await settle(tester);
      expect(
        parser.scope?.footnotes.single.body,
        'a note',
        reason: 'the same definitions, on the buffer that now holds them',
      );
      expect(parser.scope?.links['ref']?.destination, 'https://x.test');
      expect(parser.scope?.revision, second.revision);

      // A definition changed.
      final third = SourceBuffer.fromText(
        '${_note(20)}[^1]\n\n[^1]: another note\n\n[ref]: https://x.test\n',
      );
      await tester.pumpWidget(view(third, parser));
      await settle(tester);
      expect(parser.scope?.footnotes.single.body, 'another note');
    });

    testWidgets('a scan someone already holds is drawn at once', (
      tester,
    ) async {
      // The editor keeps its own reading of the note current: the pane takes
      // it rather than scanning the note in an isolate again.
      final parser = BlockParser();
      final buffer = SourceBuffer.fromText('${_note(20)}[^1]\n\n[^1]: a note');
      final held = DocumentScan.of(buffer);
      var asked = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: buffer,
              parser: parser,
              mathCache: _syncCache(),
              knownScan: (asking) {
                asked++;
                return identical(asking, buffer) ? held : null;
              },
            ),
          ),
        ),
      );
      final state = tester.state<MarkdownReadViewState>(
        find.byType(MarkdownReadView),
      );
      expect(asked, 1);
      expect(state.scanning, isFalse, reason: 'nothing was sent to scan');
      expect(find.byKey(const Key('read-view-scanning')), findsNothing);
      expect(state.blockCount, held.blocks.length);
      expect(find.textContaining('Paragraph 0', findRichText: true), findsOne);
      expect(parser.scope?.footnotes.single.body, 'a note');
    });

    testWidgets('the heights a frame measured outlive the next hand-over', (
      tester,
    ) async {
      // Estimating every block again forgot them, and on 2 M blocks cost
      // 100–200 ms; the editor's hand-over says which blocks are new.
      final parser = BlockParser();
      final live = SourceBuffer.fromText(_note(40));
      final styler = SourceStyler(live);
      Widget view() {
        final snapshot = live.snapshot();
        return MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: snapshot,
              parser: parser,
              mathCache: _syncCache(),
              knownScan: (buffer) {
                final scan = styler.handOver()!;
                return DocumentScan(
                  blocks: scan.blocks,
                  scope: scan.scope.on(buffer, buffer.revision),
                  revision: buffer.revision,
                  changes: scan.changes,
                );
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(view());
      await tester.pump();
      MarkdownReadViewState state() =>
          tester.state<MarkdownReadViewState>(find.byType(MarkdownReadView));
      final measured = state().measuredBlocks;
      expect(measured, greaterThan(5), reason: 'a screen of blocks drawn');

      // A paragraph added far below what is on screen.
      final end = live.length;
      styler.edited(live.replaceRange(end, end, '\nA new paragraph.\n'));
      await tester.pumpWidget(view(), phase: EnginePhase.build);
      expect(
        state().measuredBlocks,
        measured,
        reason: 'no block on screen changed, so none lost its height',
      );
      await tester.pump();
      expect(state().blockCount, styler.handOver()!.blocks.length);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a held scan of another revision is not taken', (tester) async {
      final parser = BlockParser();
      final buffer = SourceBuffer.fromText(_note(20));
      final stale = DocumentScan.of(buffer);
      buffer.replaceRange(0, 0, '# Now\n\n');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: buffer,
              parser: parser,
              mathCache: _syncCache(),
              knownScan: (_) => stale,
            ),
          ),
        ),
      );
      expect(
        tester
            .state<MarkdownReadViewState>(find.byType(MarkdownReadView))
            .scanning,
        isTrue,
        reason: 'its blocks are of lines no longer there',
      );
      await settle(tester);
      expect(find.textContaining('Now', findRichText: true), findsOne);
    });

    testWidgets('a footnote cited mid-sentence is not a reason to reuse', (
      tester,
    ) async {
      // The citations are the footnotes' order and numbering, and the key the
      // reuse is decided by read only the lines that open with `[`: a second
      // footnote cited in prose kept the scope that knew one.
      final parser = BlockParser();
      const definitions = '[^1]: one\n\n[^2]: two\n';
      await tester.pumpWidget(
        view(
          SourceBuffer.fromText('${_note(20)}See[^1].\n\n$definitions'),
          parser,
        ),
      );
      await settle(tester);
      expect(parser.scope?.footnoteLabels, ['1']);
      await tester.pumpWidget(
        view(
          SourceBuffer.fromText('${_note(20)}See[^1] and[^2].\n\n$definitions'),
          parser,
        ),
      );
      await settle(tester);
      expect(parser.scope?.footnoteLabels, ['1', '2']);
    });

    testWidgets('the revision before stays on screen meanwhile', (
      tester,
    ) async {
      final parser = BlockParser();
      await tester.pumpWidget(view(SourceBuffer.fromText(_note(20)), parser));
      await settle(tester);
      await tester.pumpWidget(
        view(SourceBuffer.fromText('# Now\n\n${_note(20)}'), parser),
      );
      expect(find.byKey(const Key('read-view-scanning')), findsNothing);
      expect(find.textContaining('Paragraph 0', findRichText: true), findsOne);
      await settle(tester);
      expect(find.textContaining('Now', findRichText: true), findsOne);
    });

    testWidgets('a jump asked for before the scan lands is taken after', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText(_note(200)),
              parser: BlockParser(),
              mathCache: _syncCache(),
              controller: controller,
            ),
          ),
        ),
      );
      tester
          .state<MarkdownReadViewState>(find.byType(MarkdownReadView))
          .jumpToLine(450);
      await settle(tester);
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
    });
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

    testWidgets('a display formula sits in the middle of the column', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const tex = 'x^2 + y^2 = z^2';
      final cache = _syncCache();
      final parser = BlockParser();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText('\$\$\n$tex\n\$\$\n'),
              parser: parser,
              mathCache: cache,
            ),
          ),
        ),
      );
      await tester.pump();
      // Typeset rather than still waiting: a placeholder would satisfy the
      // geometry below without a formula ever having been drawn.
      expect(cache.boxFor(tex, displayMode: true), isNotNull);
      final box = tester.getRect(find.byType(BlockMathView));
      // A block is laid out on the sliver's cross axis with a *tight* width,
      // and the katex painter always starts its ink at the canvas origin — so
      // a box as wide as the column is a formula painted at the column's left
      // edge, however wide the formula itself is.
      expect(
        box.width,
        lessThan(200),
        reason: 'the formula, not the column it sits in',
      );
      // 600 minus the 16-pixel page margin on either side.
      expect(box.center.dx, closeTo(300, 0.5));
    });

    testWidgets('a jump to a source line lands on that block', (tester) async {
      // #256: an anchor jump arrives as a source *line*, and turning it into
      // pixels through a uniform fraction of the note's height is wrong by a
      // screen on a note whose paragraphs differ this much in height — one
      // source line each, five or thirty visual ones. The height map knows
      // where every block starts, so the line resolves to a block.
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final state = await _pump(tester, _note(400), controller: controller);

      // Two lines of prose and a blank line per paragraph, so paragraph 5
      // starts at source line 15.
      state.jumpToLine(15);
      await tester.pump();
      final target = find.textContaining('Paragraph 5 has', findRichText: true);
      expect(target, findsOneWidget);
      expect(
        tester.getTopLeft(target).dy,
        lessThan(40),
        reason: 'the target block is at the top, not a screen away',
      );
      // The block above it is not on screen: the jump moved where it said.
      expect(
        find.textContaining('Paragraph 3 has', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('Paragraph 0 has', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('a jump into tall paragraphs is corrected until it lands', (
      tester,
    ) async {
      // The map estimates a paragraph from its *source* lines, and each of
      // these is thirty words: one source line, eight or nine visual ones. So
      // the first pass lands where the estimate says — several screens short —
      // and the frame that lands measures the blocks around it, which pushes
      // the target's own offset down. That is what the correction loop is for.
      tester.view.physicalSize = const Size(600, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final filler = List.filled(30, 'filler words').join(' ');
      final document = StringBuffer();
      for (var at = 0; at < 12; at++) {
        document
          ..writeln(filler)
          ..writeln();
      }
      document
        ..writeln('The target paragraph.')
        ..writeln();
      for (var at = 0; at < 6; at++) {
        document
          ..writeln(filler)
          ..writeln();
      }
      final state = await _pump(
        tester,
        document.toString(),
        controller: controller,
      );
      // Twelve paragraphs of two lines each: the target is at line 24.
      state.jumpToLine(24);
      await tester.pumpAndSettle();
      final target = find.textContaining(
        'The target paragraph',
        findRichText: true,
      );
      expect(target, findsOneWidget);
      expect(
        tester.getTopLeft(target).dy,
        lessThan(40),
        reason: 'the estimate was screens out and the correction closed it',
      );
    });

    testWidgets('a line inside a tall block still lands on its block', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final long = List.filled(40, 'wrapping words').join(' ');
      final state = await _pump(
        tester,
        'a first paragraph\n\n$long\n\nanother\n',
        controller: controller,
      );
      // Line 2 is the first line of the tall paragraph.
      state.jumpToLine(2);
      await tester.pump();
      expect(
        find.textContaining('wrapping words', findRichText: true),
        findsWidgets,
      );
      expect(tester.getTopLeft(find.byType(BlockView).at(1)).dy, lessThan(40));
    });

    testWidgets('a fenced block is coloured by its language', (tester) async {
      // Phase 2's own exit criteria ask for code colouring, and neither surface
      // had it: the preview's `syntaxHighlighter` was never wired (only a test
      // passed one), so a code block was one monospace colour everywhere.
      tester.view.physicalSize = const Size(600, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, '```dart\nfinal x = 1; // a comment\n```\n');
      final paragraph = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere(
            (paragraph) => paragraph.text.toPlainText().contains('final x = 1'),
          );
      // A manual walk, not `visitChildren`: that one skips a span with no text
      // of its own, and the *colours* live on the wrapper spans the token tree
      // puts around each token.
      final colours = <Color>{};
      void walk(InlineSpan span) {
        final colour = span.style?.color;
        if (colour != null) colours.add(colour);
        final children = span is TextSpan ? span.children : null;
        children?.forEach(walk);
      }

      walk(paragraph.text);
      expect(
        colours.length,
        greaterThan(1),
        reason: 'a keyword and a comment are not the same colour: $colours',
      );
      expect(
        paragraph.text.toPlainText(),
        contains('final x = 1; // a comment'),
        reason: 'the code itself is untouched',
      );
    });

    testWidgets('a table cell with inline math lays out', (tester) async {
      // A table's columns are `IntrinsicColumnWidth`, so a cell paragraph is
      // asked for its intrinsic size — and that asks its `WidgetSpan` children
      // for a **dry baseline**. `_RenderInlineMath` implements the laid-out one
      // and not the dry one, which Flutter treats as a broken render object: an
      // assertion in debug, a wrong baseline in release. The engine's own gate
      // found it (§8.4.4's geometry test), not a device.
      tester.view.physicalSize = const Size(600, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(
        tester,
        '| a | b |\n|---|---|\n| '
        r'$x^2$'
        ' | plain |\n',
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('plain', findRichText: true), findsWidgets);
    });

    testWidgets('sibling items share an indent, a sublist steps in', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // The depth used to be the content column of the item *before*, so the
      // second item of a list was drawn 14 px right of the first and the item
      // after a sublist further still (device report, 2026-09-21: "il punto b
      // non dovrebbe essere doppiamente indentato").
      await _pump(tester, '- one\n  - nested\n- two\n');
      final markers = find.text('\u2022');
      expect(markers, findsNWidgets(3));
      final xs = <double>[
        for (final marker in markers.evaluate())
          (marker.renderObject! as RenderBox).localToGlobal(Offset.zero).dx,
      ];
      expect(xs[1], greaterThan(xs[0]), reason: 'the sublist steps in');
      expect(xs[2], xs[0], reason: 'a sibling is not pushed past the first');
      expect(
        xs[1],
        tester.getTopLeft(find.text('one', findRichText: true)).dx,
        reason: "a sublist starts where its parent's text does",
      );
    });

    testWidgets('a one-line display is a block, not a span in the prose', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const tex = 'x^2 + y^2 = z^2';
      final cache = _syncCache();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText('\$\$$tex\$\$\n'),
              parser: BlockParser(),
              mathCache: cache,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(cache.boxFor(tex, displayMode: true), isNotNull);
      // A block, not a `WidgetSpan` inside a paragraph: a span leaves the
      // object replacement character in its paragraph's text, and a line the
      // preview draws as a centered block would be a box at the left margin
      // (#252).
      final prose = tester.allWidgets
          .whereType<Text>()
          .map((widget) => widget.textSpan?.toPlainText() ?? '')
          .join();
      expect(prose, isNot(contains('\uFFFC')));
      expect(
        tester.getRect(find.byType(BlockMathView)).center.dx,
        closeTo(300, 0.5),
      );
    });

    testWidgets('two display blocks in a row are two formulas', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cache = _syncCache();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              // The line that closes the first block starts with `$$`, and so
              // does the line that opens the second: the scanner read the run
              // as one block and the view drew one formula holding both texes.
              buffer: SourceBuffer.fromText('\$\$\na\n\$\$\n\$\$\nb\n\$\$\n'),
              parser: BlockParser(),
              mathCache: cache,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(cache.boxFor('a', displayMode: true), isNotNull);
      expect(cache.boxFor('b', displayMode: true), isNotNull);
      expect(
        tester
            .widgetList<BlockMathView>(find.byType(BlockMathView))
            .map((view) => view.tex),
        <String>['a', 'b'],
      );
    });

    testWidgets('a formula wider than the pane is broken, not cut', (
      tester,
    ) async {
      // #257: a third of the geometry note's 824 display formulas are wider
      // than a phone pane, and they were clamped to it and cut — a reader
      // studying from a phone could not see the end of the equation. Full size
      // on two lines beats shrunk onto one.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const tex =
          '2(x_1 + x_2) - 3(y_1 + y_2) + (z_1 + z_2) = (2x_1 - 3y_1 + z_1) + '
          '(2x_2 - 3y_2 + z_2) = 0;';
      final cache = _syncCache();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText('\$\$\n$tex\n\$\$\n'),
              parser: BlockParser(),
              mathCache: cache,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(cache.boxFor(tex, displayMode: true), isNotNull);
      final painted = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(BlockMathView),
              matching: find.byType(CustomPaint),
            ),
          )
          .where((paint) => paint.painter is KatexBoxPainter)
          .toList();
      expect(
        painted.length,
        greaterThan(1),
        reason: 'one box means the formula was drawn whole, which is the cut',
      );
      for (final paint in painted) {
        expect(
          paint.size.width,
          lessThanOrEqualTo(400 - 32),
          reason: 'every piece fits the pane',
        );
      }
      // The whole formula is still there: no glyph was dropped by the split.
      final drawn = tester
          .widgetList<BlockMathView>(find.byType(BlockMathView))
          .map((view) => view.tex)
          .join();
      expect(drawn, contains('2(x_1'));
      expect(drawn.trim(), endsWith('0;'));
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
