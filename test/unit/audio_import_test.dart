// Issue #56: recorded/picked audio lands in the library's assets/,
// content-addressed like images, so the same clip never duplicates.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/audio_import.dart';
import 'package:path/path.dart' as p;

void main() {
  test('import copies into assets/ and dedupes by content', () async {
    final dir = await Directory.systemTemp.createTemp('niman_audio_');
    try {
      final source = File(p.join(dir.path, 'clip.wav'));
      await source.writeAsBytes(List<int>.generate(64, (i) => i));

      final library = Directory(p.join(dir.path, 'lib'))..createSync();
      final first = await importAudioToLibrary(
        libraryRoot: library.path,
        sourcePath: source.path,
      );
      expect(first.startsWith('assets/'), isTrue);
      expect(first.endsWith('.wav'), isTrue);
      expect(File(p.join(library.path, first)).existsSync(), isTrue);

      final second = await importAudioToLibrary(
        libraryRoot: library.path,
        sourcePath: source.path,
      );
      expect(second, first);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('a configured attachments folder receives the copy', () async {
    final dir = await Directory.systemTemp.createTemp('niman_audio2_');
    try {
      final source = File(p.join(dir.path, 'clip.wav'));
      await source.writeAsBytes(List<int>.generate(64, (i) => i));

      final library = Directory(p.join(dir.path, 'lib'))..createSync();
      final relative = await importAudioToLibrary(
        libraryRoot: library.path,
        sourcePath: source.path,
        attachmentsFolder: 'Attachments',
      );
      expect(relative.startsWith('Attachments/'), isTrue);
      expect(File(p.join(library.path, relative)).existsSync(), isTrue);
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
