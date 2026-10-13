// #674: a Markdown link with no target goes nowhere when tapped in the
// preview, as on a slide. #844 / #845: a link to a block, or to a heading by
// its path, brings the note to the line it names.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/ui/note_links.dart';

import '../fakes/fake_link_source.dart';

void main() {
  late BuildContext context;

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  testWidgets('a link with no target resolves nothing (#674)', (tester) async {
    await pumpHost(tester);
    final source = FakeLinkSource(notes: ['a.md']);
    final targets = NoteLinkTargets(
      source: source,
      notePath: '/lib/n.md',
      libraryRoot: '/lib',
      newItemLocation: NewItemLocation.openNoteFolder,
      outline: const [],
      jumpToHeading: (_) {},
    );

    await openHref(context, '', targets);
    await openHref(context, '  ', targets);
    expect(source.queries, isEmpty);

    await openHref(context, 'a.md', targets);
    expect(source.queries, isNotEmpty, reason: 'a link with one does');
  });

  group('following a link to a place in a note (#844, #845)', () {
    // # Top
    // ## A
    // ### C
    // ## B
    final outline = outlineOfText('# Top\n## A\n### C\n## B\n');
    final blocks = <BlockAnchor>[
      const BlockAnchor(id: '37066d', line: 6, excerpt: 'A paragraph'),
      const BlockAnchor(id: 'Quote-2', line: 12, excerpt: 'A quote'),
    ];

    NoteLinkTargets targets({
      required List<int> jumps,
      List<(String, String?)>? opened,
      List<int>? blockReads,
      List<OutlineEntry>? headings,
    }) => NoteLinkTargets(
      source: FakeLinkSource(notes: ['other.md', 'n.md']),
      notePath: '/lib/n.md',
      libraryRoot: '/lib',
      newItemLocation: NewItemLocation.openNoteFolder,
      outline: headings ?? outline,
      jumpToHeading: jumps.add,
      blocks: () async {
        blockReads?.add(1);
        return blocks;
      },
      onOpenNote: opened == null
          ? null
          : (path, anchor) => opened.add((path, anchor)),
    );

    testWidgets('[[#^id]] brings the block into view, read only then', (
      tester,
    ) async {
      await pumpHost(tester);
      final jumps = <int>[];
      final reads = <int>[];
      final link = targets(jumps: jumps, blockReads: reads);

      await openWiki(context, parseWikiRef('#A'), link);
      expect(reads, isEmpty, reason: 'a heading never asks for the blocks');

      await openWiki(context, parseWikiRef('#^37066d'), link);
      expect(jumps, [1, 6]);
      expect(reads, hasLength(1));
    });

    testWidgets('an id is matched exactly, and a missing one says so', (
      tester,
    ) async {
      await pumpHost(tester);
      final jumps = <int>[];
      final link = targets(jumps: jumps);

      await openWiki(context, parseWikiRef('#^quote-2'), link);
      await tester.pump();
      expect(jumps, isEmpty, reason: 'the case differs: another id');
      expect(find.text('Block not found'), findsOneWidget);

      await openWiki(context, parseWikiRef('#^Quote-2'), link);
      expect(jumps, [12]);
    });

    testWidgets('[[#A#C]] lands on C, [[#B#C]] is not found', (tester) async {
      await pumpHost(tester);
      final jumps = <int>[];
      final link = targets(jumps: jumps);

      await openWiki(context, parseWikiRef('#A#C'), link);
      expect(jumps, [2]);

      await openWiki(context, parseWikiRef('#B#C'), link);
      await tester.pump();
      expect(jumps, [2]);
      expect(find.text('Heading not found'), findsOneWidget);
    });

    testWidgets('a heading with a # in its text is followed whole', (
      tester,
    ) async {
      await pumpHost(tester);
      final jumps = <int>[];
      final link = targets(
        jumps: jumps,
        headings: outlineOfText('# Top\n## C#\n## Issue #12\n'),
      );

      await openWiki(context, parseWikiRef('#C#'), link);
      await openWiki(context, parseWikiRef('#Issue #12'), link);
      expect(jumps, [1, 2]);
      expect(find.text('Heading not found'), findsNothing);
    });

    testWidgets('a link to another note carries the fragment to it', (
      tester,
    ) async {
      await pumpHost(tester);
      final opened = <(String, String?)>[];
      final link = targets(jumps: <int>[], opened: opened);

      await openWiki(context, parseWikiRef('other#^37066d'), link);
      await openWiki(context, parseWikiRef('other#A#C'), link);
      await openWiki(context, parseWikiRef('other#Heading'), link);

      expect(opened, [
        ('other.md', '^37066d'),
        ('other.md', 'A#C'),
        ('other.md', 'Heading'),
      ]);
    });

    testWidgets('a note linking to itself jumps without opening', (
      tester,
    ) async {
      await pumpHost(tester);
      final jumps = <int>[];
      final opened = <(String, String?)>[];
      final link = targets(jumps: jumps, opened: opened);

      await openWiki(context, parseWikiRef('n#^37066d'), link);

      expect(opened, isEmpty);
      expect(jumps, [6]);
    });

    testWidgets('a Markdown link to a block works the same', (tester) async {
      await pumpHost(tester);
      final opened = <(String, String?)>[];
      final jumps = <int>[];
      final link = targets(jumps: jumps, opened: opened);

      await openHref(context, 'other.md#^37066d', link);
      await openHref(context, '#^Quote-2', link);

      expect(opened, [('other.md', '^37066d')]);
      expect(jumps, [12]);
    });
  });
}
