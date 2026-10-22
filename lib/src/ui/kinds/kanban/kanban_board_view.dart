import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_add_field.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_board_controller.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_column_view.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_edits.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';
import 'package:niman/src/ui/strings.dart';

/// The board on a wide window (#1167): the columns side by side, the board
/// scrolling sideways, the cards dragged between and within the columns.
///
/// The note's text is the only state: the board is read from it again on
/// every change, and every action is one edit of it through the host.
final class KanbanBoardView extends StatefulWidget {
  /// The board of [text], the note [host] holds.
  const new({required this.text, required this.host, super.key});

  /// The full note text.
  final String text;

  /// The note's window: its text, its edits, its links.
  final NoteKindHost host;

  @override
  State<KanbanBoardView> createState() => _KanbanBoardViewState();
}

final class _KanbanBoardViewState extends State<KanbanBoardView> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _viewportKey = GlobalKey();
  final List<GlobalKey<KanbanColumnViewState>> _columnKeys = [];
  final MathCache _math = MathCache();
  late KanbanBoard _board;
  late final KanbanBoardController _controller;

  /// Where the dragged pointer last was; null until it has moved.
  Offset? _pointer;
  Timer? _ticker;

  /// How deep into an edge a held drag scrolls, and how fast at the very
  /// edge, in logical pixels a frame.
  static const double _edge = 56;
  static const double _maxSpeed = 16;

  @override
  void initState() {
    super.initState();
    _board = parseKanban(widget.text);
    _controller =
        KanbanBoardController(
            host: widget.host,
            mathCache: _math,
            announce: _announce,
            board: _board,
            edits: KanbanEdits(text: widget.text, host: widget.host),
          )
          ..dragUpdate = _onDragUpdate
          ..dragging.addListener(_onDragging);
  }

  @override
  void didUpdateWidget(KanbanBoardView old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    _board = parseKanban(widget.text);
    final focus = _controller.pendingFocus;
    _controller.pendingFocus = null;
    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _columnKeys
              .elementAtOrNull(focus.column)
              ?.currentState
              ?.focusCard(focus.card);
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller
      ..dragging.removeListener(_onDragging)
      ..dispose();
    _scroll.dispose();
    _math.dispose();
    super.dispose();
  }

  void _announce(String message) {
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  /// A drag began or ended: the edge scroll runs for as long as it is held.
  void _onDragging() {
    if (_controller.dragging.value == null) {
      _ticker?.cancel();
      _ticker = null;
      _pointer = null;
    } else {
      _ticker ??= Timer.periodic(
        const Duration(milliseconds: 16),
        (_) => _tick(),
      );
    }
  }

  void _onDragUpdate(Offset position) {
    _pointer = position;
    _refreshSpot();
  }

  /// The column nearest to the global horizontal position [x].
  int? _columnAt(double x) {
    int? best;
    var bestDistance = double.infinity;
    for (var i = 0; i < _columnKeys.length; i++) {
      final bounds = _columnKeys[i].currentState?.bounds;
      if (bounds == null) continue;
      final distance = x < bounds.left
          ? bounds.left - x
          : (x > bounds.right ? x - bounds.right : 0.0);
      if (distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    return best;
  }

  Rect? get _viewport {
    final box = _viewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Reads the gap the pointer is over: none off the board.
  void _refreshSpot() {
    final point = _pointer;
    final from = _controller.dragging.value;
    final area = _viewport;
    if (point == null || from == null) return;
    final column = area != null && area.contains(point)
        ? _columnAt(point.dx)
        : null;
    final state = column == null ? null : _columnKeys[column].currentState;
    _controller.spot.value = column == null || state == null
        ? null
        : effectiveSpot(from, (column: column, slot: state.slotAt(point.dy)));
  }

  /// The signed scroll a frame of a pointer at [at] in the span [from]-[to].
  static double _speed(double at, double from, double to) {
    if (at < from + _edge) {
      return -_maxSpeed * ((from + _edge - at) / _edge).clamp(0, 1);
    }
    if (at > to - _edge) {
      return _maxSpeed * ((at - (to - _edge)) / _edge).clamp(0, 1);
    }
    return 0;
  }

  void _tick() {
    final point = _pointer;
    final area = _viewport;
    if (point == null || area == null || !area.contains(point)) return;
    var moved = false;
    final sideways = _speed(point.dx, area.left, area.right);
    if (sideways != 0 && _scroll.hasClients) {
      final position = _scroll.position;
      final target = (position.pixels + sideways).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (target != position.pixels) {
        position.jumpTo(target);
        moved = true;
      }
    }
    final column = _columnAt(point.dx);
    final state = column == null ? null : _columnKeys[column].currentState;
    final list = state?.listBounds;
    if (state != null && list != null) {
      final vertical = _speed(point.dy, list.top, list.bottom);
      if (vertical != 0) {
        state.scrollBy(vertical);
        moved = true;
      }
    }
    if (moved) _refreshSpot();
  }

  @override
  Widget build(BuildContext context) {
    _controller
      ..host = widget.host
      ..board = _board
      ..edits = KanbanEdits(text: widget.text, host: widget.host);
    final columns = _board.columns;
    while (_columnKeys.length < columns.length) {
      _columnKeys.add(GlobalKey<KanbanColumnViewState>());
    }
    if (_columnKeys.length > columns.length) {
      _columnKeys.removeRange(columns.length, _columnKeys.length);
    }
    return Container(
      key: _viewportKey,
      child: Scrollbar(
        controller: _scroll,
        child: SingleChildScrollView(
          key: const Key('kanban-board'),
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                KanbanColumnView(
                  key: _columnKeys[i],
                  controller: _controller,
                  index: i,
                  column: columns[i],
                ),
                const SizedBox(width: 12),
              ],
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: KanbanColumnView.width,
                  child: KanbanAddField(
                    label: AppStrings.kanbanAddColumn,
                    hint: AppStrings.kanbanColumnHint,
                    onAdd: (name) {
                      _controller.edits.addColumn(name);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _scroll.hasClients) {
                          _scroll.animateTo(
                            _scroll.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
