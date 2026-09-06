import 'dart:io';

/// Copies a markdown fixture into a library as a note, so the editor can be
/// exercised on novel-length content.
///
/// Run from the repo root:
///   `dart run tool/make_perf_note.dart <libraryDir>`
///
/// with an optional size argument, one of: 1kb 10kb 50kb 200kb 500kb 1mb
///
/// Writes `<libraryDir>/perf-<size>.md`.
void main(List<String> args) {
  const sizes = ['1kb', '10kb', '50kb', '200kb', '500kb', '1mb'];
  if (args.isEmpty) {
    stderr.writeln(
        'usage: make_perf_note <libraryDir> [${sizes.join('|')}]');
    exitCode = 1;
    return;
  }
  final size = args.length > 1 ? args[1] : '200kb';
  if (!sizes.contains(size)) {
    stderr.writeln('size must be one of: ${sizes.join(', ')}');
    exitCode = 1;
    return;
  }
  final library = args.first;
  if (!Directory(library).existsSync()) {
    stderr.writeln('no such library directory: $library');
    exitCode = 1;
    return;
  }
  final src = File('test/fixtures/markdown/fixture-$size.md');
  if (!src.existsSync()) {
    stderr.writeln('no such fixture: ${src.path} (run from the repo root)');
    exitCode = 1;
    return;
  }
  final dest = File('$library/perf-$size.md');
  src.copySync(dest.path);
  stdout.writeln('wrote ${dest.path} (${dest.lengthSync()} bytes)');
}
