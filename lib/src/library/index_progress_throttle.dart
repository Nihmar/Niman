import 'package:niman/src/db/index_scan.dart';

/// Records a scan's progress, and lets the UI see it at a readable rate
/// (#1068).
///
/// The reports arrive one per note, which on a large library is far
/// faster than a frame; rebuilding on each would spend the scan drawing
/// instead of reading. Twenty a second already reads as a blur, which
/// is the point of showing them.
final class IndexProgressThrottle {
  /// A throttle that calls [show] when a report is due on screen — with
  /// `tree` true when the tree should read its rows again too.
  new({required this.show});

  /// Puts the latest report on screen.
  final void Function({required bool tree}) show;

  /// How often a running content pass lets the tree read the rows it has
  /// changed so far.
  static const _progressTreeInterval = Duration(seconds: 2);

  /// How often a running scan redraws the name it is showing.
  static const _progressInterval = Duration(milliseconds: 50);

  /// How far the first index has got, or null when no scan is running.
  IndexProgress? get progress => _progress;
  IndexProgress? _progress;
  DateTime? _progressShown;
  DateTime? _progressTreeBump;

  /// Records [progress], and shows it when the last one shown is old
  /// enough.
  void report(IndexProgress progress) {
    _progress = progress;
    final now = DateTime.now();
    final last = _progressShown;
    if (last != null && now.difference(last) < _progressInterval) return;
    _progressShown = now;
    // The tree is asked to read its rows again only now and then: titles and
    // pins reach it as the notes are read (#1068), but a flatten per report
    // would spend the pass drawing a tree that has barely moved.
    final treeAt = _progressTreeBump;
    final tree =
        treeAt == null || now.difference(treeAt) >= _progressTreeInterval;
    if (tree) _progressTreeBump = now;
    show(tree: tree);
  }

  /// The scan has ended: no progress to show.
  void end() {
    _progress = null;
    _progressTreeBump = null;
  }
}
