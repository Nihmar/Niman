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
///
/// The panel is the note's *head*, and it behaves like one: it opens closed —
/// one row of chrome, the fields a tap away — and it takes no room at all
/// while the note is scrolled past its head, so a long note is never read
/// through a panel that belongs to its first lines. Which of the three states
/// it is in is the owner's ([FrontmatterFields.panel]), because the read pane
/// and the live editor show the same panel and a state kept here would let the
/// two drift; the owner is handed the taps through
/// [FrontmatterFields.onToggle]. The three animate into one another, so
/// neither the note nor the panel jumps.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/frontmatter/typed_fields.dart';
import 'package:niman/src/ui/frontmatter_field_dialog.dart';
import 'package:niman/src/ui/strings.dart';

/// How much of the frontmatter panel is showing (#157).
enum FrontmatterPanel {
  /// The note is scrolled past its head, and the panel with it: no room at
  /// all, not even the handle's row.
  hidden,

  /// The note is at its head and the panel is closed: one row of chrome, the
  /// fields a tap away.
  closed,

  /// The reader opened it: the fields, or the raw YAML behind the toggle.
  open,
}

/// A note's frontmatter as fields.
final class FrontmatterFields extends StatefulWidget {
  /// Builds the panel over the note's head, [note].
  const new({
    required this.note,
    required this.onSet,
    required this.onRemove,
    required this.panel,
    required this.onToggle,
    super.key,
  });

  /// The note's head — from its first line through the frontmatter block —
  /// which the panel reads the block out of.
  final String note;

  /// Called with a key and the YAML value to write on its line.
  final void Function(String key, String yamlValue) onSet;

  /// Called with a key to take out of the block.
  final void Function(String key) onRemove;

  /// How much of the panel is showing: the owner keeps this, because the two
  /// surfaces show the panel at once and only one of them writes it down.
  final FrontmatterPanel panel;

  /// Called when the reader opens the closed panel, or closes the open one.
  final VoidCallback onToggle;

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

  /// How long the panel takes to open, close or leave: the toolbar's own
  /// motion (note_view), so the chrome of a note moves at one pace.
  static const Duration _motion = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final block = frontmatterBlock(widget.note);
    if (block == null) return const SizedBox.shrink();
    final parsed = frontmatterFieldsIn(block.text);
    final malformed = parsed.error != null;
    // A hidden panel is the same panel at no height, never an absent one:
    // it keeps its state (the raw toggle), and the size it gains back when
    // the note returns to its head is animated rather than jumped.
    return AnimatedSize(
      duration: _motion,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: widget.panel == FrontmatterPanel.hidden
          ? const SizedBox(width: double.infinity, height: 0)
          : Padding(
              // Room above it as well as below: the panel is a box with an
              // edge of its own, and one that touches the chrome over it —
              // the journal's day strip, the find bar, the note's own row —
              // reads as part of it (device report, 2026-09-29).
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              child: _panel(
                context,
                // The add row is the panel's one action and it is always
                // there: on a closed panel it is what the panel is for, and
                // under a long list it is not scrolled away with the rows —
                // adding a key is never behind a scroll or a tap. A block the
                // parser refused gets none: its keys are not this panel's to
                // add to.
                add: malformed ? null : _addRow(context),
                body: (context) => malformed
                    ? _brokenBody(context, block.text, parsed.error!)
                    : _fieldsBody(context, block.text, parsed.fields),
              ),
            ),
    );
  }

  /// The panel's chrome: its one row, and [body] under it while it is open.
  ///
  /// The row itself is always drawn — it is the handle that opens the panel,
  /// so it keeps its place, and the body is what a tap adds or takes away.
  Widget _panel(
    BuildContext context, {
    required WidgetBuilder body,
    Widget? add,
  }) {
    final theme = Theme.of(context);
    final open = widget.panel == FrontmatterPanel.open;
    return Container(
      key: const Key('frontmatter-fields'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.22,
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(9),
      ),
      // Tighter around a closed panel: one row of chrome with the fields
      // away is a handle, and it is charged for what it is.
      padding: EdgeInsets.fromLTRB(12, open ? 10 : 4, 12, open ? 8 : 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, open: open),
          if (open) ...[const SizedBox(height: 4), body(context)],
          ?add,
        ],
      ),
    );
  }

  /// The body with a block the parser could read: the fields, or the raw
  /// source behind the toggle.
  Widget _fieldsBody(
    BuildContext context,
    String source,
    List<FrontmatterField> fields,
  ) {
    return ConstrainedBox(
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
    );
  }

  /// The body with a block the parser refused: the reason and the raw source,
  /// and no field rows — the block is left exactly as it is written.
  Widget _brokenBody(BuildContext context, String source, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _broken(context, error),
        const SizedBox(height: 10),
        _rawSource(context, source),
      ],
    );
  }

  /// The panel's one row of chrome: the handle that opens and closes it on
  /// the left, the raw toggle on the right — the toggle only while the body it
  /// switches is showing, and the handle's chevron saying which way a tap
  /// goes (down when there is a body under it, right when there is not).
  Widget _header(BuildContext context, {required bool open}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            key: const Key('frontmatter-collapse-toggle'),
            borderRadius: BorderRadius.circular(7),
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    open ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
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
                ],
              ),
            ),
          ),
        ),
        if (open)
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

  /// One row per key: the list the panel scrolls, with the add under it. The
  /// rows only — the add row is the panel's, so it stays put whatever this
  /// list does (`_panel`).
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
            for (var i = 0; i < field.values.length; i++)
              InputChip(
                key: _chipKey(field, i),
                label: Text(field.values[i]),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelStyle: Theme.of(context).textTheme.bodySmall,
                // By position: two equal chips are two items, and deleting
                // one leaves the other. The items that stay keep the YAML
                // they were written with.
                onDeleted: () => widget.onSet(
                  field.key,
                  frontmatterListYaml([...field.items]..removeAt(i)),
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

  /// The panel's action row: a small box with a plus and the words that add a
  /// key.
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

  /// The chip of [field]'s item [index]: named after its text, and after
  /// its place too when an earlier chip already has that text, so equal
  /// items are distinct chips.
  static Key _chipKey(FrontmatterField field, int index) {
    final value = field.values[index];
    final before = field.values.take(index).where((each) => each == value);
    return Key(
      before.isEmpty
          ? 'frontmatter-chip-${field.key}-$value'
          : 'frontmatter-chip-${field.key}-$value-${before.length + 1}',
    );
  }

  /// The YAML the dialog's answer is written as: a list's values are its
  /// items' own YAML ([frontmatterListItems]), anything else is text.
  static String _yamlOf(FrontmatterFieldType type, List<String> values) =>
      type == FrontmatterFieldType.list
      ? frontmatterListYaml(values)
      : frontmatterFieldYaml(type, values);

  /// What the dialog is handed for [field]: a list's items as YAML, so the
  /// editor shows `"Doe, J", x` and reads it back as two items.
  static List<String> _dialogValues(FrontmatterField field) =>
      field.type == FrontmatterFieldType.list ? field.items : field.values;

  Future<void> _add(BuildContext context) async {
    final result = await showFrontmatterFieldDialog(context);
    if (result == null) return;
    widget.onSet(result.key, _yamlOf(result.type, result.values));
  }

  Future<void> _edit(BuildContext context, FrontmatterField field) async {
    final shown = _dialogValues(field);
    final result = await showFrontmatterFieldDialog(
      context,
      fieldKey: field.key,
      type: field.type,
      values: shown,
    );
    if (result == null) return;
    // Saved as it was shown: nothing is written. Rewriting it anyway put
    // the value back in the panel's own spelling — `1.10` as `1.1`, a
    // folded block as one quoted line — over a note nobody changed.
    if (result.type == field.type && _same(result.values, shown)) return;
    widget.onSet(field.key, _yamlOf(result.type, result.values));
  }

  static bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static String _typeLabel(FrontmatterFieldType type) => switch (type) {
    FrontmatterFieldType.text => AppStrings.frontmatterTypeText,
    FrontmatterFieldType.number => AppStrings.frontmatterTypeNumber,
    FrontmatterFieldType.date => AppStrings.frontmatterTypeDate,
    FrontmatterFieldType.boolean => AppStrings.frontmatterTypeBoolean,
    FrontmatterFieldType.list => AppStrings.frontmatterTypeList,
  };
}
