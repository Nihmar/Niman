/// The Home's random note tile (#535): one note picked at random, to
/// reread, and another one on request.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/home/home_tile_loader.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// A note picked at random.
final class RandomNoteTile extends StatefulWidget {
  /// The tile over [host]'s library, picking again on [revision].
  const new({required this.host, required this.revision, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// The Home's revision.
  final int revision;

  @override
  State<RandomNoteTile> createState() => _RandomNoteTileState();
}

final class _RandomNoteTileState extends State<RandomNoteTile> {
  /// Bumped by *Another one*, on top of the Home's revision.
  int _picks = 0;

  Future<Note?> _load() async {
    final ops = widget.host.controller.ops;
    if (ops == null) return null;
    return await ops.randomNote(excludeFolder: await ops.templateFolder);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HomeTileLoader<Note?>(
      revision: widget.revision * 1000 + _picks,
      load: _load,
      builder: (context, note) {
        if (note == null) return HomeTileEmpty(AppStrings.homeNotesEmpty);
        final folder = p.dirname(note.path);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                key: const Key('home-random-open'),
                borderRadius: BorderRadius.circular(6),
                onTap: () => widget.host.openNote(note.path),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title ?? p.basenameWithoutExtension(note.name),
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (folder != '.')
                      Text(
                        folder,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              key: const Key('home-random-another'),
              tooltip: AppStrings.homeRandomAnother,
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _picks++),
              icon: const Icon(Icons.refresh, size: 18),
            ),
          ],
        );
      },
    );
  }
}
