import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:niman/src/ui/kinds/audio_recorder.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The microphone side of an audio note: whether it is live, and whether
/// a file operation (record, import, rename) is still running.
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

  VoiceRecorder? _recorder;
  bool _recording = false;
  bool _busy = false;
  bool _disposed = false;

  /// Whether the microphone is live.
  bool get recording => _recording;

  /// Whether an operation is running (new ones are ignored meanwhile).
  bool get busy => _busy;

  VoiceRecorder get _mic => _recorder ??= _create();

  /// Runs [work] as the one running operation: ignored while another
  /// runs, failures reported through [onError].
  Future<void> guard(Future<void> Function() work) async {
    if (_busy) return;
    _update(() => _busy = true);
    try {
      await work();
    } on Object catch (error) {
      if (!_disposed) onError(error);
    } finally {
      _update(() => _busy = false);
    }
  }

  /// Starts recording (after [beforeStart]) or stops and hands the file
  /// to [onRecorded]; [newPath] names the file (default: a temp `.wav`).
  Future<void> toggle({
    required Future<void> Function() beforeStart,
    required Future<void> Function(String path) onRecorded,
    Future<String> Function()? newPath,
  }) {
    if (_recording) {
      return guard(() async {
        final String? path;
        try {
          path = await _mic.stop();
        } finally {
          _update(() => _recording = false);
        }
        if (path != null && !_disposed) await onRecorded(path);
      });
    }
    return guard(() async {
      await beforeStart();
      if (!await _mic.hasPermission()) {
        if (!_disposed) onError(AppStrings.audioPermissionDenied);
        return;
      }
      await _mic.start(path: await (newPath?.call() ?? _tempRecordPath()));
      _update(() => _recording = true);
    });
  }

  /// Throws the live recording away: nothing is handed on.
  Future<void> discard() {
    if (!_recording) return Future.value();
    return guard(() async {
      try {
        await _mic.cancel();
      } finally {
        _update(() => _recording = false);
      }
    });
  }

  Future<String> _tempRecordPath() async {
    final dir = await Directory.systemTemp.createTemp('niman_rec_');
    return p.join(
      dir.path,
      'clip-${DateTime.now().millisecondsSinceEpoch}.wav',
    );
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
