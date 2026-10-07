import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show wideBreakpoint;
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_job.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_page_source.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ocr/ocr_sidecar.dart';
import 'package:niman/src/ui/ocr/ocr_notifier.dart';
import 'package:niman/src/ui/ocr/ocr_result_sheet.dart';
import 'package:niman/src/ui/ocr/recognize_text_sheet.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

/// The shell's Recognize text (#594): asks how, queues the job, and says
/// when it is done — a snackbar with Open text while the app is in front,
/// a notification when the reader is elsewhere.
final class ShellOcrFlow {
  /// The flow over [controller]'s library, with [installation]'s engine
  /// and languages and [queue]'s jobs.
  new({
    required this.controller,
    required this.unsaved,
    required this.installation,
    required this.queue,
    required this.onWritten,
    required this.onOpen,
    OcrNotifier? notifier,
  }) : _notifier = notifier ?? OcrNotifier();

  /// The open library.
  final LibrarySession controller;

  /// The open notes, saved before a sidecar is written.
  final UnsavedTracker unsaved;

  /// The engine, languages and settings.
  final OcrInstallation installation;

  /// The jobs.
  final OcrQueue queue;

  /// After a sidecar is written: the tree and a sidecar on screen reload.
  final VoidCallback onWritten;

  /// Opens a note.
  final void Function(String path) onOpen;

  final OcrNotifier _notifier;

  /// Asks how to recognize [path] (library-relative), then queues it; a
  /// PDF's [pageCount] is read here when the caller does not know it.
  Future<void> recognize(
    BuildContext context,
    String path, {
    int? page,
    int? pageCount,
  }) async {
    final root = controller.root;
    final ops = controller.ops;
    if (root == null || ops == null) return;
    // The provider loads at creation: only a press that beats it waits.
    // The job scans the downloads again itself (#610).
    if (!installation.loaded) {
      await installation.load();
      if (!context.mounted) return;
    }
    if (installation.unavailable) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.ocrEngineUnavailable)));
      return;
    }
    var count = pageCount;
    if (count == null && p.extension(path).toLowerCase() == '.pdf') {
      try {
        final pages = await OcrPdfPages.open(p.join(root, path));
        count = pages.count;
        await pages.close();
      } on Object {
        // The sheet offers every page; the job says if the file is bad.
      }
    }
    if (!context.mounted) return;
    final request = await showRecognizeTextSheet(
      context,
      installation: installation,
      path: path,
      pageCount: count,
      page: page,
    );
    if (request == null) return;
    _enqueue(path, request.languages, request.pages);
  }

  /// Reads [page] of [path] (library-relative) again in [languages],
  /// asking nothing: its lines lost their places on the scan (#596).
  void recognizeAgain(String path, int page, List<OcrLanguage> languages) =>
      _enqueue(path, languages, [page]);

  void _enqueue(String path, List<OcrLanguage> languages, List<int>? pages) {
    final root = controller.root;
    final ops = controller.ops;
    if (root == null || ops == null) return;
    queue.enqueue(
      path: path,
      languages: languages,
      pages: pages,
      writer: (
        root: root,
        ops: ops,
        before: unsaved.saveAll,
        after: (_) => onWritten(),
      ),
    );
  }

  /// Says [job] is over: in a snackbar while [inFront] — on a phone, a
  /// picture's text in a sheet of its own — else in a notification (a
  /// failure only in the app).
  void finished(BuildContext context, OcrJob job, {required bool inFront}) {
    final sidecar = job.sidecar;
    switch (job.phase) {
      case OcrJobPhase.done
          when sidecar != null &&
              inFront &&
              p.extension(job.path).toLowerCase() != '.pdf' &&
              MediaQuery.sizeOf(context).width < wideBreakpoint:
        unawaited(_showPicture(context, job, sidecar));
      case OcrJobPhase.done when sidecar != null:
        final message = AppStrings.ocrRecognized(job.words);
        if (!inFront) {
          unawaited(
            _notifier.show(
              title: message,
              body: p.posix.basename(job.path),
              sidecar: sidecar,
            ),
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: AppStrings.ocrOpenText,
              onPressed: () => onOpen(sidecar),
            ),
          ),
        );
      case OcrJobPhase.failed:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppStrings.ocrFailed)));
      case _:
        break;
    }
    queue.dismiss(job);
  }

  Future<void> _showPicture(
    BuildContext context,
    OcrJob job,
    String sidecar,
  ) async {
    final ops = controller.ops;
    if (ops == null) return;
    final text = ocrSidecarPlainText(await ops.readNote(sidecar));
    if (!context.mounted) return;
    await showOcrResultSheet(
      context,
      words: job.words,
      savedAs: sidecar,
      text: text,
      onOpen: () => onOpen(sidecar),
    );
  }
}
