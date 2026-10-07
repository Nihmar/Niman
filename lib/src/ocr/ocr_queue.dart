import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_job.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_line.dart';
import 'package:niman/src/ocr/ocr_page_source.dart';
import 'package:niman/src/ocr/ocr_sidecar.dart';
import 'package:niman/src/ocr/ocr_worker.dart';
import 'package:path/path.dart' as p;

/// A file's pages, opened for a job: how many, and each rendered.
typedef OcrPages = ({
  int count,
  Future<OcrPixels> Function(int page) render,
  Future<void> Function() close,
});

/// A started recognizer: reads a page, and stops.
typedef OcrRecognizer = ({
  Future<List<OcrLine>> Function(OcrPixels page) recognize,
  void Function() close,
});

/// Starts a recognizer with an engine, the models' folder and the
/// languages; [OcrWorker] in the app, a fake in tests.
typedef OcrRecognizerStarter = Future<OcrRecognizer> Function({
  required String engine,
  required String datapath,
  required String languages,
});

/// What the queue reads from and writes through: the library's root and
/// operations, a hook before the write (the shell saves the open notes,
/// so an editor holding the sidecar does not write its copy back over it)
/// and one after (the shell reloads a sidecar on screen).
typedef OcrWriter = ({
  String root,
  NoteOperations ops,
  Future<void> Function() before,
  void Function(String sidecar) after,
});

/// The files waiting to be recognized, one at a time (#594).
///
/// App-wide (`ocrQueueProvider`): closing the file does not stop its job,
/// and the file's bar, the phone's strip and the notification read the
/// same state. A job first downloads what it lacks (the engine, a
/// language), then reads the pages on an [OcrWorker], then writes the
/// `.ocr.md` sidecar next to the file — merged into an existing one, so a
/// page read again leaves the others as they were corrected.
final class OcrQueue extends ChangeNotifier {
  /// A queue reading with what [installation] has.
  new({
    required this.installation,
    Future<OcrPages> Function(String path)? openPages,
    OcrRecognizerStarter? startRecognizer,
    DateTime Function()? now,
  }) : _openPages = openPages ?? openOcrPages,
       _startRecognizer = startRecognizer ?? _startWorker,
       _now = now ?? DateTime.now;

  /// The engine, languages and settings the jobs use.
  final OcrInstallation installation;

  final Future<OcrPages> Function(String path) _openPages;
  final OcrRecognizerStarter _startRecognizer;
  final DateTime Function() _now;

  final List<OcrJob> _jobs = [];
  final Map<int, OcrWriter> _writers = {};
  final StreamController<OcrJob> _finished = StreamController.broadcast();
  OcrJob? _running;
  OcrRecognizer? _recognizer;
  bool _disposed = false;
  int _nextId = 1;

  /// The jobs, finished ones until [dismiss]ed.
  List<OcrJob> get jobs => List.unmodifiable(_jobs);

  /// Each job as it finishes, done, failed or cancelled.
  Stream<OcrJob> get finished => _finished.stream;

  /// The job running now, if any.
  OcrJob? get running => _running;

  /// The latest job for [path] (library-relative), if any.
  OcrJob? jobFor(String path) {
    for (final job in _jobs.reversed) {
      if (job.path == path) return job;
    }
    return null;
  }

  /// Queues [path] (library-relative) in [languages], [pages] or all of
  /// them, written through [writer]; a file already queued or running
  /// answers its job.
  OcrJob enqueue({
    required String path,
    required List<OcrLanguage> languages,
    required OcrWriter writer,
    List<int>? pages,
  }) {
    final existing = jobFor(path);
    if (existing != null && !existing.finished) return existing;
    if (existing != null) _jobs.remove(existing);
    final job = OcrJob(
      id: _nextId++,
      path: path,
      languages: languages,
      pages: pages,
    );
    _jobs.add(job);
    _writers[job.id] = writer;
    _log.info('queued $job${pages == null ? '' : ' pages $pages'}');
    _notify();
    unawaited(_pump());
    return job;
  }

  /// Stops [job]: a waiting one leaves the queue, a running one stops at
  /// the end of its page and writes nothing.
  void cancel(OcrJob job) {
    if (job.finished) return;
    _log.info('cancel $job');
    if (identical(job, _running)) {
      job.phase = OcrJobPhase.cancelled;
      _recognizer?.close();
    } else {
      _finish(job, OcrJobPhase.cancelled);
    }
    _notify();
  }

  /// Drops a finished [job] from the list.
  void dismiss(OcrJob job) {
    if (!job.finished) return;
    _jobs.remove(job);
    _notify();
  }

  Future<void> _pump() async {
    if (_running != null || _disposed) return;
    final next = _jobs
        .where((job) => job.phase == OcrJobPhase.queued)
        .firstOrNull;
    if (next == null) return;
    _running = next;
    try {
      await _run(next);
    } finally {
      _running = null;
      _recognizer = null;
    }
    unawaited(_pump());
  }

  Future<void> _run(OcrJob job) async {
    final clock = Stopwatch()..start();
    final writer = _writers.remove(job.id)!;
    try {
      final missing = installation.missingFor(job.languages);
      if (missing.isNotEmpty) {
        _set(job, OcrJobPhase.downloading);
        await installation.downloadAll(missing);
        final failed = [
          for (final item in missing)
            if (installation.stateOf(item) is! Downloaded) item.id,
        ];
        if (failed.isNotEmpty) throw StateError('not downloaded: $failed');
      }
      if (job.phase == OcrJobPhase.cancelled) return _end(job);
      final engine = installation.engine;
      final datapath = installation.datapath(installation.settings.quality);
      if (engine == null || datapath == null) {
        throw StateError('no engine');
      }
      final pages = await _openPages(p.join(writer.root, job.path));
      final read = <int, List<OcrLine>>{};
      try {
        final wanted = [
          for (final page
              in job.pages ?? [for (var i = 1; i <= pages.count; i++) i])
            if (page >= 1 && page <= pages.count) page,
        ];
        job.pagesTotal = wanted.length;
        _set(job, OcrJobPhase.recognizing);
        final recognizer = _recognizer = await _startRecognizer(
          engine: engine.name,
          datapath: datapath,
          languages: job.languageCodes,
        );
        try {
          for (final page in wanted) {
            if (job.phase == OcrJobPhase.cancelled) break;
            final pixels = await pages.render(page);
            read[page] = await recognizer.recognize(pixels);
            job.pagesDone++;
            _log.debug(
              '$job: p. $page, ${read[page]!.length} lines, '
              '${clock.elapsedMilliseconds} ms',
            );
            _notify();
          }
        } finally {
          recognizer.close();
        }
      } finally {
        await pages.close();
      }
      if (job.phase == OcrJobPhase.cancelled) return _end(job);
      _set(job, OcrJobPhase.writing);
      job
        ..sidecar = await _write(job, read, writer)
        ..words = ocrWordCount(read);
      writer.after(job.sidecar!);
      _log.info(
        '$job: ${read.length} pages, ${job.words} words into '
        '${job.sidecar} in ${clock.elapsedMilliseconds} ms',
      );
      _finish(job, OcrJobPhase.done);
    } on Object catch (error) {
      if (job.phase == OcrJobPhase.cancelled) return _end(job);
      _log.warning('$job failed after ${clock.elapsedMilliseconds} ms: $error');
      job.error = '$error';
      _finish(job, OcrJobPhase.failed);
    }
  }

  void _end(OcrJob job) {
    _log.info('$job stopped');
    _finish(job, OcrJobPhase.cancelled);
  }

  /// Writes [read] into the sidecar of [job]'s file and answers its path:
  /// merged into the one already there, or a new note beside the file.
  Future<String> _write(
    OcrJob job,
    Map<int, List<OcrLine>> read,
    OcrWriter writer,
  ) async {
    final ops = writer.ops;
    final fileName = p.posix.basename(job.path);
    final folder = p.posix.dirname(job.path);
    final parent = folder == '.' ? '' : folder;
    final paged = p.extension(fileName).toLowerCase() == '.pdf';
    await writer.before();
    // The stem's sidecar, unless another file of that stem already owns
    // it (`scan.pdf` and `scan.jpg`): then the full name's.
    for (final name in ocrSidecarNames(fileName)) {
      final path = p.posix.join(parent, '$name.md');
      if (await ops.find(path) == null) {
        final note = await ops.createNote(
          parentPath: parent,
          name: name,
          content: ocrSidecarText(
            fileName: fileName,
            languages: job.languageCodes,
            date: _now(),
            pages: read,
            paged: paged,
          ),
        );
        return note.path;
      }
      final existing = await ops.readNote(path);
      if (!isOcrSidecarOf(existing, fileName)) continue;
      await ops.saveNote(
        path,
        mergeOcrSidecar(
          existing,
          read,
          paged: paged,
          languages: job.languageCodes,
          date: _now(),
        ),
      );
      return path;
    }
    throw StateError('no free sidecar name for ${job.path}');
  }

  void _set(OcrJob job, OcrJobPhase phase) {
    if (job.phase == OcrJobPhase.cancelled) return;
    job.phase = phase;
    _notify();
  }

  void _finish(OcrJob job, OcrJobPhase phase) {
    job.phase = phase;
    _writers.remove(job.id);
    if (!_finished.isClosed) _finished.add(job);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _recognizer?.close();
    unawaited(_finished.close());
    super.dispose();
  }
}

/// A file's pages: a PDF's, or a picture as its one page.
Future<OcrPages> openOcrPages(String path) async {
  if (p.extension(path).toLowerCase() == '.pdf') {
    final pdf = await OcrPdfPages.open(path);
    return (count: pdf.count, render: pdf.render, close: pdf.close);
  }
  return (count: 1, render: (_) => decodeOcrImage(path), close: () async {});
}

Future<OcrRecognizer> _startWorker({
  required String engine,
  required String datapath,
  required String languages,
}) async {
  final worker = await OcrWorker.start(
    engine: engine,
    datapath: datapath,
    languages: languages,
  );
  return (recognize: worker.recognize, close: worker.close);
}

const _log = AppLogger(name: 'ocr');
