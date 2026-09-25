/// Follows a reader through one document and writes down where they are
/// (#281), for a pane to feed as its view moves.
///
/// A place is written once the reader rests, and when the pane lets the
/// document go. A place the view merely settled on is not written: a
/// document opened and not moved is not a reading, and must not outdate,
/// by its newer time, the place another device wrote.
library;

import 'dart:async';

import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';

/// The reading position of the document at one path.
final class ReadingTracker {
  /// Follows the document at [path], an absolute path, among [positions];
  /// null positions, or a path outside their library, keep nothing.
  new(ReadingPositions? positions, String path)
    : _positions = positions,
      _key = positions?.keyOf(path);

  /// How long the reader rests before the place is written down.
  static const Duration restDelay = Duration(seconds: 1);

  final ReadingPositions? _positions;
  final String? _key;

  /// Whether the document was set where it was left: moves before are the
  /// view settling, not the reader.
  bool _placed = false;

  /// The place last written down, or found written when the document
  /// opened.
  BookLocation? _saved;

  /// Where the reader moved to, not yet written down.
  BookLocation? _unsaved;
  Timer? _timer;

  /// Where the document was left, or null.
  Future<BookLocation?> read() async {
    final positions = _positions;
    final key = _key;
    if (positions == null || key == null) return null;
    return await positions.read(key);
  }

  /// The document is set: at [location], where it was left, or at its
  /// start when null. The moves from here on are the reader's.
  void placed(BookLocation? location) {
    _saved = location;
    _placed = true;
  }

  /// The reader is at [here].
  void moved(BookLocation here) {
    if (!_placed || _key == null) return;
    _timer?.cancel();
    if (here.isNear(_saved)) {
      _unsaved = null;
      return;
    }
    _unsaved = here;
    _timer = Timer(restDelay, flush);
  }

  /// Writes down where the reader moved to, if they moved: the pane is
  /// letting the document go.
  void flush() {
    _timer?.cancel();
    final here = _unsaved;
    final positions = _positions;
    final key = _key;
    _unsaved = null;
    if (here == null || positions == null || key == null) return;
    _saved = here;
    unawaited(positions.write(key, here));
  }
}
