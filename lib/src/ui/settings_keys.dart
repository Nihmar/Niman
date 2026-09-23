/// The keys of the settings rows, in one place (issue #104).
///
/// Every row the settings search can find is named twice: once by the
/// screen that draws it, once by the index that points at it. As two
/// string literals those two names drift apart in silence — rename the
/// row's key and the search still finds the entry, still pushes the
/// screen, and simply never highlights anything, with nothing to fail.
///
/// Named here instead, so the two sides cannot disagree: a rename is one
/// edit, and a name that no longer exists is a compile error. The same
/// reason `Strings` is an abstract class rather than a map of fallbacks.
library;

// The members need no per-member docs: each is the key of the row its
// name says, and the screens and the index read them by that name.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

/// The key of every settings row that can be searched for.
abstract final class SettingsKeys {
  // Appearance.
  static const language = Key('language-choice');
  static const brightness = Key('theme-brightness-setting');
  static const palette = Key('theme-palette-setting');
  static const uiTextScale = Key('ui-text-scale-setting');
  static const splitRatio = Key('split-ratio-setting');
  static const closeToTray = Key('close-to-tray-setting');

  // Editor.
  static const toolbar = Key('toolbar-setting');
  static const editorSource = Key('editor-source-setting');
  static const editorWysiwyg = Key('editor-wysiwyg-setting');
  static const previewEnabled = Key('preview-enabled-setting');
  static const lineNumbers = Key('line-numbers-setting');
  static const readableLineLength = Key('readable-line-length-setting');
  static const noteColumnWidth = Key('note-column-width-setting');
  static const typewriter = Key('typewriter-setting');
  static const linkType = Key('link-type');
  static const missingNoteLocation = Key('missing-note-location');
  static const noteTextScale = Key('note-text-scale-setting');
  static const indentWidth = Key('indent-width');

  // Folders and paths.
  static const quickNote = Key('quick-note-setting');
  static const listFolder = Key('list-folder-setting');
  static const templateFolder = Key('template-folder-setting');
  static const templateHelp = Key('template-help-setting');
  static const attachmentsFolder = Key('attachments-folder-setting');
  static const journalFolder = Key('journal-folder-setting');
  static const journalEntryName = Key('journal-entry-name-setting');
  static const journalTemplate = Key('journal-template-setting');
  static const journalDayStart = Key('journal-day-start-setting');

  // Trash and history.
  static const trash = Key('trash-setting');
  // Not a settings row: the trash screen's own Empty action, which is
  // what the "delete permanently" entry goes to.
  static const trashEmptyAction = Key('empty-trash-action');
  static const trashAutoEmpty = Key('trash-auto-empty-setting');
  static const historyVersions = Key('history-versions-setting');
  static const historyInterval = Key('history-interval-setting');

  // Updates.
  static const autoUpdate = Key('auto-update-setting');
  static const checkUpdates = Key('check-updates-setting');

  // Diagnostics and about.
  static const debugLogs = Key('debug-logs-setting');
  static const exportLog = Key('export-log-setting');
  static const changelog = Key('changelog-setting');

  // Reminders.
  static const reminderShowTokens = Key('reminder-show-tokens');

  // Transcription.
  static const transcriptionModel = Key('transcription-model-setting');
  static const transcriptionLanguage = Key('transcription-language-setting');

  // Maintenance: actions rather than settings, searchable all the same.
  static const reindex = Key('reindex-setting');
  static const switchLibrary = Key('switch-library-setting');
  static const closeLibrary = Key('close-library-setting');
}
