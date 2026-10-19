// The read view's scrollbar is the scrollbar's (#1106): a drag on it scrolls
// and takes no selection, where a drag on the text still selects.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A cache that renders in-line, as the preview's own tests do.
MathCache _syncCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

/// A note long enough to scroll in a 900x500 pane.
String _note() {
  final buffer = StringBuffer();
  for (var at = 0; at < 60; at++) {
    buffer
      ..writeln('Paragraph $at has **bold** and `code` and a [link](u).')
      ..writeln('Its second line continues the paragraph.')
      ..writeln();
  }
  return buffer.toString();
}

Future<MarkdownReadViewState> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      // The desktop scrollbar: MaterialScrollBehavior adds it only on a
      // desktop platform.
      theme: ThemeData(platform: TargetPlatform.linux),
      home: Scaffold(
        body: MarkdownReadView(
          buffer: SourceBuffer.fromText(_note()),
          parser: ReadParser(),
          mathCache: _syncCache(),
          selectionActions: const [],
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownReadViewState>(find.byType(MarkdownReadView));
}

/// The pane's scroll position.
ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(MarkdownReadView),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

void main() {
  testWidgets(
    'dragging the read view scrollbar scrolls and takes no selection',
    (tester) async {
      final state = await _pump(tester);
      expect(find.byType(Scrollbar), findsOneWidget);
      // Show the bar the way a scroll does, so its thumb is painted and the
      // drag can take it.
      final position = _position(tester);
      for (final to in const <double>[1, 0]) {
        position.jumpTo(to);
        await tester.pump(const Duration(milliseconds: 100));
      }
      final before = position.pixels;

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(896, 30));
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(const Offset(896, 30));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.down(const Offset(896, 30));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(state.selection, isNull, reason: 'no text was selected');
      expect(
        _position(tester).pixels,
        greaterThan(before),
        reason: 'it scrolled',
      );
    },
  );
}
