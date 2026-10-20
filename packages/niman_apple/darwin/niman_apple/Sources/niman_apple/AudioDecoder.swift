import AVFoundation

/// Audio in any format AVFoundation reads, written out as a PCM16 WAV.
///
/// The WAV keeps the source's rate and channels: the app's Dart resampler
/// takes it from there to whisper's 16 kHz mono, the same path a recorded
/// clip takes, so the two never differ in how they are filtered.
enum AudioDecoder {
  /// Frames read and written per block: bounded memory for a long clip.
  static let blockFrames: AVAudioFrameCount = 1 << 16

  static func decodeToWav(source: URL, target: URL) throws {
    let input = try AVAudioFile(forReading: source)
    let format = input.processingFormat
    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: format.sampleRate,
      AVNumberOfChannelsKey: format.channelCount,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ]
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: blockFrames) else {
      throw NSError(
        domain: "niman_apple", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "no buffer for \(format)"])
    }
    // The file type follows the target's extension (.wav); the output file
    // is closed, and its header written, when it goes out of scope.
    let output = try AVAudioFile(
      forWriting: target, settings: settings, commonFormat: format.commonFormat,
      interleaved: format.isInterleaved)
    while input.framePosition < input.length {
      try input.read(into: buffer, frameCount: blockFrames)
      if buffer.frameLength == 0 { break }
      try output.write(from: buffer)
    }
  }
}
