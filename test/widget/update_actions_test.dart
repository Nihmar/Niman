// The download-and-apply flow of an update (#81, #900): what it shows when
// the platform step after the download fails (#905).
//
// The platform's steps are replaced by [UpdateSteps]; the flow around them is
// the real one.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/update_actions.dart';
import 'package:niman/src/update/app_version.dart';
import 'package:niman/src/update/release_asset.dart';
import 'package:niman/src/update/update_check.dart';
import 'package:path/path.dart' as p;

UpdateAvailable _update(String name) => UpdateAvailable(
  version: AppVersion.tryParse('9.9.9')!,
  asset: ReleaseAsset(name: name, downloadUrl: 'https://example.invalid/$name'),
);

/// Mounts a page whose button runs the flow with [steps] and records its
/// answer in [result].
Future<void> _pump(
  WidgetTester tester, {
  required UpdateAvailable update,
  required UpdateSteps steps,
  required List<bool> result,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result.add(
              await downloadAndApplyUpdate(context, update, steps: steps),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pump();
}

void main() {
  final file = File(p.join('unused', 'niman-setup.exe'));

  Future<File> download(
    ReleaseAsset asset, {
    void Function(int received, int? total)? onProgress,
    Future<void>? cancel,
  }) async => file;

  tearDown(() {
    if (updateDownload.running) updateDownload.finish();
  });

  testWidgets('an installer that cannot be started is told, not thrown '
      '(#905)', (tester) async {
    final result = <bool>[];
    await _pump(
      tester,
      update: _update('niman-9.9.9-windows-x64-setup.exe'),
      result: result,
      steps: UpdateSteps(
        download: download,
        canInstall: () async => true,
        apply: (file) async =>
            throw ProcessException(file.path, const [], 'blocked'),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(result, [false]);
    expect(find.text(AppStrings.updateInstallerFailed), findsOne);
    expect(
      find.text(AppStrings.updateReleasePage),
      findsOne,
      reason: 'the release itself is what is left to offer',
    );
    expect(updateDownload.running, isFalse);
  });

  testWidgets('a permission step that throws is told too (#905)', (
    tester,
  ) async {
    final result = <bool>[];
    await _pump(
      tester,
      update: _update('niman-9.9.9-android.apk'),
      result: result,
      steps: UpdateSteps(
        download: download,
        canInstall: () async => throw PlatformException(code: 'no-bridge'),
        apply: (file) async => true,
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(result, [false]);
    expect(find.text(AppStrings.updateInstallerFailed), findsOne);
  });

  testWidgets('a Cancel that lands after the last chunk never opens the '
      'installer (#911)', (tester) async {
    final result = <bool>[];
    var applied = false;
    await _pump(
      tester,
      update: _update('niman-9.9.9-windows-x64-setup.exe'),
      result: result,
      steps: UpdateSteps(
        // The file comes back whole, but Cancel was pressed while it was
        // hashed: the download step has nothing left to stop.
        download: (asset, {onProgress, cancel}) async {
          updateDownload.cancel();
          return file;
        },
        canInstall: () async => true,
        apply: (file) async => applied = true,
      ),
    );
    await tester.pump();
    expect(result, [false]);
    expect(applied, isFalse);
    expect(find.byType(SnackBar), findsNothing);
    expect(updateDownload.running, isFalse);
  });

  group('without the install permission (#914)', () {
    final apk = _update('niman-9.9.9-android.apk');

    testWidgets('a settings page that cannot be opened says so, and that the '
        'download is kept', (tester) async {
      final result = <bool>[];
      var applied = false;
      await _pump(
        tester,
        update: apk,
        result: result,
        steps: UpdateSteps(
          download: download,
          canInstall: () async => false,
          openPermission: () async => false,
          apply: (file) async => applied = true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('update-install-permission-open')));
      await tester.pump();
      await tester.pump();
      expect(result, [false]);
      expect(applied, isFalse);
      expect(find.text(AppStrings.updateInstallPermissionMissing), findsOne);
    });

    testWidgets('coming back without the grant says so, and that the '
        'download is kept', (tester) async {
      final result = <bool>[];
      var applied = false;
      await _pump(
        tester,
        update: apk,
        result: result,
        steps: UpdateSteps(
          download: download,
          canInstall: () async => false,
          openPermission: () async => true,
          apply: (file) async => applied = true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('update-install-permission-open')));
      await tester.pump();
      await tester.pump();
      expect(result, isEmpty, reason: 'waiting for the user to come back');
      // The settings page took the app to the background, and the user
      // returned from it.
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(result, [false]);
      expect(applied, isFalse);
      expect(find.text(AppStrings.updateInstallPermissionMissing), findsOne);
    });

    testWidgets('coming back with the grant installs', (tester) async {
      final result = <bool>[];
      var granted = false;
      var applied = false;
      await _pump(
        tester,
        update: apk,
        result: result,
        steps: UpdateSteps(
          download: download,
          canInstall: () async => granted,
          openPermission: () async => granted = true,
          apply: (file) async => applied = true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('update-install-permission-open')));
      await tester.pump();
      await tester.pump();
      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(result, [true]);
      expect(applied, isTrue);
      expect(
        find.text(AppStrings.updateInstallPermissionMissing),
        findsNothing,
      );
    });
  });
}
