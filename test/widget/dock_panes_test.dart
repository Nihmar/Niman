// Issue #175: the dock's three panes, on a note of their own — the
// outline jumps, the tags list and open onto their notes, the history
// lists the kept versions newest first.
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/search/tag_repo.dart';
import 'package:niman/src/ui/dock/history_dock_pane.dart';
import 'package:niman/src/ui/dock/outline_dock_pane.dart';
import 'package:niman/src/ui/dock/tags_dock_pane.dart';
import 'package:niman/src/ui/note_view_handle.dart';

import '../fakes/fake_library_session.dart';

final class _Note implements NoteViewHandle {
  new(this.currentText);

  @override
  String currentText;

  final jumps = <int>[];

  @override
  final ValueNotifier<List<OutlineEntry>> outline = ValueNotifier(const [
    OutlineEntry(line: 0, level: 1, text: 'Celestia'),
    OutlineEntry(line: 4, level: 2, text: 'Cosmologia'),
  ]);

  @override
  void jumpToHeading(int line) => jumps.add(line);

  @override
  bool get canInsert => true;

  @override
  void insertAtCaret(String markdown) => currentText += markdown;

  @override
  void openFind({bool replace = false}) {}
}

final class _Tags implements TagSource {
  @override
  Future<List<TagCount>> tagCounts() async => const [];

  @override
  Future<List<Note>> notesWithTag(String tag, {int limit = 0}) async => [
    Note(
      id: 1,
      path: 'Other.md',
      parent: 0,
      name: 'Other.md',
      isDir: false,
      size: 0,
      modified: DateTime(2026),
      pinned: false,
    ),
  ];
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// An outline of [length] headings that counts how many of them were read.
final class _CountedOutline extends ListBase<OutlineEntry> {
  new(this.length);

  @override
  int length;

  /// How many headings were asked for.
  int read = 0;

  @override
  OutlineEntry operator [](int index) {
    read++;
    return OutlineEntry(
      line: index * 10,
      level: index % 3 + 1,
      text: 'Heading $index',
    );
  }

  @override
  void operator []=(int index, OutlineEntry value) =>
      throw UnsupportedError('read only');
}

void main() {
  test('a note’s tags: its frontmatter’s, then its #tags, once', () {
    expect(noteTagsOf('---\ntags: [Work, idea]\n---\nsome #idea and #plan\n'), [
      'work',
      'idea',
      'plan',
    ]);
  });

  testWidgets('the outline lists the headings and jumps', (tester) async {
    final note = _Note('');
    await tester.pumpWidget(_app(OutlineDockPane(note: note)));
    expect(find.text('Celestia'), findsOne);
    await tester.tap(find.text('Cosmologia'));
    expect(note.jumps, [4]);
    // It follows the note as the headings change.
    note.outline.value = const [
      OutlineEntry(line: 1, level: 1, text: 'Galassia'),
    ];
    await tester.pump();
    expect(find.text('Galassia'), findsOne);
    expect(find.text('Celestia'), findsNothing);
  });

  testWidgets('a long outline builds the headings on screen, not all of them', (
    tester,
  ) async {
    // The 246 MB stress note's count: every row was built on every outline
    // the note published, a frame of O(headings) whatever was on screen.
    const headings = 22260;
    final note = _Note('');
    final outline = _CountedOutline(headings);
    note.outline.value = outline;
    await tester.pumpWidget(_app(OutlineDockPane(note: note)));
    // A screen of rows and the list's cache, against one per heading.
    expect(outline.read, lessThan(100));
    expect(find.text('Heading 0'), findsOne);
    // A new outline — the note was edited — reads a screen again.
    final next = _CountedOutline(headings);
    note.outline.value = next;
    await tester.pump();
    expect(next.read, lessThan(100));
    // The far end is there to scroll to, and its rows still jump.
    await tester.scrollUntilVisible(
      find.text('Heading ${headings - 1}'),
      50000,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Heading ${headings - 1}'));
    expect(note.jumps, [(headings - 1) * 10]);
  });

  testWidgets('the tags list, each opening onto its notes', (tester) async {
    final opened = <String>[];
    final note = _Note('a #plan here');
    await tester.pumpWidget(
      _app(
        TagsDockPane(
          note: note,
          tags: Future.value(_Tags()),
          onOpenNote: opened.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('plan'), findsOne);
    await tester.tap(find.text('plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other.md'));
    expect(opened, ['Other.md']);
  });

  testWidgets('the history lists the versions, newest first', (tester) async {
    final session = FakeLibrarySession()
      ..seedVersion(
        'a.md',
        number: 1,
        savedAt: DateTime(2026, 9, 18, 9),
        text: 'old',
      )
      ..seedVersion(
        'a.md',
        number: 2,
        savedAt: DateTime(2026, 9, 18, 11),
        text: 'newer',
        reason: HistoryReason.interval,
      );
    var opened = 0;
    await tester.pumpWidget(
      _app(
        HistoryDockPane(
          ops: session,
          path: 'a.md',
          onOpenHistory: () => opened++,
          now: () => DateTime(2026, 9, 18, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final newest = tester.getTopLeft(find.byKey(const Key('dock-history-2')));
    final oldest = tester.getTopLeft(find.byKey(const Key('dock-history-1')));
    expect(newest.dy, lessThan(oldest.dy));
    await tester.tap(find.byKey(const Key('dock-history-all')));
    expect(opened, 1);
  });
}
