import 'package:flutter/material.dart';
import 'package:niman/src/workspace/workspace.dart';

/// Two panes of the window, side by side or one over the other (#23),
/// with a divider that drags.
///
/// The first pane takes [fraction] of the space the divider leaves; the
/// drag reports the new fraction live, and the workspace keeps it.
final class PaneSplit extends StatelessWidget {
  /// Splits [axis] between [first] and [second].
  const new({
    required this.axis,
    required this.fraction,
    required this.onFraction,
    required this.first,
    required this.second,
    super.key,
  });

  /// Which way the panes sit.
  final SplitAxis axis;

  /// The first pane's share.
  final double fraction;

  /// Receives the share as the divider is dragged.
  final ValueChanged<double> onFraction;

  /// The first (left or top) pane.
  final Widget first;

  /// The second (right or bottom) pane.
  final Widget second;

  /// The divider's grab width; it draws 1 px in the middle.
  static const double dividerWidth = 9;

  @override
  Widget build(BuildContext context) {
    final horizontal = axis == SplitAxis.right;
    return LayoutBuilder(
      builder: (context, constraints) {
        final total =
            (horizontal ? constraints.maxWidth : constraints.maxHeight) -
            dividerWidth;
        final lead = (total * fraction).clamp(0.0, total);
        final divider = MouseRegion(
          cursor: horizontal
              ? SystemMouseCursors.resizeColumn
              : SystemMouseCursors.resizeRow,
          child: GestureDetector(
            key: const Key('pane-divider'),
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: horizontal
                ? (d) => onFraction((lead + d.delta.dx) / total)
                : null,
            onVerticalDragUpdate: horizontal
                ? null
                : (d) => onFraction((lead + d.delta.dy) / total),
            child: SizedBox(
              width: horizontal ? dividerWidth : double.infinity,
              height: horizontal ? double.infinity : dividerWidth,
              child: Center(
                child: horizontal
                    ? const VerticalDivider(width: 1)
                    : const Divider(height: 1),
              ),
            ),
          ),
        );
        final children = [
          SizedBox(
            width: horizontal ? lead : null,
            height: horizontal ? null : lead,
            child: first,
          ),
          divider,
          Expanded(child: second),
        ];
        return horizontal
            ? Row(children: children)
            : Column(children: children);
      },
    );
  }
}
