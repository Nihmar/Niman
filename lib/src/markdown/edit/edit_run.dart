// The undo step still being written (#1046, #1053): a run of typing, or a run
// of deletions in one direction, that the next edit may join.
//
// A step is *built*, not re-made: typing appends to a `StringBuffer` and a
// deletion adds a piece to a list, so a run of n keystrokes costs O(n) in all,
// not O(n²) from joining the whole step again at every key. The history turns
// the run into an immutable record once nothing can join it any more.
//
// An IME's composition is one run (#1337): each update replaces the composing
// text, and the run takes the new text in place of the old rather than
// stacking a step on it.
import 'package:niman/src/markdown/edit/edit_record.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';

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
      _solo = first,
      _before = first.selectionBefore,
      _after = first.selectionAfter {
    switch (_kind) {
      case _Kind.insertion:
        // A composition may begin by replacing a selection: what it replaced
        // goes back with the step.
        _replaced = first.removed;
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

  /// The selection before the run's first edit, and after its last.
  final SelectionModel? _before;
  SelectionModel? _after;

  /// What the first edit of an insertion run replaced — a composition that
  /// began over a selection — or nothing.
  String _replaced = '';

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
    // A long stretch kept as the note's chunks is a step by itself.
    if (record.held != null) return _Kind.solo;
    if (_hasBreak(record.removed) || _hasBreak(record.inserted)) {
      return _Kind.solo;
    }
    if (record.removed.isEmpty) return _Kind.insertion;
    if (record.inserted.isEmpty) return _Kind.deletion;
    // A composition over a selection starts the text it goes on writing.
    return record.composing ? _Kind.insertion : _Kind.solo;
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
      ? _solo!.removedLength + _solo.inserted.length
      : _replaced.length + _typed.length + _tail.length + _removedLength;

  /// Whether the run holds nothing any more: a composition cancelled the
  /// text it had typed.
  bool get isEmpty =>
      _kind == _Kind.insertion &&
      _replaced.isEmpty &&
      _typed.isEmpty &&
      _tail.isEmpty;

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
    _scan(head);
  }

  /// Takes [typed] into [_hasWord] and [_endsInSpace].
  void _scan(String typed) {
    for (var i = 0; i < typed.length; i++) {
      if (_isSpace(typed.codeUnitAt(i))) {
        _endsInSpace = true;
      } else {
        _hasWord = true;
        _endsInSpace = false;
      }
    }
  }

  /// Whether the selection standing at [next] is where the run left it — or
  /// the run does not know where that is.
  bool endsAt(SelectionModel next) => _after == null || _after == next;

  /// Whether [next] is the composition this run holds at work: an IME's
  /// update that replaces text the run typed. [absorb] takes it.
  bool absorbs(EditRecord next) {
    if (!next.composing || _kind != _Kind.insertion || next.held != null) {
      return false;
    }
    final from = next.start - start;
    final to = from + next.removed.length;
    if (next.removed.isEmpty || from < 0 || to > _typed.length) return false;
    return '$_typed'.substring(from, to) == next.removed;
  }

  /// Puts the text of [next], which [absorbs] said it can, in place of the
  /// composing text it replaces.
  void absorb(EditRecord next) {
    final from = next.start - start;
    final text = '$_typed'.replaceRange(
      from,
      from + next.removed.length,
      next.inserted,
    );
    _typed
      ..clear()
      ..write(text);
    _hasWord = false;
    _endsInSpace = false;
    _scan(text);
    _after = next.selectionAfter;
  }

  /// Whether [next] simply goes on with this run.
  bool accepts(EditRecord next) {
    if (_kindOf(next) != _kind) return false;
    switch (_kind) {
      case _Kind.solo:
        return false;
      case _Kind.insertion:
        // What replaces text is a composition's, and [absorbs] decides it.
        if (next.removed.isNotEmpty) return false;
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
        _after = next.selectionAfter;
      case _Kind.deletion:
        final backward = next.start + next.removed.length == start;
        _after = next.selectionAfter;
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
    _after = SelectionModel.at(caret);
    return true;
  }

  /// The edit this run amounts to.
  EditRecord finish() {
    switch (_kind) {
      case _Kind.solo:
        return _solo!;
      case _Kind.insertion:
        return EditRecord(
          start: start,
          removed: _replaced,
          inserted: '$_typed$_tail',
          selectionBefore: _before,
          selectionAfter: _after,
        );
      case _Kind.deletion:
        final pieces = _direction == _Direction.backward
            ? _removed.reversed
            : _removed;
        return EditRecord(
          start: start,
          removed: pieces.join(),
          inserted: '',
          selectionBefore: _before,
          selectionAfter: _after,
        );
    }
  }
}
