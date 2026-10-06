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

/// [text] without the double quotes around it. Only `"` quotes in
/// Mermaid: an apostrophe is a letter (`Don't`, `l'utente`).
String unquoteMermaid(String text) {
  if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
    return text.substring(1, text.length - 1);
  }
  return text;
}

/// The named entities a label may write, by name.
const Map<String, String> _entities = {
  'nbsp': ' ',
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'hash': '#',
};

/// An entity: HTML's `&name;`, `&#38;`, `&#x26;`, or Mermaid's own `#38;`
/// and `#quot;`.
final RegExp _entity = RegExp(
  r'([&#])(?:#(\d{1,7})|#x([0-9a-fA-F]{1,6})|(\d{1,7})|([a-zA-Z]+));',
);

/// [text] with its entities written out: `&nbsp;` a no-break space,
/// `#quot;` a quote. One the engine does not know stays as written, and
/// Mermaid's `#` form takes a number or a name only, so `#12;` is the
/// character 12 but `&12;` is text.
String decodeMermaidEntities(String text) {
  if (!text.contains(';')) return text;
  return text.replaceAllMapped(_entity, (m) {
    final html = m.group(1) == '&';
    final String? decoded;
    if (m.group(2) != null && html) {
      decoded = _character(int.parse(m.group(2)!));
    } else if (m.group(3) != null && html) {
      decoded = _character(int.parse(m.group(3)!, radix: 16));
    } else if (m.group(4) != null && !html) {
      decoded = _character(int.parse(m.group(4)!));
    } else if (m.group(5) != null) {
      decoded = _entities[m.group(5)!.toLowerCase()];
    } else {
      decoded = null;
    }
    return decoded ?? m.group(0)!;
  });
}

String? _character(int code) =>
    code > 0 && code <= 0x10FFFF && (code < 0xD800 || code > 0xDFFF)
    ? String.fromCharCode(code)
    : null;

/// How many characters a line of wrapped text holds: a requirement's text,
/// a C4 element's description.
const int mermaidTextColumns = 36;

/// [text] broken at words into lines of [columns] characters, a word
/// longer than that on a line of its own. The parsers wrap by characters,
/// with no font to measure, so a long text makes a box taller rather than
/// wider whatever it is drawn at.
List<String> wrapMermaidText(String text, {int columns = mermaidTextColumns}) {
  final lines = <String>[];
  var line = '';
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    if (line.isNotEmpty && line.length + 1 + word.length > columns) {
      lines.add(line);
      line = word;
    } else {
      line = line.isEmpty ? word : '$line $word';
    }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines;
}
