/// One tile of the folder grid (#727): its icon, its name and its date,
/// its pin, and the ways it is opened, dragged and dropped on.
library;

import 'package:flutter/gestures.dart' show kMiddleMouseButton;
import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/file_icon.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/ocr/ocr_tree_ring.dart';
import 'package:niman/src/ui/tree.dart' show displayNameOf, isoDate;
import 'package:niman/src/ui/tree_drag.dart';

/// A tile of the folder grid.
final class FolderGridTile extends StatelessWidget {
  /// Creates the tile of [note].
  const new({
    required this.note,
    required this.sidecar,
    required this.selected,
    required this.focused,
    required this.sort,
    required this.onTap,
    this.ocrQueue,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.onMiddleClick,
    this.onMove,
    this.renaming = false,
    super.key,
  });

  /// The note or folder the tile draws.
  final Note note;

  /// Whether it is an OCR sidecar following its file: drawn dimmed, with
  /// the scanner icon.
  final bool sidecar;

  /// Whether it is the note open in the pane.
  final bool selected;

  /// Whether the keyboard's ring is on it.
  final bool focused;

  /// The folder's order: the date drawn is the field it is sorted by.
  final TreeSort sort;

  /// A tap: the grid opens the note or enters the folder.
  final VoidCallback onTap;

  /// The text recognition jobs: a file being read wears a ring (#595).
  final OcrQueue? ocrQueue;

  /// A long press, with the tile's place for a pointer's menu to grow
  /// from: the row menu.
  final void Function(Rect? anchor)? onLongPress;

  /// A right click: the desktop's menu at the cursor.
  final GestureTapDownCallback? onSecondaryTapDown;

  /// A middle click on a note: the note in a tab of its own.
  final VoidCallback? onMiddleClick;

  /// Moves a dragged tile (#567); null leaves the tile where it is.
  final TreeMove? onMove;

  /// Whether its name is being edited in place: a drag in the field
  /// selects text, so the tile is not dragged then.
  final bool renaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final longPress = switch (onLongPress) {
      final press? => () => press(menuAnchorOf(context)),
      null => null,
    };
    final date = sort.order == TreeOrder.created ? note.created : note.modified;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: sidecar ? 12 : 12.5,
      height: 16 / 12.5,
      color: sidecar ? theme.colorScheme.onSurfaceVariant : null,
    );
    Widget icon = Icon(
      sidecar
          ? Icons.document_scanner_outlined
          : (note.isDir ? Icons.folder_outlined : fileIconFor(note.name)),
      size: sidecar ? 24 : 32,
      color: sidecar ? theme.colorScheme.onSurfaceVariant : null,
    );
    final queue = ocrQueue;
    if (queue != null && !note.isDir && isRecognizableFile(note.name)) {
      icon = OcrTreeRing(queue: queue, path: note.path, placeholder: icon);
    }
    Widget tile = InkWell(
      key: Key('grid-tile-${note.path}'),
      // The walk owns the keyboard here (#727), as in the tree: a tile
      // that took the focus itself would leave the arrows to nobody.
      canRequestFocus: false,
      onTap: onTap,
      onLongPress: TreeRowDrag.holdToDrag ? null : longPress,
      onSecondaryTapDown: onSecondaryTapDown,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? theme.highlightColor.withValues(alpha: 0.4) : null,
          border: focused
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 7),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 32, child: Center(child: icon)),
                const SizedBox(height: 5),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      displayNameOf(note),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ),
                ),
                Text(
                  isoDate(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (note.pinned && !note.isDir)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.push_pin, size: 13),
              ),
          ],
        ),
      ),
    );
    final move = onMove;
    if (move != null && !renaming) {
      tile = TreeRowDrag(
        note: note,
        onMove: move,
        onLongPress: longPress,
        child: tile,
      );
    }
    final middle = onMiddleClick;
    if (middle == null || note.isDir) return tile;
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kMiddleMouseButton) middle();
      },
      child: tile,
    );
  }
}
