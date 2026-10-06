/// The delimiter stack and the emphasis it makes: `cmark`'s
/// `process_emphasis` (the spec's appendix, "Processing emphasis"), with
/// GFM's strikethrough, whose two runs must be as long as each other.
library;

import 'package:niman/src/markdown/inline/delimiter.dart';
import 'package:niman/src/markdown/inline/inline_build.dart';

/// The runs of `*`, `_` and `~` not matched yet, top last.
final class DelimiterStack {
  /// The delimiter on top, or null when the stack is empty.
  Delimiter? last;

  /// Pushes [delimiter].
  void push(Delimiter delimiter) {
    delimiter.previous = last;
    last?.next = delimiter;
    last = delimiter;
  }

  /// Takes [delimiter] off the stack, wherever it is.
  void remove(Delimiter delimiter) {
    final previous = delimiter.previous;
    final next = delimiter.next;
    previous?.next = next;
    if (next == null) {
      last = previous;
    } else {
      next.previous = previous;
    }
    delimiter
      ..previous = null
      ..next = null;
  }

  /// Matches the delimiters above [bottom] into emphasis, strong emphasis
  /// and strikethroughs, and takes them all off the stack.
  void process(Delimiter? bottom) {
    // The lowest opener worth looking at, by the closer's character,
    // whether it can open, and its length mod 3: below it, a search for
    // that closer already failed.
    final openersBottom = <int, Delimiter?>{};
    var closer = last;
    while (closer != null && !identical(closer.previous, bottom)) {
      closer = closer.previous;
    }
    while (closer != null) {
      final current = closer;
      if (!current.canClose) {
        closer = current.next;
        continue;
      }
      final key =
          current.char * 6 + (current.canOpen ? 3 : 0) + current.original % 3;
      final floor = openersBottom.containsKey(key)
          ? openersBottom[key]
          : bottom;
      var opener = current.previous;
      var found = false;
      while (opener != null &&
          !identical(opener, bottom) &&
          !identical(opener, floor)) {
        if (opener.canOpen && opener.char == current.char) {
          if (current.char == 0x7E) {
            if (opener.count == current.count) {
              found = true;
              break;
            }
          } else {
            final odd =
                (current.canOpen || opener.canClose) &&
                (opener.original + current.original) % 3 == 0 &&
                !(opener.original % 3 == 0 && current.original % 3 == 0);
            if (!odd) {
              found = true;
              break;
            }
          }
        }
        opener = opener.previous;
      }
      if (found) {
        closer = _insert(opener!, current);
        continue;
      }
      openersBottom[key] = current.previous;
      closer = current.next;
      if (!current.canOpen) remove(current);
    }
    while (last != null && !identical(last, bottom)) {
      remove(last!);
    }
  }

  /// Makes the node [opener] and [closer] delimit, and returns the
  /// delimiter to go on from.
  Delimiter? _insert(Delimiter opener, Delimiter closer) {
    final tilde = closer.char == 0x7E;
    final use = tilde
        ? closer.count
        : (closer.count >= 2 && opener.count >= 2 ? 2 : 1);
    final open = opener.node;
    final close = closer.node;
    opener.count -= use;
    closer.count -= use;
    open
      ..text = open.text.substring(0, open.text.length - use)
      ..end -= use;
    final start = open.end;
    close
      ..text = close.text.substring(use)
      ..start += use;
    final made = InlineBuild(
      tilde
          ? InlineKind.strikethrough
          : use == 1
          ? InlineKind.emphasis
          : InlineKind.strong,
      start: start,
      end: close.start,
    )..wrapBetween(open, close);
    // The delimiters between the two are text now.
    for (
      var between = closer.previous;
      between != null && !identical(between, opener);
    ) {
      final below = between.previous;
      remove(between);
      between = below;
    }
    if (opener.count == 0) {
      open.unlink();
      remove(opener);
    }
    if (closer.count == 0) {
      close.unlink();
      final next = closer.next;
      remove(closer);
      return next;
    }
    assert(identical(made.next, close), 'the closer follows the emphasis');
    return closer;
  }
}
