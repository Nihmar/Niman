/// The command palette as the shell opens it (#155, split out of
/// `shell.dart` for #710): the commands that can run now, the recent ones,
/// the notes, the settings rows and the Home's actions — and what a
/// choice does.
///
/// The palette's own state is the commands run this session; everything
/// else is the shell's, read through narrow callbacks when it opens.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/palette/command_palette.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/palette/pinned_commands.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_search.dart';
import 'package:path/path.dart' as p;

/// Opens the palette and runs what is chosen in it.
final class ShellPalette {
  /// Creates the palette over [controller]'s library.
  new({
    required this.controller,
    required this.transcription,
    required this.ocr,
    required this.spellCheck,
    required this.commandHandlers,
    required this.labelOf,
    required this.recentNotes,
    required this.wide,
    required this.openNote,
    required this.openSettingsAt,
    required this.runHomeAction,
  });

  /// The open library's session.
  final LibrarySession controller;

  /// The transcription models, whose settings rows the palette offers.
  final TranscriptionModels? transcription;

  /// The text recognition install, whose settings rows the palette offers.
  final OcrInstallation? ocr;

  /// The spell checker, whose settings rows the palette offers.
  final EditorSpellCheck spellCheck;

  /// The commands that can run now, with what each does.
  final Map<AppCommand, VoidCallback> Function() commandHandlers;

  /// A command's name where the shell's state words it better than the
  /// registry; null for the registry's.
  final String? Function(AppCommand command) labelOf;

  /// The notes looked at last, most recent first.
  final List<String> Function() recentNotes;

  /// Whether the window is wide: the settings rows of the library are the
  /// floating window's there.
  final bool Function() wide;

  /// Opens the note at a library-relative path.
  final void Function(String path) openNote;

  /// Opens the settings at a row.
  final void Function(SettingsTarget target) openSettingsAt;

  /// Runs one of the Home's actions.
  final void Function(HomeAction action) runHomeAction;

  /// Commands run from the palette this session, most recent first.
  final List<AppCommand> _recentCommands = [];

  /// The command palette (#155); [notesOnly] is Go to note's.
  Future<void> open(BuildContext context, {bool notesOnly = false}) async {
    final handlers = commandHandlers();
    final commands = _paletteCommands(handlers);
    final ops = controller.ops;
    final choice = await showCommandPalette(
      context,
      commands: commands,
      notesOnly: notesOnly,
      recentCommands: _recentCommands,
      recentNotes: recentNotes(),
      settings: _paletteSettings(context),
      homeActions: _homeActionsOffered,
      onTogglePin: (command) =>
          unawaited(PinnedCommands.toggle(controller, command)),
      searchNotes: (query) async => ops == null
          ? const []
          : [for (final note in await ops.notesNamed(query)) note.path],
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case PaletteCommandChoice(:final command):
        _runCommand(handlers, command);
      case PaletteNoteChoice(:final path):
        openNote(path);
      case PaletteSettingChoice(:final setting):
        openSettingsAt(setting.target);
      case PaletteActionChoice(:final action):
        runHomeAction(action);
    }
  }

  /// Every action of the Home on show (#535), for the palette: the
  /// buttons of its shown actions tiles, the ones a later build wrote
  /// left out. Hidden or not, the Home's tab is not asked for.
  Future<List<HomeAction>> _homeActionsOffered() async {
    final ops = controller.ops;
    if (ops == null) return const [];
    final home = await ops.home;
    final layout = home.device ?? home.library ?? HomeLayout.defaults;
    return [
      for (final tile in layout.column)
        for (final action in tile.actions)
          if (action.kind != null) action,
    ];
  }

  /// The palette's commands: every one that can run now, but the
  /// palette's own two.
  List<PaletteCommand> _paletteCommands([
    Map<AppCommand, VoidCallback>? handlers,
  ]) => [
    for (final command in (handlers ?? commandHandlers()).keys)
      if (command != AppCommand.openPalette && command != AppCommand.goToNote)
        PaletteCommand.of(command, label: labelOf(command)),
  ];

  /// The settings rows the palette can answer with (#229).
  ///
  /// The same rows the settings search finds, read for their titles and
  /// their places: the palette opens the settings itself, so the
  /// callbacks the settings screen builds them with are not used here.
  List<PaletteSetting> _paletteSettings(BuildContext context) {
    final root = controller.root;
    if (root == null) return const [];
    return [
      for (final entry in settingsSearchEntries(
        controller: controller,
        transcription: transcription,
        ocr: ocr,
        spellCheck: spellCheck,
        libraryName: p.basename(root),
        context: context,
        flashHome: (_) {},
        openArea: (_, _) {},
        libraryRows: !wide(),
      ))
        // The keyboard and Commands pages hold a row per command, which
        // the palette already lists as the commands themselves: a second
        // row saying the same name would be noise, and the key is on the
        // command's own row anyway.
        if (entry.areaId case final area?
            when area != SettingsAreaId.shortcuts &&
                area != SettingsAreaId.commands)
          PaletteSetting(
            title: entry.title,
            area: entry.area,
            target: (area: area, row: entry.rowKey),
          ),
    ];
  }

  /// Runs [command] through [handlers], remembering it for next time.
  void _runCommand(Map<AppCommand, VoidCallback> handlers, AppCommand command) {
    _recentCommands
      ..remove(command)
      ..insert(0, command);
    handlers[command]?.call();
  }
}
