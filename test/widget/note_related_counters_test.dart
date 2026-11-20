// #1296: the status row's two counters on the wide layout -- how many notes
// link here (with a `+` past the first page) and how many open tasks do. They
// follow the library's index and the tasks as they move, and the note they
// are for.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_related_counters.dart';
import 'package:niman/src/workspace/workspace.dart';

import '../fakes/fake_link_source.dart';
import '../fakes/note_tasks_fixture.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

FakeLinkSource _library() {
  final links = FakeLinkSource(notes: ['Newton.md', 'Optics.md']);
  links.referrers['Newton.md'] = ['Laws/Three laws.md', 'Optics.md', 'Pic.md'];
  links.referrers['Optics.md'] = ['Newton.md'];
  return links;
}

String? _links(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('links-to-note-count'))).data;

void main() {
  final shown = <DockPane>[];
  setUp(shown.clear);

  NoteRelatedCounters counters(
    FakeLinkSource? links, {
    String? path = 'Newton.md',
  }) => NoteRelatedCounters(
    linkSource: links,
    path: path,
    tasks: null,
    onShow: shown.add,
  );

  testWidgets('count the notes that link here, with the icon and a tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(_app(counters(_library())));
    expect(
      find.byIcon(Icons.link_outlined),
      findsOneWidget,
      reason: 'the icon is there before the index answers',
    );
    expect(find.byKey(const Key('links-to-note-count')), findsNothing);
    await tester.pump();

    expect(_links(tester), '3');
    expect(
      tester
          .widget<Tooltip>(
            find.ancestor(
              of: find.byIcon(Icons.link_outlined),
              matching: find.byType(Tooltip),
            ),
          )
          .message,
      'Links to this note',
    );
  });

  testWidgets('a zero is shown, muted', (tester) async {
    await tester.pumpWidget(
      _app(counters(FakeLinkSource(notes: ['Lonely.md']), path: 'Lonely.md')),
    );
    await tester.pump();
    expect(_links(tester), '0');
    final muted = tester
        .widget<Text>(find.byKey(const Key('links-to-note-count')))
        .style!
        .color!;
    await tester.pumpWidget(_app(counters(_library())));
    await tester.pump();
    final plain = tester
        .widget<Text>(find.byKey(const Key('links-to-note-count')))
        .style!
        .color!;
    expect(muted.a, lessThan(plain.a));
  });

  testWidgets('a tap asks for the Links pane', (tester) async {
    await tester.pumpWidget(_app(counters(_library())));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.link_outlined));
    expect(shown, [DockPane.links]);
  });

  testWidgets('past a page the count says so with a +', (tester) async {
    final links = FakeLinkSource(notes: ['Hub.md'])..referrersPage = 2;
    links.referrers['Hub.md'] = ['a.md', 'b.md', 'c.md'];
    await tester.pumpWidget(_app(counters(links, path: 'Hub.md')));
    await tester.pump();
    expect(_links(tester), '2+');
  });

  testWidgets('follow the library when its index moves', (tester) async {
    final links = _library();
    await tester.pumpWidget(_app(counters(links)));
    await tester.pump();
    expect(_links(tester), '3');

    links.referrers['Newton.md'] = ['Optics.md'];
    links.announceChange();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(_links(tester), '1');
  });

  testWidgets('follow the note they are for', (tester) async {
    final links = _library();
    await tester.pumpWidget(_app(counters(links)));
    await tester.pump();
    expect(_links(tester), '3');

    await tester.pumpWidget(_app(counters(links, path: 'Optics.md')));
    await tester.pump();

    expect(_links(tester), '1');
  });

  testWidgets('draw nothing without a library or for a note outside one', (
    tester,
  ) async {
    await tester.pumpWidget(_app(counters(null)));
    expect(find.byIcon(Icons.link_outlined), findsNothing);
    expect(find.byType(Tooltip), findsNothing);

    await tester.pumpWidget(_app(counters(_library(), path: null)));
    expect(find.byIcon(Icons.link_outlined), findsNothing);
  });

  testWidgets('the tasks counter follows the tasks; both ask for their pane', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => NoteTasksFixture.open(
        todo: ['One [[House/Repairs]]', 'Two [[House/Repairs]]'],
      ),
    ))!;
    addTearDown(fixture.dispose);
    await tester.pumpWidget(
      _app(
        NoteRelatedCounters(
          linkSource: fixture.links,
          path: 'House/Repairs.md',
          tasks: fixture.host,
          onShow: shown.add,
        ),
      ),
    );
    await fixture.settle(tester);
    String? open() =>
        tester.widget<Text>(find.byKey(const Key('tasks-for-note-count'))).data;
    expect(open(), '2');
    expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);

    await tester.runAsync(() => fixture.controller.add('Three [[Repairs]]'));
    await fixture.settle(tester);
    expect(open(), '3');

    await tester.tap(find.byIcon(Icons.check_box_outlined));
    await tester.tap(find.byIcon(Icons.link_outlined));
    expect(shown, [DockPane.tasks, DockPane.links]);
  });
}
