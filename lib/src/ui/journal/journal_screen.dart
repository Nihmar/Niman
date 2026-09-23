/// The phone's Journal screen (#7, mockup 5): the month, the day picked
/// in a card that opens its entry or makes one, and the latest entries.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';
import 'package:niman/src/ui/strings.dart';

/// The screen, pushed over the shell.
final class JournalScreen extends StatelessWidget {
  /// The screen over the journal; its fields are [JournalBrowser]'s.
  const new({
    required this.today,
    required this.entryDays,
    required this.readEntry,
    required this.onOpenDay,
    this.revision = 0,
    this.dueOn,
    this.tasksChanged,
    this.onOpenTasks,
    super.key,
  });

  /// See [JournalBrowser.dueOn].
  final List<String> Function(DateTime day)? dueOn;

  /// See [JournalBrowser.tasksChanged].
  final Listenable? tasksChanged;

  /// See [JournalBrowser.onOpenTasks].
  final VoidCallback? onOpenTasks;

  /// See [JournalBrowser.today].
  final DateTime today;

  /// See [JournalBrowser.entryDays].
  final Future<List<DateTime>?> Function() entryDays;

  /// See [JournalBrowser.readEntry].
  final Future<String> Function(DateTime day) readEntry;

  /// See [JournalBrowser.onOpenDay].
  final void Function(DateTime day, {bool confirmed}) onOpenDay;

  /// See [JournalBrowser.revision].
  final int revision;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('journal-screen'),
      appBar: AppBar(title: Text(AppStrings.paletteGroupJournal)),
      body: JournalBrowser(
        today: today,
        entryDays: entryDays,
        readEntry: readEntry,
        onOpenDay: onOpenDay,
        revision: revision,
        large: true,
        dueOn: dueOn,
        tasksChanged: tasksChanged,
        onOpenTasks: onOpenTasks,
      ),
    );
  }
}
