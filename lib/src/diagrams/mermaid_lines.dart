/// What every Mermaid diagram's source shares before and around its own
/// syntax (#530): a front matter at the top, `%%` comments and `%%{…}%%`
/// directives anywhere. One reading of them, so the dispatcher and each
/// parser agree on where a diagram starts.
library;

import 'package:niman/src/diagrams/mermaid_error.dart';

/// The index of the first line of [lines] that is the diagram's own — its
/// header — past a `---` front matter, blank lines, comments and
/// directives; [lines].length when there is none.
///
/// Throws a [MermaidParseException] on line 1 when the front matter is
/// never closed.
int mermaidBodyStart(List<String> lines) {
  var index = 0;
  if (lines.isNotEmpty && lines.first.trim() == '---') {
    index = 1;
    while (index < lines.length && lines[index].trim() != '---') {
      index++;
    }
    if (index >= lines.length) {
      throw const MermaidParseException(1, 'unterminated frontmatter');
    }
    index++;
  }
  while (index < lines.length &&
      stripMermaidComment(lines[index]).trim().isEmpty) {
    index++;
  }
  return index;
}

/// [line] without its `%%` comment (a `%%{…}%%` directive is one too); a
/// `%%` inside double quotes is text.
String stripMermaidComment(String line) {
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      quoted = !quoted;
    } else if (!quoted && line.startsWith('%%', i)) {
      return line.substring(0, i);
    }
  }
  return line;
}
