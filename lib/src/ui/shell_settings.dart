import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';

/// What the shell reads of the open library's settings (#1256): the
/// editor's settings, the quick note, the journal, and the links the notes
/// resolve against — held as one model the shell listens to, with the
/// writes a toggle, a drag or a menu makes of them.
///
/// The settings are per library and refresh on session events (the
/// settings screen calls `notify()` after a change), so an open editor
/// picks a change up without the note being reopened. A refresh that reads
/// back what is held tells nobody.
final class ShellSettings extends ChangeNotifier {
  /// The settings of [controller]'s library.
  new({required this.controller, required this.spellCheck});

  /// The open library.
  final LibrarySession controller;

  /// The editor's spelling, which follows the library's dictionaries.
  final EditorSpellCheck spellCheck;

  /// The editor settings toggles, held here so every note view gets the
  /// same values.
  ShellEditorSettings get editor => _editor;
  ShellEditorSettings _editor = ShellEditorSettings.defaults;

  /// The library's quick note (library-relative path, or none): the note
  /// page's app bar labels it (issue #73, item 1).
  String? get quickNotePath => _quickNotePath;
  String? _quickNotePath;

  /// The journal's settings (#7): which note on screen is an entry, and of
  /// which day.
  JournalSettings get journal => _journal;
  JournalSettings _journal = const JournalSettings();

  /// The link-resolution source (T-M3-07), once the session resolved it.
  LibraryLinks? get linkSource => _linkSource;
  LibraryLinks? _linkSource;

  /// The library the wikilink suggester panel reads (#475), once resolved.
  WikilinkSuggester? get wikilinkSuggester => _wikilinkSuggester;
  WikilinkSuggester? _wikilinkSuggester;

  bool _disposed = false;

  /// Reads the settings again, and returns the navigation the library
  /// lays out (this device's own, else the library's), for the shell to
  /// place; null without a library.
  Future<NavigationLayout?> refresh() async {
    final settings = await ShellEditorSettings.read(controller);
    // The spell checker follows the library's dictionaries (T-PP-09,
    // revised); it notifies the open editor itself, so it stays out of
    // the settings value.
    final spellDictionaries = await controller.spellDictionaries;
    final ops = controller.ops;
    final quickNote = ops == null ? null : await ops.quickNotePath;
    final journal = ops == null ? null : await ops.journal;
    final navigation = ops == null ? null : await ops.navigation;
    if (_disposed) return null;
    spellCheck.setDictionaries(spellDictionaries);
    var changed = false;
    if (journal != null && journal != _journal) {
      _journal = journal;
      changed = true;
    }
    if (settings != _editor) {
      _editor = settings;
      changed = true;
    }
    if (quickNote != _quickNotePath) {
      _quickNotePath = quickNote;
      changed = true;
    }
    if (changed) notifyListeners();
    if (navigation == null) return null;
    return navigation.device ?? navigation.library ?? const NavigationLayout();
  }

  /// Resolves the links and the suggester from the session.
  Future<void> loadLinks() async {
    final source = await controller.linkSource;
    if (_disposed) return;
    if (source != null) {
      _linkSource = source;
      notifyListeners();
    }
    final suggester = await controller.wikilinkSuggester;
    if (_disposed || suggester == null) return;
    _wikilinkSuggester = suggester;
    notifyListeners();
  }

  void _set(ShellEditorSettings next) {
    if (next == _editor) return;
    _editor = next;
    notifyListeners();
  }

  /// Switches the library's editor (T-WYS-12): shown at once, then kept.
  Future<void> setEditorKind(EditorKind kind) async {
    if (kind == _editor.editorKind) return;
    await controller.setEditorKind(kind);
    controller.notify();
    if (!_disposed) _set(_editor.copyWith(editorKind: kind));
  }

  /// Switches typewriter mode (#70) for the library: the note on screen
  /// follows at once, and the setting keeps it.
  void toggleTypewriter() {
    final on = !_editor.typewriter;
    _set(_editor.copyWith(typewriter: on));
    unawaited(() async {
      await controller.setTypewriter(enabled: on);
      controller.notify();
    }());
  }

  /// Sets the tree's order (T-UI-03) and keeps it.
  ///
  /// The order changes first, for the chevron and the tree to turn over in
  /// one rebuild rather than the chevron moving on alone. The write
  /// follows, and a failure is swallowed rather than thrown: the order
  /// stays with the rows it already moved, and no revision bump comes to
  /// drag either of them back.
  Future<void> setTreeSort(TreeSort next) async {
    if (next == _editor.treeSort) return;
    _set(_editor.copyWith(treeSort: next));
    try {
      await controller.setTreeSort(next);
    } on Object catch (error) {
      const AppLogger(name: 'shell').debug('tree sort write failed: $error');
      return;
    }
    controller.notify();
  }

  /// Switches the Files pane between the tree and the grid (#727), and
  /// keeps the choice for this device, as [setTreeSort] keeps the order.
  Future<void> setTreeView(TreeView next) async {
    if (next == _editor.treeView) return;
    _set(_editor.copyWith(treeView: next));
    try {
      await controller.setTreeView(next);
    } on Object catch (error) {
      const AppLogger(name: 'shell').debug('tree view write failed: $error');
      return;
    }
    controller.notify();
  }

  /// The tree's width while its divider is dragged (T-PP-21).
  void setTreeWidth(double width) => _set(
    _editor.copyWith(treeWidth: width.clamp(minTreeWidth, maxTreeWidth)),
  );

  /// The dock's width while its divider is dragged (#297).
  void setDockWidth(double width) => _set(_editor.copyWith(dockWidth: width));

  /// Keeps the dragged tree width for the library.
  Future<void> keepTreeWidth() async {
    await controller.setTreeWidth(_editor.treeWidth);
    controller.notify();
  }

  /// Keeps the dragged dock width for the library.
  Future<void> keepDockWidth() async {
    await controller.setDockWidth(_editor.dockWidth);
    controller.notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
