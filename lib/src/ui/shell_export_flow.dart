/// Exporting from the shell (#24, split out of `shell.dart` for #710): a
/// note as Markdown, HTML, PDF or EPUB, a folder or the library as one zip
/// or book — the format asked, the destination picked, the work behind its
/// progress dialog, and where the file landed said.
///
/// Nothing here touches the shell's state: the note to export is a fact it
/// is handed, and what it needs of the shell — its guard, its unsaved
/// edits, whether the window is wide — are narrow callbacks.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/export/epub_note.dart';
import 'package:niman/src/export/export_files.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/export/export_pdf.dart';
import 'package:niman/src/export/export_progress_dialog.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:niman/src/export/export_tree_book.dart';
import 'package:niman/src/export/export_working_dialog.dart';
import 'package:niman/src/export/pdf_export_progress_dialog.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_webview.dart';
import 'package:niman/src/export/slide_page.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree.dart';
import 'package:path/path.dart' as p;

/// Runs the shell's exports.
final class ShellExportFlow {
  /// Creates the flow over [controller]'s library.
  new({
    required this.controller,
    required this.guard,
    required this.saveOpen,
    required this.saveExportFile,
    required this.pickExportFolder,
    required this.pdfPrinter,
    required this.pdfEngineLookup,
    required this.epubMetadataProblem,
    required this.epubExport,
    required this.linkSource,
    required this.wide,
    required this.shownNote,
  });

  /// The open library's session.
  final LibrarySession controller;

  /// Serializes mutating flows, reporting errors.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Writes every open note's unsaved edits: what is exported is the note
  /// as it stands.
  final Future<void> Function() saveOpen;

  /// Saves one exported file where the user picks.
  final SaveExportFile saveExportFile;

  /// Picks the folder a folder's export is written into.
  final PickExportFolder pickExportFolder;

  /// Prints a page to PDF with a browser engine, when there is one.
  final PdfPrinter pdfPrinter;

  /// Looks for the desktop's browser engine; null when there is none.
  final Future<String?> Function() pdfEngineLookup;

  /// Why a folder's book would carry no metadata, or null.
  final EpubMetadataLookup epubMetadataProblem;

  /// Builds a note's EPUB.
  final EpubNoteExport epubExport;

  /// The library's link source, for the links an export resolves.
  final LinkSource? Function() linkSource;

  /// Whether the window is wide: a dialog asks there, a sheet on a phone.
  final bool Function() wide;

  /// The note on screen, or null.
  final String? Function() shownNote;

  /// Exports the note at [path] as a file (#24): asks which format, reads
  /// the note (the buffer's edits first) and asks where to save it.
  ///
  /// [slidesPdf] exports a slides note's slides (#534): a PDF, one 16:9
  /// sheet a slide, its text as large as the slide's, no format to ask.
  Future<void> runNoteExport(
    BuildContext context,
    String path, {
    bool slidesPdf = false,
  }) async {
    // The theme is read while the context is certainly valid: the dialog
    // and the export itself both wait.
    final theme = markdownThemeOf(
      context,
      scaler: slidesPdf
          ? const TextScaler.linear(slideTextScale)
          : noteTextScalerOf(context),
    );
    final format = slidesPdf
        ? ExportFormat.pdf
        : await _chooseExportFormat(context);
    if (format == null || !context.mounted) return;
    final ops = controller.ops;
    final root = controller.root;
    if (ops == null || root == null) return;
    final save = saveExportFile;
    await guard(() async {
      // What is exported is the note as it stands, not as it was last
      // written: the editors' pending edits land first.
      await saveOpen();
      final note = await ops.find(path);
      final title = note == null ? p.basename(path) : displayNameOf(note);
      final ExportPayload payload;
      var selectable = true;
      // Why a found engine could not print, when it could not: the note was
      // drawn, and the user is told rather than left with pictures and no
      // reason (device report, 2026-09-29).
      String? engineFailure;
      if (format == ExportFormat.markdown) {
        // The file's own bytes: `readNote` would hand back a leniently
        // decoded text, and re-encoding that is not the file on disk.
        payload = exportMarkdown(
          path: path,
          bytes: await ops.readNoteBytes(path),
        );
      } else if (format == ExportFormat.pdf) {
        // The machine prints the page with a browser engine, or draws it
        // here when it has none. Which of the two it will be is settled
        // before the note is read: a picture of the pages is not what
        // everyone asked for — no text to select or search, and minutes of
        // drawing on a long note — and finding out when the file is
        // written is too late (#63).
        if (!await pdfPrinter.canPrint) {
          if (!context.mounted) return;
          if (!await _confirmPdfPicture(context)) return;
        }
        // The raster fallback draws with the note's own typography, so a
        // cache of its own goes with it.
        final cache = MathCache();
        // A browser print reports no progress and the drawing fallback can
        // take minutes on a novel: the dialog says the export is running
        // and offers the one way to stop it.
        final progress = ValueNotifier<PdfExportProgress?>(null);
        final done = Completer<void>();
        var cancelled = false;
        if (context.mounted) {
          unawaited(
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => PdfExportProgressDialog(
                title: title,
                progress: progress,
                done: done.future,
                onCancel: () {
                  cancelled = true;
                  // Android's WebView print is the one engine that can be
                  // stopped mid-flight; a desktop process is left to its
                  // own timeout, and the flag aborts before anything is
                  // written or drawn.
                  if (Platform.isAndroid) {
                    unawaited(WebViewPdfPrinter.cancel());
                  }
                },
              ),
            ),
          );
        }
        try {
          // Read behind the dialog, as the EPUB branch does: a big note is
          // not instant, and a gap between the chooser closing and the
          // dialog opening reads as a stall (#63).
          final text = await ops.readNote(path);
          final printed = await exportNotePdf(
            text: text,
            title: title,
            path: path,
            root: root,
            language: AppLanguages.resolved.id,
            linkSource: linkSource(),
            printer: pdfPrinter,
            theme: theme,
            mathCache: cache,
            onProgress: (report) => progress.value = report,
            isCancelled: () => cancelled,
            slides: slidesPdf
                ? [for (final slide in splitSlides(text)) slide.markdown]
                : null,
          );
          payload = printed.payload;
          selectable = printed.selectable;
          engineFailure = printed.engineFailure;
        } on PdfExportCancelled {
          // The dialog closed itself; a cancel says nothing.
          return;
        } finally {
          if (!done.isCompleted) done.complete();
          progress.dispose();
          cache.dispose();
        }
      } else if (format == ExportFormat.epub) {
        // The book carries its pictures itself; the body is the same
        // exported page the other formats draw (#303). Building it —
        // typesetting, copying the pictures, writing the zip — is the slow
        // part, and on a phone it is seconds: the dialog says the app is
        // working, where a PDF has its own.
        final done = Completer<void>();
        var cancelled = false;
        if (context.mounted) {
          unawaited(
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => ExportWorkingDialog(
                title: title,
                done: done.future,
                onCancel: () => cancelled = true,
              ),
            ),
          );
        }
        try {
          payload = await epubExport(
            text: await ops.readNote(path),
            title: title,
            path: path,
            root: root,
            language: AppLanguages.resolved.id,
            linkSource: linkSource(),
            isCancelled: () => cancelled,
          );
        } on EpubExportCancelled {
          // The dialog closed itself; a cancel says nothing.
          return;
        } finally {
          if (!done.isCompleted) done.complete();
        }
      } else {
        payload = await exportNote(
          text: await ops.readNote(path),
          title: title,
          path: path,
          root: root,
          language: AppLanguages.resolved.id,
          // The chooser knows more formats than the builder: PDF and EPUB
          // went their own ways above.
          format: format == ExportFormat.markdown
              ? ExportFileFormat.markdown
              : ExportFileFormat.html,
          linkSource: linkSource(),
        );
      }
      final String? place;
      try {
        place = await save(
          name: payload.name,
          bytes: payload.bytes,
          mimeType: payload.mimeType,
          dialogTitle: AppStrings.exportTitle,
        );
      } on Object catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.exportFailed(error))),
          );
        }
        return;
      }
      if (place == null || !context.mounted) return;
      _showExportDone(
        context,
        place,
        picture: !selectable,
        engineFailure: engineFailure,
      );
    });
  }

  /// Exports the note showing, from the palette (#24).
  Future<void> runShownNoteExport(BuildContext context) async {
    final path = shownNote();
    if (path == null) return;
    await runNoteExport(context, path);
  }

  /// Asks which format to export in: the wide window's dialog, the phone's
  /// sheet.
  Future<ExportFormat?> _chooseExportFormat(BuildContext context) {
    final formats = <Widget>[
      for (final format in ExportFormat.values)
        ListTile(
          key: Key('export-format-${format.name}'),
          title: Text(_exportFormatName(format)),
          onTap: () => Navigator.of(context).pop(format),
        ),
    ];
    if (wide()) {
      return showDialog<ExportFormat>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('export-dialog'),
          title: Text(AppStrings.exportTitle),
          content: Column(mainAxisSize: MainAxisSize.min, children: formats),
        ),
      );
    }
    return showActionSheet<ExportFormat>(
      context,
      title: AppStrings.exportTitle,
      sheetKey: const Key('export-sheet'),
      items: (context) => formats,
    );
  }

  static String _exportFormatName(ExportFormat format) => switch (format) {
    ExportFormat.markdown => AppStrings.exportFormatMarkdown,
    ExportFormat.html => AppStrings.exportFormatHtml,
    ExportFormat.pdf => AppStrings.exportFormatPdf,
    ExportFormat.epub => AppStrings.exportFormatEpub,
  };

  /// Exports the folder at library-relative [dir] ('' = the library root)
  /// as one zip (#24): asks the format and the destination, runs the
  /// export behind its progress dialog, and says where the file landed.
  Future<void> runFolderExport(
    BuildContext context,
    String dir, {
    required bool library,
  }) async {
    final root = controller.root;
    if (root == null) return;
    // The isolate reads the notes from disk, so the buffers' pending edits
    // land before it starts — and before the pickers, so the write happens
    // while the user is choosing (M2).
    await guard(saveOpen);
    // Android's WebView needs no engine at all; the desktop looks for one
    // now, before the chooser asks whether PDF is on offer.
    final engine = Platform.isAndroid ? null : await pdfEngineLookup();
    if (!context.mounted) return;
    final format = await _chooseExportTreeFormat(
      context,
      library: library,
      pdfAvailable: Platform.isAndroid || engine != null,
    );
    if (format == null || !context.mounted) return;
    // A book's metadata is its folder's `index.md`: without one the book
    // would carry the folder's name and nothing else. Asked before the
    // destination is even chosen, so the export can be stopped and the
    // note written first (E3).
    if (format == ExportTreeFormat.epub) {
      final problem = await epubMetadataProblem(
        dir.isEmpty ? root : p.join(root, dir),
      );
      if (!context.mounted) return;
      if (problem != null && !await _confirmEpubMetadata(context, problem)) {
        return;
      }
    }
    final folder = await pickExportFolder(dialogTitle: AppStrings.exportTitle);
    if (folder == null || !context.mounted) return;
    final name = dir.isEmpty ? p.basename(root) : p.basename(dir);
    // An existing file is never overwritten silently: a second export of
    // the same folder writes `name (2).zip` (L6). A book is a `.epub`.
    final extension = format == ExportTreeFormat.epub ? 'epub' : 'zip';
    final zipPath = await _freeZipPath(folder, name, extension);
    final TreeExport export;
    try {
      export = await TreeExport.start(
        dir: dir.isEmpty ? root : p.join(root, dir),
        zipPath: zipPath,
        format: format,
        language: AppLanguages.resolved.id,
        engine: engine,
      );
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.exportFailed(error))));
      }
      return;
    }
    if (!context.mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExportProgressDialog(export: export),
      ),
    );
    try {
      await export.done;
      if (!context.mounted) return;
      _showExportDone(context, zipPath);
    } on ExportCancelled catch (cancelled) {
      // The dialog closed itself; a cancel says nothing unless the zip is
      // still there (a Windows handle the killed isolate did not let go).
      if (!cancelled.zipLeftBehind || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.exportFailed(cancelled))),
      );
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.exportFailed(error))));
    }
  }

  /// Asks whether an EPUB export should go on when the folder has no
  /// metadata source (#303, E3): the book would carry the folder's name and
  /// no author, cover or series. True when the user lets it go on — false
  /// stops the export before anything is written.
  Future<bool> _confirmEpubMetadata(
    BuildContext context,
    EpubMetadataProblem problem,
  ) async {
    final message = switch (problem) {
      EpubMetadataProblem.missingIndex => AppStrings.exportEpubNoIndex,
      EpubMetadataProblem.missingFrontmatter =>
        AppStrings.exportEpubNoFrontmatter,
    };
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('export-epub-metadata-dialog'),
        title: Text(AppStrings.exportEpubNoMetadataTitle),
        content: Text(message),
        actions: [
          TextButton(
            key: const Key('export-epub-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: const Key('export-epub-anyway'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.exportAnyway),
          ),
        ],
      ),
    );
    return go ?? false;
  }

  /// Asks whether a PDF should be drawn when this machine has no browser
  /// engine to print the page with (#63): what is written is a picture of
  /// the pages, with no text to select or search, and a long note is
  /// minutes of drawing it. True when the user lets it go on — false stops
  /// the export before the note is even read.
  Future<bool> _confirmPdfPicture(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('export-pdf-picture-dialog'),
        title: Text(AppStrings.exportPdfNoEngineTitle),
        content: Text(AppStrings.exportPdfNoEngine),
        actions: [
          TextButton(
            key: const Key('export-pdf-picture-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: const Key('export-pdf-picture-anyway'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.exportAnyway),
          ),
        ],
      ),
    );
    return go ?? false;
  }

  /// Says where an export landed, with a way to its folder where the OS
  /// can be given one (a desktop; on Android the picker already knows),
  /// and — for a PDF drawn here — that it is a picture of the pages, with
  /// [engineFailure] saying why when the engine was there and failed.
  void _showExportDone(
    BuildContext context,
    String place, {
    bool picture = false,
    String? engineFailure,
  }) {
    final lines = <String>[AppStrings.exportDone(place)];
    if (picture) {
      lines.add(AppStrings.exportPdfPicture);
      if (engineFailure != null) {
        lines.add(AppStrings.exportPdfEngineFailed(engineFailure));
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // An action would keep it up until it is dismissed by hand (#508):
        // the banner says where the file went, and the way there is offered,
        // not demanded — it goes on its own.
        persist: false,
        // A close button on the roomy layouts; a phone has the swipe and the
        // timeout, and no width to spare for it.
        showCloseIcon: wide(),
        content: Text(lines.join('\n')),
        action: supportsTreeContextActions
            ? SnackBarAction(
                label: AppStrings.openInFileManager,
                onPressed: () => unawaited(_revealExport(context, place)),
              )
            : null,
      ),
    );
  }

  /// Shows the export in the file manager, reporting the outcome: a button
  /// that silently does nothing is worse than no button.
  Future<void> _revealExport(BuildContext context, String place) async {
    final outcome = await runTreeContextAction(
      place,
      TreeContextAction.openInFileManager,
    );
    if (!context.mounted || outcome == TreeContextOutcome.opened) return;
    final message = switch (outcome) {
      TreeContextOutcome.missing => AppStrings.openFileMissing,
      _ => AppStrings.openFileFailed,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Asks which format a folder or the library is exported in: the wide
  /// window's dialog, the phone's sheet. [pdfAvailable] is decided by the
  /// caller, after the engine search has answered.
  Future<ExportTreeFormat?> _chooseExportTreeFormat(
    BuildContext context, {
    required bool library,
    required bool pdfAvailable,
  }) {
    final title = library
        ? AppStrings.exportLibraryTitle
        : AppStrings.exportFolderTitle;
    final formats = <Widget>[
      for (final format in ExportTreeFormat.values)
        if (format != ExportTreeFormat.pdf || pdfAvailable)
          ListTile(
            key: Key('export-tree-${format.name}'),
            title: Text(_treeFormatName(format)),
            onTap: () => Navigator.of(context).pop(format),
          ),
    ];
    if (wide()) {
      return showDialog<ExportTreeFormat>(
        context: context,
        builder: (context) => AlertDialog(
          key: const Key('export-tree-dialog'),
          title: Text(title),
          content: Column(mainAxisSize: MainAxisSize.min, children: formats),
        ),
      );
    }
    return showActionSheet<ExportTreeFormat>(
      context,
      title: title,
      sheetKey: const Key('export-tree-sheet'),
      items: (context) => formats,
    );
  }

  static String _treeFormatName(ExportTreeFormat format) => switch (format) {
    ExportTreeFormat.markdown => AppStrings.exportFormatMarkdown,
    ExportTreeFormat.html => AppStrings.exportFormatHtml,
    ExportTreeFormat.pdf => AppStrings.exportFormatPdf,
    ExportTreeFormat.epub => AppStrings.exportFormatEpub,
  };

  /// The zip's file name for a folder called [name]: the characters a file
  /// name cannot hold become dashes, the names Windows reserves become
  /// something else, and a name of dots reads as "export".
  static String _zipName(String name, String extension) {
    var wanted = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').trim();
    // Windows rejects a name that ends in a dot or a space, and treats the
    // device names — CON, NUL, COM1 — as the devices themselves.
    wanted = wanted.replaceAll(RegExp(r'[. ]+$'), '');
    if (_windowsDevices.contains(wanted.toUpperCase())) wanted = 'export';
    return '${wanted.isEmpty ? 'export' : wanted}.$extension';
  }

  /// A path no file holds yet: [name]'s zip, or `name (2).epub`, `(3)`…
  /// beside it. The picker chose the folder, not the name, and truncating
  /// an export the user already has is not a choice to make for them.
  static Future<String> _freeZipPath(
    String folder,
    String name,
    String extension,
  ) async {
    final wanted = _zipName(name, extension);
    final stem = p.basenameWithoutExtension(wanted);
    var path = p.join(folder, wanted);
    // A stat per candidate, awaited: a `statSync` here would be a FUSE
    // round trip on the UI isolate on Android, and the rule is no disk I/O
    // there. The lint prefers the sync form; the platform rule wins.
    // ignore: avoid_slow_async_io
    for (var n = 2; await File(path).exists(); n++) {
      path = p.join(folder, '$stem ($n).$extension');
    }
    return path;
  }

  /// The names Windows treats as devices, whatever their extension.
  static final Set<String> _windowsDevices = <String>{
    'CON',
    'PRN',
    'AUX',
    'NUL',
    for (var n = 1; n <= 9; n++) 'COM$n',
    for (var n = 1; n <= 9; n++) 'LPT$n',
  };
}
