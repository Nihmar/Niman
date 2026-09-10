import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:copist/src/core/language.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/core/theme.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/spellcheck/editor_spell_check.dart';
import 'package:copist/src/spellcheck/hunspell_spell_checker.dart';
import 'package:copist/src/ui/folder_picker.dart';
import 'package:copist/src/ui/keyboard_shortcuts.dart';
import 'package:copist/src/ui/note_picker.dart';
import 'package:copist/src/ui/settings_rows.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/switch_library_screen.dart';
import 'package:copist/src/ui/template_help.dart';
import 'package:copist/src/ui/toolbar_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Library-level settings (M1: trash toggle, re-index, close).
///
/// Global theme/layout settings arrive with the M6 token system.
///
/// The settings content, embedded as the Settings tab (bottom bar on
/// narrow, rail on wide).
final class SettingsBody extends StatefulWidget {
  /// Creates the settings body.
  const new({
    required this.controller,
    this.onClosed,
    this.spellCheck,
    super.key,
  });

  /// The session of the library whose settings this body edits.
  final LibrarySession controller;

  /// The editor's spelling state (T-PP-09), for its toggle; null hides it.
  final EditorSpellCheck? spellCheck;

  /// Called after "Close library" closes the session; the pushed screen
  /// pops its own route, the shell tab returns to the Files tab. When null
  /// the caller must handle closing the screen itself.
  final VoidCallback? onClosed;

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

final class _SettingsBodyState extends State<SettingsBody> {
  bool? _trash;
  bool? _debugLogs;
  bool? _lineNumbers;
  bool? _autofocusEditor;
  bool? _reminderShowTokens;
  PreviewLayoutMode _previewMode = PreviewLayoutMode.auto;
  double _splitRatio = defaultSplitRatio;
  bool _splitLoaded = false;
  LinkType _linkType = LinkType.wikilink;
  int _indentWidth = 2;
  String? _quickNotePath;
  String? _listFolder;
  String? _templateFolder;
  AppLanguage _language = AppLanguage.system;
  AppBrightness _themeBrightness = AppBrightness.system;
  AppPalette _themePalette = AppPalette.system;
  double _uiTextScale = defaultTextScale;
  double _noteTextScale = defaultTextScale;

  /// Steps of 5% between [minTextScale] and [maxTextScale]: fine enough
  /// to land on a size that fits, coarse enough to be hit on a phone.
  static final int _textScaleSteps = ((maxTextScale - minTextScale) * 20)
      .round();
  List<String> _spellDictionaries = const <String>[];
  EditorKind _editorKind = EditorKind.source;
  bool _previewEnabled = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final controller = widget.controller;
    final ops = controller.ops;
    if (ops == null) return;
    final enabled = await ops.trashEnabled;
    final debug = await controller.debugLogsEnabled;
    final lineNumbers = await controller.lineNumbersEnabled;
    final autofocus = await controller.editorAutofocusEnabled;
    final reminderTokens = await controller.reminderShowTokens;
    final previewMode = await controller.previewMode;
    final splitRatio = await controller.splitRatio;
    final linkType = await controller.linkType;
    final indentWidth = await controller.indentWidth;
    final quickNotePath = await ops.quickNotePath;
    final listFolder = await ops.listNoteFolder;
    final templateFolder = await ops.templateFolder;
    final language = await controller.language;
    final themeBrightness = await controller.themeBrightness;
    final themePalette = await controller.themePalette;
    final uiTextScale = await controller.uiTextScale;
    final noteTextScale = await controller.noteTextScale;
    final spellDictionaries = await controller.spellDictionaries;
    final editorKind = await controller.editorKind;
    final previewEnabled = await controller.previewEnabled;
    if (mounted) {
      setState(() {
        _trash = enabled;
        _debugLogs = debug;
        _lineNumbers = lineNumbers;
        _autofocusEditor = autofocus;
        _reminderShowTokens = reminderTokens;
        _previewMode = previewMode;
        _splitRatio = splitRatio;
        _splitLoaded = true;
        _linkType = linkType;
        _indentWidth = indentWidth;
        _quickNotePath = quickNotePath;
        _listFolder = listFolder;
        _templateFolder = templateFolder;
        _language = language;
        _themeBrightness = themeBrightness;
        _themePalette = themePalette;
        _uiTextScale = uiTextScale;
        _noteTextScale = noteTextScale;
        _spellDictionaries = spellDictionaries;
        _editorKind = editorKind;
        _previewEnabled = previewEnabled;
      });
    }
  }

  /// Persists the UI language and applies it immediately (T-L10N-04):
  /// the app root listens to [AppLanguages] and rebuilds every screen.
  Future<void> _setLanguage(AppLanguage language) async {
    await widget.controller.setLanguage(language);
    AppLanguages.choice = language;
    if (mounted) {
      setState(() => _language = language);
    }
  }

  /// Persists the brightness and applies it immediately (T-M6-05): the
  /// app root listens to [AppThemes] and rebuilds every screen.
  Future<void> _setThemeBrightness(AppBrightness brightness) async {
    await widget.controller.setThemeBrightness(brightness);
    AppThemes.brightness = brightness;
    if (mounted) {
      setState(() => _themeBrightness = brightness);
    }
  }

  /// Persists the palette and applies it immediately.
  Future<void> _setThemePalette(AppPalette palette) async {
    await widget.controller.setThemePalette(palette);
    AppThemes.palette = palette;
    if (mounted) {
      setState(() => _themePalette = palette);
    }
  }

  /// Opens the list-folder picker (T-TK-06): the folder new list notes
  /// are created in, chosen from the library's folders rather than
  /// typed.
  Future<void> _pickListFolder() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    final folder = await showFolderPicker(
      context,
      title: AppStrings.listFolderTitle,
      folders: folders,
      ops: ops,
      current: _listFolder ?? defaultListFolder,
    );
    if (folder == null) return;
    await ops.setListNoteFolder(folder: folder);
    final saved = await ops.listNoteFolder;
    widget.controller.notify();
    if (mounted) {
      setState(() => _listFolder = saved);
    }
  }

  /// Opens the template-folder picker (T-M4-05): where the note
  /// templates live, chosen from the library's folders rather than
  /// typed.
  Future<void> _pickTemplateFolder() async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    final folders = await widget.controller.folders();
    if (!mounted) return;
    final folder = await showFolderPicker(
      context,
      title: AppStrings.templateFolderTitle,
      folders: folders,
      ops: ops,
      current: _templateFolder ?? defaultTemplateFolder,
    );
    if (folder == null) return;
    await ops.setTemplateFolder(folder: folder);
    final saved = await ops.templateFolder;
    widget.controller.notify();
    if (mounted) {
      setState(() => _templateFolder = saved);
    }
  }

  /// Opens the quick-note picker (the chosen note is set from the tree
  /// dialog); the shell picks the value up through the session.
  Future<void> _pickQuickNote() async {
    final oldPath = _quickNotePath;
    final changed = await showQuickNotePicker(
      context,
      controller: widget.controller,
      currentPath: oldPath,
    );
    if (!changed || !mounted) return;
    final path = await widget.controller.ops?.quickNotePath;
    widget.controller.notify();
    if (mounted) {
      setState(() => _quickNotePath = path);
    }
  }

  Future<void> _toggleTrash(bool value) async {
    final ops = widget.controller.ops;
    if (ops == null) return;
    await ops.setTrashEnabled(enabled: value);
    widget.controller.notify();
    if (mounted) {
      setState(() => _trash = value);
    }
  }

  Future<void> _toggleDebugLogs(bool value) async {
    final controller = widget.controller;
    await controller.setDebugLogsEnabled(enabled: value);
    if (mounted) {
      setState(() => _debugLogs = value);
    }
  }

  Future<void> _toggleLineNumbers(bool value) async {
    final controller = widget.controller;
    await controller.setLineNumbersEnabled(enabled: value);
    // Notify so the shell refreshes its cached value — an open editor
    // shows/hides the column without reopening the note.
    controller.notify();
    if (mounted) {
      setState(() => _lineNumbers = value);
    }
  }

  Future<void> _toggleAutofocusEditor(bool value) async {
    final controller = widget.controller;
    await controller.setEditorAutofocusEnabled(enabled: value);
    // Notify so the shell picks the value up; the next opened note
    // focuses (an already-open note keeps its current keyboard state).
    controller.notify();
    if (mounted) {
      setState(() => _autofocusEditor = value);
    }
  }

  /// Persists the reminder-markers toggle.
  ///
  /// Takes effect on the next reconciliation, which the shell triggers on
  /// the way back from here (a settings change bumps the session, and any
  /// resume resyncs), so already-scheduled alarms pick up the new text.
  Future<void> _toggleReminderTokens(bool value) async {
    final controller = widget.controller;
    await controller.setReminderShowTokens(enabled: value);
    controller.notify();
    if (mounted) {
      setState(() => _reminderShowTokens = value);
    }
  }

  Future<void> _setSplitRatio(double ratio) async {
    final controller = widget.controller;
    await controller.setSplitRatio(ratio);
    controller.notify();
    if (mounted) {
      setState(() => _splitRatio = ratio);
    }
  }

  Future<void> _setLinkType(LinkType type) async {
    final controller = widget.controller;
    await controller.setLinkType(type);
    controller.notify();
    if (mounted) {
      setState(() => _linkType = type);
    }
  }

  Future<void> _setIndentWidth(int width) async {
    final controller = widget.controller;
    await controller.setIndentWidth(width);
    controller.notify();
    if (mounted) {
      setState(() => _indentWidth = width);
    }
  }

  Future<void> _rescan() async {
    try {
      await widget.controller.rescanNow();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppStrings.reindexDone)));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  /// Opens a save dialog letting the user choose where the debug log goes,
  /// and writes the buffered lines (+ a context header) to the chosen file.
  Future<void> _exportLog() async {
    final controller = widget.controller;
    // Earlier runs first: the disk mirror holds what the process before
    // this one recorded (a reminder firing with the app closed, an OEM
    // kill), which the in-memory buffer can never have.
    //
    // The two overlap: reading the mirror flushes it, so everything this
    // run has logged since the file was attached is in BOTH. Keep only
    // the memory lines the mirror does not already carry -- in practice
    // the handful recorded before the attach landed. Timestamps run to
    // the millisecond, so identical lines are the same event.
    final persisted = await AppLog.file?.read() ?? '';
    final onDisk = persisted.split('\n').toSet();
    final lines = <String>[
      for (final line in AppLog.lines())
        if (!onDisk.contains(line)) line,
    ];
    if (lines.isEmpty && persisted.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppStrings.exportLogEmpty)));
      }
      return;
    }
    final now = DateTime.now();
    final stamp = _fileStamp(now);
    final phase =
        'phase: ${controller.phase.name}, '
        'lastError: ${controller.lastError ?? '-'}';
    final content = <String>[
      '# Copist debug log',
      '# exported: ${now.toIso8601String()}',
      '# library: ${controller.root ?? '(none)'}',
      '# $phase',
      '',
      if (persisted.isNotEmpty) persisted.trimRight(),
      if (persisted.isNotEmpty && lines.isNotEmpty) '# --- not yet on disk ---',
      ...lines,
    ].join('\n');
    try {
      final uri = await FilePicker.saveFile(
        fileName: 'copist-debug-log-$stamp.txt',
        bytes: Uint8List.fromList(utf8.encode(content)),
        mimeType: 'text/plain',
        dialogTitle: AppStrings.exportLogTitle,
      );
      if (uri == null) return; // The user canceled; nothing to report.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.exportLogDone(uri))));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.exportLogFailed(error))),
        );
      }
    }
  }

  static String _fileStamp(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}'
        '-${two(dt.day)}-${two(dt.hour)}${two(dt.minute)}${two(dt.second)}'
        '.${three(dt.millisecond)}';
  }

  Future<void> _chooseSplitRatio() async {
    final ratio = await showSettingsSlider(
      context,
      dialogKey: const Key('split-ratio-dialog'),
      title: AppStrings.splitRatioTitle,
      subtitle: AppStrings.splitRatioSubtitle,
      current: _splitRatio,
      min: minSplitRatio,
      max: maxSplitRatio,
      format: AppStrings.splitRatioValue,
    );
    if (ratio != null) await _setSplitRatio(ratio);
  }

  /// Asks how large the interface text should be.
  Future<void> _chooseUiTextScale() async {
    final scale = await showSettingsSlider(
      context,
      dialogKey: const Key('ui-text-scale-dialog'),
      sliderKey: const Key('ui-text-scale-slider'),
      title: AppStrings.uiTextScaleTitle,
      subtitle: AppStrings.uiTextScaleSubtitle,
      current: _uiTextScale,
      min: minTextScale,
      max: maxTextScale,
      divisions: _textScaleSteps,
      format: AppStrings.textScaleValue,
    );
    if (scale == null) return;
    await widget.controller.setUiTextScale(scale);
    if (mounted) setState(() => _uiTextScale = scale);
  }

  /// Asks how large the note text should be, in both panes.
  Future<void> _chooseNoteTextScale() async {
    final scale = await showSettingsSlider(
      context,
      dialogKey: const Key('note-text-scale-dialog'),
      sliderKey: const Key('note-text-scale-slider'),
      title: AppStrings.noteTextScaleTitle,
      subtitle: AppStrings.noteTextScaleSubtitle,
      current: _noteTextScale,
      min: minTextScale,
      max: maxTextScale,
      divisions: _textScaleSteps,
      format: AppStrings.textScaleValue,
    );
    if (scale == null) return;
    await widget.controller.setNoteTextScale(scale);
    if (mounted) setState(() => _noteTextScale = scale);
  }

  /// Asks for the link format the editor's link button inserts.
  Future<void> _chooseLinkType() async {
    final type = await showSettingsChoice<LinkType>(
      context,
      dialogKey: const Key('link-type-dialog'),
      title: AppStrings.linkTypeTitle,
      subtitle: AppStrings.linkTypeSubtitle,
      current: _linkType,
      options: [
        SettingsOption(LinkType.wikilink, AppStrings.linkTypeWikilink),
        SettingsOption(LinkType.markdown, AppStrings.linkTypeMarkdown),
      ],
    );
    if (type != null) await _setLinkType(type);
  }

  /// Asks for the spaces added per indent level.
  Future<void> _chooseIndentWidth() async {
    final width = await showSettingsChoice<int>(
      context,
      dialogKey: const Key('indent-width-dialog'),
      title: AppStrings.indentWidthTitle,
      subtitle: AppStrings.indentWidthSubtitle,
      current: _indentWidth,
      options: [
        for (final spaces in const [2, 4, 6, 8])
          SettingsOption(spaces, AppStrings.indentWidthValue(spaces)),
      ],
    );
    if (width != null) await _setIndentWidth(width);
  }

  /// Asks which editor the library writes in (T-WYS-03).
  Future<void> _chooseEditorKind() async {
    final kind = await showSettingsChoice<EditorKind>(
      context,
      dialogKey: const Key('editor-kind-dialog'),
      title: AppStrings.settingsEditorKindTitle,
      subtitle: AppStrings.settingsEditorKindSubtitle,
      current: _editorKind,
      options: [
        SettingsOption(EditorKind.source, AppStrings.editorKindSource),
        SettingsOption(EditorKind.wysiwyg, AppStrings.editorKindWysiwyg),
      ],
    );
    if (kind == null) return;
    await widget.controller.setEditorKind(kind);
    if (mounted) setState(() => _editorKind = kind);
  }

  /// Persists the preview switch (T-WYS-03).
  Future<void> _togglePreviewEnabled(bool value) async {
    await widget.controller.setPreviewEnabled(enabled: value);
    if (mounted) setState(() => _previewEnabled = value);
  }

  /// Asks which hunspell dictionaries the editor should use (T-PP-09,
  /// revised): every one found on the machine, any number of them at once.
  /// Choosing none means the locale default.
  Future<void> _chooseSpellDictionaries(EditorSpellCheck spell) async {
    final names = discoverDictionaries().keys.toList()..sort();
    final selected = _spellDictionaries.toSet();
    final choice = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('spell-dictionary-dialog'),
        scrollable: true,
        title: Text(AppStrings.spellCheckDictionaryChoiceTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.spellCheckDictionaryChoiceSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (names.isEmpty)
              Text(AppStrings.spellCheckNoDictionaries)
            else
              StatefulBuilder(
                builder: (context, setDialogState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final name in names)
                      CheckboxListTile(
                        key: Key('spell-dictionary-$name'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(name),
                        value: selected.contains(name),
                        onChanged: (value) => setDialogState(() {
                          if (value ?? false) {
                            selected.add(name);
                          } else {
                            selected.remove(name);
                          }
                        }),
                      ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('spell-dictionary-cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: const Key('spell-dictionary-save'),
            onPressed: () =>
                Navigator.of(context)
                    .pop(names.where(selected.contains).toList()),
            child: Text(AppStrings.actionSave),
          ),
        ],
      ),
    );
    if (choice == null) return;
    await widget.controller.setSpellDictionaries(choice);
    spell.setDictionaries(choice);
    if (mounted) setState(() => _spellDictionaries = choice);
  }

  /// Asks for the app's language.
  Future<void> _chooseLanguage() async {
    final language = await showSettingsChoice<AppLanguage>(
      context,
      dialogKey: const Key('language-dialog'),
      title: AppStrings.languageTitle,
      subtitle: AppStrings.languageSubtitle,
      current: _language,
      options: [
        SettingsOption(AppLanguage.system, AppStrings.languageSystem),
        SettingsOption(AppLanguage.english, AppStrings.languageEnglish),
        SettingsOption(AppLanguage.italian, AppStrings.languageItalian),
      ],
    );
    if (language != null) await _setLanguage(language);
  }

  /// Asks how bright the app should be.
  Future<void> _chooseThemeBrightness() async {
    final brightness = await showSettingsChoice<AppBrightness>(
      context,
      dialogKey: const Key('theme-brightness-dialog'),
      title: AppStrings.themeBrightnessTitle,
      subtitle: AppStrings.themeBrightnessSubtitle,
      current: _themeBrightness,
      options: [
        SettingsOption(AppBrightness.system, AppStrings.themeBrightnessSystem),
        SettingsOption(AppBrightness.day, AppStrings.themeBrightnessDay),
        SettingsOption(AppBrightness.night, AppStrings.themeBrightnessNight),
      ],
    );
    if (brightness != null) await _setThemeBrightness(brightness);
  }

  /// Asks which palette the app wears.
  Future<void> _chooseThemePalette() async {
    final palette = await showSettingsChoice<AppPalette>(
      context,
      dialogKey: const Key('theme-palette-dialog'),
      title: AppStrings.themePaletteTitle,
      subtitle: AppStrings.themePaletteSubtitle,
      current: _themePalette,
      options: [
        for (final palette in AppPalette.values)
          SettingsOption(palette, _paletteName(palette)),
      ],
    );
    if (palette != null) await _setThemePalette(palette);
  }

  /// What a palette reads as, in the dialog and on the row.
  static String _paletteName(AppPalette palette) => switch (palette) {
    AppPalette.system => AppStrings.themePaletteSystem,
    AppPalette.catppuccin => AppStrings.themePaletteCatppuccin,
    AppPalette.solarized => AppStrings.themePaletteSolarized,
    AppPalette.gruvbox => AppStrings.themePaletteGruvbox,
  };

  /// Opens the known-library list and switches to whatever is picked
  /// (T-ML-06).
  ///
  /// The switch tears down the shell this screen is part of, so the
  /// settings screen leaves with it: `onClosed` is the same exit "Close
  /// library" takes, and the tab case falls back to popping the pushed
  /// route.
  Future<void> _switchLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SwitchLibraryScreen(
          controller: widget.controller,
          onSwitched: () {
            Navigator.of(context).pop();
            widget.onClosed?.call();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final narrow = MediaQuery.sizeOf(context).width < splitBreakpoint;
    final spell = widget.spellCheck;
    // Grouped, and every setting one row of the same height (2026-09-08
    // user feedback). Switches stay switches; everything with more than
    // two choices reads its value on the right and opens a dialog, which
    // is also where its explanation went.
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        SettingsSection(AppStrings.settingsSectionAppearance),
        SettingsValueRow(
          key: const Key('language-choice'),
          title: AppStrings.languageTitle,
          value: switch (_language) {
            AppLanguage.system => AppStrings.languageSystem,
            AppLanguage.english => AppStrings.languageEnglish,
            AppLanguage.italian => AppStrings.languageItalian,
          },
          onTap: () => unawaited(_chooseLanguage()),
        ),
        SettingsValueRow(
          key: const Key('theme-brightness-setting'),
          title: AppStrings.themeBrightnessTitle,
          value: switch (_themeBrightness) {
            AppBrightness.system => AppStrings.themeBrightnessSystem,
            AppBrightness.day => AppStrings.themeBrightnessDay,
            AppBrightness.night => AppStrings.themeBrightnessNight,
          },
          onTap: () => unawaited(_chooseThemeBrightness()),
        ),
        SettingsValueRow(
          key: const Key('theme-palette-setting'),
          title: AppStrings.themePaletteTitle,
          value: _paletteName(_themePalette),
          onTap: () => unawaited(_chooseThemePalette()),
        ),
        SettingsValueRow(
          key: const Key('ui-text-scale-setting'),
          title: AppStrings.uiTextScaleTitle,
          value: AppStrings.textScaleValue(_uiTextScale),
          onTap: () => unawaited(_chooseUiTextScale()),
        ),
        // The split ratio stays here; the split/switch choice itself
        // lives in the editor's app bar (user, 2026-09-09): a layout a
        // narrow screen cannot have is not a global setting.
        if (_splitLoaded &&
            previewSplits(
              _previewMode,
              narrow: narrow,
              editor: _editorKind,
              previewEnabled: _previewEnabled,
            ))
          SettingsValueRow(
            key: const Key('split-ratio-setting'),
            title: AppStrings.splitRatioTitle,
            value: AppStrings.splitRatioValue(_splitRatio),
            onTap: () => unawaited(_chooseSplitRatio()),
          ),

        SettingsSection(AppStrings.settingsSectionEditor),
        // The toolbar is an editor setting, not an appearance one: it
        // decides what the editor can do, not how the app looks.
        SettingsValueRow(
          key: const Key('toolbar-setting'),
          title: AppStrings.toolbarSettingsTitle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) =>
                  ToolbarSettingsScreen(controller: widget.controller),
            ),
          ),
        ),
        SettingsValueRow(
          key: const Key('editor-kind-setting'),
          title: AppStrings.settingsEditorKindTitle,
          subtitle: AppStrings.settingsEditorKindSubtitle,
          value: _editorKind == EditorKind.wysiwyg
              ? AppStrings.editorKindWysiwyg
              : AppStrings.editorKindSource,
          onTap: () => unawaited(_chooseEditorKind()),
        ),
        SwitchListTile(
          key: const Key('preview-enabled-setting'),
          title: Text(AppStrings.settingsPreviewEnabledTitle),
          subtitle: Text(AppStrings.settingsPreviewEnabledSubtitle),
          value: _previewEnabled,
          onChanged: _togglePreviewEnabled,
        ),
        // Switches keep their subtitle: a switch has no dialog to move
        // the explanation into, and "off = on first tap" is exactly what
        // someone reads the row for.
        SwitchListTile(
          title: Text(AppStrings.lineNumbersTitle),
          subtitle: Text(AppStrings.lineNumbersSubtitle),
          value: _lineNumbers ?? true,
          onChanged: _toggleLineNumbers,
        ),
        // Phones and tablets only: there is no on-screen keyboard to
        // show on desktop, so the row would toggle a no-op (user,
        // 2026-09-09).
        if (Platform.isAndroid || Platform.isIOS)
          SwitchListTile(
            title: Text(AppStrings.keyboardOnOpenTitle),
            subtitle: Text(AppStrings.keyboardOnOpenSubtitle),
            value: _autofocusEditor ?? false,
            onChanged: _toggleAutofocusEditor,
          ),
        SettingsValueRow(
          key: const Key('link-type'),
          title: AppStrings.linkTypeTitle,
          value: switch (_linkType) {
            LinkType.wikilink => AppStrings.linkTypeWikilink,
            LinkType.markdown => AppStrings.linkTypeMarkdown,
          },
          onTap: () => unawaited(_chooseLinkType()),
        ),
        SettingsValueRow(
          key: const Key('note-text-scale-setting'),
          title: AppStrings.noteTextScaleTitle,
          value: AppStrings.textScaleValue(_noteTextScale),
          onTap: () => unawaited(_chooseNoteTextScale()),
        ),
        SettingsValueRow(
          key: const Key('indent-width'),
          title: AppStrings.indentWidthTitle,
          value: AppStrings.indentWidthValue(_indentWidth),
          onTap: () => unawaited(_chooseIndentWidth()),
        ),

        SettingsSection(AppStrings.settingsSectionShortcuts),
        SettingsValueRow(
          key: const Key('keyboard-shortcuts-setting'),
          title: AppStrings.keyboardShortcutsTitle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const KeyboardShortcutsScreen(),
            ),
          ),
        ),

        if (spell != null && spell.available) ...[
          SwitchListTile(
            key: const Key('spell-check-setting'),
            title: Text(AppStrings.settingsSpellCheckTitle),
            subtitle: Text(AppStrings.settingsSpellCheckSubtitle),
            value: spell.enabled,
            onChanged: (value) =>
                setState(() => spell.setEnabled(enabled: value)),
          ),
          SettingsValueRow(
            key: const Key('spell-dictionary-setting'),
            title: AppStrings.spellCheckDictionaryTitle,
            value: _spellDictionaries.isEmpty
                ? AppStrings.spellCheckDictionarySystem
                : _spellDictionaries.join(', '),
            onTap: () => unawaited(_chooseSpellDictionaries(spell)),
          ),
        ],

        SettingsSection(AppStrings.settingsSectionLibrary),
        // The one row with nothing to change: a fact about the open
        // library, kept here because this is where you go looking for it.
        ListTile(
          key: const Key('library-path'),
          title: Text(AppStrings.libraryPathTitle),
          subtitle: Text(controller.root ?? ''),
        ),
        SettingsValueRow(
          key: const Key('quick-note-setting'),
          title: AppStrings.quickNoteTitle,
          value: _quickNotePath ?? AppStrings.quickNoteUnset,
          onTap: _pickQuickNote,
        ),
        SettingsValueRow(
          key: const Key('list-folder-setting'),
          title: AppStrings.listFolderTitle,
          value: _listFolder ?? defaultListFolder,
          onTap: _pickListFolder,
        ),
        SettingsValueRow(
          key: const Key('template-folder-setting'),
          title: AppStrings.templateFolderTitle,
          value: _templateFolder ?? defaultTemplateFolder,
          onTap: _pickTemplateFolder,
        ),
        // Next to the folder, because that is where someone setting
        // templates up is already standing (T-TPL-08).
        SettingsValueRow(
          key: const Key('template-help-setting'),
          title: AppStrings.templateHelpTitle,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const TemplateHelpScreen(),
            ),
          ),
        ),
        SwitchListTile(
          key: const Key('trash-setting'),
          title: Text(AppStrings.trashTitle),
          subtitle: Text(AppStrings.trashSubtitle),
          value: _trash ?? true,
          onChanged: _toggleTrash,
        ),
        ListTile(
          key: const Key('reindex-setting'),
          leading: const Icon(Icons.refresh),
          title: Text(AppStrings.reindexTitle),
          onTap: _rescan,
        ),
        // Above "Close library" on purpose: switching is the common move
        // and closing is the way out of every library at once.
        SettingsValueRow(
          key: const Key('switch-library-setting'),
          title: AppStrings.switchLibraryTitle,
          onTap: _switchLibrary,
        ),
        ListTile(
          key: const Key('close-library-setting'),
          leading: const Icon(Icons.link_off),
          title: Text(AppStrings.closeLibraryTitle),
          onTap: () async {
            await controller.close();
            widget.onClosed?.call();
          },
        ),

        SettingsSection(AppStrings.settingsSectionReminders),
        SwitchListTile(
          key: const Key('reminder-show-tokens'),
          title: Text(AppStrings.reminderShowTokensTitle),
          subtitle: Text(AppStrings.reminderShowTokensSubtitle),
          value: _reminderShowTokens ?? false,
          onChanged: _toggleReminderTokens,
        ),

        SettingsSection(AppStrings.settingsSectionDiagnostics),
        SwitchListTile(
          title: Text(AppStrings.debugLogsTitle),
          subtitle: Text(AppStrings.debugLogsSubtitle),
          value: _debugLogs ?? true,
          onChanged: _toggleDebugLogs,
        ),
        ListTile(
          key: const Key('export-log-setting'),
          leading: const Icon(Icons.save_alt),
          title: Text(AppStrings.exportLogTitle),
          subtitle: Text(AppStrings.exportLogSubtitle),
          onTap: _exportLog,
        ),
      ],
    );
  }
}
