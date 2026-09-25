/// The fence rules of the Markdown corrector (#72).
///
/// A fence is one line deciding that every line after it is code until a
/// line says otherwise. The language tag and the closing fence are the two
/// halves a writer gets wrong: `{.dart}` is a class, not a language, and a
/// fence left open swallows the rest of the note.
library;

/// A fence's opening line: up to three spaces, three or more backticks or
/// tildes, and the info string after them.
final RegExp _opening = RegExp(r'^(\s{0,3})(`{3,}|~{3,})(.*)$');

/// A line holding nothing but a fence's run: how a block closes.
final RegExp _closing = RegExp(r'^\s{0,3}(`{3,}|~{3,})\s*$');

/// A fenced block's lines: the fence's language tag normalized
/// ([language]) and the closing fence written when the note forgot it
/// ([closing]).
///
/// The language is the first word of the info string; the rest of the
/// string is metadata and is left as written. The closing fence is the
/// opener's own run, so a `~~~` block closes with `~~~`.
///
/// It goes at the end of the note, not where the code seems to stop: an
/// unclosed fence already runs to the end of the document for every
/// reader (CommonMark 4.5), so closing it there changes nothing about how
/// the note reads. Guessing an earlier end — at a heading, at a blank
/// line — would turn code into prose on a guess; a note that meant to
/// close sooner shows it, all code to the end, and the writer moves the
/// fence.
List<String> tidyFence(
  List<String> lines, {
  required bool language,
  required bool closing,
}) {
  if (lines.isEmpty) return lines;
  final open = _opening.firstMatch(lines.first);
  if (open == null) return lines;
  final fence = open.group(2)!;
  final out = <String>[
    if (language) _tagged(lines.first, open) else lines.first,
    ...lines.skip(1),
  ];
  if (closing && !_isClosed(out, fence)) {
    // The note's own trailing newlines are not the code's last line.
    while (out.isNotEmpty && out.last.trim().isEmpty) {
      out.removeLast();
    }
    out.add(fence);
  }
  return out;
}

/// The opening line with its language written the way GFM reads one: as
/// the info string's first word.
///
/// Only Pandoc's spelling is rewritten, since a GFM reader takes it for
/// another language: `{.dart}` is the class `.dart` in braces, and `.dart`
/// is a language whose name starts with a dot. The braces go and the class
/// loses its dot; the block's other attributes stay, as metadata after the
/// language (`{.dart .numberLines}` is `dart .numberLines`). Every other
/// first word is a language name as written, punctuation and all: `c++`,
/// `c#` and `objective-c` trimmed to their letters would name another
/// language, or none.
String _tagged(String line, RegExpMatch open) {
  final info = open.group(3)!;
  final text = info.trimLeft();
  final String cleaned;
  if (text.startsWith('{') && text.contains('}')) {
    final close = text.indexOf('}');
    final words = text.substring(1, close).trim().split(RegExp(r'\s+'));
    cleaned =
        [
          _undotted(words.first),
          ...words.skip(1),
        ].where((word) => word.isNotEmpty).join(' ') +
        text.substring(close + 1);
  } else if (text.startsWith('.')) {
    cleaned = _undotted(text);
  } else {
    return line;
  }
  // The fence run ends where the info string begins; the spaces between
  // them are the writer's, and stay.
  final head = line.substring(0, open.end - text.length);
  final tag = cleaned.trimLeft();
  return tag.isEmpty ? head.trimRight() : '$head$tag';
}

/// [text] without the dots in front of it: Pandoc's class `.dart` is the
/// language `dart`.
String _undotted(String text) {
  var start = 0;
  while (start < text.length && text.codeUnitAt(start) == 0x2E) {
    start++;
  }
  return text.substring(start);
}

/// Whether [lines] ends with a fence closing [fence]: the same character
/// and a run at least as long. The opening line is not a closer.
bool _isClosed(List<String> lines, String fence) {
  for (var at = lines.length - 1; at > 0; at--) {
    final last = lines[at];
    if (last.trim().isEmpty) continue;
    final close = _closing.firstMatch(last);
    return close != null &&
        close.group(1)!.codeUnitAt(0) == fence.codeUnitAt(0) &&
        close.group(1)!.length >= fence.length;
  }
  return false;
}
