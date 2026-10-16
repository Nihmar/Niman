// One edit, as an undo needs to see it (#245, phase 3).

/// One edit, as an undo needs to see it.
final class EditRecord {
  /// Creates a record of replacing `[start, start + removed.length)` with
  /// [inserted].
  const new({
    required this.start,
    required this.removed,
    required this.inserted,
  });

  /// Where the edit began.
  final int start;

  /// What was there before.
  final String removed;

  /// What is there now.
  final String inserted;

  /// Where the edit ends in the text as it stands.
  int get end => start + inserted.length;

  /// The record that undoes this one, given the text it produced.
  EditRecord get inverse =>
      EditRecord(start: start, removed: inserted, inserted: removed);

  @override
  String toString() =>
      'EditRecord($start, -${removed.length}, +${inserted.length})';
}
