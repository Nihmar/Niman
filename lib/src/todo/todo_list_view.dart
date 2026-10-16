import 'package:flutter/foundation.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_sections.dart';

/// What the todo list shows: the filter and the sections folded away
/// (#1003).
///
/// One object the shell owns and shares between the Todo tab and the phone
/// app bar, whose Filter and Sort icons and active-filter dot read and set
/// the same state the tab draws from. It holds no entries: the tab applies
/// [filter] to the snapshot and cuts the result into sections.
///
/// The folded sections are remembered per device and library: every change
/// is handed to [onCollapsedChanged], which the shell wires to the session.
/// The filter is not persisted.
final class TodoListView extends ChangeNotifier {
  /// Creates the view with a [filter] and the sections folded at the start
  /// (default: Done only, as a fresh library has it).
  new({
    this._filter = const TodoFilter(),
    Set<String> collapsed = const <String>{todoDoneSectionId},
    this.onCollapsedChanged,
  }) : _collapsed = <String>{...collapsed};

  /// Called with the new set of folded section ids after
  /// [toggleSection] changes it, to persist it. Not called by
  /// [restoreCollapsed], which is the persisted value coming back.
  final void Function(Set<String> collapsed)? onCollapsedChanged;

  TodoFilter _filter;
  final Set<String> _collapsed;

  /// The current filter: due range, token chips and sort key.
  TodoFilter get filter => _filter;

  /// Replaces the filter outright (a filter sheet that edits a draft and
  /// applies it whole).
  void setFilter(TodoFilter value) {
    if (value == _filter) {
      return;
    }
    _filter = value;
    notifyListeners();
  }

  /// Narrows the list to [range].
  void setDueRange(TodoDueRange range) {
    setFilter(_filter.copyWith(dueRange: range));
  }

  /// Selects [token] (`+project` / `@context` / `#tag`), or deselects it
  /// when it is already selected.
  void toggleToken(String token) {
    final tokens = <String>{..._filter.tokens};
    if (!tokens.remove(token)) {
      tokens.add(token);
    }
    setFilter(_filter.copyWith(tokens: tokens));
  }

  /// Sorts the list by [sort]; the sections follow it.
  void setSort(TodoSort sort) {
    setFilter(_filter.copyWith(sort: sort));
  }

  /// Drops the due range and every token; the sort stays.
  void clearFilters() {
    setFilter(_filter.copyWith(dueRange: TodoDueRange.all, tokens: {}));
  }

  /// Drops selected tokens absent from [available] (the file changed under
  /// a selected chip).
  void pruneTokens(Set<String> available) {
    setFilter(_filter.pruneTokens(available));
  }

  /// How many filters narrow the list: each selected token, plus one for
  /// a due range other than all. The sort is not a filter.
  int get activeFilterCount {
    return _filter.tokens.length +
        (_filter.dueRange == TodoDueRange.all ? 0 : 1);
  }

  /// Whether the list is narrowed by anything.
  bool get hasActiveFilters => activeFilterCount > 0;

  /// The ids of the folded sections.
  Set<String> get collapsed => Set<String>.unmodifiable(_collapsed);

  /// Whether the section [id] is folded.
  bool isCollapsed(String id) => _collapsed.contains(id);

  /// Folds the section [id], or opens it when it is folded, and reports
  /// the new set to [onCollapsedChanged].
  void toggleSection(String id) {
    if (!_collapsed.remove(id)) {
      _collapsed.add(id);
    }
    notifyListeners();
    onCollapsedChanged?.call(<String>{..._collapsed});
  }

  /// Takes the folded sections persisted on this device (read after the
  /// view was built with the default). Does not report them back.
  void restoreCollapsed(Set<String> ids) {
    if (ids.length == _collapsed.length && _collapsed.containsAll(ids)) {
      return;
    }
    _collapsed
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }
}
