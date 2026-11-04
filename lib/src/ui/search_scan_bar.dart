import 'package:flutter/material.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/strings.dart';

/// The progress of a contains scan and the way to end it (#1038).
final class SearchScanBar extends StatelessWidget {
  /// Creates the bar for [scan].
  const new({required this.scan, required this.onStop, super.key});

  /// How far the scan has got.
  final ContainsProgress scan;

  /// Ends the scan with the hits it has found so far.
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('search-scan'),
      children: [
        LinearProgressIndicator(
          value: scan.total > 0 ? scan.scanned / scan.total : null,
          minHeight: 2,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.searchScanning(scan.scanned, scan.total),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                key: const Key('search-stop'),
                onPressed: onStop,
                child: Text(AppStrings.searchStop),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
