/// Capturing a page with the app off screen (#531): on a phone the sheet
/// closes at Save and the user goes back to the browser, so the page is
/// read and saved here, one capture at a time, and the notifications say
/// how it goes — reading, with Cancel; then saved, with Open and Show
/// folder, or why not.
///
/// Android keeps the process alive meanwhile with a short foreground
/// service, which must end within three minutes of its last start: at
/// [captureTimeLimit] from then the reading under way gives up, the
/// captures still waiting fail rather than run without the service, and
/// the service ends (#643).
library;

import 'dart:async';
import 'dart:collection';

import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/ui/capture/capture_dialog.dart';
import 'package:niman/src/ui/capture/capture_reading_task.dart';
import 'package:niman/src/ui/capture/capture_routes.dart';
import 'package:niman/src/ui/capture/capture_steps.dart';
import 'package:niman/src/ui/strings.dart';

/// How long a capture may keep the app alive: under the three minutes
/// Android gives a short foreground service.
const Duration captureTimeLimit = Duration(seconds: 150);

/// What the background capture says outside the app: the platform's
/// notifications, or a test's.
abstract interface class CaptureNotifier {
  /// Says a capture is under way and keeps the app alive while it is.
  /// Called with the app on screen — Android starts no foreground service
  /// from the background — and again for each capture queued behind it.
  Future<void> begin({required String title, String? body, String? cancel});

  /// Says where the capture under way is; [cancel] is Cancel's route,
  /// none when it can no longer be cancelled.
  Future<void> update({required String title, String? body, String? cancel});

  /// No capture is under way: the app may sleep.
  Future<void> end();

  /// Says how a capture ended: a tap routes to [open], Show folder to
  /// [folder].
  Future<void> result({
    required String title,
    required String body,
    String? open,
    String? folder,
  });
}

/// What the user chose in the sheet before Save.
typedef CaptureChosen = ({
  String folder,
  String? title,
  List<String> tags,
  bool downloadPictures,
});

/// The captures running with the app off screen, one at a time.
final class BackgroundCapture {
  /// Captures that tell the user through [notifier].
  new({required this.notifier, this.limit = captureTimeLimit});

  /// Where the notifications go.
  final CaptureNotifier notifier;

  /// How long one capture may keep the app alive.
  final Duration limit;

  final Queue<_Job> _queue = Queue<_Job>();
  _Job? _running;
  Timer? _deadline;
  int _next = 0;

  /// Whether a capture is running or waiting.
  bool get busy => _running != null || _queue.isNotEmpty;

  /// Captures the page [reading] reads into [target], as [chosen]; the
  /// task is the capture's from here on, and is disposed when it is done.
  /// Completes once [CaptureNotifier.begin] has, the capture still to
  /// come.
  Future<void> add(
    CaptureReadingTask reading, {
    required CaptureTarget target,
    required CaptureChosen chosen,
  }) async {
    final job = _Job(_next++, reading, target, chosen);
    _queue.add(job);
    await notifier.begin(
      title: AppStrings.captureReadingHost(job.host),
      cancel: captureCancelRoute(job.id),
    );
    // The service's time runs from its last start, made with the app on
    // screen: one deadline for every capture it keeps alive.
    _deadline?.cancel();
    _deadline = Timer(limit, _timeUp);
    if (_running == null) unawaited(_drain());
  }

  /// Cancels the capture [id], if it is still reading; true when it was.
  bool cancel(int id) {
    final running = _running;
    if (running != null && running.id == id) {
      if (running.saving) return false;
      if (!running.cancelled.isCompleted) running.cancelled.complete();
      return true;
    }
    final waiting = _queue.where((job) => job.id == id).firstOrNull;
    if (waiting == null) return false;
    _queue.remove(waiting);
    waiting.reading.dispose();
    return true;
  }

  Future<void> _drain() async {
    while (_queue.isNotEmpty) {
      final job = _running = _queue.removeFirst();
      try {
        await _capture(job);
      } finally {
        job.reading.dispose();
        _running = null;
      }
    }
    _deadline?.cancel();
    _deadline = null;
    await notifier.end();
  }

  /// The service's time is up: the reading under way gives up — a save
  /// under way finishes without it — and the captures waiting fail, as
  /// nothing would keep the app alive for them.
  void _timeUp() {
    _deadline = null;
    final running = _running;
    if (running != null && !running.timedOut.isCompleted) {
      running.timedOut.complete();
    }
    while (_queue.isNotEmpty) {
      final job = _queue.removeFirst();
      job.reading.dispose();
      unawaited(
        notifier.result(
          title: AppStrings.captureFailedTitle(job.host),
          body: captureFailureText(
            const PageFetchException(PageFetchFailure.timeout),
          ),
        ),
      );
    }
    unawaited(notifier.end());
  }

  Future<void> _capture(_Job job) async {
    void onStep() => unawaited(_say(job));
    job.reading.addListener(onStep);
    try {
      await _say(job);
      final reading = await Future.any<WebReading?>([
        job.reading.result,
        job.cancelled.future.then((_) => null),
        job.timedOut.future.then(
          (_) => throw const PageFetchException(PageFetchFailure.timeout),
        ),
      ]);
      job.reading.removeListener(onStep);
      if (reading == null) return;
      await _save(job, reading);
    } on PageFetchException catch (error) {
      await notifier.result(
        title: AppStrings.captureFailedTitle(job.host),
        body: captureFailureText(error),
      );
    } on Object catch (error) {
      await notifier.result(
        title: AppStrings.captureFailedTitle(job.host),
        body: '$error',
      );
    } finally {
      job.reading.removeListener(onStep);
    }
  }

  /// Says where [job] is.
  Future<void> _say(_Job job) {
    final progress = job.reading.progress;
    return notifier.update(
      title: AppStrings.captureReadingHost(job.host),
      body: progress.stage == CaptureStage.runningBrowser
          ? '${AppStrings.captureFewWords(progress.words)} · '
                '${AppStrings.captureRunningBrowser}'
          : null,
      cancel: captureCancelRoute(job.id),
    );
  }

  Future<void> _save(_Job job, WebReading reading) async {
    job.saving = true;
    await notifier.update(title: AppStrings.captureSaving);
    final target = job.target;
    final chosen = job.chosen;
    final saved = await target.save(
      reading.page,
      libraryRoot: target.libraryRoot,
      attachmentsFolder: target.attachmentsFolder,
      unreadableNotice: AppStrings.captureUnreadableNotice(
        reading.page.url.toString(),
      ),
      captured: target.clock(),
      title: chosen.title,
      downloadPictures: chosen.downloadPictures,
      tags: chosen.tags,
      linkType: target.linkType,
    );
    final path = await target.create(
      chosen.folder,
      saved.note.name,
      saved.note.text,
    );
    final readable = reading.page.readable;
    await notifier.result(
      title: readable
          ? AppStrings.captureSavedTitle(saved.note.name)
          : AppStrings.captureSavedUnreadable,
      body: readable
          ? AppStrings.captureSavedBody(
              chosen.folder.isEmpty ? '/' : chosen.folder,
              reading.page.words,
              saved.pictures,
            )
          : AppStrings.captureUnreadableBody(job.host),
      open: captureOpenRoute(path),
      folder: captureFolderRoute(chosen.folder),
    );
  }
}

final class _Job {
  new(this.id, this.reading, this.target, this.chosen);

  final int id;
  final CaptureReadingTask reading;
  final CaptureTarget target;
  final CaptureChosen chosen;
  final Completer<void> cancelled = Completer<void>();
  final Completer<void> timedOut = Completer<void>();
  bool saving = false;

  String get host => reading.url.host;
}
