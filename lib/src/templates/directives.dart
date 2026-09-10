/// What a template says about the note it makes (T-TPL-02).
///
/// Placeholders produce text where they stand. Where the note goes, what
/// it is called and how it opens are not text: they are instructions
/// about the file, and writing them inline would leave a line in every
/// note that then had to be deleted. So they live in a `copist:` mapping
/// in the template's own frontmatter, which is read, obeyed and removed —
/// the created note keeps the rest of the frontmatter and never sees this
/// key.
///
/// ```yaml
/// ---
/// copist:
///   folder: Journal/{{date:YYYY}}/{{date:MM}}
///   filename: "{{date:YYYY-MM-DD}}"
///   append: true
///   open: editor
/// tags: [journal]
/// ---
/// ```
///
/// Every value is substituted before it is read, so a path can be built
/// from a date with no nesting problem: the placeholders are gone by the
/// time the path is a path.
library;

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/frontmatter/edit.dart';
import 'package:copist/src/frontmatter/parser.dart';
import 'package:copist/src/templates/engine.dart';
import 'package:meta/meta.dart';

/// The frontmatter key the directives live under.
const String directivesKey = 'copist';

/// What happens to the note once it exists.
enum TemplateOpen {
  /// Open it in the editor (the default, and what creating a note has
  /// always done).
  editor,

  /// Open it showing the preview.
  preview,

  /// Leave it closed: the template filed something away, and the user
  /// was in the middle of something else.
  none,
}

/// The `copist:` block of a template, read and typed.
@immutable
final class TemplateDirectives {
  /// Creates a set of directives; every one is optional.
  const new({
    this.folder,
    this.filename,
    this.append = false,
    this.open = TemplateOpen.editor,
  });

  /// A template that says nothing: the note is created where the user
  /// was, under the name they typed, and opens in the editor.
  static const TemplateDirectives none = TemplateDirectives();

  /// Where the note goes (library-relative), or null to use the folder
  /// the creation started from. Created if it does not exist.
  final String? folder;

  /// What the note is called, without the `.md`, or null to ask.
  final String? filename;

  /// Whether a note that is already there is added to rather than
  /// uniquified into a second file. This is what makes a daily note *a*
  /// daily note instead of `Daily 2.md`.
  final bool append;

  /// What happens once the note exists.
  final TemplateOpen open;

  /// Whether the template named the note itself, so there is nothing to
  /// ask the user.
  bool get namesItself => filename != null && filename!.isNotEmpty;
}

/// The directives of [source], with their placeholders substituted.
///
/// [title] is what `{{title}}` means while the directives are read. It is
/// empty on the first read — the point of that read is to find out
/// whether the template names the note itself, which is what decides
/// whether a name is asked for at all.
TemplateDirectives readTemplateDirectives(
  String source, {
  String title = '',
  DateTime? now,
  Map<String, String>? answers,
  TemplateContext? context,
}) {
  final parsed = parseFrontmatter(source);
  if (parsed == null || parsed.error != null) return TemplateDirectives.none;
  String? value(String key) {
    final raw = parsed.first('$directivesKey.$key');
    if (raw == null) return null;
    final rendered = applyTemplate(
      raw,
      title: title,
      now: now,
      answers: answers,
      context: context,
    ).trim();
    return rendered.isEmpty ? null : rendered;
  }

  final folder = value('folder');
  return TemplateDirectives(
    // The same sanitizing the folder settings get: the value came out of
    // a file a person edits, so `../` and stray slashes are input.
    folder: folder == null ? null : cleanFolderPath(folder, ''),
    filename: switch (value('filename')) {
      final name? => sanitizeName(_withoutExtension(name), fallback: ''),
      null => null,
    },
    append: value('append')?.toLowerCase() == 'true',
    open: switch (value('open')?.toLowerCase()) {
      'preview' => TemplateOpen.preview,
      'none' => TemplateOpen.none,
      _ => TemplateOpen.editor,
    },
  );
}

/// [source] as the created note: placeholders substituted, `copist:`
/// gone.
///
/// The block is removed after substitution rather than before, so a
/// directive can hold a placeholder without the removal having to
/// understand one.
String renderTemplate(
  String source, {
  required String title,
  DateTime? now,
  String Function()? uuid,
  Map<String, String>? answers,
  TemplateContext? context,
}) => removeFrontmatterKey(
  applyTemplate(
    source,
    title: title,
    now: now,
    uuid: uuid,
    answers: answers,
    context: context,
  ),
  directivesKey,
);

/// `Daily.md` written in a `filename:` means `Daily`; the app adds the
/// extension, and a template that spells it out should not get `.md.md`.
String _withoutExtension(String name) =>
    isMarkdownNote(name) ? name.substring(0, name.length - 3) : name;
