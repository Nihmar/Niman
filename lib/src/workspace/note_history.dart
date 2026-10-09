/// The notes shown, one after the other, to go back and forward through
/// as a browser does through pages (#700): the mouse's back and forward
/// buttons, `Alt+Left` and `Alt+Right`.
///
/// One history for the window, whichever pane showed a note: the user
/// moves through what they looked at, not through each pane's own. A note
/// shown again after going back starts a new branch, and what was ahead
/// of it is dropped. A note closed since is still an entry — going back
/// to it opens it again; one deleted since is skipped by the caller,
/// which asks the disk, and `NoteHistory.forget` takes it out.
library;

/// The back and forward stacks around the note shown.
final class NoteHistory {
  /// The entries kept behind and ahead, each: a long session forgets its
  /// oldest steps rather than growing without end.
  static const int capacity = 100;

  final List<String> _back = [];
  final List<String> _forward = [];
  String? _current;

  /// The note shown now, as the history has it.
  String? get current => _current;

  /// The note going back would show, or null.
  String? get previous => _back.isEmpty ? null : _back.last;

  /// The note going forward would show, or null.
  String? get next => _forward.isEmpty ? null : _forward.last;

  /// [path] is shown: the note before it goes behind, and what was ahead
  /// is dropped. Showing the note already current changes nothing — nor
  /// does the step [back] or [forward] just took, which made it current
  /// first.
  void shown(String path) {
    if (path == _current) return;
    if (_current case final before?) _push(_back, before);
    _forward.clear();
    _current = path;
  }

  /// Steps back: the previous note becomes current, the current one goes
  /// ahead. Answers the note to show, or null with nothing behind.
  String? back() {
    if (_back.isEmpty) return null;
    if (_current case final now?) _push(_forward, now);
    return _current = _back.removeLast();
  }

  /// Steps forward, the mirror of [back].
  String? forward() {
    if (_forward.isEmpty) return null;
    if (_current case final now?) _push(_back, now);
    return _current = _forward.removeLast();
  }

  /// Takes [path] out of the history — a note deleted, or one the disk no
  /// longer has — and with it a folder's notes when [path] is a folder.
  void forget(String path) {
    bool gone(String entry) => entry == path || entry.startsWith('$path/');
    _back.removeWhere(gone);
    _forward.removeWhere(gone);
    if (_current case final now? when gone(now)) _current = null;
    _collapse(_back);
    _collapse(_forward);
  }

  /// Follows a rename or a move of [from] to [to], a folder's notes with
  /// it.
  void moved(String from, String to) {
    String remap(String path) => path == from || path.startsWith('$from/')
        ? to + path.substring(from.length)
        : path;
    for (final stack in [_back, _forward]) {
      for (var i = 0; i < stack.length; i++) {
        stack[i] = remap(stack[i]);
      }
    }
    if (_current case final now?) _current = remap(now);
  }

  static void _push(List<String> stack, String path) {
    if (stack.isNotEmpty && stack.last == path) return;
    stack.add(path);
    if (stack.length > capacity) stack.removeAt(0);
  }

  /// Drops the neighbours a [forget] left equal: two steps to one note
  /// are one step.
  static void _collapse(List<String> stack) {
    for (var i = stack.length - 1; i > 0; i--) {
      if (stack[i] == stack[i - 1]) stack.removeAt(i);
    }
  }
}
