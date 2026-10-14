/// The PDF viewer's selection menu on a pointer.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/selection_buttons_menu.dart';
import 'package:pdfrx/pdfrx.dart';

/// The menu for a selection in the PDF viewer, as the app's compact one.
///
/// pdfrx builds its own from `AdaptiveTextSelectionToolbar`, whose desktop
/// buttons set their own size; this is its default list — Copy, Select
/// all — handed to [customize] (the app's Highlight and Annotate) and drawn
/// as a [SelectionButtonsMenu] at the selection's anchor. Null when there
/// is nothing to offer.
Widget? pdfSelectionMenu(
  BuildContext context,
  PdfViewerContextMenuBuilderParams params, {
  required PdfViewerContextMenuUpdateMenuItemsFunction customize,
}) {
  final selection = params.textSelectionDelegate;
  final items = <ContextMenuButtonItem>[
    if (params.isTextSelectionEnabled &&
        selection.isCopyAllowed &&
        selection.hasSelectedText)
      ContextMenuButtonItem(
        onPressed: selection.copyTextSelection,
        type: ContextMenuButtonType.copy,
      ),
    if (params.isTextSelectionEnabled && !selection.isSelectingAllText)
      ContextMenuButtonItem(
        onPressed: selection.selectAllText,
        type: ContextMenuButtonType.selectAll,
      ),
  ];
  customize(params, items);
  if (items.isEmpty) return null;
  return SelectionButtonsMenu(anchor: params.anchorA, items: items);
}
