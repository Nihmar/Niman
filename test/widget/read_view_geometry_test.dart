// The geometry gate the phase asked for and nobody built (§8.4.4, §10.4).
//
// The engine comparison reads `toPlainText()`, and a position is not a word: a
// paragraph clipped to a third of its height still has its words in the tree
// (#250) and a display formula drawn at the left margin still says what it says
// (#252). Both were found by a device and a screenshot, which is the gate this
// file is.
//
// What it checks is what a render tree can be asked about itself, without
// comparing two engines' trees — that comparison is where brittleness lives.
// Three properties, over every block a frame draws:
//
// 1. **A paragraph covers its own text.** `RenderParagraph` can answer how tall
//    its text wants to be at the width it was given, so a box shorter than that
//    is the clipping #250 was, caught with no fixture-specific expectation.
// 2. **Blocks do not overlap.** They tile the note: each one starts where the
//    one above it ended.
// 3. **A display formula is centred and narrower than the column** — the shape
//    the preview draws, and what a formula stretched to the page was not.
//
// It then walks each fixture from top to bottom, checking at every step: a gate
// that only looks at the first screen is how a note is fine until you scroll.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex/katex.dart' show KatexBoxPainter, boxSizePxPadded;
import 'package:katex_dart/katex_dart.dart' show KatexOptions, renderToBox;
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

/// The fixtures the gate sweeps, and the note that found #250 and #252 when it
/// is on this machine (it is one person's file and is not in the repository).
const List<String> _fixtures = <String>[
  'test/fixtures/markdown/fixture-1kb.md',
  'test/fixtures/markdown/fixture-10kb.md',
  'test/fixtures/markdown/fixture-50kb.md',
  'test/fixtures/markdown/fixture-200kb.md',
  'Geometria 1.md',
];

/// A geometry failure, as a line to put in a `reason`.
typedef Failure = String;

MathCache _cache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

/// Every paragraph the tree drew whose box is shorter than its own text wants,
/// every pair of blocks that overlap, and every display formula that is not the
/// shape the preview draws.
///
/// Empty is the property. It is a function rather than an assertion so the test
/// below can prove it has teeth.
List<Failure> geometryFailures(
  WidgetTester tester, {
  required double pane,
  MathCache? cache,
}) {
  final failures = <Failure>[];

  for (final object in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!object.attached || !object.hasSize) continue;
    final drawn = object.size.height;
    final wanted = object.computeMaxIntrinsicHeight(object.size.width);
    // A pixel of slack: a `WidgetSpan`'s dry layout (what the intrinsic asks)
    // and its real one differ by rounding, not by a third of the block.
    if (drawn < wanted - 1) {
      final text = object.text.toPlainText().replaceAll('\n', ' ');
      final shown = text.length > 60 ? '${text.substring(0, 60)}…' : text;
      failures.add(
        'a paragraph is drawn ${drawn.toStringAsFixed(1)} px tall where its '
        'own text wants ${wanted.toStringAsFixed(1)}: "$shown"',
      );
    }
  }

  // A quote's content is blocks of its own, drawn inside the quote's: the
  // blocks that tile are the ones side by side — the note's, and each
  // quote's inside it — so they are checked by the block they are in.
  final siblings = <Element?, List<Rect>>{};
  for (final element in find.byType(BlockView).evaluate()) {
    if (element.renderObject case final RenderBox box
        when box.attached && box.hasSize) {
      Element? parent;
      element.visitAncestorElements((ancestor) {
        if (ancestor.widget is! BlockView) return true;
        parent = ancestor;
        return false;
      });
      (siblings[parent] ??= <Rect>[]).add(
        box.localToGlobal(Offset.zero) & box.size,
      );
    }
  }
  for (final blocks in siblings.values) {
    blocks.sort((a, b) => a.top.compareTo(b.top));
    for (var at = 1; at < blocks.length; at++) {
      final overlap = blocks[at - 1].bottom - blocks[at].top;
      if (overlap > 0.5) {
        failures.add(
          'two blocks overlap by ${overlap.toStringAsFixed(1)} px at y '
          '${blocks[at].top.toStringAsFixed(1)}',
        );
      }
    }
  }

  final column = pane - 32;
  for (final element in find.byType(BlockMathView).evaluate()) {
    if (element.renderObject case final RenderBox box
        when box.attached && box.hasSize) {
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final view = element.widget as BlockMathView;
      final tex = view.tex.trim();
      final shown = tex.length > 40 ? '${tex.substring(0, 40)}…' : tex;
      // What the formula *wants* to be, from the same cache the view drew
      // from. Without it a stretched box and a formula genuinely wider than the
      // pane are the same 568 pixels — and only one of them is a bug.
      final rendered = cache?.boxFor(tex, displayMode: true);
      final intrinsic = rendered == null
          ? null
          : boxSizePxPadded(rendered, view.style.fontSize).width;
      // A formula the pane is too narrow for must be **broken or shrunk** —
      // never drawn at full size into a box it cannot fit, which is the cut
      // (#257). Both answers are visible from the tree: the pieces the painter
      // draws, and the size they are painted at against the view's own. The
      // view shrinks inside itself, so its own style is the size it was asked
      // for, not the one it drew; and the theme's body is no measure either,
      // since a formula is set larger than the prose around it.
      if (intrinsic != null && intrinsic > column) {
        final painters = find
            .descendant(
              of: find.byWidget(view),
              matching: find.byType(CustomPaint),
            )
            .evaluate()
            .map((e) => (e.widget as CustomPaint).painter)
            .whereType<KatexBoxPainter>()
            .toList();
        final shrunk = painters.any(
          (painter) => painter.fontSize < view.style.fontSize - 0.01,
        );
        if (painters.length < 2 && !shrunk) {
          failures.add(
            'a formula wider than the pane is drawn whole at '
            '${view.style.fontSize} px: "$shown"',
          );
        }
      }
      if (intrinsic != null && intrinsic <= column) {
        if (rect.width > intrinsic + 1) {
          failures.add(
            'a display formula is drawn ${rect.width.toStringAsFixed(1)} px '
            'wide where it wants ${intrinsic.toStringAsFixed(1)} — the box, '
            'not the formula: "$shown"',
          );
        } else if ((rect.center.dx - pane / 2).abs() > 1) {
          failures.add(
            'a display formula is centred at '
            '${rect.center.dx.toStringAsFixed(1)} where the pane centres at '
            '${(pane / 2).toStringAsFixed(1)}: "$shown"',
          );
        }
      }
    }
  }

  return failures;
}

/// Pumps [document] in the read view at [pane] logical pixels wide and hands
/// back the controller, so a caller can walk it.
Future<(ScrollController, MathCache)> _pump(
  WidgetTester tester,
  String document, {
  required double pane,
}) async {
  tester.view.physicalSize = Size(pane, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = ScrollController();
  addTearDown(controller.dispose);
  final cache = _cache();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          buffer: SourceBuffer.fromText(document),
          parser: BlockParser(),
          mathCache: cache,
          controller: controller,
        ),
      ),
    ),
  );
  await tester.pump();
  return (controller, cache);
}

void main() {
  testWidgets('the gate has teeth: it fails a clipped paragraph', (
    tester,
  ) async {
    // The shape of #250: a box a third of the height its text wants. The check
    // has to see it, or it is not a gate.
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final long = List.filled(20, 'wrapping words').join(' ');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 20,
            child: Text(long, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(geometryFailures(tester, pane: 400), isNotEmpty);
  });

  testWidgets('the gate has teeth: it fails a formula at the left margin', (
    tester,
  ) async {
    // The shape of #252: the box stretched to the column, the ink at its left.
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cache = _cache();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: BlockMathView(
                cache: cache,
                tex: 'x^2 + y^2 = z^2',
                style: const MathStyle(),
              ),
            ),
          ),
        ),
      ),
    );
    // A stretched box is only a bug once the formula is in it: the gate asks
    // the cache for the size it *wants*, so it needs the render to have landed.
    await tester.pump();
    await tester.pump();
    expect(cache.boxFor('x^2 + y^2 = z^2', displayMode: true), isNotNull);
    expect(geometryFailures(tester, pane: 600, cache: cache), isNotEmpty);
  });

  testWidgets('the gate has teeth: it fails two blocks drawn over each other', (
    tester,
  ) async {
    // What a forced extent did to the block *after* a clipped one: the two were
    // laid out on top of each other. A `Stack` is that, deliberately.
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final buffer = SourceBuffer.fromText('# One\n\nTwo\n');
    final parser = BlockParser();
    final blocks = BlockScanner(buffer).index.blocks;
    final cache = _cache();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final theme = markdownThemeOf(context);
              return Stack(
                children: <Widget>[
                  for (final (top, index) in <(double, int)>[(0, 0), (10, 2)])
                    Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      child: BlockView(
                        parsed: parser.of(blocks[index], buffer),
                        theme: theme,
                        mathCache: cache,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(geometryFailures(tester, pane: 600), isNotEmpty);
  });

  testWidgets('the read view is clean at every step down the fixtures', (
    tester,
  ) async {
    for (final path in _fixtures) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final document = file.readAsStringSync();
      final (controller, cache) = await _pump(tester, document, pane: 600);
      // Ten steps from the top to the end: the first screen, the middle, the
      // end, and the jumps between them. Every failure is collected rather than
      // thrown at the first one, so a step cannot hide the next one's.
      final failures = <String>[];
      for (var step = 0; step <= 10; step++) {
        final max = controller.hasClients
            ? controller.position.maxScrollExtent
            : 0.0;
        controller.jumpTo(max * step / 10);
        // Two pumps: the first draws the screen, the second is the frame the
        // math renders land on. A **pending** formula is a 12.6 px placeholder
        // in a 20 px line by design, and checking before the cache answers
        // would fail the gate on a state no reader sees for more than a frame.
        await tester.pump();
        await tester.pump();
        for (final failure in geometryFailures(
          tester,
          pane: 600,
          cache: cache,
        )) {
          failures.add('$path, step $step of 10: $failure');
        }
      }
      expect(failures, isEmpty, reason: failures.take(10).join('\n'));
    }
  });

  testWidgets('the shapes a device found are clean on their own', (
    tester,
  ) async {
    // The three of them in one note, which is what a reader writes.
    final (controller, cache) = await _pump(
      tester,
      '# A title\n\n'
      '${List.filled(20, 'wrapping words').join(' ')}\n\n'
      '\$\$\n'
      r'\langle \mathbf{v} \rangle = \alpha \mathbf{v}'
      '\n\$\$\n\n'
      '- a) an item\n- b) another\n  - nested\n- c) a third\n\n'
      r'> quoted, with $x^2$ in it'
      '\n',
      pane: 600,
    );
    await tester.pump();
    expect(geometryFailures(tester, pane: 600, cache: cache), isEmpty);
    controller.jumpTo(0);
    await tester.pump();
    await tester.pump();
    expect(geometryFailures(tester, pane: 600, cache: cache), isEmpty);
  });
}
