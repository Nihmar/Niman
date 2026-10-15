import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/deck_catalog_controller.dart';
import 'package:niman/src/flashcards/deck_tree.dart';
import 'package:niman/src/ui/strings.dart';

/// The decks to study (#533, mockups D1 and P1): the tags as chips that
/// filter, and the Study tree — categories from `deck:`, decks as leaves,
/// each row with its **due** and **new** counts, summed up the categories,
/// and its own **Study**.
///
/// The same view in the wide window's left island and on a phone's Study
/// destination; [controller] keeps the counts, the view only draws them.
final class StudyView extends StatefulWidget {
  /// The tree of [controller]'s decks.
  const new({
    required this.controller,
    required this.onOpenDeck,
    required this.onStudy,
    required this.onNewDeck,
    super.key,
  });

  /// The decks, counted.
  final DeckCatalogController controller;

  /// Opens the deck note at its library-relative path.
  final ValueChanged<String> onOpenDeck;

  /// Studies the decks at their library-relative paths together, under
  /// the row's name.
  final void Function(List<String> paths, String title) onStudy;

  /// **New flashcards**, offered while there is no deck.
  final VoidCallback onNewDeck;

  @override
  State<StudyView> createState() => _StudyViewState();
}

final class _StudyViewState extends State<StudyView> {
  /// The categories folded, by [_id].
  final Set<String> _folded = {};

  static String _id(DeckCategory category) =>
      category.uncategorized ? '\u0000' : category.path.join('/');

  static String _name(DeckTreeNode node) =>
      node is DeckCategory && node.uncategorized
      ? AppStrings.flashcardsNoCategory
      : node.name;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      if (!controller.loaded) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.summaries.isEmpty) return _empty(context);
      final rows = <Widget>[];
      for (final node in controller.tree.roots) {
        _addRows(context, rows, node, 0);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in controller.tags)
                    FilterChip(
                      key: Key('study-tag-$tag'),
                      label: Text('#$tag'),
                      visualDensity: VisualDensity.compact,
                      selected: controller.selectedTags.contains(tag),
                      onSelected: (_) => controller.toggleTag(tag),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              key: const Key('study-tree'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: rows,
            ),
          ),
        ],
      );
    },
  );

  void _addRows(
    BuildContext context,
    List<Widget> rows,
    DeckTreeNode node,
    int depth,
  ) {
    switch (node) {
      case DeckLeaf(:final summary):
        rows.add(
          _StudyRow(
            key: Key('study-deck-${summary.path}'),
            depth: depth,
            leading: const Icon(Icons.style_outlined, size: 18),
            name: summary.name,
            counts: node.counts,
            onTap: () => widget.onOpenDeck(summary.path),
            onStudy: () => widget.onStudy([summary.path], summary.name),
          ),
        );
      case DeckCategory():
        final folded = _folded.contains(_id(node));
        final name = _name(node);
        rows.add(
          _StudyRow(
            key: Key('study-category-${_id(node)}'),
            depth: depth,
            leading: Icon(
              folded ? Icons.chevron_right : Icons.expand_more,
              size: 18,
            ),
            name: name,
            counts: node.counts,
            onTap: () => setState(
              () => folded ? _folded.remove(_id(node)) : _folded.add(_id(node)),
            ),
            onStudy: () => widget.onStudy([
              for (final deck in node.decks) deck.path,
            ], name),
          ),
        );
        if (!folded) {
          for (final child in node.children) {
            _addRows(context, rows, child, depth + 1);
          }
        }
    }
  }

  Widget _empty(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.style_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(AppStrings.studyEmpty, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              AppStrings.studyEmptyHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              key: const Key('study-new-deck'),
              onPressed: widget.onNewDeck,
              icon: const Icon(Icons.add),
              label: Text(AppStrings.newFlashcardsTitle),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the tree: a category or a deck, its counts, its **Study**.
final class _StudyRow extends StatelessWidget {
  const new({
    required this.depth,
    required this.leading,
    required this.name,
    required this.counts,
    required this.onTap,
    required this.onStudy,
    super.key,
  });

  final int depth;
  final Widget leading;
  final String name;
  final DeckCounts counts;
  final VoidCallback onTap;
  final VoidCallback onStudy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: 8.0 + depth * 16, end: 4),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
            _Pill(
              count: counts.due,
              colour: scheme.primary,
              tooltip: AppStrings.flashcardsDueCount(counts.due),
            ),
            const SizedBox(width: 4),
            _Pill(
              count: counts.newAvailable,
              colour: scheme.tertiary,
              tooltip: AppStrings.flashcardsNewCount(counts.newAvailable),
            ),
            // Kept in place with nothing to study: disabled, not gone.
            IconButton(
              key: const Key('study-row-study'),
              tooltip: AppStrings.flashcardsStudyCards(counts.toStudy),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.play_arrow_outlined),
              onPressed: counts.toStudy > 0 ? onStudy : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// A count, coloured while it is not zero.
final class _Pill extends StatelessWidget {
  const new({required this.count, required this.colour, required this.tooltip});

  final int count;
  final Color colour;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    return Tooltip(
      message: tooltip,
      child: Container(
        constraints: const BoxConstraints(minWidth: 28),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: count > 0 ? colour.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: count > 0 ? colour : muted,
          ),
        ),
      ),
    );
  }
}
