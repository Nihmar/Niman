import 'package:copist/src/editor/line_buffer.dart';

/// Editing session over a [LineBuffer]: the caret plus the keyboard-driven
/// edits (M2a E3).
///
/// Pure Dart — no widgets, no IME. The interactive editor (E8) drives this
/// model; autosave and the preview subscribe to its change stream.
///
/// The caret is a full-text offset in 0..textLength, the same position space
/// as [LineBuffer]. Up/down move by *logical* line, keeping the column
/// (clamped to the target line's length); the wrapped visual-row geometry is
/// a view concern (E2/E8), not part of this model.
final class LineEditor {
  /// Creates a session over [text] with the caret at its start.
  LineEditor([String text = '']) : _buffer = LineBuffer.fromText(text);

  final LineBuffer _buffer;
  final List<void Function()> _listeners = <void Function()>[];
  int _caret = 0;

  /// The buffer this session edits.
  LineBuffer get buffer => _buffer;

  /// The caret as a full-text offset, 0..[textLength].
  int get caret => _caret;

  /// The full text length in UTF-16 code units.
  int get textLength => _buffer.textLength;

  /// The full text.
  String get text => _buffer.text;

  /// The number of logical lines.
  int get lineCount => _buffer.lineCount;

  /// The logical line the caret is on.
  int get caretLine {
    final (line, _) = _buffer.locationOf(_caret);
    return line;
  }

  /// Subscribes [listener] to every change (text or caret).
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Unsubscribes [listener].
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Replaces the whole buffer with [text] and resets the caret to the start.
  void load(String text) {
    _buffer.replace(0, _buffer.textLength, text);
    _caret = 0;
    _notify();
  }

  /// Inserts [text] at the caret (typing) and moves the caret past it.
  void type(String text) {
    if (text.isEmpty) return;
    _buffer.insert(_caret, text);
    _caret += text.length;
    _notify();
  }

  /// Deletes the character before the caret (Backspace).
  void backspace() {
    if (_caret == 0) return;
    _buffer.delete(_caret - 1, _caret);
    _caret -= 1;
    _notify();
  }

  /// Deletes the character after the caret (Delete).
  void deleteForward() {
    if (_caret >= _buffer.textLength) return;
    _buffer.delete(_caret, _caret + 1);
    _notify();
  }

  /// Moves the caret one character left (stopping at the start).
  void moveLeft() => _move(_caret > 0 ? _caret - 1 : _caret);

  /// Moves the caret one character right (stopping at the end).
  void moveRight() => _move(
    _caret < _buffer.textLength ? _caret + 1 : _caret,
  );

  /// Moves to the previous *logical* line, keeping the column (clamped).
  void moveUp() => _moveVertically(-1);

  /// Moves to the next *logical* line, keeping the column (clamped).
  void moveDown() => _moveVertically(1);

  /// Moves the caret to the start of its logical line.
  void moveHome() {
    final (line, _) = _buffer.locationOf(_caret);
    _move(_buffer.offsetOf(line, 0));
  }

  /// Moves the caret to the end of its logical line.
  void moveEnd() {
    final (line, _) = _buffer.locationOf(_caret);
    _move(_buffer.offsetOf(line, _buffer.lineLength(line)));
  }

  /// Places the caret at the start of logical line [line] — the "set caret to
  /// line N" the scroll-sync and outline jumps rely on.
  void placeCaretAtLine(int line) {
    _move(_buffer.offsetOf(line, 0));
  }

  /// Sets the caret to [to], notifying only when it actually moved.
  void _move(int to) {
    if (to == _caret) return;
    _caret = to;
    _notify();
  }

  void _moveVertically(int delta) {
    final (line, col) = _buffer.locationOf(_caret);
    final targetLine = line + delta;
    if (targetLine < 0 || targetLine >= _buffer.lineCount) return;
    final len = _buffer.lineLength(targetLine);
    final targetCol = col < len ? col : len;
    _move(_buffer.offsetOf(targetLine, targetCol));
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}
