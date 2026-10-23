/// The notes offered while a `[[` link is typed in a task's text (#1152).
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/ui/todo_link_query.dart';

/// What one row writes into the link.
enum TodoLinkRowKind {
  /// A note: its shortest name that resolves to it alone.
  note,

  /// A heading of the note typed before the `#`.
  heading,

  /// A block id of that note, after `#^`.
  block,
}

/// One row of the list under the field.
@immutable
final class TodoLinkRow {
  /// A row that shows [title] and, dimmed, [detail], and writes [text].
  const new({
    required this.kind,
    required this.title,
    required this.text,
    this.detail = '',
  });

  /// What it completes.
  final TodoLinkRowKind kind;

  /// The name shown: a note's, a heading, a block's id.
  final String title;

  /// Dimmed beside it: a note's folder, a block's first words.
  final String detail;

  /// What it writes: the note's target, the heading, `^id`.
  final String text;
}

/// The list under a task's text field while a `[[` link is being typed: it
/// follows the field, asks the library's [WikilinkSuggester] — the one the
/// editor's wikilink panel uses — and writes the link the editor would
/// write, the shortest name that resolves to the note.
///
/// The field's owner calls [edited] after every edit, which is what opens the
/// list (a caret moved into a link already written only follows it); a
/// listener on the field closes the list when the caret leaves the link. The
/// list's keys are [handleKey]'s: ↑ and ↓ move, `Enter` and `Tab` insert,
/// `Esc` closes, and with no list up a key is the field's own.
final class TodoLinkSuggestions extends ChangeNotifier {
  /// The suggestions for the text in [_field], listing what [_suggester]
  /// answers; null from it offers nothing.
  new(this._field, this._suggester) {
    _field.addListener(_followCaret);
  }

  final TextEditingController _field;
  final WikilinkSuggester? Function() _suggester;

  /// How many rows are listed at once.
  static const int rowLimit = 8;

  TodoLinkQuery? _query;
  List<TodoLinkRow> _rows = const <TodoLinkRow>[];
  int _selected = 0;
  int _seq = 0;
  bool _disposed = false;
  bool _justPicked = false;

  /// The rows listed, best first; empty while no list is up.
  List<TodoLinkRow> get rows => _rows;

  /// The row the keys act on.
  int get selected => _selected;

  /// Whether a list is up.
  bool get isOpen => _rows.isNotEmpty;

  /// Whether a row was picked in this very frame: a desktop sends the line
  /// break of the `Enter` that picked it as text after the key, which a field
  /// that submits on it must not take for its own.
  bool get justPicked => _justPicked;

  /// The field was edited: a `[[` link at the caret opens, or filters, the
  /// list.
  void edited() => _refresh(typed: true);

  void _followCaret() {
    if (_query == null) return;
    _refresh(typed: false);
  }

  void _refresh({required bool typed}) {
    if (_disposed) return;
    final suggester = _suggester();
    final value = _field.value;
    final query = suggester == null
        ? null
        : TodoLinkQuery.at(value.text, value.selection.extentOffset);
    if (query == null) {
      close();
      return;
    }
    final open = _query;
    if (open != null && open.sameText(query)) {
      // The same link, the caret somewhere else in it: the rows stay.
      _query = query;
      return;
    }
    if (!typed && open == null) return;
    unawaited(_ask(query, suggester!, ++_seq));
  }

  Future<void> _ask(
    TodoLinkQuery query,
    WikilinkSuggester suggester,
    int seq,
  ) async {
    List<TodoLinkRow> rows;
    try {
      rows = await _rowsOf(query, suggester);
    } on Object {
      rows = const <TodoLinkRow>[];
    }
    // A newer edit asked again while this was read: its answer is the one.
    if (_disposed || seq != _seq) return;
    _query = rows.isEmpty ? null : query;
    _rows = rows;
    _selected = 0;
    notifyListeners();
  }

  Future<List<TodoLinkRow>> _rowsOf(
    TodoLinkQuery query,
    WikilinkSuggester suggester,
  ) async {
    final match = query.matchText.toLowerCase();
    if (!query.hasHash) {
      return [
        for (final note in await suggester.notes(query.target))
          TodoLinkRow(
            kind: TodoLinkRowKind.note,
            title: note.name,
            detail: note.folder,
            text: note.target,
          ),
      ].take(rowLimit).toList();
    }
    // Headings and blocks are a note's: with none named there are none.
    final target = query.target.trim();
    if (target.isEmpty) return const <TodoLinkRow>[];
    if (query.isBlock) {
      return [
        for (final block in await suggester.blocks(target))
          if (block.id.toLowerCase().contains(match))
            TodoLinkRow(
              kind: TodoLinkRowKind.block,
              title: '^${block.id}',
              detail: block.excerpt,
              text: '^${block.id}',
            ),
      ].take(rowLimit).toList();
    }
    final headings =
        <String>[
          for (final heading in await suggester.headings(target))
            if (heading.heading.toLowerCase().contains(match)) heading.heading,
        ]..sort((a, b) {
          final x = a.toLowerCase().startsWith(match) ? 0 : 1;
          final y = b.toLowerCase().startsWith(match) ? 0 : 1;
          return x - y;
        });
    return [
      for (final heading in headings.take(rowLimit))
        TodoLinkRow(
          kind: TodoLinkRowKind.heading,
          title: heading,
          text: heading,
        ),
    ];
  }

  /// Moves the picked row by [delta], wrapping.
  void move(int delta) {
    if (!isOpen) return;
    _selected = (_selected + delta) % _rows.length;
    notifyListeners();
  }

  /// Closes the list, and forgets a read under way.
  void close() {
    _seq++;
    final was = _rows.isNotEmpty;
    _query = null;
    _rows = const <TodoLinkRow>[];
    _selected = 0;
    if (was && !_disposed) notifyListeners();
  }

  /// Writes the row at [index] into the field and closes the list. The field
  /// keeps its focus; the caret lands past the link.
  void pick(int index) {
    final query = _query;
    if (query == null || index < 0 || index >= _rows.length) return;
    final row = _rows[index];
    final from = switch (row.kind) {
      TodoLinkRowKind.note => query.start,
      TodoLinkRowKind.heading => query.levelAt,
      TodoLinkRowKind.block => query.hashAt,
    };
    close();
    _justPicked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _justPicked = false);
    _field.value = query.complete(_field.value, from, row.text);
  }

  /// The keys of the list while it is up: ↑ and ↓ move, `Enter` and `Tab`
  /// insert, `Esc` closes. Any other key, and every key with no list up, is
  /// ignored, to be the field's.
  KeyEventResult handleKey(KeyEvent event) {
    if (!isOpen || event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      move(-1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab) {
      if (event is KeyDownEvent) pick(_selected);
    } else if (key == LogicalKeyboardKey.escape) {
      close();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _disposed = true;
    _seq++;
    _field.removeListener(_followCaret);
    super.dispose();
  }
}
