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
    bool Function()? isCancelled,
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
}
