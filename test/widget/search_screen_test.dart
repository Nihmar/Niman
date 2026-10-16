// T-M3-05 AC: debounced (~150 ms) query box, ranked results with path +
// highlighted snippet, paging, superseded queries dropped, click opens the
// note, and the Words/Contains toggle (which is T-M3-08's UI surface).
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/search_request.dart';
import 'package:niman/src/ui/search_screen.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_replace_source.dart';
import '../fakes/fake_search_source.dart';
import '../fakes/shell_harness.dart';

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

  Widget buildApp(
    SearchSource searchSource, {
    ReplaceSource? replace,
    bool dense = false,
  }) {
    return MaterialApp(
      theme: dense ? ThemeData(visualDensity: VisualDensity.compact) : null,
      home: Scaffold(
        body: SearchScreen(
          controller: session,
          onOpenNote: opened.add,
          source: searchSource,
          replaceSource: replace,
        ),
      ),
    );
  }

  Widget searchWith(SearchCommands commands) => MaterialApp(
    home: Scaffold(
      body: SearchScreen(
        controller: session,
        onOpenNote: opened.add,
        source: source,
        commands: commands,
      ),
    ),
  );

  setUp(() {
    session = FakeLibrarySession();
    source = FakeSearchSource();
    opened.clear();
  });

  testWidgets('a right click on a hit opens its menu; its rows open the hit '
      'in a new tab, beside or in the tree (#712)', (tester) async {
    source.hits = [_hit('a.md'), _hit('b.md')];
    final asked = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: VisualDensity.compact),
        home: Scaffold(
          body: SearchScreen(
            controller: session,
            onOpenNote: opened.add,
            source: source,
            hitOpens: (
              newTab: (path) => asked.add('tab $path'),
              beside: (path) => asked.add('beside $path'),
              reveal: (path) => asked.add('reveal $path'),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('search-query')), 'note');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    for (final action in ['newtab', 'beside', 'reveal', 'open']) {
      await tester.tap(
        find.byKey(const Key('search-hit-b.md')),
        buttons: kSecondaryButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('search-hit-action-$action')));
      await tester.pumpAndSettle();
    }
    expect(asked, ['tab b.md', 'beside b.md', 'reveal b.md']);
    expect(opened, ['b.md']);

    // A middle click opens in a new tab too.
    await tester.tap(
      find.byKey(const Key('search-hit-a.md')),
      buttons: kTertiaryButton,
    );
    await tester.pump();
    expect(asked.last, 'tab a.md');
  });

  testWidgets('the arrows in the field mark a hit, Enter opens it (#712)', (
    tester,
  ) async {
    source.hits = [_hit('a.md'), _hit('b.md')];
    await tester.pumpWidget(buildApp(source));
    await tester.enterText(find.byKey(const Key('search-query')), 'note');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(opened, isEmpty);
    ListTile tile(String path) =>
        tester.widget<ListTile>(find.byKey(Key('search-hit-$path')));
    expect(tile('a.md').selected, isTrue);
    expect(tile('b.md').selected, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, ['a.md']);
  });

  testWidgets('no query: hint, no results', (tester) async {
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    expect(find.textContaining('Type to search the library'), findsOne);
  });

  testWidgets('a pointer gets words/contains as a field toggle (#712)', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(source, dense: true));
    await tester.pump();
    expect(find.byKey(const Key('search-mode')), findsNothing);
    final toggle = find.byKey(const Key('search-mode-toggle'));
    expect(toggle, findsOne);
    expect(tester.widget<IconButton>(toggle).isSelected, isFalse);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<IconButton>(toggle).isSelected, isTrue);
    expect(find.byKey(const Key('search-mode')), findsNothing);
  });

  testWidgets('the words/contains toggle keeps its place when Clear comes '
      '(#782)', (tester) async {
    await tester.pumpWidget(buildApp(source, dense: true));
    await tester.pump();
    final toggle = find.byKey(const Key('search-mode-toggle'));
    final before = tester.getRect(toggle);

    await tester.enterText(find.byKey(const Key('search-query')), 'n');
    await tester.pump();
    final clear = find.byKey(const Key('search-clear'));
    expect(clear, findsOne);
    expect(tester.getRect(toggle), before);
    expect(tester.getRect(clear).right, lessThanOrEqualTo(before.left));

    await tester.tap(clear);
    await tester.pump();
    expect(clear, findsNothing);
    expect(tester.getRect(toggle), before);
    await tester.pump(const Duration(milliseconds: 500));
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
    expect(find.textContaining('Type to search the library'), findsOne);
  });

  testWidgets('paging: 50 hits per page, Show more reveals the rest', (
    tester,
  ) async {
    // A tall surface so every page's items (and the Show more slot) are
    // actually built by the lazy ListView.
    tester.view.physicalSize = const Size(1000, 8000);
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

  testWidgets('replace: only words-mode results offer the action', (
    tester,
  ) async {
    final replace = FakeReplaceSource();
    source.hits = [_hit('Docs/Note One.md', title: 'Note One')];
    await tester.pumpWidget(buildApp(source, replace: replace));
    await tester.pump();

    // Words mode with results: the replace action is present.
    await tester.enterText(find.byKey(const Key('search-query')), 'note');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(find.byKey(const Key('search-replace')), findsOne);

    // Contains mode never replaces (exact words only apply to Words).
    await tester.tap(find.text('Contains'));
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(find.byKey(const Key('search-replace')), findsNothing);

    // No results: nothing to replace into.
    await tester.tap(find.text('Words'));
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    source.hits = const [];
    await tester.enterText(find.byKey(const Key('search-query')), 'zzz');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(find.text('No matches'), findsOne);
    expect(find.byKey(const Key('search-replace')), findsNothing);
  });

  testWidgets('phone width: the mode row keeps both buttons inside', (
    tester,
  ) async {
    // Regression: at standard icon-button density the row overflowed a
    // 390 px surface by a few pixels with the replace and the tags
    // button both showing — a rendering error on a phone. Compact
    // density keeps it inside.
    setSurfaceSize(tester, const Size(390, 844));
    source.hits = [_hit('Note.md', title: 'Note')];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            controller: session,
            onOpenNote: opened.add,
            source: source,
            onOpenTags: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const Key('search-query')), 'no');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    expect(find.byKey(const Key('search-replace')), findsOneWidget);
    expect(find.byKey(const Key('open-tags')), findsOneWidget);
  });

  testWidgets('replace: whole-library flow previews inline and reports', (
    tester,
  ) async {
    final replace = FakeReplaceSource()
      ..preview = const [
        ReplaceMatchNote(
          path: 'Docs/Note One.md',
          occurrences: 3,
          samples: [
            ReplaceSample(before: 'see ', match: 'note', after: ' here.'),
          ],
        ),
        ReplaceMatchNote(path: 'Docs/Note Two.md', occurrences: 2, samples: []),
      ];
    source.hits = [_hit('Docs/Note One.md', title: 'Note One')];
    await tester.pumpWidget(buildApp(source, replace: replace));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'note');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();

    await tester.tap(find.byKey(const Key('search-replace')));
    await tester.pumpAndSettle();
    // The inline panel appears under the query box (no dialog) and the
    // preview lists the matching notes with counts.
    expect(find.byKey(const Key('replace-panel')), findsOne);
    expect(find.textContaining('in 2 notes'), findsOne);
    expect(find.textContaining('3 occurrences'), findsOne);
    expect(find.byKey(const Key('replace-note-Docs/Note One.md')), findsOne);
    expect(find.textContaining('No exact whole-word match'), findsNothing);

    // Typing the replacement renders the live → preview under the sample.
    await tester.enterText(find.byKey(const Key('replace-with')), 'label');
    await tester.pump();
    expect(
      find.textContaining('see label here.', findRichText: true),
      findsOne,
    );

    // The case toggle re-scans with the flag.
    await tester.tap(find.byKey(const Key('replace-case')));
    await tester.pumpAndSettle();
    expect(replace.previews, hasLength(2));
    expect(replace.previews.last.caseSensitive, isTrue);
    expect(replace.previews.last.term, 'note');
    expect(replace.previews.last.onlyPath, isNull);

    await tester.tap(find.byKey(const Key('replace-confirm')));
    await tester.pumpAndSettle();
    expect(replace.replaceRequests, hasLength(1));
    final request = replace.replaceRequests.single;
    expect(request.term, 'note');
    expect(request.replacement, 'label');
    expect(request.caseSensitive, isTrue);
    expect(request.only, isNull);
    // The panel closes and the outcome snackbar reports the run.
    expect(find.byKey(const Key('replace-panel')), findsNothing);
    expect(find.textContaining('Replaced 5 occurrence(s) of "note"'), findsOne);

    // The deferred results refresh fires once and does not leak.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 200));
    expect(source.queries.length, greaterThanOrEqualTo(2));
  });

  testWidgets('replace: zero-match term disables the confirm and explains', (
    tester,
  ) async {
    final replace = FakeReplaceSource(); // preview stays empty
    source.hits = [_hit('Docs/Note One.md', title: 'Note One')];
    await tester.pumpWidget(buildApp(source, replace: replace));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'envi');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();

    await tester.tap(find.byKey(const Key('search-replace')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No exact whole-word match of "envi"'),
      findsOne,
    );
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('replace-confirm')),
    );
    expect(confirm.onPressed, isNull);
  });

  testWidgets('replace: long-press a result scopes the run to that note', (
    tester,
  ) async {
    final replace = FakeReplaceSource()
      ..preview = [
        const ReplaceMatchNote(
          path: 'Docs/Note One.md',
          occurrences: 2,
          samples: [],
        ),
      ];
    source.hits = [_hit('Docs/Note One.md', title: 'Note One')];
    await tester.pumpWidget(buildApp(source, replace: replace));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'note');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();

    await tester.longPress(
      find.byKey(const Key('search-hit-Docs/Note One.md')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Replace in this note…'), findsOne);
    await tester.tap(find.byKey(const Key('replace-note-action')));
    await tester.pumpAndSettle();

    // The inline panel scopes the preview scan to the long-pressed note.
    expect(find.byKey(const Key('replace-panel')), findsOne);
    expect(find.textContaining('in Docs/Note One.md'), findsOne);
    expect(replace.previews, hasLength(1));
    expect(replace.previews.single.onlyPath, 'Docs/Note One.md');

    await tester.enterText(find.byKey(const Key('replace-with')), 'label');
    await tester.tap(find.byKey(const Key('replace-confirm')));
    await tester.pumpAndSettle();

    expect(replace.replaceRequests, hasLength(1));
    final request = replace.replaceRequests.single;
    expect(request.term, 'note');
    expect(request.only, {'Docs/Note One.md'});
    expect(request.caseSensitive, isFalse);
    expect(find.byKey(const Key('replace-panel')), findsNothing);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
  });

  testWidgets('replace: closing the panel restores the results', (
    tester,
  ) async {
    final replace = FakeReplaceSource();
    source.hits = [_hit('Docs/Note One.md', title: 'Note One')];
    await tester.pumpWidget(buildApp(source, replace: replace));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'note');
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
    await tester.tap(find.byKey(const Key('search-replace')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('replace-panel')), findsOne);

    await tester.tap(find.byKey(const Key('replace-close')));
    await tester.pump();
    expect(find.byKey(const Key('replace-panel')), findsNothing);
    expect(find.byKey(const Key('search-results')), findsOne);
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

  // #712: the shell steps the sidebar's hits with F4/Shift+F4 and focuses
  // the field with Ctrl+Shift+F; the screen owns both, so the asks come
  // through SearchCommands. The current hit stays marked.
  testWidgets('F4/Shift+F4 step the hits, the current one marked (#712)', (
    tester,
  ) async {
    final commands = SearchCommands();
    addTearDown(commands.dispose);
    source.hits = [_hit('a.md'), _hit('b.md'), _hit('c.md')];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            controller: session,
            onOpenNote: opened.add,
            source: source,
            commands: commands,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'xy');
    await settle(tester);

    bool marked(String path) =>
        tester.widget<ListTile>(find.byKey(Key('search-hit-$path'))).selected;

    // The first step opens the first hit; the next the one after it.
    commands.stepBy(1);
    await settle(tester);
    expect(opened, ['a.md']);
    expect(marked('a.md'), isTrue);

    commands.stepBy(1);
    await settle(tester);
    expect(opened, ['a.md', 'b.md']);
    expect(marked('b.md'), isTrue);
    expect(marked('a.md'), isFalse);

    commands.stepBy(-1);
    await settle(tester);
    expect(opened.last, 'a.md');
    expect(marked('a.md'), isTrue);

    // And it wraps: back from the first is the last.
    commands.stepBy(-1);
    await settle(tester);
    expect(opened.last, 'c.md');
    expect(marked('c.md'), isTrue);

    // A tap makes the same mark, so the steps continue from there.
    await tester.tap(find.byKey(const Key('search-hit-b.md')));
    await settle(tester);
    expect(opened.last, 'b.md');
    expect(marked('b.md'), isTrue);
  });

  testWidgets('the shell can give the query field the focus (#712)', (
    tester,
  ) async {
    final commands = SearchCommands();
    addTearDown(commands.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchScreen(
            controller: session,
            onOpenNote: opened.add,
            source: source,
            commands: commands,
          ),
        ),
      ),
    );
    await tester.pump();

    commands.focus();
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const Key('search-query')),
    );
    expect(field.focusNode?.hasFocus, isTrue);
  });

  // #768: a step is an event. Ctrl+Shift+F after an F4 notified the
  // screen again, and the step it still held opened the next hit.
  testWidgets('a focus ask after a step opens no other hit (#768)', (
    tester,
  ) async {
    final commands = SearchCommands();
    addTearDown(commands.dispose);
    source.hits = [_hit('a.md'), _hit('b.md'), _hit('c.md')];
    await tester.pumpWidget(searchWith(commands));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'xy');
    await settle(tester);

    commands.stepBy(1);
    await settle(tester);
    expect(opened, ['a.md']);

    commands.focus();
    await settle(tester);
    expect(opened, ['a.md']);
    final field = tester.widget<TextField>(
      find.byKey(const Key('search-query')),
    );
    expect(field.focusNode?.hasFocus, isTrue);
  });

  // #768: a focus ask is answered once; a screen mounted later (the
  // sidebar rebuilt across the breakpoint) does not take the focus for it.
  testWidgets('a remount does not take the focus for an old ask (#768)', (
    tester,
  ) async {
    final commands = SearchCommands();
    addTearDown(commands.dispose);
    await tester.pumpWidget(searchWith(commands));
    await tester.pump();
    commands.focus();
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    await tester.pumpWidget(searchWith(commands));
    await tester.pump();
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const Key('search-query')),
    );
    expect(field.focusNode?.hasFocus, isFalse);
  });

  // #768: a step to a hit whose row is not built (the last one, the
  // wrap back to the first, a row scrolled away) brings it into view.
  testWidgets('a step brings a row outside the built range into view (#768)', (
    tester,
  ) async {
    final commands = SearchCommands();
    addTearDown(commands.dispose);
    source.hits = [
      for (var i = 0; i < 120; i++) _hit('n$i.md', snippet: 'xy $i'),
    ];
    await tester.pumpWidget(searchWith(commands));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'xy');
    await settle(tester);

    Finder row(String path) => find.byKey(Key('search-hit-$path'));

    // Shift+F4 with no current hit: the last, past the page's cut.
    commands.stepBy(-1);
    await tester.pumpAndSettle();
    expect(opened.last, 'n119.md');
    expect(row('n119.md').hitTestable(), findsOne);

    // F4 from the last wraps to the first, far above.
    commands.stepBy(1);
    await tester.pumpAndSettle();
    expect(opened.last, 'n0.md');
    expect(row('n0.md').hitTestable(), findsOne);

    // F4 after scrolling the current row away: the next comes back.
    await tester.drag(
      find.byKey(const Key('search-results')),
      const Offset(0, -6000),
    );
    await tester.pumpAndSettle();
    expect(row('n1.md'), findsNothing);
    commands.stepBy(1);
    await tester.pumpAndSettle();
    expect(opened.last, 'n1.md');
    expect(row('n1.md').hitTestable(), findsOne);
  });

  // #1044
  testWidgets('a new result set starts at the top of the list', (tester) async {
    source.hits = [
      for (var i = 0; i < 40; i++) _hit('n$i.md', snippet: 'xy $i'),
    ];
    await tester.pumpWidget(buildApp(source));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('search-query')), 'xy');
    await settle(tester);

    double offset() => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('search-results')),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;

    await tester.drag(
      find.byKey(const Key('search-results')),
      const Offset(0, -1500),
    );
    await tester.pumpAndSettle();
    expect(offset(), greaterThan(500));

    source.hits = [
      for (var i = 0; i < 40; i++) _hit('m$i.md', snippet: 'xyz $i'),
    ];
    await tester.enterText(find.byKey(const Key('search-query')), 'xyz');
    await settle(tester);
    expect(offset(), 0);
    expect(find.byKey(const Key('search-hit-m0.md')), findsOne);
  });

  // #1044
  testWidgets('Enter in the field opens the first hit when none is marked', (
    tester,
  ) async {
    source.hits = [_hit('a.md'), _hit('b.md')];
    await tester.pumpWidget(buildApp(source));
    await tester.enterText(find.byKey(const Key('search-query')), 'note');
    await settle(tester);
    expect(opened, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, ['a.md']);

    // The search action of a touch keyboard does the same.
    opened.clear();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(opened, ['a.md']);
  });

  // #1044
  testWidgets('a word hit keeps its height while its excerpt loads', (
    tester,
  ) async {
    source.hits = [_hit('a.md')];
    source.excerpts['a.md'] = 'one <mark>xy</mark> two';
    final gate = source.excerptGates['a.md'] = Completer<void>();
    await tester.pumpWidget(buildApp(source));
    await tester.enterText(find.byKey(const Key('search-query')), 'xy');
    await settle(tester);

    final row = find.byKey(const Key('search-hit-a.md'));
    final before = tester.getSize(row).height;
    expect(find.byKey(const Key('search-excerpt-skeleton')), findsOne);

    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('search-excerpt-skeleton')), findsNothing);
    expect(find.textContaining('one xy two', findRichText: true), findsOne);
    expect(tester.getSize(row).height, before);
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
    required int? id,
    int limit = 200,
  }) {
    started++;
    final queryAtStart = query;
    return Future<List<SearchHit>>.delayed(
      Duration.zero,
      () => id == null || isCurrent(id)
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

  @override
  Future<String> excerpt(SearchHit hit, String userText) async => '';
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
    required int? id,
    int limit = 200,
  }) async {
    started++;
    await _gate.future;
    if (id != null && !isCurrent(id)) return const [];
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

  @override
  Future<String> excerpt(SearchHit hit, String userText) async => '';
}
