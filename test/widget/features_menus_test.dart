// #1109: the menus and the dock leave out what a feature that is off owns,
// from the same answer the palette gives — the tree row's entries, the
// ☰ menu's groups, the dock's journal pane.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/app_menu.dart';
import 'package:niman/src/ui/dock/right_dock.dart';
import 'package:niman/src/ui/shell_row_menu.dart';
import 'package:niman/src/workspace/workspace.dart';

Features off(Iterable<LibraryFeature> features) =>
    [for (final feature in features) feature]
        .fold(const Features(), (all, f) => all.withSwitch(f, on: false));

Note noteRow({required bool isDir, String name = 'Row.md'}) => Note(
  id: 1,
  path: name,
  parent: 0,
  name: name,
  nameKey: nameSortKey(name),
  isDir: isDir,
  size: 0,
  modified: DateTime(2026),
  created: DateTime(2026),
  pinned: false,
);

void main() {
  Set<String> values(Note note, Features features, {bool recognize = false}) =>
      {
        for (final group in rowMenuGroups(
          note,
          isQuickNote: false,
          offersRecognize: recognize,
          features: features,
        ))
          for (final entry in group) entry.value,
      };

  group('the tree row menu', () {
    test("a folder's creating entries follow their features", () {
      final folder = noteRow(isDir: true, name: 'Books');
      final all = values(folder, const Features());
      expect(all, containsAll(['template', 'audio', 'slides', 'flashcards']));

      final none = values(
        folder,
        off([
          LibraryFeature.templates,
          LibraryFeature.kindAudio,
          LibraryFeature.kindSlides,
          LibraryFeature.kindFlashcards,
        ]),
      );
      expect(none, isNot(contains('template')));
      expect(none, isNot(contains('audio')));
      expect(none, isNot(contains('slides')));
      expect(none, isNot(contains('flashcards')));
      // Notes and folders are core.
      expect(none, containsAll(['note', 'folder']));
    });

    test("a note's roles follow theirs", () {
      final note = noteRow(isDir: false);
      expect(
        values(note, const Features()),
        containsAll(['quicknote', 'pinwidget', 'history']),
      );

      final none = values(
        note,
        off([LibraryFeature.quickNote, LibraryFeature.widgets]),
      );
      expect(none, isNot(contains('quicknote')));
      expect(none, isNot(contains('pinwidget')));
      expect(none, contains('history'), reason: 'history is core');
    });
  });

  group('the ☰ menu', () {
    Future<void> pump(WidgetTester tester, Features features) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: AppMenuButton(
              handlers: () => const {},
              features: () => features,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('app-menu')));
      await tester.pumpAndSettle();
    }

    testWidgets('a group left empty goes, and what is off is not listed', (
      tester,
    ) async {
      await pump(tester, const Features());
      expect(find.byKey(const Key('app-menu-group-journal')), findsOne);

      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();
      await pump(tester, off([LibraryFeature.journal]));
      expect(find.byKey(const Key('app-menu-group-journal')), findsNothing);
      expect(find.byKey(const Key('app-menu-group-note')), findsOne);
    });

    testWidgets('a command of a group that stays is left out of it', (
      tester,
    ) async {
      await pump(tester, off([LibraryFeature.kindSlides]));
      await tester.tap(find.byKey(const Key('app-menu-group-note')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('app-menu-newSlides')), findsNothing);
      expect(find.byKey(const Key('app-menu-newNote')), findsOne);
    });
  });

  group('the dock', () {
    Future<void> pump(
      WidgetTester tester,
      Features features, {
      DockPane pane = DockPane.journal,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RightDock(
              features: features,
              pane: pane,
              onPane: (_) {},
              onClose: () {},
              paneBuilder: (pane) => Text('pane ${pane.name}'),
            ),
          ),
        ),
      );
    }

    testWidgets('the journal pane is a tab while the journal is on', (
      tester,
    ) async {
      await pump(tester, const Features());
      expect(find.byKey(const Key('dock-pane-journal')), findsOne);
      expect(find.text('pane journal'), findsOne);
    });

    testWidgets('with the journal off it has no tab, and the outline shows '
        'in its place', (tester) async {
      await pump(tester, off([LibraryFeature.journal]));
      expect(find.byKey(const Key('dock-pane-journal')), findsNothing);
      expect(find.byKey(const Key('dock-pane-outline')), findsOne);
      expect(find.text('pane journal'), findsNothing);
      expect(find.text('pane outline'), findsOne);
    });
  });
}
