import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/device_settings_store.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show
        EditorKind,
        LinkType,
        TreeSort,
        defaultAnnotationsFolder,
        defaultAttachmentsFolder,
        defaultListFolder,
        defaultTemplateFolder;
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/lint/lint_rule.dart';
import 'package:path/path.dart' as p;

/// The number of kept `.history/` versions of a fresh library.
const int defaultHistoryVersions = 10;

/// The smallest accepted `historyVersions` (0 = keep no history).
const int minHistoryVersions = 0;

/// The largest accepted `historyVersions`.
const int maxHistoryVersions = 100;

/// Reads a `historyVersions` value out of the settings file (T-ML-02).
///
/// The file is user-editable by design, so the number in it is an input,
/// not a fact: a hand-typed `-5` or `100000` would otherwise reach the
/// history code as-is. Anything outside [minHistoryVersions] ..
/// [maxHistoryVersions] reads back as [defaultHistoryVersions], the same
/// answer a missing key gives — a nonsense value is no more informative
/// than no value.
int normalizeHistoryVersions(Object? raw) {
  if (raw is! num) return defaultHistoryVersions;
  final count = raw.toInt();
  if (count < minHistoryVersions || count > maxHistoryVersions) {
    return defaultHistoryVersions;
  }
  return count;
}

/// The `trashAutoEmptyDays` that empties nothing: what a fresh library
/// gets, and what an unreadable value falls back to (issue #79).
const int trashAutoEmptyOff = 0;

/// The shortest an item can be asked to wait in `.trash/` before the
/// automatic empty takes it.
const int minTrashAutoEmptyDays = 1;

/// The longest wait the setting accepts (ten years — past it, someone is
/// not asking for an automatic empty at all).
const int maxTrashAutoEmptyDays = 3650;

/// The waits the settings screen offers, in days; a hand-edited file may
/// hold any whole number in [minTrashAutoEmptyDays] ..
/// [maxTrashAutoEmptyDays].
const List<int> trashAutoEmptyChoices = [
  trashAutoEmptyOff,
  7,
  30,
  90,
  180,
  365,
];

/// Reads a `trashAutoEmptyDays` value out of the settings file (issue
/// #79).
///
/// Defaulted to [trashAutoEmptyOff] rather than clamped, unlike every
/// other number here: this one is permission to delete notes for good,
/// and a value nobody can make sense of is not permission. A file whose
/// key says `-1`, `"30"` or `30.5` empties nothing at all.
int normalizeTrashAutoEmptyDays(Object? raw) {
  if (raw is! int) return trashAutoEmptyOff;
  if (raw < minTrashAutoEmptyDays || raw > maxTrashAutoEmptyDays) {
    return trashAutoEmptyOff;
  }
  return raw;
}

/// The least minutes between two history versions taken while editing,
/// in a fresh library.
const int defaultHistoryIntervalMinutes = 5;

/// The history intervals the settings screen offers, in minutes; a
/// hand-edited file may hold any whole number in between.
const List<int> historyIntervalChoices = [1, 2, 5, 10, 15, 30, 60];

/// Reads a `historyIntervalMinutes` value out of the settings file.
///
/// Defaulted rather than clamped, like `historyVersions`: 0 would mean a
/// version on every autosave, and anything outside 1 .. 60 is no more
/// informative than a missing key.
int normalizeHistoryIntervalMinutes(Object? raw) {
  if (raw is! num) return defaultHistoryIntervalMinutes;
  final minutes = raw.toInt();
  if (minutes < historyIntervalChoices.first ||
      minutes > historyIntervalChoices.last) {
    return defaultHistoryIntervalMinutes;
  }
  return minutes;
}

/// The editor's indent width in a fresh library.
const int defaultIndentWidth = 2;

/// The smallest accepted `indentWidth`.
const int minIndentWidth = 2;

/// The largest accepted `indentWidth`.
const int maxIndentWidth = 8;

/// Reads an `indentWidth` out of the settings file, into range.
///
/// Unlike `historyVersions` this one is clamped rather than defaulted: 1
/// and 40 are both plausible things to type, and the nearest legal width
/// is closer to what was meant than a jump back to 2.
int normalizeIndentWidth(Object? raw) {
  if (raw is! num) return defaultIndentWidth;
  final width = raw.toInt();
  if (width < minIndentWidth) return minIndentWidth;
  if (width > maxIndentWidth) return maxIndentWidth;
  return width;
}

/// The text size of a fresh library: the sizes the app shipped with.
const double defaultTextScale = 1;

/// The smallest accepted text scale.
const double minTextScale = 0.8;

/// The largest accepted text scale.
const double maxTextScale = 1.8;

/// The source editor's font size at [defaultTextScale], in logical
/// pixels.
///
/// It was the old source editor's default, kept so a note reads at the
/// size it always had; the note scale multiplies it.
const double baseNoteFontSize = 13;

/// Reads a text scale out of the settings file, into range.
///
/// Clamped rather than defaulted, for the reason [normalizeIndentWidth]
/// is: someone who typed 3 wants the text as large as it goes, not back
/// at the size they were trying to leave.
double normalizeTextScale(Object? raw) {
  if (raw is! num) return defaultTextScale;
  final scale = raw.toDouble();
  if (!scale.isFinite) return defaultTextScale;
  if (scale < minTextScale) return minTextScale;
  if (scale > maxTextScale) return maxTextScale;
  return scale;
}

/// The tree pane's width in a fresh library (logical pixels).
const double defaultTreeWidth = 340;

/// The narrowest the tree pane drags to.
const double minTreeWidth = 200;

/// The widest the tree pane drags to.
const double maxTreeWidth = 600;

/// Reads a `treeWidth` out of the settings file, clamped into range —
/// the same bargain as `indentWidth`: a hand-typed number stays near
/// what was meant, anything else reads back as the default.
double normalizeTreeWidth(Object? raw) {
  if (raw is! num) return defaultTreeWidth;
  final width = raw.toDouble();
  if (width < minTreeWidth) return minTreeWidth;
  if (width > maxTreeWidth) return maxTreeWidth;
  return width;
}

/// The right dock's width in a fresh library (logical pixels, #297).
const double defaultDockWidth = 280;

/// The narrowest the right dock drags to.
const double minDockWidth = 200;

/// The widest the right dock drags to.
const double maxDockWidth = 600;

/// Reads a `dockWidth` out of the settings, clamped into range — the same
/// bargain as `treeWidth`.
double normalizeDockWidth(Object? raw) {
  if (raw is! num) return defaultDockWidth;
  final width = raw.toDouble();
  if (width < minDockWidth) return minDockWidth;
  if (width > maxDockWidth) return maxDockWidth;
  return width;
}

/// The note column's width in a fresh library, in logical pixels (#171):
/// about 80 characters of prose at the shipped text size, the measure
/// the preview already read at.
const double defaultNoteColumnWidth = 700;

/// The narrowest accepted note column.
const double minNoteColumnWidth = 480;

/// The widest accepted note column.
const double maxNoteColumnWidth = 1400;

/// Reads a `noteColumnWidth` out of the settings file, clamped into range
/// — the bargain [normalizeIndentWidth] makes: a hand-typed number stays
/// near what was meant, anything else reads back as the default.
double normalizeNoteColumnWidth(Object? raw) {
  if (raw is! num) return defaultNoteColumnWidth;
  final width = raw.toDouble();
  if (!width.isFinite) return defaultNoteColumnWidth;
  if (width < minNoteColumnWidth) return minNoteColumnWidth;
  if (width > maxNoteColumnWidth) return maxNoteColumnWidth;
  return width;
}

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

/// Sanitizes a library-relative folder path: trims, drops leading and
/// trailing slashes and empty/`.`/`..` segments; an empty result is
/// [fallback].
String cleanFolderPath(String folder, String fallback) {
  final parts = folder
      .trim()
      .split('/')
      .where((s) => s.isNotEmpty && s != '.' && s != '..')
      .toList();
  return parts.isEmpty ? fallback : parts.join('/');
}

/// Sanitizes a list-folder path; an empty result is [defaultListFolder].
String cleanListFolder(String folder) =>
    cleanFolderPath(folder, defaultListFolder);

/// Sanitizes a template-folder path; an empty result is
/// [defaultTemplateFolder].
String cleanTemplateFolder(String folder) =>
    cleanFolderPath(folder, defaultTemplateFolder);

/// Sanitizes an attachments-folder path; an empty result is
/// [defaultAttachmentsFolder].
String cleanAttachmentsFolder(String folder) =>
    cleanFolderPath(folder, defaultAttachmentsFolder);

/// Sanitizes an annotations-folder path; an empty result is
/// [defaultAnnotationsFolder].
String cleanAnnotationsFolder(String folder) =>
    cleanFolderPath(folder, defaultAnnotationsFolder);

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
    this.pinnedCollapsed = false,
    this.lineNumbers = true,
    this.readableLineLength = true,
    this.typewriter = false,
    this.noteColumnWidth = defaultNoteColumnWidth,
    this.editorAutofocus = false,
    this.reminderShowTokens = false,
    this.tidyOnClose = true,
    this.lintRulesOff = const <String>{},
    this.treeSort = TreeSort.nameAsc,
    this.linkType = LinkType.wikilink,
    this.missingNoteLocation = MissingNoteLocation.currentFolder,
    this.indentWidth = defaultIndentWidth,
    this.editorToolbar = '',
    this.uiTextScale = defaultTextScale,
    this.noteTextScale = defaultTextScale,
    this.treeWidth = defaultTreeWidth,
    this.dockWidth = defaultDockWidth,
    this.spellDictionaries = const <String>[],
    this.editorKind = EditorKind.source,
    this.enabledEditors = const {EditorKind.source, EditorKind.wysiwyg},
    this.journal = const JournalSettings(),
    this.epubLook = const EpubLook(),
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
      pinnedCollapsed: _boolOr(json['pinnedCollapsed'], false),
      lineNumbers: _boolOr(json['lineNumbers'], true),
      readableLineLength: _boolOr(json['readableLineLength'], true),
      typewriter: _boolOr(json['typewriter'], false),
      noteColumnWidth: normalizeNoteColumnWidth(json['noteColumnWidth']),
      editorAutofocus: _boolOr(json['editorAutofocus'], false),
      reminderShowTokens: _boolOr(json['reminderShowTokens'], false),
      tidyOnClose: _boolOr(json['tidyOnClose'], true),
      lintRulesOff: _lintRulesOffFrom(json['lintRulesOff']),
      treeSort: switch (json['treeSort']) {
        'nameDesc' => TreeSort.nameDesc,
        _ => TreeSort.nameAsc,
      },
      linkType: switch (json['linkType']) {
        'markdown' => LinkType.markdown,
        _ => LinkType.wikilink,
      },
      missingNoteLocation: switch (json['missingNoteLocation']) {
        'libraryRoot' => MissingNoteLocation.libraryRoot,
        _ => MissingNoteLocation.currentFolder,
      },
      indentWidth: normalizeIndentWidth(json['indentWidth']),
      editorToolbar: switch (json['editorToolbar']) {
        final String layout => layout,
        _ => '',
      },
      uiTextScale: normalizeTextScale(json['uiTextScale']),
      noteTextScale: normalizeTextScale(json['noteTextScale']),
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

  /// The #72 rules this library has turned off, by [LintRule.id].
  ///
  /// The rules *left out* are stored: a rule added in a later build runs
  /// without a migration, and an id a newer build wrote is dropped on
  /// read. Empty — the default — means every rule runs.
  final Set<String> lintRulesOff;

  /// The tree's sort order (default [TreeSort.nameAsc]).
  final TreeSort treeSort;

  /// What the editor's link button inserts (default a wikilink).
  final LinkType linkType;

  /// Where a note created from a dead link lands (default the folder of
  /// the note the link was clicked in, issue #78).
  final MissingNoteLocation missingNoteLocation;

  /// Spaces added per indent level (default 2).
  final int indentWidth;

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
    bool? pinnedCollapsed,
    bool? lineNumbers,
    bool? readableLineLength,
    bool? typewriter,
    double? noteColumnWidth,
    bool? editorAutofocus,
    bool? reminderShowTokens,
    bool? tidyOnClose,
    Set<String>? lintRulesOff,
    TreeSort? treeSort,
    LinkType? linkType,
    MissingNoteLocation? missingNoteLocation,
    int? indentWidth,
    String? editorToolbar,
    double? uiTextScale,
    double? noteTextScale,
    double? treeWidth,
    double? dockWidth,
    List<String>? spellDictionaries,
    EditorKind? editorKind,
    Set<EditorKind>? enabledEditors,
    JournalSettings? journal,
    EpubLook? epubLook,
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
      pinnedCollapsed: pinnedCollapsed ?? this.pinnedCollapsed,
      lineNumbers: lineNumbers ?? this.lineNumbers,
      readableLineLength: readableLineLength ?? this.readableLineLength,
      typewriter: typewriter ?? this.typewriter,
      noteColumnWidth: noteColumnWidth ?? this.noteColumnWidth,
      editorAutofocus: editorAutofocus ?? this.editorAutofocus,
      reminderShowTokens: reminderShowTokens ?? this.reminderShowTokens,
      tidyOnClose: tidyOnClose ?? this.tidyOnClose,
      lintRulesOff: lintRulesOff ?? this.lintRulesOff,
      treeSort: treeSort ?? this.treeSort,
      linkType: linkType ?? this.linkType,
      missingNoteLocation: missingNoteLocation ?? this.missingNoteLocation,
      indentWidth: indentWidth ?? this.indentWidth,
      editorToolbar: editorToolbar ?? this.editorToolbar,
      uiTextScale: uiTextScale ?? this.uiTextScale,
      noteTextScale: noteTextScale ?? this.noteTextScale,
      treeWidth: treeWidth ?? this.treeWidth,
      dockWidth: dockWidth ?? this.dockWidth,
      spellDictionaries: spellDictionaries ?? this.spellDictionaries,
      editorKind: editorKind ?? this.editorKind,
      enabledEditors: enabledEditors ?? this.enabledEditors,
      journal: journal ?? this.journal,
      epubLook: epubLook ?? this.epubLook,
      extra: extra,
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
    'editorToolbar',
    'uiTextScale',
    'noteTextScale',
    'treeWidth',
    'dockWidth',
    'editorKind',
    'enabledEditors',
    ...EpubLook.keys,
  };

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
    'pinnedCollapsed',
    'lineNumbers',
    'readableLineLength',
    'typewriter',
    'noteColumnWidth',
    'editorAutofocus',
    'reminderShowTokens',
    'tidyOnClose',
    'lintRulesOff',
    'treeSort',
    'linkType',
    'missingNoteLocation',
    'indentWidth',
    'editorToolbar',
    'uiTextScale',
    'noteTextScale',
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
      'pinnedCollapsed': pinnedCollapsed,
      'lineNumbers': lineNumbers,
      'readableLineLength': readableLineLength,
      'typewriter': typewriter,
      'noteColumnWidth': noteColumnWidth,
      'editorAutofocus': editorAutofocus,
      'reminderShowTokens': reminderShowTokens,
      'tidyOnClose': tidyOnClose,
      'treeSort': treeSort.name,
      'linkType': linkType.name,
      'missingNoteLocation': missingNoteLocation.name,
      'indentWidth': indentWidth,
      'editorToolbar': editorToolbar,
      'uiTextScale': uiTextScale,
      'noteTextScale': noteTextScale,
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
        pinnedCollapsed == other.pinnedCollapsed &&
        lineNumbers == other.lineNumbers &&
        readableLineLength == other.readableLineLength &&
        typewriter == other.typewriter &&
        noteColumnWidth == other.noteColumnWidth &&
        editorAutofocus == other.editorAutofocus &&
        reminderShowTokens == other.reminderShowTokens &&
        tidyOnClose == other.tidyOnClose &&
        lintRulesOff.length == other.lintRulesOff.length &&
        lintRulesOff.containsAll(other.lintRulesOff) &&
        treeSort == other.treeSort &&
        linkType == other.linkType &&
        missingNoteLocation == other.missingNoteLocation &&
        indentWidth == other.indentWidth &&
        editorToolbar == other.editorToolbar &&
        uiTextScale == other.uiTextScale &&
        noteTextScale == other.noteTextScale &&
        treeWidth == other.treeWidth &&
        dockWidth == other.dockWidth &&
        _deepEquals(spellDictionaries, other.spellDictionaries) &&
        editorKind == other.editorKind &&
        enabledEditors.length == other.enabledEditors.length &&
        enabledEditors.containsAll(other.enabledEditors) &&
        journal == other.journal &&
        epubLook == other.epubLook &&
        _deepEquals(extra, other.extra);
  }

  /// Hashed over [toJsonMap], which is the same filtered view `==`
  /// compares. The spread this replaced had the shadowing problem too: a
  /// known key in [extra] displaced the typed field it duplicates, so two
  /// configs that compare equal could hash differently.
  @override
  int get hashCode => _stableHash(toJsonMap());
}

/// The reader/writer for one library's settings: `.niman/settings.json`
/// and, with a [DeviceSettingsStore], the device's share of them
/// ([LibraryConfig.deviceKeys]).
///
/// Reading a missing, unreadable or malformed file yields the defaults
/// rather than throwing: the settings file is user-editable and must
/// never take the app down. Writing is atomic (temp file + rename, same
/// as a note), so a reader never observes a partial write.
///
/// Without a device store (tests, tools, the legacy seed) the file keeps
/// every key, as it did before the split.
final class LibraryConfigStore {
  /// Creates a store for the library at its absolute path.
  new(this._libraryPath, {this._device});

  final String _libraryPath;
  final DeviceSettingsStore? _device;

  /// The settings file: `<library>/.niman/settings.json`.
  File get file => File(p.join(_libraryPath, '.niman', 'settings.json'));

  /// The settings logger: the fallback to defaults used to be silent, and that
  /// silence is half of how #258 went unnoticed for days.
  static const AppLogger _log = AppLogger(name: 'settings');

  /// Reads the library's settings; defaults when the file is missing,
  /// unreadable or malformed.
  ///
  /// With a device store, the device keys come from it — whatever the
  /// file says about them, since an older build elsewhere may still write
  /// its own there. A device that has none yet takes the file's values
  /// once and keeps them: that is the move out of the shared file.
  Future<LibraryConfig> read() async {
    final json = await _readFile();
    final deviceStore = _device;
    if (deviceStore == null) return LibraryConfig.fromJsonMap(json);
    var device = await deviceStore.read(_libraryPath);
    if (device == null) {
      device = {
        for (final key in LibraryConfig.deviceKeys)
          if (json.containsKey(key)) key: json[key],
      };
      await deviceStore.write(_libraryPath, device);
    }
    return LibraryConfig.fromJsonMap({
      for (final entry in json.entries)
        if (!LibraryConfig.deviceKeys.contains(entry.key))
          entry.key: entry.value,
      ...device,
    });
  }

  /// The file's JSON object; empty — the defaults — when it is missing,
  /// unreadable or not an object.
  ///
  /// The fallback stays — a library must open whatever its settings file
  /// says — but it **says which** of the three happened, because the
  /// defaults are not neutral: which editors are on, the toolbar, the
  /// links, the trash all revert, and nothing on screen mentions it. A
  /// missing file in a library that has been written to before is a
  /// `warning` (that is the shape of a lost or trashed file); a library
  /// with no `.niman/` at all is an `info`, because that is simply a new
  /// one.
  Future<Map<String, Object?>> _readFile() async {
    String raw;
    try {
      raw = await file.readAsString();
    } on Object catch (error) {
      if (file.parent.existsSync()) {
        _log.warning(
          'settings.json is missing or unreadable in ${file.parent.path} '
          '($error): this library is on defaults',
        );
      } else {
        _log.info('no settings.json yet: a new library, on defaults');
      }
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _log.warning(
          'settings.json is not an object in ${file.parent.path}: '
          'this library is on defaults',
        );
        return const {};
      }
      // jsonDecode yields `Map<String, dynamic>`; bridge to the typed view.
      return {
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
    } on Object catch (error) {
      _log.warning(
        'settings.json could not be parsed in ${file.parent.path} ($error): '
        'this library is on defaults',
      );
      return const {};
    }
  }

  /// Writes [config]: its library keys to the file (atomically, creating
  /// `.niman/` if needed) and, with a device store, its device keys there.
  ///
  /// The file is rewritten only when its text changes, so a change of a
  /// device key never touches it. Returns whether the file was written —
  /// what the sync needs to hear about.
  Future<bool> write(LibraryConfig config) async {
    final deviceStore = _device;
    if (deviceStore != null) {
      await deviceStore.write(_libraryPath, config.deviceJsonMap());
    }
    final json = deviceStore == null
        ? config.toJsonMap()
        : config.libraryJsonMap();
    final text = '${const JsonEncoder.withIndent('  ').convert(json)}\n';
    try {
      if (await file.readAsString() == text) return false;
    } on FileSystemException {
      // Missing: written below.
    }
    await file.parent.create(recursive: true);
    await writeFileAtomically(file, utf8.encode(text));
    return true;
  }
}
