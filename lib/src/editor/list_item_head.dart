/// The head of a list item: everything on the line before its content.
///
/// What Enter needs in order to carry a list on (#142): the indent to
/// keep, the marker to repeat or count on, and whether the writer is
/// standing on an item with nothing in it — which is how every editor
/// spells "I am done with this list".
final class ListItemHead {
  /// Creates a head; use [listItemHead], not this constructor.
  const new({
    required this.indent,
    required this.marker,
    required this.content,
    this.number,
    this.box = false,
  });

  /// The item's leading whitespace, kept by the line that follows.
  final String indent;

  /// The marker as written: `-`, `*`, `+`, or `3.` / `3)`.
  final String marker;

  /// The item's number, for an ordered item; null for a bulleted one.
  final int? number;

  /// Whether the item carries a task box.
  final bool box;

  /// What the item says, after the marker and the box.
  final String content;

  /// Whether the item is empty — marker, maybe a box, and nothing else.
  bool get isEmpty => content.trim().isEmpty;

  /// What a line continuing this item starts with.
  ///
  /// An ordered item counts on, because a writer numbering by hand
  /// expects the next number even though Markdown renumbers for them. A
  /// ticked item does not pass its tick along: a new item is a new
  /// thing to do.
  String get continuation {
    final number = this.number;
    final next = number == null
        ? marker
        : '${number + 1}${marker[marker.length - 1]}';
    return '$indent$next ${box ? '[ ] ' : ''}';
  }
}

/// A list marker at the start of a line, with the task box that may
/// follow it.
final RegExp _listItem = RegExp(
  r'^([ \t]*)([-*+]|(\d{1,9})([.)]))[ \t]+(\[[ xX]\][ \t]+)?(.*)$',
);

/// A list item with a marker and nothing after it (`- `, `1.`), which
/// the pattern above cannot match because it wants the space.
final RegExp _bareListItem = RegExp(r'^([ \t]*)([-*+]|(\d{1,9})([.)]))[ \t]*$');

/// A task box's state character, anywhere a list marker is followed by one:
/// the space of `- [ ] `, the `x` of `- [x] `, without needing the trailing
/// space `_listItem` wants — behind any quote marks the line opens with, each
/// `>` with up to three spaces before it and one after.
final RegExp _taskBoxState = RegExp(
  r'^(?: {0,3}> ?)*[ \t]*(?:[-*+]|\d{1,9}[.)])[ \t]+\[([ xX])\]',
);

/// The offset of the state character of the task box on [line] — the space
/// of `- [ ] `, the `x` of `- [x] ` — or null when the line is not a task
/// item.
///
/// The line's quote marks are passed over: a task item in a quote or a
/// callout has its box behind them, and every caller — the read view's tick,
/// the checklist cascade — hands over the raw line.
///
/// Line-local, like [listItemHead]: the caller knows whether the line is
/// inside a code fence.
int? taskBoxOffset(String line) {
  final match = _taskBoxState.firstMatch(line);
  if (match == null) return null;
  // The box's `[` is the only bracket the pattern can match, so its
  // offset inside the match is where the state character sits, minus one.
  return match.start + match[0]!.indexOf('[') + 1;
}

/// The head of the list item on [line], or null when it is not one.
///
/// Line-local on purpose: the caller knows whether the line is inside a
/// code fence, and this does not.
ListItemHead? listItemHead(String line) {
  final match = _listItem.firstMatch(line) ?? _bareListItem.firstMatch(line);
  if (match == null) return null;
  final digits = match.group(3);
  return ListItemHead(
    indent: match.group(1)!,
    marker: match.group(2)!,
    number: digits == null ? null : int.tryParse(digits),
    box: match.groupCount >= 5 && match.group(5) != null,
    content: match.groupCount >= 6 ? match.group(6) ?? '' : '',
  );
}
