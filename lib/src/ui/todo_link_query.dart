/// The `[[` link being typed in a task's text, and the edit that completes it
/// (#1152): the dialog's and the quick-add field's, the same reading of the
/// link as the note editor's wikilink panel.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/services.dart';

/// A wikilink being typed: where it starts, where the part being completed
/// ends, and what is written of it.
@immutable
final class TodoLinkQuery {
  const new _({
    required this.start,
    required this.end,
    required this.closeAt,
    required this.target,
    required this.heading,
    required this.hasHash,
  });

  /// The link the [caret] of [text] sits inside, or null when it sits inside
  /// none: a `[[` before it with no `]]` between the two, and no `|` (which
  /// starts the words shown, not the target). An embed (`![[`) is not a link
  /// to a note and completes nothing.
  ///
  /// A link already closed after the caret has the rest of what is completed
  /// there too: the target runs on to a `#`, a `|` or the `]]`, a heading to
  /// a `|` or the `]]`.
  static TodoLinkQuery? at(String text, int caret) {
    if (caret < 2 || caret > text.length) return null;
    final open = text.lastIndexOf('[[', caret - 2);
    if (open < 0) return null;
    if (open > 0 && text.codeUnitAt(open - 1) == 0x21) return null;
    final close = text.indexOf(']]', open + 2);
    if (close != -1 && close < caret) return null;
    final content = text.substring(open + 2, caret);
    if (content.contains('|') || content.contains('\n')) return null;
    final hash = content.indexOf('#');
    var end = caret;
    var closeAt = -1;
    final reopen = text.indexOf('[[', caret);
    if (close != -1 && (reopen == -1 || reopen > close)) {
      closeAt = close;
      end = close;
      for (final stop in hash == -1 ? const ['#', '|'] : const ['|']) {
        var found = text.indexOf(stop, caret);
        // A `\|` is the separator whole: its backslash is not the target's.
        if (found > caret &&
            stop == '|' &&
            text.codeUnitAt(found - 1) == 0x5C) {
          found--;
        }
        if (found != -1 && found < end) end = found;
      }
    }
    return TodoLinkQuery._(
      start: open + 2,
      end: end,
      closeAt: closeAt,
      target: hash == -1 ? content : content.substring(0, hash),
      heading: hash == -1 ? '' : content.substring(hash + 1),
      hasHash: hash != -1,
    );
  }

  /// The offset just past the `[[`: where a note's name is written.
  final int start;

  /// Where the part being completed ends: the caret in a link still open,
  /// the `#`, `|` or `]]` that ends it in a link closed after the caret.
  final int end;

  /// Where the link's closing `]]` stands, or -1 while it has none.
  final int closeAt;

  /// The note's name as typed, before any `#`.
  final String target;

  /// What follows the `#`: a heading path, or a block id after `#^`.
  final String heading;

  /// Whether a `#` was typed.
  final bool hasHash;

  /// Whether a block id is being typed (`#^`).
  bool get isBlock => hasHash && heading.startsWith('^');

  /// The offset just past the `#`, where a heading or a block id is written.
  int get hashAt => start + target.length + 1;

  /// The offset just past the last `#`: where the level of a heading path
  /// being typed (`A#B`) starts.
  int get levelAt => hashAt + heading.lastIndexOf('#') + 1;

  /// What the rows are matched against: the name typed, the last level of a
  /// heading path, the id after `#^`.
  String get matchText {
    if (!hasHash) return target.trim();
    if (isBlock) return heading.substring(1).trim();
    return heading.substring(heading.lastIndexOf('#') + 1).trim();
  }

  /// Whether [other] names the same link text, however the caret moved.
  bool sameText(TodoLinkQuery other) =>
      target == other.target &&
      heading == other.heading &&
      hasHash == other.hasHash;

  /// [value] with what this query completes — from [from] to its end —
  /// replaced by [text], and the `]]` written after it when the link has none.
  /// The caret lands past the link.
  TextEditingValue complete(TextEditingValue value, int from, String text) {
    final closed = closeAt >= 0;
    final insert = closed ? text : '$text]]';
    final shift = text.length - (end - from);
    return TextEditingValue(
      text: value.text.replaceRange(from, end, insert),
      selection: TextSelection.collapsed(
        offset: closed ? closeAt + shift + 2 : from + insert.length,
      ),
    );
  }
}
