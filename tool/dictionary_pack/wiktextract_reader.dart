// Reads a wiktextract JSONL dump as a stream. The English edition is 24.8 GB
// uncompressed, 2.9 GB gzipped: it is never decompressed to disk, never held,
// and a line is decoded only if it names a language the run builds.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'pack_collectors.dart';
import 'source_entry.dart';

/// Where the entries of one `lang_code` go, and how they are read.
final class LanguageRoute {
  /// Entries read by [parser] go to [sink].
  const new(this.parser, this.sink);

  /// How the entries are read.
  final EntryParser parser;

  /// Where they go.
  final EntrySink sink;
}

/// What a pass saw.
typedef PassResult = ({int lines, int kept, int malformed});

/// The lines of [file], from a gzip stream when it starts with the gzip
/// magic number and as they are otherwise.
Stream<String> readLines(File file) async* {
  final head = await file.openRead(0, 2).fold<List<int>>([], (a, b) => a + b);
  final bytes = file.openRead();
  final raw = head.length == 2 && head[0] == 0x1f && head[1] == 0x8b
      ? bytes.transform(gzip.decoder)
      : bytes;
  yield* raw.transform(utf8.decoder).transform(const LineSplitter());
}

/// Streams [file] and hands every entry whose `lang_code` has a route to it.
/// [log] hears of the progress.
Future<PassResult> streamEntries(
  File file,
  Map<String, LanguageRoute> routes,
  void Function(String message) log,
) async {
  // A cheap test before the expensive one: a line that does not mention a
  // wanted code as a `lang_code` at all is not decoded.
  final wanted = RegExp('"lang_code": ?"(${routes.keys.join('|')})"');
  var lines = 0;
  var kept = 0;
  var malformed = 0;
  final clock = Stopwatch()..start();
  await for (final line in readLines(file)) {
    lines++;
    if (lines % 1000000 == 0) {
      log(
        '  ${file.uri.pathSegments.last}: $lines lines, $kept kept, '
        '${clock.elapsed.inSeconds} s',
      );
    }
    if (!wanted.hasMatch(line)) continue;
    final Object? json;
    try {
      json = jsonDecode(line);
    } on FormatException {
      malformed++;
      continue;
    }
    if (json is! Map<String, Object?>) continue;
    final route = routes[json['lang_code']];
    if (route == null) continue;
    final entry = route.parser.parse(json);
    if (entry == null) continue;
    route.sink.add(entry);
    kept++;
  }
  return (lines: lines, kept: kept, malformed: malformed);
}
