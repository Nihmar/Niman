/// The editor behind the frontmatter fields panel (#157): a key, a type and a
/// value, for adding a field or changing one.
///
/// The answer is plain data — a key, a type and the values — and the panel
/// turns it into the YAML the file gets (`frontmatterFieldYaml`). A list's
/// values are its items' own YAML, shown and read as the inside of a flow
/// list (`frontmatterListItems`), so an item holding a comma stays one item.
/// The key is fixed when an existing field is edited: renaming a key is an
/// edit of its own the panel does not make. Each type gets the input it
/// deserves: a switch for a boolean, and for a date the platform's own picker
/// rather than a string that happens to parse as one — the answer comes back
/// as the `YYYY-MM-DD` the parser reads as a date again.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/frontmatter/typed_fields.dart';
import 'package:niman/src/ui/os_pickers.dart';
import 'package:niman/src/ui/strings.dart';

/// Shows the field dialog, and answers what was entered or null when it was
/// dismissed.
Future<({String key, FrontmatterFieldType type, List<String> values})?>
showFrontmatterFieldDialog(
  BuildContext context, {
  String? fieldKey,
  FrontmatterFieldType type = FrontmatterFieldType.text,
  List<String> values = const <String>[],
}) {
  return showDialog(
    context: context,
    builder: (context) =>
        _FrontmatterFieldDialog(fieldKey: fieldKey, type: type, values: values),
  );
}

/// The dialog body. Owns its controllers so they live as long as the dialog.
final class _FrontmatterFieldDialog extends StatefulWidget {
  const new({required this.fieldKey, required this.type, required this.values});

  /// The key being edited, or null when a field is being added.
  final String? fieldKey;

  /// The type the field starts on.
  final FrontmatterFieldType type;

  /// The values the field starts with.
  final List<String> values;

  @override
  State<_FrontmatterFieldDialog> createState() =>
      _FrontmatterFieldDialogState();
}

final class _FrontmatterFieldDialogState
    extends State<_FrontmatterFieldDialog> {
  late final TextEditingController _key = TextEditingController(
    text: widget.fieldKey ?? '',
  );
  late final TextEditingController _value = TextEditingController(
    text: widget.values.join(', '),
  );
  late FrontmatterFieldType _type = widget.type;
  late bool _bool = _isTrue(widget.values);

  /// The date a date field's value is: what the field was written with when
  /// it parses as one, else null until the picker gives one. The dialog
  /// answers the `YYYY-MM-DD` this writes back (`_dateText`), which is the
  /// form the parser reads as a date again.
  late DateTime? _date = _asDate(widget.values);

  static bool _isTrue(List<String> values) =>
      values.isNotEmpty && values.first.trim().toLowerCase() == 'true';

  static DateTime? _asDate(List<String> values) =>
      values.isEmpty ? null : DateTime.tryParse(values.first.trim());

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  bool get _adding => widget.fieldKey == null;

  bool get _canSave =>
      (!_adding || _key.text.trim().isNotEmpty) &&
      // A date field with no date is no field: the picker is what fills it.
      (_type != FrontmatterFieldType.date || _date != null);

  List<String> get _enteredValues {
    if (_type == FrontmatterFieldType.boolean) {
      return [if (_bool) 'true' else 'false'];
    }
    if (_type == FrontmatterFieldType.date) {
      return [_dateText(_date!)];
    }
    if (_type == FrontmatterFieldType.list) {
      // Read as the inside of a flow list, the way the items are shown:
      // `"Doe, J", x` is two items, and an item keeps its own YAML.
      return frontmatterListItems(_value.text);
    }
    return [_value.text.trim()];
  }

  void _save() {
    final key = (_adding ? _key.text : widget.fieldKey!).trim();
    if (key.isEmpty) return;
    Navigator.pop(context, (key: key, type: _type, values: _enteredValues));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _adding
            ? AppStrings.frontmatterNewField
            : AppStrings.frontmatterEditField,
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('frontmatter-key-field'),
              controller: _key,
              autofocus: _adding,
              enabled: _adding,
              decoration: InputDecoration(
                labelText: AppStrings.frontmatterKeyLabel,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _canSave ? _save() : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FrontmatterFieldType>(
              key: const Key('frontmatter-type-field'),
              initialValue: _type,
              decoration: InputDecoration(
                labelText: AppStrings.frontmatterTypeLabel,
              ),
              items: [
                for (final type in FrontmatterFieldType.values)
                  DropdownMenuItem<FrontmatterFieldType>(
                    value: type,
                    child: Text(_typeLabel(type)),
                  ),
              ],
              onChanged: (type) {
                if (type == null) return;
                setState(() {
                  // A value typed as a date becomes the picker's own date, so
                  // switching the type does not throw the value away.
                  if (type == FrontmatterFieldType.date && _date == null) {
                    _date = DateTime.tryParse(_value.text.trim());
                  }
                  _type = type;
                });
              },
            ),
            const SizedBox(height: 12),
            if (_type == FrontmatterFieldType.boolean)
              SwitchListTile(
                key: const Key('frontmatter-bool-field'),
                contentPadding: EdgeInsets.zero,
                value: _bool,
                title: Text(_bool ? 'true' : 'false'),
                onChanged: (value) => setState(() => _bool = value),
              )
            else if (_type == FrontmatterFieldType.date)
              _dateField(context)
            else
              TextField(
                key: const Key('frontmatter-value-field'),
                controller: _value,
                decoration: InputDecoration(
                  labelText: AppStrings.frontmatterValueLabel,
                  hintText: _type == FrontmatterFieldType.list
                      ? AppStrings.frontmatterListHint
                      : null,
                ),
                onSubmitted: (_) => _canSave ? _save() : null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('frontmatter-save'),
          onPressed: _canSave ? _save : null,
          child: Text(AppStrings.actionSave),
        ),
      ],
    );
  }

  /// The value of a date field: the date itself, opened in the platform's own
  /// picker. A date is picked rather than typed — the field is a `date:` one,
  /// and the day it names is a day, not a string that happens to parse.
  Widget _dateField(BuildContext context) {
    final date = _date;
    return InkWell(
      key: const Key('frontmatter-date-field'),
      borderRadius: BorderRadius.circular(4),
      onTap: () => unawaited(_pickDate(context)),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppStrings.frontmatterValueLabel,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(date == null ? '' : _dateText(date)),
      ),
    );
  }

  /// Asks the platform for a date, over the field's own or today's.
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDayPicker(
      context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
      // What a text field would have held, for a type switched back to text.
      _value.text = _dateText(_date!);
    });
  }

  /// A date as the YAML carries it: `2026-09-01`, a bare timestamp the parser
  /// reads back as a date.
  static String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _typeLabel(FrontmatterFieldType type) => switch (type) {
    FrontmatterFieldType.text => AppStrings.frontmatterTypeText,
    FrontmatterFieldType.number => AppStrings.frontmatterTypeNumber,
    FrontmatterFieldType.date => AppStrings.frontmatterTypeDate,
    FrontmatterFieldType.boolean => AppStrings.frontmatterTypeBoolean,
    FrontmatterFieldType.list => AppStrings.frontmatterTypeList,
  };
}
