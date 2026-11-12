/// How much room the note's top row has (#1266): a narrow pane's row —
/// a tablet's, beside the tree — keeps its controls' icons and drops their
/// labels, so its ⋮ stays in the row.
library;

import 'package:flutter/widgets.dart';

/// Tells the note's top row's controls whether their labels fit.
final class NoteTopBarRoom extends InheritedWidget {
  /// Says to [child] whether the row is [roomy].
  const new({required this.roomy, required super.child, super.key});

  /// Whether the row has the room for the labels.
  final bool roomy;

  /// Whether the row around [context] has the room for labels: yes outside
  /// one.
  static bool roomyAt(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NoteTopBarRoom>()?.roomy ??
      true;

  @override
  bool updateShouldNotify(NoteTopBarRoom oldWidget) => roomy != oldWidget.roomy;
}
