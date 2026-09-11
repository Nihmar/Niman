/// The fields a template asks for before it makes a note (T-TPL-03).
///
/// `{{ask:Character name}}` is a box to type in; `{{ask:Name:Ada}}` is one
/// that starts with `Ada` in it. `{{choice:Faction:Crown,Rebels}}` is a
/// pick from a list. Both are answered once, in a single form shown
/// *before* the note exists — which is the whole reason they are not
/// editor tab stops: an answer has to be available in time to name the
/// file and pick the folder.
///
/// A label is the identity of a field. The same label twice is one
/// question, and its answer fills every occurrence — the body, the
/// frontmatter and the `niman:` directives alike.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/templates/engine.dart';

/// How a field is answered.
enum TemplateFieldKind {
  /// Typed into a box.
  text,

  /// Picked from a list the template wrote.
  choice,

  /// Picked from the library's notes.
  note,
}

/// The label of the field that answers `{{parent}}` (T-TPL-04).
///
/// Not a question the template wrote — the template only mentions
/// `{{parent}}` — so the shell adds it, and it is reserved: a
/// `{{ask:parent}}` would be answering the same thing twice.
const String parentFieldLabel = 'parent';

/// One question a template asks.
@immutable
final class TemplateField {
  /// Creates a field.
  const new({
    required this.label,
    required this.kind,
    this.hint = '',
    this.choices = const [],
    this.title,
  });

  /// What the field is called; also the key its answer is stored under.
  final String label;

  /// What the form calls it, when that is not [label].
  ///
  /// A template's own questions are shown under the label their author
  /// wrote. The one field the shell adds — the backlink — has a reserved
  /// label and a phrase of its own.
  final String? title;

  /// Whether it is typed or picked.
  final TemplateFieldKind kind;

  /// What a text field starts with, empty when the template said nothing.
  final String hint;

  /// The options of a choice field, in the order the template wrote them.
  final List<String> choices;

  /// What the form offers before the user touches anything: the hint for
  /// a text field, the first option for a choice.
  String get initial => switch (kind) {
    TemplateFieldKind.text || TemplateFieldKind.note => hint,
    TemplateFieldKind.choice => choices.isEmpty ? '' : choices.first,
  };

  /// The heading the form shows over the field.
  String get heading => title ?? label;

  @override
  bool operator ==(Object other) =>
      other is TemplateField &&
      other.label == label &&
      other.kind == kind &&
      other.hint == hint &&
      other.title == title &&
      other.choices.length == choices.length &&
      other.choices.indexed.every((e) => choices[e.$1] == e.$2);

  @override
  int get hashCode =>
      Object.hash(label, kind, hint, title, Object.hashAll(choices));
}

/// Every field [source] asks for, in the order it first mentions them.
///
/// Deduplicated by label, first mention winning: a template that writes
/// `{{ask:Name}}` in its filename and again in its heading is asking one
/// question, not two. A field with no label — `{{ask:}}` — is not a
/// question and is skipped, which leaves its placeholder standing in the
/// created note where the author can see the typo.
List<TemplateField> templateFields(String source) {
  final fields = <TemplateField>[];
  final seen = <String>{};
  for (final match in templatePlaceholder.allMatches(source)) {
    final parsed = parsePlaceholder(match.group(1)!);
    final kind = switch (parsed.name) {
      'ask' => TemplateFieldKind.text,
      'choice' => TemplateFieldKind.choice,
      _ => null,
    };
    if (kind == null) continue;
    final argument = parsed.argument;
    final label = fieldLabel(argument);
    if (label.isEmpty || !seen.add(label)) continue;
    final rest = _afterLabel(argument);
    fields.add(
      TemplateField(
        label: label,
        kind: kind,
        hint: kind == TemplateFieldKind.text ? rest : '',
        choices: kind == TemplateFieldKind.choice ? _options(rest) : const [],
      ),
    );
  }
  return fields;
}

/// Whatever the argument holds after the label: a hint, or a list of
/// options.
String _afterLabel(String? argument) {
  if (argument == null) return '';
  final colon = argument.indexOf(':');
  return colon < 0 ? '' : argument.substring(colon + 1).trim();
}

/// `Crown, Rebels , Neutral` as three options; blanks dropped.
List<String> _options(String rest) => [
  for (final option in rest.split(','))
    if (option.trim().isNotEmpty) option.trim(),
];
