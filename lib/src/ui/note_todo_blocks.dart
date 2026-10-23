import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/todo_block_view.dart';

/// Draws the `todo` fences of the note at [notePath] as the lists of tasks
/// they ask for (#1152): the note's surfaces — read and `live` — put one in
/// their scope.
///
/// Two of them are the same while they stand for the same note and the same
/// tasks, so the scope does not tell its readers to draw again for a rebuild
/// that changed nothing.
@immutable
final class NoteTodoBlocks implements TodoBlockBuilder {
  /// The fences of the note at library-relative [notePath], over [host].
  const new({required this.host, required this.notePath});

  /// The tasks, and how to tick, edit and add one.
  final NoteTasksHost host;

  /// The note, library-relative.
  final String notePath;

  @override
  Widget build(
    BuildContext context, {
    required String source,
    required MarkdownTheme theme,
    void Function(int line)? onTapSource,
  }) => TodoBlockView(
    host: host,
    notePath: notePath,
    source: source,
    spacing: theme.blockSpacing,
    onTapSource: onTapSource,
  );

  @override
  bool operator ==(Object other) =>
      other is NoteTodoBlocks &&
      identical(other.host, host) &&
      other.notePath == notePath;

  @override
  int get hashCode => Object.hash(identityHashCode(host), notePath);
}
