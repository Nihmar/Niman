// Issue #172: on a wide window Settings is two columns — the search and
// the areas on the left, the selected area on the right — with no
// navigation between them. The phone keeps its list of screens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/settings_editor.dart';
import 'package:niman/src/ui/settings_folders_paths.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_tab.dart';
import 'package:niman/src/ui/settings_trash_history.dart';
import 'package:niman/src/ui/toolbar_settings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() => controller = FakeLibrarySession());

  Future<void> pumpAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsTab(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('wide', () {
    testWidgets('the list and an area are on screen together', (tester) async {
      await pumpAt(tester, 1200);
      expect(find.byKey(const Key('settings-search-field')), findsOne);
      expect(find.byKey(const Key('settings-area-editor')), findsOne);
      // The first area is shown before anything is picked: the right
      // column is never empty.
      expect(find.byKey(SettingsKeys.language), findsOne);
    });

    testWidgets('picking an area shows it beside the list, not over it', (
      tester,
    ) async {
      await pumpAt(tester, 1200);
      await tester.tap(find.byKey(const Key('settings-area-trash-history')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsTrashHistoryScreen), findsOne);
      // Still there: nothing was pushed over the list.
      expect(find.byKey(const Key('settings-area-editor')), findsOne);
      expect(find.backButton(), findsNothing);

      await tester.tap(find.byKey(const Key('settings-area-editor')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsEditorScreen), findsOne);
      expect(find.byType(SettingsTrashHistoryScreen), findsNothing);
    });

    testWidgets('a search result shows its row in the right column', (
      tester,
    ) async {
      await pumpAt(tester, 1200);
      await tester.enterText(
        find.byKey(const Key('settings-search-field')),
        'template',
      );
      // The search waits out a typing pause.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings-search-template-folder-setting')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsFoldersPathsScreen), findsOne);
      expect(find.byKey(SettingsKeys.templateFolder), findsOne);
      // The results stay: the next one is a click away.
      expect(
        find.byKey(const Key('settings-search-template-folder-setting')),
        findsOne,
      );
    });

    testWidgets('what an area opens stays in the right column', (tester) async {
      await pumpAt(tester, 1200);
      await tester.tap(find.byKey(const Key('settings-area-editor')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SettingsKeys.toolbar));
      await tester.pumpAndSettle();
      expect(find.byType(ToolbarSettingsScreen), findsOne);
      expect(find.byKey(const Key('settings-area-editor')), findsOne);
      // Its way back leads to the area, not out of Settings.
      await tester.tap(find.backButton());
      await tester.pumpAndSettle();
      expect(find.byType(SettingsEditorScreen), findsOne);
    });
  });

  testWidgets('narrow, an area is a screen of its own', (tester) async {
    await pumpAt(tester, 400);
    expect(find.byType(SettingsEditorScreen), findsNothing);
    await tester.tap(find.byKey(const Key('settings-area-editor')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsEditorScreen), findsOne);
    expect(find.byKey(const Key('settings-area-editor')), findsNothing);
  });
}
