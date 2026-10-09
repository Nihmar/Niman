/// A saved search tile's settings (#535): its name and its query.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// Asks for a search tile's [title] and [query]; null when cancelled.
Future<({String title, String query})?> showSearchTileDialog(
  BuildContext context, {
  required String title,
  required String query,
}) => showDialog<({String title, String query})>(
  context: context,
  builder: (context) => _SearchTileDialog(title: title, query: query),
);

final class _SearchTileDialog extends StatefulWidget {
  const new({required this.title, required this.query});

  final String title;
  final String query;

  @override
  State<_SearchTileDialog> createState() => _SearchTileDialogState();
}

final class _SearchTileDialogState extends State<_SearchTileDialog> {
  late final TextEditingController _title = TextEditingController(
    text: widget.title,
  );
  late final TextEditingController _query = TextEditingController(
    text: widget.query,
  );

  @override
  void dispose() {
    _title.dispose();
    _query.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, (
    title: _title.text.trim(),
    query: _query.text.trim(),
  ));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.homeTileSearch),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('home-search-title'),
            controller: _title,
            decoration: InputDecoration(labelText: AppStrings.homeSearchName),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('home-search-query'),
            controller: _query,
            autofocus: true,
            decoration: InputDecoration(
              labelText: AppStrings.homeSearchQuery,
              hintText: AppStrings.homeSearchQueryHint,
            ),
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('home-search-save'),
          onPressed: _save,
          child: Text(AppStrings.actionSave),
        ),
      ],
    );
  }
}
