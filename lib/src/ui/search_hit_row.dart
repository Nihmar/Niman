import 'package:flutter/material.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/search_snippet.dart';

/// One note row of the search results: the hit's title, its path, and its
/// snippet — or, for a word hit that carries none, the excerpt read from
/// the note as the row is built.
final class SearchHitRow extends StatelessWidget {
  /// Creates the row for [hit].
  const new({
    required this.hit,
    required this.current,
    required this.excerpt,
    required this.onTap,
    required this.onLongPress,
    required this.onMenu,
    required this.onNewTab,
    super.key,
  });

  /// The note the row lists.
  final SearchHit hit;

  /// Whether the row is the hit last opened or stepped to (#712).
  final bool current;

  /// The excerpt being read for a hit without a snippet, or null when
  /// there is none to read.
  final Future<String>? excerpt;

  /// Opens the hit.
  final VoidCallback onTap;

  /// Opens the hit's menu, as a long press does on a phone.
  final VoidCallback onLongPress;

  /// Opens the hit's menu at the pointer, on a right click.
  final ValueChanged<Rect> onMenu;

  /// Opens the hit in a new tab, on a middle click.
  final VoidCallback onNewTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = this.excerpt;
    // A hit's pointer ways in (#712): a right click opens its menu at the
    // pointer, a middle click opens it in a new tab.
    return GestureDetector(
      onSecondaryTapUp: (details) =>
          onMenu(menuAnchorAt(details.globalPosition)),
      onTertiaryTapUp: (_) => onNewTab(),
      child: ListTile(
        key: Key('search-hit-${hit.path}'),
        selected: current,
        selectedTileColor: theme.colorScheme.secondaryContainer,
        title: Text(hit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hit.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (hit.snippet.isNotEmpty)
              SearchSnippet(hit.snippet)
            else if (excerpt != null)
              FutureBuilder<String>(
                future: excerpt,
                builder: (context, excerpt) => _excerptSlot(
                  theme,
                  excerpt.data ?? '',
                  loading: excerpt.connectionState != ConnectionState.done,
                ),
              ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  /// The room for a word hit's excerpt, two lines whether it has arrived
  /// or not (#1044): the row is its final height from the first frame, so
  /// nothing slides under the pointer while the excerpts load. While it is
  /// on its way a faint bar holds the line.
  Widget _excerptSlot(
    ThemeData theme,
    String excerpt, {
    required bool loading,
  }) => Stack(
    children: [
      // Two lines of the snippet's own style, drawn as nothing.
      const Opacity(opacity: 0, child: Text('\n', maxLines: 2)),
      if (excerpt.isNotEmpty)
        SearchSnippet(excerpt)
      else if (loading)
        Positioned(
          left: 0,
          top: 5,
          width: 140,
          height: 8,
          child: DecoratedBox(
            key: const Key('search-excerpt-skeleton'),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
    ],
  );
}
