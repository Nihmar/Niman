/// Where a way in from outside the app leads (issue #100 moved it out of
/// the shell): a notification tapped, a launcher quick action, a share, and
/// each of them as what a cold start carried.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/share_in.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/ui/capture/capture_routes.dart';
import 'package:niman/src/ui/capture/capture_services.dart';
import 'package:niman/src/ui/intent_features.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/ocr/ocr_notifier.dart';
import 'package:niman/src/ui/shell_create_flow.dart';
import 'package:niman/src/ui/shell_features_intro.dart';
import 'package:niman/src/ui/shell_import_flow.dart';
import 'package:niman/src/ui/shell_intent_gate.dart';
import 'package:niman/src/ui/shell_journal_ui.dart';

/// The shell's destinations for what reaches it from outside.
final class ShellOutsideRoutes {
  /// Routes from [reminders]' notifications, [shortcuts]' launcher actions
  /// and [shareIn]'s shares, each asked of [intents] first: a way in for a
  /// feature that is off says so instead (#1109). What a launch carried
  /// keeps [featuresIntro] away.
  new({
    required this.reminders,
    required this.shortcuts,
    required this.shareIn,
    required this.capture,
    required this.intents,
    required this.featuresIntro,
    required this.imports,
    required this.creates,
    required this.journal,
    required this.journalUi,
    required this.openTodo,
    required this.addTodo,
    required this.openQuickNote,
    required this.openRecognizedText,
    required this.openNote,
    required this.revealFolder,
  });

  /// The reminders: their taps and the one a cold start came from.
  final ReminderService reminders;

  /// The launcher's quick actions (T-SC-03).
  final ShortcutService shortcuts;

  /// What other apps share in (#40).
  final ShareInService shareIn;

  /// The web capture, whose notification can cancel it (#531).
  final CaptureServices capture;

  /// What a way in from outside asks before it opens a screen (#1109).
  final ShellIntentGate intents;

  /// The introduction of Settings → Features, kept away by a launch's
  /// own target.
  final ShellFeaturesIntro featuresIntro;

  /// Shares brought in.
  final ShellImportFlow imports;

  /// The launcher's New note, list and voice note.
  final ShellCreateFlow creates;

  /// Opens journal entries (#7).
  final JournalFlow journal;

  /// The journal's calendar, which an event's reminder opens on (#730).
  final ShellJournalUi journalUi;

  /// Shows the todo list, wherever the layout keeps it.
  final VoidCallback openTodo;

  /// Asks for a new task.
  final Future<void> Function() addTodo;

  /// Opens the quick note, or its chooser when none is set.
  final Future<void> Function() openQuickNote;

  /// Opens the text recognized from a file, at `path` (#594).
  final void Function(String path) openRecognizedText;

  /// Opens the note at `path` (library-relative).
  final void Function(String path) openNote;

  /// Shows the library folder `folder` in the tree.
  final void Function(String folder) revealFolder;

  /// Opens what the notification [payload] names: a capture's note or
  /// folder, the Todo tab, the journal on an event's day, a recognition's
  /// text. A [tap] is one while the shell is up.
  Future<void> notification(
    BuildContext context,
    String? payload, {
    bool tap = false,
  }) async {
    if (_followCaptureRoute(context, payload)) return;
    if (payload == todoReminderPayload && context.mounted) {
      if (tap) {
        const AppLogger(name: 'todo').debug('todo tap: opening the todo list');
      }
      if (intents.allows(featureOfReminderPayload(payload))) openTodo();
    } else if (journalReminderDayOf(payload) != null) {
      await _openReminderPayload(context, payload!);
    } else if (payload != null &&
        payload.startsWith(ocrNotificationPrefix) &&
        context.mounted) {
      openRecognizedText(payload.substring(ocrNotificationPrefix.length));
    }
  }

  /// A reminder's own destination: the journal on its day for an event
  /// (#730), the Todo tab for a task.
  Future<void> _openReminderPayload(
    BuildContext context,
    String payload,
  ) async {
    final day = journalReminderDayOf(payload);
    if (day == null || !context.mounted) return;
    // A reminder the calendar's switch outlived says so (#1109).
    if (!intents.allows(featureOfReminderPayload(payload))) return;
    const AppLogger(name: 'calendar').debug('event reminder tap: $payload');
    journalUi.showCalendar(context);
    await journal.openDay(context, day);
  }

  /// A notification tap that started the app lands on the Todo tab.
  Future<void> reminderLaunch(BuildContext context) async {
    final payload = await reminders.consumeLaunchPayload();
    if (payload != null) featuresIntro.requested();
    if (!context.mounted) return;
    await notification(context, payload);
  }

  /// A launcher quick action that started the app (T-SC-03, cold start).
  ///
  /// Asked for here rather than at app start because the action needs an
  /// open library: the shell mounts once the library is ready, so a first
  /// run that has to pick a library first still runs the action after.
  Future<void> shortcutLaunch(BuildContext context) async {
    final action = await shortcuts.consumeLaunchAction();
    if (action == null) return;
    featuresIntro.requested();
    if (!context.mounted) return;
    await runShortcut(context, action);
  }

  /// A share that started the app (#40, cold start).
  ///
  /// Asked for here for the same reason as the launcher actions: every
  /// share needs a library — text goes into one, a file is imported into
  /// one. Shares that arrive while there is no shell wait in the service
  /// and are delivered once one mounts.
  Future<void> shareLaunch(BuildContext context) async {
    final request = await shareIn.consumeLaunchRequest();
    if (request == null) return;
    featuresIntro.requested();
    if (!context.mounted) return;
    await imports.share(context, request);
  }

  /// Where a capture's notification leads (#531): the note it made, its
  /// folder in the tree, or the capture's end. False when [route] is not
  /// a capture's.
  bool _followCaptureRoute(BuildContext context, String? route) {
    final capture = captureRouteOf(route);
    if (capture == null || !context.mounted) return false;
    switch (capture) {
      case CaptureOpenNote(:final path):
        openNote(path);
      case CaptureShowFolder(:final folder):
        revealFolder(folder);
      case CaptureCancel(:final id):
        this.capture.background.cancel(id);
    }
    return true;
  }

  /// Runs [action]'s in-app flow: the same one the equivalent control
  /// uses, so a shortcut cannot drift from the button it mirrors.
  Future<void> runShortcut(BuildContext context, ShortcutAction action) async {
    if (!context.mounted) return;
    const AppLogger(name: 'shortcuts').debug('running ${action.id}');
    // Published for the app, not for a library: one whose feature this
    // library has off says so instead (#1109).
    if (!intents.allows(featureOfShortcut(action))) return;
    switch (action) {
      case ShortcutAction.quickNote:
        await openQuickNote();
      case ShortcutAction.journalToday:
        await journal.openToday(context);
      case ShortcutAction.newTodo:
        openTodo();
        await addTodo();
      case ShortcutAction.newNote:
        await creates.createNote(context);
      case ShortcutAction.newList:
        await creates.createListNote(context);
      case ShortcutAction.newVoice:
        await creates.createAudioNote(context);
    }
  }
}
