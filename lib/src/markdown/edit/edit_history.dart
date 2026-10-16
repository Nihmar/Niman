// Undo and redo for the note the surface is editing (#245, phase 3).
//
// A history of *edits*, not of texts: each entry is a range, what was there,
// and what replaced it, which is exactly what an undo needs and what a redo
// needs turned around. Storing whole notes instead would be O(n) per keystroke
// and would make the 1M-note rule a lie in the one place a writer notices it.
//
// Rules the writer feels rather than reads:
//
// * **typing coalesces.** A keystroke per undo entry makes Ctrl+Z useless — no
//   one wants to un-type a sentence one letter at a time. Consecutive
//   insertions that are not separated by a caret move or a newline merge into
//   the step they continue.
// * **deleting coalesces** (#1046), in one direction: a held Backspace or
//   Delete is one step, not one per key repeat, which would also push the
//   writer's earlier work out of the bounded stack.
// * **the stack is bounded.** A note is a file, and a session is long: the
//   oldest entries go before the memory does. What is dropped is the *oldest*,
//   so undo reaches far enough back to matter and then stops, as every
//   editor's does.
//
// The step still being written lives in an [EditRun], built in O(size); it
// becomes a plain [EditRecord] once nothing can join it any more.
import 'package:niman/src/markdown/edit/edit_record.dart';
import 'package:niman/src/markdown/edit/edit_run.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

export 'package:niman/src/markdown/edit/edit_record.dart';

/// The edits that made the note what it is, and the way back.
final class EditHistory {
  /// Creates a history that keeps at most [limit] undo steps.
  new({this.limit = 200});

  /// How many undo steps are kept before the oldest is dropped.
  final int limit;

  final List<EditRecord> _done = <EditRecord>[];
  final List<EditRecord> _undone = <EditRecord>[];

  /// The last step, while the next edit may still join it.
  EditRun? _open;

  /// Whether there is anything to undo.
  bool get canUndo => _done.isNotEmpty || _open != null;

  /// Whether there is anything to redo.
  bool get canRedo => _undone.isNotEmpty;

  /// How many undo steps are held.
  int get length => _done.length + (_open == null ? 0 : 1);

  /// The buffer's own account of the last undo or redo, so the caller can
  /// follow it line by line instead of rebuilding what depends on the lines.
  SourceEdit? get lastEdit => _lastEdit;
  SourceEdit? _lastEdit;

  /// Ends the current step: the next edit is undone on its own even when it
  /// continues the last one (the caret moved away and came back — typing
  /// there again is a new thought).
  void seal() => _close();

  /// Records an edit that has already been applied to the buffer.
  ///
  /// [EditRecord.inserted] must be what the buffer *stored*, which is not
  /// always what was typed: a line break is stored as the note's own line
  /// ending. An undo removes `inserted.length` code units, so a record of the
  /// typed text instead deleted one character too many per line break.
  void record(EditRecord record) {
    if (record.removed.isEmpty && record.inserted.isEmpty) return;
    // A new edit is a new branch: whatever was undone is no longer reachable.
    _undone.clear();
    final open = _open;
    if (open != null && open.accepts(record)) {
      open.add(record);
      return;
    }
    _close();
    _open = EditRun(record);
    _trim();
  }

  /// Moves the open step to the stack of closed ones.
  void _close() {
    final open = _open;
    if (open == null) return;
    _open = null;
    _done.add(open.finish());
  }

  /// Drops the oldest steps beyond [limit].
  void _trim() {
    while (length > limit && _done.isNotEmpty) {
      _done.removeAt(0);
    }
  }

  /// Undoes the last edit on [buffer], returning what it did, or null when
  /// there is nothing to undo.
  EditRecord? undo(SourceBuffer buffer) {
    _close();
    if (_done.isEmpty) return null;
    final last = _done.removeLast();
    _lastEdit = buffer.replaceRange(
      last.start,
      last.end,
      last.removed,
      verbatim: true,
    );
    _undone.add(last);
    return last;
  }

  /// Redoes the last undone edit on [buffer], or null when there is nothing.
  EditRecord? redo(SourceBuffer buffer) {
    if (_undone.isEmpty) return null;
    _close();
    final next = _undone.removeLast();
    _lastEdit = buffer.replaceRange(
      next.start,
      next.start + next.removed.length,
      next.inserted,
      verbatim: true,
    );
    _done.add(next);
    return next;
  }

  /// Forgets everything (a note was reloaded from disk, and its history with
  /// it).
  void clear() {
    _done.clear();
    _undone.clear();
    _open = null;
  }
}
