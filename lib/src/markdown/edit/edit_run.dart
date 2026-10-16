// The undo step still being written (#1046): a run of typing, or a run of
// deletions in one direction, that the next edit may join.
//
// A step is *built*, not re-made: typing appends to a `StringBuffer` and a
// deletion adds a piece to a list, so a run of n keystrokes costs O(n) in all,
// not O(n²) from joining the whole step again at every key. The history turns
// the run into an immutable record once nothing can join it any more.
import 'package:niman/src/markdown/edit/edit_history.dart';

enum _Kind {
  /// Characters typed, one after the other.
  insertion,

  /// Characters taken away, one run in one direction.
  deletion,

  /// An edit that nothing joins: a replacement, or one holding a line break.
  solo,
}

/// Which way a run of deletions is eating the text.
enum _Direction {
  /// One deletion so far: either way can still continue it.
  unknown,

  /// Backspace: each deletion is just before the last one.
  backward,

  /// Delete: each deletion is at the same place as the last one.
  forward,
}

/// An undo step in the making.
final class EditRun {
  /// Starts a run with [first].
  new(EditRecord first)
    : start = first.start,
      _kind = _kindOf(first),
      _solo = first {
    switch (_kind) {
      case _Kind.insertion:
        _typed.write(first.inserted);
      case _Kind.deletion:
        _removed.add(first.removed);
        _removedLength = first.removed.length;
      case _Kind.solo:
        break;
    }
  }

  /// Where the step begins in the text: the earliest offset it touched.
  int start;

  final _Kind _kind;

  /// The edit of a run that is only that edit.
  final EditRecord? _solo;

  /// The text of an insertion run, as typed.
  final StringBuffer _typed = StringBuffer();

  /// The pieces a deletion run took, in the order they were taken.
  final List<String> _removed = <String>[];
  int _removedLength = 0;
  _Direction _direction = _Direction.unknown;

  static _Kind _kindOf(EditRecord record) {
    if (_hasBreak(record.removed) || _hasBreak(record.inserted)) {
      return _Kind.solo;
    }
    if (record.removed.isEmpty) return _Kind.insertion;
    if (record.inserted.isEmpty) return _Kind.deletion;
    return _Kind.solo;
  }

  /// Whether [text] holds a line break: a decision of its own, which undoing
  /// separately is what a writer expects.
  static bool _hasBreak(String text) =>
      text.contains('\n') || text.contains('\r');

  /// How many code units the step holds.
  int get units => _kind == _Kind.solo
      ? _solo!.removed.length + _solo.inserted.length
      : _typed.length + _removedLength;

  /// Whether [next] simply goes on with this run.
  bool accepts(EditRecord next) {
    if (_kindOf(next) != _kind) return false;
    switch (_kind) {
      case _Kind.solo:
        return false;
      case _Kind.insertion:
        return next.start == start + _typed.length;
      case _Kind.deletion:
        final backward = next.start + next.removed.length == start;
        final forward = next.start == start;
        return switch (_direction) {
          _Direction.unknown => backward || forward,
          _Direction.backward => backward,
          _Direction.forward => forward,
        };
    }
  }

  /// Takes [next] into the run; [accepts] must have said yes.
  void add(EditRecord next) {
    switch (_kind) {
      case _Kind.solo:
        throw StateError('A solo step takes nothing.');
      case _Kind.insertion:
        _typed.write(next.inserted);
      case _Kind.deletion:
        final backward = next.start + next.removed.length == start;
        if (_direction == _Direction.unknown) {
          _direction = backward ? _Direction.backward : _Direction.forward;
        }
        _removed.add(next.removed);
        _removedLength += next.removed.length;
        if (backward) start = next.start;
    }
  }

  /// The edit this run amounts to.
  EditRecord finish() {
    switch (_kind) {
      case _Kind.solo:
        return _solo!;
      case _Kind.insertion:
        return EditRecord(start: start, removed: '', inserted: '$_typed');
      case _Kind.deletion:
        final pieces = _direction == _Direction.backward
            ? _removed.reversed
            : _removed;
        return EditRecord(start: start, removed: pieces.join(), inserted: '');
    }
  }
}
