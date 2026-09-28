/// The frontmatter fields panel (#157): a note's leading YAML block drawn as
/// typed fields — one row per key, the key in a left column, the value, and a
/// small chip naming the type (text, number, date, boolean, list) — with the
/// raw YAML always a toggle away.
///
/// This is the **one** widget both surfaces put above the note: the read pane
/// and the live editor call it with the same head and the same two callbacks,
/// so the two cannot drift. It is deliberately a *view*: `note` is read for the
/// block, an edit is handed back through `onSet`/`onRemove`, and the owner
/// writes it through the editor's own path — one `.md` file, one undo step,
/// saved like any edit. The panel never holds the note's source, so it cannot
/// become a second store. A block the parser refuses ([parseFrontmatterBlock])
/// shows its reason and its raw source and no field rows, so a note whose
/// frontmatter Niman cannot read is never made worse by the panel. A note with
/// no block shows nothing.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/frontmatter/typed_fields.dart';
import 'package:niman/src/ui/frontmatter_field_dialog.dart';
import 'package:niman/src/ui/strings.dart';

/// A note's frontmatter as fields.
final class FrontmatterFields extends StatefulWidget {
  /// Builds the panel over the note's head, [note].
  const new({
    required this.note,
    required this.onSet,
    required this.onRemove,
    super.key,
  });

  /// The note's head — from its first line through the frontmatter block —
  /// which the panel reads the block out of.
  final String note;

  /// Called with a key and the YAML value to write on its line.
  final void Function(String key, String yamlValue) onSet;

  /// Called with a key to take out of the block.
  final void Function(String key) onRemove;

  @override
  State<FrontmatterFields> createState() => _FrontmatterFieldsState();
}

final class _FrontmatterFieldsState extends State<FrontmatterFields> {
  /// Whether the raw YAML is showing instead of the fields.
  bool _raw = false;

  /// The width of the key column, so every row's value starts on the same x.
  static const double _keyColumn = 150;

  /// How tall the field list may be before it scrolls on its own, so a note
  /// with many keys never pushes the note it is read with off the pane.
  static const double _maxListHeight = 260;

  @override
  Widget build(BuildContext context) {
    final block = frontmatterBlock(widget.note);
    if (block == null) return const SizedBox.shrink();
    final parsed = frontmatterFieldsIn(block.text);
    final malformed = parsed.error != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: malformed
          ? _brokenPanel(context, block.text, parsed.error!)
          : _fieldsPanel(context, block.text, parsed.fields),
    );
  }

  /// The panel with a block the parser could read: the header, and the fields
  /// or the raw source behind the toggle.
  Widget _fieldsPanel(
    BuildContext context,
    String source,
    List<FrontmatterField> fields,
  ) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('frontmatter-fields'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.22,
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _maxListHeight),
            child: SingleChildScrollView(
              child: _raw
                  ? _rawSource(context, source)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _fields(context, fields),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// The panel with a block the parser refused: the reason and the raw source,
  /// and no field rows — the block is left exactly as it is written.
  Widget _brokenPanel(BuildContext context, String source, String error) {
    return Column(
      key: const Key('frontmatter-fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _broken(context, error),
        const SizedBox(height: 10),
        _rawSource(context, source),
      ],
    );
  }

  /// The panel's one row of chrome: the title on the left, the raw toggle on
  /// the right.
  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            AppStrings.frontmatterTitle.toUpperCase(),
            key: const Key('frontmatter-properties'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        InkWell(
          key: const Key('frontmatter-raw-toggle'),
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _raw = !_raw),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _raw
                  ? AppStrings.frontmatterShowFields
                  : AppStrings.frontmatterShowRaw,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The reason a block does not parse, in the error's own colour.
  Widget _broken(BuildContext context, String error) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        AppStrings.frontmatterInvalid(error),
        key: const Key('frontmatter-panel-error'),
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }

  /// The block as it is written, under a rule: read, not typed in here — the
  /// source editor is where the YAML itself is edited.
  Widget _rawSource(BuildContext context, String source) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.only(top: 9, bottom: 2),
      child: SelectableText(
        source,
        key: const Key('frontmatter-raw'),
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// One row per key, then the add.
  List<Widget> _fields(BuildContext context, List<FrontmatterField> fields) {
    final theme = Theme.of(context);
    return [
      if (fields.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(7, 4, 7, 4),
          child: Text(
            AppStrings.frontmatterNoFields,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      for (final field in fields) _fieldRow(context, field),
      _addRow(context),
    ];
  }

  Widget _fieldRow(BuildContext context, FrontmatterField field) {
    final theme = Theme.of(context);
    return Padding(
      key: Key('frontmatter-field-${field.key}'),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          const SizedBox(width: 7),
          SizedBox(
            width: _keyColumn,
            child: Text(
              field.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _fieldValue(context, field)),
          const SizedBox(width: 10),
          _typeChip(context, field),
          IconButton(
            key: Key('frontmatter-remove-${field.key}'),
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            tooltip: AppStrings.frontmatterRemoveField,
            icon: const Icon(Icons.close),
            onPressed: () => widget.onRemove(field.key),
          ),
        ],
      ),
    );
  }

  /// The type the parser gave the field, as the drawing's small chip.
  Widget _typeChip(BuildContext context, FrontmatterField field) {
    final theme = Theme.of(context);
    return Container(
      key: Key('frontmatter-type-${field.key}'),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _typeLabel(field.type),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10.5,
        ),
      ),
    );
  }

  /// The value as its type reads: a checkbox ticks a boolean on the spot, a
  /// list is chips each with its own `×`, and a scalar opens the editor.
  Widget _fieldValue(BuildContext context, FrontmatterField field) {
    switch (field.type) {
      case FrontmatterFieldType.boolean:
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                key: Key('frontmatter-toggle-${field.key}'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: field.value?.toLowerCase() == 'true',
                onChanged: (value) => widget.onSet(
                  field.key,
                  (value ?? false) ? 'true' : 'false',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                field.value ?? 'false',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      case FrontmatterFieldType.list:
        return Wrap(
          spacing: 6,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final value in field.values)
              InputChip(
                key: Key('frontmatter-chip-${field.key}-$value'),
                label: Text(value),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: Theme.of(context).textTheme.bodySmall,
                onDeleted: () => widget.onSet(
                  field.key,
                  frontmatterFieldYaml(FrontmatterFieldType.list, [
                    for (final each in field.values)
                      if (each != value) each,
                  ]),
                ),
              ),
            IconButton(
              key: Key('frontmatter-add-item-${field.key}'),
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              tooltip: AppStrings.frontmatterEditField,
              icon: const Icon(Icons.add),
              onPressed: () => _edit(context, field),
            ),
          ],
        );
      case FrontmatterFieldType.text:
      case FrontmatterFieldType.number:
      case FrontmatterFieldType.date:
        return InkWell(
          key: Key('frontmatter-value-${field.key}'),
          onTap: () => _edit(context, field),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              field.value ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
    }
  }

  /// The last row: a small box with a plus and the words that add a key.
  Widget _addRow(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: InkWell(
        key: const Key('frontmatter-add'),
        borderRadius: BorderRadius.circular(7),
        onTap: () => _add(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(
                  Icons.add,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.frontmatterAddField,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final result = await showFrontmatterFieldDialog(context);
    if (result == null) return;
    widget.onSet(result.key, frontmatterFieldYaml(result.type, result.values));
  }

  Future<void> _edit(BuildContext context, FrontmatterField field) async {
    final result = await showFrontmatterFieldDialog(
      context,
      fieldKey: field.key,
      type: field.type,
      values: field.values,
    );
    if (result == null) return;
    widget.onSet(field.key, frontmatterFieldYaml(result.type, result.values));
  }

  static String _typeLabel(FrontmatterFieldType type) => switch (type) {
    FrontmatterFieldType.text => AppStrings.frontmatterTypeText,
    FrontmatterFieldType.number => AppStrings.frontmatterTypeNumber,
    FrontmatterFieldType.date => AppStrings.frontmatterTypeDate,
    FrontmatterFieldType.boolean => AppStrings.frontmatterTypeBoolean,
    FrontmatterFieldType.list => AppStrings.frontmatterTypeList,
  };
}
