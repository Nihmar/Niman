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

/// Downloads [update]'s asset and hands it to the platform.
///
/// Windows launches the setup installer; Linux reveals the download;
/// Android asks for "Install unknown apps" first when it is not granted,
/// and opens the system installer once it is. A download already running
/// is not started twice. Every outcome — and every failure — surfaces as a
/// snackbar, never a dialog; the permission's explanation is the one
/// dialog, because it sends the user out of the app.
///
/// True once the platform took the update — the installer opened — so a
/// banner that offered it can go; false leaves the offer standing.
Future<bool> downloadAndApplyUpdate(
  BuildContext context,
  UpdateAvailable update,
) async {
  const log = AppLogger(name: 'update');
  if (!updateDownload.start()) return false;
  final messenger = ScaffoldMessenger.of(context);
  log.debug('downloading ${update.asset.name}');
  final File file;
  try {
    file = await downloadAsset(
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
  if (!await canInstallPackages()) {
    if (!context.mounted) return false;
    log.debug('install permission missing: asking');
    if (!await _askInstallPermission(context)) return false;
  }
  final launched = await applyDownloadedUpdate(file);
  log.debug('saved ${file.path} (launched=$launched)');
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        launched
            ? AppStrings.updateInstallerStarted
            : update.asset.name.endsWith('.apk')
            ? AppStrings.updateInstallerFailed
            : AppStrings.updateSavedTo(file.path),
      ),
      // The APK is in the app's own storage: what is left to offer is the
      // release itself.
      action: launched || !update.asset.name.endsWith('.apk')
          ? null
          : SnackBarAction(
              label: AppStrings.updateReleasePage,
              onPressed: () => unawaited(
                launchUrl(_releasePage, mode: LaunchMode.externalApplication),
              ),
            ),
    ),
  );
  return launched;
}

/// Explains Android's "Install unknown apps", opens its page, and waits
/// for the user to come back; true once the permission is there.
Future<bool> _askInstallPermission(BuildContext context) async {
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
    if (!await openInstallPermission()) return false;
    await back.future;
  } finally {
    listener.dispose();
  }
  return await canInstallPackages();
}
