/// Downloading and applying releases (issue #81: auto-update).
///
/// The metadata fetch runs in an isolate ([fetchLatestRelease], through
/// [Isolate.run]): no network I/O on the UI isolate. The download itself
/// streams to disk with [HttpClient], and its digest is computed on a
/// background isolate ([IsolateGauge.run]) so a 60-100 MB installer is
/// never read and hashed on the UI isolate (#495); drift writes stay on the
/// main isolate, in the scheduler's callbacks.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/changelog.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
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
/// and are offered the release's generic `.tar.gz` bundle instead.
LinuxVariant detectLinuxVariant() {
  final appImage = Platform.environment['APPIMAGE'];
  if (appImage != null && appImage.isNotEmpty) return LinuxVariant.appImage;
  return LinuxVariant.unknown;
}

/// Runs the full update check for this device: latest release against the
/// running version, with this platform's asset selected.
///
/// Returns the available update, or null when current (or when the release
/// carries no asset for this device).
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

/// The downloaded bytes did not match the release's published digest, or
/// the release published no digest to check them against.
///
/// Raised by [downloadAsset] after it deletes the artifact, so nothing
/// unverified is left on disk or handed to the platform (issue #384).
final class UpdateIntegrityException implements Exception {
  /// Creates the refusal for [message].
  const new(this.message);

  /// What went wrong, for the log.
  final String message;

  @override
  String toString() => 'UpdateIntegrityException: $message';
}

/// Streams [asset] into [into] (default [updateDownloadDirectory]) and
/// verifies the bytes against the digest the release published.
///
/// The body lands in `<name>.part` and is renamed to the asset's base name
/// only once its digest matches, so a file under the installer's name is
/// always a whole, verified download and never a half-written one an
/// interrupted transfer left behind (#495). That partial file is removed on
/// every failure — a transport error or a stall, not only a digest
/// mismatch. The body is bounded in silence, not in time: a server that
/// sends its headers and then goes quiet fails within [stallTimeout]
/// instead of holding the check open forever.
///
/// The file name is the asset's base name, so a hostile release cannot
/// escape the folder. A download whose sha256 does not match the digest
/// the release published, or an asset that published none, is deleted and
/// rethrown as [UpdateIntegrityException]; the caller then neither offers
/// nor applies it (issue #384).
Future<File> downloadAsset(
  ReleaseAsset asset, {
  Directory? into,
  Duration stallTimeout = const Duration(seconds: 30),
}) async {
  final dir = into ?? await updateDownloadDirectory();
  final file = File(p.join(dir.path, p.basename(asset.name)));
  final part = File('${file.path}.part');
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
    final sink = part.openWrite();
    try {
      await sink.addStream(
        response.timeout(
          stallTimeout,
          onTimeout: (events) => events.addError(
            TimeoutException('no data for ${stallTimeout.inMilliseconds} ms'),
          ),
        ),
      );
    } finally {
      await _closeQuietly(sink);
    }
    await _verifyDownload(asset, part);
    await part.rename(file.path);
    return file;
  } on Object {
    // Whatever failed — the transport, a stall, the digest — nothing
    // unverified is left on disk.
    await _deleteQuietly(part);
    rethrow;
  } finally {
    client.close(force: true);
  }
}

/// Closes [sink], swallowing a failure: the transfer's own error is the one
/// the caller needs, and a sink that was already aborted must not replace it.
Future<void> _closeQuietly(IOSink sink) async {
  try {
    await sink.close();
  } on Object {
    // The write already failed; the reason below is what matters.
  }
}

/// Removes [file] if it is there, ignoring a failure: the caller is already
/// unwinding an error.
Future<void> _deleteQuietly(File file) async {
  try {
    await file.delete();
  } on FileSystemException {
    // Already gone, or its handle is not released yet.
  }
}

/// Checks [file]'s bytes against [asset]'s published digest.
///
/// The file is read and hashed on a background isolate ([IsolateGauge.run]),
/// never on the UI isolate: a 60-100 MB installer hashed with `readSync` in
/// Dart froze the UI for a second or more (#495). Throws
/// [UpdateIntegrityException] on a mismatch, or when the release carried no
/// sha256 digest at all: an unverifiable download is not silently trusted.
/// The caller removes the file.
Future<void> _verifyDownload(ReleaseAsset asset, File file) async {
  final expected = asset.expectedSha256;
  if (expected == null) {
    throw UpdateIntegrityException(
      'asset ${asset.name} published no sha256 digest to verify against',
    );
  }
  // The closure carries only the path string: [IsolateGauge] spawns the
  // read, and the gauge makes a stuck one visible in an exported log.
  final path = file.path;
  final actual = await IsolateGauge.run(
    () => hashFileSha256(File(path)),
    'verify ${asset.name}',
  );
  if (actual != expected) {
    throw UpdateIntegrityException(
      'asset ${asset.name} failed its digest check '
      '(downloaded $actual, published $expected)',
    );
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
