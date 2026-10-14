// The library-wide rows of the wikilink panel (#874): a long note name or
// block id is cut with an ellipsis, it never overflows the row.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/markdown/render/wikilink_panel.dart';

void main() {
  final long = 'n' * 120;

  Future<void> pump(
    WidgetTester tester,
    WikilinkPanelKind kind,
    SuggestEntry entry,
  ) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 220,
            child: WikilinkPanel(
              kind: kind,
              entries: <SuggestEntry>[entry],
              selected: 0,
              query: '',
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('a heading row across the library survives a 120-char note', (
    tester,
  ) async {
    await pump(
      tester,
      WikilinkPanelKind.headings,
      HeadingSuggestion('Team plan', path: 'Work/$long.md', target: 'x'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a block row across the library survives a 120-char id', (
    tester,
  ) async {
    await pump(
      tester,
      WikilinkPanelKind.blocks,
      BlockIdSuggestion(
        long,
        excerpt: 'The first idea',
        path: 'Work/$long.md',
        target: 'x',
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
