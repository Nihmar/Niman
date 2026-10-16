// One undo step, as the history keeps it (#1050): the hunks that changed.
//
// Most steps are one edit, one hunk. A step that replaced a long span — Replace
// All, Tidy, a kind GUI handing its note back — holds only the lines that
// changed, with the length of the unchanged text between them: when it is
// undone or redone that text is read from the note, where it still stands
// (the history is a stack, so the note is exactly what the step left), and
// never kept.
import 'package:niman/src/markdown/edit/edit_record.dart';
import 'package:niman/src/markdown/edit/line_hunks.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// One change inside a step, [gap] code units of unchanged text after the
/// previous hunk (none before the first).
final class EditHunk {
  /// Creates a hunk.
  const new({required this.gap, required this.removed, required this.inserted});

  /// The unchanged text between the previous hunk and this one.
  final int gap;

  /// What was there.
  final String removed;

  /// What is there now.
  final String inserted;
}

/// What an undo or a redo did: the edit the buffer reports, and where the
/// caret goes.
typedef StepMove = ({SourceEdit edit, int caret});

/// One undo step.
final class EditStep {
  /// A step of [hunks], the first at [start].
  const new(this.start, this.hunks);

  /// The step of [record]: kept whole, or — when it replaced a long span with
  /// another and most of it is unchanged — as the hunks that differ.
  factory of(EditRecord record) {
    final whole = EditStep(record.start, [
      EditHunk(gap: 0, removed: record.removed, inserted: record.inserted),
    ]);
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
    final step = EditStep(record.start + changes.first.removedStart, hunks);
    return step.units < whole.units ? step : whole;
  }

  /// A step this long (code units, both sides) is looked at for hunks; shorter
  /// ones are typing and small edits, kept as they are.
  static const int compactFrom = 4096;

  /// Where the step begins in the text.
  final int start;

  /// The changes, in order.
  final List<EditHunk> hunks;

  /// What the step holds, in code units: the text it keeps.
  int get units {
    var total = 0;
    for (final hunk in hunks) {
      total += hunk.removed.length + hunk.inserted.length;
    }
    return total;
  }

  /// Puts the text back as it was before the step.
  StepMove undo(SourceBuffer buffer) =>
      _replace(buffer, (hunk) => hunk.inserted, (hunk) => hunk.removed);

  /// Makes the step's change again.
  StepMove redo(SourceBuffer buffer) =>
      _replace(buffer, (hunk) => hunk.removed, (hunk) => hunk.inserted);

  /// Replaces the span the step covers, where it reads as [from], with what
  /// it reads as [to]; the unchanged text between the hunks is the note's own.
  StepMove _replace(
    SourceBuffer buffer,
    String Function(EditHunk hunk) from,
    String Function(EditHunk hunk) to,
  ) {
    if (hunks.length == 1) {
      final hunk = hunks.first;
      final replacing = from(hunk);
      final text = to(hunk);
      return (
        edit: buffer.replaceRange(
          start,
          start + replacing.length,
          text,
          verbatim: true,
        ),
        caret: start + text.length,
      );
    }
    final text = StringBuffer();
    var end = start;
    for (final hunk in hunks) {
      if (hunk.gap > 0) {
        text.write(buffer.substring(end, end + hunk.gap));
        end += hunk.gap;
      }
      text.write(to(hunk));
      end += from(hunk).length;
    }
    final replacement = '$text';
    return (
      edit: buffer.replaceRange(start, end, replacement, verbatim: true),
      caret: start + replacement.length,
    );
  }
}
