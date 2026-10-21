/// Where a table's `+` handles stand, settled against the frame that drew
/// the table (#261).
library;

import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Settles the grid the handles of a table are built on.
///
/// The handles are built before the frame that lays the table out: a scroll
/// notifies, the overlay rebuilds, and only then do the rows move. A grid
/// read off the drawn rows at build time is the previous frame's, and as
/// the last build of a scroll is the last time anything asks, the handles
/// stood where the table had been. So a grid is first *worked out* from what
/// the build can know — the map the note is laid out by, at the scroll offset
/// the note has now — which is the drawn one by construction for every row a
/// frame has measured.
///
/// What it cannot know are the rows no frame has measured (an edit, a jump
/// past rows only estimated), whose layout moves the table after the build.
/// So every grid it hands out is checked once the frame is drawn, against
/// the rows themselves; the drawn one replaces the worked-out one, and the
/// handles are built again on it. The check runs once per grid, not once per
/// frame: a correction is remembered for the grid it corrects, so a build
/// that arrives at the same grid is not checked again, and the handles settle
/// on the frame after the one that moved the table.
final class LiveTableGridTracker extends ChangeNotifier {
  /// Creates the tracker, checking against [drawn].
  new({required this.drawn});

  /// The grid as the rows are laid out now: asked after a frame, never
  /// during a build. Null while the table is not drawn.
  final Rect? Function() drawn;

  /// How far two grids may differ and still be the same, in pixels.
  static const double tolerance = 0.5;

  Rect? _asked;
  Rect? _correction;
  Rect? _correctionFor;
  bool _checking = false;
  bool _disposed = false;

  /// The grid to build the handles on, for the grid [worked] out by the
  /// caller, or null when there is none: the table is not in play.
  Rect? settle(Rect? worked) {
    if (worked == null) {
      _correction = null;
      _correctionFor = null;
      _asked = null;
      return null;
    }
    _asked = worked;
    final fixed = _correction;
    if (fixed != null && _correctionFor == worked) return fixed;
    _check();
    return worked;
  }

  void _check() {
    if (_checking) return;
    _checking = true;
    // Normally asked for in a frame that is being built; a frame is wanted
    // for the check all the same.
    SchedulerBinding.instance
      ..ensureVisualUpdate()
      ..addPostFrameCallback((_) {
        _checking = false;
        final asked = _asked;
        if (_disposed || asked == null) return;
        final laid = drawn();
        if (laid == null || same(laid, asked)) {
          _correction = null;
          _correctionFor = null;
          return;
        }
        _correction = laid;
        _correctionFor = asked;
        notifyListeners();
      });
  }

  /// Whether [a] and [b] are the same grid, to [tolerance].
  static bool same(Rect a, Rect b) =>
      (a.left - b.left).abs() <= tolerance &&
      (a.top - b.top).abs() <= tolerance &&
      (a.right - b.right).abs() <= tolerance &&
      (a.bottom - b.bottom).abs() <= tolerance;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
