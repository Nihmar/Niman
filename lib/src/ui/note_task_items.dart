/// The checkbox items of the note on the editor surface, as Move to tasks
/// reads and edits them (#1152).
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/task_items.dart';
import 'package:niman/src/editor/task_items_edit.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/surface_controller.dart';

/// Reads the items under the selection and takes them out of the note, or
/// puts them back, through the surface's own door: one undoable edit that the
/// editor saves like any other.
final class NoteTaskItems {
  /// Items of the note [surface] holds, scanned by [sourceView]'s blocks when
  /// that pane draws the same buffer. [canInsert] says whether the note takes
  /// an edit at all; [focus] gives the editor the keyboard back.
  const new({
    required this.surface,
    required this.sourceView,
    required this.canInsert,
    required this.focus,
  });

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// The source pane's state, when it is built.
  final MarkdownSourceViewState? Function() sourceView;

  /// Whether the note takes an edit from outside the editor.
  final bool Function() canInsert;

  /// Gives the editor the focus back.
  final VoidCallback focus;

  /// How many lines of a selection [availability] looks at: a menu asks on
  /// opening, and a select-all over a huge note is not a reason to read it.
  static const int _askReach = 5000;

  Block? Function(int line)? _blockAt() {
    final buffer = surface()?.buffer;
    final view = sourceView();
    return buffer != null && identical(view?.widget.buffer, buffer)
        ? view?.blockAt
        : null;
  }

  /// The items the selection touches (the caret's own, when it is collapsed),
  /// each with whether it can be moved.
  List<TaskItem> selected() => _read(untilMovable: false, reach: null);

  /// What Move to tasks can do now, read without walking a long selection.
  MoveAvailability availability() =>
      MoveAvailability.of(_read(untilMovable: true, reach: _askReach));

  List<TaskItem> _read({required bool untilMovable, required int? reach}) {
    final surface = this.surface();
    if (surface == null || !canInsert()) return const <TaskItem>[];
    final buffer = surface.buffer;
    final at = surface.selection.clampTo(buffer.length);
    final first = buffer.lineOf(at.start);
    var last = buffer.lineOf(at.end);
    // A selection that stops at the start of a line does not cover it.
    if (!at.isCollapsed &&
        last > first &&
        at.end == buffer.offsetOfLine(last)) {
      last--;
    }
    if (reach != null && last - first > reach) last = first + reach;
    return taskItemsIn(
      buffer: buffer,
      first: first,
      last: last,
      blockAt: _blockAt(),
      untilMovable: untilMovable,
    );
  }

  /// Takes [items] out of the note as one edit, and answers what was taken —
  /// null when the note no longer holds any of them where they were.
  TakenTaskItems? takeOut(List<TaskItem> items) {
    final surface = this.surface();
    if (surface == null || !canInsert()) return null;
    final plan = takeOutTaskItems(surface.buffer, items);
    if (plan == null) return null;
    final edit = plan.edit;
    surface.replaceRange(
      edit.start,
      edit.end,
      edit.text,
      caret: SelectionModel.at(edit.start),
      follow: false,
    );
    focus();
    return plan.taken;
  }

  /// Puts [taken] back, as one edit, where the lines stood or the nearest
  /// place there is; false when the note is not there to take them.
  bool putBack(TakenTaskItems taken) {
    final surface = this.surface();
    if (surface == null || !canInsert()) return false;
    final buffer = surface.buffer;
    final edit = restoreTaskItems(
      buffer,
      taken,
      _blockAt() ?? BlockScanner(buffer).blockAt,
    );
    if (edit == null) return false;
    surface.replaceRange(
      edit.start,
      edit.end,
      edit.text,
      caret: SelectionModel.at(edit.start),
      follow: false,
    );
    focus();
    return true;
  }
}
