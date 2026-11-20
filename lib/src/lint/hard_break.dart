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

/// [line] without the hard break it ends in — its trailing spaces, or the
/// backslash — and as it is when it ends in none. The `\r` stays.
String withoutHardBreak(String line) {
  if (!endsInHardBreak(line)) return line;
  final cr = line.endsWith('\r');
  final text = cr ? line.substring(0, line.length - 1) : line;
  final kept = text.endsWith('  ')
      ? text.trimRight()
      : text.substring(0, text.length - 1);
  return cr ? '$kept\r' : kept;
}
