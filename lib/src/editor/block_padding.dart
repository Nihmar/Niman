/// A block pasted in mid-text, kept apart from its neighbours (#1248).
library;

/// [block] as a paste puts it between [before] and [after] — the text just
/// before the selection and just after it, two characters each are enough:
/// on lines of its own, with a blank line between it and a line of text on
/// either side, since a table glued to a paragraph is read as the
/// paragraph's text. Where there is a blank line already, none is added.
String padBlock(String block, {required String before, required String after}) {
  final lead = switch (before.length) {
    0 => '',
    _ when !before.endsWith('\n') => '\n\n',
    1 => '',
    _ => before[before.length - 2] == '\n' ? '' : '\n',
  };
  final trail = switch (after.length) {
    0 => '',
    _ when after[0] != '\n' => '\n\n',
    1 => '',
    _ => after[1] == '\n' ? '' : '\n',
  };
  return '$lead$block$trail';
}
