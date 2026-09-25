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

/// The opening line with its language cleaned: the first word of the info
/// string keeps its leading and trailing alphanumerics only, so `{.dart}`
/// becomes `dart` and `dart-ish` is left alone. The rest of the info
/// string — the metadata after that first word — is kept as written.
String _tagged(String line, RegExpMatch open) {
  final info = open.group(3)!;
  final word = RegExp(r'\S+').firstMatch(info);
  if (word == null) return line;
  final written = word.group(0)!;
  final cleaned = _alphanumeric(written);
  if (cleaned == written) return line;
  // The fence run ends where the info string begins.
  final head = open.end - info.length;
  final before = line.substring(0, head) + info.substring(0, word.start);
  final after = info.substring(word.end);
  if (cleaned.isEmpty) {
    return after.isEmpty ? before.trimRight() : '$before${after.trimLeft()}';
  }
  return '$before$cleaned$after';
}

/// [word] without the characters at its ends that are not letters or
/// digits: `{.dart}` is `dart`, `--` is nothing.
String _alphanumeric(String word) {
  var start = 0;
  var end = word.length;
  while (start < end && !_isAlphanumeric(word.codeUnitAt(start))) {
    start++;
  }
  while (end > start && !_isAlphanumeric(word.codeUnitAt(end - 1))) {
    end--;
  }
  return word.substring(start, end);
}

bool _isAlphanumeric(int unit) =>
    (unit >= 0x30 && unit <= 0x39) ||
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A);

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
