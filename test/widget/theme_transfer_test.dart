// Issue #269: a theme written out into a file, and a theme file read back
// in — with the file calls the tests hand in for the system's pickers.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme_transfer.dart';
import 'package:niman/src/ui/settings_themes.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/theme_files.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/sample_themes.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    AppThemes.reset();
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    AppThemes.reset();
  });

  /// Pumps the Themes page with the two file calls a test hands in.
  Future<void> pumpPage(
    WidgetTester tester, {
    required PickThemeFile pick,
    SaveThemeFile? save,
  }) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsThemesScreen(
          controller: controller,
          pickThemeFile: pick,
          saveThemeFile:
              save ??
              ({required name, required json}) async => '/somewhere/$name.json',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A theme file holding [name]'s theme.
  String fileNamed(String name) {
    final theme = sampleCustomTheme(name: name);
    return encodeThemeFile(name: name, day: theme.day, night: theme.night);
  }

  /// Taps a row's menu entry.
  Future<void> tapMenu(WidgetTester tester, String id, String action) async {
    await tester.tap(find.byKey(Key('theme-menu-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('theme-menu-$action')));
    await tester.pumpAndSettle();
  }

  testWidgets('a theme is written out where the user says', (tester) async {
    await controller.saveCustomTheme(
      sampleCustomTheme(id: 'mine', name: 'Mine'),
    );
    String? writtenName;
    String? writtenJson;
    await pumpPage(
      tester,
      pick: () async => null,
      save: ({required name, required json}) async {
        writtenName = name;
        writtenJson = json;
        return '/somewhere/Mine.json';
      },
    );

    await tapMenu(tester, 'custom:mine', 'export');

    expect(writtenName, 'Mine');
    final read = decodeThemeFile(writtenJson!) as ThemeFileRead;
    expect(read.name, 'Mine');
    expect(read.day, sampleCustomTheme().day);
    // And the app says where it landed.
    expect(
      find.text(AppStrings.themeExportDone('/somewhere/Mine.json')),
      findsOneWidget,
    );
  });

  testWidgets('a dismissed export writes nothing and says nothing', (
    tester,
  ) async {
    await controller.saveCustomTheme(
      sampleCustomTheme(id: 'mine', name: 'Mine'),
    );
    var written = false;
    await pumpPage(
      tester,
      pick: () async => null,
      save: ({required name, required json}) async {
        written = true;
        return null;
      },
    );

    await tapMenu(tester, 'custom:mine', 'export');

    expect(written, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('an imported theme lands in the list, and is worn', (
    tester,
  ) async {
    await pumpPage(tester, pick: () async => fileNamed('Imported'));

    await tester.tap(find.byKey(SettingsThemesScreen.importTheme));
    await tester.pumpAndSettle();

    final theme = (await controller.customThemes()).single;
    expect(theme.name, 'Imported');
    expect(theme.day, sampleCustomTheme().day);
    expect(find.text('Imported'), findsOneWidget);
    expect(AppThemes.theme, CustomAppTheme(theme));
  });

  testWidgets('an imported name that is taken is asked again', (tester) async {
    await controller.saveCustomTheme(
      sampleCustomTheme(id: 'mine', name: 'Mine'),
    );
    await pumpPage(tester, pick: () async => fileNamed('Mine'));

    await tester.tap(find.byKey(SettingsThemesScreen.importTheme));
    await tester.pumpAndSettle();

    // The dialog says why it is asking, and the name can be typed over.
    expect(find.text(AppStrings.themeNameTaken), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Mine too');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.actionOk));
    await tester.pumpAndSettle();

    expect(
      (await controller.customThemes()).map((theme) => theme.name),
      containsAll(<String>['Mine', 'Mine too']),
    );
  });

  testWidgets('refusing the name imports nothing', (tester) async {
    await controller.saveCustomTheme(
      sampleCustomTheme(id: 'mine', name: 'Mine'),
    );
    await pumpPage(tester, pick: () async => fileNamed('Mine'));

    await tester.tap(find.byKey(SettingsThemesScreen.importTheme));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, AppStrings.actionCancel));
    await tester.pumpAndSettle();

    expect(await controller.customThemes(), hasLength(1));
  });

  testWidgets('a file that is not a theme says why, and imports nothing', (
    tester,
  ) async {
    final cases = <String, String>{
      'not json at all': AppStrings.themeImportInvalid,
      '{"format":"niman-theme","version":2,"name":"Later"}':
          AppStrings.themeImportVersion(2),
      '{"format":"niman-theme","version":1,"name":"Holes","day":{},'
          '"night":{}}': AppStrings.themeImportBadRole(
        'background',
      ),
    };

    for (final MapEntry(key: source, value: reason) in cases.entries) {
      await pumpPage(tester, pick: () async => source);
      await tester.tap(find.byKey(SettingsThemesScreen.importTheme));
      await tester.pumpAndSettle();

      expect(find.text(reason), findsOneWidget, reason: source);
      await tester.tap(find.widgetWithText(TextButton, AppStrings.actionOk));
      await tester.pumpAndSettle();
      expect(await controller.customThemes(), isEmpty, reason: source);
    }
  });

  testWidgets('a read that fails is said, not swallowed', (tester) async {
    await pumpPage(tester, pick: () async => throw StateError('no file'));

    await tester.tap(find.byKey(SettingsThemesScreen.importTheme));
    await tester.pumpAndSettle();

    expect(find.textContaining('no file'), findsOneWidget);
    expect(await controller.customThemes(), isEmpty);
  });
}
