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

/// Where a selection of the read view is: `line`, the first line of the
/// block it starts in; `start`, its first character in that block's text;
/// `end`, one past its last there, or null when it runs on into later
/// blocks; and the `text` selected.
typedef ReadSelection = ({int line, int start, int? end, String text});

/// An action the selection's menu offers beside Copy and Select all.
typedef ReadSelectionAction = ({
  String label,
  void Function(ReadSelection selection) onPressed,
});

/// The parts of the blocks selected, as their listeners report them.
final class ReadSelectionScope {
  final Map<int, ({int start, int end})> _blocks = {};

  /// The text selected, as the selection area last said.
  String _text = '';

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
    );
  }

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

  @override
  Widget build(BuildContext context) => SelectionArea(
    onSelectionChanged: (content) => scope._text = content?.plainText ?? '',
    // The actions are offered whatever the scope says as the menu is built:
    // the blocks report the selection after it. They read it when pressed.
    // The first comes first, where a phone's toolbar keeps it in sight; the
    // rest after Copy and Select all, which a phone may fold away.
    contextMenuBuilder: (context, region) {
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
      return AdaptiveTextSelectionToolbar.buttonItems(
        anchors: region.contextMenuAnchors,
        buttonItems: [
          ...items.take(1),
          ...region.contextMenuButtonItems,
          ...items.skip(1),
        ],
      );
    },
    child: child,
  );
}
