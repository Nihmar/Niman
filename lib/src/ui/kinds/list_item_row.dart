import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/kinds/list_drag_handle.dart';
import 'package:niman/src/ui/kinds/list_drop_indicator.dart';
import 'package:niman/src/ui/kinds/list_parser.dart';
import 'package:niman/src/ui/marquee_text.dart';
import 'package:niman/src/ui/strings.dart';

/// The commit of an in-place edit: the item's new text and quantity.
typedef ListItemCommit = void Function(String text, int quantity);

/// One row of the list-kind GUI: the drag handle (dragging it moves the
/// row, T-TK-09), the checkbox (tapping it flips the item), the item
/// text (tapping it edits it in place), the quantity pill of a shopping
/// list, and the trash (tapping it deletes the item and its subtree).
class ListItemRow extends StatefulWidget {
  /// Creates the row.
  const new({
    required this.item,
    required this.isDragSource,
    required this.isEditing,
    required this.indicator,
    required this.onToggle,
    required this.onBeginEdit,
    required this.onCommitEdit,
    required this.onDelete,
    required this.onDragStart,
    required this.onDragMove,
    required this.onDragEnd,
    required this.onDragCancel,
    this.shopping = false,
    super.key,
  });

  /// The parsed item.
  final ListItem item;

  /// Whether the row is a shopping-list item: it shows the quantity and
  /// edits it beside the text.
  final bool shopping;

  /// Whether this row is the active drag source (rendered dimmed).
  final bool isDragSource;

  /// Whether the row's text is being edited in place.
  final bool isEditing;

  /// The drop indicator to render for this row, if any.
  final ListDropMode? indicator;

  /// Flips the item's box (the checkbox tap).
  final VoidCallback onToggle;

  /// Enters in-place editing of the item (the text or the pill tap).
  final VoidCallback onBeginEdit;

  /// Commits the edited text and quantity (submit, focus loss, or the
  /// edit ending).
  final ListItemCommit onCommitEdit;

  /// Deletes the item and its subtree (the trash tap).
  final VoidCallback onDelete;

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
  final FocusNode _quantityFocus = FocusNode();
  final TextEditingController _quantity = TextEditingController();
  bool _committed = false;

  /// Whether the edit about to start should put the caret in the
  /// quantity field (the pill tap) rather than the text (the row tap).
  bool _focusQuantity = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
    _quantityFocus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(ListItemRow old) {
    super.didUpdateWidget(old);
    if (widget.isEditing && !old.isEditing) {
      _committed = false;
      _text
        ..text = widget.item.text
        ..selection = TextSelection.collapsed(offset: widget.item.text.length);
      final quantity = '${widget.item.quantity}';
      _quantity
        ..text = quantity
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: quantity.length,
        );
      if (_focusQuantity && widget.shopping) {
        _quantityFocus.requestFocus();
      } else {
        _focus.requestFocus();
      }
    } else if (!widget.isEditing && old.isEditing) {
      _focusQuantity = false;
      if (_committed) return;
      // The edit ended without a submit (another row started editing and
      // this field is going away). Commit after the frame settles: the
      // focus-loss notification is not delivered for detached nodes, and
      // the parent may not be rebuilt yet.
      scheduleMicrotask(() {
        if (mounted) _commit();
      });
    } else if (!widget.isEditing) {
      _focusQuantity = false;
    }
  }

  /// Commits the edit, at most once per edit session (submit and focus
  /// loss both call this).
  void _commit() {
    if (_committed || !mounted) return;
    _committed = true;
    widget.onCommitEdit(_text.text, _quantityValue);
  }

  /// The quantity in the field, 1 when it is empty or unreadable.
  int get _quantityValue {
    final quantity = int.tryParse(_quantity.text.trim()) ?? 1;
    return quantity < 1 ? 1 : quantity;
  }

  /// Focus loss commits the edit (submit does the same); moving the
  /// focus from the text to the quantity field is the same edit.
  void _onFocusChanged() {
    if (_focus.hasFocus || _quantityFocus.hasFocus) return;
    _commit();
  }

  /// Opens the edit with the quantity field focused (the pill tap).
  void _beginQuantityEdit() {
    _focusQuantity = true;
    widget.onBeginEdit();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _quantityFocus.removeListener(_onFocusChanged);
    _focus.dispose();
    _quantityFocus.dispose();
    _text.dispose();
    _quantity.dispose();
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
        Checkbox(value: item.checked, onChanged: (_) => widget.onToggle()),
        Expanded(
          child: widget.isEditing
              ? _editField()
              : MarqueeText(
                  text: item.text,
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
        if (widget.shopping)
          if (widget.isEditing) ...[
            Text(
              '×',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            _quantityField(),
          ] else
            _quantityPill(),
        // Always there, and always in the same place: a control that
        // came and went would move what is under the thumb already on
        // the row.
        IconButton(
          key: const Key('list-delete-item'),
          icon: const Icon(Icons.delete_outline, size: 20),
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
          tooltip: AppStrings.actionDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          onPressed: widget.onDelete,
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
      key: const Key('list-edit-field'),
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

  /// The quantity, edited beside the text: digits only, two of them,
  /// which is what the stepper offers.
  Widget _quantityField() {
    return SizedBox(
      width: 52,
      child: TextField(
        key: const Key('list-quantity-field'),
        controller: _quantity,
        focusNode: _quantityFocus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onSubmitted: (_) => _commit(),
      ),
    );
  }

  /// The quantity as it reads when the row is not being edited; tapping
  /// it opens the edit on the quantity.
  Widget _quantityPill() {
    final theme = Theme.of(context);
    final item = widget.item;
    return Tooltip(
      message: AppStrings.shoppingQuantityLabel,
      child: InkWell(
        key: const Key('list-quantity-pill'),
        borderRadius: BorderRadius.circular(14),
        onTap: _beginQuantityEdit,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: item.quantity > 1
                  ? theme.colorScheme.outline
                  : theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            '×${item.quantity}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: item.checked
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
