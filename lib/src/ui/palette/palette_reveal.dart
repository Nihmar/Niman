/// Keeps the row the arrows are on in view in a palette's list (#980): the
/// list is taller than its panel, and a selection that walked past the
/// last visible row picked something nobody could see.
library;

import 'package:flutter/widgets.dart';

/// Scrolls [scroll] so the row holding [row] — the key the list gives the
/// selected row alone — is in view, once the frame that selected it is
/// laid out. The lists are lazy: a wrap-around lands a whole list away, on
/// a row that is not built. So when the selection is the list's [first] or
/// [last] row, the list goes to that end, which builds the row, and the
/// row is brought in on the frame after.
void revealPaletteRow(
  ScrollController scroll,
  GlobalKey row, {
  bool first = false,
  bool last = false,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!scroll.hasClients) return;
    final position = scroll.position;
    if (first || last) {
      position.jumpTo(
        first ? position.minScrollExtent : position.maxScrollExtent,
      );
      revealPaletteRow(scroll, row);
      return;
    }
    final context = row.currentContext;
    if (context != null && context.mounted) Scrollable.ensureVisible(context);
  });
}
