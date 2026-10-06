/// GFM's task list item marker: the box a list item's paragraph may start
/// with (the GFM spec's task list items, `cmark-gfm`'s `tasklist.c`).
library;

/// Reads a task box.
abstract final class TaskBox {
  /// The box [text] — an item's first paragraph, as the inline parser is
  /// given it — starts with: `[ ]`, `[x]` or `[X]`, then white space or the
  /// end of the line. Whether it is ticked, and how much of [text] it
  /// takes: the white space after it on its line, and the line ending; null
  /// when there is none.
  ///
  /// A box the line ends at is one: `- [ ]` is an empty task, as GitHub
  /// draws it — `cmark` reads every line with its line ending, and the
  /// white space a box needs after it may be that ending, which the box
  /// then takes with it (`- [ ]` / `  foo` is a task of `foo`).
  static ({bool checked, int length})? of(String text) {
    if (text.length < 3 ||
        text.codeUnitAt(0) != 0x5B ||
        text.codeUnitAt(2) != 0x5D) {
      return null;
    }
    final state = text.codeUnitAt(1);
    if (state != 0x20 && state != 0x78 && state != 0x58) return null;
    var end = 3;
    while (end < text.length &&
        (text.codeUnitAt(end) == 0x20 || text.codeUnitAt(end) == 0x09)) {
      end++;
    }
    if (end < text.length && text.codeUnitAt(end) == 0x0A) {
      end++;
    } else if (end == 3 && end < text.length) {
      return null;
    }
    return (checked: state != 0x20, length: end);
  }
}
