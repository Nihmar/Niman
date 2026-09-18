// T-L10N-03/04: the language setting changes the app's own text at
// once, and is remembered.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/ui/settings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    AppLanguages.reset();
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    AppLanguages.reset();
  });

  /// Pumps the settings body, rebuilt whenever the language changes (the
  /// app root does the same for every screen).
  Future<void> pump(WidgetTester tester) async {
    // Tall enough to reach the language row without scrolling: the
    // settings list is long and lazy.
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ValueListenableBuilder<int>(
        valueListenable: AppLanguages.revision,
        builder: (context, _, _) => MaterialApp(
          locale: AppLanguages.locale,
          supportedLocales: const [Locale('en'), Locale('it')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: SettingsBody(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the Appearance area (issue #104: the language row lives in
  /// the pushed area screen), then the language row's dialog, and picks
  /// [language].
  ///
  /// The row shows the current language and the choice happens in a
  /// dialog, so a bare `find.text` would match the row's own value.
  Future<void> chooseLanguage(WidgetTester tester, AppLanguage language) async {
    await tester.tap(find.byKey(const Key('settings-area-appearance')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('settings-choice-$language')));
    await tester.pumpAndSettle();
  }

  testWidgets('choosing Italian translates the app and persists', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Appearance'), findsOneWidget);

    await chooseLanguage(tester, AppLanguage.italian);

    // The area screen's app bar and rows follow the app root's rebuild.
    expect(find.text('Aspetto'), findsOneWidget);
    expect(find.text('Lingua'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    expect(await controller.language, AppLanguage.italian);
    expect(AppLanguages.resolved, AppLanguage.italian);
  });

  testWidgets('a newly added language picks its own text', (tester) async {
    await pump(tester);
    expect(find.text('Appearance'), findsOneWidget);

    await chooseLanguage(tester, AppLanguage.french);

    expect(find.text('Apparence'), findsOneWidget);
    expect(find.text('Langue'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    expect(await controller.language, AppLanguage.french);
    expect(AppLanguages.resolved, AppLanguage.french);
  });

  testWidgets('going back to English translates back', (tester) async {
    await controller.setLanguage(AppLanguage.italian);
    AppLanguages.choice = AppLanguage.italian;
    await pump(tester);
    expect(find.text('Aspetto'), findsOneWidget);

    await chooseLanguage(tester, AppLanguage.english);

    expect(find.text('Appearance'), findsOneWidget);
    expect(await controller.language, AppLanguage.english);
  });

  testWidgets('System follows the OS language', (tester) async {
    await controller.setLanguage(AppLanguage.english);
    AppLanguages.choice = AppLanguage.english;
    AppLanguages.system = AppLanguage.italian;
    await pump(tester);
    expect(find.text('Appearance'), findsOneWidget);

    await chooseLanguage(tester, AppLanguage.system);

    // The OS is Italian, so "System" means Italian.
    expect(find.text('Aspetto'), findsOneWidget);
    expect(find.text('Lingua'), findsOneWidget);
    expect(await controller.language, AppLanguage.system);
    expect(AppLanguages.resolved, AppLanguage.italian);
  });
}
