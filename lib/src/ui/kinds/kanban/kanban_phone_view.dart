import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/kanban/board_edit_scope.dart' show oneLine;
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_text.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_column_page.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_edits.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_move_sheet.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_tab_strip.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_text_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// The board on a phone, or in a body too narrow for columns side by side
/// (#1168): one column at a time, swiped, a tab per column along the top.
///
/// A card is moved from its sheet (long press): **Move to…** another
/// column, up or down its own. There is no drag across columns on a narrow
/// screen.
///
/// The note's text is the only state: the board is read from it again on
/// every change and every action is one edit of it through the host. The
/// only state of the view is the selected column, which survives the edits
/// and is kept inside the board when columns come or go.
final class KanbanPhoneView extends StatefulWidget {
  /// The board of [text], the note [host] holds.
  const new({required this.text, required this.host, super.key});

  /// The full note text.
  final String text;

  /// The note's window: its text, its edits, its links.
  final NoteKindHost host;

  @override
  State<KanbanPhoneView> createState() => _KanbanPhoneViewState();
}

final class _KanbanPhoneViewState extends State<KanbanPhoneView>
    with TickerProviderStateMixin {
  final MathCache _math = MathCache();
  late KanbanBoard _board;
  TabController? _tabs;

  /// A column was just added: the board shows it once it is read.
  bool _selectLast = false;

  @override
  void initState() {
    super.initState();
    _board = parseKanban(widget.text);
    _syncTabs();
  }

  @override
  void didUpdateWidget(KanbanPhoneView old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    _board = parseKanban(widget.text);
    final count = _board.columns.length;
    _syncTabs(select: _selectLast && count > 0 ? count - 1 : null);
    _selectLast = false;
  }

  @override
  void dispose() {
    _tabs?.dispose();
    _math.dispose();
    super.dispose();
  }

  /// Gives the tabs one per column, on the column that was selected (or
  /// [select]) kept inside the board.
  void _syncTabs({int? select}) {
    final count = _board.columns.length;
    final old = _tabs;
    if (old != null && old.length == count && select == null) return;
    final index = count == 0
        ? 0
        : (select ?? old?.index ?? 0).clamp(0, count - 1);
    _tabs = count == 0
        ? null
        : TabController(length: count, vsync: this, initialIndex: index);
    if (old != null) {
      // The tab bar still holds the old controller until it is rebuilt.
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  KanbanEdits get _edits => KanbanEdits(text: widget.text, host: widget.host);

  int get _selected => _tabs?.index ?? 0;

  void _announce(String message) {
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  /// Moves a card of [board] to [to] through [edits]; says where it went.
  void _moveTo(KanbanEdits edits, KanbanBoard board, CardPos from, CardPos to) {
    final moved = edits.move(
      fromColumn: from.column,
      fromCard: from.card,
      toColumn: to.column,
      toIndex: to.card,
    );
    if (!moved) return;
    final total =
        board.columns[to.column].cards.length +
        (to.column == from.column ? 0 : 1);
    _announce(
      AppStrings.kanbanMovedTo(
        board.columns[to.column].name,
        to.card + 1,
        total,
      ),
    );
  }

  void _moveWithin(int column, int card, KanbanDirection direction) {
    final at = (column: column, card: card);
    final to = moveTarget(_board, at, direction);
    if (to != null) _moveTo(_edits, _board, at, to);
  }

  /// Asks for the card's title and retitles it. [edits] and [board] are
  /// those the card was drawn from: if the note moves on while the sheet is
  /// open, the edit is dropped rather than land on another card.
  Future<void> _editCard(
    KanbanEdits edits,
    KanbanBoard board,
    int column,
    int card,
  ) async {
    final title = await showKanbanTextSheet(
      context,
      title: AppStrings.kanbanEditCard,
      hint: AppStrings.kanbanCardHint,
      initial: board.columns[column].cards[card].title,
    );
    if (title == null) return;
    final one = oneLine(title);
    if (one.isNotEmpty) edits.retitle(column, card, one);
  }

  Future<void> _cardSheet(int column, int card) async {
    final board = _board;
    final edits = _edits;
    final columns = board.columns;
    final choice = await showKanbanMoveSheet(
      context,
      cardTitle: cardShownTitle(columns[column].cards[card].title),
      columnNames: [for (final c in columns) c.name],
      column: column,
      canMoveUp: card > 0,
      canMoveDown: card < columns[column].cards.length - 1,
    );
    if (choice == null || !mounted) return;
    final at = (column: column, card: card);
    switch (choice) {
      case KanbanMoveToColumn(column: final target):
        _moveTo(edits, board, at, (
          column: target,
          card: columns[target].cards.length,
        ));
      case KanbanMoveWithin(:final direction):
        final to = moveTarget(board, at, direction);
        if (to != null) _moveTo(edits, board, at, to);
      case KanbanEditChoice():
        unawaited(_editCard(edits, board, column, card));
      case KanbanDeleteChoice():
        edits.deleteCard(column, card);
    }
  }

  Future<void> _addColumn() async {
    final edits = _edits;
    final name = await showKanbanTextSheet(
      context,
      title: AppStrings.kanbanAddColumn,
      hint: AppStrings.kanbanColumnHint,
    );
    if (name == null || !mounted) return;
    _selectLast = true;
    if (!edits.addColumn(name)) _selectLast = false;
  }

  Future<void> _renameColumn() async {
    final edits = _edits;
    final column = _selected;
    final name = await showKanbanTextSheet(
      context,
      title: AppStrings.actionRename,
      hint: AppStrings.kanbanColumnHint,
      initial: _board.columns[column].name,
    );
    if (name == null || !mounted) return;
    edits.renameColumn(column, name);
  }

  @override
  Widget build(BuildContext context) {
    final columns = _board.columns;
    final tabs = _tabs;
    return Column(
      children: [
        KanbanTabStrip(
          columns: columns,
          controller: tabs,
          onRename: () => unawaited(_renameColumn()),
          onDeleteColumn: () => _edits.deleteColumn(_selected),
          onAddColumn: () => unawaited(_addColumn()),
        ),
        Expanded(
          child: tabs == null
              ? Center(
                  child: OutlinedButton.icon(
                    key: const Key('kanban-add-column-empty'),
                    icon: const Icon(Icons.add),
                    label: Text(AppStrings.kanbanAddColumn),
                    onPressed: () => unawaited(_addColumn()),
                  ),
                )
              : TabBarView(
                  key: const Key('kanban-pages'),
                  controller: tabs,
                  children: [
                    for (var i = 0; i < columns.length; i++)
                      KanbanColumnPage(
                        index: i,
                        column: columns[i],
                        host: widget.host,
                        mathCache: _math,
                        onToggle: (card) => _edits.toggle(i, card),
                        onEdit: (card) =>
                            unawaited(_editCard(_edits, _board, i, card)),
                        onMenu: (card) => unawaited(_cardSheet(i, card)),
                        onMove: (card, direction) =>
                            _moveWithin(i, card, direction),
                        onDelete: (card) => _edits.deleteCard(i, card),
                        onAdd: (title) => _edits.addCard(i, title),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
