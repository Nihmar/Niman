import 'package:flutter/foundation.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/week_start.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/library/new_item_folder.dart';

/// The settings a library keeps for itself (#1258), in its
/// `.niman/settings.json`: the features it offers, its editor, its tree,
/// its links, its text sizes and the rest of Settings' per-library rows.
///
/// Reached through `LibrarySession.librarySettings`. While no library is
/// open the reads answer the shipped defaults and the writes do nothing.
/// A new per-library setting is added here, and nowhere on the session.
abstract interface class LibraryPreferences {
  /// The open library's features (#1109), every one on while none is open.
  ///
  /// Changes after the settings file is read, a switch is changed, and a
  /// sync brings another device's: every surface that offers a feature
  /// rebuilds from it and keeps no boolean of its own.
  ValueListenable<Features> get features;

  /// Sets (and persists) the library's [features] (#1109), the switches of
  /// Settings → Features. [features] follows at once; the files stay as
  /// they are — off is inert.
  Future<void> setFeatures(Features features);

  /// The introduction Settings → Features has still to show for the open
  /// library (#1109): [FeaturesIntroduction.none] once the library's
  /// `featuresReviewed` is set, otherwise the card of a library being
  /// created or of one that existed before the switches did.
  Future<FeaturesIntroduction> get featuresIntroduction;

  /// Records that the introduction was seen (#1109): `featuresReviewed`,
  /// written when the Features screen is left, never when it opens.
  Future<void> markFeaturesReviewed();

  /// Whether the note editor shows the row-number column (default true).
  Future<bool> get lineNumbersEnabled;

  /// Sets (and persists) the editor line-numbers toggle.
  Future<void> setLineNumbersEnabled({required bool enabled});

  /// Whether a note keeps to a centred column (default true, #171).
  Future<bool> get readableLineLength;

  /// Sets (and persists) the readable-line-length toggle.
  Future<void> setReadableLineLength({required bool enabled});

  /// Whether the line being written keeps to the middle of the editor
  /// (typewriter mode, #70; default false).
  Future<bool> get typewriter;

  /// Sets (and persists) typewriter mode.
  Future<void> setTypewriter({required bool enabled});

  /// Whether ticking a checklist item also ticks the tasks nested under it
  /// (default false, #326).
  Future<bool> get cascadeChecklist;

  /// Sets (and persists) the cascade-checklist toggle.
  Future<void> setCascadeChecklist({required bool enabled});

  /// Whether hovering a link previews the note it points at (default true,
  /// #846).
  Future<bool> get linkPreview;

  /// Sets (and persists) the link-preview toggle.
  Future<void> setLinkPreview({required bool enabled});

  /// Whether a note's leading frontmatter is drawn as the properties panel
  /// above it (default true, #157).
  Future<bool> get frontmatterPanel;

  /// Sets (and persists) the properties panel's visibility.
  Future<void> setFrontmatterPanel({required bool enabled});

  /// The note column's text width, in logical pixels.
  Future<double> get noteColumnWidth;

  /// Sets (and persists) the note column's width, clamped to its range.
  Future<void> setNoteColumnWidth(double width);

  /// Whether the note editor focuses (shows the keyboard) when a note
  /// opens (default false).
  Future<bool> get editorAutofocusEnabled;

  /// Sets (and persists) the keyboard-on-open toggle.
  Future<void> setEditorAutofocusEnabled({required bool enabled});

  /// Whether a reminder's notification text keeps the `+project`,
  /// `@context` and `#tag` markers (default false).
  Future<bool> get reminderShowTokens;

  /// Sets (and persists) the reminder-markers toggle.
  Future<void> setReminderShowTokens({required bool enabled});

  /// Whether a note edited and then closed has its Markdown tidied, as
  /// the "Tidy the Markdown" command does (default true).
  Future<bool> get tidyOnClose;

  /// Sets (and persists) the tidy-on-close toggle.
  Future<void> setTidyOnClose({required bool enabled});

  /// The #72 rules turned off, by id (`LintRule.id`); the rest run when a
  /// note is tidied. Empty — the default — means every rule runs.
  Future<Set<String>> get lintRulesOff;

  /// Sets (and persists) the rules turned off.
  Future<void> setLintRulesOff(Set<String> ids);

  /// The hunspell dictionaries the spell checker uses (`<name>`s found
  /// on the machine), in selection order; empty means the locale default.
  Future<List<String>> get spellDictionaries;

  /// Sets (and persists) the spell-check dictionaries; an empty list
  /// restores the locale default.
  Future<void> setSpellDictionaries(List<String> names);

  /// Which editor the library writes in (default source).
  Future<EditorKind> get editorKind;

  /// Sets (and persists) the editor kind.
  Future<void> setEditorKind(EditorKind kind);

  /// Which editors the library offers (default both).
  Future<Set<EditorKind>> get enabledEditors;

  /// Sets (and persists) the enabled editors; an empty set is ignored —
  /// the library must never resolve to no editor.
  Future<void> setEnabledEditors(Set<EditorKind> editors);

  /// The library tree sort order (default [TreeSort.nameAsc]).
  Future<TreeSort> get treeSort;

  /// Sets (and persists) the library tree sort order.
  Future<void> setTreeSort(TreeSort sort);

  /// The todo sections folded on this device, by section id (default
  /// Done only, #1003).
  Future<Set<String>> get todoCollapsedSections;

  /// Sets (and persists) the folded todo sections on this device.
  Future<void> setTodoCollapsedSections(Set<String> ids);

  /// How the Files pane shows a folder on this device (default
  /// [TreeView.list], #727).
  Future<TreeView> get treeView;

  /// Sets (and persists) the Files pane's view on this device.
  Future<void> setTreeView(TreeView view);

  /// The tree pane's width in logical pixels (default
  /// [defaultTreeWidth]).
  Future<double> get treeWidth;

  /// Sets (and persists) the tree pane's width.
  Future<void> setTreeWidth(double width);

  /// The right dock's width in logical pixels (default
  /// [defaultDockWidth]).
  Future<double> get dockWidth;

  /// Sets (and persists) the right dock's width.
  Future<void> setDockWidth(double width);

  /// Whether the tree's pinned section is rolled up (default false).
  ///
  /// Per library, like the sort order: which notes are worth pinning — and
  /// how many — is a property of the library, not of the app.
  Future<bool> get pinnedCollapsed;

  /// Sets (and persists) the pinned section's rolled-up state.
  Future<void> setPinnedCollapsed({required bool collapsed});

  /// The link format the editor's link button inserts
  /// (default [LinkType.wikilink]).
  Future<LinkType> get linkType;

  /// Sets (and persists) the link format.
  Future<void> setLinkType(LinkType type);

  /// What a rename or a move does to the links pointing at what moved
  /// (default [LinkUpdate.automatic], #848).
  Future<LinkUpdate> get linkUpdate;

  /// Sets (and persists) what a rename or a move does to those links.
  Future<void> setLinkUpdate(LinkUpdate mode);

  /// Where a note created from a dead link lands (default the folder of
  /// the note the link was clicked in, issue #78).
  Future<NewItemLocation> get newItemLocation;

  /// Sets (and persists) the dead-link note location.
  Future<void> setNewItemLocation(NewItemLocation location);

  /// The editor's indent/outdent width in spaces (default 2).
  Future<int> get indentWidth;

  /// Sets (and persists) the indent/outdent width.
  Future<void> setIndentWidth(int width);

  /// The new flashcards each deck shows per day (default 20, 0 = none,
  /// #533).
  Future<int> get newCardsPerDay;

  /// Sets (and persists) the new flashcards per deck per day, into range.
  Future<void> setNewCardsPerDay(int count);

  /// How many days an item waits in `.trash/` before the automatic empty
  /// deletes it for good (default 0 = never).
  Future<int> get trashAutoEmptyDays;

  /// Sets (and persists) the automatic-empty wait; anything outside
  /// 1..3650 reads back as never.
  Future<void> setTrashAutoEmptyDays(int days);

  /// How many versions of each note `.history/` keeps (default 10, 0 =
  /// none).
  Future<int> get historyVersions;

  /// Sets (and persists) the kept versions; out of 0..100 reads back as
  /// the default.
  Future<void> setHistoryVersions(int versions);

  /// The least minutes between two versions kept while editing (default
  /// 5).
  Future<int> get historyIntervalMinutes;

  /// Sets (and persists) the history interval; out of 1..60 reads back as
  /// the default.
  Future<void> setHistoryIntervalMinutes(int minutes);

  /// The stored editor-toolbar layout (empty = the shipped toolbar);
  /// `ToolbarLayout.parse` turns it into the toolbar.
  Future<String> get editorToolbar;

  /// Sets (and persists) the editor-toolbar layout.
  Future<void> setEditorToolbar(String layout);

  /// The interface text size, as a multiplier of the shipped one
  /// (default 1.0). Applied by the app root, which also multiplies the
  /// platform's own scale.
  Future<double> get uiTextScale;

  /// Sets (and persists) the interface text size.
  Future<void> setUiTextScale(double scale);

  /// The note text size, as a multiplier of the shipped one (default
  /// 1.0). It reaches the source editor as a font size and the preview as
  /// a text scale, and the two have to agree.
  Future<double> get noteTextScale;

  /// Sets (and persists) the note text size.
  Future<void> setNoteTextScale(double scale);

  /// The day the library's calendars start the week on (default the
  /// system's, #566).
  Future<WeekStart> get weekStart;

  /// Sets (and persists) the first day of the week.
  Future<void> setWeekStart(WeekStart start);

  /// The face the source editor is set in
  /// (default [defaultSourceFont], issue #259). Only the source pane's own
  /// style follows it; the read view and `live` keep the note's face.
  Future<SourceFont> get sourceFont;

  /// Sets (and persists) the source editor's face.
  Future<void> setSourceFont(SourceFont font);

  /// How the library's books look (#280): their theme, brightness, font
  /// and text size.
  Future<EpubLook> get epubLook;

  /// Sets (and persists) how the books look, and puts it on screen.
  Future<void> setEpubLook(EpubLook look);
}
