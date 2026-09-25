// 2026-09-08 user feedback: the settings screen read as one wall. It is
// now grouped under headings, and every setting with more than two
// choices is a row showing its current value, changed in a dialog.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/settings_search.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  /// Pumps the settings body on a surface tall enough to hold the list.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsBody(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens [area]'s screen from the settings home (issue #104): the
  /// rows the tests drive live in the pushed area screen.
  Future<void> openArea(WidgetTester tester, Key area) async {
    await tester.tap(find.byKey(area));
    await tester.pumpAndSettle();
  }

  /// The switch inside the [HighlightRow] wrapper (issue #104): the
  /// row's key sits on the wrapper, so the switch is a descendant of it.
  Switch switchOf(WidgetTester tester, Finder row) => tester.widget<Switch>(
    find.descendant(of: row, matching: find.byType(Switch)),
  );

  testWidgets('the home groups the settings under its areas', (tester) async {
    await pump(tester);
    for (final heading in [
      AppStrings.settingsSectionAppearance,
      AppStrings.settingsSectionEditor,
      AppStrings.settingsAreaFolders,
      AppStrings.settingsAreaTrashHistory,
      AppStrings.settingsSectionReminders,
      AppStrings.settingsAreaDiagnostics,
      AppStrings.settingsGroupMaintenance,
    ]) {
      expect(find.text(heading), findsOne, reason: heading);
    }
    // The About section is gone: its rows sit under Diagnostics.
    expect(find.text(AppStrings.settingsSectionAbout), findsNothing);
  });

  testWidgets('no setting is a SegmentedButton any more', (tester) async {
    // The inline segmented blocks are what made the screen a wall: each
    // cost three lines where a switch cost one. The home has no setting
    // rows at all (issue #104): the areas hold the switches and the
    // dialogs.
    await pump(tester);
    expect(find.byType(SegmentedButton<int>), findsNothing);
    expect(find.byType(SegmentedButton<LinkType>), findsNothing);
  });

  testWidgets('a choice row reads its current value', (tester) async {
    await pump(tester);
    await openArea(tester, const Key('settings-area-editor'));
    final row = find.byKey(const Key('indent-width'));
    expect(
      find.descendant(
        of: row,
        matching: find.text(AppStrings.indentWidthValue(2)),
      ),
      findsOne,
    );
  });

  testWidgets('tapping a choice row opens the dialog and applies it', (
    tester,
  ) async {
    await pump(tester);
    await openArea(tester, const Key('settings-area-editor'));
    await tester.tap(find.byKey(const Key('indent-width')));
    await tester.pumpAndSettle();

    // The explanation is under the row's label (#172) and in the dialog,
    // where the choice is made.
    expect(find.text(AppStrings.indentWidthSubtitle), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('settings-choice-6')));
    await tester.pumpAndSettle();

    expect(await controller.indentWidth, 6);
    expect(
      find.descendant(
        of: find.byKey(const Key('indent-width')),
        matching: find.text(AppStrings.indentWidthValue(6)),
      ),
      findsOne,
    );
  });

  // Issue #79: the row is there, it starts at never, and it is what
  // turns the automatic empty on — nothing else does.
  testWidgets('the trash empties itself only once the row asks it to', (
    tester,
  ) async {
    await pump(tester);
    await openArea(tester, const Key('settings-area-trash-history'));
    final row = find.byKey(const Key('trash-auto-empty-setting'));
    await tester.pumpAndSettle();
    expect(await controller.trashAutoEmptyDays, trashAutoEmptyOff);
    expect(
      find.descendant(
        of: row,
        matching: find.text(AppStrings.trashAutoEmptyValue(trashAutoEmptyOff)),
      ),
      findsOne,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-choice-30')));
    await tester.pumpAndSettle();

    expect(await controller.trashAutoEmptyDays, 30);
    expect(
      find.descendant(
        of: row,
        matching: find.text(AppStrings.trashAutoEmptyValue(30)),
      ),
      findsOne,
    );
  });

  // User, 2026-09-17: the quick note was set from its own tab and the
  // settings row went on showing the old one. This body is mounted once
  // and kept alive, so it has to re-read when the session says a setting
  // moved.
  testWidgets('a setting changed elsewhere reaches the row', (tester) async {
    await pump(tester);
    await openArea(tester, const Key('settings-area-folders'));
    final row = find.byKey(const Key('quick-note-setting'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: row, matching: find.text(AppStrings.quickNoteUnset)),
      findsOne,
    );

    // What the quick-note tab and the tree row menu do: write it, then
    // say so.
    await controller.setQuickNotePath(path: 'Notes/Quick.md');
    controller.notify();
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: row, matching: find.text('Notes/Quick.md')),
      findsOne,
    );
  });

  testWidgets('cancelling a choice changes nothing', (tester) async {
    await pump(tester);
    await openArea(tester, const Key('settings-area-editor'));
    await tester.tap(find.byKey(const Key('link-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.actionCancel));
    await tester.pumpAndSettle();

    expect(await controller.linkType, LinkType.wikilink);
  });

  testWidgets('the dead-link location row reads and applies its value', (
    tester,
  ) async {
    await pump(tester);
    await openArea(tester, const Key('settings-area-editor'));
    final row = find.byKey(const Key('missing-note-location'));
    expect(
      find.descendant(
        of: row,
        matching: find.text(AppStrings.missingNoteLocationCurrentFolder),
      ),
      findsOne,
    );

    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.missingNoteLocationRoot));
    await tester.pumpAndSettle();

    expect(
      await controller.missingNoteLocation,
      MissingNoteLocation.libraryRoot,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.text(AppStrings.missingNoteLocationRoot),
      ),
      findsOne,
    );
  });

  testWidgets('the toolbar row sits under Editor, not Appearance', (
    tester,
  ) async {
    // It decides what the editor can do, not how the app looks (user,
    // 2026-09-09); issue #104 makes the split explicit: the row sits in
    // the editor area, not in appearance.
    await pump(tester);
    await openArea(tester, const Key('settings-area-appearance'));
    expect(find.byKey(const Key('toolbar-setting')), findsNothing);
    await tester.tap(find.backButton());
    await tester.pumpAndSettle();
    await openArea(tester, const Key('settings-area-editor'));
    expect(find.byKey(const Key('toolbar-setting')), findsOne);
  });

  testWidgets('switches keep their explanation, having no dialog', (
    tester,
  ) async {
    await pump(tester);
    await openArea(tester, const Key('settings-area-trash-history'));
    expect(find.text(AppStrings.trashSubtitle), findsOne);
  });

  testWidgets('the reminders toggle flips and persists', (tester) async {
    // Restored from the single-column settings: the split dropped the
    // section with no UI at all (issue #104).
    await pump(tester);
    await openArea(tester, const Key('settings-area-reminders'));
    final row = find.byKey(const Key('reminder-show-tokens'));
    expect(switchOf(tester, row).value, isFalse);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(await controller.reminderShowTokens, isTrue);
    expect(switchOf(tester, row).value, isTrue);
  });

  testWidgets('maintenance holds the actions, not settings', (tester) async {
    // Reindex, switch and close sit under their own heading on the
    // home (issue #104), not scattered among the settings.
    await pump(tester);
    expect(find.text(AppStrings.settingsGroupMaintenance), findsOne);
    expect(find.byKey(const Key('reindex-setting')), findsOneWidget);
    expect(find.byKey(const Key('switch-library-setting')), findsOneWidget);
    expect(find.byKey(const Key('close-library-setting')), findsOneWidget);
    // And they are out of the areas they used to hide in.
    await openArea(tester, const Key('settings-area-trash-history'));
    expect(find.byKey(const Key('reindex-setting')), findsNothing);
    await tester.tap(find.backButton());
    await tester.pumpAndSettle();
    await openArea(tester, const Key('settings-area-folders'));
    expect(find.byKey(const Key('switch-library-setting')), findsNothing);
    expect(find.byKey(const Key('close-library-setting')), findsNothing);
  });

  testWidgets('a folder the library does not hold says so', (tester) async {
    // A fresh library holds no folders: every configured folder (lists,
    // templates, attachments, annotations) wears the "to create" badge
    // rather than a confident value (issue #104).
    await pump(tester);
    await openArea(tester, const Key('settings-area-folders'));
    expect(find.text(AppStrings.settingsFolderToCreate), findsNWidgets(4));
  });

  testWidgets('the keyboard row shows on phones only, hidden on desktop', (
    tester,
  ) async {
    // The test host is a desktop platform, so the row — gated on
    // Android/iOS — is never offered here (user, 2026-09-09).
    await pump(tester);
    expect(find.text(AppStrings.keyboardOnOpenSubtitle), findsNothing);
  });

  group('the editor switches', () {
    final source = find.byKey(const Key('editor-source-setting'));
    final wysiwyg = find.byKey(const Key('editor-wysiwyg-setting'));

    testWidgets('both editors are on by default', (tester) async {
      await pump(tester);
      await openArea(tester, const Key('settings-area-editor'));
      expect(switchOf(tester, source).value, isTrue);
      expect(switchOf(tester, wysiwyg).value, isTrue);
    });

    testWidgets('one editor switches off, never the last', (tester) async {
      await pump(tester);
      await openArea(tester, const Key('settings-area-editor'));
      await tester.tap(wysiwyg);
      await tester.pumpAndSettle();
      expect(await controller.enabledEditors, {EditorKind.source});
      // The last one on disables its own switch rather than offering a
      // library with no editor.
      expect(switchOf(tester, source).onChanged, isNull);
      await tester.tap(source);
      await tester.pumpAndSettle();
      expect(await controller.enabledEditors, {EditorKind.source});
      // Back on: both again.
      await tester.tap(wysiwyg);
      await tester.pumpAndSettle();
      expect(await controller.enabledEditors, {
        EditorKind.source,
        EditorKind.wysiwyg,
      });
    });
  });

  testWidgets('the shortcuts row opens the reference where a keyboard exists', (
    tester,
  ) async {
    // The test host is a desktop platform, so a physical keyboard is
    // assumed and the home row stays enabled: it pushes the reference
    // straight from the home (issue #104), with no keyboard area.
    await pump(tester);
    final row = find.byKey(const Key('keyboard-shortcuts'));
    expect(row, findsOneWidget);
    expect(
      tester
          .widget<ListTile>(
            find.descendant(of: row, matching: find.byType(ListTile)),
          )
          .enabled,
      isTrue,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(KeyboardShortcutsScreen), findsOneWidget);
  });

  testWidgets('a disabled row cannot be tapped', (tester) async {
    // Phones and tablets have no physical keyboard: the shortcuts row
    // reads as disabled and its tap goes nowhere.
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsValueRow(
            title: 'Shortcuts',
            enabled: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tile = find.text('Shortcuts');
    await tester.tap(tile, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tapped, isFalse);
  });

  group('the settings search', () {
    /// Types [query] into the home's search field and lets the debounce
    /// and the value loads settle (issue #104).
    Future<void> search(WidgetTester tester, String query) async {
      await pump(tester);
      await tester.enterText(
        find.byKey(const Key('settings-search-field')),
        query,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    testWidgets('a result carries its area and opens its screen', (
      tester,
    ) async {
      await search(tester, 'indent');
      // The indent width, and Indent's formatting key (#205).
      expect(find.text(AppStrings.settingsSearchResults(2)), findsOne);
      final result = find.byKey(const Key('settings-search-indent-width'));
      expect(
        find.descendant(
          of: result,
          matching: find.text(AppStrings.settingsSectionEditor),
        ),
        findsOne,
      );
      expect(
        find.descendant(
          of: result,
          matching: find.text(AppStrings.indentWidthValue(2)),
        ),
        findsOne,
      );
      await tester.tap(result);
      await tester.pumpAndSettle();
      // The editor screen opened on the row.
      expect(find.byKey(const Key('indent-width')), findsOneWidget);
    });

    testWidgets('a maintenance result flashes the home row in place', (
      tester,
    ) async {
      // Maintenance actions sit on the home itself: opening one clears
      // the search instead of pushing a screen.
      await search(tester, 're-index');
      expect(find.text(AppStrings.settingsSearchResults(1)), findsOne);
      await tester.tap(
        find.byKey(const Key('settings-search-reindex-setting')),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.settingsSearchResults(1)), findsNothing);
      expect(find.byKey(const Key('reindex-setting')), findsOneWidget);
    });

    // A query matches a row's area as well as its title, so one word can
    // bring a whole area back — and every one of those rows is a tile in
    // one list, which Flutter will not have sharing a key.
    testWidgets('a word that matches a whole area lists its rows', (
      tester,
    ) async {
      await search(tester, 'trash');
      expect(tester.takeException(), isNull);
      final keys = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => tile.key)
          .whereType<Key>()
          .toList();
      expect(keys, isNotEmpty);
      expect(keys.toSet().length, keys.length, reason: '$keys');
    });

    testWidgets('nothing matching reads as zero', (tester) async {
      await search(tester, 'zzz-no-such-setting');
      expect(find.text(AppStrings.settingsSearchResults(0)), findsOne);
    });

    // The index and the screens name each row through `SettingsKeys`, so
    // they cannot spell it differently. They can still disagree about
    // whether the row exists at all: a row deleted from its screen
    // leaves an entry that opens the screen and highlights nothing.
    testWidgets('every entry points at a row that is really there', (
      tester,
    ) async {
      await pump(tester);
      final context = tester.element(
        find.byKey(const Key('settings-search-field')),
      );
      final entries = settingsSearchEntries(
        controller: controller,
        transcription: null,
        spellCheck: null,
        libraryName: 'Notes',
        context: context,
        flashHome: (_) {},
        // The phone's way in: the area's own screen, pushed.
        openArea: (area, row) => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => settingsAreas(
              controller: controller,
              spellCheck: null,
              transcription: null,
              keyboardAttached: true,
            ).firstWhere((a) => a.id == area).build(row),
          ),
        ),
      );
      expect(entries, isNotEmpty);

      for (final entry in entries) {
        if (entry.onHome) {
          // Maintenance actions sit on the home itself.
          expect(find.byKey(entry.rowKey), findsOneWidget, reason: entry.title);
          continue;
        }
        entry.open();
        await tester.pumpAndSettle();
        expect(find.byKey(entry.rowKey), findsOneWidget, reason: entry.title);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });
  });
}
