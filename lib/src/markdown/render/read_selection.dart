/// Selecting text in the read view (#283): Flutter's own selection over the
/// blocks — handles and a toolbar on a phone, a mouse drag and a context
/// menu on desktop, Ctrl+C and Ctrl+A with the keyboard — and where the
/// selection is, in the note's own terms: the block it starts in and its
/// characters there.
///
/// Every block is wrapped in a [SelectionListener] ([SelectableBlock]) that
/// reports the part of it selected to a [ReadSelectionScope]; the scope
/// answers with a [ReadSelection]: the first block's first line, the
/// selection's start in that block's text, its end when it ends in the same
/// block, and the text selected. The characters are those of the block as
/// drawn — the text a reader sees, which a highlight of them paints back
/// (`RangeHighlight`).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:niman/src/editor/selection_buttons_menu.dart';
import 'package:niman/src/ui/pointer_density.dart';

/// Where a selection of the read view is: `line`, the first line of the
/// block it starts in; `start`, its first character in that block's text;
/// `end`, one past its last there, or null when it runs on into later
/// blocks; the `text` selected; and `anchor`, where it is on screen (in the
/// window's coordinates), for a panel that opens beside it: the selection's
/// own box when its menu knows it, else where the pointer last was, null
/// when neither is known.
typedef ReadSelection = ({
  int line,
  int start,
  int? end,
  String text,
  Rect? anchor,
});

/// An action the selection's menu offers beside Copy and Select all.
final class ReadSelectionAction {
  /// An action called [label], run on the selection when it is chosen, or
  /// when [shortcut] is pressed while a selection exists.
  const new({required this.label, required this.onPressed, this.shortcut});

  /// What the menu says.
  final String label;

  /// Runs on the selection.
  final void Function(ReadSelection selection) onPressed;

  /// The keys that run it without the menu, on a desktop; null for none.
  final SingleActivator? shortcut;
}

/// The parts of the blocks selected, as their listeners report them.
final class ReadSelectionScope {
  final Map<int, ({int start, int end})> _blocks = {};

  /// The text selected, as the selection area last said.
  String _text = '';

  /// The selection's box, as its menu last placed itself by it; dropped
  /// when the selection changes.
  Rect? _anchor;

  /// Where the pointer last was over the area, in the window's coordinates:
  /// the stand-in for the selection's box when no menu gave it.
  Offset? _pointer;

  /// The selection, or null when nothing is selected.
  ReadSelection? get selection {
    if (_blocks.isEmpty || _text.trim().isEmpty) return null;
    final lines = _blocks.keys.toList()..sort();
    final first = _blocks[lines.first]!;
    return (
      line: lines.first,
      start: first.start,
      end: lines.length == 1 ? first.end : null,
      text: _text,
      anchor: _anchor ?? _pointerBox,
    );
  }

  Rect? get _pointerBox => switch (_pointer) {
    final at? => Rect.fromCenter(center: at, width: 0, height: 20),
    null => null,
  };

  void _set(int line, int start, int end) =>
      _blocks[line] = (start: start, end: end);

  void _clear(int line) => _blocks.remove(line);
}

/// A block of the read view whose selected part is reported to [scope].
final class SelectableBlock extends StatefulWidget {
  /// Reports the selection of the block starting at [line].
  const new({
    required this.scope,
    required this.line,
    required this.child,
    super.key,
  });

  /// Where the part selected is reported.
  final ReadSelectionScope scope;

  /// The block's first line.
  final int line;

  /// The block.
  final Widget child;

  @override
  State<SelectableBlock> createState() => _SelectableBlockState();
}

final class _SelectableBlockState extends State<SelectableBlock> {
  final SelectionListenerNotifier _notifier = SelectionListenerNotifier();

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_changed);
  }

  void _changed() {
    final details = _notifier.selection;
    final range = details.range;
    if (details.status == SelectionStatus.uncollapsed && range != null) {
      widget.scope._set(
        widget.line,
        math.min(range.startOffset, range.endOffset),
        math.max(range.startOffset, range.endOffset),
      );
    } else {
      widget.scope._clear(widget.line);
    }
  }

  @override
  void didUpdateWidget(SelectableBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line != widget.line) widget.scope._clear(oldWidget.line);
  }

  @override
  void dispose() {
    widget.scope._clear(widget.line);
    _notifier
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SelectionListener(selectionNotifier: _notifier, child: widget.child);
}

/// The box the menu's [anchors] describe: from the selection's top to its
/// bottom, or one line high at the point a right click gave.
Rect _boxOf(TextSelectionToolbarAnchors anchors) {
  final box = Rect.fromPoints(
    anchors.primaryAnchor,
    anchors.secondaryAnchor ?? anchors.primaryAnchor,
  );
  return box.height >= 4
      ? box
      : Rect.fromCenter(center: box.center, width: 0, height: 20);
}

/// The read view's text, selectable: the blocks under [child] report to
/// [scope], and the selection's menu offers [actions] beside Copy and
/// Select all.
final class ReadSelectionArea extends StatelessWidget {
  /// Makes [child] selectable.
  const new({
    required this.scope,
    required this.actions,
    required this.child,
    super.key,
  });

  /// Where the blocks report their selected parts.
  final ReadSelectionScope scope;

  /// What the menu offers for the selection.
  final List<ReadSelectionAction> actions;

  /// The blocks.
  final Widget child;

  /// The keys of the actions that have some, bound to run them on the
  /// selection that exists.
  Map<ShortcutActivator, VoidCallback> get _bindings => {
    for (final action in actions)
      ?action.shortcut: () {
        if (scope.selection case final selection?) action.onPressed(selection);
      },
  };

  @override
  Widget build(BuildContext context) => _keyed(
    Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: (event) => scope._pointer = event.position,
      onPointerUp: (event) => scope._pointer = event.position,
      child: _area(),
    ),
  );

  Widget _keyed(Widget child) => _bindings.isEmpty
      ? child
      : CallbackShortcuts(bindings: _bindings, child: child);

  Widget _area() => SelectionArea(
    onSelectionChanged: (content) {
      scope
        .._text = content?.plainText ?? ''
        .._anchor = null;
    },
    // The actions are offered whatever the scope says as the menu is built:
    // the blocks report the selection after it. They read it when pressed.
    // The first comes first, where a phone's toolbar keeps it in sight; the
    // rest after Copy and Select all, which a phone may fold away.
    contextMenuBuilder: (context, region) {
      // Asked once: a right click's point is given only to the first ask.
      final anchors = region.contextMenuAnchors;
      scope._anchor = _boxOf(anchors);
      final items = [
        for (final action in actions)
          ContextMenuButtonItem(
            label: action.label,
            onPressed: () {
              final selection = scope.selection;
              region
                ..hideToolbar()
                ..clearSelection();
              if (selection != null) action.onPressed(selection);
            },
          ),
      ];
      final buttons = [
        ...items.take(1),
        ...region.contextMenuButtonItems,
        ...items.skip(1),
      ];
      // A pointer's menu is the app's compact one; Flutter's desktop
      // toolbar sets its own button size and cannot be themed.
      if (pointerDense(Theme.of(context))) {
        final overlay = Overlay.of(context).context.findRenderObject();
        final at = anchors.primaryAnchor;
        return SelectionButtonsMenu(
          anchor: overlay is RenderBox && overlay.hasSize
              ? overlay.globalToLocal(at)
              : at,
          items: buttons,
        );
      }
      return AdaptiveTextSelectionToolbar.buttonItems(
        anchors: anchors,
        buttonItems: buttons,
      );
    },
    child: child,
  );
}
