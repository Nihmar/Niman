import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_model.dart';
import 'package:niman/src/todo/todo_store.dart';

/// What the Todo tab keeps between builds (#1003): the model of the last
/// snapshot, filter and day, the items of that model under the last folded
/// sections, and the rows swiped away whose delete has not published yet.
///
/// Deriving is a pass over every line and a sort, and a fold or a rebuild
/// must not repeat it.
final class TodoModelCache {
  /// Rows swiped away whose delete has not published yet. A dismissed
  /// `Dismissible` must leave the tree at once, while the controller's
  /// snapshot arrives after the file write; the next publish (the delete,
  /// or its failure) settles them, and a failed delete brings the row back.
  final Set<TodoEntry> _hidden = {};
  int _hiddenVersion = 0;

  TodoSnapshot? _snapshot;
  TodoFilter? _filter;
  DateTime? _day;
  int _modelHidden = -1;
  TodoListModel? _model;
  List<TodoListItem>? _items;
  Set<String>? _itemsCollapsed;

  /// Hides [entry] (one of the current snapshot's own) until the next
  /// [settle].
  void hide(TodoEntry entry) {
    _hidden.add(entry);
    _hiddenVersion++;
  }

  /// A publish: the hidden rows are settled. The version moves with them,
  /// so the model derived while they were hidden is not reused when a
  /// failed delete published the very same snapshot.
  void settle() {
    if (_hidden.isEmpty) return;
    _hidden.clear();
    _hiddenVersion++;
  }

  /// The model of [snapshot] under [filter] on [day], derived once for as
  /// long as those and the hidden rows stay.
  TodoListModel modelOf(
    TodoSnapshot snapshot,
    TodoFilter filter,
    DateTime day,
  ) {
    final cached = _model;
    if (cached != null &&
        identical(_snapshot, snapshot) &&
        _filter == filter &&
        _day == day &&
        _modelHidden == _hiddenVersion) {
      return cached;
    }
    _snapshot = snapshot;
    _filter = filter;
    _day = day;
    _modelHidden = _hiddenVersion;
    _items = null;
    return _model = TodoListModel.derive(
      snapshot,
      filter,
      day,
      hidden: _hidden,
    );
  }

  /// The headers and rows of [model] under the sections [collapsed].
  List<TodoListItem> itemsOf(TodoListModel model, Set<String> collapsed) {
    final cached = _items;
    final folded = _itemsCollapsed;
    if (cached != null &&
        folded != null &&
        folded.length == collapsed.length &&
        folded.containsAll(collapsed)) {
      return cached;
    }
    _itemsCollapsed = collapsed;
    return _items = model.items(collapsed);
  }
}
