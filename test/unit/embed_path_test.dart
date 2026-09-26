// The shared embed-path rule (#24): the lookup order the read view and the
// export both use.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/embed_path.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_link_source.dart';

void main() {
  late Directory root;
  late String note;

  setUp(() async {
    root = await Directory.current.createTemp('niman_embed_');
    note = p.join(root.path, 'notes', 'here.md');
    await Directory(p.join(root.path, 'notes')).create(recursive: true);
    await File(note).writeAsString('x');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('the library root comes first', () async {
    final atRoot = File(p.join(root.path, 'photo.png'))
      ..writeAsStringSync('root');
    File(p.join(root.path, 'notes', 'photo.png')).writeAsStringSync('beside');
    expect(
      await resolveEmbedPath('photo.png', note, root.path, null),
      atRoot.path,
    );
  });

  test("then the note's own folder", () async {
    final beside = File(p.join(root.path, 'notes', 'photo.png'))
      ..writeAsStringSync('beside');
    expect(
      await resolveEmbedPath('photo.png', note, root.path, null),
      beside.path,
    );
  });

  test('then the link index, by unique name', () async {
    final indexed = File(p.join(root.path, 'Attachments', 'photo.png'))
      ..createSync(recursive: true)
      ..writeAsStringSync('indexed');
    final source = FakeLinkSource(notes: ['Attachments/photo.png']);
    expect(
      await resolveEmbedPath('photo.png', note, root.path, source),
      indexed.path,
    );
    expect(source.queries, ['wiki:photo.png']);
  });

  test('a nested target is joined whole', () async {
    final nested = File(p.join(root.path, 'Assets', 'a b.png'))
      ..createSync(recursive: true)
      ..writeAsStringSync('nested');
    expect(
      await resolveEmbedPath('Assets/a b.png', note, root.path, null),
      nested.path,
    );
  });

  test('nothing there is null, and an empty target is not asked', () async {
    final source = FakeLinkSource(notes: ['Attachments/photo.png']);
    expect(
      await resolveEmbedPath('missing.png', note, root.path, source),
      isNull,
    );
    expect(await resolveEmbedPath('', note, root.path, source), isNull);
    expect(source.queries, ['wiki:missing.png']);
  });

  test('the index naming a file that is gone is not a path', () async {
    final source = FakeLinkSource(notes: ['Attachments/gone.png']);
    expect(await resolveEmbedPath('gone.png', note, root.path, source), isNull);
  });

  test('with no link source only the folders are searched', () async {
    File(p.join(root.path, 'Attachments', 'photo.png'))
      ..createSync(recursive: true)
      ..writeAsStringSync('indexed');
    expect(await resolveEmbedPath('photo.png', note, root.path, null), isNull);
  });
}
