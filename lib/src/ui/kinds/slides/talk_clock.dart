/// The time a talk has run (#534): it starts on the talk's first move, not
/// on opening, and can be paused and put back to zero.
final class TalkClock {
  /// When the clock last started, null while stopped; the time it had
  /// counted before.
  DateTime? _started;
  Duration _counted = Duration.zero;
  bool _paused = false;

  /// Whether the speaker paused it.
  bool get paused => _paused;

  /// The time the talk has run.
  Duration get elapsed {
    final started = _started;
    return _counted +
        (started == null ? Duration.zero : DateTime.now().difference(started));
  }

  /// The talk moved: the first move starts the clock, unless it is paused.
  void moved() {
    if (_started == null && !_paused) _started = DateTime.now();
  }

  /// Pauses the clock, or starts it again.
  void togglePause() {
    final started = _started;
    if (started != null) {
      _counted += DateTime.now().difference(started);
      _started = null;
      _paused = true;
    } else {
      _started = DateTime.now();
      _paused = false;
    }
  }

  /// Back to zero, waiting for the next move.
  void restart() {
    _counted = Duration.zero;
    _started = null;
    _paused = false;
  }
}
