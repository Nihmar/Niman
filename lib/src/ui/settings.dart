import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/ui/name_dialog.dart';
import 'package:copist/src/ui/quick_note_picker.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Library-level settings (M1: trash toggle, re-index, close).
///
/// Global theme/layout settings arrive with the M6 token system.
final class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const SettingsScreen({required this.controller, super.key});

  /// The session of the library whose settings this screen edits.
  final LibrarySession controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
  const SettingsBody({required this.controller, this.onClosed, super.key});

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
      });
    }
  }

  /// Opens the list-folder name dialog (T-TK-06): the folder new list
  /// notes are created in.
  Future<void> _pickListFolder() async {
    final folder = await showNameDialog(
      context,
      title: 'List folder',
      initial: _listFolder ?? 'Lists',
    );
    if (folder == null) return;
    final ops = widget.controller.ops!;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Re-index complete')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The debug log buffer is empty')),
        );
      }
      return;
    }
    final now = DateTime.now();
    final stamp = _fileStamp(now);
    final phase = 'phase: ${controller.phase.name}, '
        'lastError: ${controller.lastError ?? '-'}';
    final content = <String>[
      '# Copist debug log',
      '# exported: ${now.toIso8601String()}',
      '# library: ${controller.root ?? '(none)'}',
      '# $phase',
      '',
      if (persisted.isNotEmpty) persisted.trimRight(),
      if (persisted.isNotEmpty && lines.isNotEmpty)
        '# --- not yet on disk ---',
      ...lines,
    ].join('\n');
    try {
      final uri = await FilePicker.saveFile(
        fileName: 'copist-debug-log-$stamp.txt',
        bytes: Uint8List.fromList(utf8.encode(content)),
        mimeType: 'text/plain',
        dialogTitle: 'Export debug log',
      );
      if (uri == null) return; // The user canceled; nothing to report.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug log exported to $uri')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $error')),
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text(AppStrings.trashTitle),
            subtitle: const Text(AppStrings.trashSubtitle),
            value: _trash ?? true,
            onChanged: _toggleTrash,
          ),
          SwitchListTile(
            title: const Text(AppStrings.debugLogsTitle),
            subtitle: const Text(AppStrings.debugLogsSubtitle),
            value: _debugLogs ?? true,
            onChanged: _toggleDebugLogs,
          ),
          SwitchListTile(
            title: const Text(AppStrings.lineNumbersTitle),
            subtitle: const Text(AppStrings.lineNumbersSubtitle),
            value: _lineNumbers ?? true,
            onChanged: _toggleLineNumbers,
          ),
          SwitchListTile(
            title: const Text(AppStrings.keyboardOnOpenTitle),
            subtitle: const Text(AppStrings.keyboardOnOpenSubtitle),
            value: _autofocusEditor ?? false,
            onChanged: _toggleAutofocusEditor,
          ),
          SwitchListTile(
            key: const Key('reminder-show-tokens'),
            title: const Text(AppStrings.reminderShowTokensTitle),
            subtitle: const Text(AppStrings.reminderShowTokensSubtitle),
            value: _reminderShowTokens ?? false,
            onChanged: _toggleReminderTokens,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.previewModeTitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  AppStrings.previewModeSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<PreviewLayoutMode>(
                  segments: const [
                    ButtonSegment(
                      value: PreviewLayoutMode.auto,
                      label: Text(AppStrings.previewModeAuto),
                    ),
                    ButtonSegment(
                      value: PreviewLayoutMode.split,
                      label: Text(AppStrings.previewModeSplit),
                    ),
                    ButtonSegment(
                      value: PreviewLayoutMode.fullScreen,
                      label: Text(AppStrings.previewModeSwitch),
                    ),
                  ],
                  selected: {_previewMode},
                  onSelectionChanged: (selection) =>
                      _setPreviewMode(selection.first),
                ),
              ],
            ),
          ),
          if (_splitLoaded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.splitRatioTitle,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    AppStrings.splitRatioSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Slider(
                    key: const Key('split-ratio'),
                    min: minSplitRatio,
                    max: maxSplitRatio,
                    value: _splitRatio,
                    onChanged: (v) => setState(() => _splitRatio = v),
                    onChangeEnd: _setSplitRatio,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.linkTypeTitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  AppStrings.linkTypeSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<LinkType>(
                  key: const Key('link-type'),
                  segments: const [
                    ButtonSegment(
                      value: LinkType.wikilink,
                      label: Text(AppStrings.linkTypeWikilink),
                    ),
                    ButtonSegment(
                      value: LinkType.markdown,
                      label: Text(AppStrings.linkTypeMarkdown),
                    ),
                  ],
                  selected: {_linkType},
                  onSelectionChanged: (selection) =>
                      _setLinkType(selection.first),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.indentWidthTitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  AppStrings.indentWidthSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  key: const Key('indent-width'),
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 4, label: Text('4')),
                    ButtonSegment(value: 6, label: Text('6')),
                    ButtonSegment(value: 8, label: Text('8')),
                  ],
                  selected: {_indentWidth},
                  onSelectionChanged: (selection) =>
                      _setIndentWidth(selection.first),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            key: const Key('quick-note-setting'),
            title: const Text('Quick note'),
            subtitle: Text(
              _quickNotePath == null ? 'Not set yet' : _quickNotePath!,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickQuickNote,
          ),
          ListTile(
            key: const Key('list-folder-setting'),
            title: const Text('List folder'),
            subtitle: Text(_listFolder ?? 'Lists'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickListFolder,
          ),
          const Divider(),
          ListTile(
            title: const Text('Library path'),
            subtitle: Text(controller.root ?? ''),
          ),
          ListTile(
            title: const Text('Re-index now'),
            leading: const Icon(Icons.refresh),
            onTap: _rescan,
          ),
          ListTile(
            title: const Text('Export debug log'),
            leading: const Icon(Icons.save_alt),
            subtitle: const Text(
              'Save the recorded events to a file you choose',
            ),
            onTap: _exportLog,
          ),
          ListTile(
            title: const Text('Close library'),
            leading: const Icon(Icons.link_off),
            onTap: () async {
              await controller.close();
              widget.onClosed?.call();
            },
          ),
        ],
    );
  }
}
