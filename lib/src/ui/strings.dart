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
  static const String trashSubtitle = 'Deletions move to .trash/ (off = hard delete)';
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

  // Preview switch (phone mode).
  static const String showPreviewTooltip = 'Show preview';
  static const String showEditorTooltip = 'Show editor';
}
