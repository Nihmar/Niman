import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// How many leading bytes of a file [wavDurationOf] needs at most: the
/// RIFF header plus the chunks a recorder writes before `data`.
const int wavHeaderProbeBytes = 4096;

/// The length of a WAV file from its leading [header] bytes and its
/// [fileLength], or null when [header] is not a PCM-style RIFF/WAVE file.
///
/// The `data` chunk size comes from the header; a recorder that never
/// patched it (0 or 0xFFFFFFFF) or wrote one past the end of the file
/// falls back to the bytes actually on disk after the chunk header.
Duration? wavDurationOf(Uint8List header, int fileLength) {
  if (header.length < 12) return null;
  final bytes = ByteData.sublistView(header);
  if (_tag(header, 0) != 'RIFF' || _tag(header, 8) != 'WAVE') return null;
  int? byteRate;
  var offset = 12;
  while (offset + 8 <= header.length) {
    final id = _tag(header, offset);
    final size = bytes.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ' && body + 12 <= header.length) {
      byteRate = bytes.getUint32(body + 8, Endian.little);
    } else if (id == 'data') {
      if (byteRate == null || byteRate == 0) return null;
      final onDisk = fileLength - body;
      final dataBytes = size == 0 || size == 0xFFFFFFFF || size > onDisk
          ? onDisk
          : size;
      if (dataBytes <= 0) return Duration.zero;
      return Duration(microseconds: dataBytes * 1000000 ~/ byteRate);
    }
    // Chunks are word-aligned: an odd size carries one pad byte.
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  return null;
}

String _tag(Uint8List bytes, int offset) =>
    String.fromCharCodes(bytes.sublist(offset, offset + 4));

/// The lengths of the `.wav` files among [absolutePaths], read off the UI
/// isolate (every open is a FUSE round trip on Android). Paths that are
/// missing, unreadable or not WAV are left out of the result.
Future<Map<String, Duration>> readWavDurations(List<String> absolutePaths) {
  final wavs = [
    for (final path in absolutePaths)
      if (path.toLowerCase().endsWith('.wav')) path,
  ];
  if (wavs.isEmpty) return Future.value(const {});
  return Isolate.run(() => _probe(wavs));
}

Map<String, Duration> _probe(List<String> paths) {
  final out = <String, Duration>{};
  for (final path in paths) {
    RandomAccessFile? file;
    try {
      file = File(path).openSync();
      final length = file.lengthSync();
      final header = file.readSync(wavHeaderProbeBytes);
      final duration = wavDurationOf(header, length);
      if (duration != null) out[path] = duration;
    } on FileSystemException {
      // A clip that is gone or unreadable simply shows no length.
    } finally {
      file?.closeSync();
    }
  }
  return out;
}
