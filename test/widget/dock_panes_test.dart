// Issue #175: the dock's three panes, on a note of their own — the
// outline jumps, the tags list and open onto their notes, the history
// lists the kept versions newest first.
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
