// `live` and the read view are one page: the same note, drawn the same, one
// of them editable. What is held here is what the reader sees move when the
// pane flips — a glyph that is not where it was.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A note whose second paragraph wraps in any pane this file uses.
final String _note =
    'caret\n\nplain words\n\n${List.filled(40, 'wrapping').join(' ')}\n';

/// Pumps [_note] in `live`, or in the read view when [read].
Future<void> _pump(
  WidgetTester tester, {
  required bool read,
  required bool numbers,
  required NoteColumn column,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => read
              ? MarkdownReadView(
                  buffer: SourceBuffer.fromText(_note),
                  parser: BlockParser(),
                  mathCache: MathCache(),
                  column: column,
                  lineNumbers: numbers,
                )
              : MarkdownSurface(
                  buffer: SourceBuffer.fromText(_note),
                  mode: MarkdownSurfaceMode.live,
                  theme: markdownThemeOf(context),
                  selection: const SelectionModel.at(0),
                  showLineNumbers: numbers,
                  column: column,
                ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Where the glyph at [offset] of the paragraph that starts with [start] is
/// drawn, globally.
Offset _glyph(WidgetTester tester, String start, int offset) {
  final paragraph = tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .firstWhere((p) => p.text.toPlainText().startsWith(start));
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + 1),
      )
      .first;
  return paragraph.localToGlobal(Offset(box.left, box.top));
}

/// The first offset of the paragraph starting with [start] that is drawn on
/// its second row.
int _wrap(WidgetTester tester, String start) {
  final first = _glyph(tester, start, 0).dy;
  var at = 1;
  while (_glyph(tester, start, at).dy <= first) {
    at++;
  }
  return at;
}

void main() {
  for (final numbers in [false, true]) {
    for (final (name, column) in [
      ('full width', NoteColumn.off),
      ('a column', const NoteColumn(width: 500)),
    ]) {
      testWidgets('the text starts and wraps where it does in live '
          '(${numbers ? 'numbers' : 'no numbers'}, $name)', (tester) async {
        // The read view set its text 16 px in from each side; `live`, with
        // no column, 5 px — past the numbers when they were on — and 5 px
        // from the right: the text moved and wrapped elsewhere each time
        // the pane flipped.
        tester.view.physicalSize = const Size(900, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pump(tester, read: false, numbers: numbers, column: column);
        final live = _glyph(tester, 'plain', 0).dx;
        final liveWrap = _wrap(tester, 'wrapping');
        await _pump(tester, read: true, numbers: numbers, column: column);
        expect(_glyph(tester, 'plain', 0).dx, closeTo(live, 0.01));
        expect(_wrap(tester, 'wrapping'), liveWrap);
      });
    }
  }
}
