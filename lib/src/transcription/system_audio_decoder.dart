/// Audio formats other than WAV decoded by the system, where Niman ships
/// no FFmpeg: AVFoundation on macOS and iOS, through `packages/niman_apple`
/// (docs/records/apple-platforms.md).
///
/// The decoder writes a PCM16 WAV at the source's own rate and channels;
/// the Dart resampler takes it to whisper's 16 kHz mono like any recorded
/// clip, so the two paths are filtered the same way.
library;

import 'dart:io';

import 'package:flutter/services.dart';

/// Decodes the audio at `source` into a WAV at `target`.
typedef AudioDecoder = Future<void> Function({
  required String source,
  required String target,
});

/// The host's decoder, or null where it has none: Android converts in
/// `whisper_ggml`'s FFmpeg, Linux and Windows take WAV only.
AudioDecoder? systemAudioDecoder() =>
    Platform.isIOS || Platform.isMacOS ? _decodeWithAvFoundation : null;

const MethodChannel _audio = MethodChannel('niman/audio');

Future<void> _decodeWithAvFoundation({
  required String source,
  required String target,
}) => _audio.invokeMethod<void>('decodeToWav', {
  'source': source,
  'target': target,
});
