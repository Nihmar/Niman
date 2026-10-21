// The bounds an EPUB's zip is read within (#1138): its file count, what all
// its files expand to, and what any one read as text may - a lying entry
// (declared small, inflating large) is stopped where it passes the bound.
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_archive.dart';

import '../fakes/raw_deflate_zip.dart';

Matcher _refusedAsTooLarge() => throwsA(
  isA<EpubRefused>().having((e) => e.reason, 'reason', EpubRefusal.tooLarge),
);

void main() {
  EpubArchive open(
    Uint8List zip, {
    int maxBytes = epubMaxBytes,
    int maxEntries = epubMaxEntries,
    int maxTextBytes = epubMaxTextBytes,
  }) => EpubArchive.open(
    InputMemoryStream(zip),
    maxBytes: maxBytes,
    maxEntries: maxEntries,
    maxTextBytes: maxTextBytes,
  );

  Uint8List zipOf(Map<String, String> files) {
    final archive = Archive();
    for (final entry in files.entries) {
      archive.add(ArchiveFile.string(entry.key, entry.value));
    }
    return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
  }

  test('the real bounds are what a book needs and a hostile one passes', () {
    expect(epubMaxTextBytes, lessThan(epubMaxBytes));
    expect(epubMaxTextBytes, greaterThanOrEqualTo(16 << 20));
    expect(epubMaxEntries, 100000);
  });

  test('a zip with more entries than allowed is refused up front', () {
    final zip = zipOf({'a': '1', 'b': '2', 'c': '3'});
    expect(() => open(zip, maxEntries: 2), _refusedAsTooLarge());
    expect(open(zip, maxEntries: 3).has('c'), isTrue);
  });

  test('a text entry over the cap is refused, whatever the budget left', () {
    final zip = zipOf({'big.xhtml': 'x' * 5000, 'small.xhtml': 'ok'});
    final archive = open(zip, maxTextBytes: 1000);
    expect(() => archive.text('big.xhtml'), _refusedAsTooLarge());
    // The cap is per entry: another one is still read, within the budget.
    expect(archive.text('small.xhtml'), 'ok');
  });

  test('the cap is for text: bytes are read within the budget alone', () {
    final zip = zipOf({'picture.png': 'x' * 5000});
    final archive = open(zip, maxTextBytes: 1000);
    expect(archive.bytes('picture.png')!.length, 5000);
  });

  test('an entry that lies about its size is stopped at the cap', () {
    // Declares 10 bytes; inflates to 240000, then is invalid. An inflate
    // that ran on to the end would fail on the invalid block instead of
    // refusing the size.
    final zip = rawDeflateZip(
      'lie.xhtml',
      storedZerosThenInvalid(blocks: 4, size: 60000),
      declared: 10,
    );
    final archive = open(zip, maxTextBytes: 100000);
    expect(() => archive.text('lie.xhtml'), _refusedAsTooLarge());
  });
}
