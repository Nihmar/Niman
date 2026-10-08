/// The rows of notes a Home tile lists (#535): the recently modified, the
/// pinned, a saved search's results.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:path/path.dart' as p;

/// One row: the note's path, what it is called, and a short text at the
/// row's end (when it was modified) or null.
typedef HomeNoteRow = ({String path, String title, String? end});

/// [note] as a row, its frontmatter title or else its file name.
HomeNoteRow homeNoteRow(Note note, {String? end}) => (
  path: note.path,
  title: note.title ?? p.basenameWithoutExtension(note.name),
  end: end,
);

/// Notes, one row each, as many as the tile's height holds.
final class HomeNoteList extends StatelessWidget {
  /// Lists [rows]; a tap opens one through [onOpen]. [empty] is what
  /// shows when there is none.
  const new({
    required this.rows,
    required this.onOpen,
    required this.empty,
    this.icon = Icons.description_outlined,
    super.key,
  });

  /// The notes, in order.
  final List<HomeNoteRow> rows;

  /// Opens a note by path.
  final void Function(String path) onOpen;

  /// What the tile says with no note.
  final String empty;

  /// The rows' icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return HomeTileEmpty(empty);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Not scrollable: a tile shows what its height holds, and a scroll
    // inside the phone's scrolling column would fight it.
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final row in rows)
          InkWell(
            key: Key('home-note-${row.path}'),
            borderRadius: BorderRadius.circular(6),
            onTap: () => onOpen(row.path),
            child: SizedBox(
              height: 32,
              child: Row(
                children: [
                  Icon(icon, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (row.end case final text?) ...[
                    const SizedBox(width: 8),
                    Text(text, style: muted),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
