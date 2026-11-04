import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/settings_areas.dart';

/// One searchable settings row (issue #104): its title, where it lives,
/// its current value, and how to open it.
final class SettingsSearchEntry {
  /// Describes the row titled [title] in [area].
  const new({
    required this.title,
    required this.area,
    required this.rowKey,
    required this.value,
    required this.open,
    this.areaId,
    this.onHome = false,
  });

  /// The row's title.
  final String title;

  /// Where the row lives ("Library X › Trash and history"), so nothing
  /// is changed by accident in the wrong place.
  final String area;

  /// The row's key: the highlight target on its screen.
  final Key rowKey;

  /// The row's current value for the result line; null shows none.
  final Future<String?> Function() value;

  /// Opens the row's screen with the row highlighted.
  final VoidCallback open;

  /// Which area the row lives in, for a caller that opens settings
  /// itself — the command palette (#229). Null for the rows that sit on
  /// the settings home.
  final SettingsAreaId? areaId;

  /// True for the maintenance actions: they sit on the home itself, so
  /// opening them means clearing the search and flashing in place.
  final bool onHome;
}
