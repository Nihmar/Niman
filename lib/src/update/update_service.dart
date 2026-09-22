/// Downloading and applying releases (issue #81: auto-update).
///
/// The metadata fetch runs in an isolate ([fetchLatestRelease], through
/// [Isolate.run]): no network I/O on the UI isolate. The download itself
/// streams to disk with [HttpClient]; drift writes stay on the main
/// isolate, in the scheduler's callbacks.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/changelog.dart';
import 'package:niman/src/update/app_version.dart';
import 'package:niman/src/update/release_asset.dart';
import 'package:niman/src/update/update_check.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The GitHub API endpoint listing the latest Niman release.
const String latestReleaseUrl =
    'https://api.github.com/repos/Nihmar/Niman/releases/latest';

/// Fetches and decodes the latest-release payload.
///
/// A top-level function so the scheduler can run it in an isolate: it
/// takes nothing and touches no shared state.
Future<Map<String, dynamic>> fetchLatestReleaseJson() async {
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse(latestReleaseUrl))
        .timeout(const Duration(seconds: 20));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'niman-auto-update');
    final response = await request.close().timeout(const Duration(seconds: 20));
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'GitHub releases answered ${response.statusCode}',
        uri: Uri.parse(latestReleaseUrl),
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('GitHub releases answered no object');
    }
    return decoded;
  } finally {
    client.close();
  }
}

/// Fetches the latest published release off the UI isolate.
Future<LatestRelease> fetchLatestRelease() async {
  final json = await Isolate.run(fetchLatestReleaseJson);
  return LatestRelease.fromJson(json);
}

/// The running app's version, through the changelog's [appVersion].
///
/// Throws when the version is unparseable or the platform channel is
/// unavailable: scheduled callers treat it as a quiet skip, display
/// callers catch it.
Future<AppVersion> currentAppVersion() async {
  final version = AppVersion.tryParse(await appVersion());
  if (version == null) {
    throw const FormatException('unparseable app version');
  }
  return version;
}

/// Which Linux package variant this process runs as.
///
/// An AppImage sets `APPIMAGE` to its own file; a tarball and an Arch
/// package leave no reliable trace, so both read as [LinuxVariant.unknown]
/// and the user picks from the downloaded assets instead.
LinuxVariant detectLinuxVariant() {
  final appImage = Platform.environment['APPIMAGE'];
  if (appImage != null && appImage.isNotEmpty) return LinuxVariant.appImage;
  return LinuxVariant.unknown;
}

/// Runs the full update check for this device: latest release against the
/// running version, with this platform's asset selected.
///
/// Returns the available update, or null when current (or when no asset
/// matches, e.g. an unknown Linux variant — the picker case).
Future<UpdateAvailable?> checkNow({required AppVersion current}) async {
  final release = await fetchLatestRelease();
  final check = checkForUpdate(
    release: release,
    current: current,
    isAndroid: Platform.isAndroid,
    isWindows: Platform.isWindows,
    linuxVariant: Platform.isLinux
        ? detectLinuxVariant()
        : LinuxVariant.unknown,
  );
  return check is UpdateAvailable ? check : null;
}

/// The folder downloads land in: the platform Downloads, falling back to
/// `~/Downloads`, created on the way.
Future<Directory> downloadDirectory() async {
  final platform = await getDownloadsDirectory();
  final candidates = [
    if (platform != null) platform.path,
    if (Platform.isLinux || Platform.isMacOS)
      if (Platform.environment['HOME'] case final home?)
        p.join(home, 'Downloads'),
    if (Platform.isWindows)
      if (Platform.environment['USERPROFILE'] case final home?)
        p.join(home, 'Downloads'),
  ];
  for (final path in candidates) {
    try {
      return await Directory(path).create(recursive: true);
    } on FileSystemException {
      continue;
    }
  }
  throw StateError('no downloads folder is reachable');
}

/// The folder update downloads land in.
///
/// The platform Downloads everywhere except Android, where the APK goes
/// into the app support directory's `updates/` folder instead: it needs
/// no storage permission there, and the system installer reads it
/// through FileProvider (see `file_provider_paths.xml`).
Future<Directory> updateDownloadDirectory() {
  if (Platform.isAndroid) {
    return appSupportDirectory().then(
      (support) =>
          Directory(p.join(support.path, 'updates')).create(recursive: true),
    );
  }
  return downloadDirectory();
}

/// Streams [asset] into [into] (default [updateDownloadDirectory]).
///
/// The file name is the asset's base name, so a hostile release cannot
/// escape the folder.
Future<File> downloadAsset(ReleaseAsset asset, {Directory? into}) async {
  final dir = into ?? await updateDownloadDirectory();
  final file = File(p.join(dir.path, p.basename(asset.name)));
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(Uri.parse(asset.downloadUrl))
        .timeout(const Duration(seconds: 20));
    final response = await request.close().timeout(const Duration(seconds: 20));
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'download answered ${response.statusCode}',
        uri: Uri.parse(asset.downloadUrl),
      );
    }
    await response.pipe(file.openWrite());
    return file;
  } finally {
    client.close();
  }
}

/// Hands a downloaded [file] to the platform.
///
/// - Android: opens the system package installer for the APK (issue #81)
///   and returns whether it launched; the user still confirms there.
/// - Windows: launches the setup installer and returns true.
/// - Linux: reveals the Downloads folder (best effort) and returns false.
Future<bool> applyDownloadedUpdate(File file) {
  if (Platform.isAndroid) return installApk(file);
  return _applyDesktop(file);
}

/// Hands a downloaded [file] to a desktop platform: see
/// [applyDownloadedUpdate].
Future<bool> _applyDesktop(File file) async {
  if (Platform.isWindows) {
    await Process.start(file.path, []);
    return true;
  }
  if (Platform.isLinux) {
    try {
      await Process.run('xdg-open', [file.parent.path]);
    } on ProcessException {
      // Revealing is a courtesy; the file is downloaded either way.
    }
  }
  return false;
}

/// Opens the system package installer for the downloaded [apk].
///
/// False when the bridge is unreachable (tests) or the installer
/// refuses the file; the APK stays in the updates folder either way.
Future<bool> installApk(File apk) async {
  try {
    final launched = await const MethodChannel('niman/update')
        .invokeMethod<bool>('installApk', {'path': apk.path});
    return launched ?? false;
  } on Object {
    return false;
  }
}
