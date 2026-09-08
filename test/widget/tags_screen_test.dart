// T-M3-06 AC: tag list with counts (frontmatter + inline sources), tap a
// tag → its notes in path order → open; normalization is the indexer's job
// (unit-covered), the screen shows the stored names.
import 'package:copist/src/ui/tags_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_tag_source.dart';

void main() {
  late FakeLibrarySession session;
  late FakeTagSource source;
  final opened = <String>[];

  Widget buildApp() {
    return MaterialApp(
      home: Scaffold(
        body: TagsScreen(
          controller: session,
          onOpenNote: opened.add,
          onBack: () {},
          sourceOverride: source,
        ),
      ),
    );
  }

  setUp(() {
    session = FakeLibrarySession();
    source = FakeTagSource(
      tags: {
        'work': ['Docs/a.md', 'b.md'],
        'ideas': ['Docs/a.md', 'Docs/b.md', 'c.md'],
        'solo': ['x.md'],
      },
    );
    opened.clear();
  });

  testWidgets('tag list shows counts, most used first', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('tags-list')), findsOne);
    expect(find.text('#ideas'), findsOne);
    expect(find.text('#work'), findsOne);
    expect(find.text('#solo'), findsOne);
    // ideas (3) before work (2) before solo (1); the trailing count text.
    final ideasTile = tester.widget<ListTile>(find.byKey(const Key('tag-0')));
    expect(
      (ideasTile.trailing! as Text).data,
      '3',
    );
  });

  testWidgets('tapping a tag shows its notes in path order', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('#work'));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('tag-notes')), findsOne);
    final tiles = tester.widgetList<ListTile>(
      find.byWidgetPredicate(
        (w) => w is ListTile && w.key.toString().contains('tag-note-'),
      ),
    );
    final paths = [
      for (final tile in tiles) (tile.subtitle! as Text).data!,
    ];
    expect(paths, ['Docs/a.md', 'b.md']); // path order, not map order
  });

  testWidgets('tapping a note opens it; back returns to the tag list', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('#solo'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('tag-note-x.md')));
    expect(opened, ['x.md']);

    await tester.tap(find.byKey(const Key('tags-back')));
    await tester.pump();
    expect(find.byKey(const Key('tags-list')), findsOne);
  });

  testWidgets('no tags: empty state', (tester) async {
    source.tags = {};
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump();
    expect(
      find.text('No tags yet — add a #tag or frontmatter tags'),
      findsOne,
    );
  });
}
