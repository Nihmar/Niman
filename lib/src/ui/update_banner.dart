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

/// A banner over the shell offering the pending update, if any.
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
    return MaterialBanner(
      key: const Key('update-available-banner'),
      leading: Icon(Icons.system_update, color: scheme.primary),
      content: Text(AppStrings.updateAvailableMessage(update.version)),
      actions: [
        TextButton(
          key: const Key('update-available-download'),
          onPressed: () => unawaited(
            downloadAndApplyUpdate(
              context,
              update,
            ).then((_) => session.clearPendingUpdate()),
          ),
          child: Text(AppStrings.checkForUpdatesTitle),
        ),
        TextButton(
          key: const Key('update-available-dismiss'),
          onPressed: session.clearPendingUpdate,
          child: Text(AppStrings.actionCancel),
        ),
      ],
    );
  }
}
