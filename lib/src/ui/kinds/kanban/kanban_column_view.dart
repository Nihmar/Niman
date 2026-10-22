import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/kanban/kanban_column.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_add_field.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_board_controller.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_tile.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_column_header.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_drop_bar.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_palette.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';
import 'package:niman/src/ui/strings.dart';

/// One column of the board (#1167): a tinted, rounded lane of [width] with
/// its header, its cards in a list of their own and **+ Add a card** at the
/// foot, which stays in view while the cards scroll.
final class KanbanColumnView extends StatefulWidget {
  /// Column [index], [column] of the board.
  const new({
    required this.controller,
    required this.index,
    required this.column,
    super.key,
  });

  /// The width of a column.
  static const double width = 296;

  /// What the board shares.
  final KanbanBoardController controller;

  /// The column's index.
  final int index;

  /// The column.
  final KanbanColumn column;

  @override
  State<KanbanColumnView> createState() => KanbanColumnViewState();
}

/// The state of a [KanbanColumnView]: the board asks it where a card would
/// land, scrolls it under a held drag and hands the focus to a card of it.
final class KanbanColumnViewState extends State<KanbanColumnView> {
  final ScrollController _scroll = ScrollController();
  final Set<KanbanCardTileState> _tiles = <KanbanCardTileState>{};
  final GlobalKey _listKey = GlobalKey();
  bool _scrollToEnd = false;

  @override
  void didUpdateWidget(KanbanColumnView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scrollToEnd &&
        widget.column.cards.length > oldWidget.column.cards.length) {
      _scrollToEnd = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The column's rectangle on screen, null while it is not laid out.
  Rect? get bounds => _boundsOf(context);

  /// The rectangle the cards scroll in, on screen.
  Rect? get listBounds {
    final listContext = _listKey.currentContext;
    return listContext == null ? null : _boundsOf(listContext);
  }

  static Rect? _boundsOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// The gap a card dropped at global height [y] would take: the index of the
  /// first card built whose middle is below [y], or the end of the built ones.
  int slotAt(double y) {
    if (_tiles.isEmpty) return 0;
    int? before;
    var last = 0;
    for (final tile in _tiles) {
      last = math.max(last, tile.index);
      final middle = tile.centerY;
      if (middle != null && y < middle) {
        before = before == null ? tile.index : math.min(before, tile.index);
      }
    }
    return before ?? last + 1;
  }

  /// Scrolls the cards by [delta], as a drag held at their edge does.
  void scrollBy(double delta) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) position.jumpTo(target);
  }

  /// Gives card [index] the focus. A card out of the built ones is brought
  /// into them by scrolling to where it should be, and focused when it is.
  void focusCard(int index) {
    if (_focusBuilt(index)) return;
    final count = widget.column.cards.length;
    if (count == 0 || !_scroll.hasClients) return;
    final position = _scroll.position;
    position.jumpTo(
      (position.maxScrollExtent * index / count).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusBuilt(index);
    });
  }

  bool _focusBuilt(int index) {
    for (final tile in _tiles) {
      if (tile.index == index) {
        tile.focus();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = KanbanPalette.of(context);
    final column = widget.column;
    final cards = column.cards;
    return SizedBox(
      width: KanbanColumnView.width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.column,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KanbanColumnHeader(
              controller: widget.controller,
              column: widget.index,
              name: column.name,
              count: cards.length,
            ),
            Expanded(
              child: cards.isEmpty
                  ? _empty()
                  : ListView.builder(
                      key: _listKey,
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                      itemCount: cards.length,
                      itemBuilder: (context, i) => KanbanCardTile(
                        key: ValueKey(i),
                        controller: widget.controller,
                        registry: _tiles,
                        column: widget.index,
                        index: i,
                        card: cards[i],
                        columnName: column.name,
                        cardCount: cards.length,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
              child: KanbanAddField(
                label: AppStrings.kanbanAddCard,
                hint: AppStrings.kanbanCardHint,
                keepOpen: true,
                onAdd: (title) {
                  _scrollToEnd = true;
                  widget.controller.edits.addCard(widget.index, title);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// An empty column: a place a card can be dropped, marked when one would.
  Widget _empty() {
    return Padding(
      key: _listKey,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: ValueListenableBuilder<DropSpot?>(
        valueListenable: widget.controller.spot,
        builder: (context, spot, _) => Align(
          alignment: Alignment.topCenter,
          child: spot?.column == widget.index
              ? const KanbanDropBar()
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
