/// Writing one YAML scalar so that it reads back as exactly what it was
/// given: the values the frontmatter panel writes (#157) and the keys the
/// line edits of `edit.dart` add.
///
/// Whether the plain form is safe is YAML's call, not a list of characters
/// kept here: the plain form is loaded back and kept only when YAML reads it
/// as the same value. A hand-kept list missed a trailing `:` (`Todo:` broke
/// the whole block), a comma inside a flow list (`Doe, J` became two items)
/// and a line break (a multi-line value lost its newline and left a line at
/// column 0 behind). Asking the parser cannot miss what the parser itself
/// would misread.
library;

import 'package:yaml/yaml.dart';

/// [text] as a YAML value that reads back as the string [text]: plain when
/// YAML reads the plain form that way, double-quoted otherwise.
///
/// [inFlow] asks for an item of a flow list (`[a, b]`), where a comma or a
/// bracket ends a plain scalar that would be whole anywhere else.
String yamlString(String text, {bool inFlow = false}) =>
    yamlReadsBack(text, (value) => value == text, inFlow: inFlow)
    ? text
    : yamlDoubleQuoted(text);

/// Whether [literal], written as a mapping's value — or, with [inFlow], as
/// the one item of a flow list — loads back as a single value [accepts]
/// takes. A literal YAML refuses, or reads as more than one value, is not.
bool yamlReadsBack(
  String literal,
  bool Function(Object? value) accepts, {
  bool inFlow = false,
}) {
  // An empty plain scalar is YAML's null, never an empty string.
  if (literal.isEmpty) return false;
  try {
    final doc = loadYaml(inFlow ? 'k: [$literal]' : 'k: $literal');
    if (doc is! Map || doc.length != 1 || !doc.containsKey('k')) return false;
    final value = doc['k'];
    if (!inFlow) return accepts(value);
    return value is List && value.length == 1 && accepts(value.first);
  } on FormatException {
    return false;
  }
}

/// [key] as a YAML mapping key that reads back as the string [key]: plain
/// when it can be, double-quoted otherwise (`due: date`, `#tag`, `123`).
String yamlKey(String key) {
  try {
    final doc = loadYaml('$key: x');
    if (doc is Map && doc.length == 1 && doc.keys.first == key) return key;
  } on FormatException {
    // Not a plain key: quoted below.
  }
  return yamlDoubleQuoted(key);
}

/// [text] as a double-quoted YAML scalar, every character that is not
/// itself inside the quotes escaped: a line break is `\n`, so the value
/// stays on its key's line and keeps the break it holds.
String yamlDoubleQuoted(String text) {
  final out = StringBuffer('"');
  for (final rune in text.runes) {
    switch (rune) {
      case 0x5C:
        out.write(r'\\');
      case 0x22:
        out.write(r'\"');
      case 0x0A:
        out.write(r'\n');
      case 0x0D:
        out.write(r'\r');
      case 0x09:
        out.write(r'\t');
      case 0x85:
        out.write(r'\N');
      case 0x2028:
        out.write(r'\L');
      case 0x2029:
        out.write(r'\P');
      default:
        if (rune < 0x20 || rune == 0x7F) {
          out.write('\\x${rune.toRadixString(16).padLeft(2, '0')}');
        } else {
          out.writeCharCode(rune);
        }
    }
  }
  out.write('"');
  return out.toString();
}
