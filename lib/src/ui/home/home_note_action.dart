/// A Home action's new note (#535): its template, its folder and its
/// fields, each fixed in advance or asked when the button is pressed — in
/// one form, then the note is made the way a template's always is.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/frontmatter/typed_fields.dart';
import 'package:niman/src/frontmatter/yaml_scalar.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/templates/directives.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/templates/prompts.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/shell_template_flow.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/template_form.dart';

/// The label the note's name is asked under: one no template can write,
/// so it never meets a template's own question.
const String homeNameLabel = 'niman:name';

/// How many values a field's suggestions hold.
const int _suggestions = 8;

/// Makes the note [action] describes, through [templates].
///
/// A fixed value answers the template's question of the same label, or
/// else fills that frontmatter key; it may hold template commands
/// (`{{date}}`) and questions of its own (`{{ask:Topic}}`). An asked
/// field is a question with the values the library already holds for its
/// key as suggestions. With nothing to ask, no form shows.
Future<void> makeHomeNote(
  BuildContext context,
  HomeAction action, {
  required LibrarySession controller,
  required ShellTemplateFlow templates,
}) async {
  final source = await controller.templateSource;
  final templateFolder = await source?.folder ?? '';
  if (!context.mounted) return;
  var template = '';
  if (action.template case final path?) {
    final read = await templates.readTemplate(context, path, templateFolder);
    if (read == null || !context.mounted) return;
    template = read;
  }
  final fixed = {
    for (final MapEntry(:key, :value) in action.fields.entries)
      key: ?value.fixed,
  };
  final asked = [
    for (final MapEntry(:key, :value) in action.fields.entries)
      if (value.asks) key,
  ];
  final own = templates.questionsOf(template);
  final ownLabels = {for (final f in own) f.label};
  final namesItself =
      template.isNotEmpty &&
      readTemplateDirectives(
        template,
        context: TemplateContext.empty,
      ).namesItself;
  final fields = await _questions(
    controller,
    own: [
      for (final f in own)
        if (!fixed.containsKey(f.label)) f,
    ],
    fixed: [...fixed.values, ?action.name.fixed],
    asked: asked,
    askName: !namesItself && action.name.asks,
  );
  var answers = <String, String>{};
  if (fields.isNotEmpty) {
    if (!context.mounted) return;
    final given = await showTemplateForm(
      context,
      fields: fields,
      pickNote: () => templates.pickBacklinkNote(context),
      title: homeActionLabel(action),
      sheet: MediaQuery.sizeOf(context).width < wideBreakpoint,
    );
    if (given == null) return;
    answers = given;
  }
  final String? name;
  if (namesItself) {
    name = null;
  } else {
    final written = switch (action.name.fixed) {
      final pattern? => applyTemplate(pattern, title: '', answers: answers),
      null => answers[homeNameLabel] ?? '',
    }.trim();
    name = written.isEmpty ? AppStrings.newNoteTitle : written;
  }
  answers.remove(homeNameLabel);
  final rendered = {
    for (final MapEntry(:key, :value) in fixed.entries)
      key: applyTemplate(value, title: name ?? '', answers: answers),
  };
  final templateAnswers = {
    ...answers,
    for (final MapEntry(:key, :value) in rendered.entries)
      if (ownLabels.contains(key)) key: value,
  };
  final frontmatter = {
    for (final MapEntry(:key, :value) in rendered.entries)
      if (!ownLabels.contains(key)) key: _fieldYaml(key, value),
    for (final key in asked)
      if (!ownLabels.contains(key) && (answers[key] ?? '').isNotEmpty)
        key: _fieldYaml(key, answers[key]!),
  };
  final surroundings = await templates.surroundingsOf(
    template,
    templateAnswers,
  );
  if (!context.mounted) return;
  final folder = action.folder ?? '';
  await templates.file(
    context,
    template: template,
    answers: templateAnswers,
    surroundings: surroundings,
    name: name,
    folder: folder,
    folderWins: folder.isNotEmpty,
    templateName: action.template ?? homeActionLabel(action),
    frontmatter: frontmatter,
    open: action.open,
  );
}

/// The form's questions, each once, in the order a person reads them: the
/// name, the template's own, those inside fixed values, the asked fields.
Future<List<TemplateField>> _questions(
  LibrarySession controller, {
  required List<TemplateField> own,
  required List<String> fixed,
  required List<String> asked,
  required bool askName,
}) async {
  final fields = <TemplateField>[
    if (askName)
      TemplateField(
        label: homeNameLabel,
        title: AppStrings.homeActionNoteName,
        kind: TemplateFieldKind.text,
      ),
    ...own,
    for (final value in fixed) ...templateFields(value),
  ];
  final seen = <String>{};
  final out = [
    for (final f in fields)
      if (seen.add(f.label)) f,
  ];
  final values = await controller.fieldSource;
  for (final key in asked) {
    if (!seen.add(key)) continue;
    out.add(
      TemplateField(
        label: key,
        kind: TemplateFieldKind.text,
        suggestions:
            await values?.topValues(key, limit: _suggestions) ?? const [],
      ),
    );
  }
  return out;
}

/// [value] as the YAML of [key] in the new note (#683): `tags` a list, its
/// items split at the commas the form joins chips with; anything else as
/// typed when YAML reads it as one value — `3`, `false`, a date, `[a, b]`
/// stay what they are — and as text otherwise.
String _fieldYaml(String key, String value) {
  var text = value.trim();
  if (key == 'tags') {
    if (text.startsWith('[') && text.endsWith(']')) {
      text = text.substring(1, text.length - 1);
    }
    return frontmatterListYaml(frontmatterListItems(text));
  }
  // A string read back must be the text itself, or YAML cut something:
  // `Issue #42` reads as `Issue`, the rest a comment (#693). A value the
  // user quoted is YAML of its own, kept as written (`"007"`).
  final quoted = RegExp(r'''^(".*"|'.*')$''').hasMatch(text);
  final typed =
      !text.contains('\n') &&
      yamlReadsBack(
        text,
        (read) =>
            read != null &&
            read is! Map &&
            (read is! String || read == text || quoted),
      );
  return typed ? text : yamlString(text);
}
