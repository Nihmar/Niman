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

  test('a step up that stays in the library is a sibling', () async {
    // `..` is allowed as long as it does not leave the root: the note's own
    // folder is a probe, not a boundary (#385).
    final sibling = File(p.join(root.path, 'photo.png'))
      ..writeAsStringSync('up');
    expect(
      await resolveEmbedPath('../photo.png', note, root.path, null),
      sibling.path,
    );
  });

  test('an absolute target inside the root is one', () async {
    final absolute = File(p.join(root.path, 'Assets', 'photo.png'))
      ..createSync(recursive: true)
      ..writeAsStringSync('absolute');
    expect(
      await resolveEmbedPath(absolute.path, note, root.path, null),
      absolute.path,
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

  // A note that arrived by sync or import can name any file the app can
  // read; neither the read view nor an export may reach outside the
  // library for it (#385). The library here is a folder of its own, so
  // there is a real parent to point at.
  group('a target that leaves the library', () {
    late Directory outer;
    late Directory library;
    late String notePath;

    setUp(() async {
      outer = await Directory.current.createTemp('niman_embed_outside_');
      library = Directory(p.join(outer.path, 'library'))..createSync();
      notePath = p.join(library.path, 'notes', 'here.md');
      await Directory(p.join(library.path, 'notes')).create();
      await File(notePath).writeAsString('x');
    });

    tearDown(() async {
      if (outer.existsSync()) await outer.delete(recursive: true);
    });

    /// A picture above the library, where a `..` target would land.
    File outsidePicture() => File(p.join(outer.path, 'private', 'shot.png'))
      ..createSync(recursive: true)
      ..writeAsStringSync('private');

    test('is not a path for the root probe', () async {
      final shot = outsidePicture();
      expect(shot.existsSync(), isTrue);
      expect(
        await resolveEmbedPath(
          '../private/shot.png',
          notePath,
          library.path,
          null,
        ),
        isNull,
      );
    });

    test('is not a path for the note-relative probe', () async {
      // One step further out: the root's own probe lands above the temp
      // folder and finds nothing, so the note's folder is the probe that
      // reaches the file — and the one that has to refuse it.
      final shot = outsidePicture();
      expect(shot.existsSync(), isTrue);
      expect(
        await resolveEmbedPath(
          '../../private/shot.png',
          notePath,
          library.path,
          null,
        ),
        isNull,
      );
    });

    test('is not a path when the target names it absolutely', () async {
      final shot = outsidePicture();
      expect(
        await resolveEmbedPath(shot.path, notePath, library.path, null),
        isNull,
      );
    });

    test('is not a path for the index either', () async {
      final shot = outsidePicture();
      final source = FakeLinkSource(
        notes: [p.relative(shot.path, from: library.path)],
      );
      expect(
        await resolveEmbedPath('shot.png', notePath, library.path, source),
        isNull,
      );
    });
  });
}
