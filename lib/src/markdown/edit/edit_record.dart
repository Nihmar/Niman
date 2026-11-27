// One edit, as an undo needs to see it (#245, phase 3).
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A long stretch of the note an edit took out, held as the buffer's own
/// chunks rather than as a new string (#1359).
///
/// Select all and Delete on a 246 MB note would otherwise join the whole note
/// into one string and keep it in the step. This keeps a
/// [SourceBuffer.snapshot]
/// taken before the edit — the lines and their index shared with the note, so
/// only what the note edits afterwards is copied — and reads the text from it
/// when an undo needs it.
final class HeldText {
  /// The stretch `[start, end)` of [_snapshot].
  const new _(this._snapshot, this.start, this.end);

  /// From how many code units a deletion is held rather than copied.
  static const int from = 1 << 20;

  /// Holds `[start, end)` of [buffer] if it is long enough to be worth it, or
  /// null; call it *before* the edit.
  static HeldText? of(SourceBuffer buffer, int start, int end) =>
      end - start < from ? null : HeldText._(buffer.snapshot(), start, end);

  final SourceBuffer _snapshot;

  /// Where the stretch began in the note it was taken from.
  final int start;

  /// Where it ended.
  final int end;

  /// How many code units it holds.
  int get length => end - start;

  /// The text, read from the shared chunks: O(its length), when asked.
  String get text => _snapshot.substring(start, end);
}

/// What an edit took out of the note: its text, or — a long deletion — the
/// buffer's chunks ([HeldText]).
typedef Removal = ({String text, HeldText? held});

/// Reads what `[start, end)` of [buffer] holds, before an edit replaces it
/// with [inserted]; a long stretch that is only deleted is held, not copied.
Removal removalOf(SourceBuffer buffer, int start, int end, String inserted) {
  final held = inserted.isEmpty ? HeldText.of(buffer, start, end) : null;
  return (text: held == null ? buffer.substring(start, end) : '', held: held);
}

/// One edit, as an undo needs to see it.
final class EditRecord {
  /// Creates a record of replacing `[start, start + removed.length)` with
  /// [inserted].
  ///
  /// [held] stands for [removed] when the edit took out a long stretch
  /// ([removalOf]); [selectionBefore] and [selectionAfter] are the selection
  /// either side of the edit, which an undo and a redo put back (#1338).
  /// [composing] says the edit is an IME's composition at work, which goes on
  /// in the step of the composition rather than being a step of its own
  /// (#1337).
  const new({
    required this.start,
    required this.inserted,
    this.removed = '',
    this.held,
    this.selectionBefore,
    this.selectionAfter,
    this.composing = false,
  });

  /// Where the edit began.
  final int start;

  /// What was there before; empty when it is [held].
  final String removed;

  /// What is there now.
  final String inserted;

  /// What was there before, when it is long and kept as the note's chunks.
  final HeldText? held;

  /// The selection before the edit, when the caller knew it.
  final SelectionModel? selectionBefore;

  /// The selection after the edit, when the caller knew it.
  final SelectionModel? selectionAfter;

  /// Whether the edit is part of an IME composition.
  final bool composing;

  /// How many code units were there before.
  int get removedLength => held?.length ?? removed.length;

  /// Where the edit ends in the text as it stands.
  int get end => start + inserted.length;

  @override
  String toString() =>
      'EditRecord($start, -$removedLength, +${inserted.length})';
}
