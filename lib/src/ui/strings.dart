/// The single file for UI strings — every user-visible label lives here
/// (and a future translation pass only touches this file).
library;

/// All user-visible app strings.
///
/// One file for every label, so a future translation pass (and any
/// renaming) touches exactly this file. The constants need no per-member
/// docs: their values ARE their documentation.
// ignore_for_file: public_member_api_docs
final class AppStrings {
  const AppStrings._();

  // Settings: editor toggles.
  static const String trashTitle = 'Trash';
  static const String trashSubtitle =
      'Deletions move to .trash/ (off = hard delete)';
  static const String debugLogsTitle = 'Debug logs';
  static const String debugLogsSubtitle =
      'Record app events in an in-memory buffer';
  static const String lineNumbersTitle = 'Line numbers';
  static const String lineNumbersSubtitle =
      'Show the row-number column in the note editor';
  static const String keyboardOnOpenTitle = 'Keyboard on open';
  static const String keyboardOnOpenSubtitle =
      'Show the keyboard as soon as a note opens (off = on first tap)';

  // Settings: preview mode.
  static const String previewModeTitle = 'Preview mode';
  static const String previewModeSubtitle =
      'How the preview sits next to the editor (auto = by width)';
  static const String previewModeAuto = 'Auto';
  static const String previewModeSplit = 'Side by side';
  static const String previewModeSwitch = 'Full screen';
  static const String splitRatioTitle = 'Split width';
  static const String splitRatioSubtitle =
      'The editor’s share when the preview is side by side';

  // Editor status bar.
  static const String outlineTooltip = 'Outline';
  static const String outlineNoHeadings = 'No headings';
  static const String outlineNoTitle = '(no title)';
  static const String insertImageTooltip = 'Insert image';

  // Preview switch (phone mode).
  static const String showPreviewTooltip = 'Show preview';
  static const String showEditorTooltip = 'Show editor';

  // Raw-HTML table fallback.
  static const String htmlTableFallback = '(raw HTML table)';

  // Search (T-M3-05).
  static const String searchHint = 'Search notes';
  static const String searchModeWords = 'Words';
  static const String searchModeContains = 'Contains';
  static const String searchEmptyHint = 'Type to search the library';
  static const String searchTooShortHint = 'Type at least 2 characters';
  static const String searchNoMatches = 'No matches';
  static const String searchLoadMore = 'Show more';

  // Replace (T-M3-10): the search screen's optional exact-word replace.
  static const String replaceTooltip = 'Replace…';
  static const String replaceInNoteAction = 'Replace in this note…';
  static const String replaceInThisNote = 'Replace in this note';
  static const String replaceWithLabel = 'Replace with';
  static const String replaceCaseSensitive = 'Case-sensitive';
  static const String replaceWholeWordsHint =
      'only exact whole-word matches are replaced';
  static const String replaceConfirm = 'Replace';
  static const String replaceCancel = 'Close';
  static const String replaceUnavailable = 'Replace is unavailable right now';

  // Editor find & replace (the classic in-note bar, re_editor's find
  // controller + CopistFindPanel).
  static const String findInNoteTooltip = 'Find in note';
  static const String editorFindHint = 'Find';
  static const String editorReplaceHint = 'Replace';
  static const String editorFindCaseTooltip = 'Match case';
  static const String editorFindPreviousTooltip = 'Previous match';
  static const String editorFindNextTooltip = 'Next match';
  static const String editorFindCloseTooltip = 'Close find';
  static const String editorFindReplaceModeTooltip = 'Replace mode';
  static const String editorReplaceOneTooltip = 'Replace this match';
  static const String editorReplaceAllTooltip = 'Replace all matches';

  // Tags (T-M3-06).
  static const String openTagsTooltip = 'Tags';
  static const String tagsTitle = 'Tags';
  static const String tagsEmpty =
      'No tags yet — add a #tag or frontmatter tags';
  static const String tagsBackTooltip = 'Back to search';
  static const String tagsNotesEmpty = 'No notes with this tag';

  // Link navigation (T-M3-07).
  static const String unresolvedLinkTitle = 'Link not found';
  static const String headingNotFoundTitle = 'Heading not found';
  static const String ambiguousLinkTitle = 'Several notes match';
  static const String openLinkFailed = 'Could not open link';
  static const String chooseNote = 'Choose a note';

  // Task lists (T-TD-04).
  static const String todoOpen = 'Open';
  static const String todoDone = 'Done';
  static const String todoEmptyOpen = 'No open tasks yet';
  static const String todoEmptyDone = 'Nothing completed yet';
  static const String todoEmptyFiltered = 'No tasks match';
  static const String todoAddTooltip = 'Add task';
  static const String todoAddTitle = 'Add task';
  static const String todoEditTitle = 'Edit task';
  static const String todoDescriptionHint = 'Description';
  static const String todoCancel = 'Cancel';
  static const String todoSave = 'Save';
  static const String todoEditAction = 'Edit';
  static const String todoDeleteAction = 'Delete';
  static const String todoHasReminder = 'Has reminder';

  // Task filters (T-TD-05).
  static const String todoDueAll = 'All';
  static const String todoDueOverdue = 'Overdue';
  static const String todoDueToday = 'Today';
  static const String todoDueNext7 = 'Next 7 days';
  static const String todoDueNoDate = 'No date';
  static const String todoSortTooltip = 'Sort';
  static const String todoSortDue = 'Due date';
  static const String todoSortPriority = 'Priority';
  static const String todoSortCreation = 'Creation date';

  // Task dialog pickers (T-TD-06).
  static const String todoNoPriority = 'No priority';
  static const String todoNoDueDate = 'No due date';
  static const String todoNoReminder = 'No reminder';
  static const String todoAddProject = '+ Project';
  static const String todoAddContext = '@ Context';
  static const String todoAddHashtag = '# Tag';

  // Task reminders (T-TD-07).
  static const String todoReminderChannel = 'Task reminders';
  static const String todoReminderChannelDescription =
      'Scheduled alerts for tasks with a reminder time.';
  static const String todoReminderBody = 'Todo reminder';
  static const String todoReminderFallbackTitle = 'Task reminder';
  static const String todoReminderBlocked =
      'Notifications are off, so reminders will not appear.';
  static const String todoReminderBattery =
      'Battery optimization is on for Copist. The system may sleep the '
      'app and drop pending reminders.';
  static const String todoReminderInexact =
      'This device does not allow exact alarms, so a reminder can arrive '
      'several minutes late with the screen off.';
  static const String todoReminderFixAction = 'Open settings';
  static const String todoReminderDismissAction = 'Dismiss';
  static const String todoReminderDue = 'Due';
}
