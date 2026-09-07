// T-M3-05 AC: debounced (~150 ms) query box, ranked results with path +
// highlighted snippet, paging, superseded queries dropped, click opens the
// note, and the Words/Contains toggle (which is T-M3-08's UI surface).
import 'dart:async';

import 'package:copist/src/search/search_repo.dart';
import 'package:copist/src/ui/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_search_source.dart';

SearchHit _hit(String path, {String? title, String? snippet}) => SearchHit(
  noteId: 0,
  path: path,
  title: title ?? path,
  snippet: snippet ?? '',
);

void main() {
  late FakeLibrarySession session;
  late FakeSearchSource source;
  final opened = <String>[];

  Widget buildApp(SearchSource searchSource) {
    return MaterialApp(
      home: Scaffold(
        body: SearchScreen(
          controller: session,
          onOpenNote: opened.add,
          source: searchSource,
        ),
      ),
    );
  }

  setUp(() {
    session = FakeLibrarySession();
    source = FakeSearchSource();
    opened.clear();
  });

  testWidgets('no query: hint, no results', (tester) async {
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    expect(find.text('Type to search the library'), findsOne);
  });

  testWidgets('query debounces: one search per pause, results appear', (
    tester,
  ) async {
    source.hits = [_hit('Docs/Note One.md', title: 'Note One')];
    await tester.pumpWidget(buildApp(source));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('search-query')), 'no');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byKey(const Key('search-query')), 'note');
    // Before the debounce window elapses, no query has run.
    expect(source.queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    // The source receives the built FTS expression (last
    // token prefixed), after the debounce window.
    expect(source.queries, ['"note"*']);
    expect(find.text('Note One'), findsOne);
    expect(find.text('Docs/Note One.md'), findsOne);
  });

  testWidgets('a superseded query does not replace the newer results', (
    tester,
  ) async {
    final slow = _SlowSource();
    await tester.pumpWidget(buildApp(slow));
    await tester.pump();

    // First query starts and stays pending; the second supersedes it, so
    // when both complete only the second one's results may render.
    await tester.enterText(find.byKey(const Key('search-query')), 'first');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.enterText(find.byKey(const Key('search-query')), 'second');
    await tester.pump(const Duration(milliseconds: 160));
    expect(slow.started, 2);
    await tester.pump();
    await tester.pump();
    expect(find.text('Second hit'), findsOne);
    expect(find.text('First hit'), findsNothing);
  });

  testWidgets('clicking a result opens the note path', (tester) async {
    source.hits = [_hit('Folder/Clicky.md')];
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'clicky');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();

    await tester.tap(find.byKey(const Key('search-hit-Folder/Clicky.md')));
    expect(opened, ['Folder/Clicky.md']);
  });

  testWidgets('snippet marks render highlighted text', (tester) async {
    source.hits = [
      _hit('a.md', title: 'A', snippet: 'before <mark>match</mark> after'),
    ];
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'match');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();

    final rich = tester.widget<RichText>(
      find
          .descendant(
            of: find.byKey(const Key('search-hit-a.md')),
            matching: find.byType(RichText),
          )
          .last,
    );
    final marked = rich.text
        .toPlainText(); // spans concatenate: no mark tags left
    expect(marked, contains('match'));
    expect(marked, isNot(contains('<mark>')));
  });

  testWidgets('contains mode filters via the source and shows the mode', (
    tester,
  ) async {
    source.hits = [
      _hit('deep.md', title: 'Deep', snippet: 'the quick brown fox'),
      _hit('other.md', title: 'Other', snippet: 'nothing here'),
    ];
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'quick');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(find.text('Deep'), findsOne);
    expect(find.text('Other'), findsOne);

    await tester.tap(find.text('Contains'));
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(find.text('Deep'), findsOne);
    expect(find.text('Other'), findsNothing);
  });

  testWidgets('empty results show the no-matches state; clearing resets', (
    tester,
  ) async {
    source.hits = [];
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'zzz');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(find.text('No matches'), findsOne);

    await tester.tap(find.byKey(const Key('search-clear')));
    await tester.pump();
    expect(find.text('Type to search the library'), findsOne);
  });

  testWidgets('paging: 50 hits per page, Show more reveals the rest', (
    tester,
  ) async {
    // A tall surface so every page's items (and the Show more slot) are
    // actually built by the lazy ListView.
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    source.hits = [for (var i = 0; i < 60; i++) _hit('n$i.md', title: 'n$i')];
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'n1');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();

    expect(find.text('n0'), findsOne);
    expect(find.text('n49'), findsOne);
    expect(find.text('n50'), findsNothing);
    await tester.tap(find.byKey(const Key('search-load-more')));
    await tester.pump();
    expect(find.text('n50'), findsOne);
    expect(find.byKey(const Key('search-load-more')), findsNothing);
  });

  testWidgets('one-character queries are not issued; the box hints', (
    tester,
  ) async {
    // A one-character FTS prefix ("e"*) expands to every term starting
    // with that letter — multi-second MATCHes on a real library — so the
    // screen never issues them (T-M3-09 device report).
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'e');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(source.queries, isEmpty);
    expect(find.text('Type at least 2 characters'), findsOne);

    // Two characters search normally.
    await tester.enterText(find.byKey(const Key('search-query')), 'en');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(source.queries, ['"en"*']);
    expect(find.text('Type at least 2 characters'), findsNothing);
  });

  testWidgets('contains mode also needs two characters', (tester) async {
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    await tester.tap(find.text('Contains'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'x');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(source.queries, isEmpty);
    expect(find.text('Type at least 2 characters'), findsOne);

    await tester.enterText(find.byKey(const Key('search-query')), 'xy');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(source.queries, ['xy']);
  });

  testWidgets('a pending query superseded by a too-short term never lands', (
    tester,
  ) async {
    final hang = _HangingSource();
    await tester.pumpWidget(buildApp(hang));
    await tester.pump();

    // The first query starts and stays pending...
    await tester.enterText(find.byKey(const Key('search-query')), 'first');
    await tester.pump(const Duration(milliseconds: 160));
    expect(hang.started, 1);
    // ...then the user deletes down to a single character: the in-flight
    // query is superseded so its late results cannot replace the hint.
    await tester.enterText(find.byKey(const Key('search-query')), 'f');
    await tester.pump();
    expect(find.text('Type at least 2 characters'), findsOne);
    hang.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('First hit'), findsNothing);
    expect(find.text('Type at least 2 characters'), findsOne);
  });
}

/// A source whose searches complete only after a microtask — for the
/// supersede assertion (the late query must win over the earlier,
/// still-pending one).
final class _SlowSource implements SearchSource {
  int _id = 0;
  int started = 0;

  @override
  int begin() => ++_id;

  @override
  bool isCurrent(int id) => id == _id;

  @override
  Future<List<SearchHit>> search(
    String? query, {
    required int id,
    int limit = 200,
  }) {
    started++;
    final queryAtStart = query;
    return Future<List<SearchHit>>.delayed(
      Duration.zero,
      () => isCurrent(id)
          ? [
              _hit(
                queryAtStart == 'first' ? 'first.md' : 'second.md',
                title: queryAtStart == 'first' ? 'First hit' : 'Second hit',
              ),
            ]
          : const [],
    );
  }

  @override
  Future<List<SearchHit>> searchContains(
    String pattern, {
    required int id,
    int limit = 200,
  }) {
    return search(pattern, id: id, limit: limit);
  }
}

/// A source whose queries stay pending until [complete] — for the
/// supersede assertion on the too-short path (the late result must not
/// replace the hint).
final class _HangingSource implements SearchSource {
  int _id = 0;
  int started = 0;
  final Completer<void> _gate = Completer<void>();

  @override
  int begin() => ++_id;

  @override
  bool isCurrent(int id) => id == _id;

  void complete() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<List<SearchHit>> search(
    String? query, {
    required int id,
    int limit = 200,
  }) async {
    started++;
    await _gate.future;
    if (!isCurrent(id)) return const [];
    return [_hit('first.md', title: 'First hit')];
  }

  @override
  Future<List<SearchHit>> searchContains(
    String pattern, {
    required int id,
    int limit = 200,
  }) {
    return search(pattern, id: id, limit: limit);
  }
}
