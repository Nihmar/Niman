// The marks the read view paints beside a list item (`item_marks.dart`):
// a bullet and a checkbox are drawn, not written, so a test finds them by
// their painter rather than by a glyph or an icon.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/item_marks.dart';

/// The painter of [widget], when it paints an item's mark.
ItemMarkPainter? itemMarkOf(Widget widget) => switch (widget) {
  CustomPaint(:final ItemMarkPainter painter) => painter,
  _ => null,
};

/// The bullets the read view paints.
Finder findBullet() => find.byWidgetPredicate((widget) {
  final mark = itemMarkOf(widget);
  return mark != null && mark.task == null;
}, description: 'a painted bullet');

/// The checkboxes the read view paints, [ticked] or not.
Finder findCheckbox({required bool ticked}) => find.byWidgetPredicate(
  (widget) => itemMarkOf(widget)?.task == ticked,
  description: ticked ? 'a ticked checkbox' : 'an empty checkbox',
);
