/// The Home's journal calendar tile (#535): the journal's month, the days
/// with an entry marked, a tap opening a day.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_loader.dart';
import 'package:niman/src/ui/journal/journal_calendar.dart';

/// The days of the journal that have an entry, and the journal's today.
typedef _Days = ({Set<DateTime> entries, DateTime today});

/// A month of the journal.
final class JournalCalendarTile extends StatefulWidget {
  /// The tile over [host]'s journal, reloaded on [revision].
  const new({required this.host, required this.revision, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// The Home's revision.
  final int revision;

  @override
  State<JournalCalendarTile> createState() => _JournalCalendarTileState();
}

final class _JournalCalendarTileState extends State<JournalCalendarTile> {
  /// The month shown, once the user moved off today's.
  DateTime? _month;

  Future<_Days?> _load() async {
    final today = await widget.host.journal.today();
    final days = await widget.host.journal.entryDays();
    if (today == null || days == null) return null;
    return (entries: days.toSet(), today: today);
  }

  @override
  Widget build(BuildContext context) {
    return HomeTileLoader<_Days?>(
      revision: widget.revision,
      load: _load,
      builder: (context, days) {
        if (days == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, box) {
            // Seven columns, and up to eight rows with the month's name
            // and the weekdays: the cell the tile's room allows.
            final cell = min(box.maxWidth / 7, box.maxHeight / 8.5);
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: JournalCalendar(
                month: _month ?? days.today,
                entries: days.entries,
                today: days.today,
                cell: max(cell, 16),
                onMonth: (month) => setState(() => _month = month),
                onDay: (day) =>
                    unawaited(widget.host.journal.openDay(context, day)),
              ),
            );
          },
        );
      },
    );
  }
}
