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
  String get debugLogsTitle => 'Debug logs';
  @override
  String get debugLogsSubtitle => 'Record app events in an in-memory buffer';
  @override
  String get lineNumbersTitle => 'Line numbers';
  @override
  String get lineNumbersSubtitle =>
      'Show the row-number column in the note editor';
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
  String get settingsPreviewEnabledTitle => 'Preview';
  @override
  String get settingsPreviewEnabledSubtitle =>
      'Show the rendered note beside the source editor';
  @override
  String get switchToWysiwygTooltip => 'Switch to the WYSIWYG editor';
  @override
  String get switchToSourceTooltip => 'Switch to the Markdown source';
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
  String get newFolderTitle => 'New folder';
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
}
