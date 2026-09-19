import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/hunspell_spell_checker.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/toolbar_settings.dart';

/// The Editor area of the settings home (issue #104): which editors the
/// library offers, what the toolbar can do, and the editor's own
/// behaviour — line numbers, links, text size, indentation, spelling.
final class SettingsEditorScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({
    required this.controller,
    required this.spellCheck,
    this.highlight,
    super.key,
  });

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  /// The editor's spelling state (T-PP-09), for its toggle; null hides it.
  final EditorSpellCheck? spellCheck;

  @override
  State<SettingsEditorScreen> createState() => _SettingsEditorScreenState();
}

final class _SettingsEditorScreenState extends State<SettingsEditorScreen> {
  Set<EditorKind> _enabledEditors = const {
    EditorKind.source,
    EditorKind.wysiwyg,
  };
  bool _previewEnabled = true;
  bool? _lineNumbers;
  bool _readableLineLength = true;
  double _noteColumnWidth = defaultNoteColumnWidth;
  bool _typewriter = false;
  bool? _autofocusEditor;
  LinkType _linkType = LinkType.wikilink;
  MissingNoteLocation _missingNoteLocation = MissingNoteLocation.currentFolder;
  double _noteTextScale = defaultTextScale;
  int _indentWidth = 2;
  List<String> _spellDictionaries = const <String>[];

  /// Steps of 5% between [minTextScale] and [maxTextScale]: fine enough
  /// to land on a size that fits, coarse enough to be hit on a phone.
  static final int _textScaleSteps = ((maxTextScale - minTextScale) * 20)
      .round();

  /// Steps of 20 px between the narrowest and the widest note column.
  static final int _columnWidthSteps =
      ((maxNoteColumnWidth - minNoteColumnWidth) / 20).round();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final controller = widget.controller;
    final lineNumbers = await controller.lineNumbersEnabled;
    final readableLineLength = await controller.readableLineLength;
    final noteColumnWidth = await controller.noteColumnWidth;
    final typewriter = await controller.typewriter;
    final autofocus = await controller.editorAutofocusEnabled;
    final linkType = await controller.linkType;
    final missingNoteLocation = await controller.missingNoteLocation;
    final noteTextScale = await controller.noteTextScale;
    final indentWidth = await controller.indentWidth;
    final spellDictionaries = await controller.spellDictionaries;
    final enabledEditors = await controller.enabledEditors;
    final previewEnabled = await controller.previewEnabled;
    if (!mounted) return;
    setState(() {
      _lineNumbers = lineNumbers;
      _readableLineLength = readableLineLength;
      _noteColumnWidth = noteColumnWidth;
      _typewriter = typewriter;
      _autofocusEditor = autofocus;
      _linkType = linkType;
      _missingNoteLocation = missingNoteLocation;
      _noteTextScale = noteTextScale;
      _indentWidth = indentWidth;
      _spellDictionaries = spellDictionaries;
      _enabledEditors = {...enabledEditors};
      _previewEnabled = previewEnabled;
    });
  }

  /// Persists the line-numbers toggle (T-WYS-02).
  ///
  /// The editor shows the change without reopening the note: the
  /// notification reaches the shell, which re-lays the open surface.
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

  /// Persists the readable-line-length toggle (issue #171); an open note
  /// takes the column on the spot, through the shell's refresh.
  Future<void> _toggleReadableLineLength(bool value) async {
    final controller = widget.controller;
    await controller.setReadableLineLength(enabled: value);
    controller.notify();
    if (mounted) setState(() => _readableLineLength = value);
  }

  /// Persists typewriter mode (#70); an open note takes it on the spot,
  /// through the shell's refresh.
  Future<void> _toggleTypewriter(bool value) async {
    final controller = widget.controller;
    await controller.setTypewriter(enabled: value);
    controller.notify();
    if (mounted) setState(() => _typewriter = value);
  }

  /// Asks how wide the note column is.
  Future<void> _chooseNoteColumnWidth() async {
    final width = await showSettingsSlider(
      context,
      dialogKey: const Key('note-column-width-dialog'),
      sliderKey: const Key('note-column-width-slider'),
      title: AppStrings.noteColumnWidthTitle,
      subtitle: AppStrings.noteColumnWidthSubtitle,
      current: _noteColumnWidth,
      min: minNoteColumnWidth,
      max: maxNoteColumnWidth,
      divisions: _columnWidthSteps,
      format: (value) => AppStrings.noteColumnWidthValue(value.round()),
    );
    if (width == null) return;
    final controller = widget.controller;
    await controller.setNoteColumnWidth(width.roundToDouble());
    controller.notify();
    if (mounted) setState(() => _noteColumnWidth = width.roundToDouble());
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

  Future<void> _setLinkType(LinkType type) async {
    final controller = widget.controller;
    await controller.setLinkType(type);
    controller.notify();
    if (mounted) {
      setState(() => _linkType = type);
    }
  }

  Future<void> _setMissingNoteLocation(MissingNoteLocation location) async {
    final controller = widget.controller;
    await controller.setMissingNoteLocation(location);
    controller.notify();
    if (mounted) {
      setState(() => _missingNoteLocation = location);
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

  /// Asks where a note created from a dead link lands (issue #78).
  Future<void> _chooseMissingNoteLocation() async {
    final location = await showSettingsChoice<MissingNoteLocation>(
      context,
      dialogKey: const Key('missing-note-location-dialog'),
      title: AppStrings.missingNoteLocationTitle,
      current: _missingNoteLocation,
      options: [
        SettingsOption(
          MissingNoteLocation.libraryRoot,
          AppStrings.missingNoteLocationRoot,
        ),
        SettingsOption(
          MissingNoteLocation.currentFolder,
          AppStrings.missingNoteLocationCurrentFolder,
        ),
      ],
    );
    if (location != null) await _setMissingNoteLocation(location);
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

  /// Enables or disables one of the library's editors (T-WYS-03).
  ///
  /// The last enabled editor cannot be switched off: the callback arrives
  /// null for it, so its switch reads as disabled rather than opening a
  /// dead end with no editor at all.
  Future<void> _toggleEditorEnabled(EditorKind kind, bool enabled) async {
    final next = {..._enabledEditors};
    if (enabled) {
      next.add(kind);
    } else {
      if (next.length < 2) return;
      next.remove(kind);
    }
    await widget.controller.setEnabledEditors(next);
    // Notify so the shell refreshes its cached value — the open note swaps
    // surfaces, and the status row gains or loses its switch, without
    // reopening it.
    widget.controller.notify();
    if (mounted) setState(() => _enabledEditors = next);
  }

  /// Persists the preview switch (T-WYS-03).
  Future<void> _togglePreviewEnabled(bool value) async {
    await widget.controller.setPreviewEnabled(enabled: value);
    widget.controller.notify();
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

  @override
  Widget build(BuildContext context) {
    final spell = widget.spellCheck;
    return SettingsAreaShell(
      title: AppStrings.settingsSectionEditor,
      controller: widget.controller,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // The toolbar is an editor setting, not an appearance one: it
          // decides what the editor can do, not how the app looks.
          HighlightRow(
            key: SettingsKeys.toolbar,
            child: SettingsValueRow(
              title: AppStrings.toolbarSettingsTitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) =>
                      ToolbarSettingsScreen(controller: widget.controller),
                ),
              ),
            ),
          ),
          // Which editors the library offers: both, or one alone. The
          // last one on cannot be switched off (its switch disables
          // itself), so the choice never resolves to no editor.
          HighlightRow(
            key: SettingsKeys.editorSource,
            child: SettingsSwitchRow(
              title: AppStrings.editorKindSource,
              description: AppStrings.editorKindSourceSubtitle,
              value: _enabledEditors.contains(EditorKind.source),
              onChanged:
                  _enabledEditors.length < 2 &&
                      _enabledEditors.contains(EditorKind.source)
                  ? null
                  : (value) => unawaited(
                      _toggleEditorEnabled(EditorKind.source, value),
                    ),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.editorWysiwyg,
            child: SettingsSwitchRow(
              title: AppStrings.editorKindWysiwyg,
              description: AppStrings.editorKindWysiwygSubtitle,
              value: _enabledEditors.contains(EditorKind.wysiwyg),
              onChanged:
                  _enabledEditors.length < 2 &&
                      _enabledEditors.contains(EditorKind.wysiwyg)
                  ? null
                  : (value) => unawaited(
                      _toggleEditorEnabled(EditorKind.wysiwyg, value),
                    ),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.previewEnabled,
            child: SettingsSwitchRow(
              title: AppStrings.settingsPreviewEnabledTitle,
              description: AppStrings.settingsPreviewEnabledSubtitle,
              value: _previewEnabled,
              onChanged: _togglePreviewEnabled,
            ),
          ),
          // Switches keep their subtitle: a switch has no dialog to move
          // the explanation into, and "off = on first tap" is exactly
          // what someone reads the row for.
          HighlightRow(
            key: SettingsKeys.lineNumbers,
            child: SettingsSwitchRow(
              title: AppStrings.lineNumbersTitle,
              description: AppStrings.lineNumbersSubtitle,
              value: _lineNumbers ?? true,
              onChanged: _toggleLineNumbers,
            ),
          ),
          // Every platform has it (#171): a phone is narrower than any
          // column, so there it only starts to count on a tablet or in
          // landscape — which is the reason not to hide it.
          HighlightRow(
            key: SettingsKeys.readableLineLength,
            child: SettingsSwitchRow(
              title: AppStrings.readableLineLengthTitle,
              description: AppStrings.readableLineLengthSubtitle,
              value: _readableLineLength,
              onChanged: (value) => unawaited(_toggleReadableLineLength(value)),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.noteColumnWidth,
            child: SettingsValueRow(
              title: AppStrings.noteColumnWidthTitle,
              subtitle: AppStrings.noteColumnWidthSubtitle,
              value: AppStrings.noteColumnWidthValue(_noteColumnWidth.round()),
              enabled: _readableLineLength,
              onTap: () => unawaited(_chooseNoteColumnWidth()),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.typewriter,
            child: SettingsSwitchRow(
              title: AppStrings.typewriterTitle,
              description: AppStrings.typewriterSubtitle,
              value: _typewriter,
              onChanged: (value) => unawaited(_toggleTypewriter(value)),
            ),
          ),
          // Phones and tablets only: there is no on-screen keyboard to
          // show on desktop, so the row would toggle a no-op (user,
          // 2026-09-09).
          if (Platform.isAndroid || Platform.isIOS)
            SettingsSwitchRow(
              title: AppStrings.keyboardOnOpenTitle,
              description: AppStrings.keyboardOnOpenSubtitle,
              value: _autofocusEditor ?? false,
              onChanged: _toggleAutofocusEditor,
            ),
          HighlightRow(
            key: SettingsKeys.linkType,
            child: SettingsValueRow(
              title: AppStrings.linkTypeTitle,
              subtitle: AppStrings.linkTypeSubtitle,
              value: switch (_linkType) {
                LinkType.wikilink => AppStrings.linkTypeWikilink,
                LinkType.markdown => AppStrings.linkTypeMarkdown,
              },
              onTap: () => unawaited(_chooseLinkType()),
            ),
          ),
          // Next to the link format: both decide what a link does — one
          // what it inserts, the other what a click on a missing target
          // becomes (issue #78).
          HighlightRow(
            key: SettingsKeys.missingNoteLocation,
            child: SettingsValueRow(
              title: AppStrings.missingNoteLocationTitle,
              value: switch (_missingNoteLocation) {
                MissingNoteLocation.libraryRoot =>
                  AppStrings.missingNoteLocationRoot,
                MissingNoteLocation.currentFolder =>
                  AppStrings.missingNoteLocationCurrentFolder,
              },
              onTap: () => unawaited(_chooseMissingNoteLocation()),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.noteTextScale,
            child: SettingsValueRow(
              title: AppStrings.noteTextScaleTitle,
              subtitle: AppStrings.noteTextScaleSubtitle,
              value: AppStrings.textScaleValue(_noteTextScale),
              onTap: () => unawaited(_chooseNoteTextScale()),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.indentWidth,
            child: SettingsValueRow(
              title: AppStrings.indentWidthTitle,
              subtitle: AppStrings.indentWidthSubtitle,
              value: AppStrings.indentWidthValue(_indentWidth),
              onTap: () => unawaited(_chooseIndentWidth()),
            ),
          ),
          if (spell != null && spell.available) ...[
            SettingsSwitchRow(
              key: const Key('spell-check-setting'),
              title: AppStrings.settingsSpellCheckTitle,
              description: AppStrings.settingsSpellCheckSubtitle,
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
        ],
      ),
    );
  }
}
