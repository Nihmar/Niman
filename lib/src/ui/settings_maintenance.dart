import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/switch_library_screen.dart';

/// The Maintenance group of the settings home (issue #104): the actions
/// that are not settings — reindexing, switching and closing the
/// library — sitting together under their own heading instead of
/// scattered among the settings as though they were ones.
final class SettingsMaintenanceGroup extends StatelessWidget {
  /// Creates the group for [controller]'s library session.
  const new({required this.controller, this.onClosed, super.key});

  /// The session the actions act on.
  final LibrarySession controller;

  /// Fired when the library closes or switches; the shell leaves the
  /// settings behind with it.
  final VoidCallback? onClosed;

  /// Re-reads every note from disk into the index.
  Future<void> _rescan(BuildContext context) async {
    try {
      await controller.rescanNow();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppStrings.reindexDone)));
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  /// Opens the known-library list and switches to whatever is picked
  /// (T-ML-06).
  ///
  /// The switch tears down the shell this group is part of, so `onClosed`
  /// is the same exit "Close library" takes.
  Future<void> _switchLibrary(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SwitchLibraryScreen(
          controller: controller,
          onSwitched: () {
            Navigator.of(context).pop();
            onClosed?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            AppStrings.settingsGroupMaintenance,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          key: const Key('reindex-setting'),
          leading: const Icon(Icons.refresh_outlined),
          title: Text(AppStrings.reindexTitle),
          onTap: () => _rescan(context),
        ),
        // Above "Close library" on purpose: switching is the common
        // move and closing is the way out of every library at once.
        ListTile(
          key: const Key('switch-library-setting'),
          leading: const Icon(Icons.swap_horiz_outlined),
          title: Text(AppStrings.switchLibraryTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _switchLibrary(context),
        ),
        ListTile(
          key: const Key('close-library-setting'),
          leading: const Icon(Icons.link_off_outlined),
          title: Text(AppStrings.closeLibraryTitle),
          onTap: () async {
            await controller.close();
            onClosed?.call();
          },
        ),
      ],
    );
  }
}
