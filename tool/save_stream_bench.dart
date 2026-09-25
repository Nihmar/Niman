/// Measures a note's save both ways, on the real [SourceBuffer].
///
/// The old shape: join the whole note, hand the string to the writing
/// isolate — a string is copied between isolates, never shared — and encode
/// it there in one go. The new one
/// (`lib/src/library/note_write_stream.dart`): build and encode a slice at
/// a time on this isolate and send the bytes as they are made, so the
/// frames keep coming.
///
/// The claim it checks is the one `docs/records/huge-notes.md` records: on the
/// 247 MB note the old save is one 643 ms turn of the UI isolate, and the
/// new one is a couple of hundred turns under 16 ms. The whole save takes
/// slightly longer new — the slices and the messages cost — and that is the
/// point of it.
///
/// It prints rather than asserts, as the repo's benchmarks do, and JIT
/// inflates the absolutes — the shape carries.
///
/// ```sh
/// dart run tool/save_stream_bench.dart
/// dart run tool/save_stream_bench.dart "Quicknote.md"
/// ```
library;

// A benchmark's whole output is its report.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:niman/src/markdown/source_buffer.dart';

/// The editor's slice: `_NoteViewState.kSaveSliceLines`/`Chars`.
const int _sliceLines = 16384;
const int _sliceChars = 4 << 20;

Future<void> main(List<String> args) async {
  final path = args.isEmpty ? 'Quicknote.md' : args.first;
  final readClock = Stopwatch()..start();
  final raw = await File(path).readAsString();
  final readMs = readClock.elapsedMilliseconds;
  final text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final splitClock = Stopwatch()..start();
  final buffer = SourceBuffer.fromText(text);
  print(
    '$path: ${text.length} chars, ${buffer.lineCount} lines, '
    'read ${readMs}ms, split ${splitClock.elapsedMilliseconds}ms',
  );

  await _old(buffer);
  await _new(buffer);
}

/// The join, then one isolate copy, encode and write.
Future<void> _old(SourceBuffer buffer) async {
  var clock = Stopwatch()..start();
  final joined = buffer.text;
  final joinMs = clock.elapsedMilliseconds;
  clock = Stopwatch()..start();
  final bytes = await Isolate.run(() => utf8.encode(joined).length);
  final copyEncodeMs = clock.elapsedMilliseconds;
  print(
    'OLD  join ${joinMs}ms + isolate(copy+encode) ${copyEncodeMs}ms '
    '= ${joinMs + copyEncodeMs}ms of one-go work on the UI isolate '
    '($bytes bytes, joined ${joined.length} chars)',
  );
}

/// The slice, the encode and the send, with the writer taking them.
Future<void> _new(SourceBuffer buffer) async {
  final done = ReceivePort();
  final ready = ReceivePort();
  final isolate = await Isolate.spawn(_writer, (ready.sendPort, done.sendPort));
  final requests = await ready.first as SendPort;
  final clock = Stopwatch()..start();
  var index = 0;
  var longest = 0;
  var longestMs = 0;
  var worst = 0;
  var slices = 0;
  while (true) {
    final sliceClock = Stopwatch()..start();
    final first = index * _sliceLines;
    if (first >= buffer.lineCount) {
      requests.send(null);
      break;
    }
    final slice = utf8.encode(
      buffer.sliceText(first, first + _sliceLines, _sliceChars),
    );
    final sliceMs = sliceClock.elapsedMilliseconds;
    if (sliceMs > worst) worst = sliceMs;
    if (slice.length > longest) {
      longest = slice.length;
      longestMs = sliceMs;
    }
    slices++;
    index++;
    if (slice.isNotEmpty) requests.send(Uint8List.fromList(slice));
    // What the editor does between slices: give the frames their turn.
    if (index % 8 == 0) await Future<void>.delayed(Duration.zero);
  }
  final bytes = await done.first as int;
  print(
    'NEW  $slices slices, longest ${longest ~/ 1024}KB in ${longestMs}ms, '
    'worst slice ${worst}ms, whole save ${clock.elapsedMilliseconds}ms '
    '($bytes bytes)',
  );
  isolate.kill(priority: Isolate.immediate);
  ready.close();
  done.close();
}

/// Takes what the save sends, as the writing isolate does.
void _writer((SendPort, SendPort) ports) {
  final (ready, done) = ports;
  final requests = ReceivePort();
  ready.send(requests.sendPort);
  var total = 0;
  requests.listen((message) {
    if (message == null) {
      requests.close();
      done.send(total);
      return;
    }
    total += (message as Uint8List).length;
  });
}
