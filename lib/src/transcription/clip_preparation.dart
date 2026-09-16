import 'dart:io';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/wav_convert.dart';
import 'package:path/path.dart' as p;

/// Converts a WAV clip for whisper; [convertWavForWhisper] in the app.
typedef WavConverter = Future<WavConversion> Function({
  required String source,
  required String target,
});

/// A clip ready for whisper: its `path` in the work folder and its length
/// in ms (0 when unknown before whisper decodes it).
typedef PreparedClip = ({String path, int lengthMs});

/// Puts the clip at [audioPath] in [work] the way whisper reads it: a
/// 16 kHz mono WAV converted by [convert], or, when [packageConverts]
/// (Android), a plain copy the package converts itself with FFmpeg.
///
/// Always a copy in [work], never the clip itself: `whisper_ggml` writes
/// its converted file next to its input, which must not be the library.
/// [label] prefixes the log lines.
Future<PreparedClip> prepareClip({
  required String audioPath,
  required Directory work,
  required WavConverter convert,
  required bool packageConverts,
  required String label,
}) async {
  final clock = Stopwatch()..start();
  if (p.extension(audioPath).toLowerCase() == '.wav') {
    final target = p.join(work.path, 'input.wav');
    final report = await convert(source: audioPath, target: target);
    final lengthMs = report.outputFrames * 1000 ~/ whisperSampleRate;
    _log.info(
      '$label: converted ${report.sampleRate} Hz ${report.channels} ch '
      '${report.bits} bit, ${report.bytesIn} b -> ${report.bytesOut} b, '
      '$lengthMs ms of audio; read ${report.readMs} ms, '
      'filter ${report.dspMs} ms, write ${report.writeMs} ms, '
      'total ${clock.elapsedMilliseconds} ms',
    );
    return (path: target, lengthMs: lengthMs);
  }
  if (!packageConverts) {
    throw const UnsupportedAudioException('only WAV on this platform');
  }
  final target = p.join(work.path, 'input${p.extension(audioPath)}');
  await File(audioPath).copy(target);
  _log.info(
    '$label: copied for the package to convert '
    '(${clock.elapsedMilliseconds} ms)',
  );
  return (path: target, lengthMs: 0);
}

const _log = AppLogger(name: 'transcription');
