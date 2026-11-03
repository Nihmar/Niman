import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/lazy_drag_paths.dart';

/// The rows marked together (#712), by path: `Shift`+click, `Shift`+the
/// arrows and `Space` mark, a plain click or `Esc` lets go; so does a row
/// leaving the tree (#979). The tree's own rows only, not the pinned
/// block's copies.
final class TreeMarks {
  final Set<String> _paths = {};

  /// Whether no row is marked.
  bool get isEmpty => _paths.isEmpty;

  /// Whether a row is marked.
  bool get isNotEmpty => _paths.isNotEmpty;

  /// Whether the row at [path] is marked.
  bool contains(String path) => _paths.contains(path);

  /// Whether the row at [path] is one of several marked rows: what a drag, a
  /// right click, the menu key and `Delete` on it act on together.
  bool isAmongSeveral(String path) =>
      _paths.length > 1 && _paths.contains(path);

  /// The marked rows' paths.
  List<String> toList() => _paths.toList();

  /// Marks the row at [path], or lets it go when it is marked.
  void toggle(String path) {
    if (!_paths.remove(path)) _paths.add(path);
  }

  /// Marks the rows at [paths].
  void addAll(Iterable<String> paths) => _paths.addAll(paths);

  /// Lets every mark go.
  void clear() => _paths.clear();

  /// The paths a drag started on [path] carries (#996): every marked row's
  /// when [path] is one of several marked rows, else null, the row's own.
  ///
  /// The marks are copied when a drag looks at them, not when the row is
  /// built (#1234): a range can mark a million rows, and every marked row on
  /// screen is built with these.
  List<String>? dragPaths(String path) =>
      isAmongSeveral(path) ? LazyDragPaths(_paths.toList) : null;

  /// Lets go of the marks on rows that are no longer in the tree — deleted,
  /// moved, renamed or folded away — so a `Delete` never goes to paths that
  /// are not on screen (#979). Once per read, not per frame.
  ///
  /// A row is folded away when a folder above it is not in [expanded]; one
  /// that is gone is asked of [session]'s index, whatever page it was in.
  Future<void> dropOutside(Set<String> expanded, LibrarySession session) async {
    if (_paths.isEmpty) return;
    _paths.removeWhere((path) => !_isUnderOpenFolders(path, expanded));
    if (_paths.isEmpty) return;
    final gone = await session.missingPaths(_paths.toList());
    _paths.removeWhere(gone.contains);
  }

  /// Whether every folder above [path] is in [expanded].
  static bool _isUnderOpenFolders(String path, Set<String> expanded) {
    for (var cut = path.lastIndexOf('/'); cut > 0;) {
      if (!expanded.contains(path.substring(0, cut))) return false;
      cut = path.lastIndexOf('/', cut - 1);
    }
    return true;
  }
}
