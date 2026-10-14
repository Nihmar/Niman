/// The shell banner offering a downloaded update (issue #81: auto-update).
///
/// Renders nothing while no update is pending: the scheduler stores what
/// it finds on the session ([LibrarySession.pendingUpdate]) and bumps the
/// revision, so this appears on top of the shell after the next rebuild.
/// Download reuses the shared [downloadAndApplyUpdate] flow; dismiss drops
/// the pending update for this app run.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/update_actions.dart';
import 'package:niman/src/update/update_check.dart';

/// A banner over the shell offering the pending update, if any.
///
/// Download turns it into the download's progress, with a Cancel that
/// stops it; the banner goes once the installer has the update, and stays
/// offering it when it did not get there (#900).
final class UpdateAvailableBanner extends StatelessWidget {
  /// Creates the banner reading the pending update from [session].
  const new({required this.session, super.key});

  /// The session holding the scheduler's pending update.
  final LibrarySession session;

  @override
  Widget build(BuildContext context) {
    final update = session.pendingUpdate;
    if (update == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    // The banner is the top of the window, above the shell's own scaffold:
    // on a phone that is under the status bar, which cut its first line off.
    // The shell below gives the inset up while the banner holds it.
    return SafeArea(
      bottom: false,
      // A download shows how far it got, and its Cancel stops it (#900).
      child: ListenableBuilder(
        listenable: updateDownload,
        builder: (context, _) {
          final running = updateDownload.running;
          final progress = updateDownload.progress;
          return MaterialBanner(
            key: const Key('update-available-banner'),
            leading: Icon(Icons.system_update, color: scheme.primary),
            content: running
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.updateDownloading(
                          ((progress ?? 0) * 100).floor(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        key: const Key('update-download-progress'),
                        value: progress,
                      ),
                    ],
                  )
                : Text(AppStrings.updateAvailableMessage(update.version)),
            actions: running
                ? [
                    TextButton(
                      key: const Key('update-download-cancel'),
                      onPressed: updateDownload.cancelled
                          ? null
                          : updateDownload.cancel,
                      child: Text(AppStrings.actionCancel),
                    ),
                  ]
                : [
                    TextButton(
                      key: const Key('update-available-download'),
                      onPressed: () => unawaited(_download(context, update)),
                      child: Text(AppStrings.actionDownload),
                    ),
                    TextButton(
                      key: const Key('update-available-dismiss'),
                      onPressed: session.clearPendingUpdate,
                      child: Text(AppStrings.updateLater),
                    ),
                  ],
          );
        },
      ),
    );
  }

  Future<void> _download(BuildContext context, UpdateAvailable update) async {
    if (await downloadAndApplyUpdate(context, update)) {
      session.clearPendingUpdate();
    }
  }
}
