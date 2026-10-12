// The read view's columns (#729, `docs/records/note-columns.md`): side by
// side where the width allows, stacked where it does not, each column
// windowed by a sliver of its own.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/read_selection.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

MathCache _syncCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

Future<MarkdownReadViewState> _pump(
  WidgetTester tester,
  String document, {
  double width = 1000,
  double height = 800,
  ScrollController? controller,
  List<ReadSelectionAction>? selectionActions,
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          buffer: SourceBuffer.fromText(document),
          parser: ReadParser(),
          mathCache: _syncCache(),
          controller: controller,
          selectionActions: selectionActions,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownReadViewState>(find.byType(MarkdownReadView));
}

const String _two = '''
Before.

:::: columns
::: {.column width="40%"}
Left
:::

::: column
Right
:::
::::

After.
''';

Rect _rectOf(WidgetTester tester, String text) =>
    tester.getRect(find.textContaining(text));

void main() {
  testWidgets('two columns sit side by side on a wide pane', (tester) async {
    await _pump(tester, _two);
    final left = _rectOf(tester, 'Left');
    final right = _rectOf(tester, 'Right');
    expect(right.left, greaterThan(left.left + 200));
    expect((right.top - left.top).abs(), lessThan(1));
    // The note goes on under the block, in order.
    final before = _rectOf(tester, 'Before.');
    final after = _rectOf(tester, 'After.');
    expect(before.bottom, lessThanOrEqualTo(left.top));
    expect(after.top, greaterThan(left.bottom));
  });

  testWidgets('the shares split the width after the gap', (tester) async {
    await _pump(tester, _two);
    final left = _rectOf(tester, 'Left');
    final right = _rectOf(tester, 'Right');
    // The left column is 40 % of the width after the gap: the right
    // column starts past it, a gap of 1.5 em (21 px) on.
    final pane = tester.getRect(find.byType(MarkdownReadView));
    final share = right.left - left.left;
    expect(share, greaterThan(0.35 * pane.width));
    expect(share, lessThan(0.5 * pane.width));
  });

  testWidgets('on a phone the columns stack, in source order', (tester) async {
    await _pump(tester, _two, width: 360);
    final left = _rectOf(tester, 'Left');
    final right = _rectOf(tester, 'Right');
    expect(right.top, greaterThan(left.bottom));
    expect((right.left - left.left).abs(), lessThan(1));
  });

  testWidgets('three columns that do not fit wrap two and one', (tester) async {
    await _pump(
      tester,
      ':::: columns\n::: column\nOne\n:::\n::: column\nTwo\n:::\n'
      '::: column\nThree\n:::\n::::\n',
      width: 640,
    );
    final one = _rectOf(tester, 'One');
    final two = _rectOf(tester, 'Two');
    final three = _rectOf(tester, 'Three');
    expect((two.top - one.top).abs(), lessThan(1));
    expect(two.left, greaterThan(one.right));
    expect(three.top, greaterThan(one.bottom));
    expect((three.left - one.left).abs(), lessThan(1));
  });

  testWidgets('a selectable view stacks the columns, in source order', (
    tester,
  ) async {
    await _pump(tester, _two, selectionActions: const []);
    final left = _rectOf(tester, 'Left');
    final right = _rectOf(tester, 'Right');
    expect(right.top, greaterThan(left.bottom));
  });

  testWidgets('columns in a list item stand at its indent', (tester) async {
    await _pump(
      tester,
      '- Item\n\n  :::: columns\n  ::: column\n  Left\n  :::\n'
      '  ::: column\n  Right\n  :::\n  ::::\n',
    );
    final item = _rectOf(tester, 'Item');
    final left = _rectOf(tester, 'Left');
    final right = _rectOf(tester, 'Right');
    expect((left.left - item.left).abs(), lessThan(1));
    expect((right.top - left.top).abs(), lessThan(1));
  });

  testWidgets('a long columns block builds what the viewport shows', (
    tester,
  ) async {
    final note = StringBuffer(':::: columns\n::: column\n');
    for (var at = 0; at < 1000; at++) {
      note.writeln('Left paragraph $at.\n');
    }
    note.writeln(':::\n::: column');
    for (var at = 0; at < 1000; at++) {
      note.writeln('Right paragraph $at.\n');
    }
    note.writeln(':::\n::::\nAfter.');
    final controller = ScrollController();
    final state = await _pump(tester, note.toString(), controller: controller);
    // Two columns of 2 000 blocks each: a viewport of them, not the block.
    expect(state.builtBlocks, lessThan(200));
    final built = state.builtBlocks;
    controller.jumpTo(controller.position.maxScrollExtent / 2);
    await tester.pump();
    expect(state.builtBlocks - built, lessThan(200));
    // Both columns are drawn where the reader is.
    expect(find.textContaining('Left paragraph'), findsWidgets);
    expect(find.textContaining('Right paragraph'), findsWidgets);
  });

  testWidgets('a jump to a line in a column lands on the block', (
    tester,
  ) async {
    final note = StringBuffer();
    for (var at = 0; at < 200; at++) {
      note.writeln('Paragraph $at.\n');
    }
    note.write(_two);
    for (var at = 0; at < 200; at++) {
      note.writeln('\nMore $at.');
    }
    final controller = ScrollController();
    final state = await _pump(tester, note.toString(), controller: controller);
    // `Right` is line 400 + 9.
    state.jumpToLine(409);
    for (var frame = 0; frame < 15; frame++) {
      await tester.pump();
    }
    final right = _rectOf(tester, 'Right');
    expect(right.top, greaterThanOrEqualTo(0));
    expect(right.top, lessThan(100));
  });

  testWidgets('columns in a callout sit side by side inside its box', (
    tester,
  ) async {
    await _pump(tester, '''
> [!note]
> :::: columns
> ::: column
> Left
> :::
> ::: column
> Right
> :::
> ::::
''');
    final left = _rectOf(tester, 'Left');
    final right = _rectOf(tester, 'Right');
    expect((right.top - left.top).abs(), lessThan(1));
    expect(right.left, greaterThan(left.right));
  });

  testWidgets('columns inside a column stack', (tester) async {
    await _pump(tester, '''
:::::: columns
::: column
:::: columns
::: column
Inner one
:::
::: column
Inner two
:::
::::
:::
::: column
Outer
:::
::::::
''');
    final one = _rectOf(tester, 'Inner one');
    final two = _rectOf(tester, 'Inner two');
    final outer = _rectOf(tester, 'Outer');
    expect(two.top, greaterThan(one.bottom));
    // Beside them: the outer column's text is past its own band, the inner
    // one's past three.
    expect(outer.left, greaterThan(one.right));
    expect(outer.top, lessThan(one.bottom));
  });
}
