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
  /// Creates a field.
  const new({required this.key, required this.type, this.values = const []});

  /// The key, as it is written in the block.
  final String key;

  /// What the value is.
  final FrontmatterFieldType type;

  /// The values as text: one for a scalar, one per item for a list.
  final List<String> values;

  /// The scalar value, or null when the field is empty or a list.
  String? get value => values.isEmpty ? null : values.first;
}

/// The typed fields of [source], the YAML inside the fences.
///
/// `error` is the parser's message when the block does not parse —
/// [parseFrontmatterBlock] is the arbiter — and `fields` is then empty, so a
/// block Niman refuses is shown raw rather than guessed at. A key whose value
/// is a nested mapping is left out of `fields`: no field row can show it, and
/// it stays in the raw source.
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
  final doc = loadYaml(source);
  if (doc is! Map) {
    return (fields: const <FrontmatterField>[], error: null);
  }
  final fields = <FrontmatterField>[];
  for (final entry in doc.entries) {
    final field = _fieldOf(entry.key.toString(), entry.value);
    if (field != null) fields.add(field);
  }
  return (fields: fields, error: null);
}

/// One top-level entry as a field, or null when no row can show it (a nested
/// mapping, a null, an empty scalar).
FrontmatterField? _fieldOf(String key, Object? value) {
  if (value == null) return null;
  if (value is bool) {
    return FrontmatterField(
      key: key,
      type: FrontmatterFieldType.boolean,
      values: [if (value) 'true' else 'false'],
    );
  }
  if (value is num) {
    return FrontmatterField(
      key: key,
      type: FrontmatterFieldType.number,
      values: [value.toString()],
    );
  }
  if (value is DateTime) {
    return FrontmatterField(
      key: key,
      type: FrontmatterFieldType.date,
      values: [_isoText(value)],
    );
  }
  if (value is List) {
    final values = <String>[];
    for (final item in value) {
      final text = _itemText(item);
      if (text.isNotEmpty) values.add(text);
    }
    return FrontmatterField(
      key: key,
      type: FrontmatterFieldType.list,
      values: values,
    );
  }
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return null;
    // A quoted date under `date:` reads as a date, the way the parser's own
    // typed getter reads it; a quoted date under any other key is text.
    final date = key.trim().toLowerCase() == 'date'
        ? DateTime.tryParse(text)
        : null;
    return FrontmatterField(
      key: key,
      type: date == null
          ? FrontmatterFieldType.text
          : FrontmatterFieldType.date,
      values: [if (date == null) text else _isoText(date)],
    );
  }
  return null;
}

/// One list item as text, or an empty string for an item no row can show.
String _itemText(Object? value) {
  if (value == null) return '';
  if (value is bool) return value ? 'true' : 'false';
  if (value is num) return value.toString();
  if (value is DateTime) return _isoText(value);
  if (value is Map || value is List) return '';
  return value.toString().trim();
}

/// The YAML literal for [values] of a field of [type]: what the panel writes
/// back and [loadYaml] reads again as the same type.
///
/// A list is `[a, b]`; a boolean is `true`/`false`; a number and a date are
/// written as typed; text is quoted only when YAML would read the plain form as
/// something else (a `true`, a number, a `#`). Nothing here reflows the rest of
/// the block — `setFrontmatterKey` puts this on the key's own line.
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

/// A date as YAML writes it: `2026-03-01` at midnight, the timestamp
/// otherwise — the same shape the parser stores.
String _isoText(DateTime value) {
  final iso = value.toIso8601String();
  final midnight =
      value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0;
  return midnight ? iso.substring(0, 10) : iso;
}
