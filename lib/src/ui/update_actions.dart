/// The shared download-and-apply flow (issue #81: auto-update).
///
/// Used by the update banner and the settings "Check for updates" row:
/// downloads the asset, hands it to the platform, and reports the outcome
/// in a snackbar.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/update/update_check.dart';
import 'package:niman/src/update/update_service.dart';

/// Downloads [update]'s asset and hands it to the platform.
///
/// Windows launches the setup installer; Linux reveals the download;
/// Android leaves the APK in Downloads until the native installer bridge
/// lands (issue #81). Every outcome — and every failure — surfaces as a
/// snackbar, never a dialog.
Future<void> downloadAndApplyUpdate(
  BuildContext context,
  UpdateAvailable update,
) async {
  final messenger = ScaffoldMessenger.of(context);
  const AppLogger(name: 'update').debug('downloading ${update.asset.name}');
  try {
    final file = await downloadAsset(update.asset);
    final launched = await applyDownloadedUpdate(file);
    const AppLogger(name: 'update')
        .debug('saved ${file.path} (launched=$launched)');
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          launched
              ? AppStrings.updateInstallerStarted
              : AppStrings.updateSavedTo(file.path),
        ),
      ),
    );
  } on Object catch (error) {
    const AppLogger(name: 'update').warning('download failed: $error');
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(AppStrings.updateCheckFailed)),
    );
  }
}
