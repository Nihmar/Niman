import 'package:flutter/material.dart';
import 'package:niman/src/library/indexing_status.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/strings.dart';

/// The line Search, Tags and a note's links show while the library's notes
/// are still being read into the index (#1068): what they list may be
/// partial, and nothing else says so. Nothing while the index is complete.
final class IndexingNotice extends StatelessWidget {
  /// Creates the notice.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: IndexingStatus.contentOwed,
      builder: (context, owed, _) {
        if (!owed) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final style = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
        return Padding(
          key: const Key('indexing-notice'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(AppStrings.indexingPartial, style: style)),
            ],
          ),
        );
      },
    );
  }
}

/// The tree footer's line while the notes are being read: "Indexing… 412 of
/// 10000 notes" (#1068). It sits above the footer's buttons, so they stay
/// where they are when it comes and goes.
final class IndexingFooterLine extends StatelessWidget {
  /// Creates the line for [controller]'s index pass.
  const new({required this.controller, super.key});

  /// The session whose [LibrarySession.indexProgress] it shows.
  final LibrarySession controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: controller.events,
      builder: (context, _) {
        final progress = controller.indexProgress;
        if (progress == null) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Padding(
          key: const Key('indexing-footer'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.indexingTitle} '
                  '${AppStrings.indexingCount(progress.done, progress.of)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
