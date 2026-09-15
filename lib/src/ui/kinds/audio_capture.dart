import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/kinds/audio_recorder.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The microphone side of an audio note: whether it is live or paused,
/// whether a stopped recording is still being saved, and whether a file
/// operation (record, import, rename) is still running.
///
/// The recorder is created on first use: the platform plugin is slow to
/// set up and the page should open instantly. Failures go to [onError]
/// rather than out of the calls, so the view shows them in one place.
final class AudioCapture extends ChangeNotifier {
  /// Creates the state over the recorder [_create] makes on first use;
  /// [ownsRecorder] disposes it with this object.
  new(this._create, {required this.ownsRecorder, required this.onError});

  final VoiceRecorder Function() _create;

  /// Whether [dispose] releases the recorder (false for an injected one).
  final bool ownsRecorder;

  /// Shows a failure (an exception or a message).
  final void Function(Object error) onError;

  static const _log = AppLogger(name: 'audio');

  VoiceRecorder? _recorder;
  bool _recording = false;
  bool _paused = false;
  bool _saving = false;
  bool _busy = false;
  bool _disposed = false;

  /// Whether the microphone is live (paused included).
  bool get recording => _recording;

  /// Whether the live recording is paused.
  bool get paused => _paused;

  /// Whether a stopped recording is being written and added to the note:
  /// the recording bar stays up until it lands.
  bool get saving => _saving;

  /// Whether an operation is running (new ones are ignored meanwhile).
  bool get busy => _busy;

  VoiceRecorder get _mic => _recorder ??= _create();

  /// Runs [work] as the one running operation: ignored while another
  /// runs, failures reported through [onError].
  Future<void> guard(Future<void> Function() work) async {
    if (_busy) {
      _log.debug('ignored: an operation is still running');
      return;
    }
    _update(() => _busy = true);
    try {
      await work();
    } on Object catch (error) {
      _log.error('operation failed: $error');
      if (!_disposed) onError(error);
    } finally {
      _update(() => _busy = false);
    }
  }

  /// Starts recording (after [beforeStart]) or stops and hands the file
  /// to [onRecorded]; [newPath] names the file (default: a temp `.wav`).
  ///
  /// Stopping keeps [recording] true, with [saving] set, until
  /// [onRecorded] has finished: the composer changes once, when the clip
  /// is in the note, instead of flickering through an in-between state.
  Future<void> toggle({
    required Future<void> Function() beforeStart,
    required Future<void> Function(String path) onRecorded,
    Future<String> Function()? newPath,
  }) {
    if (_recording) {
      return guard(() async {
        final clock = Stopwatch()..start();
        _update(() => _saving = true);
        String? path;
        try {
          path = await _mic.stop();
          _log.info(
            'record stop: ${path ?? 'nothing recorded'} '
            '(${clock.elapsedMilliseconds} ms)',
          );
          if (path != null && !_disposed) {
            final handOff = Stopwatch()..start();
            await onRecorded(path);
            _log.info(
              'record saved: ${handOff.elapsedMilliseconds} ms into the '
              'note, ${clock.elapsedMilliseconds} ms since stop',
            );
          }
        } finally {
          _update(() {
            _recording = false;
            _paused = false;
            _saving = false;
          });
          if (path != null) unawaited(_deleteTemp(path));
        }
      });
    }
    return guard(() async {
      await beforeStart();
      if (!await _mic.hasPermission()) {
        _log.warning('record start: microphone permission denied');
        if (!_disposed) onError(AppStrings.audioPermissionDenied);
        return;
      }
      final clock = Stopwatch()..start();
      final path = await (newPath?.call() ?? _tempRecordPath());
      await _mic.start(path: path);
      _log.info('record start: $path (${clock.elapsedMilliseconds} ms)');
      _update(() {
        _recording = true;
        _paused = false;
      });
    });
  }

  /// Pauses the live recording, or resumes a paused one.
  Future<void> togglePause() {
    if (!_recording || _saving) return Future.value();
    return guard(() async {
      final clock = Stopwatch()..start();
      if (_paused) {
        await _mic.resume();
        _log.info('record resume (${clock.elapsedMilliseconds} ms)');
      } else {
        await _mic.pause();
        _log.info('record pause (${clock.elapsedMilliseconds} ms)');
      }
      _update(() => _paused = !_paused);
    });
  }

  /// Throws the live recording away: nothing is handed on.
  Future<void> discard() {
    if (!_recording || _saving) return Future.value();
    return guard(() async {
      try {
        await _mic.cancel();
        _log.info('record discarded');
      } finally {
        _update(() {
          _recording = false;
          _paused = false;
        });
      }
    });
  }

  Future<String> _tempRecordPath() async {
    final dir = await Directory.systemTemp.createTemp(_tempPrefix);
    return p.join(
      dir.path,
      'clip-${DateTime.now().millisecondsSinceEpoch}.wav',
    );
  }

  static const _tempPrefix = 'niman_rec_';

  /// Removes the temp folder a recording was written to, once the clip
  /// has been copied into the library (or failed to be). Only folders this
  /// class made: a path handed in through `newPath` is the caller's.
  ///
  /// Asynchronous `dart:io`, so the delete never holds a frame.
  static Future<void> _deleteTemp(String path) async {
    final dir = Directory(p.dirname(path));
    if (!p.basename(dir.path).startsWith(_tempPrefix)) return;
    try {
      await dir.delete(recursive: true);
      _log.debug('record temp removed: ${dir.path}');
    } on FileSystemException catch (e) {
      _log.warning('record temp not removed: ${dir.path}: ${e.message}');
    }
  }

  void _update(void Function() change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (ownsRecorder) _recorder?.dispose();
    super.dispose();
  }
}
