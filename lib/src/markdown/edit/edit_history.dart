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
// * **an undo puts back the selection** (#1338): each step keeps the selection
//   before it and after it, so undoing a bold selects the word again and
//   undoing a forward Delete leaves the caret where it was.
// * **the history knows where the disk is** (#1358): [position] names a place
//   in it, the save pipeline keeps the one the file holds, and a note undone
//   back to that place is the saved text, whatever the revision says.
//
// The step still being written lives in an [EditRun], built in O(size); once
// nothing can join it it becomes an [EditStep], which keeps only the lines an
// edit over a long span changed.
import 'package:flutter/foundation.dart';
import 'package:niman/src/markdown/edit/edit_record.dart';
import 'package:niman/src/markdown/edit/edit_run.dart';
import 'package:niman/src/markdown/edit/edit_step.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

export 'package:niman/src/markdown/edit/edit_record.dart';

/// Where an [EditHistory] stands: equal to an earlier position exactly when
/// the note says what it said then.
typedef HistoryPosition = (int, int, int, int);

/// A closed step, and the place the history stood in once it was done.
typedef _Entry = ({EditStep step, int serial, int version});

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

  final List<_Entry> _done = <_Entry>[];
  final List<_Entry> _undone = <_Entry>[];

  /// A number for every step made, so a position can name it; the open step
  /// has one too, and a version that moves with every edit it takes in.
  int _serial = 0;
  int _openSerial = 0;
  int _openVersion = 0;

  /// How many steps the bound has dropped from the bottom: the history empty
  /// is not the note as it was opened once any were.
  int _trimmed = 0;

  /// How many times the history was cleared: a position from before is gone.
  int _epoch = 0;

  /// What the closed undo steps hold, in code units.
  int _doneUnits = 0;

  /// The last step, while the next edit may still join it.
  EditRun? _open;

  /// Whether there is anything to undo.
  bool get canUndo => _done.isNotEmpty || _open != null;

  /// Whether there is anything to redo.
  bool get canRedo => _undone.isNotEmpty;

  /// Whether there is anything to undo and to redo, as a value that tells
  /// when either changes — not on every keystroke — for the toolbar's undo
  /// and redo buttons (#1336).
  ValueListenable<(bool, bool)> get availability => _availability;
  final ValueNotifier<(bool, bool)> _availability = ValueNotifier((
    false,
    false,
  ));

  void _publish() => _availability.value = (canUndo, canRedo);

  /// How many undo steps are held.
  int get length => _done.length + (_open == null ? 0 : 1);

  /// How many code units of text the undo steps hold.
  int get units => _doneUnits + (_open?.units ?? 0);

  /// Where the history stands now. The open step counts with what it holds,
  /// so typing on after a position was taken is another position.
  HistoryPosition get position {
    if (_open != null) return (_epoch, _openSerial, _openVersion, 0);
    if (_done.isEmpty) return (_epoch, 0, 0, _trimmed);
    final top = _done.last;
    return (_epoch, top.serial, top.version, 0);
  }

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
  ///
  /// An [alone] edit is a step of its own whatever stands next to it: a paste,
  /// a cut or a command's edit is a decision, not a keystroke the typing
  /// before or after it may join (#1339).
  void record(EditRecord record, {int closing = 0, bool alone = false}) {
    if (record.removedLength == 0 && record.inserted.isEmpty) return;
    // A new edit is a new branch: whatever was undone is no longer reachable.
    _undone.clear();
    final now = _clock();
    final paused = now - _lastEditAt > pause;
    _lastEditAt = now;
    if (alone) {
      _close();
      _push(EditStep.of(record));
    } else {
      _record(record, closing: closing, paused: paused);
    }
    _trim();
    _publish();
  }

  /// Takes [record] into the open step when it goes on with it, or starts
  /// the next one.
  void _record(
    EditRecord record, {
    required int closing,
    required bool paused,
  }) {
    final open = _open;
    if (open != null && !paused) {
      if (open.absorbs(record)) {
        // An IME's update to the text it is composing (#1337).
        open.absorb(record);
        _openVersion++;
        if (open.isEmpty) _open = null;
        return;
      }
      if (open.accepts(record)) {
        open.add(record, closing: closing);
        _openVersion++;
        return;
      }
    }
    _close();
    final run = EditRun(record, closing: closing);
    if (run.isComplete) {
      // Nothing will join it, so it is kept as it will stay — in hunks, for
      // an edit over a long span — and the span's text is not held on.
      _push(EditStep.of(record));
    } else {
      _open = run;
      _openSerial = ++_serial;
      _openVersion = 0;
    }
  }

  /// How many code units the steps keep as the note's own chunks rather than
  /// as strings ([HeldText]), for a test.
  @visibleForTesting
  int get heldUnits {
    var total = 0;
    for (final entry in _done) {
      for (final hunk in entry.step.hunks) {
        if (hunk.held != null) total += hunk.held!.length;
      }
    }
    return total;
  }

  /// Whether the last step is one edit that put [text] at [start] and nothing
  /// has been done since: what undoing it takes away is exactly that.
  bool lastStepInserted(int start, String text) {
    if (_open != null || _done.isEmpty) return false;
    final step = _done.last.step;
    return step.start == start &&
        step.hunks.length == 1 &&
        step.hunks.first.inserted == text;
  }

  /// Records a step the caller built, one that changed `hunks` of a long span
  /// ([EditStep]): kept as it is, with nothing read to find what changed
  /// (#1359). A step of its own, like an `alone` edit.
  void recordStep(EditStep step) {
    _undone.clear();
    _lastEditAt = _clock();
    _close();
    _push(step);
    _trim();
    _publish();
  }

  /// The selection moved to [next] without an edit of the caret's own: a step
  /// that does not end there is over (a caret that went away and came back
  /// is typing a new thought).
  void selectionMoved(SelectionModel next) {
    final open = _open;
    if (open != null && !open.endsAt(next)) _close();
  }

  /// The caret stepped over a closer the open step wrote, to [caret]: typing
  /// goes on in the same step. Any other caret move ends it ([seal]).
  void stepOver(int caret) {
    final open = _open;
    if (open != null && open.stepOver(caret)) {
      _openVersion++;
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
    _push(
      EditStep.of(open.finish()),
      serial: _openSerial,
      version: _openVersion,
    );
  }

  void _push(EditStep step, {int? serial, int version = 0}) {
    _done.add((step: step, serial: serial ?? ++_serial, version: version));
    _doneUnits += step.units;
  }

  /// Drops the oldest steps beyond [limit] and [budget], never the newest.
  void _trim() {
    // The open step is the newest when there is one; otherwise the last
    // closed step is.
    final keep = _open == null ? 1 : 0;
    while (_done.length > keep &&
        (length > limit || _doneUnits + (_open?.units ?? 0) > budget)) {
      _doneUnits -= _done.removeAt(0).step.units;
      _trimmed++;
    }
  }

  /// Undoes the last step on [buffer], returning the selection that goes
  /// with it, or null when there is nothing to undo — or when the note is not
  /// what the step left, which empties the history rather than write over it.
  SelectionModel? undo(SourceBuffer buffer) {
    _close();
    if (_done.isEmpty) return null;
    final last = _done.removeLast();
    _doneUnits -= last.step.units;
    final move = last.step.undo(buffer);
    if (move == null) {
      clear();
      return null;
    }
    _lastEdit = move.edit;
    _undone.add(last);
    _publish();
    return move.selection;
  }

  /// Redoes the last undone step on [buffer], returning the selection that
  /// goes with it, or null when there is nothing (or the note moved under
  /// it, as for [undo]).
  SelectionModel? redo(SourceBuffer buffer) {
    if (_undone.isEmpty) return null;
    _close();
    final next = _undone.removeLast();
    final move = next.step.redo(buffer);
    if (move == null) {
      clear();
      return null;
    }
    _lastEdit = move.edit;
    _done.add(next);
    _doneUnits += next.step.units;
    _publish();
    return move.selection;
  }

  /// Forgets everything (a note was reloaded from disk, and its history with
  /// it).
  void clear() {
    _done.clear();
    _undone.clear();
    _doneUnits = 0;
    _open = null;
    _trimmed = 0;
    _epoch++;
    _publish();
  }
}
