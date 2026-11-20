/// Converting a web page into a note (#1293), from wherever it is asked: the
/// tree's menu, the palette, Settings → Maintenance, a drop on the window
/// and a share. One flow for all of them, as the book's is
/// (`epub_convert_flow.dart`): the question (`html_convert_dialog.dart`),
/// the conversion on its isolate with its progress and a cancel, and
/// afterwards the tree showing the note's folder and the note open.
library;

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/import/html/html_conversion.dart';
import 'package:niman/src/import/html/html_file.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/convert_progress_dialog.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/html_convert_dialog.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The conversion of web pages into notes, for one library session.
final class HtmlConvertFlow {
  /// Converts into [session]'s library; [reveal] shows a folder in the
  /// tree and [open] opens a note, both by library-relative path.
  const new({required this.session, required this.reveal, required this.open});

  /// The library.
  final LibrarySession session;

  /// Shows a folder in the tree.
  final void Function(String folder) reveal;

  /// Opens a note.
  final void Function(String note) open;

  static const AppLogger _log = AppLogger(name: 'html');

  /// Asks for an `.html`, `.htm` or `.xhtml` file and converts it.
  Future<void> pickAndRun(BuildContext context) async {
    final picked = await FilePicker.pickFile(
      dialogTitle: AppStrings.htmlConvertPickTitle,
      type: FileType.custom,
      allowedExtensions: htmlPickerExtensions,
    );
    final path = picked?.path;
    if (path == null || !context.mounted) return;
    await run(context, path);
  }

  /// Converts the page at [source], an absolute path. [consume] deletes it
  /// afterwards, whatever happened: a share's copy in the app's cache.
  /// [name] is what the page is called when its file is not: the name a
  /// share came with, rather than its copy's (`<millis>-Page.html`).
  Future<void> run(
    BuildContext context,
    String source, {
    String? name,
    bool consume = false,
  }) async {
    try {
      await runAll(context, [source], name: name);
    } finally {
      if (consume) await _delete(source);
    }
  }

  /// Converts the pages at [sources], absolute paths, one after the other
  /// into one folder, asked once for all of them. A cancel of one stops
  /// the ones after it. [name] is given for a single page only.
  Future<void> runAll(
    BuildContext context,
    List<String> sources, {
    String? name,
  }) async {
    if (sources.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final root = session.root;
    final ops = session.ops;
    if (root == null || ops == null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(AppStrings.htmlConvertNeedsLibrary)),
      );
      return;
    }
    // A page in the library: its note goes beside it, where it was put.
    final first = sources.first;
    final parent = p.isWithin(root, first)
        ? p
              .split(p.relative(p.dirname(first), from: root))
              .where((part) => part != '.')
              .join('/')
        : '';
    final choice = await showHtmlConvertDialog(
      context,
      sources: sources,
      name: name,
      parent: parent,
      pickFolder: (current) async {
        final folders = await session.tree.folders();
        if (!context.mounted) return null;
        return await showFolderPicker(
          context,
          title: AppStrings.convertInto,
          folders: folders,
          ops: ops,
          current: current,
          allowRoot: true,
        );
      },
    );
    if (choice == null || !context.mounted) return;
    final attachments = await ops.attachmentsFolder;
    final linkType = await session.librarySettings.linkType;
    for (final source in sources) {
      if (!context.mounted) return;
      final conversion = await HtmlConversion.start(
        source: source,
        name: sources.length == 1 ? name : null,
        libraryRoot: root,
        parent: choice.parent,
        attachments: attachments,
        linkType: linkType,
      );
      if (!context.mounted) {
        await conversion.cancel();
        return;
      }
      ConvertProgressDialog.show(
        context,
        progress: conversion.progress,
        done: conversion.done,
        cancel: conversion.cancel,
        reading: AppStrings.htmlConvertReading,
        key: const Key('html-convert-progress'),
        cancelKey: const Key('html-convert-cancel-progress'),
      );
      final finished = await settle(
        context,
        done: conversion.done,
        source: source,
        root: root,
        messenger: messenger,
        name: sources.length == 1 ? name : null,
      );
      if (!finished) return;
    }
  }

  /// Tells, on [messenger], how the conversion that [done] answers for ended,
  /// and — when it wrote — shows what it made; false when it was cancelled,
  /// which the pages after it are not converted after.
  ///
  /// The tree is not asked to re-read the library: the note is moved in
  /// whole and the watcher finds it, as it does a converted book's. The
  /// note's folder is shown and the note opened only if the library the
  /// conversion wrote into ([root]) is still the one open, and the screen
  /// still there: a conversion takes a while, and the user may have
  /// switched library, or closed it, in the meantime.
  @visibleForTesting
  Future<bool> settle(
    BuildContext context, {
    required Future<HtmlConverted> done,
    required String source,
    required String root,
    required ScaffoldMessengerState? messenger,
    String? name,
  }) async {
    final shown = htmlDisplayName(source, name);
    final HtmlConverted converted;
    try {
      converted = await done;
    } on HtmlConvertCancelled {
      _log.info('convert "$shown": cancelled');
      return false;
    } on Object catch (error) {
      _log.warning('convert "$shown" failed: $error');
      messenger?.showSnackBar(
        SnackBar(content: Text(htmlConvertProblem(error, source, name: name))),
      );
      return true;
    }
    _log.info(
      'convert "$shown" -> "${converted.made}": '
      '${converted.pictures} picture(s)',
    );
    if (context.mounted && session.root == root) {
      final folder = p.posix.dirname(converted.made);
      reveal(folder == '.' ? '' : folder);
      open(converted.open);
    }
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.convertDone(
            converted.made,
            converted.notes,
            converted.pictures,
          ),
        ),
      ),
    );
    return true;
  }

  Future<void> _delete(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // A cache file that outlives us costs disk, not the conversion.
    }
  }
}
