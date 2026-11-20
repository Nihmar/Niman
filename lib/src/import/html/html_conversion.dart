/// An HTML page's conversion to a note (#1293), from the main isolate's
/// side: the isolate that writes it (`html_convert_job.dart`), its
/// progress, and a cancel that leaves the library as it was: the isolate is
/// asked to stop and ends through its own `finally` blocks — its hidden
/// folder deleted — and is never killed mid-write.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_convert_job.dart';
import 'package:niman/src/import/html/html_page.dart';
import 'package:path/path.dart' as p;

export 'package:niman/src/import/html/html_convert_failures.dart';
export 'package:niman/src/import/html/html_convert_job.dart'
    show HtmlConvertProgress, HtmlConverted, htmlDisplayName, htmlMaxBytes;
export 'package:niman/src/import/html/html_page.dart' show HtmlExtent;

/// One conversion running.
final class HtmlConversion {
  new _(this._staging, this._events, this._exits);

  /// Starts converting the page [source] (an `.html`, `.htm` or `.xhtml`)
  /// into a note of the folder [parent] (library-relative) of
  /// [libraryRoot]. [name] is what the page is called when its file is not
  /// called that (a share's copy); [extent] says how much of the page
  /// becomes the note.
  static Future<HtmlConversion> start({
    required String source,
    required String libraryRoot,
    required String parent,
    required String attachments,
    required LinkType linkType,
    HtmlExtent extent = HtmlExtent.article,
    String? name,
    DateTime? importedOn,
  }) async {
    final parentAbs = p.joinAll([libraryRoot, ...parent.split('/')]);
    final staging = p.join(
      parentAbs,
      '.html.niman-tmp-${DateTime.now().microsecondsSinceEpoch}',
    );
    final events = ReceivePort();
    final exits = ReceivePort();
    final request = (
      source: source,
      name: name,
      libraryRoot: libraryRoot,
      parent: parent,
      staging: staging,
      attachments: attachments,
      linkType: linkType,
      extent: extent,
      importedOn: importedOn,
    );
    await Isolate.spawn(convertHtmlEntry, (
      request,
      events.sendPort,
    ), onExit: exits.sendPort);
    return HtmlConversion._(staging, events, exits).._listen(source);
  }

  final String _staging;
  final ReceivePort _events;
  final ReceivePort _exits;
  final Completer<HtmlConverted> _done = Completer<HtmlConverted>();
  final Completer<void> _exited = Completer<void>();
  bool _finishing = false;
  bool _cancelling = false;
  int? _gauge;

  /// Where the isolate is told to stop; null until it says it is ready.
  SendPort? _control;

  /// How far it has got; null before the first step.
  final ValueNotifier<HtmlConvertProgress?> progress = ValueNotifier(null);

  /// Answers what was written, or throws [HtmlRefused],
  /// [HtmlConvertCancelled] or [HtmlConvertFailed].
  Future<HtmlConverted> get done => _done.future;

  /// Whether a cancel can still stop it: not once it moves its notes in.
  bool get cancellable => !_finishing && !_cancelling && !_done.isCompleted;

  void _listen(String source) {
    final gauge = _gauge = IsolateGauge.begin(
      'convert "${p.basename(source)}"',
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
          final String made,
          final String open,
          final int notes,
          final int pictures,
        ):
          _settle(
            gauge,
            value: (made: made, open: open, notes: notes, pictures: pictures),
          );
        case ('refused', final String reason, final String detail):
          _settle(
            gauge,
            error: HtmlRefused(HtmlRefusal.values.byName(reason), detail),
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

  void _settle(int gauge, {HtmlConverted? value, Object? error}) {
    // A cancel answers for itself: a refusal or a failure the isolate had
    // sent before the stop reached it, delivered while the cancel waits for
    // its end, is not the answer any more.
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

  /// Stops it, when it still can: the isolate is asked to stop, ends
  /// between two of its steps with its book closed and what it wrote
  /// deleted, and only then does this answer — whether it stopped.
  ///
  /// It is never killed: a kill skips the `finally` that closes the book
  /// (a file Windows will not let be deleted) and leaves the isolate free
  /// to write into the folder deleted under it. The wait is the length of
  /// the step it is in: one chapter's reading, the planning (a fraction of
  /// a second for a book of thousands of chapters), one picture, one note.
  Future<bool> cancel() async {
    if (!cancellable) return false;
    _cancelling = true;
    // Counted out now: a cancelled job left in would read in an exported
    // log as one still running, warned about, for the rest of the session.
    if (_gauge case final gauge?) {
      IsolateGauge.finishJob(gauge, error: const HtmlConvertCancelled());
    }
    _control?.send('stop');
    await _exited.future;
    _events.close();
    _exits.close();
    // The backstop, for an isolate that died before its own cleanup: it has
    // exited, so nothing writes any more.
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
