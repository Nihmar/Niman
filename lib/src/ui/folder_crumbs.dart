/// The folder grid's breadcrumb (#727): the library, the folders walked
/// through, the folder shown, and the way back up.
///
/// The first crumb reads Library and goes to the library's root; any
/// crumb goes straight to its folder, and a crumb takes a drop, which is
/// how something is moved up. A narrow pane folds the middle crumbs into
/// a "…" that opens them as a menu, so the root and the folder shown
/// never move. Up is disabled at the root, never hidden: the crumbs keep
/// their places under the pointer.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree_drag.dart';

/// One crumb: what it reads, and the folder it goes to.
final class _Crumb {
  const new(this.label, this.path);

  final String label;
  final String path;
}

/// The breadcrumb above the grid.
final class FolderCrumbs extends StatelessWidget {
  /// Creates the breadcrumb for the folder shown; '' is the root, which
  /// has no parent.
  const new({
    required this.folder,
    required this.onOpen,
    required this.onUp,
    required this.onMove,
    super.key,
  });

  /// The folder shown, library-relative.
  final String folder;

  /// Goes to the folder at the path given; the current folder is a no-op
  /// to the shell, which is already there.
  final ValueChanged<String> onOpen;

  /// Leaves for the parent folder; disabled at the root.
  final VoidCallback onUp;

  /// Moves a dragged item into a crumb's folder (#567, #727).
  final TreeMove onMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall ?? const TextStyle();
    final muted = style.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final current = style.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    );
    final segments = folder.isEmpty ? const <String>[] : folder.split('/');
    final crumbs = <_Crumb>[
      _Crumb(AppStrings.libraryCrumb, ''),
      for (var i = 0; i < segments.length; i++)
        _Crumb(segments[i], segments.take(i + 1).join('/')),
    ];
    return Container(
      key: const Key('folder-crumbs'),
      height: 32,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final direction = Directionality.of(context);
          // The Up button and the gap after it lead the row: the crumbs
          // are measured against what is left (#727).
          final shown = _visible(
            crumbs,
            constraints.maxWidth - _upWidth - _upGap,
            style,
            direction,
          );
          final folded = shown.length == crumbs.length
              ? const <_Crumb>[]
              : crumbs.sublist(1, crumbs.length - 1);
          return Row(
            children: [
              IconButton(
                key: const Key('folder-up'),
                tooltip: AppStrings.folderUpTooltip,
                onPressed: folder.isEmpty ? null : onUp,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: _upWidth,
                  height: _upWidth,
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_upward, size: 16),
              ),
              const SizedBox(width: _upGap),
              for (final (index, crumb) in shown.indexed) ...[
                if (index > 0) _separator(theme),
                if (crumb.path == _foldMarker)
                  _moreMenu(context, folded, muted)
                else
                  _growable(
                    index == shown.length - 1,
                    _crumb(
                      context,
                      crumb,
                      style: crumb.path == folder ? current : muted,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// The Up button's width, and the gap between it and the crumbs.
  static const double _upWidth = 28;
  static const double _upGap = 2;

  /// The crumbs that fit [width], the full list or the root, the fold
  /// marker and the folder shown. [width] is the room the crumbs have:
  /// the pane less the padding and the Up button's slot.
  List<_Crumb> _visible(
    List<_Crumb> crumbs,
    double width,
    TextStyle style,
    TextDirection direction,
  ) {
    if (crumbs.length <= 2) return crumbs;
    final labels = [
      for (final crumb in crumbs)
        _textWidth(crumb.label, style, direction) + 12,
    ];
    final total =
        labels.reduce((a, b) => a + b) + _separatorWidth * (crumbs.length - 1);
    if (total <= width) return crumbs;
    return [crumbs.first, const _Crumb('…', _foldMarker), crumbs.last];
  }

  /// The fold marker's path: no folder, only the "…" the crumbs fold into.
  static const String _foldMarker = '\u0000';

  static const double _separatorWidth = 16;

  Widget _separator(ThemeData theme) => SizedBox(
    width: _separatorWidth,
    child: Icon(
      Icons.chevron_right,
      size: 14,
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );

  /// The last crumb may shrink — the current folder's name is the one that
  /// ellipsizes when the pane runs out — and a [Flexible] has to be the
  /// [Row]'s own child, not the [DragTarget]'s.
  Widget _growable(bool grows, Widget child) =>
      grows ? Flexible(child: child) : child;

  /// One crumb: a tap goes there, a drop moves into it.
  Widget _crumb(
    BuildContext context,
    _Crumb crumb, {
    required TextStyle style,
  }) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          treeDropMoves(details.data, crumb.path),
      onAcceptWithDetails: (details) => onMove(details.data, crumb.path),
      builder: (context, candidates, _) {
        final lit = candidates.any(
          (path) => path != null && treeDropMoves(path, crumb.path),
        );
        // A drop on a crumb lights it as a folder row lights up; the room
        // is reserved either way, so the crumbs do not move under the
        // pointer.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: lit
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.16)
                : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: InkWell(
            onTap: () => onOpen(crumb.path),
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                crumb.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        );
      },
    );
  }

  /// The "…" the middle crumbs fold into: its menu opens them.
  Widget _moreMenu(BuildContext context, List<_Crumb> folded, TextStyle style) {
    return PopupMenuButton<String>(
      key: const Key('crumbs-more'),
      tooltip: AppStrings.breadcrumbMoreTooltip,
      padding: EdgeInsets.zero,
      onSelected: onOpen,
      itemBuilder: (context) => [
        for (final crumb in folded)
          PopupMenuItem(
            key: Key('crumb-${crumb.path}'),
            value: crumb.path,
            child: Text(crumb.label),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text('…', style: style),
      ),
    );
  }
}

/// The width [text] takes on one line in [style].
double _textWidth(String text, TextStyle style, TextDirection direction) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: direction,
  )..layout();
  return painter.width;
}
