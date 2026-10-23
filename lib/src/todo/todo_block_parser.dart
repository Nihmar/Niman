/// Reading the body of a `todo` fence (#1152).
library;

import 'package:meta/meta.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/todo/todo_block_due.dart';
import 'package:niman/src/todo/todo_block_error.dart';
import 'package:niman/src/todo/todo_block_keys.dart';
import 'package:niman/src/todo/todo_block_query.dart';

/// A block read: the query its good lines make, and the lines that are not.
///
/// A block with any [errors] lists no tasks: a half-read filter would show a
/// list that looks right. The query is still what the good lines say, for the
/// head to tell what the block asks.
@immutable
final class TodoBlock {
  /// A block of [query] and [errors].
  const new({
    required this.query,
    this.errors = const <TodoBlockError>[],
    this.linkLine = 0,
  });

  /// Reads the body of a fence, [source], one `key: value` to a line.
  ///
  /// Blank lines and the spaces round a line are ignored. Keys are read in
  /// any case.
  factory parse(String source) => _Reader(source).read();

  /// What the lines ask for.
  final TodoBlockQuery query;

  /// The lines that could not be read, in order.
  final List<TodoBlockError> errors;

  /// The line `link:` is on (1-based), or 0 when the block has none: where a
  /// note it names that is not there is pointed at.
  final int linkLine;

  /// Whether some line could not be read.
  bool get hasErrors => errors.isNotEmpty;
}

/// The keys that may be given again, each adding a name to match.
const Set<String> _repeatable = <String>{'project', 'context', 'tag'};

final class _Reader {
  new(this.source);

  final String source;
  final List<TodoBlockError> errors = <TodoBlockError>[];
  final Set<String> seen = <String>{};

  TodoBlockLink link = const LinkThis();
  int linkLine = 0;
  final List<String> projects = <String>[];
  final List<String> contexts = <String>[];
  final List<String> tags = <String>[];
  TodoBlockDue? due;
  String? priorityFrom;
  String? priorityTo;
  TodoBlockDone done = TodoBlockDone.no;
  TodoBlockSort sort = TodoBlockSort.due;

  TodoBlock read() {
    final lines = source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final text = lines[i].trim();
      if (text.isNotEmpty) _line(i + 1, text);
    }
    return TodoBlock(
      query: TodoBlockQuery(
        link: link,
        projects: projects,
        contexts: contexts,
        tags: tags,
        due: due,
        priorityFrom: priorityFrom,
        priorityTo: priorityTo,
        done: done,
        sort: sort,
      ),
      errors: errors,
      linkLine: linkLine,
    );
  }

  void _line(int n, String text) {
    final colon = text.indexOf(':');
    if (colon < 0) {
      errors.add(
        TodoBlockError(kind: TodoBlockErrorKind.noColon, line: n, key: text),
      );
      return;
    }
    final written = text.substring(0, colon).trim();
    final key = written.toLowerCase();
    final value = text.substring(colon + 1).trim();
    if (!todoBlockKeys.contains(key)) {
      errors.add(
        TodoBlockError(
          kind: TodoBlockErrorKind.unknownKey,
          line: n,
          key: written,
          suggestion: nearestTodoBlockKey(written),
        ),
      );
      return;
    }
    void fail(TodoBlockErrorKind kind) =>
        errors.add(TodoBlockError(kind: kind, line: n, key: key, value: value));
    if (value.isEmpty) {
      fail(TodoBlockErrorKind.missingValue);
    } else if (!_repeatable.contains(key) && !seen.add(key)) {
      fail(TodoBlockErrorKind.repeatedKey);
    } else if (!_take(key, value)) {
      fail(TodoBlockErrorKind.badValue);
    } else if (key == 'link') {
      linkLine = n;
    }
  }

  /// Takes [value] for [key]; false when the key cannot read it.
  bool _take(String key, String value) {
    switch (key) {
      case 'link':
        return _link(value);
      case 'project':
        return _token(projects, '+', value);
      case 'context':
        return _token(contexts, '@', value);
      case 'tag':
        return _token(tags, '#', value);
      case 'due':
        final read = TodoBlockDue.parse(value);
        if (read != null) due = read;
        return read != null;
      case 'priority':
        return _priority(value);
      case 'done':
        final read = _named(TodoBlockDone.values, value);
        if (read != null) done = read;
        return read != null;
      default:
        final read = _named(TodoBlockSort.values, value);
        if (read != null) sort = read;
        return read != null;
    }
  }

  bool _link(String value) {
    switch (value.toLowerCase()) {
      case 'this':
        link = const LinkThis();
        return true;
      case 'any':
        link = const LinkAny();
        return true;
    }
    if (!value.startsWith('[[') || !value.endsWith(']]')) return false;
    final target = parseWikiRef(value.substring(2, value.length - 2)).target;
    if (target.isEmpty) return false;
    link = LinkNote(target);
    return true;
  }

  /// A project, context or tag, with or without its [sigil].
  bool _token(List<String> into, String sigil, String value) {
    final name = value.startsWith(sigil) ? value.substring(1) : value;
    if (name.isEmpty || RegExp(r'[\s+@#]').hasMatch(name)) return false;
    into.add(name);
    return true;
  }

  bool _priority(String value) {
    final match = RegExp(r'^([A-Za-z])(?:\s*-\s*([A-Za-z]))?$')
        .firstMatch(value);
    if (match == null) return false;
    final from = match.group(1)!.toUpperCase();
    final to = (match.group(2) ?? from).toUpperCase();
    if (to.compareTo(from) < 0) return false;
    priorityFrom = from;
    priorityTo = to;
    return true;
  }

  static T? _named<T extends Enum>(List<T> values, String value) {
    final word = value.toLowerCase();
    for (final candidate in values) {
      if (candidate.name == word) return candidate;
    }
    return null;
  }
}
