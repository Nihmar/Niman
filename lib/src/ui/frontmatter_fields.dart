/// The frontmatter fields panel (#157): a note's leading YAML block drawn as
/// typed fields — one row per key, a checkbox for a boolean, chips for a list —
/// with the raw YAML always a toggle away.
///
/// This is a prototype, and deliberately a *view*: `note` is read for the
/// block, an edit is handed back through `onSet`/`onRemove`, and the owner
/// writes it through the editor's own path — one `.md` file, one undo step,
/// saved like any edit. The panel never holds the note's source, so it cannot
/// become a second store. A block the parser refuses
/// ([parseFrontmatterBlock]) shows its raw source and the parser's reason and
/// no field rows, so a note whose frontmatter Niman cannot read is never made
/// worse by the panel. A note with no block shows nothing.
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

  /// Whether the panel is folded to its header row.
  bool _collapsed = false;

  /// How tall the field list may be before it scrolls on its own, so a note
  /// with many keys never pushes the note it is read with off the pane.
  static const double _maxListHeight = 220;

  @override
  Widget build(BuildContext context) {
    final block = frontmatterBlock(widget.note);
    if (block == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final parsed = frontmatterFieldsIn(block.text);
    final malformed = parsed.error != null;
    final source = block.text;
    return Material(
      key: const Key('frontmatter-fields'),
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, malformed: malformed),
          const Divider(height: 1),
          if (!_collapsed)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _maxListHeight),
              child: SingleChildScrollView(
                child: _raw || malformed
                    ? _rawSource(context, source, parsed.error)
                    : _fields(context, parsed.fields),
              ),
            ),
        ],
      ),
    );
  }

  /// The panel's one row of chrome: the fold, the title, and — when the block
  /// parses, so there is something to show on the other side — the raw toggle.
  Widget _header(BuildContext context, {required bool malformed}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const SizedBox(width: 4),
        IconButton(
          key: const Key('frontmatter-collapse'),
          visualDensity: VisualDensity.compact,
          iconSize: 18,
          tooltip: AppStrings.frontmatterTitle,
          icon: Icon(_collapsed ? Icons.expand_more : Icons.expand_less),
          onPressed: () => setState(() => _collapsed = !_collapsed),
        ),
        Expanded(
          child: Text(
            AppStrings.frontmatterTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (!malformed)
          IconButton(
            key: const Key('frontmatter-raw-toggle'),
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            tooltip: _raw
                ? AppStrings.frontmatterShowFields
                : AppStrings.frontmatterShowRaw,
            icon: Icon(_raw ? Icons.tune : Icons.code),
            onPressed: () => setState(() => _raw = !_raw),
          ),
      ],
    );
  }

  /// The block as it is written, with the parser's reason above it when it did
  /// not parse. Readable, not typed in here: the source editor is where the
  /// YAML itself is edited.
  Widget _rawSource(BuildContext context, String source, String? error) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                AppStrings.frontmatterInvalid(error),
                key: const Key('frontmatter-panel-error'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          SelectableText(
            source,
            key: const Key('frontmatter-raw'),
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  /// One row per key, then the add.
  Widget _fields(BuildContext context, List<FrontmatterField> fields) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fields.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              AppStrings.frontmatterNoFields,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final field in fields) _fieldRow(context, field),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: TextButton.icon(
              key: const Key('frontmatter-add'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppStrings.frontmatterAddField),
              onPressed: () => _add(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldRow(BuildContext context, FrontmatterField field) {
    final theme = Theme.of(context);
    return Padding(
      key: Key('frontmatter-field-${field.key}'),
      padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
      child: Row(
        children: [
          Icon(
            _iconOf(field.type),
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text(
              field.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _fieldValue(context, field)),
          IconButton(
            key: Key('frontmatter-remove-${field.key}'),
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            tooltip: AppStrings.frontmatterRemoveField,
            icon: const Icon(Icons.close),
            onPressed: () => widget.onRemove(field.key),
          ),
        ],
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
          child: Checkbox(
            key: Key('frontmatter-toggle-${field.key}'),
            visualDensity: VisualDensity.compact,
            value: field.value?.toLowerCase() == 'true',
            onChanged: (value) =>
                widget.onSet(field.key, (value ?? false) ? 'true' : 'false'),
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

  static IconData _iconOf(FrontmatterFieldType type) => switch (type) {
    FrontmatterFieldType.text => Icons.notes,
    FrontmatterFieldType.number => Icons.numbers,
    FrontmatterFieldType.date => Icons.event_outlined,
    FrontmatterFieldType.boolean => Icons.check_box_outlined,
    FrontmatterFieldType.list => Icons.list,
  };
}
