// A long note is drawn from its top while the whole of it is scanned, and
// the scan lands whenever it lands: often while the reader is already
// scrolling. A long book jumped up and down there — the view moved itself
// back to where the reader had been when the scan landed, frame after
// frame, and each move ended the drag or the fling the finger had started.
import 'dart:async';

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
}
