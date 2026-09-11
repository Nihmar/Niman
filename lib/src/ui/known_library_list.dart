import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/strings.dart';

/// What the known-library list needs to draw itself: the entries, and
/// which of their folders are not there right now.
typedef KnownLibraries = ({List<KnownLibrary> entries, Set<String> missing});

/// Reads the known libraries and checks which folders still exist.
///
/// The check is a stat per row, not a walk: the list is a handful of
/// entries, and the alternative is a row that opens onto an empty tree
/// because its drive is unplugged.
Future<KnownLibraries> loadKnownLibraries(LibrarySession session) async {
  final entries = await session.knownLibraries();
  final missing = <String>{};
  for (final entry in entries) {
    // Sync on purpose: `exists()` spawns an isolate per call, which costs
    // more than the stat it avoids for a list this short.
    if (!Directory(entry.path).existsSync()) missing.add(entry.path);
  }
  return (entries: entries, missing: missing);
}

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
    this.currentPath,
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

  /// The library open right now, marked as such and not offered for
  /// forgetting — an app cannot stop listing the library it is showing.
  /// Null on the home screen, where nothing is open.
  final String? currentPath;

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
            isCurrent: entry.path == currentPath,
            onOpen: () => onOpen(entry.path),
            onForget: entry.path == currentPath
                ? null
                : () => _confirmForget(context, entry),
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
    required this.isCurrent,
    required this.onOpen,
    required this.onForget,
  });

  final KnownLibrary entry;
  final bool reachable;
  final bool enabled;
  final bool isCurrent;
  final VoidCallback onOpen;

  /// Null for the open library, which cannot be forgotten.
  final Future<void> Function()? onForget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: Key('known-library-${entry.path}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      selected: isCurrent,
      leading: Icon(switch ((isCurrent, reachable)) {
        (true, _) => Icons.folder_open,
        (false, true) => Icons.folder_outlined,
        (false, false) => Icons.folder_off_outlined,
      }, color: reachable ? null : theme.colorScheme.error),
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
            switch ((isCurrent, reachable)) {
              (true, _) => AppStrings.libraryOpenNow,
              (false, true) => _lastOpened(entry.lastOpened),
              (false, false) => AppStrings.libraryUnreachable,
            },
            style: theme.textTheme.bodySmall?.copyWith(
              color: reachable ? null : theme.colorScheme.error,
            ),
          ),
        ],
      ),
      // An unreachable folder still opens on a tap: the drive may be back
      // by now, and the open path already reports what went wrong.
      onTap: enabled ? onOpen : null,
      onLongPress: enabled ? onForget?.call : null,
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
