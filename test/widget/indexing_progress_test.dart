// A library indexed for the first time opens on its tree and reads its notes
// behind it (#1073, #1068). While it does, the tree's footer counts the notes
// read, and Search and Tags say what they list may be partial.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/library/indexing_status.dart';
import 'package:niman/src/ui/search_screen.dart';
import 'package:niman/src/ui/shell_tree_footer.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tags_screen.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_search_source.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() {
    session = FakeLibrarySession();
    IndexingStatus.contentOwed.value = false;
  });

  tearDown(() async {
    IndexingStatus.contentOwed.value = false;
    await session.dispose();
  });

  Future<void> pumpFooter(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const Spacer(),
            TreeFooterBar(
              controller: session,
              onNewItem: (_) {},
              syncButton: const SizedBox.shrink(),
              sortToggle: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets('the footer counts the notes read while the pass runs', (
    tester,
  ) async {
    session.indexing = const IndexProgress(file: 'a.md', done: 12, of: 400);
    await pumpFooter(tester);
    session.notify();
    await tester.pump();

    expect(
      find.text(
        '${AppStrings.indexingTitle} ${AppStrings.indexingCount(12, 400)}',
      ),
      findsOne,
    );
  });

  testWidgets('the footer line goes with the pass and moves no button', (
    tester,
  ) async {
    await pumpFooter(tester);
    final before = tester.getTopLeft(find.byKey(const Key('new-item-menu')));
    expect(find.byKey(const Key('indexing-footer')), findsNothing);

    session
      ..indexing = const IndexProgress(file: 'a.md', done: 1, of: 3)
      ..notify();
    await tester.pump();
    expect(find.byKey(const Key('indexing-footer')), findsOne);
    expect(
      tester.getTopLeft(find.byKey(const Key('new-item-menu'))),
      before,
      reason: 'the line comes in above the bar',
    );

    session
      ..indexing = null
      ..notify();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('indexing-footer')), findsNothing);
  });

  testWidgets('Search says its results may be partial while notes are read', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            controller: session,
            onOpenNote: (_) {},
            source: FakeSearchSource(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('indexing-notice')), findsNothing);

    IndexingStatus.contentOwed.value = true;
    await tester.pump();
    expect(find.text(AppStrings.indexingPartial), findsOne);

    IndexingStatus.contentOwed.value = false;
    await tester.pump();
    expect(find.byKey(const Key('indexing-notice')), findsNothing);
  });

  testWidgets('Tags says its list may be partial while notes are read', (
    tester,
  ) async {
    IndexingStatus.contentOwed.value = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagsScreen(
            controller: session,
            onOpenNote: (_) {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.indexingPartial), findsOne);
  });
}
