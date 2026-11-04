import 'dart:async';

import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// The source view's colours: the [SourceStyler] over the note, read in
/// place or in the background, moved along by every edit, and its scan
/// carried on a slice at a time when an edit left it owed.
///
/// The view owns it and asks it for [styler]; what lands outside an edit —
/// a long note's reading, a scan settling — is handed back through the
/// narrow callbacks it is given.
final class SourceStyling {
  /// The colours of [_buffer]'s note.
  new({
    required this._buffer,
    required this._mounted,
    required this._readsInBackground,
    required this._progressiveLines,
    required this._landed,
    required this._settled,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// Whether the view is still mounted.
  final bool Function() _mounted;

  /// Whether a note is a long one, whose colours are read in the
  /// background.
  final bool Function(SourceBuffer buffer) _readsInBackground;

  /// From how many lines on a note read in place reads the blocks of its
  /// top alone before its first frame.
  final int Function() _progressiveLines;

  /// A long note's reading landed: [styler] is the new one, to draw with.
  final void Function() _landed;

  /// A slice of the scan an edit left owed ran, and settled it.
  final void Function() _settled;

  /// How many lines of such a note are read before its first frame: a
  /// screen and more. A frame placed further down — a note reopened where
  /// it was read — reads on as far as its lines ([SourceStyler.blockOf]).
  static const int _firstScanLines = 512;

  /// The colours: the read view's engine put on the source lines, kept
  /// across rebuilds and moved along by every edit — O(change).
  ///
  /// Null while a long note is read in the background ([restyle]): the
  /// lines are drawn plain until it lands.
  SourceStyler? get styler => _styler;
  SourceStyler? _styler;

  /// Counts the readings started, so one a later one overtook is dropped.
  int _stylings = 0;

  /// The last reading of a long note, from the call that started it to the
  /// styler in place — complete once it has landed; null for a note read in
  /// place.
  Future<void>? _reading;

  /// Completes when the reading of the note under way has landed — at once
  /// when none is.
  Future<void> get readingLanded => _reading ?? Future<void>.value();

  /// The next slice of a scan an edit left owed, when one is waiting.
  Timer? _scanSlice;

  /// Reads the note's colours again, from the top.
  ///
  /// A long note is read in an isolate ([SourceStyler.inBackground]): the
  /// block scan of a 246 MB note is 2 s of a frozen window. Its lines are
  /// drawn plain until the reading lands, and one that lands on a note that
  /// moved on meanwhile is started again.
  void restyle() {
    final buffer = _buffer();
    final reading = ++_stylings;
    // The scan a slice was waiting to carry on is the styler's this one
    // replaces: left waiting, it kept the new styler's from being carried
    // on, and found the old one gone when it ran.
    _scanSlice?.cancel();
    _scanSlice = null;
    if (!_readsInBackground(buffer)) {
      _reading = null;
      final progressive = buffer.lineCount >= _progressiveLines();
      _styler = SourceStyler(
        buffer,
        firstLines: progressive ? _firstScanLines : null,
      );
      if (progressive) _carryScanOn();
      return;
    }
    _styler = null;
    // The landing itself is what [readingLanded] answers: a reader waiting
    // on it finds the styler in place when it resumes.
    final landing = SourceStyler.inBackground(buffer).then((styler) {
      if (!_mounted() || reading != _stylings) return;
      if (!identical(_buffer(), buffer)) return;
      if (styler.revision != buffer.revision) {
        restyle();
        return;
      }
      _styler = styler;
      _landed();
    });
    _reading = landing;
    unawaited(landing);
  }

  /// Moves the colours along [edit], already made to the buffer.
  void edited(SourceEdit edit) {
    _styler?.edited(edit);
    _carryScanOn();
  }

  /// Carries on, a slice at a time, the scan an edit left owed
  /// (`docs/records/huge-notes.md` item 3).
  ///
  /// An edit that changes what the rest of the note is — a `$$` opened at 50 %
  /// of a 246 MB note — scans its budget of lines and stops, and the lines on
  /// screen catch it up as far as they need. Nothing drawn waits for the rest,
  /// so nothing here repaints; what finishing it gives back is the whole
  /// note's answers — the outline, the blocks — to the readers that ask for
  /// all of it.
  ///
  /// Each slice is a timer of its own, so a frame or a key between two slices
  /// waits for one slice at most. Not an idle-priority scheduler task: those
  /// are refused while any animation runs, and a refused task asks the event
  /// loop again at once — a core spinning for as long as a spinner turns.
  void _carryScanOn() {
    final styler = _styler;
    if (_scanSlice != null || styler == null || styler.settled) return;
    _scanSlice = Timer(Duration.zero, () {
      _scanSlice = null;
      if (!_mounted() || !identical(_styler, styler)) return;
      styler.advance();
      if (styler.settled) _settled();
      _carryScanOn();
    });
  }

  /// Stops the slice waiting to run.
  void dispose() => _scanSlice?.cancel();
}
