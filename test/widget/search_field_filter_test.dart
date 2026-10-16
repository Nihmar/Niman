// T-M4-03 AC: `key = value` in the search box filters by frontmatter,
// for any key — the invented ones as much as the known ones.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/search_screen.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_search_source.dart';

/// A field source over a fixed set of notes, recording what it was asked.
final class _FakeFieldSource implements FieldSource {
  /// path → its frontmatter fields.
  Map<String, Map<String, List<String>>> notes = {};

  /// Every (key, value) pair the screen asked for, in order.
  final List<String> queries = [];

  /// How many pages of the long lists were read.
  int pagesRead = 0;

  Note _note(String path) => Note(
    id: path.hashCode & 0x7fffffff,
    path: path,
    parent: 0,
    name: path.split('/').last,
    nameKey: nameSortKey(path.split('/').last),
    isDir: false,
    size: 0,
    modified: DateTime.fromMillisecondsSinceEpoch(0),
    created: DateTime.fromMillisecondsSinceEpoch(0),
    pinned: false,
  );

  @override
  Future<List<Note>> pinnedNotes() async => const [];

  @override
  Future<List<FieldKeyCount>> fieldKeys() async => const [];

  @override
  Future<List<({Note note, String value})>> fieldValues(String key) async =>
      const [];

  @override
  Future<List<String>> topValues(String key, {int limit = 20}) async =>
      const [];

  @override
  Future<List<Note>> notesWithField(
    String key,
    String value, {
    int? limit,
    String? after,
  }) async {
    if (queries.isEmpty || queries.last != '$key=$value') {
      queries.add('$key=$value');
    }
    if (limit != null) pagesRead++;
    final out = <Note>[];
    for (final entry in notes.entries) {
      final values = entry.value[key];
      if (values == null) continue;
      if (value.isEmpty || values.any((v) => v.toLowerCase() == value)) {
        out.add(_note(entry.key));
      }
    }
    out.sort((a, b) => a.path.compareTo(b.path));
    final past = after == null
        ? out
        : [
            for (final note in out)
              if (note.path.compareTo(after) > 0) note,
          ];
    return limit == null ? past : past.take(limit).toList();
  }

  @override
  Future<int> countWithField(String key, String value) async =>
      (await notesWithField(key, value)).length;
}

void main() {
  late FakeLibrarySession session;
  late FakeSearchSource source;
  late _FakeFieldSource fields;
  final opened = <String>[];

  Widget buildApp() {
    return MaterialApp(
      home: Scaffold(
        body: SearchScreen(
          controller: session,
          onOpenNote: opened.add,
          source: source,
          fieldSource: fields,
        ),
      ),
    );
  }

  setUp(() {
    session = FakeLibrarySession();
    source = FakeSearchSource();
    fields = _FakeFieldSource()
      ..notes = {
        'Draft.md': {
          'status': ['draft'],
          'projects': ['alpha', 'beta'],
        },
        'Done.md': {
          'status': ['done'],
        },
      };
    opened.clear();
  });

  /// Types [text] and waits out the debounce.
  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('search-query')), text);
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump();
  }

  testWidgets('key = value filters instead of searching the text', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await type(tester, 'status = draft');

    expect(fields.queries, ['status=draft']);
    expect(source.queries, isEmpty, reason: 'no FTS query was issued');
    expect(find.byKey(const Key('search-hit-Draft.md')), findsOne);
    expect(find.byKey(const Key('search-hit-Done.md')), findsNothing);
  });

  testWidgets('an invented key works the same as a known one', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await type(tester, 'projects = beta');

    expect(fields.queries, ['projects=beta']);
    expect(find.byKey(const Key('search-hit-Draft.md')), findsOne);
  });

  testWidgets('a value-less filter lists every note declaring the key', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await type(tester, 'status =');

    expect(find.byKey(const Key('search-hit-Draft.md')), findsOne);
    expect(find.byKey(const Key('search-hit-Done.md')), findsOne);
  });

  testWidgets('the prefix icon says the box is filtering', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    expect(find.byIcon(Icons.search), findsOne);

    await type(tester, 'status = draft');

    expect(find.byIcon(Icons.filter_alt_outlined), findsOne);
    expect(find.byIcon(Icons.search), findsNothing);
  });

  testWidgets('a filter offers no Replace, a text search does', (tester) async {
    source.hits = [
      const SearchHit(noteId: 1, path: 'Draft.md', title: 'Draft', snippet: ''),
    ];
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await type(tester, 'draft');
    expect(find.byKey(const Key('search-replace')), findsOne);

    await type(tester, 'status = draft');
    expect(find.byKey(const Key('search-replace')), findsNothing);
  });

  testWidgets('Contains mode searches the text, equals sign and all', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.tap(find.text('Contains'));
    await tester.pump();

    await type(tester, 'status = draft');

    expect(fields.queries, isEmpty);
    expect(source.queries, ['status = draft']);
  });

  testWidgets('tapping a filtered result opens the note', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await type(tester, 'status = draft');

    await tester.tap(find.byKey(const Key('search-hit-Draft.md')));

    expect(opened, ['Draft.md']);
  });

  testWidgets('a filter that matches nothing says so', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await type(tester, 'status = archived');

    expect(find.text('No matches'), findsOne);
  });

  // #1037: a key most notes carry lists a page of its notes, says how many
  // there are, and reads the next page when it is asked for.
  testWidgets('a long filter lists a page, says the count, reads on', (
    tester,
  ) async {
    fields.notes = {
      for (var i = 0; i < 1200; i++)
        'n${i.toString().padLeft(4, '0')}.md': {
          'status': ['draft'],
        },
    };
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await type(tester, 'status =');

    final more = find.byKey(const Key('search-load-more'));
    Future<void> reveal() => tester.scrollUntilVisible(
      more,
      800,
      scrollable: find.descendant(
        of: find.byKey(const Key('search-results')),
        matching: find.byType(Scrollable),
      ),
    );
    Future<void> showMore() async {
      await reveal();
      await tester.ensureVisible(more);
      await tester.pump();
      await tester.tap(more);
      await tester.pump();
      await tester.pump();
    }

    // 500 notes are read, 50 are shown; the rest of the count is known.
    expect(fields.queries, ['status=']);
    await showMore();
    // Show what is held (ten pages of fifty): the next page is read only
    // once the held ones are all shown.
    await reveal();
    expect(find.text('Showing the first 500 of 1200'), findsOne);
    for (var i = 0; i < 7; i++) {
      await showMore();
    }
    expect(fields.pagesRead, 1);
    await showMore();
    await showMore();
    expect(fields.pagesRead, 2);
    await reveal();
    expect(find.text('Showing the first 1000 of 1200'), findsOne);
  });
}
