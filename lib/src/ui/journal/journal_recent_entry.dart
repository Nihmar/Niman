/// One of the latest entries the journal browser lists (#7): its day, and
/// its first words.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/templates/engine.dart';

/// A recent entry's row: the weekday and the day's number, then the
/// entry's first words, or its date when it has none.
final class JournalRecentEntry extends StatelessWidget {
  /// The row of [day]'s entry, its weekday in [heading].
  ///
  /// [onOpen] opens the entry; [onMenu], when given, opens its menu at a
  /// right click's global position (#619). [dense] is the dock's row.
  const new({
    required this.day,
    required this.summary,
    required this.heading,
    required this.onOpen,
    this.dense = false,
    this.onMenu,
    super.key,
  });

  /// The entry's day.
  final DateTime day;

  /// The entry's first words; null or empty shows its date instead.
  final String? summary;

  /// The style of the weekday.
  final TextStyle? heading;

  /// Whether the row is the dock's denser one.
  final bool dense;

  /// Opens the entry.
  final VoidCallback onOpen;

  /// Opens the entry's menu at a right click's global position; null
  /// offers none.
  final void Function(Offset position)? onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onSecondaryTapUp: switch (onMenu) {
        final menu? => (details) => menu(details.globalPosition),
        null => null,
      },
      child: ListTile(
        key: Key('journal-recent-${formatDateTime(day, 'YYYY-MM-DD')}'),
        dense: dense,
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(
          width: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(formatDateTime(day, 'ddd').toUpperCase(), style: heading),
              Text(
                '${day.day}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          summary?.isNotEmpty ?? false
              ? summary!
              : formatDateTime(day, 'D MMMM YYYY'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onOpen,
      ),
    );
  }
}
