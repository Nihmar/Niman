import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_dashed_box.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_palette.dart';

/// A dashed "+ Add a card" or "+ Add a column" (#1167): pressed, it becomes
/// a field. `Enter` adds what was typed, `Esc` or leaving the field closes
/// it; what was typed is added when the field is left, so a click elsewhere
/// does not lose it.
final class KanbanAddField extends StatefulWidget {
  /// A control labelled [label] whose field hints [hint] and adds through
  /// [onAdd].
  ///
  /// With [keepOpen] the field stays open for the next one after an add.
  const new({
    required this.label,
    required this.hint,
    required this.onAdd,
    this.keepOpen = false,
    super.key,
  });

  /// The closed control's text.
  final String label;

  /// The open field's hint.
  final String hint;

  /// Adds the text typed (never blank).
  final ValueChanged<String> onAdd;

  /// Whether the field stays open after an add.
  final bool keepOpen;

  @override
  State<KanbanAddField> createState() => _KanbanAddFieldState();
}

final class _KanbanAddFieldState extends State<KanbanAddField> {
  final FocusNode _focus = FocusNode(debugLabel: 'kanban-add');
  final TextEditingController _text = TextEditingController();
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_open && !_focus.hasFocus) _close(add: true);
  }

  void _openField() => setState(() => _open = true);

  void _close({required bool add}) {
    if (!_open) return;
    final title = _text.text.trim();
    _text.clear();
    setState(() => _open = false);
    if (add && title.isNotEmpty) widget.onAdd(title);
  }

  void _submit() {
    final title = _text.text.trim();
    if (title.isEmpty) {
      _close(add: false);
      return;
    }
    widget.onAdd(title);
    _text.clear();
    if (widget.keepOpen) {
      _focus.requestFocus();
    } else {
      setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = KanbanPalette.of(context);
    final theme = Theme.of(context);
    if (!_open) {
      return KanbanDashedBox(
        color: palette.muted.withValues(alpha: 0.6),
        child: InkWell(
          key: const Key('kanban-add'),
          borderRadius: BorderRadius.circular(10),
          onTap: _openField,
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: palette.muted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _close(add: false),
      },
      child: TextField(
        key: const Key('kanban-add-field'),
        controller: _text,
        focusNode: _focus,
        autofocus: true,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: palette.card,
          hintText: widget.hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        // Not onSubmitted: completing the field keeps its focus, which a
        // submit would drop.
        onEditingComplete: _submit,
      ),
    );
  }
}
