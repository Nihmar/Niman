/// The template commands, as the editor sees them: which `{{…}}` the
/// engine answers, and where they stand in a line, for the source mode to
/// colour them apart from the Markdown around them.
///
/// Only the commands the engine knows: a placeholder it does not know is
/// left standing in the note it makes (`engine.dart`), and left plain in
/// the editor, so a typo reads as one before the template is used.
library;

import 'package:niman/src/templates/engine.dart';

/// The names of the placeholders the engine answers: `engine.dart`'s and
/// `{{include:…}}` (`includes.dart`).
const Set<String> templateCommandNames = {
  'title',
  'date',
  'time',
  'now',
  'uuid',
  'counter',
  'cursor',
  'ask',
  'choice',
  'parent',
  'folder',
  'clipboard',
  'selection',
  'include',
};

/// Whether [body], the inside of a `{{…}}`, names a command the engine
/// answers, whatever its argument and filters.
bool isTemplateCommand(String body) =>
    templateCommandNames.contains(parsePlaceholder(body).name);

/// The template commands of [line], each as its start and end offsets,
/// braces included, in order.
List<(int, int)> templateCommandsIn(String line) {
  if (!line.contains('{{')) return const [];
  return [
    for (final match in templatePlaceholder.allMatches(line))
      if (isTemplateCommand(match.group(1)!)) (match.start, match.end),
  ];
}
