import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/capture/shared_page.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/share_in.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/import/notion.dart';
import 'package:niman/src/library/markdown_import.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/epub_convert_flow.dart';
import 'package:niman/src/ui/intent_features.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What the shell brings into the library from outside (#40, #25, #75,
/// #1138): a share — a page to capture, text for the quick note, a file to
/// import —, a Notion export, a book, and a folder dropped on the window.
final class ShellImportFlow {
  /// The flow over [controller]'s library.
  new({
    required this.controller,
    required this.guard,
    required this.capture,
    required this.epubConvert,
    required this.shareText,
    required this.newItemFolder,
    required this.reveal,
    required this.openNote,
  });

  /// The open library.
  final LibrarySession controller;

  /// Runs an action once at a time, saying when it failed.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Web pages captured as notes (#531).
  final CaptureFlow capture;

  /// Books converted into notes (#1138).
  final EpubConvertFlow epubConvert;

  /// Puts shared text into the quick note and opens it.
  final Future<void> Function(String text) shareText;

  /// The folder the library's rule puts a new note in (#850).
  final String Function() newItemFolder;

  /// Shows a library folder (relative; '' is the root) in the tree.
  final void Function(String folder) reveal;

  /// Opens a note (library-relative).
  final void Function(String path) openNote;

  /// Runs a share: a web page or a quote from one into the capture sheet
  /// (#531), other text into the quick note, a file into the library
  /// (#40). With Web capture off a page is plain text, and with Quick note
  /// off text is imported as a note of its own (#1109).
  Future<void> share(BuildContext context, ShareRequest request) async {
    switch (request) {
      case SharedText(:final text, :final subject):
        final web = classifyShare(text, subject: subject);
        switch (sharedTextRoute(
          isWebPage: web != null,
          features: controller.librarySettings.features.value,
        )) {
          case SharedTextRoute.capture:
            if (context.mounted) await capture.captureShared(context, web!);
          case SharedTextRoute.quickNote:
            await shareText(text);
          case SharedTextRoute.importAsNote:
            // No quick note to put it in (#1109): the text is the point of
            // the share, so it is imported as a note of its own.
            await _createImportedNote(
              context,
              name: sharedTextNoteName(text, subject: subject),
              text: text,
            );
        }
      case SharedFile(:final path, :final name):
        await _importSharedFile(context, path: path, name: name);
    }
  }

  /// Imports the file a share copied into the library and opens it (#40).
  ///
  /// Android hands a `content://` URI, not a file: the platform side read
  /// the bytes and wrote its own copy at [path], which is imported here
  /// and deleted. The note lands at the library root under the name it
  /// came with, uniquified like any new note; a `.markdown` and a `.txt`
  /// alike become one, because what is imported is its text. A `.zip` is
  /// a Notion export instead (#25): its pages land in a folder of their
  /// own, see [_importNotionArchive].
  Future<void> _importSharedFile(
    BuildContext context, {
    required String path,
    required String name,
  }) async {
    final ops = controller.ops;
    if (ops == null || !context.mounted) return;
    final source = File(path);
    if (!await source.exists()) return;
    // A shared book is converted into notes (#1138), never decoded as a
    // note's text: its cache copy goes once it is.
    // Told by its name, or — a provider that names it `msf:1234` — by the
    // `mimetype` the format opens on.
    if (isBook(name) || await looksLikeEpub(path)) {
      if (context.mounted) {
        await epubConvert.run(context, path, name: name, consume: true);
      }
      return;
    }
    if (p.extension(name).toLowerCase() == '.zip') {
      if (!context.mounted) return;
      await _importNotionArchive(context, source, name, consume: true);
      return;
    }
    var text = decodeNoteText(await source.readAsBytes());
    // A BOM is the platform's encoding marker, not part of the note.
    if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
      text = text.substring(1);
    }
    try {
      // The copy has done its job whatever the import decides next.
      await source.delete();
    } on FileSystemException {
      // A cache file that outlives us costs disk, not the import.
    }
    if (!context.mounted) return;
    await _createImportedNote(
      context,
      name: p.basenameWithoutExtension(name),
      text: text,
    );
  }

  /// Makes a note named [name] of [text] where the library's rule puts a new
  /// note (#850) — a share that arrives with no note open lands at the
  /// root — and opens it: what a shared file becomes, and shared text when
  /// there is no quick note to take it (#1109).
  Future<void> _createImportedNote(
    BuildContext context, {
    required String name,
    required String text,
  }) async {
    final ops = controller.ops;
    if (ops == null || !context.mounted) return;
    await guard(() async {
      final folder = newItemFolder();
      final imported = await ops.createNote(
        parentPath: folder,
        name: name,
        content: text,
      );
      if (!context.mounted) return;
      reveal(folder);
      openNote(imported.path);
    });
  }

  /// Imports the Notion export [source] (a `.zip`) into a new folder of
  /// the library (#25), revealing it, and says where it landed.
  ///
  /// [consume] deletes the archive first — a share's copy in the app
  /// cache has no other owner; a file the user dropped is theirs and
  /// stays where it is.
  Future<void> _importNotionArchive(
    BuildContext context,
    File source,
    String name, {
    bool consume = false,
  }) async {
    final root = controller.root;
    if (root == null || !context.mounted) return;
    await guard(() async {
      final imported = await importNotionZip(
        source: source.path,
        libraryRoot: root,
      );
      if (consume) {
        try {
          await source.delete();
        } on FileSystemException {
          // A cache file that outlives us costs disk, not the import.
        }
      }
      if (!context.mounted) return;
      // Asked for now rather than waiting for the watcher: the tree is
      // where the user looks next, and the notes have just been written.
      if (imported != null) await controller.rescanNow();
      if (!context.mounted) return;
      _showImported(context, imported?.folder, name);
    });
  }

  /// Says how an import of [name] went: nothing to bring in when
  /// [folder] is null, else the folder it landed in, shown in the tree.
  void _showImported(BuildContext context, String? folder, String name) {
    final messenger = ScaffoldMessenger.of(context);
    if (folder == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.importFolderEmpty(name))),
      );
      return;
    }
    reveal(folder);
    messenger.showSnackBar(
      SnackBar(content: Text(AppStrings.importFolderDone(folder))),
    );
  }

  /// A folder dropped on the window (#75). One of this library's own is
  /// shown in the tree; any other is offered for import — its Markdown
  /// copied into a new folder here — and shown once it is in. A Notion
  /// export (a `.zip`, #25) goes through the import instead.
  Future<void> openFolder(BuildContext context, String path) async {
    if (p.extension(path).toLowerCase() == '.zip') {
      await _importNotionArchive(context, File(path), p.basename(path));
      return;
    }
    // A book: into notes (#1138), or a word that a library is needed.
    if (isBook(path)) {
      await epubConvert.run(context, path);
      return;
    }
    final root = controller.root;
    if (root == null || !context.mounted) return;
    if (p.equals(root, path) || p.isWithin(root, path)) {
      reveal(p.equals(root, path) ? '' : relPath(path, root));
      return;
    }
    final name = p.basename(p.normalize(path));
    // The walk is a FUSE round trip per folder on Android: it runs off the
    // UI isolate, so the count is awaited rather than read inline (#382).
    final count = (await markdownFilesIn(path)).length;
    if (!context.mounted) return;
    if (count == 0) return _showImported(context, null, name);
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('import-folder'),
        title: Text(AppStrings.importFolderTitle(name)),
        content: Text(AppStrings.importFolderBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: const Key('import-folder-yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.importFolderAction),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    await guard(() async {
      final imported = await importMarkdownFolder(
        source: path,
        libraryRoot: root,
      );
      if (imported == null || !context.mounted) return;
      // The walk and the copy are off the UI isolate now (#382), and the
      // watcher finds what landed on its own: a rescan here would only block
      // the frame the reveal is drawn in, so it is left to converge.
      _showImported(context, imported.folder, name);
    });
  }
}
