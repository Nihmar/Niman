import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/templates/prompts.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks a template's questions, all of them at once (T-TPL-03).
///
/// Resolves to the answers keyed by label, or null when the user backs
/// out — in which case no note is created. One form rather than a chain
/// of dialogs: the questions belong to the same note, and answering the
/// third should not mean having answered the first two irreversibly.
/// [pickNote] answers a note field, resolving to the name to write or
/// null when nothing was picked; without it a note field is read-only.
///
/// [title] names the form (the template form's own by default); [sheet]
/// shows it as a bottom sheet rather than a dialog — a Home action on a
/// phone (#535).
Future<Map<String, String>?> showTemplateForm(
  BuildContext context, {
  required List<TemplateField> fields,
  Future<String?> Function()? pickNote,
  String? title,
  bool sheet = false,
}) {
  final form = _TemplateForm(
    fields: fields,
    pickNote: pickNote,
    title: title,
    sheet: sheet,
  );
  if (sheet) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => form,
    );
  }
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => form,
  );
}

final class _TemplateForm extends StatefulWidget {
  const new({
    required this.fields,
    required this.sheet,
    this.pickNote,
    this.title,
  });

  final List<TemplateField> fields;
  final Future<String?> Function()? pickNote;
  final String? title;
  final bool sheet;

  @override
  State<_TemplateForm> createState() => _TemplateFormState();
}

final class _TemplateFormState extends State<_TemplateForm> {
  /// One controller per text field, held for the life of the dialog so
  /// the exit animation does not rebuild over disposed ones.
  late final Map<String, TextEditingController> _typed = {
    for (final field in widget.fields)
      if (field.kind == TemplateFieldKind.text)
        field.label: TextEditingController(text: field.initial),
  };

  late final Map<String, String> _picked = {
    for (final field in widget.fields)
      if (field.kind != TemplateFieldKind.text) field.label: field.initial,
  };

  /// Opens the note picker for [field] and keeps what came back.
  Future<void> _pickNoteFor(TemplateField field) async {
    final pick = widget.pickNote;
    if (pick == null) return;
    final chosen = await pick();
    if (chosen == null || !mounted) return;
    setState(() => _picked[field.label] = chosen);
  }

  @override
  void dispose() {
    for (final controller in _typed.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, <String, String>{
      for (final field in widget.fields)
        field.label: switch (field.kind) {
          TemplateFieldKind.text => _typed[field.label]!.text.trim(),
          TemplateFieldKind.choice ||
          TemplateFieldKind.note => _picked[field.label] ?? '',
        },
    });
  }

  /// Puts [value] in [field]'s box: in place of what is there, or after
  /// it when what is there ends with a comma — a list being written.
  void _suggest(TemplateField field, String value) {
    final box = _typed[field.label]!;
    final text = box.text.trimRight();
    box.text = text.endsWith(',') ? '$text $value' : value;
    box.selection = TextSelection.collapsed(offset: box.text.length);
  }

  /// The suggestions under [field]'s box.
  Widget _suggestions(TemplateField field) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final value in field.suggestions)
          ActionChip(
            key: Key('template-suggestion-${field.label}-$value'),
            visualDensity: VisualDensity.compact,
            label: Text(value),
            onPressed: () => _suggest(field, value),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final title = Text(widget.title ?? AppStrings.templateFormTitle);
    final content = SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final field in widget.fields) ...[
            const SizedBox(height: 8),
            switch (field.kind) {
              TemplateFieldKind.text when field.suggestions.isNotEmpty =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: Key('template-field-${field.label}'),
                      controller: _typed[field.label],
                      autofocus: field == widget.fields.first,
                      decoration: InputDecoration(labelText: field.heading),
                      onSubmitted: (_) => _submit(),
                    ),
                    _suggestions(field),
                  ],
                ),
              TemplateFieldKind.text => TextField(
                key: Key('template-field-${field.label}'),
                controller: _typed[field.label],
                // Only the first one: raising the keyboard onto a form
                // of six fields hides the rest of them.
                autofocus: field == widget.fields.first,
                decoration: InputDecoration(labelText: field.heading),
                onSubmitted: (_) => _submit(),
              ),
              TemplateFieldKind.choice => DropdownButtonFormField<String>(
                key: Key('template-field-${field.label}'),
                initialValue: _picked[field.label],
                decoration: InputDecoration(labelText: field.heading),
                items: [
                  for (final option in field.choices)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: (value) => setState(() {
                  _picked[field.label] = value ?? '';
                }),
              ),
              // A note is picked from the library tree, not typed: the
              // link has to land on a note that is really there.
              TemplateFieldKind.note => ListTile(
                key: Key('template-field-${field.label}'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link),
                title: Text(field.heading),
                subtitle: Text(
                  (_picked[field.label] ?? '').isEmpty
                      ? AppStrings.templateFormNoNote
                      : _picked[field.label]!,
                ),
                trailing: (_picked[field.label] ?? '').isEmpty
                    ? null
                    : IconButton(
                        key: Key('template-field-clear-${field.label}'),
                        tooltip: AppStrings.actionClear,
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _picked[field.label] = ''),
                      ),
                onTap: widget.pickNote == null
                    ? null
                    : () => unawaited(_pickNoteFor(field)),
              ),
            },
          ],
        ],
      ),
    );
    final actions = [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppStrings.actionCancel),
      ),
      FilledButton(
        key: const Key('template-form-ok'),
        onPressed: _submit,
        child: Text(AppStrings.actionOk),
      ),
    ];
    if (!widget.sheet) {
      return AlertDialog(
        key: const Key('template-form'),
        title: title,
        content: content,
        actions: actions,
      );
    }
    // Lifted over the keyboard, which a sheet does not do on its own.
    return Padding(
      key: const Key('template-form'),
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.titleLarge,
            child: title,
          ),
          Flexible(child: content),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: actions,
          ),
        ],
      ),
    );
  }
}
