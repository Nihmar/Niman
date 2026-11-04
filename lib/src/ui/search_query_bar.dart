import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The top of the Search screen: the query box with its Clear and, where
/// a pointer aims, its Words/Contains toggle (#712), the row under it
/// with the segmented mode, Replace and Tags, and the replace panel when
/// replace mode is on.
final class SearchQueryBar extends StatelessWidget {
  /// Creates the bar over [query].
  const new({
    required this.query,
    required this.focusNode,
    required this.dense,
    required this.contains,
    required this.fieldMode,
    required this.canReplace,
    required this.onSubmitted,
    required this.onClear,
    required this.onContainsChanged,
    required this.onReplace,
    required this.onOpenTags,
    required this.panel,
    super.key,
  });

  /// The query box's text.
  final TextEditingController query;

  /// The query box's focus, whose keys step through the hits.
  final FocusNode focusNode;

  /// Whether the mode is a toggle in the field rather than a segmented
  /// row: where the platform is a pointer, and where the pane is narrow.
  final bool dense;

  /// Whether the search is a contains scan rather than whole words.
  final bool contains;

  /// Whether the box holds a `key = value` filter.
  final bool fieldMode;

  /// Whether the Replace button shows.
  final bool canReplace;

  /// The search action of a touch keyboard.
  final VoidCallback onSubmitted;

  /// Empties the box.
  final VoidCallback onClear;

  /// Switches between whole words (false) and contains (true).
  final ValueChanged<bool> onContainsChanged;

  /// Enters replace mode across every matching note.
  final VoidCallback onReplace;

  /// Opens the Tags screen; the tags button shows only when set.
  final VoidCallback? onOpenTags;

  /// The replace panel under the row, or null outside replace mode.
  final Widget? panel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          TextField(
            key: const Key('search-query'),
            controller: query,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            // The search action of a touch keyboard (a hardware
            // Enter is the focus node's).
            onSubmitted: (_) => onSubmitted(),
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              // The icon says which of the two the box is doing, so a
              // filter that matched is visible before the results are.
              prefixIcon: Icon(
                fieldMode ? Icons.filter_alt_outlined : Icons.search,
              ),
              suffixIcon: dense || query.text.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      // The row is anchored at the field's end and
                      // grows leftwards: Clear, which comes and
                      // goes, sits on that side, so the toggle at
                      // the end never moves under a pointer on it
                      // (#782). Beside the toggle it is as compact
                      // as the toggle, or the field would grow
                      // taller and shift the toggle down.
                      children: [
                        if (query.text.isNotEmpty)
                          IconButton(
                            key: const Key('search-clear'),
                            icon: const Icon(Icons.close),
                            visualDensity: dense ? VisualDensity.compact : null,
                            onPressed: onClear,
                          ),
                        if (dense) _modeToggle(),
                      ],
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              // Words or contains is a toggle inside the field where a
              // pointer aims (#712); a phone keeps the segmented row.
              if (!dense)
                SegmentedButton<bool>(
                  key: const Key('search-mode'),
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(AppStrings.searchModeWords),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(AppStrings.searchModeContains),
                    ),
                  ],
                  selected: {contains},
                  onSelectionChanged: (selection) =>
                      onContainsChanged(selection.single),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              const Spacer(),
              // Compact so the row stays inside a phone's width with
              // the replace button showing: at standard density it
              // overflows by a few pixels at 390 px.
              if (canReplace)
                IconButton(
                  key: const Key('search-replace'),
                  tooltip: AppStrings.replaceTooltip,
                  icon: const Icon(Icons.find_replace),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onReplace,
                ),
              if (onOpenTags != null)
                IconButton(
                  key: const Key('open-tags'),
                  tooltip: AppStrings.openTagsTooltip,
                  icon: const Icon(Icons.sell_outlined),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onOpenTags,
                ),
            ],
          ),
          ?panel,
        ],
      ),
    );
  }

  /// Words/contains as a toggle in the query field, where a pointer aims
  /// (#712): selected means contains, unselected means whole words.
  Widget _modeToggle() => IconButton(
    key: const Key('search-mode-toggle'),
    tooltip: contains
        ? AppStrings.searchModeContains
        : AppStrings.searchModeWords,
    isSelected: contains,
    visualDensity: VisualDensity.compact,
    icon: const Icon(Icons.abc),
    onPressed: () => onContainsChanged(!contains),
  );
}
