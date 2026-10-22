/// The line ending most of [text]'s lines end with: `\r\n` when more of its
/// terminated lines end in `\r\n` than in a bare `\n`, else `\n`.
String lineEndingOf(String text) {
  var crlf = 0;
  var lf = 0;
  var at = text.indexOf('\n');
  while (at >= 0) {
    if (at > 0 && text.codeUnitAt(at - 1) == 0x0D) {
      crlf++;
    } else {
      lf++;
    }
    at = text.indexOf('\n', at + 1);
  }
  return crlf > lf ? '\r\n' : '\n';
}
