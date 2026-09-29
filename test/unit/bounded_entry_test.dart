// #492: an entry read out of a zip is bounded by what it really expands to,
// while it expands — not after `package:archive` has inflated all of it.
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/bounded_entry.dart';

import '../fakes/raw_deflate_zip.dart';

void main() {
  ArchiveFile entry(List<int> deflated, {int method = 8, int declared = 10}) =>
      ZipDecoder()
          .decodeBytes(
            rawDeflateZip('a.md', deflated, declared: declared, method: method),
          )
          .first;

  test('a bomb is refused with the inflation stopped near the budget', () {
    // 64 MB of zeros deflate to about 64 kB. Read against a 1 MB budget, the
    // inflater must be stopped once the budget is passed: what it produced is
    // counted chunk by chunk as it comes out.
    final deflated = ZLibCodec(raw: true).encode(Uint8List(64 << 20));
    var produced = 0;

    expect(
      () => readEntryWithin(
        entry(deflated),
        1 << 20,
        onInflated: (length) => produced += length,
      ),
      throwsA(isA<EntryOverBudget>()),
    );

    expect(produced, greaterThan(1 << 20), reason: 'it did reach the budget');
    expect(
      produced,
      lessThan(2 << 20),
      reason: 'and was stopped there, not run out to 64 MB',
    );
  });

  test('a deflated entry within the budget is inflated whole', () {
    final text = Uint8List.fromList(List.generate(300000, (i) => i % 251));
    final deflated = ZLibCodec(raw: true).encode(text);

    final bytes = readEntryWithin(entry(deflated), 300000);

    expect(bytes, text);
  });

  test('a stored entry is compared with the budget before it is read', () {
    final text = Uint8List(5000);

    expect(readEntryWithin(entry(text, method: 0), 5000), text);
    expect(
      () => readEntryWithin(entry(text, method: 0), 4999),
      throwsA(isA<EntryOverBudget>()),
    );
  });

  test('an entry with no content answers null, not an empty file', () {
    expect(readEntryWithin(ArchiveFile.noData('a.md'), 1024), isNull);
  });
}
