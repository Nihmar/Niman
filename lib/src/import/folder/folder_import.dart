/// A folder's import (#75, #1295), from the main isolate's side: the isolate
/// that writes it (`folder_job.dart`), its progress, and a cancel that leaves
/// the library as it was — the isolate is asked to stop and ends through its
/// own `finally` blocks, its hidden folder deleted, and is never killed
/// mid-write.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/folder/folder_job.dart';
import 'package:niman/src/import/folder/folder_scan.dart';
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_convert_types.dart'
    show HtmlConvertProgress;
import 'package:path/path.dart' as p;

export 'package:niman/src/import/folder/folder_scan.dart'
    show
        FolderImportRefused,
        FolderLimits,
        FolderRefusal,
        FolderScan,
        folderImportLimits,
        scanFolder;
export 'package:niman/src/import/folder/folder_types.dart'
    show FolderImported, folderImportMaxDownloads;
export 'package:niman/src/import/html/html_convert_failures.dart'
    show HtmlConvertCancelled, HtmlConvertFailed;

/// One import running.
final class FolderImport {
  new _(this._staging, this._events, this._exits);

  /// Starts importing the folder [source] — whose [scan] says what it holds —
  /// into a new folder of [libraryRoot], named after it.
  static Future<FolderImport> start({
    required String source,
    required FolderScan scan,
    required String libraryRoot,
    required String attachments,
    required LinkType linkType,
    DateTime? importedOn,
  }) async {
    final staging = p.join(
      libraryRoot,
      '.folder.niman-tmp-${DateTime.now().microsecondsSinceEpoch}',
    );
    final events = ReceivePort();
    final exits = ReceivePort();
    final request = (
      source: source,
      name: sanitizeName(
        p.basename(p.normalize(source)),
        fallback: defaultFolderName,
      ),
      libraryRoot: libraryRoot,
      staging: staging,
      attachments: attachments,
      linkType: linkType,
      markdown: scan.markdown,
      pages: scan.pages,
      importedOn: importedOn,
    );
    await Isolate.spawn(importFolderEntry, (
      request,
      events.sendPort,
    ), onExit: exits.sendPort);
    return FolderImport._(staging, events, exits).._listen(source);
  }

  final String _staging;
  final ReceivePort _events;
  final ReceivePort _exits;
  final Completer<FolderImported?> _done = Completer<FolderImported?>();
  final Completer<void> _exited = Completer<void>();
  bool _finishing = false;
  bool _cancelling = false;
  int? _gauge;

  /// Where the isolate is told to stop; null until it says it is ready.
  SendPort? _control;

  /// How far it has got: files done of the total; null before the first.
  final ValueNotifier<HtmlConvertProgress?> progress = ValueNotifier(null);

  /// Answers what was written — null when the folder held nothing to
  /// import — or throws [HtmlConvertCancelled] or [HtmlConvertFailed].
  Future<FolderImported?> get done => _done.future;

  /// Whether a cancel can still stop it: not once it moves its notes in.
  bool get cancellable => !_finishing && !_cancelling && !_done.isCompleted;

  void _listen(String source) {
    final gauge = _gauge = IsolateGauge.begin(
      'import folder "${p.basename(p.normalize(source))}"',
    );
    _events.listen((message) {
      switch (message) {
        case ('ready', final SendPort control):
          _control = control;
          // A cancel that came before the isolate was ready asks now.
          if (_cancelling) control.send('stop');
        case ('progress', final int done, final int total, final String what):
          progress.value = (done: done, total: total, what: what);
        case ('finishing', final SendPort reply):
          // Answered in turn with a cancel: whichever comes first wins, and
          // there is no moment when both could.
          if (_cancelling) {
            reply.send(false);
          } else {
            _finishing = true;
            reply.send(true);
          }
        case (
          'done',
          final String folder,
          final int notes,
          final int pages,
          final int pictures,
          final int skipped,
        ):
          _settle(
            gauge,
            value: folder.isEmpty
                ? null
                : (
                    folder: folder,
                    notes: notes,
                    pages: pages,
                    pictures: pictures,
                    skipped: skipped,
                  ),
          );
        case ('failed', final String error):
          _settle(gauge, error: HtmlConvertFailed(error));
      }
    });
    // An isolate gone without its last word died: nothing it wrote stays.
    _exits.listen((_) {
      // A cancel waits for the exit: the answer is the cancel's.
      if (_cancelling) {
        if (!_exited.isCompleted) _exited.complete();
      } else if (!_done.isCompleted) {
        unawaited(_discard());
        _settle(gauge, error: const HtmlConvertFailed('the isolate died'));
      }
    });
  }

  void _settle(int gauge, {FolderImported? value, Object? error}) {
    // A cancel answers for itself.
    if (_done.isCompleted || _cancelling) return;
    IsolateGauge.finishJob(gauge, error: error);
    _events.close();
    _exits.close();
    if (error != null) {
      _done.completeError(error);
    } else {
      _done.complete(value);
    }
  }

  /// Stops it, when it still can: the isolate is asked to stop, ends between
  /// two of its steps with what it wrote deleted, and only then does this
  /// answer — whether it stopped. Never killed: a kill skips the `finally`
  /// that deletes the hidden folder and leaves the isolate free to write
  /// into it while it is deleted.
  Future<bool> cancel() async {
    if (!cancellable) return false;
    _cancelling = true;
    // Counted out now: a cancelled job left in would read in an exported log
    // as one still running, warned about, for the rest of the session.
    if (_gauge case final gauge?) {
      IsolateGauge.finishJob(gauge, error: const HtmlConvertCancelled());
    }
    _control?.send('stop');
    await _exited.future;
    _events.close();
    _exits.close();
    // The backstop, for an isolate that died before its own cleanup.
    await _discard();
    if (!_done.isCompleted) _done.completeError(const HtmlConvertCancelled());
    return true;
  }

  Future<void> _discard() async {
    try {
      await Directory(_staging).delete(recursive: true);
    } on FileSystemException {
      // Not made yet, or already gone; the sweep takes what a crash left.
    }
  }
}
