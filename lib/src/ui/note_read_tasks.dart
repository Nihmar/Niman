/// A task item ticked in the read pane, written into the note on the editor
/// surface (issue #100 moved it out of `note_view.dart`).
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/markdown/task_cascade.dart';
import 'package:niman/src/ui/note_read_snapshot.dart';

/// Ticks the read pane's task items through the editor's own door.
final class NoteReadTasks {
  /// Toggles on [surface], for the lines of [snapshot].
  const new({
    required this.surface,
    required this.snapshot,
    required this.blocks,
    required this.cascade,
    required this.onEdited,
  });

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// What the read pane shows of the note.
  final NoteReadSnapshot snapshot;

  /// The note's blocks as a pane on screen has them scanned, or null with
  /// neither scan in hand.
  final List<Block>? Function() blocks;

  /// Whether ticking a checklist item ticks the tasks nested under it
  /// (`NoteView.cascadeChecklist`, #326).
  final bool Function() cascade;

  /// The note took the edit: the read pane is shown it at once.
  final VoidCallback onEdited;

  /// Ticks or unticks the task item on [line] of the note the read pane is
  /// showing: an edit to the note itself, through the editor's own door —
  /// one undo step, saved like any other — and the pane shown the note as
  /// it now is at once, rather than when the preview's debounce comes round.
  ///
  /// Only when the pane shows the editor's note as it is: its lines are a
  /// snapshot, and a line number of an older one is not this note's.
  void toggle(int line) {
    final surface = this.surface();
    final from = surface == null ? null : snapshot.current(surface.buffer);
    if (surface == null || from == null || line >= from.lineCount) {
      return;
    }
    final text = from.lineAt(line);
    final box = taskBoxOffset(text);
    if (box == null) return;
    final ticked = text.codeUnitAt(box) != 0x20;
    if (!ticked && cascade()) {
      // The pane on screen has the note scanned; with neither scan in
      // hand the sweep waits and the one box still toggles.
      final blocks = this.blocks();
      final edit = blocks == null
          ? null
          : checklistTickEdit(
              buffer: from,
              blocks: blocks,
              line: line,
              ticked: true,
            );
      if (edit != null) {
        surface.replaceRange(
          edit.start,
          edit.end,
          edit.text,
          caret: surface.selection,
        );
        onEdited();
        return;
      }
    }
    final at = from.offsetOfLine(line) + box;
    surface.replaceRange(
      at,
      at + 1,
      ticked ? ' ' : 'x',
      caret: surface.selection,
    );
    onEdited();
  }
}
