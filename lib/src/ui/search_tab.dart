import 'package:flutter/material.dart';

/// The Search tab: reserved per the mockup; the body stays disabled until
/// the M3 SearchScreen lands (T-UI-02 R3).
final class SearchTab extends StatelessWidget {
  /// Creates the search tab.
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 56),
          SizedBox(height: 8),
          Text('Search'),
          SizedBox(height: 4),
          Text('Search lands in M3'),
        ],
      ),
    );
  }
}
