/// The Home's journal tile (#535): today's entry, its first lines, or a
/// way to write it.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/home/note_preview.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/home/home_tile_loader.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/strings.dart';

/// What the tile found: the journal's day, and the entry when there is one.
typedef _Today = ({DateTime day, String? path, String preview});

/// Today's journal entry.
final class JournalTodayTile extends StatelessWidget {
  /// The tile over [host]'s journal, reloaded on [revision].
  const new({required this.host, required this.revision, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// The Home's revision.
  final int revision;

  Future<_Today?> _load() async {
    final ops = host.controller.ops;
    final root = host.controller.root;
    final day = await host.journal.today();
    if (ops == null || root == null || day == null) return null;
    final path = (await ops.journal).entryPath(day);
    if (await ops.find(path) == null) {
      return (day: day, path: null, preview: '');
    }
    return (day: day, path: path, preview: await notePreview(root, path));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HomeTileLoader<_Today?>(
      revision: revision,
      load: _load,
      builder: (context, today) {
        if (today == null) return const SizedBox.shrink();
        final date = Text(
          journalDayLabel(today.day),
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
        final path = today.path;
        if (path == null) {
          // Clipped rather than squeezed: a tile made short cuts the
          // button off instead of overflowing.
          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                date,
                const SizedBox(height: 4),
                HomeTileEmpty(AppStrings.homeJournalEmpty),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  key: const Key('home-journal-write'),
                  onPressed: () => unawaited(host.journal.openToday(context)),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(AppStrings.homeJournalWrite),
                ),
              ],
            ),
          );
        }
        return InkWell(
          key: const Key('home-journal-open'),
          borderRadius: BorderRadius.circular(6),
          onTap: () => host.openNote(path),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              date,
              const SizedBox(height: 4),
              Expanded(
                child: ClipRect(
                  child: Text(
                    today.preview,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.fade,
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
