import 'package:flutter/foundation.dart';
import 'package:niman/src/workspace/workspace_tab.dart';

/// One pane of the workspace (issue #23): its tabs, in order, and which
/// of them is showing.
@immutable
final class WorkspacePane {
  /// A pane holding [tabs], showing the one at [active].
  ///
  /// [active] is -1 exactly when [tabs] is empty.
  const new({this.tabs = const [], this.active = -1})
    : assert(active >= -1, 'active is a tab, or -1 for an empty pane');

  /// A pane holding [tabs], showing [active] — clamped, so a caller
  /// removing tabs never has to work out the edge cases itself.
  factory clamped(List<WorkspaceTab> tabs, int active) => tabs.isEmpty
      ? WorkspacePane.empty
      : WorkspacePane(
          tabs: List.unmodifiable(tabs),
          active: active.clamp(0, tabs.length - 1),
        );

  /// A pane with nothing open.
  static const WorkspacePane empty = WorkspacePane();

  /// The pane's tabs, left to right.
  final List<WorkspaceTab> tabs;

  /// The index of the tab showing, or -1 when there is none.
  final int active;

  /// The tab showing, or null for an empty pane.
  WorkspaceTab? get activeTab => active < 0 ? null : tabs[active];

  /// Whether nothing is open in it.
  bool get isEmpty => tabs.isEmpty;

  /// The index of [path]'s tab, or -1.
  int indexOf(String path) => tabs.indexWhere((t) => t.path == path);

  @override
  bool operator ==(Object other) =>
      other is WorkspacePane &&
      other.active == active &&
      listEquals(other.tabs, tabs);

  @override
  int get hashCode => Object.hash(active, Object.hashAll(tabs));

  @override
  String toString() => 'WorkspacePane($active of $tabs)';
}
