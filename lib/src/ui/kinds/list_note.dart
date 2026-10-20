import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/list_item_row.dart';
import 'package:niman/src/ui/kinds/list_parser.dart';
import 'package:niman/src/ui/kinds/shopping_parser.dart';
import 'package:niman/src/ui/kinds/shopping_quantity_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// The frontmatter a new list note is created with.
String listNoteContent() => '---\ntype: list\n---\n';

/// The `list` note kind (T-TK-04): a check-list GUI over the note's task
/// items.
final class ListKindGui implements NoteKindGUI {
  @override
  String get type => 'list';

  @override
  LibraryFeature get feature => LibraryFeature.kindList;

  @override
  Widget buildBody(BuildContext context, NoteKindHost host) {
    return ListNoteView(
      text: host.text,
      onChanged: host.applyEdit,
      onTapLink: host.openLink,
      onTapWikiLink: host.openWikiLink,
    );
  }
}

/// The list-kind body: the note's task items as checkable rows, nested by
/// indentation, plus an add row.
///
/// Prose in the note is invisible here (the raw editor shows it). Edits
/// are byte-stable ([flipListItem], [appendListItem], [editItemText],
/// [moveSubtree]): unmodified lines keep their bytes, and a moved item
/// keeps its bytes apart from the leading spaces.
///
/// [shopping] builds the same body for the `shopping-list` subtype
/// (#309): every item carries a quantity, edited beside its text and
/// kept in the item's own text as a `×2`.
class ListNoteView extends StatefulWidget {
  /// Creates the view; [onChanged] receives the new full note text.
  const new({
    required this.text,
    required this.onChanged,
    this.shopping = false,
    this.onTapLink,
    this.onTapWikiLink,
    super.key,
  });

  /// The full note text.
  final String text;

  /// Called with the new full note text after an edit; the host persists
  /// it.
  final ValueChanged<String> onChanged;

  /// Whether the body is a shopping list, with a quantity per item.
  final bool shopping;

  /// Follows a Markdown link in an item's text, where the host has a way
  /// (#1094); null draws the links without following them.
  final void Function(BuildContext context, String href)? onTapLink;

  /// Follows a wikilink in an item's text.
  final void Function(BuildContext context, String inner)? onTapWikiLink;

  @override
  State<ListNoteView> createState() => _ListNoteViewState();
}

/// The item being dragged (T-TK-09).
final class _Drag {
  new(this.index, this.position);

  final int index;

  /// Where the pointer last was, in global coordinates.
  Offset position;
}

/// Where a dragged item will land: the target item index in [mode], or
/// -1 (the zone above the list) / the item count (below it).
final class _DropTarget {
  const new(this.item, this.mode);

  final int item;
  final ListDropMode mode;
}

class _ListNoteViewState extends State<ListNoteView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late List<ListItem> _items;
  final TextEditingController _newItem = TextEditingController();

  /// The items' formulas, shared by the rows (#1094).
  final MathCache _mathCache = MathCache();

  /// The add field's focus: an add hands it back to the field so the next
  /// item is typed at once, whichever of Enter or the check button added.
  final FocusNode _addFocus = FocusNode();

  /// The quantity the add row will write; one is the absence of a marker,
  /// and the chip resets to it after every add.
  int _newQuantity = 1;

  final ScrollController _scroll = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final Map<int, GlobalKey> _rowKeys = {};

  /// The first and last item index the last layout built: the drop is read
  /// against those rows only, whatever the note's length (#720) — walking
  /// every item a frame cost the list's own length.
  ///
  /// The drag source is left out (#777): it is kept alive, so the list
  /// rebuilds it wherever it scrolled to, and taking its index in would
  /// stretch the walk from it to the viewport — a span that grows with the
  /// distance the edge scroll covered. [_dropAt] reads it on its own.
  int? _builtFirst;
  int? _builtLast;

  int? _editingIndex;

  /// Whether the next rebuild is the one a just-added item landed in: the
  /// list then takes the scroll to its new foot.
  bool _scrollToEnd = false;

  /// A commit the row is about to deliver whose item the delete already
  /// took: the row is reused for the item that shifted into its place,
  /// and that item must not be overwritten with the deleted one's text.
  bool _cancelPendingCommit = false;
  _Drag? _drag;
  _DropTarget? _drop;

  /// How deep into the list an edge reaches, and how fast a held drag
  /// scrolls a frame at the very edge: the tree's own numbers (#580,
  /// #720).
  static const double _edge = 48;
  static const double _maxEdgeSpeed = 16;

  /// The signed scroll a frame while a drag is held at an edge; zero away
  /// from the edges.
  double _edgeSpeed = 0;

  /// Runs the edge scroll a frame at a time while a dragged pointer stays
  /// in an edge zone (#720): a held finger keeps the list moving, which a
  /// jump per move event never did, and it stops with the drag.
  Timer? _edgeTicker;

  /// How deep into an edge zone the drag was picked up (signed like
  /// [_edgeSpeed]), until the pointer goes past it; null once it has, or
  /// when the pickup was outside both zones.
  ///
  /// The top and bottom rows on screen lie mostly inside the zones, and a
  /// long press picks a row up with a still finger (#777): scrolling from
  /// the pickup itself moved the list away from a thumb that never asked
  /// for it. The scroll starts once the pointer moves deeper into the
  /// zone than the pickup, or leaves the zone and comes back.
  double? _pickupDepth;

  /// Drives the add row's show/hide: it steps aside while a row is being
  /// edited in place, so the edited row is never hidden behind it.
  late final AnimationController _addRowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final CurvedAnimation _addRowShown = CurvedAnimation(
    parent: _addRowController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  /// Whether the software keyboard was up at the last metrics change.
  ///
  /// Dismissals are edge-triggered (open, then closed) so a stray
  /// zero-inset frame around gaining focus can never end an edit.
  bool _keyboardOpen = false;

  @override
  void initState() {
    super.initState();
    _items = _parse(widget.text);
    WidgetsBinding.instance.addObserver(this);
    _focusAddFieldOnDesktop();
  }

  /// Opening the list on a desktop puts the caret in the add field: there
  /// is a keyboard already, and typing is what the note is for. A phone
  /// would pop its soft keyboard over the list, so it waits for a tap.
  ///
  /// Asked for once the frame has put the field under its focus node (the
  /// field's `autofocus` gives way to whatever its scope already focused),
  /// and not taken from a text field that already has the keyboard.
  void _focusAddFieldOnDesktop() {
    if (!_isDesktop) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editingIndex != null || _addFocus.hasFocus) return;
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused != null &&
          (focused.widget is EditableText ||
              focused.findAncestorWidgetOfExactType<EditableText>() != null)) {
        return;
      }
      _addFocus.requestFocus();
    });
  }

  static bool get _isDesktop => switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.windows ||
    TargetPlatform.macOS => true,
    _ => false,
  };

  /// The items of [text], with quantities when this is a shopping list.
  List<ListItem> _parse(String text) =>
      widget.shopping ? parseShoppingItems(text) : parseListItems(text);

  /// Ends an in-place edit when the software keyboard is dismissed
  /// (issue #5).
  ///
  /// On Android the back gesture closes the IME but leaves the field
  /// focused, so the row's focus-loss commit never runs and the add row
  /// stays hidden until the note is reopened. Closing the edit here takes
  /// the same path as any other finish: the row sees `isEditing` go false
  /// and commits.
  ///
  /// One observer for the whole list, not one per row. Every row used to
  /// register its own, so a hundred-item list registered a hundred
  /// observers and each keyboard or rotation event walked all of them —
  /// and only one row is ever editing, which this state already knows.
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final open = WidgetsBinding.instance.platformDispatcher.views.any(
      (view) => view.viewInsets.bottom / view.devicePixelRatio > 0,
    );
    final dismissed = _keyboardOpen && !open;
    _keyboardOpen = open;
    if (dismissed && _editingIndex != null && mounted) {
      setState(() => _setEditing(null));
    }
  }

  /// Opens ([index]) or closes (null) the in-place edit, animating the
  /// add row out of the way with it.
  void _setEditing(int? index) {
    _editingIndex = index;
    if (index == null) {
      _addRowController.forward();
    } else {
      _addRowController.reverse();
    }
  }

  @override
  void didUpdateWidget(ListNoteView old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      final oldItems = _items;
      _items = _parse(widget.text);
      _drag = null;
      _drop = null;
      // An open in-place edit survives the rebuild unless its own line
      // changed (a committed edit or a pencil edit under the field).
      final e = _editingIndex;
      if (e != null &&
          (e >= _items.length ||
              oldItems[e].text != _items[e].text ||
              oldItems[e].quantity != _items[e].quantity)) {
        _setEditing(null);
      }
      if (_scrollToEnd) {
        _scrollToEnd = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNewItem());
      }
    }
  }

  /// Takes the list to the item just added, so it is on screen when the
  /// field is empty again.
  ///
  /// The add row sits outside the scroll view, at the viewport's foot: a
  /// new line lands under it, and without this the list stayed where it
  /// was until the writer scrolled by hand.
  void _scrollToNewItem() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent) return;
    unawaited(
      _scroll
          .animateTo(
            position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          )
          // The extent a sliver reports is an estimate until its last child
          // is built: the glide lands, building the new item can move the
          // foot a little further, and the rest is a jump rather than a
          // second animation.
          .whenComplete(() {
            if (!mounted || !_scroll.hasClients) return;
            final landed = _scroll.position;
            if (landed.pixels < landed.maxScrollExtent) {
              landed.jumpTo(landed.maxScrollExtent);
            }
          }),
    );
  }

  @override
  void dispose() {
    _stopEdgeScroll();
    WidgetsBinding.instance.removeObserver(this);
    _newItem.dispose();
    _addFocus.dispose();
    _scroll.dispose();
    _addRowShown.dispose();
    _addRowController.dispose();
    _mathCache.dispose();
    super.dispose();
  }

  GlobalKey _rowKey(int index) => _rowKeys.putIfAbsent(index, GlobalKey.new);

  void _toggle(int index) {
    widget.onChanged(flipListItem(widget.text, _items[index]));
  }

  void _add() {
    // The check button took the focus with the click: give it back, an
    // empty field included.
    _addFocus.requestFocus();
    final text = _newItem.text.trim();
    if (text.isEmpty) return;
    _newItem.clear();
    _scrollToEnd = true;
    if (!widget.shopping) {
      widget.onChanged(appendListItem(widget.text, text));
      return;
    }
    // A typed `latte x2` carries its own quantity; the chip wins when it
    // was moved off one, since that was a deliberate choice too.
    final typed = parseShoppingItems('- [ ] $text\n').first;
    final quantity = _newQuantity > 1 ? _newQuantity : typed.quantity;
    if (_newQuantity != 1) setState(() => _newQuantity = 1);
    widget.onChanged(appendShoppingItem(widget.text, typed.text, quantity));
  }

  void _beginEdit(int index) {
    if (_drag != null) return;
    _cancelPendingCommit = false;
    setState(() => _setEditing(index));
  }

  void _commitEdit(int index, String raw, int quantity) {
    if (!mounted) return;
    if (_cancelPendingCommit) {
      _cancelPendingCommit = false;
      return;
    }
    if (index >= _items.length) return;
    final text = raw.trim();
    final item = _items[index];
    if (widget.shopping) {
      if (text == item.text && quantity == item.quantity) {
        if (_editingIndex == index) setState(() => _setEditing(null));
        return;
      }
      widget.onChanged(editShoppingItem(widget.text, item, text, quantity));
      return;
    }
    if (text == item.text) {
      if (_editingIndex == index) setState(() => _setEditing(null));
      return;
    }
    widget.onChanged(editItemText(widget.text, item, text));
  }

  /// Deletes the item at [index] and its whole subtree, at once, and
  /// offers the whole block back through the snackbar's Undo.
  ///
  /// A confirmation would stand between the trash and every single item
  /// nobody meant to remove; the Undo covers the one that was, and the
  /// editor's own history covers it too.
  void _delete(int index) {
    final items = _items;
    final item = items[index];
    final end = subtreeEnd(items, index, listLineCount(widget.text));
    final block = widget.text.split('\n').sublist(item.line, end);
    if (_editingIndex == index) {
      _cancelPendingCommit = true;
      setState(() => _setEditing(null));
    }
    widget.onChanged(deleteListItem(widget.text, items, index));
    _offerUndo(block, item.line);
  }

  /// The snackbar a delete leaves behind: Undo puts [block] back at
  /// [atLine], byte for byte.
  void _offerUndo(List<String> block, int atLine) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // An action would keep it up until it is dismissed by hand (#508).
          persist: false,
          content: Text(AppStrings.deletedMessage),
          action: SnackBarAction(
            label: AppStrings.actionUndo,
            onPressed: () {
              if (!mounted) return;
              widget.onChanged(insertListLines(widget.text, atLine, block));
            },
          ),
        ),
      );
  }

  void _onDragStart(int index, Offset global) {
    if (_drag != null) return;
    unawaited(HapticFeedback.mediumImpact());
    _drag = _Drag(index, global);
    _drop = _dropAt(global);
    final depth = _edgeDepth(global);
    _pickupDepth = depth == 0 ? null : depth;
    setState(() {});
  }

  void _onDragMove(Offset global) {
    final drag = _drag;
    if (drag == null) return;
    drag.position = global;
    _followEdge(global);
    _readDrop();
  }

  void _onDragEnd() {
    // The scroll stops with the drag, and the drop is read again before
    // the drag is let go: the list may have moved since the last move
    // event, so the remembered target is not the one under the pointer
    // (#720).
    _stopEdgeScroll();
    final drag = _drag;
    final drop = drag == null ? null : _dropAt(drag.position);
    setState(() {
      _drag = null;
      _drop = null;
    });
    if (drag == null || drop == null) return;
    final resolved = resolveListDrop(
      _items,
      drag.index,
      drop.item,
      drop.mode,
      listLineCount(widget.text),
    );
    if (resolved == null) return;
    unawaited(HapticFeedback.mediumImpact());
    widget.onChanged(
      moveSubtree(
        widget.text,
        _items,
        drag.index,
        insertLine: resolved.insertLine,
        indent: resolved.indent,
      ),
    );
  }

  /// A press on the row at [index] ended without a drop.
  ///
  /// Flutter reports every press that ends before the long-press timeout
  /// — every tap — as a cancelled long press (#778): only the drag
  /// source's own cancel ends the drag. Any other row's is a tap, and a
  /// second finger tapping another row mid-drag must not drop the drag,
  /// nor any tap cost a rebuild of the list.
  void _onDragCancel(int index) {
    if (_drag?.index != index) return;
    _stopEdgeScroll();
    setState(() {
      _drag = null;
      _drop = null;
    });
  }

  /// Lights the drop under the drag's last position, when it changed: the
  /// list scrolls under the finger, so the row a line falls on moves with
  /// it.
  void _readDrop() {
    final drag = _drag;
    if (drag == null) return;
    final drop = _dropAt(drag.position);
    if (!_sameDrop(drop, _drop)) setState(() => _drop = drop);
  }

  bool _sameDrop(_DropTarget? a, _DropTarget? b) =>
      a == null ? b == null : b != null && a.item == b.item && a.mode == b.mode;

  /// The drop target under [global], or null (no indicator).
  ///
  /// Read against the rows as they stand (#720): with the list scrolled
  /// under the finger, the row a line falls on is not the one the last
  /// move saw. A pointer above every row, or below every row — the space
  /// at the list's head or foot — is the zone before the first root item
  /// or after the last one, rather than nothing, so a release there lands.
  _DropTarget? _dropAt(Offset global) {
    final items = _items;
    final drag = _drag;
    if (items.isEmpty || drag == null) return null;
    final listBox = _listBox();
    if (listBox == null) return null;
    final listRect = listBox.localToGlobal(Offset.zero) & listBox.size;
    if (global.dx < listRect.left || global.dx > listRect.right) return null;
    if (global.dy < listRect.top || global.dy > listRect.bottom) return null;

    final dragLine = items[drag.index].line;
    final dragEnd = subtreeEnd(items, drag.index, listLineCount(widget.text));
    final from = _builtFirst ?? 0;
    final to = _builtLast ?? items.length - 1;
    // Over the dragged row or one of its own children: no drop. The
    // dragged row is outside the window (see [_builtFirst]): read on its
    // own.
    bool over(int j) {
      final box = _rowBox(j);
      if (box == null) return false;
      final top = box.localToGlobal(Offset.zero).dy;
      return global.dy >= top && global.dy < top + box.size.height;
    }

    if (over(drag.index)) return null;
    for (var j = from; j <= to; j++) {
      final line = items[j].line;
      if (line <= dragLine || line >= dragEnd) continue;
      if (over(j)) return null;
    }

    _DropTarget? past;
    for (var j = from; j <= to; j++) {
      if (j == drag.index) continue;
      final line = items[j].line;
      if (line > dragLine && line < dragEnd) continue; // own subtree
      final box = _rowBox(j);
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final height = box.size.height;
      if (global.dy < top) {
        // Above every row there is: the list's head is on screen and the
        // pointer is in the space before it — the first root item (#777).
        if (past == null) return const _DropTarget(-1, ListDropMode.before);
        // The first row on screen below the pointer: before it.
        return _DropTarget(j, ListDropMode.before);
      }
      if (global.dy >= top + height) {
        past = _DropTarget(j, ListDropMode.after);
        continue;
      }
      final rel = (global.dy - top) / height;
      return _DropTarget(
        j,
        rel < 0.25
            ? ListDropMode.before
            : rel > 0.75
            ? ListDropMode.after
            : ListDropMode.under,
      );
    }
    // Below every row there is: rows fill the viewport to its edge unless
    // the list's foot is on screen, so the pointer is in the space after
    // the last item — the last root item (#777), not a child of whatever
    // row ends the list.
    return past == null ? null : _DropTarget(items.length, ListDropMode.after);
  }

  RenderBox? _rowBox(int index) {
    final key = _rowKeys[index];
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    return box is RenderBox ? box : null;
  }

  RenderBox? _listBox() {
    final ctx = _listKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    return box is RenderBox ? box : null;
  }

  /// A dragged pointer at [global] near a list edge: the list scrolls
  /// toward it a frame at a time, faster the closer it is — the tree's
  /// treatment of the same edge (#580, #720).
  ///
  /// [ScrollPosition.jumpTo], not `correctBy`: the latter is a layout-time
  /// correction that moves the offset without notifying anyone, so the
  /// list only actually scrolled on the frames something else happened to
  /// rebuild it.
  void _followEdge(Offset global) {
    if (!_scroll.hasClients) return _stopEdgeScroll();
    final depth = _edgeDepth(global);
    final pickup = _pickupDepth;
    if (pickup != null) {
      // Where the drag was picked up, or nearer the middle: no scroll yet.
      final sameZone = depth != 0 && depth.sign == pickup.sign;
      if (sameZone && depth.abs() <= pickup.abs()) return _stopEdgeScroll();
      _pickupDepth = null;
    }
    if (depth == 0) return _stopEdgeScroll();
    _edgeSpeed = (depth / _edge).clamp(-1.0, 1.0) * _maxEdgeSpeed;
    _edgeTicker ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _tickEdgeScroll(),
    );
  }

  /// How deep [global] is into the list's top (negative) or bottom
  /// (positive) edge zone; zero between them, or with no list laid out.
  double _edgeDepth(Offset global) {
    final box = _listBox();
    if (box == null) return 0;
    final local = box.globalToLocal(global);
    if (local.dy < _edge) return local.dy - _edge;
    if (local.dy > box.size.height - _edge) {
      return local.dy - (box.size.height - _edge);
    }
    return 0;
  }

  /// One frame of the edge scroll: the list moves a step, and the drop is
  /// read again so the indicator follows the content under the finger.
  void _tickEdgeScroll() {
    if (!mounted || _drag == null) return _stopEdgeScroll();
    if (!_scroll.hasClients) return _stopEdgeScroll();
    final position = _scroll.position;
    final target = (position.pixels + _edgeSpeed).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return; // the end: nothing to scroll
    _scroll.jumpTo(target);
    _readDrop();
  }

  /// Ends the edge scroll: the drag let go, left the edge, or went.
  void _stopEdgeScroll() {
    _edgeTicker?.cancel();
    _edgeTicker = null;
    _edgeSpeed = 0;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    // The window is filled again by the itemBuilder calls the layout makes
    // after this build (#720).
    _builtFirst = null;
    _builtLast = null;
    return Padding(
      padding: EdgeInsets.only(
        // Raised above the bottom edge: phones with rounded screen
        // corners clip the add row's own corners there.
        bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.listEmpty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    key: _listKey,
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      if (index != _drag?.index) {
                        _builtFirst = _builtFirst == null
                            ? index
                            : math.min(_builtFirst!, index);
                        _builtLast = _builtLast == null
                            ? index
                            : math.max(_builtLast!, index);
                      }
                      final item = items[index];
                      ListDropMode? indicator;
                      final drop = _drop;
                      if (drop != null) {
                        if (drop.item == index) {
                          indicator = drop.mode;
                        } else if (drop.item == -1 && index == 0) {
                          indicator = ListDropMode.before;
                        } else if (drop.item == items.length &&
                            index == items.length - 1) {
                          indicator = ListDropMode.after;
                        }
                      }
                      return ListItemRow(
                        key: _rowKey(index),
                        item: item,
                        shopping: widget.shopping,
                        mathCache: _mathCache,
                        onTapLink: widget.onTapLink,
                        onTapWikiLink: widget.onTapWikiLink,
                        isDragSource: _drag?.index == index,
                        isEditing: _editingIndex == index,
                        indicator: indicator,
                        onToggle: () => _toggle(index),
                        onBeginEdit: () => _beginEdit(index),
                        onCommitEdit: (text, quantity) =>
                            _commitEdit(index, text, quantity),
                        onDelete: () => _delete(index),
                        onDragStart: (global) => _onDragStart(index, global),
                        onDragMove: _onDragMove,
                        onDragEnd: _onDragEnd,
                        onDragCancel: () => _onDragCancel(index),
                      );
                    },
                  ),
          ),
          _addRow(context),
        ],
      ),
    );
  }

  Widget _addRow(BuildContext context) {
    return SizeTransition(
      key: const Key('list-add-row'),
      sizeFactor: _addRowShown,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _addRowShown, child: _addField(context)),
    );
  }

  Widget _addField(BuildContext context) {
    return Padding(
      // Inset from the screen edges, which are rounded on most phones.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: TextField(
        key: const Key('list-add-field'),
        controller: _newItem,
        focusNode: _addFocus,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        decoration: InputDecoration(
          hintText: AppStrings.listAddHint,
          prefixIcon: widget.shopping ? null : const Icon(Icons.add),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.shopping) _addQuantityButton(context),
              IconButton(
                key: const Key('list-add-button'),
                icon: const Icon(Icons.check),
                tooltip: AppStrings.listAddTooltip,
                onPressed: _add,
              ),
            ],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        // Not `onSubmitted`: the field's own handling of the action ends
        // by unfocusing it, which dropped the keyboard on a phone and the
        // caret on a desktop after every item.
        onEditingComplete: _add,
      ),
    );
  }

  /// The add row's quantity chip: what the next item is written with,
  /// reset to one after every add.
  Widget _addQuantityButton(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: AppStrings.shoppingQuantityLabel,
      child: InkWell(
        key: const Key('list-add-quantity'),
        borderRadius: BorderRadius.circular(14),
        onTap: _pickAddQuantity,
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('×$_newQuantity', style: theme.textTheme.labelMedium),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAddQuantity() async {
    final picked = await showShoppingQuantitySheet(
      context,
      quantity: _newQuantity,
    );
    if (picked == null || !mounted) return;
    setState(() => _newQuantity = picked);
  }
}
