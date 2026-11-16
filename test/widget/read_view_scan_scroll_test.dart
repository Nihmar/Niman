// A long note is drawn from its top while the whole of it is scanned, and
// the scan lands whenever it lands: often while the reader is already
// scrolling. A long book jumped up and down there — the view moved itself
// back to where the reader had been when the scan landed, frame after
// frame, and each move ended the drag or the fling the finger had started.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A cache that renders in-line, as the preview's own tests do.
MathCache _syncCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

/// A book's text: [paragraphs] paragraphs of prose, each long enough to
/// wrap over several lines, as a novel's do.
String _book(int paragraphs) {
  final buffer = StringBuffer();
  for (var at = 0; at < paragraphs; at++) {
    buffer
      ..write('Paragraph $at. ')
      ..writeln(
        List.filled(
          6 + at % 7 * 4,
          'the reader goes on through the pages',
        ).join(' '),
      )
      ..writeln();
  }
  return buffer.toString();
}

/// The line at the top of [view] in each frame drawn from now on, read
/// once the frame is laid out and painted — before anything a post-frame
/// callback does to the position, which the reader never sees.
({List<int> lines, void Function() stop}) drawnTops(
  WidgetTester tester,
  MarkdownReadViewState view,
) {
  final lines = <int>[];
  var recording = true;
  tester.binding.addPersistentFrameCallback((_) {
    final top = view.topAnchor;
    if (recording && top != null) lines.add(top.line);
  });
  return (lines: lines, stop: () => recording = false);
}

void main() {
  setUp(() {
    MarkdownReadViewState.backgroundLines = 20;
    // A hundred paragraphs of the book drawn while the rest is read.
    MarkdownReadViewState.headLines = 200;
  });
  tearDown(() {
    MarkdownReadViewState.backgroundLines = 50000;
    MarkdownReadViewState.headLines = 5000;
  });

  /// Opens [buffer] in the read view, its scan landing when [scan]
  /// completes.
  Future<MarkdownReadViewState> open(
    WidgetTester tester,
    SourceBuffer buffer,
    ScrollController controller,
    Completer<DocumentScan?> scan,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownReadView(
            buffer: buffer,
            parser: ReadParser(),
            mathCache: _syncCache(),
            controller: controller,
            sharedScan: (_) => scan.future,
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.state<MarkdownReadViewState>(find.byType(MarkdownReadView));
  }

  testWidgets('a drag under way when the scan lands follows the finger', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText(_book(400));
    final controller = ScrollController();
    final scan = Completer<DocumentScan?>();
    final view = await open(tester, buffer, controller, scan);
    expect(view.scanning, isTrue);

    final drag = await tester.startGesture(const Offset(400, 400));
    // Past the touch slop, then a few steps into the book.
    for (var step = 0; step < 12; step++) {
      await drag.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final before = controller.offset;
    final offsets = <double>[before];
    final drawn = drawnTops(tester, view);

    scan.complete(DocumentScan.of(buffer));
    for (var step = 0; step < 20; step++) {
      await drag.moveBy(const Offset(0, -10));
      await tester.pump(const Duration(milliseconds: 16));
      offsets.add(controller.offset);
    }
    drawn.stop();
    final lines = drawn.lines;
    await drag.up();
    await tester.pumpAndSettle();

    expect(view.scanning, isFalse);
    // The finger moved 200 px into the book after the scan landed, and
    // the page went with it: nothing ended the drag or pulled it back.
    for (var at = 1; at < lines.length; at++) {
      expect(
        lines[at],
        greaterThanOrEqualTo(lines[at - 1]),
        reason: 'the top line went back, step $at: $lines',
      );
    }
    expect(
      offsets.last - before,
      closeTo(200, 40),
      reason: 'the drag stopped following the finger: $offsets',
    );
  });

  testWidgets('a fling under way when the scan lands keeps going', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText(_book(400));
    final controller = ScrollController();
    final scan = Completer<DocumentScan?>();
    final view = await open(tester, buffer, controller, scan);

    await tester.fling(
      find.byType(MarkdownReadView),
      const Offset(0, -300),
      2000,
    );
    // A few frames into the fling.
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final landed = controller.offset;
    final drawn = drawnTops(tester, view);

    scan.complete(DocumentScan.of(buffer));
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    drawn.stop();
    final lines = drawn.lines;
    await tester.pumpAndSettle();

    expect(view.scanning, isFalse);
    for (var at = 1; at < lines.length; at++) {
      expect(
        lines[at],
        greaterThanOrEqualTo(lines[at - 1]),
        reason: 'the top line went back, frame $at: $lines',
      );
    }
    expect(
      controller.offset - landed,
      greaterThan(100),
      reason: 'the fling stopped when the scan landed',
    );
  });

  testWidgets('a page at rest when the scan lands stays where it is', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText(_book(400));
    final controller = ScrollController();
    final scan = Completer<DocumentScan?>();
    final view = await open(tester, buffer, controller, scan);

    // Read a long way in, by the page, so the blocks above are measured.
    for (var page = 0; page < 12; page++) {
      await tester.drag(find.byType(MarkdownReadView), const Offset(0, -500));
      // Not to settle: the bar under the top of the book runs until the
      // scan lands.
      for (var frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    final before = view.topAnchor!;
    final shown = drawnTops(tester, view);

    scan.complete(DocumentScan.of(buffer));
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    shown.stop();
    await tester.pumpAndSettle();

    expect(view.scanning, isFalse);
    // Not one frame drawn somewhere else first.
    expect(shown.lines, isNotEmpty);
    for (final line in shown.lines) {
      expect(line, before.line, reason: '$before, then ${shown.lines}');
    }
  });

  testWidgets('a wheel turned as the scan lands is not undone', (tester) async {
    final buffer = SourceBuffer.fromText(_book(400));
    final controller = ScrollController();
    final scan = Completer<DocumentScan?>();
    final view = await open(tester, buffer, controller, scan);
    final wheel = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      wheel.hover(tester.getCenter(find.byType(MarkdownReadView))),
    );
    for (var turn = 0; turn < 10; turn++) {
      await tester.sendEventToBinding(wheel.scroll(const Offset(0, 120)));
      await tester.pump(const Duration(milliseconds: 16));
    }

    scan.complete(DocumentScan.of(buffer));
    // The frame that draws the whole book, and its first settling pass.
    await tester.pump(const Duration(milliseconds: 16));
    final offsets = <double>[];
    for (var turn = 0; turn < 6; turn++) {
      final from = controller.offset;
      await tester.sendEventToBinding(wheel.scroll(const Offset(0, 120)));
      await tester.pump(const Duration(milliseconds: 16));
      offsets.add(controller.offset - from);
    }

    expect(view.scanning, isFalse);
    for (final moved in offsets) {
      expect(moved, 120, reason: 'a turn of the wheel was undone: $offsets');
    }
  });
}
