/// Which feature each way into the app from outside needs (#1109): a
/// launcher shortcut, a notification, a widget tap, a share.
///
/// A way in that leads to a feature that is off says so in one sentence
/// instead of opening a screen that is not there (see `ShellIntentGate`).
/// The shortcuts stay published whatever a library has on — they belong to
/// the app, not to one library — so the check is made when one is run.
library;

import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/todo/todo_reminder.dart';
import 'package:niman/src/widget/widget_target.dart';

/// The feature a launcher or tray shortcut opens, or null for core.
LibraryFeature? featureOfShortcut(ShortcutAction action) => switch (action) {
  ShortcutAction.quickNote => LibraryFeature.quickNote,
  ShortcutAction.journalToday => LibraryFeature.journal,
  ShortcutAction.newTodo => LibraryFeature.todo,
  ShortcutAction.newNote => null,
  ShortcutAction.newList => LibraryFeature.kindList,
  ShortcutAction.newVoice => LibraryFeature.kindAudio,
};

/// The feature a tap on the notification with [payload] opens, or null for
/// one that leads nowhere a switch can take away.
LibraryFeature? featureOfReminderPayload(String? payload) {
  if (payload == todoReminderPayload) return LibraryFeature.todo;
  if (journalReminderDayOf(payload) != null) return LibraryFeature.calendar;
  return null;
}

/// The feature a tap on a home-screen widget opens, or null for core.
LibraryFeature? featureOfWidgetTarget(WidgetTargetKind kind) => switch (kind) {
  WidgetTargetKind.todo => LibraryFeature.todo,
  WidgetTargetKind.study => LibraryFeature.kindFlashcards,
  WidgetTargetKind.note => null,
  // Where a widget that is off sends the tap: always there.
  WidgetTargetKind.features => null,
};

/// Where text another app shared goes.
enum SharedTextRoute {
  /// The capture sheet: a web page, or a quote from one (#531).
  capture,

  /// The end of the quick note.
  quickNote,

  /// A new note of its own, as a shared file is imported.
  importAsNote,
}

/// Where shared text goes under [features]: [isWebPage] text is captured
/// unless Web capture is off, when it is plain text and its link stays a
/// link; plain text goes to the quick note unless Quick note is off, when
/// it is imported as a note instead — shared text is never dropped.
SharedTextRoute sharedTextRoute({
  required bool isWebPage,
  required Features features,
}) {
  if (isWebPage && features.isOn(LibraryFeature.capture)) {
    return SharedTextRoute.capture;
  }
  return features.isOn(LibraryFeature.quickNote)
      ? SharedTextRoute.quickNote
      : SharedTextRoute.importAsNote;
}

/// The name of the note shared [text] is imported as: the share's subject,
/// else the text's first line, without what a file name cannot hold.
String sharedTextNoteName(String text, {String? subject}) {
  String clean(String? raw) => (raw ?? '')
      .replaceAll(RegExp(r'[\\/:*?"<>|#\[\]^\u0000-\u001f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  var name = clean(subject);
  if (name.isEmpty) {
    for (final line in text.split('\n')) {
      name = clean(line);
      if (name.isNotEmpty) break;
    }
  }
  if (name.length > 60) name = name.substring(0, 60).trim();
  // A leading dot would hide the file.
  name = name.replaceFirst(RegExp(r'^\.+'), '').trim();
  return name.isEmpty ? 'Shared' : name;
}
