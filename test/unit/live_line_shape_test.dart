// What `live` draws beside a line (#246): the shape is read off the line's
// tokens and its block, so it is tested through the real styler.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// The shape of every line of [note].
List<LineShape> _shapes(String note) {
  final buffer = SourceBuffer.fromText(note);
  final styler = SourceStyler(buffer);
  return <LineShape>[
    for (var line = 0; line < buffer.lineCount; line++)
      LineShape.of(
        StyledLine(buffer.lineAt(line), styler.tokensOf(line)),
        styler.blockOf(line),
        line,
      ),
  ];
}

void main() {
  test('a bullet, a number counted as the list counts, a checkbox', () {
    final shapes = _shapes(
      '- a\n  - b\n\n1. one\n1. two\n\n- [ ] do\n- [x] done',
    );
    expect(shapes[0], const LineShape(marker: 0));
    expect(shapes[1], const LineShape(marker: 2, listDepth: 1));
    expect(shapes[3].ordinal, 1);
    expect(shapes[4].ordinal, 2, reason: '`1. 1.` reads 1, 2');
    expect(shapes[6].task, isFalse);
    expect(shapes[7].task, isTrue);
  });

  test("a quote's depth, on its lazy lines too", () {
    final shapes = _shapes('> a\n> > b\nlazy\n\nprose');
    expect(shapes[0].quoteDepth, 1);
    expect(shapes[1].quoteDepth, 2);
    expect(shapes[2].quoteDepth, greaterThan(0), reason: 'still quoted');
    expect(shapes[4], LineShape.none);
  });

  test('a thematic break is a rule, and frontmatter is not', () {
    final shapes = _shapes('---\ntitle: x\n---\n\ntext\n\n---\n');
    expect(shapes[0].rule, isFalse);
    expect(shapes[2].rule, isFalse);
    expect(shapes[6].rule, isTrue);
  });

  test("a code block's rows are its box, the fences its top and bottom", () {
    // `live` drew a code block as plain rows on the page, where the read
    // view draws a box: each row now says which part of the box it is.
    final shapes = _shapes(
      'text\n\n```dart\nvar a;\nvar b;\n```\n\n```\n```\n\n    indented\n',
    );
    expect(shapes[0].code, isNull);
    expect(shapes[2].code, CodeRow.top);
    expect(shapes[3].code, CodeRow.middle);
    expect(shapes[4].code, CodeRow.middle);
    expect(shapes[5].code, CodeRow.bottom);
    expect(shapes[6], LineShape.none);
    expect(shapes[7].code, CodeRow.top);
    expect(shapes[8].code, CodeRow.bottom);
    expect(shapes[10].code, CodeRow.only);
  });
}
