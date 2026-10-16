// The undo step still being written (#1046, #1053): a run of typing, or a run
// of deletions in one direction, that the next edit may join.
//
// A step is *built*, not re-made: typing appends to a `StringBuffer` and a
// deletion adds a piece to a list, so a run of n keystrokes costs O(n) in all,
// not O(n²) from joining the whole step again at every key. The history turns
// the run into an immutable record once nothing can join it any more.
import 'package:niman/src/markdown/edit/edit_record.dart';

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
  /// Starts a run with [first]; the last [closing] characters of what it
  /// inserted are closers the editor wrote ahead of the caret (see [add]).
  new(EditRecord first, {int closing = 0})
    : start = first.start,
      _kind = _kindOf(first),
      _solo = first {
    switch (_kind) {
      case _Kind.insertion:
        _write(first.inserted, closing);
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

  /// The text of an insertion run, as typed: what stands before the caret.
  final StringBuffer _typed = StringBuffer();

  /// The closers an insertion run wrote ahead of the caret — the `)` of a
  /// `(` typed — which what is typed next goes before, and a keystroke over
  /// them steps across ([stepOver]).
  String _tail = '';

  /// Whether the typed text holds anything but white space.
  bool _hasWord = false;

  /// Whether the typed text ends in white space.
  bool _endsInSpace = false;

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

  /// Whether the code unit [unit] is white space.
  static bool _isSpace(int unit) =>
      unit <= 0x20 ||
      unit == 0xA0 ||
      (unit >= 0x2000 && unit <= 0x200A) ||
      unit == 0x3000;

  /// Whether nothing can join this run: it is a step already.
  bool get isComplete => _kind == _Kind.solo;

  /// How many code units the step holds.
  int get units => _kind == _Kind.solo
      ? _solo!.removed.length + _solo.inserted.length
      : _typed.length + _tail.length + _removedLength;

  /// Where the caret stands once the run's typing is in: after the typed
  /// text, before the closers.
  int get _caret => start + _typed.length;

  /// Appends [inserted] — its last [closing] characters being closers — to
  /// what is typed.
  void _write(String inserted, int closing) {
    final cut = inserted.length - closing.clamp(0, inserted.length);
    final head = inserted.substring(0, cut);
    _typed.write(head);
    _tail = '${inserted.substring(cut)}$_tail';
    for (var i = 0; i < head.length; i++) {
      if (_isSpace(head.codeUnitAt(i))) {
        _endsInSpace = true;
      } else {
        _hasWord = true;
        _endsInSpace = false;
      }
    }
  }

  /// Whether [next] simply goes on with this run.
  bool accepts(EditRecord next) {
    if (_kindOf(next) != _kind) return false;
    switch (_kind) {
      case _Kind.solo:
        return false;
      case _Kind.insertion:
        // At the caret, or just past the closers the run wrote.
        if (next.start != _caret && next.start != _caret + _tail.length) {
          return false;
        }
        // A word typed after a space, once the run holds a word, is the next
        // thought: undo takes the words back one at a time (#1053).
        if (_hasWord &&
            _endsInSpace &&
            _tail.isEmpty &&
            !_isSpace(next.inserted.codeUnitAt(0))) {
          return false;
        }
        return true;
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

  /// Takes [next] into the run; [accepts] must have said yes. The last
  /// [closing] characters of an insertion are closers written ahead of the
  /// caret.
  void add(EditRecord next, {int closing = 0}) {
    switch (_kind) {
      case _Kind.solo:
        throw StateError('A solo step takes nothing.');
      case _Kind.insertion:
        if (next.start != _caret) {
          // Typed past the closers: they are behind the caret now.
          _typed.write(_tail);
          _tail = '';
          _endsInSpace = false;
        }
        _write(next.inserted, closing);
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

  /// The caret stepped over the closer the run wrote right after it, to
  /// [caret]: the closer is behind the caret now and typing goes on in the
  /// same step. False when the run wrote no closer there.
  bool stepOver(int caret) {
    if (_kind != _Kind.insertion || _tail.isEmpty || caret != _caret + 1) {
      return false;
    }
    _typed.write(_tail.substring(0, 1));
    _tail = _tail.substring(1);
    _endsInSpace = false;
    return true;
  }

  /// The edit this run amounts to.
  EditRecord finish() {
    switch (_kind) {
      case _Kind.solo:
        return _solo!;
      case _Kind.insertion:
        return EditRecord(start: start, removed: '', inserted: '$_typed$_tail');
      case _Kind.deletion:
        final pieces = _direction == _Direction.backward
            ? _removed.reversed
            : _removed;
        return EditRecord(start: start, removed: pieces.join(), inserted: '');
    }
  }
}
