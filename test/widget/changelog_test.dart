// Issue #80: the in-app changelog — the launch dialog after an update and
// the screen reached from Settings.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/changelog.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/changelog.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

final _newVersion = ChangelogVersion(
  version: '1.2.3',
  date: DateTime(2026, 9, 14),
  sections: [
    ChangelogSection(title: 'Added', items: ['A new feature']),
  ],
);

final _olderVersion = ChangelogVersion(
  version: '1.2.2',
  sections: [
    ChangelogSection(title: 'Fixed', items: ['An old fix']),
  ],
);

void main() {
  late FakeLibrarySession session;
  late AppLanguage previousLanguage;

  setUp(() async {
    session = FakeLibrarySession();
    await session.open('/fake/library', create: true);
    // The strings below are English; do not follow the test host's OS.
    previousLanguage = AppLanguages.choice;
    AppLanguages.choice = AppLanguage.english;
  });
  tearDown(() {
    AppLanguages.choice = previousLanguage;
    unawaited(session.dispose());
  });

  /// Pumps the app root with the update check forced to report [update]
  /// (null = nothing new).
  Future<void> pumpApp(
    WidgetTester tester, {
    List<ChangelogVersion>? update,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(session),
          changelogUpdateProvider.overrideWith((ref) => Future.value(update)),
        ],
        child: const NimanApp(),
      ),
    );
  }

  testWidgets('the launch dialog shows the new version and dismisses', (
    tester,
  ) async {
    await pumpApp(tester, update: [_newVersion]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('changelog-update-dialog')), findsOne);
    expect(find.text("What's new in 1.2.3"), findsOne);
    expect(find.text('1.2.3 · 2026-09-14'), findsOne);
    expect(find.text('Added'), findsOne);
    expect(find.text('A new feature'), findsOne);

    await tester.tap(find.byKey(const Key('changelog-update-ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('changelog-update-dialog')), findsNothing);
  });

  testWidgets('several new versions share one dialog under the plain title', (
    tester,
  ) async {
    await pumpApp(tester, update: [_newVersion, _olderVersion]);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.changelogTitle), findsOne);
    expect(find.text('1.2.3 · 2026-09-14'), findsOne);
    expect(find.text('1.2.2'), findsOne);
    expect(find.text('An old fix'), findsOne);
  });

  testWidgets('no dialog when there is nothing new', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('changelog-update-dialog')), findsNothing);
  });

  testWidgets('the screen lists every shipped version', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          changelogProvider.overrideWith(
            (ref) => Future.value([_newVersion, _olderVersion]),
          ),
        ],
        child: const MaterialApp(home: ChangelogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.changelogTitle), findsOne);
    expect(find.text('1.2.3 · 2026-09-14'), findsOne);
    expect(find.text('A new feature'), findsOne);
    expect(find.text('1.2.2'), findsOne);
    expect(find.text('An old fix'), findsOne);
  });

  testWidgets('the settings row opens the changelog screen', (tester) async {
    tester.view.physicalSize = const Size(900, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          changelogProvider.overrideWith((ref) => Future.value([_newVersion])),
        ],
        child: MaterialApp(
          home: Scaffold(body: SettingsBody(controller: session)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.settingsSectionAbout), findsOne);
    await tester.tap(find.byKey(const Key('changelog-setting')));
    await tester.pumpAndSettle();
    expect(find.byType(ChangelogScreen), findsOneWidget);
    expect(find.text('A new feature'), findsOne);
  });
}
