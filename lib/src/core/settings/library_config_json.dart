/// How a [LibraryConfig] reads from and writes to its JSON object, the
/// one `.niman/settings.json` holds: the known keys, the readers of the
/// values that need more than a type check, and the migration of the
/// legacy keys.
library;

import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show
        EditorKind,
        LinkType,
        LinkUpdate,
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

/// The keys [LibraryConfig] reads; every other key of the file is kept
/// in [LibraryConfig.extra].
const Set<String> _knownKeys = {
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

/// Parses the raw `settings.json` object into a config: the body of
/// [LibraryConfig.fromJsonMap].
LibraryConfig libraryConfigFromJsonMap(Map<String, Object?> json) {
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
    trashAutoEmptyDays: normalizeTrashAutoEmptyDays(json['trashAutoEmptyDays']),
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

/// The JSON object [config] writes: the body of
/// [LibraryConfig.toJsonMap].
Map<String, Object?> libraryConfigToJsonMap(LibraryConfig config) {
  final json = <String, Object?>{
    'trashEnabled': config.trashEnabled,
    'trashAutoEmptyDays': config.trashAutoEmptyDays,
    'historyVersions': config.historyVersions,
    'historyIntervalMinutes': config.historyIntervalMinutes,
    'listNoteFolder': config.listNoteFolder,
    'templateFolder': config.templateFolder,
    'attachmentsFolder': config.attachmentsFolder,
    'annotationsFolder': config.annotationsFolder,
    'captureFolder': config.captureFolder,
    'highlightColour': config.highlightColour,
    'pinnedCollapsed': config.pinnedCollapsed,
    'lineNumbers': config.lineNumbers,
    'readableLineLength': config.readableLineLength,
    'typewriter': config.typewriter,
    'noteColumnWidth': config.noteColumnWidth,
    'editorAutofocus': config.editorAutofocus,
    'reminderShowTokens': config.reminderShowTokens,
    'tidyOnClose': config.tidyOnClose,
    'deleteCarriesNotes': config.deleteCarriesNotes,
    'cascadeChecklist': config.cascadeChecklist,
    'linkPreview': config.linkPreview,
    'frontmatterPanel': config.frontmatterPanel,
    'treeSort': config.treeSort.name,
    // Sorted, so the file does not churn on a set rebuilt in another
    // order; written even when empty, which is "all open" rather than
    // the default.
    'todoCollapsedSections': config.todoCollapsedSections.toList()..sort(),
    'treeView': config.treeView.name,
    'linkType': config.linkType.name,
    'linkUpdate': config.linkUpdate.name,
    'weekStart': config.weekStart.name,
    'newItemLocation': config.newItemLocation.name,
    'indentWidth': config.indentWidth,
    'newCardsPerDay': config.newCardsPerDay,
    'editorToolbar': config.editorToolbar,
    'uiTextScale': config.uiTextScale,
    'noteTextScale': config.noteTextScale,
    'sourceFont': config.sourceFont.name,
    'treeWidth': config.treeWidth,
    'dockWidth': config.dockWidth,
    'editorKind': config.editorKind.name,
    // Canonical order, so the file does not churn when the set is
    // rebuilt insertion-ordered differently.
    'enabledEditors': [
      for (final kind in EditorKind.values)
        if (config.enabledEditors.contains(kind)) kind.name,
    ],
    ...config.journal.toJson(),
    ...config.epubLook.toJson(),
  };
  if (config.quickNotePath != null) {
    json['quickNotePath'] = config.quickNotePath;
  }
  if (config.spellDictionaries.isNotEmpty) {
    json['spellDictionaries'] = config.spellDictionaries;
  }
  if (config.navigation case final layout?) {
    json['navigation'] = layout.toJson();
  }
  if (config.deviceNavigation case final layout?) {
    json['deviceNavigation'] = layout.toJson();
  }
  if (config.deviceHome case final home?) json['deviceHome'] = home;
  // Only the switches that are off: a library that never opens the
  // screen writes no key, and its file stays as it was.
  final off = config.features.toJson();
  if (off.isNotEmpty) json['features'] = off;
  if (config.featuresReviewed) json['featuresReviewed'] = true;
  if (config.lintRulesOff.isNotEmpty) {
    // Canonical order, so the file does not churn on a set rebuilt
    // insertion-ordered differently.
    json['lintRulesOff'] = [
      for (final rule in LintRule.values)
        if (config.lintRulesOff.contains(rule.id)) rule.id,
    ];
  }
  for (final entry in config.extra.entries) {
    if (_knownKeys.contains(entry.key)) continue;
    json[entry.key] = entry.value;
  }
  return json;
}
