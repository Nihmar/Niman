/// A line of a `todo` block that cannot be read (#1152).
library;

import 'package:meta/meta.dart';

/// What is wrong with a line.
enum TodoBlockErrorKind {
  /// No `:` to split a key from its value.
  noColon,

  /// A key the block does not know.
  unknownKey,

  /// A known key with nothing after it.
  missingValue,

  /// A value the key cannot read.
  badValue,

  /// A key given twice that takes one value.
  repeatedKey,
}

/// What each key takes, as it is written: syntax, not words, so the same in
/// every language.
const Map<String, String> todoBlockExpected = <String, String>{
  'link': 'this, any, [[Note]]',
  'project': 'house',
  'context': 'phone',
  'tag': 'urgent',
  'due': 'today, overdue, <=+7d, 2026-11-02, 2026-11-01..2026-11-07',
  'priority': 'A, A-C',
  'done': 'no, yes, all',
  'sort': 'due, priority, file',
};

/// One problem in a block, on one of its lines.
@immutable
final class TodoBlockError {
  /// A [kind] problem on line [line] (1-based, in the block), about [key] and
  /// [value] as written.
  const new({
    required this.kind,
    required this.line,
    this.key = '',
    this.value = '',
    this.suggestion,
  });

  /// What is wrong.
  final TodoBlockErrorKind kind;

  /// The line, counted from the first line inside the fence.
  final int line;

  /// The key as written (the whole line for [TodoBlockErrorKind.noColon]).
  final String key;

  /// The value as written.
  final String value;

  /// For an unknown key, the known one it is probably a typo of.
  final String? suggestion;

  /// What the key takes, as a hint after a bad value; empty for an unknown
  /// key.
  String get expected => todoBlockExpected[key.toLowerCase()] ?? '';
}
