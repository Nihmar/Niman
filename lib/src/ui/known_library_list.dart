import 'package:copist/src/db/app_database.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The libraries the app knows about, on the home screen (T-ML-05).
///
/// Each row shows the name, the path and when it was last opened. The
/// path is not decoration: two libraries can both be called `Notes`, one
/// on the device and one on a card, and it is the only thing that tells
/// those two rows apart.
///
/// A long press offers to forget one (T-ML-07); a swipe would fire by
/// accident on a list this short.
final class KnownLibraryList extends StatelessWidget {
  /// Creates the list.
  const new({
    required this.entries,
    required this.unreachable,
    required this.onOpen,
    required this.onForget,
    this.enabled = true,
    super.key,
  });

  /// The known libraries, most recently opened first.
  final List<KnownLibrary> entries;

  /// The paths whose folder is not there right now (an unplugged drive,
  /// a card that was removed). Their rows say so instead of opening onto
  /// an empty tree.
  final Set<String> unreachable;

  /// Opens the library at the tapped path.
  final void Function(String libraryPath) onOpen;

  /// Forgets the library at the long-pressed path, already confirmed.
  final void Function(String libraryPath) onForget;

  /// False while an open or a picker is in flight.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            AppStrings.knownLibrariesTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        for (final entry in entries)
          _KnownLibraryTile(
            entry: entry,
            reachable: !unreachable.contains(entry.path),
            enabled: enabled,
            onOpen: () => onOpen(entry.path),
            onForget: () => _confirmForget(context, entry),
          ),
      ],
    );
  }

  /// Asks before forgetting, and says what forgetting does and does not
  /// touch — the word invites the reading that it deletes the notes.
  Future<void> _confirmForget(BuildContext context, KnownLibrary entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.libraryForgetTitle(entry.name)),
        content: Text(AppStrings.libraryForgetExplained),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: const Key('confirm-forget-library'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.libraryForget),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onForget(entry.path);
  }
}

/// One row of [KnownLibraryList].
final class _KnownLibraryTile extends StatelessWidget {
  const new({
    required this.entry,
    required this.reachable,
    required this.enabled,
    required this.onOpen,
    required this.onForget,
  });

  final KnownLibrary entry;
  final bool reachable;
  final bool enabled;
  final VoidCallback onOpen;
  final Future<void> Function() onForget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: Key('known-library-${entry.path}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        reachable ? Icons.folder_outlined : Icons.folder_off_outlined,
        color: reachable ? null : theme.colorScheme.error,
      ),
      title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            reachable
                ? _lastOpened(entry.lastOpened)
                : AppStrings.libraryUnreachable,
            style: theme.textTheme.bodySmall?.copyWith(
              color: reachable ? null : theme.colorScheme.error,
            ),
          ),
        ],
      ),
      // An unreachable folder still opens on a tap: the drive may be back
      // by now, and the open path already reports what went wrong.
      onTap: enabled ? onOpen : null,
      onLongPress: enabled ? onForget.call : null,
    );
  }

  /// When it was last opened, in the words a person would use for a
  /// recent date and as a date for an old one.
  static String _lastOpened(DateTime when) {
    final today = DateTime.now();
    final days = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(when.year, when.month, when.day)).inDays;
    if (days <= 0) return AppStrings.libraryOpenedToday;
    if (days == 1) return AppStrings.libraryOpenedYesterday;
    if (days < 7) return AppStrings.libraryOpenedDaysAgo(days);
    return AppStrings.libraryOpenedOn(when);
  }
}
