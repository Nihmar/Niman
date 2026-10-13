import 'package:flutter/material.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/link_preview/link_preview_body.dart';
import 'package:niman/src/ui/link_preview/link_preview_card.dart';
import 'package:niman/src/ui/strings.dart';

/// The preview a long press on a link opens on a touch screen, where no
/// pointer hovers (#846): the same note, rendered the same way, in a bottom
/// sheet that has an **Open** action.
///
/// [onOpen] follows the link as a tap would; the sheet closes first.
Future<void> showLinkPreviewSheet(
  BuildContext context, {
  required LinkPreview preview,
  required MathCache mathCache,
  required VoidCallback onOpen,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SizedBox(
      key: const Key('link-preview-sheet'),
      height: MediaQuery.sizeOf(sheet).height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinkPreviewTitle(
            preview: preview,
            trailing: FilledButton.tonal(
              key: const Key('link-preview-open'),
              onPressed: () {
                Navigator.pop(sheet);
                onOpen();
              },
              child: Text(AppStrings.linkPreviewOpen),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: LinkPreviewBody(preview: preview, mathCache: mathCache),
          ),
        ],
      ),
    ),
  );
}
