// The streamed walk (#302): one directory at a time, parents before their
// children, so a full scan can mirror a listing and move on instead of
// holding the whole tree.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_walk_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('yields one listing per directory, parents before children', () async {
    File(p.join(root.path, 'b.md')).writeAsStringSync('b');
    File(p.join(root.path, 'a.md')).writeAsStringSync('a');
    Directory(p.join(root.path, 'z')).createSync();
    File(p.join(root.path, 'z/y.md')).writeAsStringSync('y');
    Directory(p.join(root.path, 'z/x')).createSync();
    File(p.join(root.path, 'z/x/w.md')).writeAsStringSync('w');
    Directory(p.join(root.path, '.hidden')).createSync();
    File(p.join(root.path, '.hidden/h.md')).writeAsStringSync('h');

    final walk = await DirWalker.start(root.path);
    addTearDown(walk.close);
    final listings = <DirListing>[];
    for (
      var listing = await walk.next();
      listing != null;
      listing = await walk.next()
    ) {
      listings.add(listing);
    }

    expect(listings.map((l) => l.rel), ['', 'z', 'z/x']);
    expect(listings.first.entries.map((e) => e.name), ['a.md', 'b.md', 'z']);
    expect(listings.first.entries.last.isDir, isTrue);
    expect(listings.first.entries.first.size, 1);
    expect(listings[1].entries.map((e) => e.name), ['x', 'y.md']);
    expect(listings[2].entries.map((e) => e.name), ['w.md']);
    expect(listings.every((l) => l.failed), isFalse);
    expect(listings.first.logs, contains(contains('.hidden')));
  });

  test('a directory that vanishes is reported, not thrown', () async {
    final gone = Directory(p.join(root.path, 'gone'))..createSync();
    File(p.join(gone.path, 'x.md')).writeAsStringSync('x');
    final walk = await DirWalker.start(root.path);
    addTearDown(walk.close);

    final first = await walk.next();
    expect(first!.entries.map((e) => e.name), ['gone']);
    await gone.delete(recursive: true);

    final second = await walk.next();
    expect(second!.rel, 'gone');
    expect(second.failed, isTrue);
    expect(second.entries, isEmpty);
    expect(await walk.next(), isNull);
  });

  test('an empty library is one empty listing', () async {
    final walk = await DirWalker.start(root.path);
    addTearDown(walk.close);

    final listing = await walk.next();
    expect(listing!.rel, '');
    expect(listing.entries, isEmpty);
    expect(await walk.next(), isNull);
  });
}
