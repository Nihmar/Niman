import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/note_top_bar.dart';

/// The side panel's buttons that are on screen, one in the row above each
/// note, so that the overlay can start under that row and leave the
/// button where it is: a button the panel covers is a button that cannot
/// close it.
final class DockToggles {
  final Set<BuildContext> _on = {};

  /// Called by a button as it appears.
  void add(BuildContext context) => _on.add(context);

  /// Called by a button as it goes.
  void remove(BuildContext context) => _on.remove(context);

  /// The bottom edge of the lowest note row holding a button, in the
  /// coordinates of [within], or 0 when no note shows one.
  ///
  /// The lowest, so that with the panes split one above the other the
  /// overlay clears every button; side by side, both rows are the same.
  /// It reads the last layout: the overlay opens from a button that has
  /// been on screen for a frame at least.
  double rowBottom({required RenderObject? within}) {
    var bottom = 0.0;
    for (final context in _on) {
      if (!context.mounted) continue;
      RenderObject? row;
      context.visitAncestorElements((element) {
        if (element.widget is! NoteTopBar) return true;
        row = element.renderObject;
        return false;
      });
      final box = row;
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      bottom = math.max(
        bottom,
        box.localToGlobal(Offset(0, box.size.height), ancestor: within).dy,
      );
    }
    return bottom;
  }
}
