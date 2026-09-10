import 'dart:convert';
import 'dart:io';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/settings/library_settings.dart'
    show
        EditorKind,
        LinkType,
        TreeSort,
        defaultListFolder,
        defaultTemplateFolder;
import 'package:meta/meta.dart';
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
/// It is re_editor's own default, restated here because the note scale
/// multiplies it: leaving the package to supply the size would make 100%
/// mean whatever the next version of it decides.
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

/// The per-library settings, stored in the library folder itself as
/// `<library>/.copist/settings.json` (T-ML-01, T-ML-10).
///
/// A library is a self-describing folder: these settings travel with it,
/// survive a sync, and can be read and fixed in any editor — the same
/// bargain the notes get. Keys this build does not understand are preserved
/// on read and written back untouched, so a newer build's settings survive
/// an older one opening the library.
///
/// Every setting that describes how you write in *this* library is here,
/// not only the four T-ML-02 moved: the toolbar, the editor toggles, the
/// tree order, the reminder markers. There is no notion of a library
/// "overriding" the app — a library simply has its own answers, seeded
/// from the defaults the first time it is opened. What stays app-wide is
/// what does not depend on the library at all: the language, the debug
/// switch, and the preview layout, which follows the screen.
@immutable
final class LibraryConfig {
  /// Creates a library config. [extra] holds keys this build does not
  /// understand, preserved verbatim.
  const new({
    required this.trashEnabled,
    required this.historyVersions,
    required this.quickNotePath,
    required this.listNoteFolder,
    this.templateFolder = defaultTemplateFolder,
    this.pinnedCollapsed = false,
    this.lineNumbers = true,
    this.editorAutofocus = false,
    this.reminderShowTokens = false,
    this.treeSort = TreeSort.nameAsc,
    this.linkType = LinkType.wikilink,
    this.indentWidth = defaultIndentWidth,
    this.editorToolbar = '',
    this.uiTextScale = defaultTextScale,
    this.noteTextScale = defaultTextScale,
    this.treeWidth = defaultTreeWidth,
    this.spellDictionaries = const <String>[],
    this.editorKind = EditorKind.source,
    this.enabledEditors = const {EditorKind.source, EditorKind.wysiwyg},
    this.previewEnabled = true,
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
    return LibraryConfig(
      trashEnabled: switch (trash) {
        final bool enabled => enabled,
        _ => true,
      },
      historyVersions: normalizeHistoryVersions(versions),
      quickNotePath: quick is String ? quick : null,
      listNoteFolder: folder is String
          ? cleanListFolder(folder)
          : defaultListFolder,
      templateFolder: templates is String
          ? cleanTemplateFolder(templates)
          : defaultTemplateFolder,
      pinnedCollapsed: _boolOr(json['pinnedCollapsed'], false),
      lineNumbers: _boolOr(json['lineNumbers'], true),
      editorAutofocus: _boolOr(json['editorAutofocus'], false),
      reminderShowTokens: _boolOr(json['reminderShowTokens'], false),
      treeSort: switch (json['treeSort']) {
        'nameDesc' => TreeSort.nameDesc,
        _ => TreeSort.nameAsc,
      },
      linkType: switch (json['linkType']) {
        'markdown' => LinkType.markdown,
        _ => LinkType.wikilink,
      },
      indentWidth: normalizeIndentWidth(json['indentWidth']),
      editorToolbar: switch (json['editorToolbar']) {
        final String layout => layout,
        _ => '',
      },
      uiTextScale: normalizeTextScale(json['uiTextScale']),
      noteTextScale: normalizeTextScale(json['noteTextScale']),
      treeWidth: normalizeTreeWidth(json['treeWidth']),
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
      previewEnabled: _boolOr(json['previewEnabled'], true),
      extra: extra,
    );
  }

  /// The settings of a fresh library: trash enabled, 10 history versions,
  /// the default quick note at the root, list notes in `Lists`, templates
  /// in `Templates`.
  static const LibraryConfig defaults = LibraryConfig(
    trashEnabled: true,
    historyVersions: defaultHistoryVersions,
    quickNotePath: null,
    listNoteFolder: defaultListFolder,
  );

  /// Whether deletes move notes into `.trash/` (default true).
  final bool trashEnabled;

  /// The number of kept `.history/` versions (default 10), in
  /// [minHistoryVersions] .. [maxHistoryVersions] when it came from the
  /// file.
  final int historyVersions;

  /// The user-chosen quick note (library-relative path), or null when the
  /// default `Quick note.md` at the library root is used.
  final String? quickNotePath;

  /// The folder (library-relative) holding the list notes.
  final String listNoteFolder;

  /// The folder (library-relative) holding the note templates.
  final String templateFolder;

  /// Whether the tree's pinned section is rolled up (default false).
  final bool pinnedCollapsed;

  /// Whether the editor shows the row-number column (default true).
  final bool lineNumbers;

  /// Whether opening a note raises the keyboard (default false).
  final bool editorAutofocus;

  /// Whether a reminder's notification keeps the `+project`, `@context`
  /// and `#tag` markers (default false).
  final bool reminderShowTokens;

  /// The tree's sort order (default [TreeSort.nameAsc]).
  final TreeSort treeSort;

  /// What the editor's link button inserts (default a wikilink).
  final LinkType linkType;

  /// Spaces added per indent level (default 2).
  final int indentWidth;

  /// The arranged editor toolbar; empty means the shipped one.
  final String editorToolbar;

  /// How much larger than shipped the interface text is (default 1.0).
  ///
  /// Per library rather than per install (user, 2026-09-09): the size a
  /// library wants to be read at is a property of what is in it, and the
  /// tablet-vs-phone argument that keeps the preview layout app-wide does
  /// not apply — a library read on both wants the same text on both.
  final double uiTextScale;

  /// How much larger than shipped the note text is, in the editor and in
  /// the preview alike (default 1.0).
  final double noteTextScale;

  /// The tree pane's width in logical pixels (default
  /// [defaultTreeWidth]), dragged on wide screens.
  final double treeWidth;

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

  /// Whether the preview exists at all (default true).
  final bool previewEnabled;

  /// Keys this build does not understand, preserved verbatim.
  final Map<String, Object?> extra;

  /// A copy with the given fields replaced.
  LibraryConfig copyWith({
    bool? trashEnabled,
    int? historyVersions,
    String? quickNotePath,
    bool clearQuickNotePath = false,
    String? listNoteFolder,
    String? templateFolder,
    bool? pinnedCollapsed,
    bool? lineNumbers,
    bool? editorAutofocus,
    bool? reminderShowTokens,
    TreeSort? treeSort,
    LinkType? linkType,
    int? indentWidth,
    String? editorToolbar,
    double? uiTextScale,
    double? noteTextScale,
    double? treeWidth,
    List<String>? spellDictionaries,
    EditorKind? editorKind,
    Set<EditorKind>? enabledEditors,
    bool? previewEnabled,
  }) {
    return LibraryConfig(
      trashEnabled: trashEnabled ?? this.trashEnabled,
      historyVersions: historyVersions ?? this.historyVersions,
      quickNotePath: clearQuickNotePath
          ? null
          : quickNotePath ?? this.quickNotePath,
      listNoteFolder: listNoteFolder ?? this.listNoteFolder,
      templateFolder: templateFolder ?? this.templateFolder,
      pinnedCollapsed: pinnedCollapsed ?? this.pinnedCollapsed,
      lineNumbers: lineNumbers ?? this.lineNumbers,
      editorAutofocus: editorAutofocus ?? this.editorAutofocus,
      reminderShowTokens: reminderShowTokens ?? this.reminderShowTokens,
      treeSort: treeSort ?? this.treeSort,
      linkType: linkType ?? this.linkType,
      indentWidth: indentWidth ?? this.indentWidth,
      editorToolbar: editorToolbar ?? this.editorToolbar,
      uiTextScale: uiTextScale ?? this.uiTextScale,
      noteTextScale: noteTextScale ?? this.noteTextScale,
      treeWidth: treeWidth ?? this.treeWidth,
      spellDictionaries: spellDictionaries ?? this.spellDictionaries,
      editorKind: editorKind ?? this.editorKind,
      enabledEditors: enabledEditors ?? this.enabledEditors,
      previewEnabled: previewEnabled ?? this.previewEnabled,
      extra: extra,
    );
  }

  static const _knownKeys = {
    'trashEnabled',
    'historyVersions',
    'quickNotePath',
    'listNoteFolder',
    'templateFolder',
    'pinnedCollapsed',
    'lineNumbers',
    'editorAutofocus',
    'reminderShowTokens',
    'treeSort',
    'linkType',
    'indentWidth',
    'editorToolbar',
    'uiTextScale',
    'noteTextScale',
    'treeWidth',
    'spellDictionary', // Legacy single-dictionary key (read, never written).
    'spellDictionaries',
    'editorKind',
    'enabledEditors',
    'previewEnabled',
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
      'historyVersions': historyVersions,
      'listNoteFolder': listNoteFolder,
      'templateFolder': templateFolder,
      'pinnedCollapsed': pinnedCollapsed,
      'lineNumbers': lineNumbers,
      'editorAutofocus': editorAutofocus,
      'reminderShowTokens': reminderShowTokens,
      'treeSort': treeSort.name,
      'linkType': linkType.name,
      'indentWidth': indentWidth,
      'editorToolbar': editorToolbar,
      'uiTextScale': uiTextScale,
      'noteTextScale': noteTextScale,
      'treeWidth': treeWidth,
      'editorKind': editorKind.name,
      // Canonical order, so the file does not churn when the set is
      // rebuilt insertion-ordered differently.
      'enabledEditors': [
        for (final kind in EditorKind.values)
          if (enabledEditors.contains(kind)) kind.name,
      ],
      'previewEnabled': previewEnabled,
    };
    if (quickNotePath != null) {
      json['quickNotePath'] = quickNotePath;
    }
    if (spellDictionaries.isNotEmpty) {
      json['spellDictionaries'] = spellDictionaries;
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
        historyVersions == other.historyVersions &&
        quickNotePath == other.quickNotePath &&
        listNoteFolder == other.listNoteFolder &&
        templateFolder == other.templateFolder &&
        pinnedCollapsed == other.pinnedCollapsed &&
        lineNumbers == other.lineNumbers &&
        editorAutofocus == other.editorAutofocus &&
        reminderShowTokens == other.reminderShowTokens &&
        treeSort == other.treeSort &&
        linkType == other.linkType &&
        indentWidth == other.indentWidth &&
        editorToolbar == other.editorToolbar &&
        uiTextScale == other.uiTextScale &&
        noteTextScale == other.noteTextScale &&
        treeWidth == other.treeWidth &&
        _deepEquals(spellDictionaries, other.spellDictionaries) &&
        editorKind == other.editorKind &&
        enabledEditors.length == other.enabledEditors.length &&
        enabledEditors.containsAll(other.enabledEditors) &&
        previewEnabled == other.previewEnabled &&
        _deepEquals(extra, other.extra);
  }

  /// Hashed over [toJsonMap], which is the same filtered view `==`
  /// compares. The spread this replaced had the shadowing problem too: a
  /// known key in [extra] displaced the typed field it duplicates, so two
  /// configs that compare equal could hash differently.
  @override
  int get hashCode => _stableHash(toJsonMap());
}

/// The reader/writer for one library's `.copist/settings.json`.
///
/// Reading a missing, unreadable or malformed file yields
/// [LibraryConfig.defaults] rather than throwing: the settings file is
/// user-editable and must never take the app down. Writing is atomic
/// (temp file + rename, same as a note), so a reader never observes a
/// partial write.
final class LibraryConfigStore {
  /// Creates a store for the library at its absolute path.
  new(this._libraryPath);

  final String _libraryPath;

  /// The settings file: `<library>/.copist/settings.json`.
  File get file => File(p.join(_libraryPath, '.copist', 'settings.json'));

  /// Reads the library's settings; defaults when the file is missing,
  /// unreadable or malformed.
  Future<LibraryConfig> read() async {
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return LibraryConfig.defaults;
      }
      // jsonDecode yields `Map<String, dynamic>`; bridge to the typed view.
      final json = <String, Object?>{
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
      return LibraryConfig.fromJsonMap(json);
    } on Object catch (_) {
      return LibraryConfig.defaults;
    }
  }

  /// Writes [config] atomically, creating the `.copist/` folder if needed.
  Future<void> write(LibraryConfig config) async {
    await file.parent.create(recursive: true);
    final text = const JsonEncoder.withIndent('  ').convert(config.toJsonMap());
    await writeFileAtomically(file, utf8.encode('$text\n'));
  }
}
