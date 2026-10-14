/// The shared download-and-apply flow (issue #81: auto-update).
///
/// Used by the update banner and the settings "Download" row: downloads the
/// asset with its progress on show, hands it to the platform, and reports
/// the outcome in a snackbar. One download at a time, whichever of the two
/// started it: both read [updateDownload] (#900).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/update/release_asset.dart';
import 'package:niman/src/update/update_check.dart';
import 'package:niman/src/update/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// The download running now, if any (#900): how far it got, and the way to
/// stop it. The banner and the Settings row both show it.
final class UpdateDownload extends ChangeNotifier {
  /// Whether a download is running.
  bool get running => _running;
  bool _running = false;

  /// How much of it has come, 0 to 1; null while the size is not known.
  double? get progress => _progress;
  double? _progress;

  /// Whether its Cancel was pressed.
  bool get cancelled => _cancelled;
  bool _cancelled = false;

  /// Starts a download; false when one is already running.
  bool start() {
    if (_running) return false;
    _running = true;
    _cancelled = false;
    _progress = null;
    notifyListeners();
    return true;
  }

  /// [received] bytes of [total] have come.
  void report(int received, int? total) {
    final next = total == null || total == 0 ? null : received / total;
    // A redraw per whole percent, not per chunk.
    if (next != null &&
        _progress != null &&
        (next * 100).floor() == (_progress! * 100).floor()) {
      return;
    }
    _progress = next;
    notifyListeners();
  }

  /// Stops the download at its next chunk.
  void cancel() {
    if (!_running) return;
    _cancelled = true;
    notifyListeners();
  }

  /// The download is over, however it ended.
  void finish() {
    _running = false;
    _progress = null;
    notifyListeners();
  }
}

/// The app's one update download.
final UpdateDownload updateDownload = UpdateDownload();

/// The page of the latest release, for an update the installer would not
/// take.
final Uri _releasePage = Uri.parse(
  'https://github.com/Nihmar/Niman/releases/latest',
);

/// The steps of the flow that reach the platform, so a test can stand in for
/// them: the download, the install permission and the hand-over.
final class UpdateSteps {
  /// The real steps.
  const new({
    this.download = downloadAsset,
    this.canInstall = canInstallPackages,
    this.openPermission = openInstallPermission,
    this.apply = applyDownloadedUpdate,
  });

  /// Fetches and verifies the asset.
  final Future<File> Function(
    ReleaseAsset asset, {
    void Function(int received, int? total)? onProgress,
    bool Function()? isCancelled,
  })
  download;

  /// Whether the platform lets the app install a package now.
  final Future<bool> Function() canInstall;

  /// Opens the page that grants it; false when it did not open.
  final Future<bool> Function() openPermission;

  /// Hands the downloaded file to the platform.
  final Future<bool> Function(File file) apply;
}

/// Downloads [update]'s asset and hands it to the platform.
///
/// Windows launches the setup installer; Linux reveals the download;
/// Android asks for "Install unknown apps" first when it is not granted,
/// and opens the system installer once it is. A download already running
/// is not started twice. Every outcome — and every failure, the hand-over's
/// too (#905) — surfaces as a snackbar, never a dialog; the permission's
/// explanation is the one dialog, because it sends the user out of the app.
///
/// True once the platform took the update — the installer opened — so a
/// banner that offered it can go; false leaves the offer standing.
Future<bool> downloadAndApplyUpdate(
  BuildContext context,
  UpdateAvailable update, {
  UpdateSteps steps = const UpdateSteps(),
}) async {
  const log = AppLogger(name: 'update');
  if (!updateDownload.start()) return false;
  final messenger = ScaffoldMessenger.of(context);
  log.debug('downloading ${update.asset.name}');
  final File file;
  try {
    file = await steps.download(
      update.asset,
      onProgress: updateDownload.report,
      isCancelled: () => updateDownload.cancelled,
    );
  } on UpdateCancelled {
    log.debug('download cancelled');
    return false;
  } on Object catch (error) {
    log.warning('download failed: $error');
    messenger.showSnackBar(
      SnackBar(content: Text(AppStrings.updateCheckFailed)),
    );
    return false;
  } finally {
    updateDownload.finish();
  }
  final bool launched;
  try {
    if (!await steps.canInstall()) {
      if (!context.mounted) return false;
      log.debug('install permission missing: asking');
      if (!await _askInstallPermission(context, steps)) return false;
    }
    launched = await steps.apply(file);
  } on Object catch (error) {
    // Starting the installer can throw (a ProcessException on Windows: the
    // setup file blocked, removed or refused): the offer stands, and the
    // user is told rather than left to an uncaught async error.
    log.warning('install failed: $error');
    messenger.showSnackBar(_installerFailed());
    return false;
  }
  log.debug('saved ${file.path} (launched=$launched)');
  messenger.showSnackBar(
    launched
        ? SnackBar(
            persist: false,
            content: Text(AppStrings.updateInstallerStarted),
          )
        : update.asset.name.endsWith('.apk')
        ? _installerFailed()
        : SnackBar(
            persist: false,
            content: Text(AppStrings.updateSavedTo(file.path)),
          ),
  );
  return launched;
}

/// The installer did not open: the release itself is what is left to offer,
/// since the APK is in the app's own storage.
SnackBar _installerFailed() => SnackBar(
  // An action would keep it up until it is dismissed by hand.
  persist: false,
  content: Text(AppStrings.updateInstallerFailed),
  action: SnackBarAction(
    label: AppStrings.updateReleasePage,
    onPressed: () => unawaited(
      launchUrl(_releasePage, mode: LaunchMode.externalApplication),
    ),
  ),
);

/// Explains Android's "Install unknown apps", opens its page, and waits
/// for the user to come back; true once the permission is there.
Future<bool> _askInstallPermission(
  BuildContext context,
  UpdateSteps steps,
) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('update-install-permission'),
      title: Text(AppStrings.updateInstallPermissionTitle),
      content: Text(AppStrings.updateInstallPermissionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('update-install-permission-open'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(AppStrings.updateOpenSettings),
        ),
      ],
    ),
  );
  if (go != true) return false;
  final back = Completer<void>();
  final listener = AppLifecycleListener(
    onResume: () {
      if (!back.isCompleted) back.complete();
    },
  );
  try {
    if (!await steps.openPermission()) return false;
    await back.future;
  } finally {
    listener.dispose();
  }
  return await steps.canInstall();
}
