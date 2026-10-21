/// Converting a book into notes (#1138), from wherever it is asked: the
/// book's own row in the reader, the tree's menu, the palette, Settings →
/// Maintenance, a drop on the window and a share. One flow for all of
/// them: the question (`epub_convert_dialog.dart`), the conversion on its
/// isolate with its progress and a cancel, and afterwards the tree showing
/// the new folder and its `index.md` — or the one note — open.
library;

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/epub/epub_conversion.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/epub_convert_dialog.dart';
import 'package:niman/src/ui/epub_convert_progress_dialog.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The conversion of books into notes, for one library session.
final class EpubConvertFlow {
  /// Converts into [session]'s library; [reveal] shows a folder in the
  /// tree and [open] opens a note, both by library-relative path.
  const new({
    required this.session,
    required this.reveal,
    required this.open,
    this.preview = previewEpubOnIsolate,
  });

  /// The library.
  final LibrarySession session;

  /// Shows a folder in the tree.
  final void Function(String folder) reveal;

  /// Opens a note.
  final void Function(String note) open;

  /// What reads a book for the dialog; a test hands in its own.
  final EpubPreviewer preview;

  static const AppLogger _log = AppLogger(name: 'epub');

  /// Asks for an `.epub` file and converts it.
  Future<void> pickAndRun(BuildContext context) async {
    final picked = await FilePicker.pickFile(
      dialogTitle: AppStrings.epubConvertPickTitle,
      type: FileType.custom,
      allowedExtensions: const ['epub'],
    );
    final path = picked?.path;
    if (path == null || !context.mounted) return;
    await run(context, path);
  }

  /// Converts the book at [source], an absolute path. [consume] deletes it
  /// afterwards, whatever happened: a share's copy in the app's cache.
  /// [name] is what the book is called when its file is not: the name a
  /// share came with, rather than its copy's (`<millis>-Dune.epub`).
  Future<void> run(
    BuildContext context,
    String source, {
    String? name,
    bool consume = false,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final root = session.root;
      final ops = session.ops;
      if (root == null || ops == null) {
        messenger?.showSnackBar(
          SnackBar(content: Text(AppStrings.epubConvertNeedsLibrary)),
        );
        return;
      }
      // A book in the library: its notes go beside it, where it was put.
      final parent = p.isWithin(root, source)
          ? p
                .split(p.relative(p.dirname(source), from: root))
                .where((part) => part != '.')
                .join('/')
          : '';
      final choice = await showEpubConvertDialog(
        context,
        source: source,
        name: name,
        parent: parent,
        preview: preview,
        pickFolder: (current) async {
          final folders = await session.folders();
          if (!context.mounted) return null;
          return await showFolderPicker(
            context,
            title: AppStrings.epubConvertInto,
            folders: folders,
            ops: ops,
            current: current,
            allowRoot: true,
          );
        },
      );
      if (choice == null || !context.mounted) return;
      final conversion = await EpubConversion.start(
        source: source,
        name: name,
        libraryRoot: root,
        parent: choice.parent,
        oneNote: choice.oneNote,
        attachments: await ops.attachmentsFolder,
        words: epubConvertWords(),
      );
      if (!context.mounted) {
        await conversion.cancel();
        return;
      }
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => EpubConvertProgressDialog(conversion),
        ),
      );
      await settle(
        context,
        done: conversion.done,
        source: source,
        root: root,
        messenger: messenger,
        name: name,
      );
    } finally {
      if (consume) {
        try {
          await File(source).delete();
        } on FileSystemException {
          // A cache file that outlives us costs disk, not the conversion.
        }
      }
    }
  }

  /// Tells, on [messenger], how the conversion that [done] answers for ended,
  /// and — when it wrote — shows what it made.
  ///
  /// The tree is not asked to re-read the library: the new folder is moved
  /// in whole and the watcher finds it, as it does an imported folder
  /// (#382). A full rescan walked the whole library with the user waiting
  /// and no dialog on screen, and threw when the library had been closed
  /// meanwhile. The folder is shown and its note opened only if the library
  /// the conversion wrote into ([root]) is still the one open, and the
  /// screen still there: a conversion takes a while, and the user may have
  /// switched library, or closed it, in the meantime.
  @visibleForTesting
  Future<void> settle(
    BuildContext context, {
    required Future<EpubConverted> done,
    required String source,
    required String root,
    required ScaffoldMessengerState? messenger,
    String? name,
  }) async {
    final shown = epubDisplayName(source, name);
    final EpubConverted converted;
    try {
      converted = await done;
    } on EpubConvertCancelled {
      _log.info('convert "$shown": cancelled');
      return;
    } on Object catch (error) {
      _log.warning('convert "$shown" failed: $error');
      messenger?.showSnackBar(
        SnackBar(content: Text(epubConvertProblem(error, source, name: name))),
      );
      return;
    }
    _log.info(
      'convert "$shown" -> "${converted.made}": '
      '${converted.notes} note(s), ${converted.pictures} picture(s)',
    );
    if (context.mounted && session.root == root) {
      final folder = converted.made.endsWith('.md')
          ? p.posix.dirname(converted.made)
          : converted.made;
      reveal(folder == '.' ? '' : folder);
      open(converted.open);
    }
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.epubConvertDone(
            converted.made,
            converted.notes,
            converted.pictures,
          ),
        ),
      ),
    );
  }
}
