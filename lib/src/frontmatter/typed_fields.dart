/// The typed view of a note's frontmatter that the fields panel edits (#157).
///
/// The block is YAML and stays YAML. This reads the same document
/// [parseFrontmatterBlock] does and classifies each top-level key by the type
/// YAML gave its value, so the panel can draw a checkbox for a boolean, a chip
/// list for a list, a date for a date. Nothing here writes the note: an edit
/// goes back through `edit.dart`'s `setFrontmatterKey`/`removeFrontmatterKey`,
/// which replace the named key's line and leave every other key, comment and
/// quoting exactly where the user wrote it. A field shown, touched and left
/// alone must leave the bytes identical — it is the whole reason the panel is a
/// view and not a store.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/frontmatter/yaml_scalar.dart';
import 'package:yaml/yaml.dart';

/// The type of a frontmatter field, as far as the panel can tell it apart.
///
/// The five are what YAML's own scalars and lists give ([loadYaml]): a `true`
/// is a boolean, a bare `2026-09-01` a date, a number a number, `[a, b]` a
/// list, everything else text. A nested mapping has no type here: no field row
/// draws one, and it is left to the raw source untouched.
enum FrontmatterFieldType {
  /// A scalar YAML reads as a string.
  text,

  /// An integer or a float.
  number,

  /// A YAML timestamp, or a `date:` string that parses as one.
  date,

  /// `true` or `false`.
  boolean,

  /// A YAML list of scalars.
  list,
}

/// One top-level key of a note's frontmatter, with the type its value has.
@immutable
final class FrontmatterField {
  /// Creates a field; [items] defaults to [values] (a field that did not
  /// come from a file).
  const new({
    required this.key,
    required this.type,
    this.values = const [],
    this._items,
  });

  /// The key, as it is written in the block.
  final String key;

  /// What the value is.
  final FrontmatterFieldType type;

  /// The values as text, as they are written: one for a scalar, one per
  /// item for a list. A number reads `1.10`, not `1.1`; a date keeps the
  /// offset it was written with.
  final List<String> values;

  final List<String>? _items;

  /// For a list, each item as the YAML it is written as, in a form that
  /// can stand inside `[a, b]`: `1` stays a number and `"1"` a string, so
  /// a list rewritten around an item leaves the others exactly what they
  /// were ([frontmatterListYaml]).
  List<String> get items => _items ?? values;

  /// The scalar value, or null when the field is empty or a list.
  String? get value => values.isEmpty ? null : values.first;
}

/// The typed fields of [source], the YAML inside the fences.
///
/// `error` is the parser's message when the block does not parse —
/// [parseFrontmatterBlock] is the arbiter — and `fields` is then empty, so a
/// block Niman refuses is shown raw rather than guessed at. A key whose value
/// is a nested mapping is left out of `fields`: no field row can show it, and
/// it stays in the raw source — and so is a list holding anything but plain
/// values (a mapping, a list, a null, an empty string): a row of chips could
/// not show it, and rewriting the list around a chip would drop it.
///
/// Values are shown as they are written, never as the parser normalized
/// them: a field opened and saved unchanged must leave the bytes identical.
({List<FrontmatterField> fields, String? error}) frontmatterFieldsIn(
  String source,
) {
  final parsed = parseFrontmatterBlock(source);
  if (parsed.error != null) {
    return (fields: const <FrontmatterField>[], error: parsed.error);
  }
  if (source.trim().isEmpty) {
    return (fields: const <FrontmatterField>[], error: null);
  }
  final doc = loadYamlNode(source);
  if (doc is! YamlMap) {
    return (fields: const <FrontmatterField>[], error: null);
  }
  final fields = <FrontmatterField>[];
  for (final MapEntry(:key, value: node) in doc.nodes.entries) {
    final name = key is YamlNode ? '${key.value}' : '$key';
    final field = _fieldOf(name, node);
    if (field != null) fields.add(field);
  }
  return (fields: fields, error: null);
}

/// One top-level entry as a field, or null when no row can show it (a nested
/// mapping, a null, an empty scalar, a list holding something other than
/// plain values).
FrontmatterField? _fieldOf(String key, YamlNode node) {
  if (node is YamlList) {
    final values = <String>[];
    final items = <String>[];
    for (final item in node.nodes) {
      final text = item is YamlScalar ? _scalarText(item) : null;
      if (text == null || text.isEmpty) return null;
      values.add(text);
      items.add(_flowItem(item as YamlScalar, text));
    }
    return FrontmatterField(
      key: key,
      type: FrontmatterFieldType.list,
      values: values,
      items: items,
    );
  }
  if (node is! YamlScalar) return null;
  final value = node.value;
  final text = _scalarText(node);
  if (text == null) return null;
  if (value is bool) {
    return FrontmatterField(
      key: key,
      type: FrontmatterFieldType.boolean,
      values: [text],
    );
  }
  if (value is num) {
    return FrontmatterField(
      key: key,
      type: FrontmatterFieldType.number,
      values: [text],
    );
  }
  if (text.isEmpty) return null;
  // A date under `date:` — plain or quoted — reads as a date, the way the
  // parser's own typed getter reads it; a date under any other key is text.
  final date =
      key.trim().toLowerCase() == 'date' && DateTime.tryParse(text) != null;
  return FrontmatterField(
    key: key,
    type: date ? FrontmatterFieldType.date : FrontmatterFieldType.text,
    values: [text],
  );
}

/// [scalar] as the panel shows it: a boolean as `true`/`false`, a number as
/// it is written (`1.10`, `007`), a string trimmed; null for a null.
String? _scalarText(YamlScalar scalar) {
  final value = scalar.value;
  if (value == null) return null;
  if (value is bool) return value ? 'true' : 'false';
  if (value is num) return scalar.span.text;
  return '$value'.trim();
}

/// [item], shown as [text], as YAML that stands as one item of `[a, b]`:
/// its own source when that reads back as the same value there (a number
/// stays a number, a quoted `"1"` a string), else [text] quoted as it must
/// be — an item of a block list may be plain with a comma in it
/// (`- Doe, J`), which a flow list would split.
String _flowItem(YamlScalar item, String text) {
  final source = item.span.text;
  final value = item.value;
  if (yamlReadsBack(source, (read) => read == value, inFlow: true)) {
    return source;
  }
  return yamlString(value is String ? value : text, inFlow: true);
}

/// The YAML literal for [values] of a field of [type]: what the panel writes
/// back and [loadYaml] reads again as the same type.
///
/// A list is `[a, b]` of [values] taken as text (a list read from a file is
/// written back with [frontmatterListYaml] instead, keeping each item's
/// YAML); a boolean is `true`/`false`; a number and a date are written as
/// typed; text is quoted only when YAML would read the plain form as
/// something else (a `true`, a number, a `#`). Nothing here reflows the rest
/// of the block — `setFrontmatterKey` puts this on the key's own line.
String frontmatterFieldYaml(FrontmatterFieldType type, List<String> values) {
  final first = values.isEmpty ? '' : values.first;
  return switch (type) {
    FrontmatterFieldType.boolean => _isTruthy(first) ? 'true' : 'false',
    FrontmatterFieldType.number =>
      yamlReadsBack(first.trim(), (value) => value is num)
          ? first.trim()
          : _yamlText(first),
    // A date is a string to YAML: written plain whenever it reads back so.
    FrontmatterFieldType.date => _yamlText(first),
    FrontmatterFieldType.list => _yamlList(values),
    FrontmatterFieldType.text => _yamlText(first),
  };
}

/// Whether [value] is one of YAML's spellings of true.
bool _isTruthy(String value) =>
    const {'true', 'yes', 'on', '1'}.contains(value.trim().toLowerCase());

/// [values] as a flow list, `[a, b]`, each item quoted as it needs to be to
/// stay one item.
String _yamlList(List<String> values) {
  final items = [for (final value in values) _yamlText(value, inFlow: true)];
  return '[${items.join(', ')}]';
}

/// [value], trimmed, as a YAML scalar that reads back as that same text:
/// plain when YAML reads the plain form so, quoted otherwise
/// ([yamlString] asks the parser). [inFlow] is for an item of `[a, b]`.
String _yamlText(String value, {bool inFlow = false}) =>
    yamlString(value.trim(), inFlow: inFlow);

/// [items] — each the YAML of one item, as [FrontmatterField.items] holds
/// them — as a flow list, `[a, b]`. The items are written as they are:
/// removing one chip rewrites the list around it and every other item
/// keeps the YAML it had.
String frontmatterListYaml(List<String> items) => '[${items.join(', ')}]';

/// The items typed into the list editor, [text], as the YAML of each item.
///
/// The editor shows a list's items as [FrontmatterField.items] joined by
/// `, ` — the inside of a flow list — so what comes back is read the same
/// way: `"Doe, J", x` is two items, the first holding its comma, and `1`
/// stays the number it was. Text YAML cannot read as a list of plain
/// values (an unclosed quote, `a: b`) is split at its commas instead, each
/// part a string.
List<String> frontmatterListItems(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const <String>[];
  try {
    final node = loadYamlNode('[$trimmed]');
    if (node is YamlList &&
        node.nodes.every(
          (item) =>
              item is YamlScalar &&
              item.value != null &&
              '${item.value}'.trim().isNotEmpty,
        )) {
      return [for (final item in node.nodes) item.span.text];
    }
  } on FormatException {
    // Not a flow list: split at the commas below.
  }
  return [
    for (final part in trimmed.split(','))
      if (part.trim().isNotEmpty) _yamlText(part, inFlow: true),
  ];
}
