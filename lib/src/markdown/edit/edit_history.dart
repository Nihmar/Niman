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
//   the step they continue — until the writer pauses for about a second
//   (#1053), or starts a word after a space, so undo takes a recent word back
//   rather than a paragraph. A bracket pair the editor wrote is part of the
//   step typed inside it, and typing over its closer does not end the step.
// * **deleting coalesces** (#1046), in one direction: a held Backspace or
//   Delete is one step, not one per key repeat, which would also push the
//   writer's earlier work out of the bounded stack.
// * **the stack is bounded**, in steps and in text (#1050). A note is a file,
//   and a session is long: the oldest entries go before the memory does. What
//   is dropped is the *oldest*, so undo reaches far enough back to matter and
//   then stops, as every editor's does. The newest step is never dropped, big
//   as it is: undoing the edit just made is what the stack is for.
//
// The step still being written lives in an [EditRun], built in O(size); once
// nothing can join it it becomes an [EditStep], which keeps only the lines an
// edit over a long span changed.
import 'package:niman/src/markdown/edit/edit_record.dart';
import 'package:niman/src/markdown/edit/edit_run.dart';
import 'package:niman/src/markdown/edit/edit_step.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

export 'package:niman/src/markdown/edit/edit_record.dart';

/// The edits that made the note what it is, and the way back.
final class EditHistory {
  /// Creates a history that keeps at most [limit] undo steps, and as many of
  /// them as fit in [budget] code units of text.
  ///
  /// A step ends when the writer stops for longer than [pause]. [clock] says
  /// how long the history has been alive, and must be monotonic: a test gives
  /// its own and moves it by hand; the default is a stopwatch.
  new({
    this.limit = 200,
    this.budget = defaultBudget,
    this.pause = const Duration(seconds: 1),
    Duration Function()? clock,
  }) : _clock = clock ?? _stopwatchClock;

  /// The text a history keeps by default: 16 M code units, 32 MB of UTF-16.
  static const int defaultBudget = 16 * 1024 * 1024;

  /// How many undo steps are kept before the oldest is dropped.
  final int limit;

  /// How many code units of text the undo steps keep, removed and inserted
  /// together, before the oldest are dropped.
  final int budget;

  /// How long a writer may stop before the next edit is a step of its own.
  final Duration pause;

  final Duration Function() _clock;

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static Duration _stopwatchClock() => _stopwatch.elapsed;

  /// When the last edit was recorded, on [_clock].
  Duration _lastEditAt = Duration.zero;

  final List<EditStep> _done = <EditStep>[];
  final List<EditStep> _undone = <EditStep>[];

  /// What the closed undo steps hold, in code units.
  int _doneUnits = 0;

  /// The last step, while the next edit may still join it.
  EditRun? _open;

  /// Whether there is anything to undo.
  bool get canUndo => _done.isNotEmpty || _open != null;

  /// Whether there is anything to redo.
  bool get canRedo => _undone.isNotEmpty;

  /// How many undo steps are held.
  int get length => _done.length + (_open == null ? 0 : 1);

  /// How many code units of text the undo steps hold.
  int get units => _doneUnits + (_open?.units ?? 0);

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
  ///
  /// The last [closing] characters of [EditRecord.inserted] are closers the
  /// editor wrote ahead of the caret — the `)` of a `(` typed — and what is
  /// typed inside the pair goes on the step that wrote it (#1053).
  void record(EditRecord record, {int closing = 0}) {
    if (record.removed.isEmpty && record.inserted.isEmpty) return;
    // A new edit is a new branch: whatever was undone is no longer reachable.
    _undone.clear();
    final now = _clock();
    final paused = now - _lastEditAt > pause;
    _lastEditAt = now;
    final open = _open;
    if (open != null && !paused && open.accepts(record)) {
      open.add(record, closing: closing);
    } else {
      _close();
      final run = EditRun(record, closing: closing);
      if (run.isComplete) {
        // Nothing will join it, so it is kept as it will stay — in hunks, for
        // an edit over a long span — and the span's text is not held on.
        _push(EditStep.of(record));
      } else {
        _open = run;
      }
    }
    _trim();
  }

  /// The caret stepped over a closer the open step wrote, to [caret]: typing
  /// goes on in the same step. Any other caret move ends it ([seal]).
  void stepOver(int caret) {
    final open = _open;
    if (open != null && open.stepOver(caret)) {
      _lastEditAt = _clock();
      return;
    }
    _close();
  }

  /// Moves the open step to the stack of closed ones.
  void _close() {
    final open = _open;
    if (open == null) return;
    _open = null;
    _push(EditStep.of(open.finish()));
  }

  void _push(EditStep step) {
    _done.add(step);
    _doneUnits += step.units;
  }

  /// Drops the oldest steps beyond [limit] and [budget], never the newest.
  void _trim() {
    // The open step is the newest when there is one; otherwise the last
    // closed step is.
    final keep = _open == null ? 1 : 0;
    while (_done.length > keep &&
        (length > limit || _doneUnits + (_open?.units ?? 0) > budget)) {
      _doneUnits -= _done.removeAt(0).units;
    }
  }

  /// Undoes the last step on [buffer], returning where the caret goes, or
  /// null when there is nothing to undo.
  int? undo(SourceBuffer buffer) {
    _close();
    if (_done.isEmpty) return null;
    final last = _done.removeLast();
    _doneUnits -= last.units;
    final move = last.undo(buffer);
    _lastEdit = move.edit;
    _undone.add(last);
    return move.caret;
  }

  /// Redoes the last undone step on [buffer], returning where the caret goes,
  /// or null when there is nothing.
  int? redo(SourceBuffer buffer) {
    if (_undone.isEmpty) return null;
    _close();
    final next = _undone.removeLast();
    final move = next.redo(buffer);
    _lastEdit = move.edit;
    _push(next);
    return move.caret;
  }

  /// Forgets everything (a note was reloaded from disk, and its history with
  /// it).
  void clear() {
    _done.clear();
    _undone.clear();
    _doneUnits = 0;
    _open = null;
  }
}
