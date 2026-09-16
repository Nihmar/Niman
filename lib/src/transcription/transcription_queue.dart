import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/clip_preparation.dart';
import 'package:niman/src/transcription/model_state.dart';
import 'package:niman/src/transcription/speech_transcriber.dart';
import 'package:niman/src/transcription/transcription_job.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/transcription/wav_convert.dart';
import 'package:path/path.dart' as p;

/// The clips waiting to be transcribed, one running at a time.
///
/// App-wide ([transcriptionQueueProvider]): a transcription keeps running
/// when its note closes, and its result waits here until the note takes
/// it ([takeFinished]). Each job copies the clip into a temp folder
/// first — `whisper_ggml` writes its own converted file next to its
/// input, which must never be the library — converting WAV to 16 kHz
/// mono on the way. A job whose model is still downloading waits for it.
/// The model stays loaded while jobs follow each other and is released
/// when the queue empties.
final class TranscriptionQueue extends ChangeNotifier {
  /// A queue transcribing with [models]' files.
  new({
    required this.models,
    SpeechTranscriber? transcriber,
    WavConverter? convert,
    Future<Directory> Function()? workDirectory,
    bool? packageConverts,
  }) : _transcriber = transcriber ?? WhisperTranscriber(),
       _convert = convert ?? convertWavForWhisper,
       _workDirectory =
           workDirectory ??
           (() => Directory.systemTemp.createTemp('niman_transcribe_')),
       _packageConverts = packageConverts ?? Platform.isAndroid {
    models.addListener(_onModels);
  }

  /// The installation's models, whose downloads jobs wait for.
  final TranscriptionModels models;

  final SpeechTranscriber _transcriber;
  final WavConverter _convert;
  final Future<Directory> Function() _workDirectory;
  final bool _packageConverts;

  final List<TranscriptionJob> _jobs = [];
  TranscriptionJob? _running;
  Timer? _estimate;
  bool _modelLoaded = false;
  bool _disposed = false;
  int _nextId = 1;

  /// Seconds of work per second of audio, by model id, from the last job
  /// (drives the progress estimate; whisper reports only a few steps).
  final Map<String, double> _realTimeFactor = {};

  /// The jobs not taken yet, in order.
  List<TranscriptionJob> get jobs => List.unmodifiable(_jobs);

  /// Whether [audioPath] can be transcribed here: WAV everywhere, other
  /// formats only where the package has FFmpeg (Android).
  bool supports(String audioPath) =>
      _packageConverts || p.extension(audioPath).toLowerCase() == '.wav';

  /// The job for [clipTarget] in [notePath] not taken yet, if any.
  TranscriptionJob? jobFor(String notePath, String clipTarget) {
    for (final job in _jobs) {
      if (job.notePath == notePath && job.clipTarget == clipTarget) return job;
    }
    return null;
  }

  /// Queues the clip [clipTarget] of [notePath] (file [audioPath]); a clip
  /// already queued or running returns its existing job. [placement] and
  /// [originalDescription] say what the text does to the description.
  TranscriptionJob enqueue({
    required String notePath,
    required String clipTarget,
    required String audioPath,
    required TranscriptionModel model,
    required String language,
    TranscriptPlacement placement = TranscriptPlacement.replace,
    String originalDescription = '',
  }) {
    final existing = jobFor(notePath, clipTarget);
    if (existing != null && !existing.finished) return existing;
    if (existing != null) _jobs.remove(existing);
    final job = TranscriptionJob(
      id: _nextId++,
      notePath: notePath,
      clipTarget: clipTarget,
      audioPath: audioPath,
      model: model,
      language: language,
      placement: placement,
      originalDescription: originalDescription,
      phase: models.stateOf(model) is ModelInstalled
          ? TranscriptionPhase.queued
          : TranscriptionPhase.waitingForModel,
    );
    _jobs.add(job);
    _log.info(
      'queued $job for ${p.basename(notePath)}, '
      '${_jobs.where((j) => !j.finished).length} pending',
    );
    _notify();
    _pump();
    return job;
  }

  /// Drops [job]: a waiting one leaves the queue, a running one finishes
  /// in the background and its result is thrown away.
  void cancel(TranscriptionJob job) {
    if (!_jobs.remove(job)) return;
    final running = identical(job, _running);
    _log.info('cancelled $job${running ? ' (running; result discarded)' : ''}');
    _notify();
    _pump();
  }

  /// Removes and returns the finished jobs of [notePath] (every note when
  /// null), for their text to be written.
  List<TranscriptionJob> takeFinished([String? notePath]) {
    final taken = [
      for (final job in _jobs)
        if ((notePath == null || job.notePath == notePath) && job.finished) job,
    ];
    if (taken.isEmpty) return taken;
    _jobs.removeWhere(taken.contains);
    _notify();
    return taken;
  }

  /// Returns a finished [job] that could not be written yet, so a later
  /// taker gets it.
  void putBack(TranscriptionJob job) {
    if (_jobs.contains(job)) return;
    _jobs.add(job);
    _notify();
  }

  /// Follows a clip renamed in [notePath] from [from] to [to] (file now
  /// [audioPath]), so its job still finds the clip and its file.
  void retarget(
    String notePath, {
    required String from,
    required String to,
    required String audioPath,
  }) {
    final job = jobFor(notePath, from);
    if (job == null) return;
    job
      ..clipTarget = to
      ..audioPath = audioPath;
    _log.info('$job: clip renamed from $from');
    _notify();
  }

  /// Drops the job of the clip [clipTarget] in [notePath], if any: the
  /// clip left the note.
  void cancelClip(String notePath, String clipTarget) {
    final job = jobFor(notePath, clipTarget);
    if (job != null) cancel(job);
  }

  void _onModels() {
    if (_jobs.any((job) => job.phase == TranscriptionPhase.waitingForModel)) {
      _pump();
      // The strips of waiting jobs show the download's progress.
      _notify();
    }
  }

  /// Settles waiting jobs against their model and starts the next one.
  void _pump() {
    if (_disposed) return;
    var changed = false;
    for (final job in _jobs) {
      if (job.phase != TranscriptionPhase.waitingForModel) continue;
      switch (models.stateOf(job.model)) {
        case ModelInstalled():
          job.phase = TranscriptionPhase.queued;
          changed = true;
        case ModelAbsent() || ModelFailed(resumable: false):
          job
            ..phase = TranscriptionPhase.failed
            ..error = 'model ${job.model.id} is not downloaded';
          _log.warning('$job: ${job.error}');
          changed = true;
        case ModelDownloading() || ModelFailed(resumable: true):
          // Still coming (a paused download resumes with the app).
          break;
      }
    }
    if (changed) _notify();
    if (_running != null) return;
    final next = _jobs
        .where((job) => job.phase == TranscriptionPhase.queued)
        .firstOrNull;
    if (next != null) {
      unawaited(_run(next));
    } else if (_modelLoaded) {
      unawaited(_release());
    }
  }

  Future<void> _run(TranscriptionJob job) async {
    _running = job;
    final clock = Stopwatch()..start();
    job.phase = TranscriptionPhase.preparing;
    _notify();
    Directory? work;
    try {
      work = await _workDirectory();
      final prepared = await prepareClip(
        audioPath: job.audioPath,
        work: work,
        convert: _convert,
        packageConverts: _packageConverts,
        label: '$job',
      );
      if (!_jobs.contains(job)) return;

      job
        ..phase = TranscriptionPhase.transcribing
        ..progress = 0;
      _notify();
      final whisperClock = Stopwatch()..start();
      final expectedMs =
          prepared.lengthMs *
          (_realTimeFactor[job.model.id] ?? (_packageConverts ? 0.6 : 0.15));
      var reported = 0.0;
      var steps = 0;
      _estimate = Timer.periodic(const Duration(milliseconds: 250), (_) {
        final guess = expectedMs <= 0
            ? 0.0
            : whisperClock.elapsedMilliseconds / expectedMs;
        final next = (guess > reported ? guess : reported).clamp(0.0, 0.95);
        if (next > job.progress) {
          job.progress = next;
          _notify();
        }
      });
      final raw = await _transcriber.transcribe(
        model: job.model,
        audioPath: prepared.path,
        language: job.language,
        onProgress: (percent) {
          steps++;
          reported = percent / 100;
        },
      );
      _modelLoaded = true;
      _estimate?.cancel();
      final wallMs = whisperClock.elapsedMilliseconds;
      if (prepared.lengthMs > 0) {
        _realTimeFactor[job.model.id] = wallMs / prepared.lengthMs;
      }
      final text = cleanTranscript(raw);
      final rtf = prepared.lengthMs == 0
          ? '-'
          : (wallMs / prepared.lengthMs).toStringAsFixed(2);
      _log.info(
        '$job: whisper $wallMs ms for ${prepared.lengthMs} ms of audio '
        '(rtf $rtf, estimate ${expectedMs.round()} ms), '
        '$steps progress steps, '
        '${raw.length} chars raw, ${text.length} kept, '
        'total ${clock.elapsedMilliseconds} ms',
      );
      if (!_jobs.contains(job)) {
        _log.info('$job: cancelled while running, result discarded');
        return;
      }
      job
        ..text = text
        ..progress = 1
        ..phase = TranscriptionPhase.done;
    } on Object catch (error) {
      final reason = switch (error) {
        UnsupportedAudioException(:final reason) => 'unsupported: $reason',
        TranscriptionException(:final reason) => reason,
        _ => error.toString(),
      };
      _log.warning(
        '$job: failed after ${clock.elapsedMilliseconds} ms ($reason)',
      );
      job
        ..error = reason
        ..phase = TranscriptionPhase.failed;
    } finally {
      _estimate?.cancel();
      await _cleanUp(work);
      _running = null;
      if (!_disposed) {
        _notify();
        _pump();
      }
    }
  }

  Future<void> _cleanUp(Directory? work) async {
    if (work == null) return;
    try {
      await work.delete(recursive: true);
    } on FileSystemException catch (error) {
      _log.warning('temp folder not removed: $error');
    }
  }

  Future<void> _release() async {
    _modelLoaded = false;
    final clock = Stopwatch()..start();
    try {
      await _transcriber.release();
      _log.info('model released in ${clock.elapsedMilliseconds} ms');
    } on Object catch (error) {
      _log.warning('model release failed: $error');
    }
  }

  /// Notifies unless disposed: jobs and timers outlive a queue that is
  /// torn down mid-transcription (the app closing).
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _estimate?.cancel();
    models.removeListener(_onModels);
    if (_modelLoaded) unawaited(_release());
    super.dispose();
  }
}

const _log = AppLogger(name: 'transcription');

/// The app's transcription queue, shared by every audio note.
final transcriptionQueueProvider = Provider<TranscriptionQueue>((ref) {
  final queue = TranscriptionQueue(
    models: ref.watch(transcriptionModelsProvider),
  );
  ref.onDispose(queue.dispose);
  return queue;
});
