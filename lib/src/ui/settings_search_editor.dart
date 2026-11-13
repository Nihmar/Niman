import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/lint/lint_rule.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/strings.dart';

/// The settings search's rows of Editor (#104), in the order the search
/// lists them.
List<SettingsSearchEntry> editorSearchEntries(SettingsSearchScope scope) {
  final settings = scope.controller.librarySettings;
  void pushEditor(Key row) => scope.openArea(SettingsAreaId.editor, row);
  final editor = AppStrings.settingsSectionEditor;
  return [
    SettingsSearchEntry(
      title: AppStrings.toolbarSettingsTitle,
      area: editor,
      rowKey: SettingsKeys.toolbar,
      value: scope.noValue,
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.toolbar),
    ),
    SettingsSearchEntry(
      title: AppStrings.editorKindSource,
      area: editor,
      rowKey: SettingsKeys.editorSource,
      value: () async => scope.onOff(
        on: (await settings.enabledEditors).contains(EditorKind.source),
      ),
      open: () => pushEditor(SettingsKeys.editorSource),
    ),
    SettingsSearchEntry(
      title: AppStrings.editorKindWysiwyg,
      area: editor,
      rowKey: SettingsKeys.editorWysiwyg,
      value: () async => scope.onOff(
        on: (await settings.enabledEditors).contains(EditorKind.wysiwyg),
      ),
      open: () => pushEditor(SettingsKeys.editorWysiwyg),
    ),
    SettingsSearchEntry(
      title: AppStrings.lineNumbersTitle,
      area: editor,
      rowKey: SettingsKeys.lineNumbers,
      value: () async => scope.onOff(on: await settings.lineNumbersEnabled),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.lineNumbers),
    ),
    SettingsSearchEntry(
      title: AppStrings.readableLineLengthTitle,
      area: editor,
      rowKey: SettingsKeys.readableLineLength,
      value: () async => scope.onOff(on: await settings.readableLineLength),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.readableLineLength),
    ),
    SettingsSearchEntry(
      title: AppStrings.noteColumnWidthTitle,
      area: editor,
      rowKey: SettingsKeys.noteColumnWidth,
      value: () async =>
          AppStrings.noteColumnWidthValue(await settings.noteColumnWidth),
      open: () => pushEditor(SettingsKeys.noteColumnWidth),
    ),
    SettingsSearchEntry(
      title: AppStrings.typewriterTitle,
      area: editor,
      rowKey: SettingsKeys.typewriter,
      value: () async => scope.onOff(on: await settings.typewriter),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.typewriter),
    ),
    SettingsSearchEntry(
      title: AppStrings.cascadeChecklistTitle,
      area: editor,
      rowKey: SettingsKeys.cascadeChecklist,
      value: () async => scope.onOff(on: await settings.cascadeChecklist),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.cascadeChecklist),
    ),
    SettingsSearchEntry(
      title: AppStrings.linkPreviewTitle,
      area: editor,
      rowKey: SettingsKeys.linkPreview,
      value: () async => scope.onOff(on: await settings.linkPreview),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.linkPreview),
    ),
    SettingsSearchEntry(
      title: AppStrings.linkTypeTitle,
      area: editor,
      rowKey: SettingsKeys.linkType,
      value: () async => switch (await settings.linkType) {
        LinkType.wikilink => AppStrings.linkTypeWikilink,
        LinkType.markdown => AppStrings.linkTypeMarkdown,
      },
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.linkType),
    ),
    SettingsSearchEntry(
      title: AppStrings.linkUpdateTitle,
      area: editor,
      rowKey: SettingsKeys.linkUpdate,
      value: () async => switch (await settings.linkUpdate) {
        LinkUpdate.automatic => AppStrings.linkUpdateAutomatic,
        LinkUpdate.ask => AppStrings.linkUpdateAsk,
        LinkUpdate.never => AppStrings.linkUpdateNever,
      },
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.linkUpdate),
    ),
    SettingsSearchEntry(
      title: AppStrings.newItemLocationTitle,
      area: editor,
      rowKey: SettingsKeys.newItemLocation,
      value: () async => switch (await settings.newItemLocation) {
        NewItemLocation.libraryRoot => AppStrings.newItemLocationRoot,
        NewItemLocation.openNoteFolder => AppStrings.newItemLocationOpenNote,
      },
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.newItemLocation),
    ),
    SettingsSearchEntry(
      title: AppStrings.noteTextScaleTitle,
      area: editor,
      rowKey: SettingsKeys.noteTextScale,
      value: () async =>
          AppStrings.textScaleValue(await settings.noteTextScale),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.noteTextScale),
    ),
    SettingsSearchEntry(
      title: AppStrings.sourceFontTitle,
      area: editor,
      rowKey: SettingsKeys.sourceFont,
      value: () async => switch (await settings.sourceFont) {
        SourceFont.monospace => AppStrings.sourceFontMonospace,
        SourceFont.sansSerif => AppStrings.sourceFontSansSerif,
        SourceFont.serif => AppStrings.sourceFontSerif,
      },
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.sourceFont),
    ),
    SettingsSearchEntry(
      title: AppStrings.indentWidthTitle,
      area: editor,
      rowKey: SettingsKeys.indentWidth,
      value: () async =>
          AppStrings.indentWidthValue(await settings.indentWidth),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.indentWidth),
    ),
    SettingsSearchEntry(
      title: AppStrings.tidyOnCloseTitle,
      area: editor,
      rowKey: SettingsKeys.tidyOnClose,
      value: () async => scope.onOff(on: await settings.tidyOnClose),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.tidyOnClose),
    ),
    SettingsSearchEntry(
      title: AppStrings.lintRulesTitle,
      area: editor,
      rowKey: SettingsKeys.lintRules,
      value: () async {
        final off = await settings.lintRulesOff;
        return AppStrings.lintRulesValue(
          LintRule.values.length - off.length,
          LintRule.values.length,
        );
      },
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.lintRules),
    ),
  ];
}
