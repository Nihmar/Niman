import 'dart:async';

import 'package:copist/src/ui/kinds/list_parser.dart';
import 'package:flutter/material.dart';

/// One row of the list-kind GUI: the checkbox (tapping it flips the
/// item), the item text (tapping it edits the text in place) and the
/// whole row as a long-press drag source (T-TK-09).
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

  /// The long press started at the given global position (the row's
  /// drag).
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
    final row = Row(
      children: [
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
    final padded = Padding(
      padding: EdgeInsets.only(
        left: indent,
        right: 8,
        top: 4,
        bottom: 4,
      ),
      child: row,
    );
    final content = widget.isEditing
        ? padded
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onBeginEdit,
            onLongPressStart: (d) => widget.onDragStart(d.globalPosition),
            onLongPressMoveUpdate: (d) => widget.onDragMove(
              d.globalPosition,
            ),
            onLongPressEnd: (_) => widget.onDragEnd(),
            onLongPressCancel: widget.onDragCancel,
            child: padded,
          );
    return Opacity(
      opacity: widget.isDragSource ? 0.35 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.indicator == ListDropMode.before) _indicator(theme),
          content,
          if (widget.indicator == ListDropMode.after ||
              widget.indicator == ListDropMode.under)
            _indicator(
              theme,
              under: widget.indicator == ListDropMode.under,
            ),
        ],
      ),
    );
  }

  /// The drop indicator line: full width for before/after, indented for
  /// under (the item will become a child).
  Widget _indicator(ThemeData theme, {bool under = false}) {
    final indent = 8.0 + widget.item.depth * 24 + (under ? 24 : 0);
    return Container(
      height: 2,
      margin: EdgeInsets.only(left: indent, right: 8),
      color: theme.colorScheme.primary,
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
