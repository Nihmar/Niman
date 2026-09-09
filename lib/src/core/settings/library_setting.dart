/// A setting a library may override (T-ML-10).
///
/// Every one of these has an app-wide value that holds for each library
/// that says nothing about it. A library that does say something keeps
/// its answer in its own `settings.json`, under `overrides`, keyed by the
/// enum's name — so a user with one library never meets the mechanism,
/// and a user with five does not set the toolbar five times.
///
/// What is not here is deliberate. `language` is about the reader, not
/// the library, and `debugLogsEnabled` is a diagnostic switch for the
/// installation. The trash toggle, the history depth, the quick note and
/// the list folder are not here either: they are plain per-library
/// values with no app-wide meaning to fall back to.
enum LibrarySetting {
  /// The editor's row-number column.
  lineNumbers,

  /// Whether opening a note raises the keyboard.
  editorAutofocus,

  /// Whether a reminder's text keeps its `+project`/`@context`/`#tag`.
  reminderShowTokens,

  /// The preview layout: auto, side by side, or full screen.
  previewMode,

  /// The editor's share of the split.
  splitRatio,

  /// The tree's sort order.
  treeSort,

  /// What the editor's link button inserts.
  linkType,

  /// Spaces added per indent level.
  indentWidth,

  /// The arranged editor toolbar.
  editorToolbar;

  /// The setting with this `settings.json` key, or null when the key is
  /// one this build does not know.
  static LibrarySetting? fromId(String? id) {
    for (final setting in values) {
      if (setting.name == id) return setting;
    }
    return null;
  }
}
