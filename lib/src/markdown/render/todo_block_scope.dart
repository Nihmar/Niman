/// How a note's `todo` fence is drawn as the list of tasks it asks for
/// (#1152).
///
/// The renderer knows the fence and nothing of tasks: what draws the list is
/// handed in by whoever owns them, through this scope, the way the note's
/// links are. A surface with no scope — a card's text, a preview — shows the
/// fence as the code it is on disk.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';

/// Draws the fences named `todo`.
abstract interface class TodoBlockBuilder {
  /// The list the fence whose body is [source] asks for, or null to leave
  /// the fence as the code it is.
  ///
  /// [onTapSource] is called with a line of the block's body (1-based) to
  /// show its source again: `live` puts the caret there. Null in the read
  /// view, which has no source to show.
  Widget? build(
    BuildContext context, {
    required String source,
    required MarkdownTheme theme,
    void Function(int line)? onTapSource,
  });
}

/// The [TodoBlockBuilder] a note's surfaces draw `todo` fences with.
final class TodoBlockScope extends InheritedWidget {
  /// A scope over [child] drawing with [builder]; null draws no fence as a
  /// list.
  const new({required this.builder, required super.child, super.key});

  /// What draws the fences, or null.
  final TodoBlockBuilder? builder;

  /// The builder of the nearest scope, or null; the caller is rebuilt when
  /// it changes.
  static TodoBlockBuilder? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TodoBlockScope>()?.builder;

  @override
  bool updateShouldNotify(TodoBlockScope oldWidget) =>
      builder != oldWidget.builder;
}
