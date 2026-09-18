// The English strings: the source language every other file translates.
//
// One class per locale file; see `base.dart` for the contract and
// `strings.dart` for the facade the app calls.
// ignore_for_file: public_member_api_docs, unnecessary_library_directive
library;

import 'package:niman/src/ui/strings/base.dart';

final class EnglishStrings extends Strings {
  const new();

  @override
  List<String> get monthNames => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  @override
  List<String> get monthNamesShort => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  @override
  List<String> get weekdayNames => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  @override
  List<String> get weekdayNamesShort => const [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Settings: editor toggles.
  @override
  String get trashTitle => 'Trash';
  @override
  String get trashSubtitle => 'Deletions move to .trash/ (off = hard delete)';
  @override
  String get trashAutoEmptyTitle => 'Auto-empty trash';
  @override
  String get trashAutoEmptySubtitle =>
      'Older deletions go for good when the library opens';
  @override
  String trashAutoEmptyValue(int days) => days == 0
      ? 'Never'
      : days == 1
      ? '1 day'
      : '$days days';
  @override
  String get debugLogsTitle => 'Debug logs';
  @override
  String get debugLogsSubtitle => 'Record app events in an in-memory buffer';
  @override
  String get lineNumbersTitle => 'Line numbers';
  @override
  String get lineNumbersSubtitle =>
      'Show the row-number column in the note editor';
  @override
  String get readableLineLengthTitle => 'Readable line length';
  @override
  String get readableLineLengthSubtitle =>
      "Keep a note's text in a centred column instead of the full "
      'width of the window';
  @override
  String get noteColumnWidthTitle => 'Column width';
  @override
  String get noteColumnWidthSubtitle =>
      'How wide the note column is, in pixels';
  @override
  String noteColumnWidthValue(int pixels) => '$pixels px';
  @override
  String get keyboardOnOpenTitle => 'Keyboard on open';
  @override
  String get keyboardOnOpenSubtitle =>
      'Show the keyboard as soon as a note opens (off = on first tap)';
  @override
  String get editorKindSource => 'Markdown source';
  @override
  String get editorKindWysiwyg => 'WYSIWYG';
  @override
  String get editorKindSourceSubtitle => 'Markdown source, as written';
  @override
  String get editorKindWysiwygSubtitle => 'Formatted text, edited in place';
  @override
  String get settingsFolderToCreate => 'to create';
  @override
  String get settingsSearchHint => 'Search settings';
  @override
  String settingsSearchResults(int count) =>
      count == 1 ? '1 setting found' : '$count settings found';
  @override
  String get settingsToggleOn => 'On';
  @override
  String get settingsToggleOff => 'Off';
  @override
  String get settingsPreviewEnabledTitle => 'Preview';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Show the rendered note beside the source editor';
  @override
  String get switchToWysiwygTooltip => 'Switch to the WYSIWYG editor';
  @override
  String get switchToSourceTooltip => 'Switch to the Markdown source';
  @override
  String get switchToSourceLabel => 'Source';
  @override
  String get switchToWysiwygLabel => 'WYSIWYG';
  @override
  String get wysiwygTooLarge =>
      'This note is too large for the WYSIWYG editor. Open it in the Markdown '
      'source.';

  // Settings: the section headings the list is grouped under.
  @override
  String get settingsSectionAppearance => 'Appearance';
  @override
  String get settingsSectionEditor => 'Editor';
  @override
  String get settingsSectionLibrary => 'Library';
  @override
  String get settingsSectionReminders => 'Reminders';
  @override
  String get settingsSectionShortcuts => 'Keyboard';
  @override
  String get keyboardShortcutsTitle => 'Keyboard shortcuts';

  // Settings home (issue #104): the groups the areas sit under.
  @override
  String get settingsGroupApp => 'App';
  @override
  String settingsGroupLibrary(String name) => 'Library $name';
  @override
  String get settingsGroupLibraryHint => 'applies only to this library';
  @override
  String get settingsGroupMaintenance => 'Maintenance';

  // Settings home rows.
  @override
  String get settingsAreaFolders => 'Folders and paths';
  @override
  String get settingsAreaTrashHistory => 'Trash and history';
  @override
  String get settingsAreaDiagnostics => 'Diagnostics and info';
  @override
  String get settingsAreaKeyboardDisabled =>
      'Needs a connected physical keyboard';
  @override
  String get settingsSectionUpdates => 'Updates';
  @override
  String get autoUpdateTitle => 'Automatic updates';
  @override
  String get autoUpdateSubtitle =>
      'Check GitHub Releases at launch and every 6 hours';
  @override
  String get checkForUpdatesTitle => 'Check for updates';
  @override
  String updateAvailableMessage(Object version) =>
      'Niman $version is available';
  @override
  String get updateUpToDate => 'Niman is up to date';
  @override
  String get updateCheckFailed => 'Update check failed';
  @override
  String updateSavedTo(Object path) => 'Update saved to $path';
  @override
  String get updateInstallerStarted => 'Installer started';
  @override
  String get settingsSectionDiagnostics => 'Diagnostics';
  @override
  String get settingsSpellCheckTitle => 'Check spelling';
  @override
  String get settingsSpellCheckSubtitle =>
      'Underline misspelled words while writing.';
  @override
  String get spellCheckDictionaryTitle => 'Dictionary';
  @override
  String get spellCheckDictionarySystem => 'System default';
  @override
  String get spellCheckDictionaryChoiceTitle => 'Choose dictionaries';
  @override
  String get spellCheckDictionaryChoiceSubtitle =>
      'Pick every language this library is written in. A word passes when '
      'any chosen dictionary knows it; with none chosen, the system '
      'locale decides.';
  @override
  String get spellCheckNoDictionaries =>
      'No dictionaries found on this system.';

  // Spelling review (T-PP-09).
  @override
  String get spellCheckTooltip => 'Check spelling';
  @override
  String get spellCheckTitle => 'Spelling';
  @override
  String get spellCheckEmpty => 'No spelling mistakes.';
  @override
  String get spellCheckUnavailable =>
      'hunspell is not installed on this system.';
  @override
  String get spellCheckNoSuggestions => 'No suggestions';
  @override
  String spellCheckCount(int count) => '$count to review';
  @override
  String spellCheckLine(int line) => 'line $line';

  @override
  String get addWordToDictionary => 'Add to dictionary';

  @override
  String indentWidthValue(int spaces) => '$spaces spaces';

  // Settings: theme (T-M6-05).
  @override
  String get themeBrightnessTitle => 'Brightness';
  @override
  String get themeBrightnessSubtitle =>
      'Light, dark, or whatever the device is set to';
  @override
  String get themeBrightnessSystem => 'System';
  @override
  String get themeBrightnessDay => 'Light';
  @override
  String get themeBrightnessNight => 'Dark';
  @override
  String get themePaletteTitle => 'Palette';
  @override
  String get themePaletteSubtitle =>
      'The colors of the interface and of the note';
  @override
  String get themePaletteSystem => 'System';

  // Settings: text size (T-M6-12).
  @override
  String get uiTextScaleTitle => 'Interface text size';
  @override
  String get uiTextScaleSubtitle =>
      'The tree, the tabs and the dialogs; on top of the system setting';
  @override
  String get noteTextScaleTitle => 'Note text size';
  @override
  String get noteTextScaleSubtitle =>
      'The editor and the preview, which always agree';

  // Settings: preview mode.
  @override
  String get previewModeTitle => 'Preview mode';
  @override
  String get previewModeSubtitle =>
      'Whether the preview shares the screen with the editor, or replaces '
      'it';
  @override
  String get previewModeAuto => 'Side by side';
  @override
  String get previewModeSwitch => 'Full screen';
  @override
  String get splitRatioTitle => 'Split width';
  @override
  String get splitRatioSubtitle =>
      'The editor’s share when the preview is side by side';

  // Settings: editor formatting.
  @override
  String get linkTypeTitle => 'Link format';
  @override
  String get linkTypeSubtitle => 'What the link button in the editor inserts';
  @override
  String get linkTypeWikilink => 'Wikilink';
  @override
  String get linkTypeMarkdown => 'Markdown';
  @override
  String get missingNoteLocationTitle => 'Create missing notes in';
  @override
  String get missingNoteLocationRoot => 'Library root';
  @override
  String get missingNoteLocationCurrentFolder => 'Current folder';
  @override
  String get indentWidthTitle => 'Indent width';
  @override
  String get indentWidthSubtitle =>
      'Spaces added per indent level in the editor';

  // Settings: language (T-L10N-04).
  @override
  String get languageTitle => 'Language';
  @override
  String get languageSubtitle => 'The language of the app’s own text';
  @override
  String get languageSystem => 'System';

  // List note kind (T-TK-02).
  @override
  String get listAddHint => 'Add an item';
  @override
  String get listAddTooltip => 'Add an item';
  @override
  String get listEmpty => 'No items yet';
  @override
  String get listDragHandleLabel => 'Reorder item';

  // Audio note kind (issue #56).
  @override
  String get audioEmpty => 'No recordings yet';
  @override
  String get audioRecord => 'Record';
  @override
  String get audioStop => 'Stop';
  @override
  String get audioPlay => 'Play';
  @override
  String get audioDelete => 'Delete recording';
  @override
  String get audioImport => 'Import an audio file';
  @override
  String get audioRecording => 'Recording…';
  @override
  String get audioPermissionDenied =>
      'Microphone permission denied — recording needs it.';
  @override
  String get newAudioNoteTitle => 'New voice note';
  @override
  String get newAudioNoteDefault => 'My recording';
  @override
  String get showAudioTooltip => 'Show recordings';
  @override
  String get audioMessageHint => 'Write a note…';
  @override
  String get audioSend => 'Send';
  @override
  String get audioRename => 'Rename recording';
  @override
  String get audioDescriptionHint => 'Describe this recording…';
  @override
  String get audioEditDescription => 'Edit description';
  @override
  String get audioDeleteNote => 'Delete note';
  @override
  String get audioEditNote => 'Edit note';
  @override
  String get audioPause => 'Pause';
  @override
  String get audioEditTitle => 'Edit title';
  @override
  String get audioTitleHint => 'Title this recording…';
  @override
  String audioUntitled(int n) => 'Recording $n';
  @override
  String get audioMoreActions => 'More actions';
  @override
  String get audioDiscardRecording => 'Discard recording';
  @override
  String get audioPauseRecording => 'Pause recording';
  @override
  String get audioResumeRecording => 'Resume recording';
  @override
  String get audioRecordingPaused => 'Paused';
  @override
  String get audioSavingRecording => 'Saving…';

  // Launcher quick actions (T-SC-02), in the order they are published.
  @override
  String get shortcutQuickNote => 'Quick note';
  @override
  String get shortcutNewTodo => 'New todo';
  @override
  String get shortcutNewNote => 'New note';
  @override
  String get shortcutNewList => 'New list';
  @override
  String get shortcutNewAudio => 'New voice note';
  @override
  String get shortcutToggleSidebar => 'Show or hide the file tree';
  @override
  String get shortcutEditorSection => 'In the editor';
  @override
  String get shortcutFind => 'Find';
  @override
  String get shortcutReplace => 'Find and replace';
  @override
  String get shortcutSavingNote =>
      'Edits are saved automatically, so there is no save shortcut.';

  // Editor status bar.
  @override
  String get noteStatusLoading => 'Loading…';
  @override
  String get noteStatusSaving => 'Saving…';
  @override
  String get noteStatusUnsaved => 'Unsaved';
  @override
  String get noteStatusSaved => 'Saved';
  @override
  String get noteStatusError => 'Error';
  @override
  String get noteNotText =>
      'This file is not a text note, so Niman cannot show it here.';
  @override
  String get noteLoadFailed => 'This note could not be opened.';
  @override
  String wordCount(int count) => count == 1 ? '1 word' : '$count words';
  @override
  String get outlineTooltip => 'Outline';
  @override
  String get outlineNoHeadings => 'No headings';
  @override
  String get outlineNoTitle => '(no title)';

  // Editor toolbar: one name per button.
  @override
  String get toolbarBold => 'Bold';
  @override
  String get toolbarItalic => 'Italic';
  @override
  String get toolbarStrikethrough => 'Strikethrough';
  @override
  String get toolbarSuperscript => 'Superscript';
  @override
  String get toolbarUnderline => 'Underline';
  @override
  String get toolbarLink => 'Link';
  @override
  String get toolbarCode => 'Code block';
  @override
  String get toolbarImage => 'Insert image';
  @override
  String get toolbarHeading => 'Heading';
  @override
  String get toolbarList => 'List';
  @override
  String get toolbarOrderedList => 'Numbered list';
  @override
  String get toolbarQuote => 'Quote';
  @override
  String get toolbarIndent => 'Indent';
  @override
  String get toolbarOutdent => 'Outdent';

  // Editor tools (#136): the Tools button, the sheet it opens, and
  // the list count that is the first tool in it.
  @override
  String get toolbarTools => 'Tools';
  @override
  String get editorToolsTitle => 'Editor tools';
  @override
  String get toolCountListTitle => 'Count a list';
  @override
  String get toolCountListSubtitle =>
      'Total up what the rows list, as a checklist';
  @override
  String get toolCountListNeedsList => 'This note has no list to count';
  @override
  String get tallySourceLabel => 'List';
  @override
  String get tallyCutLabel => 'Read each row as';
  @override
  String get tallyCutDash => 'Name - values';
  @override
  String get tallyCutColon => 'Name: values';
  @override
  String get tallyCutCommas => 'Values, comma separated';
  @override
  String get tallyCutWhole => 'The whole row, as one value';
  @override
  String get tallySortLabel => 'Order';
  @override
  String get tallySortCount => 'Most first';
  @override
  String get tallySortAlphabetical => 'Alphabetical';
  @override
  String get tallySortFirstSeen => 'As listed';
  @override
  String get tallyInsert => 'Insert';
  @override
  String get tallyUpdate => 'Update';
  @override
  String get tallyNothingToCount => 'Nothing to count here';
  @override
  String get headingDialogTitle => 'Heading level';

  // Toolbar settings (T-TB-05).
  @override
  String get toolbarSettingsTitle => 'Editor toolbar';
  @override
  String get toolbarSettingsHint =>
      'Drag to reorder; the eye shows or hides a button.';
  @override
  String get toolbarShowButton => 'Show';
  @override
  String get toolbarHideButton => 'Hide';
  @override
  String get toolbarResetOrder => 'Restore defaults';

  // Preview switch (phone mode).
  @override
  String get showPreviewTooltip => 'Show preview';
  @override
  String get showEditorTooltip => 'Show editor';
  @override
  String get enterFullScreenTooltip => 'Full screen';
  @override
  String get exitFullScreenTooltip => 'Exit full screen';

  // Raw-HTML table fallback.
  @override
  String get htmlTableFallback => '(raw HTML table)';

  // Search (T-M3-05).
  @override
  String get searchHint => 'Search notes';
  @override
  String get searchModeWords => 'Words';
  @override
  String get searchModeContains => 'Contains';
  @override
  String get searchEmptyHint =>
      'Type to search the library, or key = value to filter by frontmatter';
  @override
  String get searchTooShortHint => 'Type at least 2 characters';
  @override
  String get searchNoMatches => 'No matches';
  @override
  String get searchLoadMore => 'Show more';

  // Replace (T-M3-10).
  @override
  String get replaceTooltip => 'Replace…';
  @override
  String get replaceInNoteAction => 'Replace in this note…';
  @override
  String get replaceInThisNote => 'Replace in this note';
  @override
  String get replaceWithLabel => 'Replace with';
  @override
  String get replaceCaseSensitive => 'Case-sensitive';
  @override
  String get replaceWholeWordsHint =>
      'only exact whole-word matches are replaced';
  @override
  String get replaceConfirm => 'Replace';
  @override
  String get replaceCancel => 'Close';
  @override
  String get replaceUnavailable => 'Replace is unavailable right now';

  // Editor find & replace.
  @override
  String get findInNoteTooltip => 'Find in note';
  @override
  String get editorFindHint => 'Find';
  @override
  String get editorReplaceHint => 'Replace';
  @override
  String get editorFindCaseTooltip => 'Match case';
  @override
  String get editorFindPreviousTooltip => 'Previous match';
  @override
  String get editorFindNextTooltip => 'Next match';
  @override
  String get editorFindCloseTooltip => 'Close find';
  @override
  String get editorFindReplaceModeTooltip => 'Replace mode';
  @override
  String get editorReplaceOneTooltip => 'Replace this match';
  @override
  String get editorReplaceAllTooltip => 'Replace all matches';

  // Tags (T-M3-06).
  @override
  String get openTagsTooltip => 'Tags';
  @override
  String get tagsTitle => 'Tags';
  @override
  String get tagsEmpty => 'No tags yet — add a #tag or frontmatter tags';
  @override
  String get tagsBackTooltip => 'Back to search';
  @override
  String get tagsNotesEmpty => 'No notes with this tag';
  @override
  String tagsNotesCapped(int limit) =>
      'Only the first $limit are listed — search the tag to narrow it down';

  // Link navigation (T-M3-07).
  @override
  String get unresolvedLinkTitle => 'Link not found';
  @override
  String get headingNotFoundTitle => 'Heading not found';
  @override
  String get ambiguousLinkTitle => 'Several notes match';
  @override
  String get openLinkFailed => 'Could not open link';

  // Dead-link note creation (issue #78).
  @override
  String get missingNoteDialogTitle => 'Note does not exist';
  @override
  String missingNoteDialogBody(String path) => "Create '$path'?";
  @override
  String missingNoteFolderMissing(String folder) =>
      "The folder '$folder' does not exist";

  // Task lists (T-TD-04).
  @override
  String get todoOpen => 'Open';
  @override
  String get todoDone => 'Done';

  // Filter row + sheet (T-TDM-03).
  @override
  String get todoAllDates => 'All dates';
  @override
  String get todoFilter => 'Filter';
  @override
  String get todoNoTokens => 'No tokens in this list';
  @override
  String get todoCountOpen => 'open';
  @override
  String get todoCountDone => 'done';
  @override
  String get todoEmptyOpen => 'No open tasks yet';
  @override
  String get todoEmptyDone => 'Nothing completed yet';
  @override
  String get todoEmptyFiltered => 'No tasks match';
  @override
  String get todoTitle => 'Todo';
  @override
  String get todoAddTooltip => 'Add task';

  // The todo.txt format help (T-TD-08).
  @override
  String get todoHelpTitle => 'The todo.txt format';
  @override
  String get todoHelpTooltip => 'Format help';
  @override
  String get todoHelpIntro =>
      'Your tasks are one plain text file, one task per line. Niman '
      'writes the syntax for you, but nothing is hidden: you can edit '
      'the file in any editor and Niman will read it back.';
  @override
  String get todoHelpFilesTitle => 'The two files';
  @override
  String get todoHelpFilesBody =>
      'Open tasks live in todo.txt at the root of your library. '
      'Completing one moves its line to done.txt, so todo.txt stays '
      'short. If a completed line ends up back in todo.txt, Niman '
      'archives it the next time it reads the files.';
  @override
  String get todoHelpLineTitle => 'Anatomy of a line';
  @override
  String get todoHelpLineBody =>
      'Everything before the description is optional and must come in '
      'this order:';
  @override
  String get todoHelpDoneBody =>
      'Marks the task done. Niman adds it when you tick the checkbox.';
  @override
  String get todoHelpPriority => '(A) to (Z)';
  @override
  String get todoHelpPriorityBody =>
      'Priority. A is the highest. Shown as a badge in the list.';
  @override
  String get todoHelpDatesBody =>
      'Completion date, then creation date. With only one date it is the '
      'creation date, unless the line starts with x.';
  @override
  String get todoHelpTokensTitle => 'Projects, contexts and tags';
  @override
  String get todoHelpTokensBody =>
      'Anywhere in the description, a word with one of these prefixes '
      'becomes a chip you can filter by. Nothing is predefined: a token '
      'exists as soon as you write it.';
  @override
  String get todoHelpProjectBody =>
      'What the task is part of, for example +kitchen or +thesis.';
  @override
  String get todoHelpContextBody =>
      'Where or how you will do it, for example @home or @calls.';
  @override
  String get todoHelpHashtagBody =>
      'A free label, for anything the other two do not cover.';
  @override
  String get todoHelpTagsTitle => 'Dates and reminders';
  @override
  String get todoHelpTagsBody =>
      'These are key:value tags. Niman writes them from the task dialog, '
      'and reads them wherever they appear on the line.';
  @override
  String get todoHelpDueBody =>
      'The due date. Drives the coloured badge and the due filters.';
  @override
  String get todoHelpRemBody =>
      'When to send a notification, in your local time. It fires with '
      'the screen off and the app closed.';
  @override
  String get todoHelpRemDesktop =>
      'On desktop Niman must be running when the time comes: the reminder is '
      'shown while the app is open, and nothing fires when it is closed.';
  @override
  String get todoHelpOtherBody =>
      'Kept exactly as written, so tags from other todo.txt apps survive '
      'a round trip. Niman does not act on them, rec: included: a '
      'recurring task is not repeated yet.';
  @override
  String get todoHelpEditTitle => 'Editing outside Niman';
  @override
  String get todoHelpEditBody =>
      'A task you have not touched is written back byte for byte, odd '
      'spacing included. Edit a line and Niman rewrites that one line in '
      'its canonical form, leaving the rest of the file alone.';

  // Task dialog (T-TD-06).
  @override
  String get todoAddTitle => 'Add task';
  @override
  String get todoEditTitle => 'Edit task';
  @override
  String get todoDescriptionHint => 'Description';
  @override
  String get todoCancel => 'Cancel';
  @override
  String get todoSave => 'Save';
  @override
  String get todoEditAction => 'Edit';
  @override
  String get todoDeleteAction => 'Delete';

  // Task filters (T-TD-05).
  @override
  String get todoDueOverdue => 'Overdue';
  @override
  String get todoDueToday => 'Today';
  @override
  String get todoDueNext7 => 'Next 7 days';
  @override
  String get todoDueNoDate => 'No date';
  @override
  String get todoRowDue => 'Due';
  @override
  String get todoRowDueToday => 'Due today';
  @override
  String get todoSortTooltip => 'Sort';
  @override
  String get todoSortDue => 'Due date';
  @override
  String get todoSortPriority => 'Priority';
  @override
  String get todoSortCreation => 'Creation date';

  // Task dialog pickers (T-TD-06).
  @override
  String get todoNoPriority => 'No priority';
  @override
  String get todoNoPriorityShort => 'None';
  @override
  String get todoMorePriorities => 'More…';
  @override
  String get todoPriorityTitle => 'Priority';
  @override
  String get todoNoDueDate => 'No due date';
  @override
  String get todoNoReminder => 'No reminder';
  @override
  String get todoAddProject => '+ Project';
  @override
  String get todoAddContext => '@ Context';
  @override
  String get todoAddHashtag => '# Tag';

  // Task reminders (T-TD-07).
  @override
  String get todoReminderChannel => 'Task reminders';
  @override
  String get todoReminderChannelDescription =>
      'Scheduled alerts for tasks with a reminder time.';
  @override
  String get todoReminderBody => 'Todo reminder';
  @override
  String get todoReminderFallbackTitle => 'Task reminder';
  @override
  String get todoReminderBlocked =>
      'Notifications are off, so reminders will not appear.';
  @override
  String get todoReminderBattery =>
      'Battery optimization is on for Niman. The system may sleep the '
      'app and drop pending reminders.';
  @override
  String get todoReminderInexact =>
      'This device does not allow exact alarms, so a reminder can arrive '
      'several minutes late with the screen off.';
  @override
  String get reminderShowTokensTitle => 'Tags in reminder notifications';
  @override
  String get reminderShowTokensSubtitle =>
      'Keep +project, @context and #tag in the notification text. Off '
      'shows only the task you typed.';
  @override
  String get todoReminderFixAction => 'Open settings';
  @override
  String get todoReminderDismissAction => 'Dismiss';
  @override
  String get todoReminderDue => 'Due';

  // Actions and buttons shared by the dialogs (T-L10N-06).
  @override
  String get actionOk => 'OK';
  @override
  String get actionCancel => 'Cancel';
  @override
  String get actionCreate => 'Create';
  @override
  String get actionNew => 'New';
  @override
  String get actionSave => 'Save';
  @override
  String get actionClear => 'Clear';
  @override
  String get actionChoose => 'Choose';
  @override
  String get actionDelete => 'Delete';
  @override
  String get actionRename => 'Rename';
  @override
  String get actionMove => 'Move';
  @override
  String get saveAndClose => 'Save and close';
  @override
  String get closeUnsavedTitle => 'Unsaved changes';
  @override
  String closeUnsavedBody(List<String> names) {
    if (names.length == 1) {
      return "'${names.first}' has edits that are not saved yet. "
          'Save them before closing?';
    }
    return '${names.length} notes have edits that are not saved yet. '
        'Save them before closing?';
  }

  @override
  String get closeSaveFailed => 'Could not save; still open.';
  @override
  String get actionRestore => 'Restore';
  @override
  String get actionEmpty => 'Empty';

  // The shell: app bar, tabs and tree actions.
  @override
  String get hideSidebarTooltip => 'Hide sidebar (Ctrl+B)';
  @override
  String get showSidebarTooltip => 'Show sidebar (Ctrl+B)';
  @override
  String get windowMinimizeTooltip => 'Minimize';
  @override
  String get windowMaximizeTooltip => 'Maximize';
  @override
  String get windowRestoreTooltip => 'Restore';
  @override
  String get windowCloseTooltip => 'Close';
  @override
  String get tabFiles => 'Files';
  @override
  String get tabSearch => 'Search';
  @override
  String get tabSettings => 'Settings';
  @override
  String get quickNoteTitle => 'Quick note';
  @override
  String get treeEmpty => 'No notes yet';
  @override
  String get selectANote => 'Select a note';
  @override
  String get showListTooltip => 'Show list';
  @override
  String get editRawTooltip => 'Edit raw';
  @override
  String get sortAscTooltip => 'Sort A-Z';
  @override
  String get sortDescTooltip => 'Sort Z-A';
  @override
  String get newNoteTitle => 'New note';
  @override
  String get newItemTooltip => 'New';
  @override
  String get closeMenuTooltip => 'Close';
  @override
  String get newFolderTitle => 'New folder';
  @override
  String get newNoteSameFolder => 'New note in the same folder';
  @override
  String get newFromTemplateSameFolder =>
      'New from template in the same folder';
  @override
  String trashOriginalPath(String path) => 'was at $path';
  @override
  String get trashOriginalRoot => 'was in the library root';
  @override
  String trashItemCount(int count) => count == 1 ? '1 item' : '$count items';
  @override
  String get newNoteHere => 'New note here';
  @override
  String get newFolderHere => 'New folder here';
  @override
  String get newListNoteTitle => 'New list note';
  @override
  String get newListNoteDefault => 'My list';
  @override
  String get setAsQuickNote => 'Set as quick note';
  @override
  String get currentQuickNote => 'Current quick note';
  @override
  String get pinnedSection => 'Pinned';
  @override
  String pinnedSectionCount(int count) => 'Pinned · $count';
  @override
  String get templateFolderTitle => 'Template folder';
  @override
  String get newFromTemplateTitle => 'New from template';
  @override
  String get newFromTemplateHere => 'New from template here';
  @override
  String get templateFormTitle => 'Fill in the template';
  @override
  String get templateFormBacklink => 'Linked from';
  @override
  String get templateFormNoNote => 'No note';
  @override
  String get templateFormPickNote => 'Choose the note';

  // The template placeholder reference (T-TPL-08).
  @override
  String get templateHelpTitle => 'Template placeholders';
  @override
  String get templateHelpSubtitle =>
      'Date, title and the other values to fill in';
  @override
  String get quickNoteSubtitle => 'The note the Quick note tab opens';
  @override
  String get listFolderSubtitle => 'The new task lists';
  @override
  String get templateFolderSubtitle => 'The source of New from template';
  @override
  String get attachmentsFolderSubtitle => 'Images and audio placed in a note';
  @override
  String get templateHelpIntro =>
      'A template is an ordinary note with holes in it. Creating a note '
      'from one copies its text and fills the holes in.';
  @override
  String get templateHelpUnknown =>
      'A placeholder Niman does not know is left exactly as written, so a '
      'typo shows up in the note instead of quietly eating a line.';
  @override
  String get templateHelpValuesTitle => 'Values';
  @override
  String get templateHelpTitleBody =>
      'The name the note is being created under.';
  @override
  String get templateHelpDateBody =>
      'Today, and the time now. Both take a format: {{date:DD/MM/YYYY}}.';
  @override
  String get templateHelpNowBody => 'The date and the time together.';
  @override
  String get templateHelpUuidBody =>
      'A fresh identifier, a different one at every occurrence.';
  @override
  String get templateHelpCounterBody =>
      'A number that counts up per name, kept across restarts: the first '
      'note writes 1, the next 2. Same name in one note writes the same '
      'number; combine with |pad:3.';
  @override
  String get templateHelpCursorBody =>
      'Lands the caret here when the note is created; the marker itself '
      'is not written. First marker wins, no filters, fresh notes only — '
      'and the keyboard opens even with auto-focus off.';
  @override
  String get templateHelpDatesTitle => 'Writing a date';
  @override
  String get templateHelpDatesBody =>
      'These stand for parts of the date inside a format. Anything else is '
      'literal, and text in single quotes is literal too. Month and '
      'weekday names follow the app language.';
  @override
  String get templateHelpYear => 'the year: 2026, 26';
  @override
  String get templateHelpMonth => 'the month: 03, 3, March, Mar';
  @override
  String get templateHelpDay => 'the day: 09, 9, Monday, Mon';
  @override
  String get templateHelpTime => 'hours, minutes, seconds';
  @override
  String get templateHelpWeek => 'the ISO week and the quarter: 11, 11, 1';
  @override
  String get templateHelpFiltersTitle => 'Filters';
  @override
  String get templateHelpFiltersBody =>
      'A value can be followed by filters, applied left to right.';
  @override
  String get templateHelpCaseBody =>
      'Upper case, lower case, and the first letter of each word — a word '
      'you capitalised yourself is left alone.';
  @override
  String get templateHelpSlugBody =>
      'The link form of the text, for building a wikilink.';
  @override
  String get templateHelpPadBody =>
      'Trim the ends; pad with zeros to a width; use a fallback when the '
      'value is empty.';
  @override
  String get templateHelpShiftBody =>
      'Move a date by days, weeks, months or years — next week’s lecture, '
      'last month’s file.';
  @override
  String get templateHelpSnapBody =>
      'Snap a date to the start or the end of its week, month or year.';
  @override
  String get templateHelpAskTitle => 'Asking you something';
  @override
  String get templateHelpAskBody =>
      'A form appears before the note is created, one box per question — '
      'and one for the backlink, when the template wants one. '
      'The same label twice is one question, and its answer fills every '
      'occurrence — the folder and the file name included.';
  @override
  String get templateHelpAskFieldBody =>
      'A box to type in; the text after the second colon is what it starts '
      'with.';
  @override
  String get templateHelpChoiceBody =>
      'A pick from a list, separated by commas.';
  @override
  String get templateHelpWhereTitle => 'Where the note goes';
  @override
  String get templateHelpWhereBody =>
      'These are not text: they are instructions, and they live in a '
      'niman: block in the template’s own frontmatter. The block is '
      'obeyed and then removed, so it never appears in the note. Their '
      'values may hold placeholders.';
  @override
  String get templateHelpFolderBody =>
      'The folder the note is created in, made if it is not there. Without '
      'it the note lands where you were.';
  @override
  String get templateHelpFilenameBody =>
      'What the note is called. A template that says this is not asked for '
      'a name.';
  @override
  String get templateHelpAppendBody =>
      'Add to the note if it is already there, instead of making a second '
      'one. This is what turns a month of meetings into one file.';
  @override
  String get templateHelpOpenBody =>
      'What happens once the note exists: the editor (the default), the '
      'preview, or nothing — the note is filed and you stay where you '
      'were.';
  @override
  String get templateHelpAroundTitle => 'Where it came from';
  @override
  String get templateHelpParentBody =>
      'A note you pick in the form, which suggests the one on screen; write '
      '[[{{parent}}]] for a link back to it.';
  @override
  String get templateHelpFolderValueBody => 'The folder the note ended up in.';
  @override
  String get templateHelpClipboardBody =>
      'What is on the clipboard, and the editor selection when the note was '
      'started from one.';
  @override
  String get templateHelpIncludeTitle => 'Reusing a piece';
  @override
  String get templateHelpIncludeBody =>
      'Pastes another template in, so ten templates can share one checklist. '
      'It is looked for in the template folder first, and the .md may be '
      'left off. Its own questions join the same form.';
  @override
  String get templateHelpExampleTitle => 'All together';

  // What an {{include:…}} that could not be pasted leaves behind (T-TPL-06).
  @override
  String includeMissing(String path) => '⚠ no template “$path”';
  @override
  String includeCycle(String path) => '⚠ “$path” includes itself';
  @override
  String includeTooDeep(String path) => '⚠ “$path” is nested too deep';
  @override
  String frontmatterInvalid(String reason) => 'Frontmatter not read: $reason';
  @override
  String templateFrontmatterInvalid(String template, String reason) =>
      'The frontmatter of “$template” was not read, so its folder and '
      'file name did nothing: $reason';
  @override
  String get templatePickerTitle => 'Choose a template';
  @override
  String templatePickerEmpty(String folder) =>
      'No templates yet. Put a note in $folder/ and it becomes one.';

  // Tree actions.
  @override
  String get actionPin => 'Pin';
  @override
  String get actionUnpin => 'Unpin';
  @override
  String get pinToWidget => 'Pin to home widget';
  @override
  String get pinnedForWidget =>
      'Pinned: now place the Note widget on the home screen';
  @override
  String get pinWidgetUnavailable =>
      'Home-screen widgets are available on Android';

  // Handing a note's file to the OS (issue #76).
  @override
  String get openInFileManager => 'Show in file manager';
  @override
  String get openInDefaultApp => 'Open in default app';
  @override
  String get openFileMissing => 'This note’s file is not on disk';
  @override
  String get openFileFailed => 'Could not open this note outside Niman';

  @override
  String get movedToTrash => 'Moved to trash';
  @override
  String get deletedMessage => 'Deleted';
  @override
  String deleteToTrashConfirm(String name) => '$name will be moved to .trash/';
  @override
  String deleteForeverConfirm(String name) =>
      '$name will be permanently deleted';
  @override
  String get chooseDestination => 'Choose destination';
  @override
  String get libraryRoot => 'Library root';
  @override
  String moveTitle(String name) => 'Move $name';
  @override
  String headingLevelLabel(int level) => 'Heading $level';

  // Quick note tab and picker.
  @override
  String get quickNoteEmpty =>
      'No quick note yet. Choose an existing note, or create a new '
      'one — the quick note opens here.';
  @override
  String get quickNoteChooseAction => 'Choose a note…';
  @override
  String get quickNoteCreateAction => 'Create a new note…';
  @override
  String get quickNoteNewTitle => 'New quick note';
  @override
  String get quickNotePickerTitle => 'Choose quick note';

  // Folder picker (T-TK-07).
  @override
  String get folderPickerNewFolder => 'New folder';
  @override
  String get folderPickerEmpty => 'No folders yet';
  @override
  String get listFolderTitle => 'List folder';
  @override
  String get attachmentsFolderTitle => 'Attachments folder';

  // Trash (M1).
  @override
  String get trashEmpty => 'Trash is empty';
  @override
  String get trashEmptyAction => 'Empty trash';
  @override
  String get trashEmptyConfirm =>
      'This deletes everything in the trash folder permanently, '
      'including items Niman did not put there.';
  @override
  String trashDeleteConfirm(String name) =>
      '$name will be deleted permanently (no restore)';
  @override
  String get trashDeletePermanently => 'Delete permanently';

  // The open/create library screen.
  @override
  String get openLibraryIntro =>
      'Open a folder of Markdown notes as your library';
  @override
  String get openLibraryExisting => 'Open existing';
  @override
  String get openLibraryCreate => 'Create new';
  @override
  String get openLibraryCreateTitle => 'Create new library';
  @override
  String get openLibraryFolderName => 'Folder name';
  @override
  String get openLibraryChooseFolder => 'Choose the library folder';
  @override
  String get openLibraryChooseParent =>
      'Choose the folder the library will be created in';
  @override
  String get openLibraryUnsupported =>
      'That folder is not supported. Pick a folder on the device storage.';
  @override
  String indexingCount(int done, int total) => '$done of $total notes';

  // The known-library list on the home screen (T-ML-05, T-ML-07).
  @override
  String get knownLibrariesTitle => 'Your libraries';
  @override
  String get libraryUnreachable => 'Not reachable';
  @override
  String get libraryOpenedToday => 'Opened today';
  @override
  String get libraryOpenedYesterday => 'Opened yesterday';
  @override
  String libraryOpenedDaysAgo(int days) => 'Opened $days days ago';
  @override
  String libraryOpenedOn(DateTime when) {
    final d = when.day.toString().padLeft(2, '0');
    final m = when.month.toString().padLeft(2, '0');
    return 'Opened on ${when.year}-$m-$d';
  }

  @override
  String get libraryOpenNow => 'Open now';
  @override
  String get switchLibraryTitle => 'Switch library';
  @override
  String get libraryForget => 'Forget';
  @override
  String libraryForgetTitle(String name) => 'Forget "$name"?';
  @override
  String get libraryForgetExplained =>
      'It goes off this list. The folder, the notes and the library '
      'settings inside it are left alone, and opening it again brings '
      'it back.';

  // Android storage access.
  @override
  String get storageAccessAction => 'Grant file access';
  @override
  String get storageAccessNeeded =>
      'Niman cannot read your notes without "All files access". Grant it '
      'to open a library.';
  @override
  String get storageAccessExplained =>
      'Niman reads your notes as ordinary files, so Android needs to '
      'allow it access to all files. Nothing is uploaded, and only the '
      'library folder you pick is read.';
  @override
  String folderAccessDenied(Object error) =>
      'The system did not give access to the folder: $error';
  @override
  String folderPickFailed(Object error) => 'Could not pick a folder: $error';

  // Settings screen rows and messages.
  @override
  String get settingsTitle => 'Settings';
  @override
  String get libraryPathTitle => 'Library path';
  @override
  String get reindexTitle => 'Re-index now';
  @override
  String get reindexDone => 'Re-index complete';
  @override
  String get closeLibraryTitle => 'Close library';
  @override
  String get exportLogTitle => 'Export debug log';
  @override
  String get exportLogSubtitle =>
      'Save the recorded events to a file you choose';
  @override
  String get exportLogEmpty => 'The debug log buffer is empty';
  @override
  String get quickNoteUnset => 'Not set yet';
  @override
  String exportLogDone(Object target) => 'Debug log exported to $target';
  @override
  String exportLogFailed(Object error) => 'Export failed: $error';

  // Replace results (T-M3-10).
  @override
  String replaceNoMatch(String term) =>
      'No whole-word match of "$term" was found';
  @override
  String replaceDone(int occurrences, String term, int notes) =>
      'Replaced $occurrences occurrence(s) of "$term" in $notes note(s)';
  @override
  String replaceSkipped(int skipped) => ' ($skipped open note(s) skipped)';
  @override
  String replacePreviewEmpty(String term, String? only) =>
      'No exact whole-word match of "$term" '
      '${only == null ? 'was found' : 'found in $only'}';

  // About (issue #80).
  @override
  String get settingsSectionAbout => 'About';
  @override
  String get versionTitle => 'Version';
  @override
  String get changelogTitle => 'Changelog';
  @override
  String get changelogEmpty => 'No changelog entries available';
  @override
  String changelogWhatsNew(String version) => "What's new in $version";

  // Note history (issues #13, #55, #67).
  @override
  String get noteHistoryTitle => 'History';
  @override
  String get noteMenuTooltip => 'Note actions';
  @override
  String get historyCurrentVersion => 'Current version';
  @override
  String get historyCurrentSubtitle => 'The note as it is now';
  @override
  String get historyToday => 'Today';
  @override
  String get historyYesterday => 'Yesterday';
  @override
  String get historyReasonSession => 'before editing';
  @override
  String get historyReasonInterval => 'while editing';
  @override
  String get historyReasonRestore => 'before restore';
  @override
  String get historyReasonSync => 'before sync';
  @override
  String get historyReasonReplace => 'before replace';
  @override
  String get historyReasonUnknown => 'recovered';
  @override
  String get historySyncBase => 'sync base';
  @override
  String get historyEmpty =>
      'No versions yet. Niman keeps one when you start editing the note, '
      'then at most one every few minutes while you write.';
  @override
  String historyKept(int kept, int limit) => '$kept of $limit versions kept';
  @override
  String get historyBaseKept => 'The sync base is kept beyond the limit.';
  @override
  String get historyOff =>
      'History is off for this library (Settings, Library).';
  @override
  String get historyLoadFailed => 'Could not read the history';
  @override
  String get historyCompareSubtitle => 'Compared with the current version';
  @override
  String get historyTabChanges => 'Changes';
  @override
  String get historyTabVersion => 'Version';
  @override
  String get historyNoChanges => 'Same text as the current version.';
  @override
  String get historyRestoreAction => 'Restore this version';
  @override
  String historyRestoreConfirmTitle(String when) =>
      'Restore the version of $when?';
  @override
  String get historyRestoreConfirmBody =>
      'The current text is kept in the history first, so you can always '
      'go back.';
  @override
  String get historyRestoreConfirm => 'Restore';
  @override
  String historyRestored(String when) => 'Restored the version of $when';
  @override
  String get historyRestoreFailed => 'Could not restore the version';
  @override
  String get actionUndo => 'Undo';
  @override
  String diffLineRange(int start, int end) => 'Lines $start–$end';
  @override
  String diffLineSingle(int line) => 'Line $line';
  @override
  String diffUnchanged(int count) =>
      count == 1 ? '1 unchanged line' : '$count unchanged lines';
  @override
  String get historyTakeHunk => 'Restore this';
  @override
  String historyRestoreSelectedAction(int count) =>
      count == 1 ? 'Restore 1 change' : 'Restore $count changes';
  @override
  String get historyRestoreSelectedConfirmBody =>
      "The changes you picked go back to this version's text. The note as it "
      'is now is kept as a version first, so you can undo this.';
  @override
  String get historyNoteChangedReloaded =>
      'The note changed while you were here — the comparison has been '
      'refreshed.';
  @override
  String get historyVersionsTitle => 'Versions to keep';
  @override
  String get historyVersionsSubtitle => 'Per note, in .history/';
  @override
  String historyVersionsValue(int count) => count == 0 ? 'None' : '$count';
  @override
  String get historyIntervalTitle => 'New version at most every';
  @override
  String get historyIntervalSubtitle =>
      'While you write; starting to edit a note always keeps one';
  @override
  String historyIntervalValue(int minutes) => '$minutes min';
  @override
  String get settingsSectionTranscription => 'Transcription';
  @override
  String get transcriptionModelTitle => 'Model';
  @override
  String get transcriptionModelNone => 'None';
  @override
  String get transcriptionLanguageTitle => 'Language';
  @override
  String get transcriptionLanguageSubtitle =>
      'The language spoken in your recordings. Naming it is more accurate '
      'than detecting it.';
  @override
  String transcriptionLanguageApp(String language) =>
      'Same as the app ($language)';
  @override
  String get transcriptionLanguageDetect => 'Detect automatically';
  @override
  String get transcriptionModelsTitle => 'Transcription models';
  @override
  String transcriptionModelsUsed(String size) => '$size used';
  @override
  String get transcriptionModelsInstalled => 'Downloaded';
  @override
  String get transcriptionModelsDownloading => 'Downloading';
  @override
  String get transcriptionModelsAvailable => 'Available';
  @override
  String get transcriptionModelsFooter =>
      "Models stay in the app's storage on this device. They are not copied "
      'into the library or synced.';
  @override
  String get transcriptionModelDefault => 'Default';
  @override
  String get transcriptionModelSlow => 'Slow';
  @override
  String get transcriptionModelHintTiny => 'Fastest, least accurate';
  @override
  String get transcriptionModelHintBase => 'Good balance of speed and accuracy';
  @override
  String get transcriptionModelHintSmall => 'More accurate, about 3× slower';
  @override
  String get transcriptionModelHintMedium => 'Very accurate, slow on a phone';
  @override
  String get transcriptionModelHintLarge =>
      'Most accurate, needs a lot of memory';
  @override
  String get transcriptionModelDownload => 'Download';
  @override
  String transcriptionModelDeleteTitle(String model) =>
      'Delete the $model model?';
  @override
  String transcriptionModelDeleteBody(String size) =>
      'This frees $size. You can download the model again later.';
  @override
  String get transcriptionModelFailed =>
      'Download failed. Check the connection and try again.';
  @override
  String get actionRetry => 'Retry';
  @override
  String get decimalSeparator => '.';
  @override
  String get transcriptionModelRetrying => 'Connection lost, trying again…';
  @override
  String transcriptionModelInterrupted(String progress) =>
      'Paused at $progress';
  @override
  String get actionResume => 'Resume';
  @override
  String get audioTranscribe => 'Transcribe';
  @override
  String get audioTranscribeUnsupported => 'Only WAV recordings on this device';
  @override
  String get transcriptionQueued => 'Queued';
  @override
  String get transcriptionPreparing => 'Preparing the audio…';
  @override
  String transcriptionRunning(int percent) => 'Transcribing… $percent%';
  @override
  String transcriptionWaitingForModel(String model, int percent) =>
      'Downloading $model · $percent%';
  @override
  String get transcriptionSaved => 'Transcription added to the description';
  @override
  String get transcriptionNoSpeech => 'No speech recognized in this recording';
  @override
  String get transcriptionFailed => 'Transcription failed';
  @override
  String get transcriptionPickModelTitle => 'Choose a model';
  @override
  String get transcriptionPickModelBody =>
      'Transcription runs on this device and the recording is never uploaded. '
      'The model is downloaded once.';
  @override
  String get transcriptionPickModelAction => 'Download and transcribe';
  @override
  String get transcriptionModelRecommended => 'Recommended';
  @override
  String get transcriptionExistingTitle =>
      'This recording already has a description';
  @override
  String get transcriptionExistingBody =>
      'Put the transcription in its place, or add it below?';
  @override
  String get transcriptionAppend => 'Add below';
  @override
  String get transcriptionReplace => 'Replace';
  @override
  String get settingsSectionSync => 'Sync';
  @override
  String get syncWebDavTitle => 'WebDAV';
  @override
  String get syncNotConfigured => 'Not set up for this library';
  @override
  String get syncNeverSynced => 'Never synced';
  @override
  String syncLastSynced(String when) => 'Synced $when';
  @override
  String get syncRunning => 'Syncing…';
  @override
  String syncScreenSubtitle(String library) => 'Library $library';
  @override
  String get syncUrlLabel => 'Folder address';
  @override
  String get syncUrlRequired => 'Enter the server address';
  @override
  String get syncUrlHint =>
      'The folder must exist. Copy the address as the server '
      'shows it.';
  @override
  String get syncHttpWarning =>
      'Unencrypted connection: fine over a VPN or on your local '
      'network.';
  @override
  String get syncUserLabel => 'User';
  @override
  String get syncUserHint =>
      'Leave empty if the server asks for no credentials.';
  @override
  String get syncPasswordLabel => 'Password';
  @override
  String get syncPasswordHint =>
      "Kept in this device's keychain, never in the library "
      'files.';
  @override
  String get syncPasswordKeepHint => 'Leave empty to keep the saved password.';
  @override
  String get syncShowPassword => 'Show password';
  @override
  String get syncHidePassword => 'Hide password';
  @override
  String get syncTestAction => 'Test connection';
  @override
  String get syncTesting => 'Testing…';
  @override
  String get syncRetargetWarning =>
      'A new address or user makes the next sync start over as a '
      'first sync.';
  @override
  String get syncTestOk => 'Connection works';
  @override
  String get syncModeFull => 'Full mode';
  @override
  String get syncModeCompatible => 'Compatible mode';
  @override
  String syncTestOkSubtitle(String mode, int ms) => '$mode · $ms ms';
  @override
  String get syncCapBasic => 'Read, write and delete';
  @override
  String get syncCapEtags => 'File fingerprints (ETags)';
  @override
  String get syncCapNoEtags => 'No file fingerprints (ETags)';
  @override
  String get syncCapNoEtagsDetail =>
      'Compares size and date; downloads again when in doubt';
  @override
  String get syncCapGuarded => 'Protected writes';
  @override
  String get syncCapUnguarded => 'Unprotected writes';
  @override
  String get syncCapUnguardedDetail =>
      'Checks the file on the server right before writing';
  @override
  String get syncCapMove => 'Renames without uploading again';
  @override
  String get syncCapNoMove => 'No renames on the server';
  @override
  String get syncCapNoMoveDetail =>
      'A rename becomes a delete and a new upload';
  @override
  String get syncCompatibleNote =>
      'In compatible mode sync works the same, with a few more '
      'requests.';
  @override
  String get syncTestInvalidUrl => 'Not a valid address';
  @override
  String get syncTestInvalidUrlHint =>
      'Enter an http:// or https:// address, without user or '
      'password in it.';
  @override
  String get syncTestOffline => 'Server not reachable';
  @override
  String get syncTestOfflineHint =>
      'Is the VPN on? A 10.x or 192.168.x address only works '
      'from the same network.';
  @override
  String get syncTestAuth => 'User or password rejected';
  @override
  String get syncTestAuthHint => 'Check them, then test again.';
  @override
  String get syncTestNotFound => 'The folder does not exist';
  @override
  String get syncTestNotFoundHint =>
      'Create it on the server or fix the address.';
  @override
  String get syncTestUnsupported => 'Not a WebDAV folder';
  @override
  String get syncTestUnsupportedHint =>
      'The server answers, but not as WebDAV.';
  @override
  String get syncTestFailed => 'The test did not work';
  @override
  String get syncNowAction => 'Sync now';
  @override
  String get syncSectionServer => 'Server';
  @override
  String get syncServerRow => 'Address, user and password';
  @override
  String get syncRetestTitle => 'Test the server again';
  @override
  String syncProbedAgo(String when) => 'Last test $when';
  @override
  String get syncDisconnectTitle => 'Disconnect this library';
  @override
  String get syncDisconnectSubtitle => 'Files stay here and on the server';
  @override
  String get syncDisconnectConfirmTitle => 'Disconnect sync?';
  @override
  String get syncDisconnectConfirmBody =>
      'This library stops syncing on this device. No file is '
      'deleted, here or on the server. If you connect it again, '
      'the first sync starts over.';
  @override
  String get syncDisconnectConfirm => 'Disconnect';
  @override
  String get syncFirstTitle => 'First sync';
  @override
  String get syncFirstIntro =>
      'I compared the library with the folder on the server:';
  @override
  String get syncFirstUpload => 'To upload';
  @override
  String get syncFirstDownload => 'To download';
  @override
  String get syncFirstBoth => 'On both sides';
  @override
  String get syncFirstBothHint =>
      'Identical: no transfer. Different: to resolve';
  @override
  String get syncFirstNoDelete =>
      'The first sync deletes nothing, here or on the server.';
  @override
  String get syncStartAction => 'Start';
  @override
  String syncMassTrashTitle(int count) => 'Move $count files to the trash?';
  @override
  String syncMassTrashBody(int count, int total) =>
      '$count of the $total synced files are missing on the '
      'server. That usually means a wrong address, an unmounted '
      'NAS disk or a folder emptied by mistake.';
  @override
  String get syncMassTrashHint =>
      'If you really deleted them on another device, confirm: '
      'here they go to the trash.';
  @override
  String get syncMassTrashConfirm => 'Move to trash';
  @override
  String syncMassDeleteTitle(int count) =>
      'Delete $count files from the server?';
  @override
  String syncMassDeleteBody(int count, int total) =>
      '$count of the $total synced files are missing here. If '
      'you did not delete them, cancel and check the library '
      'folder.';
  @override
  String get syncMassDeleteConfirm => 'Delete from server';
  @override
  String get syncTooltip => 'Sync';
  @override
  String get syncStageConnecting => 'Connecting to the server…';
  @override
  String get syncStageComparing => 'Comparing with the server…';
  @override
  String syncStageApplying(int done, int total) => 'Syncing · $done of $total';
  @override
  String get syncStatusWarnings => 'Synced with warnings';
  @override
  String syncConflictsHeader(int count) =>
      'Changed here and on the server · $count';
  @override
  String get syncConflictHint => 'Neither version was touched';
  @override
  String get syncResolveAction => 'Resolve';
  @override
  String syncFailuresHeader(int count) => 'Not synced · $count';
  @override
  String get syncFailuresHint => 'Tried again at the next sync';
  @override
  String get syncAbortAuth => 'Password rejected by the server';
  @override
  String get syncAbortMissingPassword => 'No password saved';
  @override
  String get syncAbortOffline => 'Server not reachable';
  @override
  String get syncAbortRemoteMissing => 'The folder on the server is gone';
  @override
  String get syncAbortUnsupported => 'The server no longer works as WebDAV';
  @override
  String get syncAbortFailed => 'Sync did not work';
  @override
  String get syncAbortNotConfirmed => 'Sync cancelled';
  @override
  String get syncAbortNothingTouched =>
      'No file was touched. Your changes stay here until the '
      'next successful sync.';
  @override
  String syncLastSuccess(String when) => 'Last successful sync $when';
  @override
  String get syncNoSuccessYet => 'No successful sync yet';
  @override
  String get syncUpdatePasswordAction => 'Update password';
  @override
  String get syncRetryAction => 'Try again';
  @override
  String get syncOpenSettingsAction => 'Settings';
  @override
  String get syncCloseAction => 'Close';
  @override
  String get syncDoneSnack => 'Synced';
  @override
  String syncTrashedSnack(int count) => count == 1
      ? 'Synced · 1 file deleted elsewhere is in the trash'
      : 'Synced · $count files deleted elsewhere are in the trash';
  @override
  String syncConflictsSnack(int count) => count == 1
      ? 'Synced · 1 conflict to resolve'
      : 'Synced · $count conflicts to resolve';
  @override
  String get syncShowAction => 'Show';
  @override
  String get syncConflictTitle => 'Resolve conflict';
  @override
  String get syncConflictLegend =>
      "Lines marked − are the server's, lines marked + are this "
      "device's.";
  @override
  String get syncConflictBinary =>
      'Not a text file: choose which copy to keep.';
  @override
  String get syncConflictKeepNote =>
      'The copy you do not keep stays in the note history.';
  @override
  String get syncKeepLocal => "Keep this device's";
  @override
  String get syncKeepRemote => "Keep the server's";
  @override
  String get syncConflictIdentical => 'The two versions are identical';
  @override
  String get syncConflictLoadFailed => 'Could not read both versions';
  @override
  String get syncResolveFailed => 'Could not resolve the conflict';
  @override
  String get syncResolved => 'Conflict resolved';
  @override
  String get syncSectionWhen => 'When to sync';
  @override
  String get syncAutoTitle => 'Automatically';
  @override
  String get syncAutoSubtitle => 'After edits, on opening and at intervals';
  @override
  String get syncIntervalTitle => 'Check the server every';
  @override
  String get syncIntervalSubtitle => 'Only while the app is open';
  @override
  String get syncIntervalDialogBody =>
      'To see changes made on other devices while the app is open. '
      'With “Never”, only after edits and on opening.';
  @override
  String syncIntervalMinutes(int count) =>
      count == 1 ? '1 minute' : '$count minutes';
  @override
  String get syncIntervalNever => 'Never';
  @override
  String get syncWifiOnlyTitle => 'Wi-Fi only';
  @override
  String get syncWifiOnlySubtitle => 'On mobile data, sync only by hand';
  @override
  String syncPendingChanges(int count) =>
      count == 1 ? '1 change waiting' : '$count changes waiting';
  @override
  String syncRetryIn(String wait) => 'retrying in $wait';
  @override
  String syncWaitSeconds(int seconds) => '$seconds s';
  @override
  String syncWaitMinutes(int minutes) => '$minutes min';
  @override
  String get syncWaitingForWifi => 'Waiting for Wi-Fi';
  @override
  String get syncWaitingForNetwork => 'Waiting for a connection';
  @override
  String get syncMobileDataHint => '“Sync now” still uses mobile data.';
  @override
  String get syncQueueKeptHint =>
      'Changes stay here, even if you close the app, and go out by '
      'themselves when the server answers.';
  @override
  String get syncAutoPaused => 'Automatic sync paused';
  @override
  String get syncPausedAuthHint =>
      'It resumes when you update the password or sync by hand.';
  @override
  String get syncPausedServerHint =>
      'It resumes when you fix the address or sync by hand.';
  @override
  String get syncPausedConfirmHint =>
      '“Sync now” shows what would be removed and asks first.';
  @override
  String get syncNeedsConfirmation => 'Waiting for your confirmation';
  @override
  String get syncMergeIntro =>
      'Edits that do not overlap are already merged; choose what to keep '
      'where they do.';
  @override
  String get syncMergeClean =>
      'The two versions merge on their own: nothing overlaps.';
  @override
  String get syncMergeNoBase =>
      'No shared version to merge on, so the whole file has to be chosen.';
  @override
  String syncMergeOverlap(int index, int total) => 'Overlap $index of $total';
  @override
  String get syncMergeFromLocal => 'From this device';
  @override
  String get syncMergeFromRemote => 'From the server';
  @override
  String get syncMergeRemovedLines => 'Lines removed';
  @override
  String get syncMergeKeepLocal => 'Mine';
  @override
  String get syncMergeKeepRemote => 'Theirs';
  @override
  String get syncMergeKeepBoth => 'Both';
  @override
  String get syncMergeSave => 'Save the merge';
  @override
  String get syncMergeKeepWhole => 'Or keep one whole copy';
}
