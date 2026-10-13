import 'package:flutter/material.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/link_preview/link_preview_body.dart';

/// The card a hovered link opens (#846): the note it points at, rendered, in
/// a box of a fixed size that scrolls.
final class LinkPreviewCard extends StatelessWidget {
  /// The card of [preview].
  const new({
    required this.preview,
    required this.mathCache,
    this.onEnter,
    this.onExit,
    super.key,
  });

  /// What the card shows.
  final LinkPreview preview;

  /// The math render cache the note's formulas are typeset through.
  final MathCache mathCache;

  /// The pointer came onto the card, which then stays up.
  final VoidCallback? onEnter;

  /// The pointer left the card.
  final VoidCallback? onExit;

  /// The card's size: a screenful of a note, whatever its length.
  static const Size size = Size(420, 300);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MouseRegion(
      onEnter: (_) => onEnter?.call(),
      onExit: (_) => onExit?.call(),
      child: Material(
        key: const Key('link-preview-card'),
        elevation: 8,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinkPreviewTitle(preview: preview),
            const Divider(height: 1),
            Expanded(
              child: LinkPreviewBody(preview: preview, mathCache: mathCache),
            ),
          ],
        ),
      ),
    );
  }
}

/// The title row of a preview: the note's name, and the place in it the link
/// names.
final class LinkPreviewTitle extends StatelessWidget {
  /// The title of [preview]; [trailing] stands at the end of the row.
  const new({required this.preview, this.trailing, super.key});

  /// The note previewed.
  final LinkPreview preview;

  /// What ends the row: the sheet's Open button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anchor = preview.anchor;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, trailing == null ? 8 : 4, 8, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              preview.title,
              key: const Key('link-preview-title'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (anchor != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '#$anchor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}
