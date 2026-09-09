import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:copist/src/core/language.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/folder_picker.dart';
import 'package:copist/src/ui/quick_note_picker.dart';
import 'package:copist/src/ui/settings_rows.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/toolbar_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Library-level settings (M1: trash toggle, re-index, close).
///
/// Global theme/layout settings arrive with the M6 token system.
final class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const new({required this.controller, super.key});

  /// The session of the library whose settings this screen edits.
  final LibrarySession controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settingsTitle)),
      body: SettingsBody(
        controller: controller,
        onClosed: () {
          // The pushed screen returns to the shell (which then re-renders
          // into the open-library screen since the session is closed).
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// The settings content: the same list is shown pushed (wide app-bar
/// button) and embedded as the bottom-nav Settings tab (T-UI-02).
final class SettingsBody extends StatefulWidget {
  /// Creates the settings body.
  const new({required this.controller, this.onClosed, super.key});

  /// The session of the library whose settings this body edits.
  final LibrarySession controller;

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
  AppLanguage _language = AppLanguage.system;

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
    final language = await controller.language;
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
        _language = language;
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

  Future<void> _setPreviewMode(PreviewLayoutMode mode) async {
    final controller = widget.controller;
    await controller.setPreviewMode(mode);
    controller.notify();
    if (mounted) {
      setState(() => _previewMode = mode);
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

  /// Asks for the preview mode.
  Future<void> _choosePreviewMode() async {
    final mode = await showSettingsChoice<PreviewLayoutMode>(
      context,
      dialogKey: const Key('preview-mode-dialog'),
      title: AppStrings.previewModeTitle,
      subtitle: AppStrings.previewModeSubtitle,
      current: _previewMode,
      options: [
        SettingsOption(PreviewLayoutMode.auto, AppStrings.previewModeAuto),
        SettingsOption(PreviewLayoutMode.split, AppStrings.previewModeSplit),
        SettingsOption(
          PreviewLayoutMode.fullScreen,
          AppStrings.previewModeSwitch,
        ),
      ],
    );
    if (mode != null) await _setPreviewMode(mode);
  }

  /// Asks for the editor's share of a side-by-side split.
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
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
          key: const Key('preview-mode-setting'),
          title: AppStrings.previewModeTitle,
          value: switch (_previewMode) {
            PreviewLayoutMode.auto => AppStrings.previewModeAuto,
            PreviewLayoutMode.split => AppStrings.previewModeSplit,
            PreviewLayoutMode.fullScreen => AppStrings.previewModeSwitch,
          },
          onTap: () => unawaited(_choosePreviewMode()),
        ),
        // Only where the two panes actually share a screen (T-CL-05):
        // on a phone in the switch layout this slider moves a number
        // nothing reads. The stored ratio is untouched while it is
        // hidden, so plugging in a monitor brings back the chosen split.
        if (_splitLoaded &&
            previewSplits(
              _previewMode,
              narrow: MediaQuery.sizeOf(context).width < splitBreakpoint,
            ))
          SettingsValueRow(
            key: const Key('split-ratio-setting'),
            title: AppStrings.splitRatioTitle,
            value: AppStrings.splitRatioValue(_splitRatio),
            onTap: () => unawaited(_chooseSplitRatio()),
          ),
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

        SettingsSection(AppStrings.settingsSectionEditor),
        // Switches keep their subtitle: a switch has no dialog to move
        // the explanation into, and "off = on first tap" is exactly what
        // someone reads the row for.
        SwitchListTile(
          title: Text(AppStrings.lineNumbersTitle),
          subtitle: Text(AppStrings.lineNumbersSubtitle),
          value: _lineNumbers ?? true,
          onChanged: _toggleLineNumbers,
        ),
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
          key: const Key('indent-width'),
          title: AppStrings.indentWidthTitle,
          value: AppStrings.indentWidthValue(_indentWidth),
          onTap: () => unawaited(_chooseIndentWidth()),
        ),

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
