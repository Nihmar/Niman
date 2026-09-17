/// Making new things in the library (issue #100, split out of
/// `shell.dart`): a note, a list note, a voice note, a folder.
///
/// Each is the same shape — ask for a name, create under the guard,
/// report what was made — and none of them needs the shell's state:
/// where to create is a question it asks, and what to open afterwards is
/// a fact it reports. Notes from a template have a flow of their own,
/// because their directives decide the folder.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/kinds/audio_note.dart';
import 'package:niman/src/ui/kinds/list_note.dart';
import 'package:niman/src/ui/name_dialog.dart';
import 'package:niman/src/ui/strings.dart';

/// What a finished create hands back: the row's path, whether it is a
/// folder, and whether the note carries a kind the editor has a GUI for
/// (a list or a voice note), which the shell answers by resetting the
/// kind it is showing.
typedef CreatedItem = ({String path, bool isDir, bool hasKind});

/// Creates notes and folders from the shell's menus, FAB and row menu.
final class ShellCreateFlow {
  /// Creates the flow; the session outlives the shell, the callbacks
  /// read the shell's live state and take its decisions.
  new({
    required this.controller,
    required this.createParent,
    required this.guard,
    required this.onCreated,
  });

  /// The open library's session.
  final LibrarySession controller;

  /// The folder a create with no parent of its own lands in: the FAB's
  /// target, which follows the tree selection.
  final String Function() createParent;

  /// Serializes mutating flows, reporting errors.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Reports what was created; the shell opens it.
  final void Function(CreatedItem item) onCreated;

  /// A plain Markdown note in [parent] (default: the FAB's target).
  Future<void> createNote(BuildContext context, {String? parent}) async {
    final name = await showNameDialog(
      context,
      title: AppStrings.newNoteTitle,
      initial: AppStrings.newNoteTitle,
    );
    if (name == null) return;
    await guard(() async {
      final row = await controller.ops!.createNote(
        parentPath: parent ?? createParent(),
        name: name,
      );
      onCreated((path: row.path, isDir: false, hasKind: false));
    });
  }

  /// A list note (T-TK-06): a note with `type: list` frontmatter in the
  /// configured list folder (default `Lists`), whatever is selected.
  Future<void> createListNote(BuildContext context) async {
    final name = await showNameDialog(
      context,
      title: AppStrings.newListNoteTitle,
      initial: AppStrings.newListNoteDefault,
    );
    if (name == null) return;
    await guard(() async {
      final ops = controller.ops!;
      final folder = await _ensureListFolder(ops);
      final row = await ops.createNote(
        parentPath: folder,
        name: name,
        content: listNoteContent(),
      );
      onCreated((path: row.path, isDir: false, hasKind: true));
    });
  }

  /// A voice note: a note with `type: audio` frontmatter in the FAB's
  /// target folder, ready to record into.
  Future<void> createAudioNote(BuildContext context) async {
    final name = await showNameDialog(
      context,
      title: AppStrings.newAudioNoteTitle,
      initial: AppStrings.newAudioNoteDefault,
    );
    if (name == null) return;
    await guard(() async {
      final row = await controller.ops!.createNote(
        parentPath: createParent(),
        name: name,
        content: audioNoteContent(),
      );
      onCreated((path: row.path, isDir: false, hasKind: true));
    });
  }

  /// A folder in [parent] (default: the FAB's target).
  Future<void> createFolder(BuildContext context, {String? parent}) async {
    final name = await showNameDialog(
      context,
      title: AppStrings.newFolderTitle,
      initial: AppStrings.newFolderTitle,
    );
    if (name == null) return;
    await guard(() async {
      final row = await controller.ops!.createFolder(
        parentPath: parent ?? createParent(),
        name: name,
      );
      onCreated((path: row.path, isDir: true, hasKind: false));
    });
  }

  /// Makes sure the configured list folder exists, one level at a time,
  /// and returns it.
  ///
  /// The folder is also written back to the settings: a library whose
  /// list folder was only a setting until now ends up with the folder
  /// and the setting agreeing.
  Future<String> _ensureListFolder(NoteOperations ops) async {
    final folder = await ops.listNoteFolder;
    var prefix = '';
    for (final part in folder.split('/')) {
      if (part.isEmpty) continue;
      prefix = prefix.isEmpty ? part : '$prefix/$part';
      final existing = await ops.find(prefix);
      if (existing == null || !existing.isDir) {
        await ops.createFolder(parentPath: parentOf(prefix), name: part);
      }
    }
    await ops.setListNoteFolder(folder: folder);
    return folder;
  }
}
