import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/device_settings_store.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_config_values.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show
        EditorKind,
        LinkType,
        LinkUpdate,
        SourceFont,
        TreeSort,
        TreeView,
        defaultAnnotationsFolder,
        defaultAttachmentsFolder,
        defaultCaptureFolder,
        defaultHighlightColour,
        defaultListFolder,
        defaultTemplateFolder;
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/core/week_start.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/lint/lint_rule.dart';

export 'package:niman/src/core/settings/library_config_store.dart';
export 'package:niman/src/core/settings/library_config_values.dart';

/// The bool in [raw], or [fallback] when it is anything else.
bool _boolOr(Object? raw, bool fallback) => raw is bool ? raw : fallback;

/// Reads an `enabledEditors` list out of the settings file.
///
/// Unknown names are dropped; an empty or missing list reads back as both
/// editors — the file must never resolve to no editor, and files written
/// before the switch existed offered both.
Set<EditorKind> _enabledEditorsFrom(Object? raw) {
  final kinds = <EditorKind>{};
  if (raw is List) {
    for (final name in raw) {
      for (final kind in EditorKind.values) {
        if (name == kind.name) kinds.add(kind);
      }
    }
  }
  return kinds.isEmpty ? const {EditorKind.source, EditorKind.wysiwyg} : kinds;
}

/// Reads a `todoCollapsedSections` list out of the settings file.
///
/// An absent or malformed value is the default (Done folded); a list is
/// taken as it stands, so an empty one means every section is open. Ids
/// are kept as written, whatever they are: a section a newer build knows
/// is not this build's to drop.
Set<String> _todoCollapsedSectionsFrom(Object? raw) {
  if (raw is! List) return defaultTodoCollapsedSections;
  return <String>{
    for (final id in raw)
      if (id is String && id.isNotEmpty) id,
  };
}

/// Reads a `lintRulesOff` list out of the settings file: the #72 rules
/// this library has turned off, by [LintRule.id].
///
/// The rules *left out* are stored, not the ones on, so a rule added in a
/// later build runs without a migration — and an unknown id (a rule a
/// newer build wrote, or one since removed) is dropped.
Set<String> _lintRulesOffFrom(Object? raw) {
  if (raw is! List) return const <String>{};
  return <String>{
    for (final id in raw)
      if (id is String && LintRule.values.any((rule) => rule.id == id)) id,
  };
}

/// Reads a `spellDictionaries` list out of the settings file.
///
/// Accepts the legacy single `spellDictionary` string as well, so an
/// older library opens with its one dictionary selected. Blank and
/// duplicate names are dropped; the order is the selection order.
List<String> _spellDictionariesFrom(Object? raw) {
  final names = switch (raw) {
    final List<Object?> list => [
      for (final name in list)
        if (name is String) name,
    ],
    final String name => [name],
    _ => const <String>[],
  };
  final clean = <String>[];
  for (final name in names) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || clean.contains(trimmed)) continue;
    clean.add(trimmed);
  }
  return clean;
}

/// The per-library settings, stored in the library folder itself as
/// `<library>/.niman/settings.json` (T-ML-01, T-ML-10).
///
/// A library is a self-describing folder: these settings travel with it,
/// survive a sync, and can be read and fixed in any editor — the same
/// bargain the notes get. Keys this build does not understand are preserved
/// on read and written back untouched, so a newer build's settings survive
/// an older one opening the library.
///
/// One model, two homes. The settings that shape the library — its
/// trash, history, folders, links, indentation, quick note, reminder
/// markers, tidying on close, dictionaries — are written to that file and
/// travel with it. The ones that describe this screen and this person
/// ([deviceKeys]: the tree's width and order, the text scale, the editor
/// and its toggles, the books' look) are kept on the device, per library,
/// by a [DeviceSettingsStore]: a
/// width set on a desktop means nothing on a phone, and every tweak of
/// one used to rewrite the shared file and sync it everywhere. There is
/// no notion of a library "overriding" the app — a library simply has its
/// own answers, seeded from the defaults the first time it is opened.
/// What stays app-wide is what does not depend on the library at all: the
/// language and the debug switch.
@immutable
final class LibraryConfig {
  /// Creates a library config. [extra] holds keys this build does not
  /// understand, preserved verbatim.
  const new({
    required this.trashEnabled,
    required this.historyVersions,
    required this.quickNotePath,
    required this.listNoteFolder,
    this.trashAutoEmptyDays = trashAutoEmptyOff,
    this.historyIntervalMinutes = defaultHistoryIntervalMinutes,
    this.templateFolder = defaultTemplateFolder,
    this.attachmentsFolder = defaultAttachmentsFolder,
    this.annotationsFolder = defaultAnnotationsFolder,
    this.captureFolder = defaultCaptureFolder,
    this.highlightColour = defaultHighlightColour,
    this.pinnedCollapsed = false,
    this.lineNumbers = true,
    this.readableLineLength = true,
    this.typewriter = false,
    this.noteColumnWidth = defaultNoteColumnWidth,
    this.editorAutofocus = false,
    this.reminderShowTokens = false,
    this.tidyOnClose = true,
    this.deleteCarriesNotes = true,
    this.cascadeChecklist = true,
    this.linkPreview = true,
    this.frontmatterPanel = true,
    this.lintRulesOff = const <String>{},
    this.treeSort = TreeSort.nameAsc,
    this.todoCollapsedSections = defaultTodoCollapsedSections,
    this.treeView = TreeView.list,
    this.linkType = LinkType.wikilink,
    this.linkUpdate = LinkUpdate.automatic,
    this.weekStart = WeekStart.system,
    this.newItemLocation = NewItemLocation.openNoteFolder,
    this.indentWidth = defaultIndentWidth,
    this.newCardsPerDay = defaultNewCardsPerDay,
    this.editorToolbar = '',
    this.uiTextScale = defaultTextScale,
    this.noteTextScale = defaultTextScale,
    this.sourceFont = defaultSourceFont,
    this.treeWidth = defaultTreeWidth,
    this.dockWidth = defaultDockWidth,
    this.spellDictionaries = const <String>[],
    this.editorKind = EditorKind.source,
    this.enabledEditors = const {EditorKind.source, EditorKind.wysiwyg},
    this.journal = const JournalSettings(),
    this.epubLook = const EpubLook(),
    this.navigation,
    this.deviceNavigation,
    this.deviceHome,
    this.features = const Features(),
    this.featuresReviewed = false,
    this.extra = const {},
  });

  /// Parses the raw `settings.json` object into a config.
  ///
  /// Wrong-type known keys fall back to their defaults, an out-of-range
  /// `historyVersions` with them, and `listNoteFolder` is sanitized the
  /// way the setter sanitizes it; every other key goes into
  /// [LibraryConfig.extra].
  factory fromJsonMap(Map<String, Object?> json) {
    final extra = <String, Object?>{};
    for (final entry in json.entries) {
      if (!_knownKeys.contains(entry.key)) {
        extra[entry.key] = entry.value;
      }
    }
    final trash = json['trashEnabled'];
    final versions = json['historyVersions'];
    final quick = json['quickNotePath'];
    final folder = json['listNoteFolder'];
    final templates = json['templateFolder'];
    final attachments = json['attachmentsFolder'];
    final annotations = json['annotationsFolder'];
    final captures = json['captureFolder'];
    final highlight = json['highlightColour'];
    return LibraryConfig(
      trashEnabled: switch (trash) {
        final bool enabled => enabled,
        _ => true,
      },
      trashAutoEmptyDays: normalizeTrashAutoEmptyDays(
        json['trashAutoEmptyDays'],
      ),
      historyVersions: normalizeHistoryVersions(versions),
      historyIntervalMinutes: normalizeHistoryIntervalMinutes(
        json['historyIntervalMinutes'],
      ),
      quickNotePath: quick is String ? quick : null,
      listNoteFolder: folder is String
          ? cleanListFolder(folder)
          : defaultListFolder,
      templateFolder: templates is String
          ? cleanTemplateFolder(templates)
          : defaultTemplateFolder,
      attachmentsFolder: attachments is String
          ? cleanAttachmentsFolder(attachments)
          : defaultAttachmentsFolder,
      annotationsFolder: annotations is String
          ? cleanAnnotationsFolder(annotations)
          : defaultAnnotationsFolder,
      captureFolder: captures is String
          ? cleanCaptureFolder(captures)
          : defaultCaptureFolder,
      highlightColour: highlight is String && highlight.trim().isNotEmpty
          ? highlight.trim()
          : defaultHighlightColour,
      pinnedCollapsed: _boolOr(json['pinnedCollapsed'], false),
      lineNumbers: _boolOr(json['lineNumbers'], true),
      readableLineLength: _boolOr(json['readableLineLength'], true),
      typewriter: _boolOr(json['typewriter'], false),
      noteColumnWidth: normalizeNoteColumnWidth(json['noteColumnWidth']),
      editorAutofocus: _boolOr(json['editorAutofocus'], false),
      reminderShowTokens: _boolOr(json['reminderShowTokens'], false),
      tidyOnClose: _boolOr(json['tidyOnClose'], true),
      deleteCarriesNotes: _boolOr(json['deleteCarriesNotes'], true),
      cascadeChecklist: _boolOr(json['cascadeChecklist'], true),
      linkPreview: _boolOr(json['linkPreview'], true),
      frontmatterPanel: _boolOr(json['frontmatterPanel'], true),
      lintRulesOff: _lintRulesOffFrom(json['lintRulesOff']),
      // The enum's name is the stored id (#726): a value a later build
      // added reads back as the default here, which is what the setting
      // has always done with an unknown one.
      treeSort: switch (json['treeSort']) {
        final String id => TreeSort.values.firstWhere(
          (sort) => sort.name == id,
          orElse: () => TreeSort.nameAsc,
        ),
        _ => TreeSort.nameAsc,
      },
      todoCollapsedSections: _todoCollapsedSectionsFrom(
        json['todoCollapsedSections'],
      ),
      // The enum's name is the stored id, as the sort's is: an unknown
      // value reads back as the list view (#727).
      treeView: switch (json['treeView']) {
        'grid' => TreeView.grid,
        _ => TreeView.list,
      },
      linkType: switch (json['linkType']) {
        'markdown' => LinkType.markdown,
        _ => LinkType.wikilink,
      },
      // The enum's name is the stored id; a file without the key, or with
      // one this build does not know, keeps the rewrite it always had (#848).
      linkUpdate: switch (json['linkUpdate']) {
        'ask' => LinkUpdate.ask,
        'never' => LinkUpdate.never,
        _ => LinkUpdate.automatic,
      },
      weekStart: WeekStart.fromName(json['weekStart']),
      // The old dead-link setting reads into the new one when the new key
      // is absent (#850); it is never written again.
      newItemLocation:
          newItemLocationFromId(json['newItemLocation']) ??
          newItemLocationFromLegacy(json['missingNoteLocation']),
      indentWidth: normalizeIndentWidth(json['indentWidth']),
      newCardsPerDay: normalizeNewCardsPerDay(json['newCardsPerDay']),
      editorToolbar: switch (json['editorToolbar']) {
        final String layout => layout,
        _ => '',
      },
      uiTextScale: normalizeTextScale(json['uiTextScale']),
      noteTextScale: normalizeTextScale(json['noteTextScale']),
      sourceFont: normalizeSourceFont(json['sourceFont']),
      treeWidth: normalizeTreeWidth(json['treeWidth']),
      dockWidth: normalizeDockWidth(json['dockWidth']),
      // The legacy single-dictionary key migrates to the list.
      spellDictionaries: _spellDictionariesFrom(
        json['spellDictionaries'] ?? json['spellDictionary'],
      ),
      editorKind: switch (json['editorKind']) {
        'wysiwyg' => EditorKind.wysiwyg,
        _ => EditorKind.source,
      },
      // Absent on files written before the switch existed: both editors
      // were offered then (the status row always switched), so both stay
      // on. An empty or all-unknown list reads back the same way — the
      // file must never resolve to no editor.
      enabledEditors: _enabledEditorsFrom(json['enabledEditors']),
      journal: JournalSettings.fromJson(json),
      epubLook: EpubLook.fromJson(json),
      navigation: json['navigation'] == null
          ? null
          : NavigationLayout.fromJson(json['navigation']),
      deviceNavigation: json['deviceNavigation'] == null
          ? null
          : NavigationLayout.fromJson(json['deviceNavigation']),
      deviceHome: switch (json['deviceHome']) {
        final Map<Object?, Object?> home => {
          for (final e in home.entries) e.key.toString(): e.value,
        },
        _ => null,
      },
      features: Features.fromJson(json['features']),
      featuresReviewed: _boolOr(json['featuresReviewed'], false),
      extra: extra,
    );
  }

  /// The settings of a fresh library: trash enabled, 10 history versions,
  /// the default quick note at the root, list notes in `Lists`, templates
  /// in `Templates`, attachments in `assets`.
  static const LibraryConfig defaults = LibraryConfig(
    trashEnabled: true,
    historyVersions: defaultHistoryVersions,
    quickNotePath: null,
    listNoteFolder: defaultListFolder,
  );

  /// Whether deletes move notes into `.trash/` (default true).
  final bool trashEnabled;

  /// How many days an item may sit in `.trash/` before the automatic
  /// empty deletes it for good; [trashAutoEmptyOff] (the default) never
  /// deletes anything (issue #79).
  final int trashAutoEmptyDays;

  /// The number of kept `.history/` versions (default 10), in
  /// [minHistoryVersions] .. [maxHistoryVersions] when it came from the
  /// file.
  final int historyVersions;

  /// The least minutes between two history versions taken while editing
  /// (default 5); an editing session's first save and a restore always
  /// take one.
  final int historyIntervalMinutes;

  /// The user-chosen quick note (library-relative path), or null when the
  /// default `Quick note.md` at the library root is used.
  final String? quickNotePath;

  /// The folder (library-relative) holding the list notes.
  final String listNoteFolder;

  /// The folder (library-relative) holding the note templates.
  final String templateFolder;

  /// The folder (library-relative) holding the attachments: editor images
  /// and voice-note clips, copied in and linked (issue #56).
  final String attachmentsFolder;

  /// The folder (library-relative) where a note annotating a PDF or a book
  /// is made, when the file has none yet (#284).
  final String annotationsFolder;

  /// The folder (library-relative) a web page or a quote captured as a
  /// new note goes in unless another is picked for it.
  final String captureFolder;

  /// The colour a passage is highlighted in (#626): the one last chosen,
  /// by its id — `yellow`, `green`, `blue`, `pink`.
  final String highlightColour;

  /// Whether the tree's pinned section is rolled up (default false).
  final bool pinnedCollapsed;

  /// Whether the editor shows the row-number column (default true).
  final bool lineNumbers;

  /// Whether a note's text keeps to a centred column instead of the full
  /// width of its pane (default true, #171).
  final bool readableLineLength;

  /// Whether the line being written keeps to the middle of the editor
  /// (typewriter mode, #70; default false).
  final bool typewriter;

  /// The width of that column's text, in logical pixels (default
  /// [defaultNoteColumnWidth]). A pane narrower than it is the column.
  final double noteColumnWidth;

  /// Whether opening a note raises the keyboard (default false).
  final bool editorAutofocus;

  /// Whether a reminder's notification keeps the `+project`, `@context`
  /// and `#tag` markers (default false).
  final bool reminderShowTokens;

  /// Whether a note edited and then closed has its Markdown tidied, as
  /// the "Tidy the Markdown" command does (default true). Library-wide:
  /// it decides how the library's files are written, so it travels with
  /// them.
  final bool tidyOnClose;

  /// Whether the delete of a file or folder takes its own notes
  /// (companions, an OCR sidecar) along by default (#717): which of the
  /// question's two actions is emphasised, remembered from the last
  /// answer. The notes are never taken silently — the question is still
  /// asked.
  final bool deleteCarriesNotes;

  /// Whether ticking a checklist item also ticks the tasks nested under it
  /// (default true, #326). Library-wide, and one-way: clearing a parent
  /// leaves its children as they are.
  final bool cascadeChecklist;

  /// Whether hovering a link previews the note it points at (default true,
  /// #846): a card at the pointer in the read view, with Ctrl (⌘) held in the
  /// editor, and a sheet from a long press on a touch screen.
  final bool linkPreview;

  /// Whether a note's leading frontmatter is drawn as the properties panel
  /// above it (default true, #157).
  ///
  /// Off, the note is its own text everywhere and no panel stands over it.
  /// On, the panel is the note's head: closed until it is opened, one row of
  /// chrome while it is closed, and away once the note is scrolled past it.
  final bool frontmatterPanel;

  /// The #72 rules this library has turned off, by [LintRule.id].
  ///
  /// The rules *left out* are stored: a rule added in a later build runs
  /// without a migration, and an id a newer build wrote is dropped on
  /// read. Empty — the default — means every rule runs.
  final Set<String> lintRulesOff;

  /// The tree's sort order (default [TreeSort.nameAsc]).
  final TreeSort treeSort;

  /// The todo list's sections folded on this device, by section id (#1003).
  ///
  /// Kept on the device ([deviceKeys]) like the view the Files pane takes:
  /// a phone folds what a wide window leaves open. Done starts folded
  /// ([defaultTodoCollapsedSections]); an empty set means every section is
  /// open.
  final Set<String> todoCollapsedSections;

  /// How the Files pane shows a folder, the tree or the grid (default
  /// [TreeView.list], #727).
  ///
  /// Kept on the device ([deviceKeys]): a wide window wants the grid, a
  /// phone the tree it always had, and a library opened on both keeps an
  /// answer per screen.
  final TreeView treeView;

  /// What the editor's link button inserts (default a wikilink).
  final LinkType linkType;

  /// What a rename or a move does to the links pointing at what moved
  /// (default: rewrite them, as it always has, #848).
  final LinkUpdate linkUpdate;

  /// The day the calendars start the week on (#566): the system's by
  /// default; a library sets one for every device it is opened on.
  final WeekStart weekStart;

  /// Where new notes and folders go when no folder is named (default the
  /// folder of the open note, issue #850; it absorbed the dead-link
  /// setting `missingNoteLocation` of issue #78).
  final NewItemLocation newItemLocation;

  /// Spaces added per indent level (default 2).
  final int indentWidth;

  /// The new flashcards each deck shows per day (default 20, 0 = none,
  /// #533).
  final int newCardsPerDay;

  /// The arranged editor toolbar; empty means the shipped one.
  final String editorToolbar;

  /// How much larger than shipped the interface text is (default 1.0).
  ///
  /// Per library rather than per install (user, 2026-09-09): the size a
  /// library wants to be read at is a property of what is in it, and a
  /// library read on a tablet and on a phone wants the same text on both.
  final double uiTextScale;

  /// How much larger than shipped the note text is, in the editor and in
  /// the preview alike (default 1.0).
  final double noteTextScale;

  /// The face the source editor is set in (default [defaultSourceFont], the
  /// monospace face it shipped with, issue #259).
  ///
  /// The read view and `live` are drawn in the note's own face whatever this
  /// says: only the source pane, which is read as text, changes.
  ///
  /// Kept on the device ([deviceKeys]), like the note's text size it sits
  /// under: the face a screen reads a file in is that screen's own answer,
  /// and the folder travels between a phone and a desktop.
  final SourceFont sourceFont;

  /// The tree pane's width in logical pixels (default
  /// [defaultTreeWidth]), dragged on wide screens.
  final double treeWidth;

  /// The right dock's width in logical pixels (default
  /// [defaultDockWidth]), dragged on wide screens (#297).
  final double dockWidth;

  /// The hunspell dictionaries the spell checker uses (`<name>`s found
  /// on the machine), in selection order. Empty means the locale's default.
  /// Several are checked at once, a word passing when any of them knows it
  /// (T-PP-09, revised).
  final List<String> spellDictionaries;

  /// Which editor this library writes in (default source).
  final EditorKind editorKind;

  /// Which editors the library offers (default both): the settings screen
  /// enables source, WYSIWYG, or both, never none; the note's status row
  /// switches between them only when both are enabled.
  final Set<EditorKind> enabledEditors;

  /// The journal's settings (#7).
  final JournalSettings journal;

  /// How the library's books look (#280).
  final EpubLook epubLook;

  /// The navigation's order and hidden destinations (#536), as the
  /// library keeps them for every device; null is the defaults.
  final NavigationLayout? navigation;

  /// This device's own navigation ([deviceKeys]), set by *Only on this
  /// device*; while it is there it wins over [navigation].
  final NavigationLayout? deviceNavigation;

  /// This device's own Home (#535), set by *Only on this device*: the
  /// object `.niman/home.json` would hold (`HomeLayout`). While it is there
  /// it wins over the file.
  final Map<String, Object?>? deviceHome;

  /// Which of the library's features are on (#1109); every one when the
  /// file has no `features` key.
  final Features features;

  /// Whether the Features introduction has been seen in this library; false
  /// when the file does not say.
  final bool featuresReviewed;

  /// Keys this build does not understand, preserved verbatim.
  final Map<String, Object?> extra;

  /// A copy with the given fields replaced.
  LibraryConfig copyWith({
    bool? trashEnabled,
    int? trashAutoEmptyDays,
    int? historyVersions,
    int? historyIntervalMinutes,
    String? quickNotePath,
    bool clearQuickNotePath = false,
    String? listNoteFolder,
    String? templateFolder,
    String? attachmentsFolder,
    String? annotationsFolder,
    String? captureFolder,
    String? highlightColour,
    bool? pinnedCollapsed,
    bool? lineNumbers,
    bool? readableLineLength,
    bool? typewriter,
    double? noteColumnWidth,
    bool? editorAutofocus,
    bool? reminderShowTokens,
    bool? tidyOnClose,
    bool? deleteCarriesNotes,
    bool? cascadeChecklist,
    bool? linkPreview,
    bool? frontmatterPanel,
    Set<String>? lintRulesOff,
    TreeSort? treeSort,
    Set<String>? todoCollapsedSections,
    TreeView? treeView,
    LinkType? linkType,
    LinkUpdate? linkUpdate,
    WeekStart? weekStart,
    NewItemLocation? newItemLocation,
    int? indentWidth,
    int? newCardsPerDay,
    String? editorToolbar,
    double? uiTextScale,
    double? noteTextScale,
    SourceFont? sourceFont,
    double? treeWidth,
    double? dockWidth,
    List<String>? spellDictionaries,
    EditorKind? editorKind,
    Set<EditorKind>? enabledEditors,
    JournalSettings? journal,
    EpubLook? epubLook,
    NavigationLayout? navigation,
    NavigationLayout? deviceNavigation,
    bool clearDeviceNavigation = false,
    Map<String, Object?>? deviceHome,
    bool clearDeviceHome = false,
    Features? features,
    bool? featuresReviewed,
  }) {
    return LibraryConfig(
      trashEnabled: trashEnabled ?? this.trashEnabled,
      trashAutoEmptyDays: trashAutoEmptyDays ?? this.trashAutoEmptyDays,
      historyVersions: historyVersions ?? this.historyVersions,
      historyIntervalMinutes:
          historyIntervalMinutes ?? this.historyIntervalMinutes,
      quickNotePath: clearQuickNotePath
          ? null
          : quickNotePath ?? this.quickNotePath,
      listNoteFolder: listNoteFolder ?? this.listNoteFolder,
      templateFolder: templateFolder ?? this.templateFolder,
      attachmentsFolder: attachmentsFolder ?? this.attachmentsFolder,
      annotationsFolder: annotationsFolder ?? this.annotationsFolder,
      captureFolder: captureFolder ?? this.captureFolder,
      highlightColour: highlightColour ?? this.highlightColour,
      pinnedCollapsed: pinnedCollapsed ?? this.pinnedCollapsed,
      lineNumbers: lineNumbers ?? this.lineNumbers,
      readableLineLength: readableLineLength ?? this.readableLineLength,
      typewriter: typewriter ?? this.typewriter,
      noteColumnWidth: noteColumnWidth ?? this.noteColumnWidth,
      editorAutofocus: editorAutofocus ?? this.editorAutofocus,
      reminderShowTokens: reminderShowTokens ?? this.reminderShowTokens,
      tidyOnClose: tidyOnClose ?? this.tidyOnClose,
      deleteCarriesNotes: deleteCarriesNotes ?? this.deleteCarriesNotes,
      cascadeChecklist: cascadeChecklist ?? this.cascadeChecklist,
      linkPreview: linkPreview ?? this.linkPreview,
      frontmatterPanel: frontmatterPanel ?? this.frontmatterPanel,
      lintRulesOff: lintRulesOff ?? this.lintRulesOff,
      treeSort: treeSort ?? this.treeSort,
      todoCollapsedSections:
          todoCollapsedSections ?? this.todoCollapsedSections,
      treeView: treeView ?? this.treeView,
      linkType: linkType ?? this.linkType,
      linkUpdate: linkUpdate ?? this.linkUpdate,
      weekStart: weekStart ?? this.weekStart,
      newItemLocation: newItemLocation ?? this.newItemLocation,
      indentWidth: indentWidth ?? this.indentWidth,
      newCardsPerDay: newCardsPerDay ?? this.newCardsPerDay,
      editorToolbar: editorToolbar ?? this.editorToolbar,
      uiTextScale: uiTextScale ?? this.uiTextScale,
      noteTextScale: noteTextScale ?? this.noteTextScale,
      sourceFont: sourceFont ?? this.sourceFont,
      treeWidth: treeWidth ?? this.treeWidth,
      dockWidth: dockWidth ?? this.dockWidth,
      spellDictionaries: spellDictionaries ?? this.spellDictionaries,
      editorKind: editorKind ?? this.editorKind,
      enabledEditors: enabledEditors ?? this.enabledEditors,
      journal: journal ?? this.journal,
      epubLook: epubLook ?? this.epubLook,
      navigation: navigation ?? this.navigation,
      deviceNavigation: clearDeviceNavigation
          ? null
          : deviceNavigation ?? this.deviceNavigation,
      deviceHome: clearDeviceHome ? null : deviceHome ?? this.deviceHome,
      features: features ?? this.features,
      featuresReviewed: featuresReviewed ?? this.featuresReviewed,
      extra: extra,
    );
  }

  /// This config with every library-relative path that pointed at the item
  /// that moved from [from] to [to] rewritten (#506): the quick note, the
  /// list, template, attachments, annotations and capture folders, and the
  /// journal's own folder and template.
  ///
  /// A folder carries everything under it; a note only itself. A config
  /// nothing pointed to comes back equal, so the write is skipped and the
  /// settings file is not churned.
  LibraryConfig renamed(String from, String to, {required bool isDir}) {
    String rewrite(String value) =>
        pathAfterMove(value, from, to, isDir: isDir) ?? value;
    return copyWith(
      quickNotePath: pathAfterMove(quickNotePath, from, to, isDir: isDir),
      listNoteFolder: rewrite(listNoteFolder),
      templateFolder: rewrite(templateFolder),
      attachmentsFolder: rewrite(attachmentsFolder),
      annotationsFolder: rewrite(annotationsFolder),
      captureFolder: rewrite(captureFolder),
      journal: journal.copyWith(
        folder: rewrite(journal.folder),
        template: pathAfterMove(journal.template, from, to, isDir: isDir),
      ),
    );
  }

  /// The keys kept on the device rather than in `settings.json`.
  static const Set<String> deviceKeys = {
    'pinnedCollapsed',
    'lineNumbers',
    'readableLineLength',
    'typewriter',
    'noteColumnWidth',
    'editorAutofocus',
    'treeSort',
    'todoCollapsedSections',
    'treeView',
    'editorToolbar',
    'uiTextScale',
    'noteTextScale',
    'sourceFont',
    'treeWidth',
    'dockWidth',
    'editorKind',
    'enabledEditors',
    'deviceNavigation',
    'deviceHome',
    ...EpubLook.keys,
  };

  /// The device keys for the two editor settings, as the file spells
  /// them, for the first-open seed the welcome's answer gives (#266).
  ///
  /// Built here rather than in `core/welcome.dart` so the JSON names and
  /// the enum spelling live with the serialization they belong to.
  static Map<String, Object?> editorDeviceKeys({
    required EditorKind kind,
    required Set<EditorKind> enabled,
  }) {
    return {
      'editorKind': kind.name,
      'enabledEditors': [
        for (final option in EditorKind.values)
          if (enabled.contains(option)) option.name,
      ],
    };
  }

  /// What `settings.json` holds: [toJsonMap] without the [deviceKeys].
  Map<String, Object?> libraryJsonMap() => {
    for (final entry in toJsonMap().entries)
      if (!deviceKeys.contains(entry.key)) entry.key: entry.value,
  };

  /// What the device keeps: the [deviceKeys] of [toJsonMap].
  Map<String, Object?> deviceJsonMap() => {
    for (final entry in toJsonMap().entries)
      if (deviceKeys.contains(entry.key)) entry.key: entry.value,
  };

  static const Set<String> _knownKeys = {
    'trashEnabled',
    'trashAutoEmptyDays',
    'historyVersions',
    'historyIntervalMinutes',
    'quickNotePath',
    'listNoteFolder',
    'templateFolder',
    'attachmentsFolder',
    'annotationsFolder',
    'captureFolder',
    'highlightColour',
    'pinnedCollapsed',
    'lineNumbers',
    'readableLineLength',
    'typewriter',
    'noteColumnWidth',
    'editorAutofocus',
    'reminderShowTokens',
    'tidyOnClose',
    'deleteCarriesNotes',
    'cascadeChecklist',
    'linkPreview',
    'frontmatterPanel',
    'lintRulesOff',
    'treeSort',
    'todoCollapsedSections',
    'treeView',
    'linkType',
    'linkUpdate',
    'weekStart',
    'newItemLocation',
    // Legacy dead-link setting, read never written (#850): the new key
    // takes its value over, and the file must not hand it back as an
    // unknown one to preserve forever.
    'missingNoteLocation',
    'indentWidth',
    'newCardsPerDay',
    'editorToolbar',
    'uiTextScale',
    'noteTextScale',
    'sourceFont',
    'treeWidth',
    'dockWidth',
    'spellDictionary', // Legacy single-dictionary key (read, never written).
    'spellDictionaries',
    'editorKind',
    // The engine switch, read never written: the unified engine is the
    // only one now (#247), and a file that still carries the key must not
    // have it handed back as an unknown one to preserve forever.
    'markdownEngine',
    'enabledEditors',
    // Legacy preview switch, read never written: the preview is part of
    // the app now, and a file that still carries the key must not have it
    // handed back as an unknown one to preserve forever.
    'previewEnabled',
    'navigation',
    'deviceNavigation',
    'deviceHome',
    'features',
    'featuresReviewed',
    ...JournalSettings.keys,
    ...EpubLook.keys,
  };

  /// The JSON object to write: the known keys (a null quick note is
  /// omitted) followed by the preserved unknown keys.
  ///
  /// A known key found in [extra] is dropped rather than written. It
  /// cannot get there through [LibraryConfig.fromJsonMap], which filters
  /// the known ones
  /// out, but a config built by hand could carry one, and an `addAll`
  /// would then let it overwrite the typed field it duplicates. The typed
  /// field is the authority; this makes that true by construction instead
  /// of by the caller's care.
  Map<String, Object?> toJsonMap() {
    final json = <String, Object?>{
      'trashEnabled': trashEnabled,
      'trashAutoEmptyDays': trashAutoEmptyDays,
      'historyVersions': historyVersions,
      'historyIntervalMinutes': historyIntervalMinutes,
      'listNoteFolder': listNoteFolder,
      'templateFolder': templateFolder,
      'attachmentsFolder': attachmentsFolder,
      'annotationsFolder': annotationsFolder,
      'captureFolder': captureFolder,
      'highlightColour': highlightColour,
      'pinnedCollapsed': pinnedCollapsed,
      'lineNumbers': lineNumbers,
      'readableLineLength': readableLineLength,
      'typewriter': typewriter,
      'noteColumnWidth': noteColumnWidth,
      'editorAutofocus': editorAutofocus,
      'reminderShowTokens': reminderShowTokens,
      'tidyOnClose': tidyOnClose,
      'deleteCarriesNotes': deleteCarriesNotes,
      'cascadeChecklist': cascadeChecklist,
      'linkPreview': linkPreview,
      'frontmatterPanel': frontmatterPanel,
      'treeSort': treeSort.name,
      // Sorted, so the file does not churn on a set rebuilt in another
      // order; written even when empty, which is "all open" rather than
      // the default.
      'todoCollapsedSections': todoCollapsedSections.toList()..sort(),
      'treeView': treeView.name,
      'linkType': linkType.name,
      'linkUpdate': linkUpdate.name,
      'weekStart': weekStart.name,
      'newItemLocation': newItemLocation.name,
      'indentWidth': indentWidth,
      'newCardsPerDay': newCardsPerDay,
      'editorToolbar': editorToolbar,
      'uiTextScale': uiTextScale,
      'noteTextScale': noteTextScale,
      'sourceFont': sourceFont.name,
      'treeWidth': treeWidth,
      'dockWidth': dockWidth,
      'editorKind': editorKind.name,
      // Canonical order, so the file does not churn when the set is
      // rebuilt insertion-ordered differently.
      'enabledEditors': [
        for (final kind in EditorKind.values)
          if (enabledEditors.contains(kind)) kind.name,
      ],
      ...journal.toJson(),
      ...epubLook.toJson(),
    };
    if (quickNotePath != null) {
      json['quickNotePath'] = quickNotePath;
    }
    if (spellDictionaries.isNotEmpty) {
      json['spellDictionaries'] = spellDictionaries;
    }
    if (navigation case final layout?) json['navigation'] = layout.toJson();
    if (deviceNavigation case final layout?) {
      json['deviceNavigation'] = layout.toJson();
    }
    if (deviceHome case final home?) json['deviceHome'] = home;
    // Only the switches that are off: a library that never opens the
    // screen writes no key, and its file stays as it was.
    final off = features.toJson();
    if (off.isNotEmpty) json['features'] = off;
    if (featuresReviewed) json['featuresReviewed'] = true;
    if (lintRulesOff.isNotEmpty) {
      // Canonical order, so the file does not churn on a set rebuilt
      // insertion-ordered differently.
      json['lintRulesOff'] = [
        for (final rule in LintRule.values)
          if (lintRulesOff.contains(rule.id)) rule.id,
      ];
    }
    for (final entry in extra.entries) {
      if (_knownKeys.contains(entry.key)) continue;
      json[entry.key] = entry.value;
    }
    return json;
  }

  /// Deep-compares two (small) JSON values, recursing into maps and lists.
  bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is Map<String, Object?> && b is Map<String, Object?>) {
      if (a.length != b.length) return false;
      for (final entry in a.entries) {
        if (!b.containsKey(entry.key) ||
            !_deepEquals(b[entry.key], entry.value)) {
          return false;
        }
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  /// A stable hash for a (possibly nested) JSON value.
  int _stableHash(Object? v) {
    if (v is Map<String, Object?>) {
      final keys = v.keys.toList()..sort();
      final parts = <Object?>[];
      for (final key in keys) {
        parts
          ..add(key)
          ..add(_stableHash(v[key]));
      }
      return Object.hashAll(parts);
    }
    if (v is List) return Object.hashAll(v);
    return v.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LibraryConfig) return false;
    return trashEnabled == other.trashEnabled &&
        trashAutoEmptyDays == other.trashAutoEmptyDays &&
        historyVersions == other.historyVersions &&
        historyIntervalMinutes == other.historyIntervalMinutes &&
        quickNotePath == other.quickNotePath &&
        listNoteFolder == other.listNoteFolder &&
        templateFolder == other.templateFolder &&
        attachmentsFolder == other.attachmentsFolder &&
        annotationsFolder == other.annotationsFolder &&
        captureFolder == other.captureFolder &&
        highlightColour == other.highlightColour &&
        pinnedCollapsed == other.pinnedCollapsed &&
        lineNumbers == other.lineNumbers &&
        readableLineLength == other.readableLineLength &&
        typewriter == other.typewriter &&
        noteColumnWidth == other.noteColumnWidth &&
        editorAutofocus == other.editorAutofocus &&
        reminderShowTokens == other.reminderShowTokens &&
        tidyOnClose == other.tidyOnClose &&
        deleteCarriesNotes == other.deleteCarriesNotes &&
        cascadeChecklist == other.cascadeChecklist &&
        linkPreview == other.linkPreview &&
        lintRulesOff.length == other.lintRulesOff.length &&
        lintRulesOff.containsAll(other.lintRulesOff) &&
        treeSort == other.treeSort &&
        todoCollapsedSections.length == other.todoCollapsedSections.length &&
        todoCollapsedSections.containsAll(other.todoCollapsedSections) &&
        treeView == other.treeView &&
        linkType == other.linkType &&
        linkUpdate == other.linkUpdate &&
        weekStart == other.weekStart &&
        newItemLocation == other.newItemLocation &&
        indentWidth == other.indentWidth &&
        newCardsPerDay == other.newCardsPerDay &&
        editorToolbar == other.editorToolbar &&
        uiTextScale == other.uiTextScale &&
        noteTextScale == other.noteTextScale &&
        sourceFont == other.sourceFont &&
        treeWidth == other.treeWidth &&
        dockWidth == other.dockWidth &&
        _deepEquals(spellDictionaries, other.spellDictionaries) &&
        editorKind == other.editorKind &&
        enabledEditors.length == other.enabledEditors.length &&
        enabledEditors.containsAll(other.enabledEditors) &&
        journal == other.journal &&
        epubLook == other.epubLook &&
        navigation == other.navigation &&
        deviceNavigation == other.deviceNavigation &&
        _deepEquals(deviceHome, other.deviceHome) &&
        features == other.features &&
        featuresReviewed == other.featuresReviewed &&
        _deepEquals(extra, other.extra);
  }

  /// Hashed over [toJsonMap], which is the same filtered view `==`
  /// compares. The spread this replaced had the shadowing problem too: a
  /// known key in [extra] displaced the typed field it duplicates, so two
  /// configs that compare equal could hash differently.
  @override
  int get hashCode => _stableHash(toJsonMap());
}
