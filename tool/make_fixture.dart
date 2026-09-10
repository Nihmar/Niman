import 'dart:io';

/// Writes a synthetic note library, for the scale gate (T-M6-01).
///
/// Run from the repo root:
///   `dart run tool/make_fixture.dart <dir> [notes] [notesPerFolder]`
///
/// Defaults to a million notes in folders of a thousand. That is a real
/// library made of real files, and it writes about 400 of them a second
/// on a Windows laptop with a virus scanner in the path — call it half an
/// hour and a couple of hundred megabytes for the full million. Generate
/// it once and keep it: opening it in the app is the on-device half of
/// the gate, the half no test can fake.
/// The other half, what a million rows cost the index, is measured
/// without any of this by `test/perf/index_scale_test.dart`.
///
/// Every note carries frontmatter with a title and two tags, a body with
/// a number that appears in exactly one note, and a wikilink into the
/// next folder — so indexing, search, tags and links all have real work
/// rather than a million copies of the same string.
void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: make_fixture <dir> [notes] [notesPerFolder]');
    exitCode = 1;
    return;
  }
  final root = Directory(args.first);
  final notes = args.length > 1 ? int.tryParse(args[1]) ?? 1000000 : 1000000;
  final perFolder = args.length > 2 ? int.tryParse(args[2]) ?? 1000 : 1000;
  if (notes < 1 || perFolder < 1) {
    stderr.writeln('notes and notesPerFolder must be positive');
    exitCode = 1;
    return;
  }
  if (root.existsSync() && root.listSync().isNotEmpty) {
    stderr.writeln('${root.path} is not empty — refusing to write into it');
    exitCode = 1;
    return;
  }
  root.createSync(recursive: true);

  final folders = (notes / perFolder).ceil();
  final clock = Stopwatch()..start();
  var written = 0;
  for (var f = 0; f < folders; f++) {
    final folder = Directory('${root.path}/${_folder(f)}')..createSync();
    for (var n = 0; n < perFolder && written < notes; n++) {
      final name = '${_folder(f)}_${_pad(n)}';
      final next = '${_folder((f + 1) % folders)}_${_pad(0)}';
      File('${folder.path}/$name.md').writeAsStringSync(
        '---\n'
        'title: $name title\n'
        'tags: [fixture, ${n.isEven ? 'even' : 'odd'}]\n'
        '---\n'
        '# $name\n\n'
        'Body of $name with seed $written and a link to [[$next]].\n',
      );
      written++;
    }
    if (f % 50 == 0) {
      stdout.writeln(
        '$written/$notes notes, ${clock.elapsed.inSeconds}s elapsed',
      );
    }
  }
  stdout.writeln(
    'wrote $written notes in $folders folders under ${root.path} '
    'in ${clock.elapsed.inSeconds}s',
  );
}

String _folder(int f) => 'f${f.toString().padLeft(4, '0')}';

String _pad(int n) => n.toString().padLeft(4, '0');
