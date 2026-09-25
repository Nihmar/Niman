// Gathering a note's sources for its exported page (#24): the pictures it
// shows, resolved through the shared embed rule and read as `data:` URIs.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:path/path.dart' as p;

void main() {
  group('picture targets', () {
    test('an embed counts when it names an image, and only then', () {
      expect(ExportSources.pictureTargets('![[photo.png]]\n'), ['photo.png']);
      expect(ExportSources.pictureTargets('![[notes.md]]\n'), isEmpty);
      expect(ExportSources.pictureTargets('![[photo.png|400]]\n'), [
        'photo.png',
      ]);
    });

    test('an embed in code or math is not a picture', () {
      expect(
        ExportSources.pictureTargets('```\n![[photo.png]]\n```\n'),
        isEmpty,
      );
      expect(ExportSources.pictureTargets('`![[photo.png]]`\n'), isEmpty);
      expect(
        ExportSources.pictureTargets('Text \$![[photo.png]]\$\n'),
        isEmpty,
      );
    });

    test("a Markdown image's src is one, as the parser writes it", () {
      expect(ExportSources.pictureTargets('![alt](img/a%20b.png)\n'), [
        'img/a%20b.png',
      ]);
      expect(ExportSources.pictureTargets('![alt](photo.svg)\n'), [
        'photo.svg',
      ]);
    });

    test('a note with none', () {
      expect(ExportSources.pictureTargets('Just text.\n'), isEmpty);
    });
  });

  group('reading them', () {
    late Directory root;
    late String note;

    setUp(() async {
      root = await Directory.current.createTemp('niman_export_');
      note = p.join(root.path, 'here.md');
      await File(note).writeAsString('x');
    });

    tearDown(() async {
      if (root.existsSync()) await root.delete(recursive: true);
    });

    Future<Map<String, String>> imagesOf(String text) =>
        ExportSources.images(text: text, notePath: note, root: root.path);

    test('a picture becomes a data URI, by the target as written', () async {
      final bytes = <int>[1, 2, 3, 4];
      File(p.join(root.path, 'photo.png')).writeAsBytesSync(bytes);
      expect(await imagesOf('![[photo.png]]\n'), {
        'photo.png': 'data:image/png;base64,${base64Encode(bytes)}',
      });
    });

    test('a Markdown image resolves its percent-encoded path', () async {
      File(p.join(root.path, 'img', 'a b.png'))
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[9]);
      final images = await imagesOf('![alt](img/a%20b.png)\n');
      expect(images.keys, ['img/a%20b.png']);
      expect(images.values.single, startsWith('data:image/png;base64,'));
    });

    test('an unreadable picture stays as written', () async {
      expect(await imagesOf('![[gone.png]]\n'), isEmpty);
    });

    test('a target whose type is not an image is skipped', () async {
      File(p.join(root.path, 'drawing.svg')).writeAsStringSync('<svg/>');
      expect(await imagesOf('![alt](drawing.svg)\n'), isEmpty);
    });

    test('a note with none reads nothing and keeps its text', () async {
      final source = await ExportSources.forNote(
        text: 'Just text.\n',
        title: 'A title',
        notePath: note,
        root: root.path,
      );
      expect(source.images, isEmpty);
      expect(source.title, 'A title');
      expect(source.text, 'Just text.\n');
    });

    test('the printed page points at the picture on disk', () async {
      File(p.join(root.path, 'photo.png')).writeAsBytesSync(<int>[1, 2, 3]);
      final source = await ExportSources.forPrint(
        text: '![[photo.png]]\n',
        title: 'A title',
        notePath: note,
        root: root.path,
      );
      // The engine fetches the file itself: the page carries no base64.
      expect(source.images['photo.png'], startsWith('file:'));
      expect(source.images['photo.png'], contains('photo.png'));
    });

    test('a type the data-URI export skips still prints', () async {
      File(p.join(root.path, 'drawing.svg')).writeAsStringSync('<svg/>');
      final urls = await ExportSources.imageUrls(
        text: '![alt](drawing.svg)\n',
        notePath: note,
        root: root.path,
      );
      expect(urls.keys, ['drawing.svg']);
    });
  });

  test('the page is built off the UI isolate', () async {
    const source = NoteHtmlSource(
      text: '# Title\n\nA formula, \$x^2\$, and **bold**.\n',
      title: 'Title',
    );
    final page = await ExportSources.page(source, language: 'it');
    expect(page, contains('<html lang="it">'));
    expect(page, contains('<h1 id="title">Title</h1>'));
    expect(page, contains('<svg '));
    expect(page, contains('<strong>bold</strong>'));
  });
}
