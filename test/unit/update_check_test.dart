// Issue #81: the Android asset's selection and the release check's outcome.
// A computer is offered nothing: it finds its versions on the release page
// (#1270).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/update/app_version.dart';
import 'package:niman/src/update/release_asset.dart';
import 'package:niman/src/update/update_check.dart';

List<ReleaseAsset> sampleAssets() => const [
  ReleaseAsset(
    name: 'niman-1.0.0-android.apk',
    downloadUrl: 'https://example.com/niman-1.0.0-android.apk',
  ),
  ReleaseAsset(
    name: 'niman-1.0.0-linux-x64.tar.gz',
    downloadUrl: 'https://example.com/niman-1.0.0-linux-x64.tar.gz',
  ),
  ReleaseAsset(
    name: 'niman-1.0.0-linux-x64.AppImage',
    downloadUrl: 'https://example.com/niman-1.0.0-linux-x64.AppImage',
  ),
  ReleaseAsset(
    name: 'niman-1.0.0-1-x86_64.pkg.tar.zst',
    downloadUrl: 'https://example.com/niman-1.0.0.pkg.tar.zst',
  ),
  ReleaseAsset(
    name: 'niman-1.0.0-macos.dmg',
    downloadUrl: 'https://example.com/niman-1.0.0-macos.dmg',
  ),
  ReleaseAsset(
    name: 'niman-1.0.0-macos.zip',
    downloadUrl: 'https://example.com/niman-1.0.0-macos.zip',
  ),
  ReleaseAsset(
    name: 'niman-1.0.0-windows-x64-setup.exe',
    downloadUrl: 'https://example.com/niman-1.0.0-windows-x64-setup.exe',
  ),
  ReleaseAsset(
    name: 'niman-1.0.0-windows-x64.zip',
    downloadUrl: 'https://example.com/niman-1.0.0-windows-x64.zip',
  ),
];

void main() {
  group('asset selection', () {
    test('android picks the apk', () {
      expect(
        selectAndroidAsset(sampleAssets())!.name,
        'niman-1.0.0-android.apk',
      );
    });

    test('android picks the official apk, not the testing build', () {
      // The order the 0.0.10 release page had: GitHub lists assets by
      // name, and `-android-testing.apk` sorts before `-android.apk`.
      const page = [
        ReleaseAsset(
          name: 'niman-1.0.0-android-testing.apk',
          downloadUrl: 'https://example.com/niman-1.0.0-android-testing.apk',
        ),
        ReleaseAsset(
          name: 'niman-1.0.0-android.apk',
          downloadUrl: 'https://example.com/niman-1.0.0-android.apk',
        ),
      ];
      expect(selectAndroidAsset(page)!.name, 'niman-1.0.0-android.apk');
    });

    test('android with only a testing apk offers nothing', () {
      // A testing APK installs beside the app, so it can never update it:
      // with no official APK there is no update to offer (issue #355).
      const page = [
        ReleaseAsset(
          name: 'niman-1.0.0-android-testing.apk',
          downloadUrl: 'https://example.com/niman-1.0.0-android-testing.apk',
        ),
      ];
      expect(selectAndroidAsset(page), isNull);
    });

    test('missing assets return null', () {
      expect(selectAndroidAsset(const []), isNull);
    });
  });

  group('LatestRelease.fromJson', () {
    test('decodes tag and assets, skips malformed entries', () {
      final release = LatestRelease.fromJson({
        'tag_name': 'v1.0.0',
        'assets': [
          {
            'name': 'niman-1.0.0-android.apk',
            'browser_download_url': 'https://example.com/a.apk',
          },
          {'name': 'checksums.txt'}, // no url: skipped
          'not-a-map', // skipped
        ],
      });
      expect(release.version, const AppVersion(1, 0, 0));
      expect(release.assets, hasLength(1));
    });

    test('rejects missing or unparseable tag', () {
      expect(() => LatestRelease.fromJson({}), throwsFormatException);
      expect(
        () => LatestRelease.fromJson({'tag_name': 'nightly'}),
        throwsFormatException,
      );
    });

    // Issue #384: the asset's published digest must survive decoding.
    test('carries the asset digest, absent when the API omits it', () {
      final release = LatestRelease.fromJson({
        'tag_name': 'v1.0.0',
        'assets': [
          {
            'name': 'niman-1.0.0-android.apk',
            'browser_download_url': 'https://example.com/a.apk',
            'digest': 'sha256:abc123',
          },
          {
            'name': 'niman-1.0.0-windows-x64-setup.exe',
            'browser_download_url': 'https://example.com/setup.exe',
          },
        ],
      });
      expect(release.assets.first.digest, 'sha256:abc123');
      expect(release.assets.first.expectedSha256, 'abc123');
      expect(release.assets.last.digest, isNull);
      expect(release.assets.last.expectedSha256, isNull);
    });
  });

  group('checkForUpdate', () {
    LatestRelease release() => LatestRelease(
      version: const AppVersion(1, 0, 0),
      assets: sampleAssets(),
    );

    test('newer release on android offers the apk', () {
      final result = checkForUpdate(
        release: release(),
        current: const AppVersion(0, 0, 3),
        isAndroid: true,
      );
      expect(result, isA<UpdateAvailable>());
      final available = result as UpdateAvailable;
      expect(available.asset.name, 'niman-1.0.0-android.apk');
    });

    test('off Android nothing is offered, whatever the release carries', () {
      // A computer goes to the release page (#1270), and iOS is the App
      // Store's: the setup, the disk image and the AppImage are all here.
      final result = checkForUpdate(
        release: release(),
        current: const AppVersion(0, 0, 3),
        isAndroid: false,
      );
      expect(result, isA<UpToDate>());
    });

    test('current or newer version is up to date', () {
      for (final current in [
        const AppVersion(1, 0, 0),
        const AppVersion(2, 0, 0),
      ]) {
        expect(
          checkForUpdate(release: release(), current: current, isAndroid: true),
          isA<UpToDate>(),
        );
      }
    });
  });
}
