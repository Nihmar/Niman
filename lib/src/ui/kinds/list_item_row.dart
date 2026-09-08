import 'dart:async';

import 'package:copist/src/ui/kinds/list_drag_handle.dart';
import 'package:copist/src/ui/kinds/list_drop_indicator.dart';
import 'package:copist/src/ui/kinds/list_parser.dart';
import 'package:flutter/material.dart';

/// One row of the list-kind GUI: the drag handle (dragging it moves the
/// row, T-TK-09), the checkbox (tapping it flips the item) and the item
/// text (tapping it edits the text in place).
class ListItemRow extends StatefulWidget {
  /// Creates the row.
  const ListItemRow({
    required this.item,
    required this.isDragSource,
    required this.isEditing,
    required this.indicator,
    required this.onToggle,
    required this.onBeginEdit,
    required this.onCommitEdit,
    required this.onDragStart,
    required this.onDragMove,
    required this.onDragEnd,
    required this.onDragCancel,
    super.key,
  });

  /// The parsed item.
  final ListItem item;

  /// Whether this row is the active drag source (rendered dimmed).
  final bool isDragSource;

  /// Whether the row's text is being edited in place.
  final bool isEditing;

  /// The drop indicator to render for this row, if any.
  final ListDropMode? indicator;

  /// Flips the item's box (the checkbox tap).
  final VoidCallback onToggle;

  /// Enters in-place editing of the item text (the text tap).
  final VoidCallback onBeginEdit;

  /// Commits the edited text (submit, focus loss, or the edit ending).
  final ValueChanged<String> onCommitEdit;

  /// The drag started at the given global position (the handle's drag).
  final ValueChanged<Offset> onDragStart;

  /// The drag moved to the given global position.
  final ValueChanged<Offset> onDragMove;

  /// The drag ended (drop).
  final VoidCallback onDragEnd;

  /// The drag was cancelled (no drop).
  final VoidCallback onDragCancel;

  @override
  State<ListItemRow> createState() => _ListItemRowState();
}

class _ListItemRowState extends State<ListItemRow> {
  final FocusNode _focus = FocusNode();
  final TextEditingController _text = TextEditingController();
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(ListItemRow old) {
    super.didUpdateWidget(old);
    if (widget.isEditing && !old.isEditing) {
      _committed = false;
      _text
        ..text = widget.item.text
        ..selection = TextSelection.collapsed(
          offset: widget.item.text.length,
        );
      _focus.requestFocus();
    } else if (!widget.isEditing && old.isEditing && !_committed) {
      // The edit ended without a submit (another row started editing and
      // this field is going away). Commit after the frame settles: the
      // focus-loss notification is not delivered for detached nodes, and
      // the parent may not be rebuilt yet.
      scheduleMicrotask(() {
        if (mounted) _commit();
      });
    }
  }

  /// Commits the edit, at most once per edit session (submit and focus
  /// loss both call this).
  void _commit() {
    if (_committed || !mounted) return;
    _committed = true;
    widget.onCommitEdit(_text.text);
  }

  /// Focus loss commits the edit (submit does the same).
  void _onFocusChanged() {
    if (_focus.hasFocus) return;
    _commit();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final indent = 8.0 + item.depth * 24;
    final under = widget.indicator == ListDropMode.under;
    final row = Row(
      children: [
        ListDragHandle(
          key: const Key('list-drag-handle'),
          active: widget.isDragSource,
          onDragStart: widget.onDragStart,
          onDragMove: widget.onDragMove,
          onDragEnd: widget.onDragEnd,
          onDragCancel: widget.onDragCancel,
        ),
        Checkbox(
          value: item.checked,
          onChanged: (_) => widget.onToggle(),
        ),
        Expanded(
          child: widget.isEditing
              ? _editField()
              : Text(
                  item.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    decoration: item.checked
                        ? TextDecoration.lineThrough
                        : null,
                    color: item.checked
                        ? theme.colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
        ),
      ],
    );
    // The "under" drop tints the target row: the dragged item is about to
    // become its child, which no line between rows can say on its own.
    final body = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: EdgeInsets.only(left: indent, right: 8, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: under
            ? theme.colorScheme.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: row,
    );
    final content = widget.isEditing
        ? body
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onBeginEdit,
            child: body,
          );
    return Opacity(
      opacity: widget.isDragSource ? 0.3 : 1,
      // The indicators overlay the row's edges instead of taking space:
      // rows keep their height and position while a drag hovers them.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (widget.indicator == ListDropMode.before)
            _indicatorAt(top: true, indent: indent),
          if (widget.indicator == ListDropMode.after)
            _indicatorAt(top: false, indent: indent),
          if (under) _indicatorAt(top: false, indent: indent + 24),
        ],
      ),
    );
  }

  /// A drop indicator centred on the row's top or bottom edge.
  Widget _indicatorAt({required bool top, required double indent}) {
    const overhang = -ListDropIndicator.height / 2;
    return Positioned(
      left: 0,
      right: 0,
      top: top ? overhang : null,
      bottom: top ? null : overhang,
      child: ListDropIndicator(indent: indent),
    );
  }

  Widget _editField() {
    return TextField(
      controller: _text,
      focusNode: _focus,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onSubmitted: (_) => _commit(),
    );
  }
}
