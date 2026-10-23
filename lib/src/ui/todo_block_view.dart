import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/todo/todo_block_parser.dart';
import 'package:niman/src/todo/todo_block_query.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/note_task_row.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/todo_block_parts.dart';
import 'package:niman/src/ui/todo_block_shown.dart';
import 'package:niman/src/ui/todo_block_text.dart';

/// A `todo` fence drawn as the list of tasks it asks for (#1152).
///
/// Its head says what it lists and how many; its rows are the note's own task
/// rows — a box that ticks, a tap that opens the task, a chip for each link —
/// and its foot is Add task, written out from the block's filters. A block
/// with an error shows the error instead of a list.
///
/// The block is read once for each source it is given and run again only when
/// the tasks change (the map, or the controller) or a note it names might
/// have: a keystroke elsewhere in the note costs this nothing. Drawing it
/// never writes the note.
final class TodoBlockView extends StatefulWidget {
  /// The list the fence whose body is [source] asks for, in the note at
  /// library-relative [notePath].
  const new({
    required this.host,
    required this.notePath,
    required this.source,
    this.spacing = 0,
    this.onTapSource,
    super.key,
  });

  /// The tasks, and how to tick, edit and add one.
  final NoteTasksHost host;

  /// The note the fence is in.
  final String notePath;

  /// The fence's body.
  final String source;

  /// The space the block keeps above and below it.
  final double spacing;

  /// Called with a line of [source] (1-based) to show the source again; null
  /// where there is none to show.
  final void Function(int line)? onTapSource;

  @override
  State<TodoBlockView> createState() => _TodoBlockViewState();
}

final class _TodoBlockViewState extends State<TodoBlockView> {
  late TodoBlock _block;
  ResolveResult? _named;
  TodoBlockShown? _shown;
  int _asked = 0;
  late Listenable _tasks;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(TodoBlockView old) {
    super.didUpdateWidget(old);
    if (old.host != widget.host ||
        old.notePath != widget.notePath ||
        old.source != widget.source) {
      _tasks.removeListener(_changed);
      _bind();
    }
  }

  void _bind() {
    _block = TodoBlock.parse(widget.source);
    _named = null;
    _shown = null;
    _tasks = Listenable.merge(<Listenable>[
      widget.host.map,
      widget.host.controller,
    ])..addListener(_changed);
    _resolve();
  }

  @override
  void dispose() {
    _tasks.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() => _shown = null);
    _resolve();
  }

  /// Asks the resolver which note `link: [[Note]]` names: the index can change
  /// under it (a note made or renamed), so it is asked again with the tasks.
  void _resolve() {
    final link = _block.query.link;
    if (link is! LinkNote) return;
    final asked = ++_asked;
    unawaited(
      widget.host.resolveNote(link.target, from: widget.notePath).then((
        result,
      ) {
        if (!mounted || asked != _asked) return;
        // The same answer as before is no change to draw.
        if (_sameAnswer(result, _named)) return;
        setState(() {
          _named = result;
          _shown = null;
        });
      }),
    );
  }

  static bool _sameAnswer(ResolveResult? a, ResolveResult? b) =>
      a is ResolvedNote && b is ResolvedNote
      ? a.note.path == b.note.path
      : a.runtimeType == b.runtimeType;

  TodoBlockShown _compute() {
    final host = widget.host;
    return _shown ??= TodoBlockShown.of(
      _block,
      snapshot: host.snapshot ?? const TodoSnapshot(todo: [], done: []),
      tasksFor: host.map.tasksFor,
      notePath: widget.notePath,
      today: host.today,
      named: _named,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _compute();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final failed = shown.block.hasErrors || shown.problem != null;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.spacing / 2),
      child: Material(
        key: const Key('todo-block'),
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: failed
                ? scheme.error.withValues(alpha: 0.55)
                : scheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TodoBlockHead(
              text: todoBlockHead(
                shown.block.query,
                count: failed ? null : shown.tasks.count,
              ),
              onTap: _tapSource(1),
            ),
            if (failed)
              ..._problems(shown)
            else if (shown.tasks.isEmpty)
              TodoBlockEmpty(onTap: _tapSource(1))
            else
              ..._rows(shown),
            TodoBlockFoot(onAdd: () => unawaited(_add(shown))),
          ],
        ),
      ),
    );
  }

  VoidCallback? _tapSource(int line) {
    final tap = widget.onTapSource;
    return tap == null ? null : () => tap(line);
  }

  List<Widget> _problems(TodoBlockShown shown) => <Widget>[
    for (final error in shown.block.errors)
      TodoBlockProblem(
        text: todoBlockErrorText(error),
        line: error.line,
        onTap: _tapSource(error.line),
      ),
    if (shown.problem case final problem?)
      TodoBlockProblem(
        text: problem,
        line: shown.block.linkLine,
        onTap: _tapSource(shown.block.linkLine),
      ),
  ];

  List<Widget> _rows(TodoBlockShown shown) {
    final host = widget.host;
    final today = host.today;
    Widget row(TodoEntry entry, {required bool done}) => NoteTaskRow(
      // A row is a line of one file: a tick moves the task to the other.
      key: ValueKey('${done ? 'done' : 'open'}|${entry.lineIndex}'),
      entry: entry,
      done: done,
      notePath: shown.subject,
      today: today,
      links: host.links,
      onToggle: (_) => unawaited(host.toggle(entry, done: done)),
      onEdit: () => unawaited(host.edit(context, entry, done: done)),
    );
    return <Widget>[
      for (final entry in shown.tasks.open) row(entry, done: false),
      for (final entry in shown.tasks.done) row(entry, done: true),
    ];
  }

  /// Opens the task dialog with what the block's filters would give a task:
  /// the link to the note the list is about, then the `+project`, `@context`
  /// and `#tag` it filters by.
  Future<void> _add(TodoBlockShown shown) async {
    final host = widget.host;
    final subject = shown.subject;
    final words = <String>[
      if (subject != null) await host.linkTo(subject),
      ...shown.block.query.tokens,
    ];
    // The dialog opens with the caret at the start: what is typed lands before
    // these as a word of its own, and the dialog's trim takes the space off
    // when nothing is typed.
    await host.addTask(words.isEmpty ? '' : ' ${words.join(' ')}');
  }
}
