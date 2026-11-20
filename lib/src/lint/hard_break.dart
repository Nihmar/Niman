/// A hard line break at the end of a source line.
library;

/// Whether [line] ends in a hard break: two spaces, or a backslash that
/// escapes none. The `\r` a line may end with is not part of it.
bool endsInHardBreak(String line) {
  final text = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
  if (text.endsWith('  ')) return true;
  var slashes = 0;
  while (slashes < text.length &&
      text.codeUnitAt(text.length - 1 - slashes) == 0x5C) {
    slashes++;
  }
  return slashes.isOdd;
}
