// One undo step, as the history keeps it (#1050): the hunks that changed.
//
// Most steps are one edit, one hunk. A step that replaced a long span — Replace
// All, Tidy, a kind GUI handing its note back — holds only the lines that
// changed, with the length of the unchanged text between them: when it is
// undone or redone that text is read from the note, where it still stands
// (the history is a stack, so the note is exactly what the step left), and
// never kept. A step the caller already knows the hunks of — Replace All, one
// per match — is kept as it was handed over, and a long deletion keeps the
// note's own chunks ([HeldText]) rather than a string (#1359).
import 'package:niman/src/markdown/edit/edit_record.dart';
import 'package:niman/src/markdown/edit/line_hunks.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// One change inside a step, [gap] code units of unchanged text after the
/// previous hunk (none before the first).
final class EditHunk {
  /// Creates a hunk; [held] stands for [removed] when that is a long stretch
  /// kept as the note's chunks.
  const new({
    required this.gap,
    required this.inserted,
    this.removed = '',
    this.held,
  });

  /// The unchanged text between the previous hunk and this one.
  final int gap;

  /// What was there; empty when it is [held].
  final String removed;

  /// What is there now.
  final String inserted;

  /// What was there, when it is kept as the note's chunks.
  final HeldText? held;

  /// How many code units were there.
  int get removedLength => held?.length ?? removed.length;

  /// What was there, read from the held chunks when that is where it is.
  String get removedText => held?.text ?? removed;
}

/// What an undo or a redo did: the edit the buffer reports, and the selection
/// that goes with it.
typedef StepMove = ({SourceEdit edit, SelectionModel selection});

/// One undo step.
final class EditStep {
  /// A step of [hunks], the first at [start]; [before] and [after] are the
  /// selection either side of it, which an undo and a redo put back.
  const new(this.start, this.hunks, {this.before, this.after});

  /// The step of [record]: kept whole, or — when it replaced a long span with
  /// another and most of it is unchanged — as the hunks that differ.
  factory of(EditRecord record) {
    final whole = EditStep(
      record.start,
      [
        EditHunk(
          gap: 0,
          removed: record.removed,
          inserted: record.inserted,
          held: record.held,
        ),
      ],
      before: record.selectionBefore,
      after: record.selectionAfter,
    );
    if (record.removed.isEmpty ||
        record.inserted.isEmpty ||
        record.removed.length + record.inserted.length < compactFrom) {
      return whole;
    }
    final changes = lineHunks(record.removed, record.inserted);
    if (changes.isEmpty) return whole;
    final hunks = <EditHunk>[];
    var previousEnd = changes.first.removedStart;
    for (final change in changes) {
      hunks.add(
        EditHunk(
          gap: change.removedStart - previousEnd,
          removed: record.removed.substring(
            change.removedStart,
            change.removedEnd,
          ),
          inserted: record.inserted.substring(
            change.insertedStart,
            change.insertedEnd,
          ),
        ),
      );
      previousEnd = change.removedEnd;
    }
    final step = EditStep(
      record.start + changes.first.removedStart,
      hunks,
      before: record.selectionBefore,
      after: record.selectionAfter,
    );
    return step.units < whole.units ? step : whole;
  }

  /// A step this long (code units, both sides) is looked at for hunks; shorter
  /// ones are typing and small edits, kept as they are.
  static const int compactFrom = 4096;

  /// From how many hunks on the unchanged text between them is read from the
  /// note in one go rather than hunk by hunk.
  static const int _readWholeFrom = 64;

  /// Where the step begins in the text.
  final int start;

  /// The changes, in order.
  final List<EditHunk> hunks;

  /// The selection before the step, when it is known.
  final SelectionModel? before;

  /// The selection after the step, when it is known.
  final SelectionModel? after;

  /// What the step holds, in code units: the text it keeps.
  int get units {
    var total = 0;
    for (final hunk in hunks) {
      total += hunk.removedLength + hunk.inserted.length;
    }
    return total;
  }

  /// Puts the text back as it was before the step, or null when the note is
  /// not what the step left (the history is then no longer to be trusted).
  StepMove? undo(SourceBuffer buffer) => _replace(buffer, undoing: true);

  /// Makes the step's change again, or null when the note is not what the
  /// step undid.
  StepMove? redo(SourceBuffer buffer) => _replace(buffer, undoing: false);

  int _fromLength(EditHunk hunk, {required bool undoing}) =>
      undoing ? hunk.inserted.length : hunk.removedLength;

  String _toText(EditHunk hunk, {required bool undoing}) =>
      undoing ? hunk.removedText : hunk.inserted;

  /// Whether the note holds what the step expects to replace: the span it
  /// covers is there and begins and ends with the units the hunks say. Cheap
  /// — a run of the note is never compared — and enough to refuse an edit
  /// made behind the history's back, where an assert would be gone from a
  /// release build (#1376).
  bool _holds(SourceBuffer buffer, int span, {required bool undoing}) {
    if (start < 0 || start + span > buffer.length) return false;
    bool unitIs(int at, String text, int index) =>
        buffer.substring(at, at + 1) == text.substring(index, index + 1);
    // What a held hunk removed is read from its chunks only when it is the
    // text an undo puts back, never to be compared.
    final first = hunks.first;
    final head = undoing ? first.inserted : first.removed;
    if (head.isNotEmpty && !unitIs(start, head, 0)) return false;
    final last = hunks.last;
    final tail = undoing ? last.inserted : last.removed;
    if (tail.isNotEmpty && !unitIs(start + span - 1, tail, tail.length - 1)) {
      return false;
    }
    return true;
  }

  /// Replaces the span the step covers, where it reads as the hunks' `from`
  /// side, with what it reads as their `to` side; the unchanged text between
  /// the hunks is the note's own.
  StepMove? _replace(SourceBuffer buffer, {required bool undoing}) {
    var span = 0;
    for (final hunk in hunks) {
      span += hunk.gap + _fromLength(hunk, undoing: undoing);
    }
    if (!_holds(buffer, span, undoing: undoing)) return null;
    final landing = undoing ? before : after;
    if (hunks.length == 1) {
      final text = _toText(hunks.first, undoing: undoing);
      return (
        edit: buffer.replaceRange(start, start + span, text, verbatim: true),
        selection: landing ?? SelectionModel.at(start + text.length),
      );
    }
    final text = StringBuffer();
    // A step of many hunks reads its whole span at once: a read for every gap
    // is a walk down the note's index each.
    final whole = hunks.length >= _readWholeFrom
        ? buffer.substring(start, start + span)
        : null;
    var at = 0;
    for (final hunk in hunks) {
      if (hunk.gap > 0) {
        text.write(
          whole != null
              ? whole.substring(at, at + hunk.gap)
              : buffer.substring(start + at, start + at + hunk.gap),
        );
        at += hunk.gap;
      }
      text.write(_toText(hunk, undoing: undoing));
      at += _fromLength(hunk, undoing: undoing);
    }
    final replacement = '$text';
    return (
      edit: buffer.replaceRange(
        start,
        start + span,
        replacement,
        verbatim: true,
      ),
      selection: landing ?? SelectionModel.at(start + replacement.length),
    );
  }
}
