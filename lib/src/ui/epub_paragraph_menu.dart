/// What a paragraph of a book offers when it is long-pressed, or clicked
/// with the secondary button (#284): to annotate it, and to copy a link to
/// it (#282).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// What was picked in a paragraph's menu.
enum EpubParagraphAction {
  /// Annotate the paragraph in the book's companion note.
  annotate,

  /// Copy a link to the paragraph.
  copyLink,
}

/// Shows a paragraph's menu at [position], a global offset; [annotate]
/// false leaves its annotation out (a book with nowhere to write one).
Future<EpubParagraphAction?> showEpubParagraphMenu(
  BuildContext context,
  Offset position, {
  required bool annotate,
}) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final at = overlay.globalToLocal(position);
  return showMenu<EpubParagraphAction>(
    context: context,
    position: RelativeRect.fromRect(
      at & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: [
      if (annotate)
        PopupMenuItem(
          key: const Key('epub-paragraph-annotate'),
          value: EpubParagraphAction.annotate,
          child: ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text(AppStrings.annotateAction),
          ),
        ),
      PopupMenuItem(
        key: const Key('epub-paragraph-link'),
        value: EpubParagraphAction.copyLink,
        child: ListTile(
          leading: const Icon(Icons.link),
          title: Text(AppStrings.copyPlaceLink),
        ),
      ),
    ],
  );
}
