import 'package:niman/src/ui/settings_search_entry.dart';

/// Matches [entries] against [query]: every word lands in the title or
/// the area, case-insensitively.
List<SettingsSearchEntry> matchSettingsEntries(
  List<SettingsSearchEntry> entries,
  String query,
) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return const [];
  return [
    for (final entry in entries)
      if (words.every(
        (word) =>
            entry.title.toLowerCase().contains(word) ||
            entry.area.toLowerCase().contains(word),
      ))
        entry,
  ];
}
