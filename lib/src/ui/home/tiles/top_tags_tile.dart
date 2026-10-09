/// The Home's top tags tile (#535): the tags most used, each a way into
/// its notes.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/search/tag_repo.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/home/home_tile_loader.dart';
import 'package:niman/src/ui/strings.dart';

/// The tags most used.
final class TopTagsTile extends StatelessWidget {
  /// The tile over [host]'s library, reloaded on [revision].
  const new({required this.host, required this.revision, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// The Home's revision.
  final int revision;

  /// How many tags it shows.
  static const int limit = 12;

  Future<List<TagCount>> _load() async {
    final counts = await (await host.controller.tagSource)?.tagCounts();
    return (counts ?? const <TagCount>[]).take(limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return HomeTileLoader<List<TagCount>>(
      revision: revision,
      load: _load,
      builder: (context, tags) {
        if (tags.isEmpty) return HomeTileEmpty(AppStrings.homeTagsEmpty);
        return ClipRect(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in tags)
                ActionChip(
                  key: Key('home-tag-${tag.name}'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => host.openTag(tag.name),
                  label: Text.rich(
                    TextSpan(
                      text: '#${tag.name} ',
                      children: [TextSpan(text: '${tag.count}', style: count)],
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
