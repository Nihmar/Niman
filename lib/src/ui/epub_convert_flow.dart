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
  Future<void> run(
    BuildContext context,
    String source, {
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
      await _settle(conversion, source, messenger);
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

  Future<void> _settle(
    EpubConversion conversion,
    String source,
    ScaffoldMessengerState? messenger,
  ) async {
    final EpubConverted converted;
    try {
      converted = await conversion.done;
    } on EpubConvertCancelled {
      _log.info('convert "${p.basename(source)}": cancelled');
      return;
    } on Object catch (error) {
      _log.warning('convert "${p.basename(source)}" failed: $error');
      messenger?.showSnackBar(
        SnackBar(content: Text(epubConvertProblem(error, source))),
      );
      return;
    }
    _log.info(
      'convert "${p.basename(source)}" -> "${converted.made}": '
      '${converted.notes} note(s), ${converted.pictures} picture(s)',
    );
    // Asked for now rather than waiting for the watcher: the tree is where
    // the user looks next, and the notes have just been written.
    await session.rescanNow();
    final folder = converted.made.endsWith('.md')
        ? p.posix.dirname(converted.made)
        : converted.made;
    reveal(folder == '.' ? '' : folder);
    open(converted.open);
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
