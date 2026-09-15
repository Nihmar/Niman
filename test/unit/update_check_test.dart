// Issue #81: per-platform asset selection and release check outcome.
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

    test('windows picks the installer, never the portable zip', () {
      expect(
        selectWindowsAsset(sampleAssets())!.name,
        'niman-1.0.0-windows-x64-setup.exe',
      );
      expect(
        selectWindowsAsset(const [
          ReleaseAsset(
            name: 'niman-1.0.0-windows-x64.zip',
            downloadUrl: 'https://example.com/x.zip',
          ),
        ]),
        isNull,
      );
    });

    test('linux picks the installed variant', () {
      expect(
        selectLinuxAsset(sampleAssets(), LinuxVariant.appImage)!.name,
        'niman-1.0.0-linux-x64.AppImage',
      );
      expect(
        selectLinuxAsset(sampleAssets(), LinuxVariant.tarball)!.name,
        'niman-1.0.0-linux-x64.tar.gz',
      );
      expect(
        selectLinuxAsset(sampleAssets(), LinuxVariant.archPackage)!.name,
        'niman-1.0.0-1-x86_64.pkg.tar.zst',
      );
    });

    test('linux unknown variant defers to the picker', () {
      expect(selectLinuxAsset(sampleAssets(), LinuxVariant.unknown), isNull);
      expect(linuxAssets(sampleAssets()), hasLength(3));
    });

    test('missing assets return null', () {
      expect(selectAndroidAsset(const []), isNull);
      expect(selectWindowsAsset(const []), isNull);
      expect(selectLinuxAsset(const [], LinuxVariant.appImage), isNull);
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
        isWindows: false,
        linuxVariant: LinuxVariant.unknown,
      );
      expect(result, isA<UpdateAvailable>());
      final available = result as UpdateAvailable;
      expect(available.asset.name, 'niman-1.0.0-android.apk');
    });

    test('newer release on windows offers the installer', () {
      final result = checkForUpdate(
        release: release(),
        current: const AppVersion(0, 0, 3),
        isAndroid: false,
        isWindows: true,
        linuxVariant: LinuxVariant.unknown,
      );
      expect(
        (result as UpdateAvailable).asset.name,
        'niman-1.0.0-windows-x64-setup.exe',
      );
    });

    test('newer release on linux appimage offers the appimage', () {
      final result = checkForUpdate(
        release: release(),
        current: const AppVersion(0, 0, 3),
        isAndroid: false,
        isWindows: false,
        linuxVariant: LinuxVariant.appImage,
      );
      expect(
        (result as UpdateAvailable).asset.name,
        'niman-1.0.0-linux-x64.AppImage',
      );
    });

    test('current or newer version is up to date', () {
      for (final current in [
        const AppVersion(1, 0, 0),
        const AppVersion(2, 0, 0),
      ]) {
        expect(
          checkForUpdate(
            release: release(),
            current: current,
            isAndroid: true,
            isWindows: false,
            linuxVariant: LinuxVariant.unknown,
          ),
          isA<UpToDate>(),
        );
      }
    });

    test('unknown linux variant with no matching asset stays quiet', () {
      final result = checkForUpdate(
        release: release(),
        current: const AppVersion(0, 0, 3),
        isAndroid: false,
        isWindows: false,
        linuxVariant: LinuxVariant.unknown,
      );
      expect(result, isA<UpToDate>());
      // ... while the settings UI can still offer the picker:
      expect(linuxAssets(release().assets), hasLength(3));
    });
  });
}
