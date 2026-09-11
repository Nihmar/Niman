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
Future<Map<String, String>?> showTemplateForm(
  BuildContext context, {
  required List<TemplateField> fields,
  Future<String?> Function()? pickNote,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => _TemplateForm(fields: fields, pickNote: pickNote),
  );
}

final class _TemplateForm extends StatefulWidget {
  const new({required this.fields, this.pickNote});

  final List<TemplateField> fields;
  final Future<String?> Function()? pickNote;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('template-form'),
      title: Text(AppStrings.templateFormTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final field in widget.fields) ...[
              const SizedBox(height: 8),
              switch (field.kind) {
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('template-form-ok'),
          onPressed: _submit,
          child: Text(AppStrings.actionOk),
        ),
      ],
    );
  }
}
