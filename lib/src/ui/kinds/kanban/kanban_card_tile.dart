import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/kanban/board_edit_scope.dart' show oneLine;
import 'package:niman/src/kanban/kanban_card.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_board_controller.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_draggable.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_face.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_keys.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_menu.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_title.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_drop_bar.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_palette.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';
import 'package:niman/src/ui/strings.dart';

/// One card of a column (#1167): focusable, dragged, edited in place, moved
/// by the keys and by its menu.
///
/// A tile is the card at a *place* of the board, not a card: after an edit
/// the same tile shows whatever the text now has there, and the focus stays
/// with it. The board asks for the focus to follow a moved card.
final class KanbanCardTile extends StatefulWidget {
  /// The tile of card [index] of column [column].
  const new({
    required this.controller,
    required this.registry,
    required this.column,
    required this.index,
    required this.card,
    required this.columnName,
    required this.cardCount,
    super.key,
  });

  /// What the board shares.
  final KanbanBoardController controller;

  /// The tiles of the column that are built, which the column reads to find
  /// where a dragged card would land.
  final Set<KanbanCardTileState> registry;

  /// The column's index.
  final int column;

  /// The card's index in its column.
  final int index;

  /// The card.
  final KanbanCard card;

  /// The column's name, for the screen reader.
  final String columnName;

  /// How many cards the column holds.
  final int cardCount;

  @override
  State<KanbanCardTile> createState() => KanbanCardTileState();
}

/// The state of a [KanbanCardTile]: the column reads where it is.
final class KanbanCardTileState extends State<KanbanCardTile>
    with AutomaticKeepAliveClientMixin {
  final FocusNode _focus = FocusNode(debugLabel: 'kanban-card');
  final FocusNode _editFocus = FocusNode(debugLabel: 'kanban-card-edit');
  final TextEditingController _text = TextEditingController();
  final MenuController _menu = MenuController();
  bool _editing = false;
  bool _dragSource = false;

  CardPos get _pos => (column: widget.column, card: widget.index);

  /// The card's index in its column.
  int get index => widget.index;

  /// The vertical middle of the tile on screen, null while it is not laid
  /// out.
  double? get centerY {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero)).dy;
  }

  /// Gives the tile the keyboard focus and brings it into view.
  void focus() {
    _focus.requestFocus();
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.registry.add(this);
    _editFocus.addListener(_onEditFocus);
  }

  @override
  void didUpdateWidget(KanbanCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_editing && oldWidget.card.title != widget.card.title) {
      // The text moved under the field (an undo, a sync): the title being
      // typed belonged to a card that is no longer here.
      _editing = false;
    }
  }

  @override
  void dispose() {
    widget.registry.remove(this);
    _editFocus.removeListener(_onEditFocus);
    _editFocus.dispose();
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  /// The tile being dragged is kept alive: the column scrolls under a held
  /// pointer, and the drag's recognizer lives in this tile.
  @override
  bool get wantKeepAlive => _dragSource;

  void _beginEdit() {
    if (_editing) return;
    _text.value = TextEditingValue(
      text: widget.card.title,
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: widget.card.title.length,
      ),
    );
    setState(() => _editing = true);
  }

  /// Ends the edit; [save] writes the title, [refocus] hands the keyboard
  /// back to the card (Enter and Esc do, a click elsewhere does not).
  void _finish({required bool save, required bool refocus}) {
    if (!_editing) return;
    final title = oneLine(_text.text);
    setState(() => _editing = false);
    if (refocus) _focus.requestFocus();
    if (save && title.isNotEmpty) {
      widget.controller.edits.retitle(widget.column, widget.index, title);
    }
  }

  void _onEditFocus() {
    if (_editing && !_editFocus.hasFocus) _finish(save: true, refocus: false);
  }

  /// A tap picks the card; a tap on the card already picked edits it.
  void _tap() {
    if (_focus.hasPrimaryFocus) {
      _beginEdit();
    } else {
      _focus.requestFocus();
    }
  }

  void _toggle() => widget.controller.edits.toggle(widget.column, widget.index);

  void _move(KanbanDirection direction) =>
      widget.controller.move(_pos, direction);

  void _delete() => widget.controller.delete(_pos);

  void _dragStarted() {
    _dragSource = true;
    updateKeepAlive();
    widget.controller.dragging.value = _pos;
    _focus.requestFocus();
  }

  void _dragEnded() {
    _dragSource = false;
    if (mounted) updateKeepAlive();
    widget.controller.dragEnd();
  }

  Widget _title(BuildContext context) {
    if (!_editing) return _plainTitle();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _finish(save: false, refocus: true),
      },
      child: TextField(
        key: const Key('kanban-card-field'),
        controller: _text,
        focusNode: _editFocus,
        autofocus: true,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: AppStrings.kanbanCardHint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onSubmitted: (_) => _finish(save: true, refocus: true),
      ),
    );
  }

  Widget _plainTitle() => KanbanCardTitle(
    card: widget.card,
    host: widget.controller.host,
    mathCache: widget.controller.mathCache,
  );

  Widget _face(BuildContext context, {required bool lifted}) {
    final controller = widget.controller;
    return KanbanCardFace(
      card: widget.card,
      title: lifted ? _plainTitle() : _title(context),
      onToggle: lifted ? () {} : _toggle,
      menu: lifted
          ? null
          : KanbanCardMenu(
              controller: _menu,
              canMove: (direction) => controller.canMove(_pos, direction),
              onMove: _move,
              onDelete: _delete,
            ),
    );
  }

  /// The card's surface: a hairline, and a ring while it holds the focus.
  Widget _surface(BuildContext context, Widget face, {bool ring = false}) {
    final palette = KanbanPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ring ? palette.focus : palette.border,
          width: ring ? 2 : 1,
        ),
      ),
      child: face,
    );
  }

  Map<CustomSemanticsAction, VoidCallback> get _semanticActions => {
    for (final direction in KanbanDirection.values)
      if (widget.controller.canMove(_pos, direction))
        CustomSemanticsAction(label: KanbanCardMenu.label(direction)): () =>
            _move(direction),
    CustomSemanticsAction(label: AppStrings.actionDelete): _delete,
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lifted = Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      color: Colors.transparent,
      child: _surface(context, _face(context, lifted: true), ring: true),
    );
    final card = ListenableBuilder(
      listenable: _focus,
      builder: (context, _) => _surface(
        context,
        _face(context, lifted: false),
        ring: _focus.hasFocus && !_editing,
      ),
    );
    final tap = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      onSecondaryTapUp: (details) =>
          _menu.open(position: details.localPosition),
      child: card,
    );
    final body = _editing
        ? tap
        : KanbanCardDraggable(
            data: _pos,
            feedback: (width) => SizedBox(width: width, child: lifted),
            onStart: _dragStarted,
            onUpdate: widget.controller.dragUpdate,
            onEnd: _dragEnded,
            child: tap,
          );
    return Focus(
      focusNode: _focus,
      onKeyEvent: (node, event) => _editing
          ? KeyEventResult.ignored
          : KanbanCardKeys(
              onMove: _move,
              onEdit: _beginEdit,
              onDelete: _delete,
              onToggle: _toggle,
            ).handle(node, event),
      child: Semantics(
        container: true,
        label: AppStrings.kanbanCardLabel(
          widget.index + 1,
          widget.cardCount,
          widget.columnName,
        ),
        customSemanticsActions: _semanticActions,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(padding: const EdgeInsets.only(bottom: 8), child: body),
            KanbanDropBars(
              spot: widget.controller.spot,
              column: widget.column,
              index: widget.index,
              last: widget.index == widget.cardCount - 1,
            ),
          ],
        ),
      ),
    );
  }
}
