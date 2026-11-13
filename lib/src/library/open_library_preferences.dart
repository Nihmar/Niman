import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/features_introduction.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/core/week_start.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/library/library_preferences.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/library/open_library_settings.dart';

/// The [LibraryPreferences] of the open library, read from and written to
/// its `.niman/settings.json` through [OpenLibrarySettings]: the shipped
/// defaults while none is open, and a no-op write.
///
/// What a setting puts on screen goes with the write: the text sizes, the
/// first day of the week and the books' look.
final class OpenLibraryPreferences implements LibraryPreferences {
  /// Settings kept in [_settings]; [_publishEpubLook] puts a books' look
  /// on screen once it is written.
  new(this._settings, this._publishEpubLook);

  final OpenLibrarySettings _settings;
  final Future<void> Function(EpubLook) _publishEpubLook;

  static const _log = AppLogger(name: 'session');

  @override
  ValueListenable<Features> get features => _settings.features;

  /// Whether the note editor shows the row-number column.
  @override
  Future<bool> get lineNumbersEnabled async =>
      (await _settings.config).lineNumbers;

  /// Sets (and persists) the editor line-numbers toggle.
  @override
  Future<void> setLineNumbersEnabled({required bool enabled}) async {
    _log.info('editor line numbers set to $enabled');
    await _settings.edit((c) => c.copyWith(lineNumbers: enabled));
  }

  @override
  Future<bool> get readableLineLength async =>
      (await _settings.config).readableLineLength;

  @override
  Future<void> setReadableLineLength({required bool enabled}) async {
    _log.info('readable line length set to $enabled');
    await _settings.edit((c) => c.copyWith(readableLineLength: enabled));
  }

  @override
  Future<bool> get typewriter async => (await _settings.config).typewriter;

  @override
  Future<void> setTypewriter({required bool enabled}) async {
    _log.info('typewriter mode set to $enabled');
    await _settings.edit((c) => c.copyWith(typewriter: enabled));
  }

  @override
  Future<bool> get cascadeChecklist async =>
      (await _settings.config).cascadeChecklist;

  @override
  Future<void> setCascadeChecklist({required bool enabled}) async {
    _log.info('cascade checklist set to $enabled');
    await _settings.edit((c) => c.copyWith(cascadeChecklist: enabled));
  }

  @override
  Future<bool> get linkPreview async => (await _settings.config).linkPreview;

  @override
  Future<void> setLinkPreview({required bool enabled}) async {
    _log.info('link preview set to $enabled');
    await _settings.edit((c) => c.copyWith(linkPreview: enabled));
  }

  @override
  Future<bool> get frontmatterPanel async =>
      (await _settings.config).frontmatterPanel;

  @override
  Future<void> setFrontmatterPanel({required bool enabled}) async {
    _log.info('frontmatter panel set to $enabled');
    await _settings.edit((c) => c.copyWith(frontmatterPanel: enabled));
  }

  @override
  Future<double> get noteColumnWidth async =>
      (await _settings.config).noteColumnWidth;

  @override
  Future<void> setNoteColumnWidth(double width) async {
    _log.info('note column width set to $width');
    await _settings.edit(
      (c) => c.copyWith(noteColumnWidth: normalizeNoteColumnWidth(width)),
    );
  }

  /// Whether the note editor focuses (shows the keyboard) on note open.
  @override
  Future<bool> get editorAutofocusEnabled async =>
      (await _settings.config).editorAutofocus;

  /// Sets (and persists) the keyboard-on-open toggle.
  @override
  Future<void> setEditorAutofocusEnabled({required bool enabled}) async {
    _log.info('editor keyboard-on-open set to $enabled');
    await _settings.edit((c) => c.copyWith(editorAutofocus: enabled));
  }

  /// Whether reminder text keeps the +project/@context/#tag markers.
  @override
  Future<bool> get reminderShowTokens async =>
      (await _settings.config).reminderShowTokens;

  /// Sets (and persists) the reminder-markers toggle.
  @override
  Future<void> setReminderShowTokens({required bool enabled}) async {
    _log.info('reminder markers set to $enabled');
    await _settings.edit((c) => c.copyWith(reminderShowTokens: enabled));
  }

  /// Whether a note edited and then closed has its Markdown tidied.
  @override
  Future<bool> get tidyOnClose async => (await _settings.config).tidyOnClose;

  /// Sets (and persists) the tidy-on-close toggle.
  @override
  Future<void> setTidyOnClose({required bool enabled}) async {
    _log.info('tidy on close set to $enabled');
    await _settings.edit((c) => c.copyWith(tidyOnClose: enabled));
  }

  /// The #72 rules turned off, by id.
  @override
  Future<Set<String>> get lintRulesOff async =>
      (await _settings.config).lintRulesOff;

  /// Sets (and persists) the rules turned off.
  @override
  Future<void> setLintRulesOff(Set<String> ids) async {
    _log.info('lint rules off set to ${ids.join(', ')}');
    await _settings.edit((c) => c.copyWith(lintRulesOff: ids));
  }

  /// The spell-check dictionary names, in selection order.
  @override
  Future<List<String>> get spellDictionaries async =>
      (await _settings.config).spellDictionaries;

  /// Sets (and persists) the spell-check dictionaries.
  @override
  Future<void> setSpellDictionaries(List<String> names) async {
    _log.info(
      'spell-check dictionaries set to '
      '${names.isEmpty ? 'system' : names.join(', ')}',
    );
    await _settings.edit((c) => c.copyWith(spellDictionaries: names));
  }

  /// Which editor the library writes in (default source).
  @override
  Future<EditorKind> get editorKind async =>
      (await _settings.config).editorKind;

  /// Sets (and persists) the editor kind.
  @override
  Future<void> setEditorKind(EditorKind kind) async {
    _log.info('editor kind set to ${kind.name}');
    await _settings.edit((c) => c.copyWith(editorKind: kind));
  }

  /// Which editors the library offers (default both).
  @override
  Future<Set<EditorKind>> get enabledEditors async =>
      (await _settings.config).enabledEditors;

  /// Sets (and persists) the enabled editors; an empty set is ignored.
  @override
  Future<void> setEnabledEditors(Set<EditorKind> editors) async {
    if (editors.isEmpty) {
      _log.info('enabled editors: empty set ignored');
      return;
    }
    _log.info('enabled editors set to ${editors.map((e) => e.name).join(',')}');
    await _settings.edit((c) => c.copyWith(enabledEditors: {...editors}));
  }

  /// The library tree sort order.
  @override
  Future<TreeSort> get treeSort async => (await _settings.config).treeSort;

  @override
  Future<void> setFeatures(Features features) =>
      _settings.edit((c) => c.copyWith(features: features));

  @override
  Future<FeaturesIntroduction> get featuresIntroduction =>
      _settings.featuresIntroduction;

  @override
  Future<void> markFeaturesReviewed() =>
      _settings.edit((c) => c.copyWith(featuresReviewed: true));

  /// Sets (and persists) the library tree sort order.
  @override
  Future<void> setTreeSort(TreeSort sort) async {
    await _settings.edit((c) => c.copyWith(treeSort: sort));
  }

  /// The todo sections folded on this device (#1003).
  @override
  Future<Set<String>> get todoCollapsedSections async =>
      (await _settings.config).todoCollapsedSections;

  /// Sets (and persists) the folded todo sections on this device.
  @override
  Future<void> setTodoCollapsedSections(Set<String> ids) async {
    await _settings.edit((c) => c.copyWith(todoCollapsedSections: {...ids}));
  }

  /// How the Files pane shows a folder on this device (#727).
  @override
  Future<TreeView> get treeView async => (await _settings.config).treeView;

  /// Sets (and persists) the Files pane's view.
  @override
  Future<void> setTreeView(TreeView view) async {
    await _settings.edit((c) => c.copyWith(treeView: view));
  }

  /// The tree pane's width in logical pixels.
  @override
  Future<double> get treeWidth async => (await _settings.config).treeWidth;

  /// Sets (and persists) the tree pane's width.
  @override
  Future<void> setTreeWidth(double width) async {
    await _settings.edit((c) => c.copyWith(treeWidth: width));
  }

  /// The right dock's width in logical pixels.
  @override
  Future<double> get dockWidth async => (await _settings.config).dockWidth;

  /// Sets (and persists) the right dock's width.
  @override
  Future<void> setDockWidth(double width) async {
    await _settings.edit((c) => c.copyWith(dockWidth: width));
  }

  /// Whether the tree's pinned section is rolled up.
  @override
  Future<bool> get pinnedCollapsed async =>
      (await _settings.config).pinnedCollapsed;

  /// Sets (and persists) the pinned section's rolled-up state.
  @override
  Future<void> setPinnedCollapsed({required bool collapsed}) async {
    await _settings.edit((c) => c.copyWith(pinnedCollapsed: collapsed));
  }

  /// The link format the editor's link button inserts.
  @override
  Future<LinkType> get linkType async => (await _settings.config).linkType;

  /// Sets (and persists) the link format.
  @override
  Future<void> setLinkType(LinkType type) async {
    _log.info('link type set to ${type.name}');
    await _settings.edit((c) => c.copyWith(linkType: type));
  }

  /// What a rename or a move does to the links pointing at what moved.
  @override
  Future<LinkUpdate> get linkUpdate async =>
      (await _settings.config).linkUpdate;

  /// Sets (and persists) what a rename or a move does to those links.
  @override
  Future<void> setLinkUpdate(LinkUpdate mode) async {
    _log.info('link update set to ${mode.name}');
    await _settings.edit((c) => c.copyWith(linkUpdate: mode));
  }

  /// Where a note created from a dead link lands.
  @override
  Future<NewItemLocation> get newItemLocation async =>
      (await _settings.config).newItemLocation;

  /// Sets (and persists) the dead-link note location.
  @override
  Future<void> setNewItemLocation(NewItemLocation location) async {
    _log.info('missing note location set to ${location.name}');
    await _settings.edit((c) => c.copyWith(newItemLocation: location));
  }

  /// The editor's indent/outdent width in spaces.
  @override
  Future<int> get indentWidth async => (await _settings.config).indentWidth;

  /// Sets (and persists) the indent/outdent width, clamped to its range.
  @override
  Future<void> setIndentWidth(int width) async {
    _log.info('indent width set to $width');
    await _settings.edit(
      (c) => c.copyWith(indentWidth: normalizeIndentWidth(width)),
    );
  }

  /// The new flashcards each deck shows per day (#533).
  @override
  Future<int> get newCardsPerDay async =>
      (await _settings.config).newCardsPerDay;

  /// Sets (and persists) the new flashcards per deck per day, into range.
  @override
  Future<void> setNewCardsPerDay(int count) async {
    _log.info('new cards per day set to $count');
    await _settings.edit(
      (c) => c.copyWith(newCardsPerDay: normalizeNewCardsPerDay(count)),
    );
  }

  @override
  Future<int> get trashAutoEmptyDays async =>
      (await _settings.config).trashAutoEmptyDays;

  @override
  Future<void> setTrashAutoEmptyDays(int days) async {
    _log.info('trash auto-empty set to $days day(s)');
    await _settings.edit(
      (c) => c.copyWith(trashAutoEmptyDays: normalizeTrashAutoEmptyDays(days)),
    );
  }

  @override
  Future<int> get historyVersions async =>
      (await _settings.config).historyVersions;

  @override
  Future<void> setHistoryVersions(int versions) async {
    _log.info('history versions set to $versions');
    await _settings.edit(
      (c) => c.copyWith(historyVersions: normalizeHistoryVersions(versions)),
    );
  }

  @override
  Future<int> get historyIntervalMinutes async =>
      (await _settings.config).historyIntervalMinutes;

  @override
  Future<void> setHistoryIntervalMinutes(int minutes) async {
    _log.info('history interval set to $minutes min');
    await _settings.edit(
      (c) => c.copyWith(
        historyIntervalMinutes: normalizeHistoryIntervalMinutes(minutes),
      ),
    );
  }

  /// The stored editor-toolbar layout (empty = the shipped toolbar).
  @override
  Future<String> get editorToolbar async =>
      (await _settings.config).editorToolbar;

  /// Sets (and persists) the editor-toolbar layout.
  @override
  Future<void> setEditorToolbar(String layout) async {
    _log.info('editor toolbar set to "$layout"');
    await _settings.edit((c) => c.copyWith(editorToolbar: layout));
  }

  /// The interface text size.
  @override
  Future<double> get uiTextScale async => (await _settings.config).uiTextScale;

  /// Sets (and persists) the interface text size, and puts it on screen.
  @override
  Future<void> setUiTextScale(double scale) async {
    final clamped = normalizeTextScale(scale);
    _log.info('interface text scale set to $clamped');
    await _settings.edit((c) => c.copyWith(uiTextScale: clamped));
    AppTextScales.ui = clamped;
  }

  /// The note text size.
  @override
  Future<double> get noteTextScale async =>
      (await _settings.config).noteTextScale;

  /// Sets (and persists) the note text size, and puts it on screen.
  @override
  Future<void> setNoteTextScale(double scale) async {
    final clamped = normalizeTextScale(scale);
    _log.info('note text scale set to $clamped');
    await _settings.edit((c) => c.copyWith(noteTextScale: clamped));
    AppTextScales.note = clamped;
  }

  /// The day the library's calendars start the week on (#566).
  @override
  Future<WeekStart> get weekStart async => (await _settings.config).weekStart;

  /// Sets (and persists) the first day of the week, and puts it on screen.
  @override
  Future<void> setWeekStart(WeekStart start) async {
    _log.info('first day of the week set to ${start.name}');
    await _settings.edit((c) => c.copyWith(weekStart: start));
    AppWeekStart.choice = start;
  }

  /// The source editor's face (issue #259).
  @override
  Future<SourceFont> get sourceFont async =>
      (await _settings.config).sourceFont;

  /// Sets (and persists) the source editor's face.
  @override
  Future<void> setSourceFont(SourceFont font) async {
    _log.info('source editor font set to ${font.name}');
    await _settings.edit((c) => c.copyWith(sourceFont: font));
  }

  /// How the library's books look (#280).
  @override
  Future<EpubLook> get epubLook async => (await _settings.config).epubLook;

  /// Sets (and persists) how the books look, and puts it on screen.
  @override
  Future<void> setEpubLook(EpubLook look) async {
    _log.info(
      'books set to ${look.theme ?? 'the app theme'}, '
      '${look.brightness?.id ?? 'the app brightness'}, '
      '${look.font.name} at ${look.textScale}',
    );
    await _settings.edit((c) => c.copyWith(epubLook: look));
    await _publishEpubLook(look);
  }
}
