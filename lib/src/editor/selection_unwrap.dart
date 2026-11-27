import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'package:niman/src/editor/md_editing.dart' show MarkdownEdit;

/// The edit that takes the [left] and [right] markers off [selection] of
/// [text], when it is wrapped in them already — what a second press of Bold,
/// Italic, Strike and the other wrapping buttons does (#1340) — or null when
/// it is not.
///
/// A selection is wrapped when the markers are inside it (`**a**` selected, as
/// a double click on a bold word leaves it) or right outside it (`a` selected
/// in `**a**`); a caret, when the run of non-blank characters around it is
/// wrapped (`**a|b**`). What stays selected is the text the markers held.
///
/// A marker that is one character repeated — `*`, `**`, `~~`, `==` — is
/// counted by its run, the way Markdown reads it: `**a**` is bold and not
/// italic, and `***a***` is both, so Italic over the first wraps it again and
/// over the second takes one `*` off each side.
MarkdownEdit? unwrapSelection({
  required String text,
  required TextSelection selection,
  required String left,
  required String right,
}) {
  var start = selection.start;
  var end = selection.end;
  final caret = start;
  if (selection.isCollapsed) {
    // The run of non-blank characters the caret is in.
    while (start > 0 && !_blank(text.codeUnitAt(start - 1))) {
      start--;
    }
    while (end < text.length && !_blank(text.codeUnitAt(end))) {
      end++;
    }
    if (start == end) return null;
    final inner = _inside(text, start, end, left, right);
    if (inner == null) return null;
    final held = inner.end - inner.start;
    final at = math.min(math.max(caret - left.length, start), start + held);
    return MarkdownEdit(
      text: text.replaceRange(
        start,
        end,
        text.substring(inner.start, inner.end),
      ),
      selection: TextSelection.collapsed(offset: at),
    );
  }
  final inner = _inside(text, start, end, left, right);
  if (inner != null) {
    final held = text.substring(inner.start, inner.end);
    return MarkdownEdit(
      text: text.replaceRange(start, end, held),
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + held.length,
      ),
    );
  }
  final outside = _around(text, start, end, left, right);
  if (outside == null) return null;
  return MarkdownEdit(
    text: text
        .replaceRange(end, end + outside.after, '')
        .replaceRange(start - outside.before, start, ''),
    selection: TextSelection(
      baseOffset: start - outside.before,
      extentOffset: end - outside.before,
    ),
  );
}

/// Whether [unit] is a space, a tab or a line break.
bool _blank(int unit) =>
    unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D;

/// The bounds of what the markers hold, when `[start, end)` of [text] opens
/// with [left] and closes with [right]; null when it does not.
({int start, int end})? _inside(
  String text,
  int start,
  int end,
  String left,
  String right,
) {
  if (end - start < left.length + right.length) return null;
  if (!text.startsWith(left, start) ||
      !text.startsWith(right, end - right.length)) {
    return null;
  }
  final repeated = _repeated(left, right);
  if (repeated == null) {
    return (start: start + left.length, end: end - right.length);
  }
  // Counted by the run: how many of the character the stretch starts with and
  // ends with, which are the markers and whatever else is stacked on them.
  final run = _runAt(text, start, end, repeated, forward: true);
  final back = _runAt(text, start, end, repeated, forward: false);
  if (run == end - start) return null;
  final count = math.min(run, back);
  if (!_wrapped(count, left.length)) return null;
  return (start: start + left.length, end: end - right.length);
}

/// How many characters before and after `[start, end)` are the markers, when
/// they stand right outside it; null when they do not.
({int before, int after})? _around(
  String text,
  int start,
  int end,
  String left,
  String right,
) {
  if (start < left.length || end + right.length > text.length) return null;
  if (!text.startsWith(left, start - left.length) ||
      !text.startsWith(right, end)) {
    return null;
  }
  final repeated = _repeated(left, right);
  if (repeated != null) {
    final before = _runBefore(text, start, repeated);
    final after = _runAfter(text, end, repeated);
    if (!_wrapped(math.min(before, after), left.length)) return null;
  }
  return (before: left.length, after: right.length);
}

/// The one character [left] and [right] both repeat, or null.
String? _repeated(String left, String right) {
  if (left.isEmpty || left != right) return null;
  final unit = left[0];
  return left == unit * left.length ? unit : null;
}

/// Whether a run of [count] marker characters holds a marker [width] long: a
/// single `*` is italic in a run of one or three, a `**` is bold from two up.
bool _wrapped(int count, int width) =>
    width == 1 ? count.isOdd : count >= width;

/// The length of the run of [unit] at the start (or [forward] false: the end)
/// of `[start, end)`.
int _runAt(
  String text,
  int start,
  int end,
  String unit, {
  required bool forward,
}) {
  var run = 0;
  while (start + run < end &&
      text[forward ? start + run : end - 1 - run] == unit) {
    run++;
  }
  return run;
}

/// The run of [unit] that ends right before [at].
int _runBefore(String text, int at, String unit) {
  var run = 0;
  while (at - 1 - run >= 0 && text[at - 1 - run] == unit) {
    run++;
  }
  return run;
}

/// The run of [unit] that starts at [at].
int _runAfter(String text, int at, String unit) {
  var run = 0;
  while (at + run < text.length && text[at + run] == unit) {
    run++;
  }
  return run;
}
