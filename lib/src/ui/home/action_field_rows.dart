/// A new-note action's name and fields, as the editor holds them (#535):
/// each one fixed, its value written, or asked when the button is pressed.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/ui/strings.dart';

/// One field being edited.
final class _Field {
  new(String key, FieldPreset preset)
    : key = TextEditingController(text: key),
      value = TextEditingController(text: preset.fixed ?? ''),
      asks = preset.asks;

  final TextEditingController key;
  final TextEditingController value;
  bool asks;

  void dispose() {
    key.dispose();
    value.dispose();
  }
}

/// The name and the fields, editable.
final class ActionFieldRows extends ChangeNotifier {
  /// Starts from an action's [name] and [fields].
  new({required FieldPreset name, required Map<String, FieldPreset> fields})
    : _nameAsks = name.asks,
      _name = TextEditingController(text: name.fixed ?? ''),
      _rows = [for (final e in fields.entries) _Field(e.key, e.value)];

  bool _nameAsks;
  final TextEditingController _name;
  final List<_Field> _rows;

  /// The name as set: asked, or fixed to what is written (asked when
  /// nothing is).
  FieldPreset get name => _nameAsks || _name.text.trim().isEmpty
      ? const FieldPreset.ask()
      : FieldPreset.value(_name.text.trim());

  /// The fields as set, the ones with no key left out.
  Map<String, FieldPreset> get fields => {
    for (final row in _rows)
      if (row.key.text.trim().isNotEmpty)
        row.key.text.trim(): row.asks
            ? const FieldPreset.ask()
            : FieldPreset.value(row.value.text.trim()),
  };

  void _setNameAsks(bool asks) {
    _nameAsks = asks;
    notifyListeners();
  }

  void _setAsks(_Field row, bool asks) {
    row.asks = asks;
    notifyListeners();
  }

  void _add() {
    _rows.add(_Field('', const FieldPreset.value('')));
    notifyListeners();
  }

  void _remove(_Field row) {
    _rows.remove(row);
    row.dispose();
    notifyListeners();
  }

  @override
  void dispose() {
    _name.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }
}

/// The name's and the fields' controls.
final class ActionFieldEditor extends StatelessWidget {
  /// Edits [rows].
  const new({required this.rows, super.key});

  /// What is being edited.
  final ActionFieldRows rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: rows,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.homeActionNoteName,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          _PresetRow(
            keyPrefix: 'home-action-name',
            asks: rows._nameAsks,
            value: rows._name,
            onAsks: rows._setNameAsks,
          ),
          const SizedBox(height: 16),
          Text(AppStrings.homeActionFields, style: theme.textTheme.titleSmall),
          for (final (i, row) in rows._rows.indexed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('home-action-field-key-$i'),
                    controller: row.key,
                    decoration: InputDecoration(
                      labelText: AppStrings.homeActionFieldKey,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  key: Key('home-action-field-remove-$i'),
                  tooltip: AppStrings.actionDelete,
                  onPressed: () => rows._remove(row),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _PresetRow(
              keyPrefix: 'home-action-field-$i',
              asks: row.asks,
              value: row.value,
              onAsks: (asks) => rows._setAsks(row, asks),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('home-action-field-add'),
              onPressed: rows._add,
              icon: const Icon(Icons.add),
              label: Text(AppStrings.homeActionFieldAdd),
            ),
          ),
        ],
      ),
    );
  }
}

/// *Fixed* or *Ask*, and the fixed value's box.
final class _PresetRow extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.asks,
    required this.value,
    required this.onAsks,
  });

  final String keyPrefix;
  final bool asks;
  final TextEditingController value;
  final ValueChanged<bool> onAsks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SegmentedButton<bool>(
          key: Key('$keyPrefix-mode'),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [
            ButtonSegment(
              value: false,
              label: Text(AppStrings.homeActionFixed),
            ),
            ButtonSegment(value: true, label: Text(AppStrings.homeActionAsk)),
          ],
          selected: {asks},
          onSelectionChanged: (picked) => onAsks(picked.single),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: asks
              ? Text(
                  AppStrings.homeActionAskHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : TextField(
                  key: Key('$keyPrefix-value'),
                  controller: value,
                  decoration: InputDecoration(
                    hintText: AppStrings.homeActionFixedHint,
                    isDense: true,
                  ),
                ),
        ),
      ],
    );
  }
}
