import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The pre-search hint: the empty state, the too-short state (the box
/// holds text that cannot be searched yet), or nothing while a runnable
/// query waits out the debounce.
final class SearchHint extends StatelessWidget {
  /// Creates the hint for the box holding [query].
  const new({required this.query, required this.searchable, super.key});

  /// The box's text, trimmed.
  final String query;

  /// Whether [query] is a search worth running.
  final bool searchable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String message;
    if (query.isEmpty) {
      message = AppStrings.searchEmptyHint;
    } else if (!searchable) {
      message = AppStrings.searchTooShortHint;
    } else {
      return const SizedBox.shrink();
    }
    // Padded and centered, and width-capped: a bare Text under a Center
    // still takes the full width, so the hint wrapped ragged-right against
    // both screen edges (device report, 2026-09-11). The cap keeps the two
    // lines a readable measure instead of one edge-to-edge line on a wide
    // window.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
