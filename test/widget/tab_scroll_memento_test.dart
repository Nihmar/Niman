// #1075 and #1077: where a tab was scrolled is a place in the note — the
// source line at the top of whichever pane is on stage — and it survives the
// editor being torn down (evicted from the kept-alive tabs, or remounted by
// a resize across the wide/narrow breakpoint), when the panes are gone by
// the time the note view hands in its memento. It restores in a window of
// another width.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/note_memento.dart';

import '../fakes/detail_pane_harness.dart';

void main() {
  setUp(() {
    paneKeys.clear();
    paneNotes
      ..clear()
      ..['a.md'] = [for (var i = 0; i < 300; i++) 'Paragraph $i\n'].join('\n')
      ..['b.md'] = 'beta text';
  });

  Widget pane(
    String active, {
    required void Function(String, NoteMemento) onMemento,
    Map<String, NoteMemento> mementos = const {},
    bool preview = false,
    double width = 800,
  }) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          height: 600,
          child: detailPane(
            active,
            tracker: UnsavedTracker(),
            onMemento: onMemento,
            mementos: mementos,
            showPreview: preview,
          ),
        ),
      ),
    ),
  );

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  MarkdownReadViewState reader(WidgetTester tester) =>
      tester.state<MarkdownReadViewState>(find.byType(MarkdownReadView));

  testWidgets('the memento a torn-down editor hands in has its place', (
    tester,
  ) async {
    final handed = <String, NoteMemento>{};
    await tester.pumpWidget(pane('a.md', onMemento: (p, m) => handed[p] = m));
    await tester.pumpAndSettle();
    paneEditorOf(tester, 'a.md').showAnchor((line: 120, fraction: 0.0));
    await tester.pumpAndSettle();
    final top = paneEditorOf(tester, 'a.md').topAnchor!;
    expect(top.line, greaterThan(50));

    // The editor goes: the tab fell out of the kept-alive ones.
    await teardown(tester);
    expect(handed['a.md']?.scrollLine, top.line);
    expect(handed['a.md']?.scrollOffset, isNull, reason: 'no pixels');
  });

  testWidgets('the editor comes back at the same line in another width', (
    tester,
  ) async {
    final handed = <String, NoteMemento>{};
    await tester.pumpWidget(pane('a.md', onMemento: (p, m) => handed[p] = m));
    await tester.pumpAndSettle();
    paneEditorOf(tester, 'a.md').showAnchor((line: 160, fraction: 0.0));
    await tester.pumpAndSettle();
    final line = paneEditorOf(tester, 'a.md').topAnchor!.line;
    await teardown(tester);

    await tester.pumpWidget(
      pane(
        'a.md',
        onMemento: (p, m) => handed[p] = m,
        mementos: {'a.md': handed['a.md']!},
        width: 420,
      ),
    );
    await tester.pumpAndSettle();
    expect(paneEditorOf(tester, 'a.md').topAnchor!.line, line);
    await teardown(tester);
  });

  testWidgets('the preview’s reading place is remembered too', (tester) async {
    final handed = <String, NoteMemento>{};
    await tester.pumpWidget(
      pane('a.md', onMemento: (p, m) => handed[p] = m, preview: true),
    );
    await tester.pumpAndSettle();
    reader(tester).showAnchor((line: 200, fraction: 0.0));
    await tester.pumpAndSettle();
    final line = reader(tester).topAnchor!.line;
    expect(line, greaterThan(100));
    await teardown(tester);
    expect(handed['a.md']?.scrollLine, line);

    // Another width: the same top line shows, not the same distance.
    await tester.pumpWidget(
      pane(
        'a.md',
        onMemento: (p, m) => handed[p] = m,
        mementos: {'a.md': handed['a.md']!},
        preview: true,
        width: 380,
      ),
    );
    await tester.pumpAndSettle();
    expect(reader(tester).topAnchor!.line, closeTo(line, 1));
    await teardown(tester);
  });

  testWidgets('a memento with pixels still puts the editor back', (
    tester,
  ) async {
    await tester.pumpWidget(
      pane(
        'a.md',
        onMemento: (_, _) {},
        mementos: {'a.md': const NoteMemento(scrollOffset: 900)},
      ),
    );
    await tester.pumpAndSettle();
    expect(paneEditorOf(tester, 'a.md').scrollOffset, 900);
    await teardown(tester);
  });
}
