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
}
