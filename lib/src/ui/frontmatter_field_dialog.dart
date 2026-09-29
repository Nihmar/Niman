/// The editor behind the frontmatter fields panel (#157): a key, a type and a
/// value, for adding a field or changing one.
///
/// The answer is plain data — a key, a type and the values — and the panel
/// turns it into the YAML the file gets (`frontmatterFieldYaml`). A list's
/// values are its items' own YAML, shown and read as the inside of a flow
/// list (`frontmatterListItems`), so an item holding a comma stays one item.
/// The key is fixed when an existing field is edited: renaming a key is an
/// edit of its own the panel does not make.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/frontmatter/typed_fields.dart';
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

  static bool _isTrue(List<String> values) =>
      values.isNotEmpty && values.first.trim().toLowerCase() == 'true';

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  bool get _adding => widget.fieldKey == null;

  bool get _canSave => !_adding || _key.text.trim().isNotEmpty;

  List<String> get _enteredValues {
    if (_type == FrontmatterFieldType.boolean) {
      return [if (_bool) 'true' else 'false'];
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
                if (type != null) setState(() => _type = type);
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

  static String _typeLabel(FrontmatterFieldType type) => switch (type) {
    FrontmatterFieldType.text => AppStrings.frontmatterTypeText,
    FrontmatterFieldType.number => AppStrings.frontmatterTypeNumber,
    FrontmatterFieldType.date => AppStrings.frontmatterTypeDate,
    FrontmatterFieldType.boolean => AppStrings.frontmatterTypeBoolean,
    FrontmatterFieldType.list => AppStrings.frontmatterTypeList,
  };
}
