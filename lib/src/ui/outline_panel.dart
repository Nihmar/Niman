import 'package:copist/src/editor/outline.dart';
import 'package:flutter/material.dart';

/// The heading outline panel (T-M2-07): a compact column listing the
/// document's headings, indented by level; tapping an entry jumps the editor
/// to that heading line. A folded heading is shown with a filled chevron.
final class OutlinePanel extends StatelessWidget {
  /// Creates the panel.
  const OutlinePanel({
    required this.entries,
    required this.onJump,
    this.foldedLines = const <int>{},
    this.maxHeight = 240,
    super.key,
  });

  /// The document's headings (line order).
  final List<OutlineEntry> entries;

  /// Called with the heading's line when an entry is tapped.
  final ValueChanged<int> onJump;

  /// The heading lines currently folded (marker state).
  final Set<int> foldedLines;

  /// The panel's vertical bound.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Text('No headings'),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final folded = foldedLines.contains(entry.line);
                return InkWell(
                  onTap: () => onJump(entry.line),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 8 + (entry.level - 1) * 12.0,
                        ),
                        Icon(
                          folded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.text.isEmpty
                                ? '(no title)'
                                : entry.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: entry.level == 1
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
