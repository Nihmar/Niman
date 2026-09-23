/// Opening the journal (#7): a day's entry, made from the journal's
/// template the first time that day is opened.
///
/// Today's entry is made at once: asking would only slow down the thing
/// people do every day. A past or future day asks first, so leafing
/// through the calendar never leaves empty notes behind.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/journal/journal_days.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/templates/counters.dart';
import 'package:niman/src/templates/directives.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/templates/includes.dart';
import 'package:niman/src/templates/prompts.dart';
import 'package:niman/src/ui/shell_template_flow.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/template_form.dart';

/// The template an entry is made from when the journal names none: a
/// heading with the day's date, and the caret under it.
const String builtInJournalTemplate =
    '# {{date:dddd D MMMM YYYY}}\n\n{{cursor}}';

/// How a day reads in the journal's questions and strip:
/// `Wednesday 23 September 2026`.
String journalDayLabel(DateTime day) => formatDateTime(day, 'dddd D MMMM YYYY');

/// Opens and makes journal entries.
final class JournalFlow {
  /// A flow over [controller]'s library; [templates] lends it the way
  /// template includes are found, [guard] reports failures, [onOpen]
  /// opens an entry that exists and [onCreated] one just made (with the
  /// template's caret). [clock] is the device's time (tests fix it).
  new({
    required this.controller,
    required this.templates,
    required this.guard,
    required this.onOpen,
    required this.onCreated,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The open library.
  final LibrarySession controller;

  /// The template flow, for resolving `{{include:…}}`.
  final ShellTemplateFlow templates;

  /// Serializes mutating flows, reporting errors.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Opens the entry at a library-relative path.
  final void Function(String path) onOpen;

  /// Opens an entry just made, with the caret where the template put it.
  final void Function(String path, int? caret) onCreated;

  final DateTime Function() _clock;

  static const _log = AppLogger(name: 'journal');

  /// The journal's day now, by its settings.
  Future<DateTime?> today() async {
    final ops = controller.ops;
    if (ops == null) return null;
    return (await ops.journal).today(_clock());
  }

  /// Opens today's entry, making it first when there is none.
  Future<void> openToday(BuildContext context) async {
    final day = await today();
    if (day == null || !context.mounted) return;
    await openDay(context, day);
  }

  /// Opens [day]'s entry. One that does not exist is made — after
  /// asking, unless [day] is today.
  Future<void> openDay(BuildContext context, DateTime day) async {
    final ops = controller.ops;
    if (ops == null) return;
    final settings = await ops.journal;
    final path = settings.entryPath(day);
    if (await ops.find(path) != null) {
      _log.info('journal: open ${journalDayLabel(day)} ($path)');
      onOpen(path);
      return;
    }
    if (day != settings.today(_clock())) {
      if (!context.mounted) return;
      final create = await _askToCreate(context, day);
      if (create != true) return;
    }
    if (!context.mounted) return;
    await _create(context, settings, day, path);
  }

  /// Opens the entry before [day]'s, skipping the days without one; the
  /// day before, to be made, when there is none earlier.
  Future<void> openPrevious(BuildContext context, DateTime day) async {
    final days = await _days();
    if (days == null || !context.mounted) return;
    final before =
        journalDayBefore(days, day) ??
        DateTime(day.year, day.month, day.day - 1);
    await openDay(context, before);
  }

  /// Opens the entry after [day]'s, skipping the days without one; the
  /// day after, to be made, when there is none later and it is not past
  /// today. Null, doing nothing, when [day] is today or later.
  Future<void> openNext(BuildContext context, DateTime day) async {
    final days = await _days();
    final today = await this.today();
    if (days == null || today == null || !context.mounted) return;
    final after = journalDayAfter(days, day);
    if (after != null) {
      await openDay(context, after);
      return;
    }
    if (!day.isBefore(today)) return;
    await openDay(context, DateTime(day.year, day.month, day.day + 1));
  }

  /// The days with an entry, oldest first.
  Future<List<DateTime>?> _days() async {
    final ops = controller.ops;
    if (ops == null) return null;
    final settings = await ops.journal;
    return journalDays(settings, await ops.notePathsUnder(settings.folder));
  }

  Future<bool?> _askToCreate(BuildContext context, DateTime day) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('journal-create-dialog'),
          title: Text(AppStrings.paletteGroupJournal),
          content: Text(AppStrings.journalCreateAsk(journalDayLabel(day))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.actionCancel),
            ),
            FilledButton(
              key: const Key('journal-create-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.actionCreate),
            ),
          ],
        ),
      );

  /// Makes [day]'s entry at [path] from the journal's template and opens
  /// it. The template's questions are asked like any template's; its
  /// `niman:` directives are not followed, since the journal already says
  /// where the entry goes and what it is called.
  Future<void> _create(
    BuildContext context,
    JournalSettings settings,
    DateTime day,
    String path,
  ) async {
    final ops = controller.ops!;
    final messenger = ScaffoldMessenger.of(context);
    var source = builtInJournalTemplate;
    if (settings.template case final template?) {
      try {
        final folder = await ops.templateFolder;
        source = await expandTemplateIncludes(
          await ops.readNote(template),
          sourcePath: template,
          resolve: (written) => templates.resolveInclude(ops, folder, written),
        );
      } on Object catch (error) {
        _log.warning('journal: template $template unusable ($error)');
        messenger.showSnackBar(
          SnackBar(content: Text(AppStrings.journalTemplateMissing(template))),
        );
      }
    }
    var answers = <String, String>{};
    final fields = templateFields(source);
    if (fields.isNotEmpty) {
      if (!context.mounted) return;
      final given = await showTemplateForm(context, fields: fields);
      if (given == null) return;
      answers = given;
    }
    final slash = path.lastIndexOf('/');
    final parent = slash < 0 ? '' : path.substring(0, slash);
    final name = path.substring(slash + 1, path.length - '.md'.length);
    final root = controller.root;
    final counters = templateUses(source, 'counter') && root != null
        ? await CounterStore.load(root)
        : null;
    int Function(String)? counter;
    if (counters != null) {
      final used = <String, int>{};
      counter = (key) => used.putIfAbsent(key, () => counters.use(key));
    }
    // The day's own date, at this moment's time: an entry made for last
    // Monday says Monday, and `{{time}}` still says when it was written.
    final now = _clock();
    final when = DateTime(
      day.year,
      day.month,
      day.day,
      now.hour,
      now.minute,
      now.second,
    );
    final clipboard = templateUses(source, 'clipboard')
        ? await templates.clipboardText()
        : '';
    await guard(() async {
      final rendered = renderTemplateWithCaret(
        source,
        title: name,
        now: when,
        answers: answers,
        context: TemplateContext(folder: parent, clipboard: clipboard),
        counter: counter,
      );
      if (parent.isNotEmpty) await ops.ensureFolder(parent);
      final row = await ops.createNote(
        parentPath: parent,
        name: name,
        content: rendered.text,
      );
      await counters?.save();
      _log.info('journal: made ${journalDayLabel(day)} (${row.path})');
      onCreated(row.path, rendered.caret);
    });
  }
}
