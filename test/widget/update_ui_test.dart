// The update banner and the Updates screen on a phone: the banner clears
// the status bar instead of sitting under it, and "Check for updates" only
// checks — an update found enables the Download row, and nothing is fetched
// until that row is pressed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/settings_updates.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/update_banner.dart';
import 'package:niman/src/update/app_version.dart';
import 'package:niman/src/update/release_asset.dart';
import 'package:niman/src/update/update_check.dart';

import '../fakes/fake_library_session.dart';

final UpdateAvailable _update = UpdateAvailable(
  version: AppVersion.tryParse('9.9.9')!,
  asset: const ReleaseAsset(
    name: 'niman.apk',
    downloadUrl: 'https://example.invalid/niman.apk',
  ),
);

Finder _downloadRow() => find.byKey(const Key('settings-update-download'));

bool _enabled(WidgetTester tester) =>
    tester.widget<SettingsActionRow>(_downloadRow()).enabled;

void main() {
  testWidgets('the banner clears the status bar', (tester) async {
    final session = FakeLibrarySession()..pendingUpdate = _update;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          // A phone's status bar: 24 logical pixels over the app.
          data: const MediaQueryData(padding: EdgeInsets.only(top: 24)),
          child: Scaffold(
            body: Column(children: [UpdateAvailableBanner(session: session)]),
          ),
        ),
      ),
    );
    final banner = find.byType(MaterialBanner);
    expect(
      tester.getTopLeft(banner).dy,
      greaterThanOrEqualTo(24),
      reason: 'under the status bar its first line was cut off',
    );
    expect(
      find.descendant(
        of: banner,
        matching: find.text(AppStrings.actionDownload),
      ),
      findsOne,
    );
  });

  testWidgets('checking only checks; Download fetches', (tester) async {
    final session = FakeLibrarySession();
    var downloads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsUpdatesScreen(
          controller: session,
          checkUpdate: () async => _update,
          downloadUpdate: (_, _) async => downloads++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_downloadRow(), findsOne, reason: 'there before any check');
    expect(_enabled(tester), isFalse, reason: 'nothing found yet');
    await tester.tap(_downloadRow());
    await tester.pumpAndSettle();
    expect(downloads, 0, reason: 'off, it fetches nothing');

    await tester.tap(find.text(AppStrings.checkForUpdatesTitle));
    await tester.pumpAndSettle();
    expect(downloads, 0, reason: 'a check is not a download');
    expect(find.text(AppStrings.updateAvailableMessage('9.9.9')), findsOne);
    expect(_enabled(tester), isTrue);

    await tester.tap(_downloadRow());
    await tester.pumpAndSettle();
    expect(downloads, 1);
  });

  testWidgets('up to date leaves Download off', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsUpdatesScreen(
          controller: FakeLibrarySession(),
          checkUpdate: () async => null,
          downloadUpdate: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.checkForUpdatesTitle));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.updateUpToDate), findsOne);
    expect(_enabled(tester), isFalse);
  });

  testWidgets('an update the scheduled check found is ready to download', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsUpdatesScreen(
          controller: FakeLibrarySession()..pendingUpdate = _update,
          checkUpdate: () async => null,
          downloadUpdate: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.updateAvailableMessage('9.9.9')), findsOne);
    expect(_enabled(tester), isTrue);
  });
}
