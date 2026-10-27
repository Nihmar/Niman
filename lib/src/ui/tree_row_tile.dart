import 'package:flutter/gestures.dart' show kMiddleMouseButton;
import 'package:flutter/material.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/file_icon.dart';
import 'package:niman/src/ui/marquee_text.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/ocr/ocr_tree_ring.dart';
import 'package:niman/src/ui/tree_drag.dart';
import 'package:niman/src/ui/tree_rename_field.dart';
import 'package:niman/src/ui/tree_row_metrics.dart';
import 'package:niman/src/ui/tree_spring_load.dart';

/// A rename in place (#707): the row at `path` shows a field, which
/// renames through `submit` — null once done, or why the name cannot be —
/// or gives up through `cancel`.
typedef TreeRename = ({
  String path,
  Future<String?> Function(String name) submit,
  VoidCallback cancel,
});

/// One row tile: chevron (folders) or doc icon (files), then the name —
/// the name column is shared, per the mockup.
final class TreeRowTile extends StatelessWidget {
  /// A tile for [note], drawn [depth] levels in.
  const new({
    required this.note,
    required this.depth,
    required this.isExpanded,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
    this.focused = false,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.onMiddleClick,
    this.onMove,
    this.spring,
    this.dragPaths,
    this.icon,
    this.sidecar = false,
    this.ocrQueue,
    this.renaming,
    super.key,
  });

  /// The rename under way on this row, or null.
  final TreeRename? renaming;

  /// Whether the keyboard's cursor is on this row (#727): a ring of its
  /// own, apart from the selection's fill, as a grid tile's is.
  final bool focused;

  /// Moves this row by dragging it, and takes drops (#567).
  final TreeMove? onMove;

  /// Opens this row, if a closed folder, when a drag dwells on it (#1071).
  final TreeSpringLoad? spring;

  /// The paths this row's drag carries when it is dragged (#996): the
  /// marked rows' when this row is one of several, else null — the row's
  /// own path alone.
  final List<String>? dragPaths;

  /// A text recognition sidecar under its file: dimmed, with the scan's
  /// icon (#595).
  final bool sidecar;

  /// The recognition jobs, for the ring on a file being read.
  final OcrQueue? ocrQueue;

  /// The note or folder the row shows.
  final Note note;

  /// How many levels in the row sits.
  final int depth;

  /// Whether the folder's chevron is open.
  final bool isExpanded;

  /// Whether the row wears the selection's fill: the open note, or a row
  /// marked with others.
  final bool selected;

  /// Called with the row's note when it is clicked.
  final void Function(Note note) onSelect;

  /// Called with a folder's path when its chevron is clicked.
  final ValueChanged<String> onToggle;

  /// Called on a long press, with the row's place on screen.
  final void Function(Note note, Rect? anchor)? onLongPress;

  /// Called on a right click.
  final void Function(Note note, TapDownDetails details)? onSecondaryTapDown;

  /// A middle click on a note's row (not a folder's).
  final void Function(Note note)? onMiddleClick;

  /// Replaces the file-type icon; the pinned block uses it to say why the
  /// row is there.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = TreeRowMetrics.of(context);
    final middle = onMiddleClick;
    final move = onMove;
    final longPress = onLongPress == null
        ? null
        : () => onLongPress!(note, menuAnchorOf(context));
    // By touch the hold drags the row, and a hold that does not move is the
    // long press: the drag gives it back.
    final held = move != null && TreeRowDrag.holdToDrag;
    Widget row = InkWell(
      // The walk owns the keyboard here (#727): a row that took the focus
      // itself would leave the arrows to nobody — a key pressed with the
      // scope focused lands on the first focusable descendant, and that
      // would be a row rather than the pane's own node.
      canRequestFocus: false,
      onTap: () => onSelect(note),
      onLongPress: held ? null : longPress,
      onSecondaryTapDown: onSecondaryTapDown == null
          ? null
          : (details) => onSecondaryTapDown!(note, details),
      child: Container(
        // A field with something to say under it takes the room it needs.
        constraints: renaming == null
            ? BoxConstraints.tightFor(height: metrics.height)
            : BoxConstraints(minHeight: metrics.height),
        color: selected ? theme.highlightColor.withValues(alpha: 0.4) : null,
        // Over the child, and no part of its size: the rows keep the
        // height the list and the walk measured them at (#727).
        foregroundDecoration: focused
            ? BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              )
            : null,
        padding: EdgeInsets.only(left: depth * metrics.indent + 8),
        child: Row(
          children: [
            if (note.isDir)
              IconButton(
                // The chevron fills its slot and no more: the button's own
                // 48 px minimum, and its padded tap target, would widen a
                // pointer's row back out.
                constraints: BoxConstraints.tightFor(
                  width: metrics.leading,
                  height: metrics.height,
                ),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: metrics.chevronSize,
                ),
                onPressed: () => onToggle(note.path),
              )
            else
              SizedBox(
                width: metrics.leading,
                child: Icon(
                  icon ??
                      (sidecar
                          ? Icons.document_scanner_outlined
                          : fileIconFor(note.name)),
                  size: sidecar ? 14 : 16,
                  color: sidecar ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            Expanded(
              child: renaming != null
                  ? TreeRenameField(
                      // On disk: the file is what is renamed, whatever the
                      // row shows for its title.
                      name: note.name,
                      isDir: note.isDir,
                      // The row is as tall as every other: a name that
                      // cannot be used is said in a bubble under it.
                      floatingError: true,
                      style: theme.textTheme.bodyMedium,
                      onSubmit: renaming!.submit,
                      onCancel: renaming!.cancel,
                    )
                  : MarqueeText(
                      text: displayNameOf(note),
                      style: sidecar
                          ? theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : theme.textTheme.bodyMedium,
                    ),
            ),
            if (ocrQueue case final queue?
                when !note.isDir && isRecognizableFile(note.name))
              OcrTreeRing(queue: queue, path: note.path),
            if (note.date case final DateTime date)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: Text(
                  isoDate(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    // A row being renamed is not dragged: a drag in its field selects text.
    if (move != null && renaming == null) {
      row = TreeRowDrag(
        note: note,
        paths: dragPaths,
        onMove: move,
        spring: spring,
        onLongPress: longPress,
        child: row,
      );
    }
    if (middle == null || note.isDir) return row;
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kMiddleMouseButton) middle(note);
      },
      child: row,
    );
  }
}

/// What a note is called on screen: its frontmatter `title:` when it has
/// one, else its filename (T-M4-02).
///
/// The title is the note's own name for itself, so it wins wherever the
/// note is listed. The filename still decides the file on disk and still
/// resolves `[[links]]` — this changes what is shown, not what anything
/// points at.
String displayNameOf(Note note) {
  final title = note.title;
  return (title == null || title.isEmpty) ? note.name : title;
}

/// A frontmatter date as `YYYY-MM-DD` — the form it is written in.
String isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
