// A note that is a symbolic link is written through it (#1368): the atomic
// rename used to replace the link with a regular file, so the link's target
// was never updated and the link was gone.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  late Directory elsewhere;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('niman_link');
    elsewhere = Directory.systemTemp.createTempSync('niman_link_target');
  });
  tearDown(() {
    dir.deleteSync(recursive: true);
    elsewhere.deleteSync(recursive: true);
  });

  /// Whether this machine lets a program make a symbolic link: on Windows
  /// that takes a privilege.
  final canLink = () {
    final probe = Directory.systemTemp.createTempSync('niman_link_probe');
    try {
      File(p.join(probe.path, 't')).writeAsStringSync('t');
      Link(p.join(probe.path, 'l')).createSync(p.join(probe.path, 't'));
      return true;
    } on FileSystemException {
      return false;
    } finally {
      probe.deleteSync(recursive: true);
    }
  }();
  final skip = canLink ? null : 'symbolic links need a privilege here';

  bool isLink(String path) =>
      FileSystemEntity.typeSync(path, followLinks: false) ==
      FileSystemEntityType.link;

  /// What is in [folder]: a temp file left behind would show.
  List<String> names(Directory folder) =>
      folder.listSync().map((e) => p.basename(e.path)).toList()..sort();

  group('writeFileAtomically through a symbolic link', () {
    test('a link to a file beside it stays a link and its target is '
        'written', () async {
      final target = File(p.join(dir.path, 'real.md'))
        ..writeAsStringSync('old');
      final link = p.join(dir.path, 'note.md');
      Link(link).createSync('real.md');

      await writeFileAtomically(File(link), utf8.encode('new text'));

      expect(isLink(link), isTrue);
      expect(target.readAsStringSync(), 'new text');
      expect(File(link).readAsStringSync(), 'new text');
      expect(names(dir), ['note.md', 'real.md']);
    }, skip: skip);

    test('a link to a file in another folder writes that file in its own '
        'folder', () async {
      final target = File(p.join(elsewhere.path, 'real.md'))
        ..writeAsStringSync('old');
      final link = p.join(dir.path, 'note.md');
      Link(link).createSync(target.path);

      await writeFileAtomically(File(link), utf8.encode('new text'));

      expect(isLink(link), isTrue);
      expect(target.readAsStringSync(), 'new text');
      expect(names(dir), ['note.md']);
      expect(names(elsewhere), ['real.md']);
    }, skip: skip);

    test('a relative link to another folder, and a chain of links, are '
        'followed', () async {
      final target = File(p.join(elsewhere.path, 'real.md'))
        ..writeAsStringSync('old');
      final second = p.join(dir.path, 'second.md');
      Link(second).createSync(target.path);
      final first = p.join(dir.path, 'first.md');
      Link(first).createSync('second.md');

      await writeFileAtomically(File(first), utf8.encode('through two'));

      expect(isLink(first), isTrue);
      expect(isLink(second), isTrue);
      expect(target.readAsStringSync(), 'through two');
    }, skip: skip);

    test('a link whose target is not there yet creates it', () async {
      final target = p.join(dir.path, 'later.md');
      final link = p.join(dir.path, 'note.md');
      Link(link).createSync('later.md');

      await writeFileAtomically(File(link), utf8.encode('created'));

      expect(isLink(link), isTrue);
      expect(File(target).readAsStringSync(), 'created');
    }, skip: skip);

    test('a link that points at itself is written as the path itself, not '
        'looped on', () async {
      final link = p.join(dir.path, 'loop.md');
      Link(link).createSync('loop.md');
      // Whatever the platform does with it, the write ends.
      await writeFileAtomically(
        File(link),
        utf8.encode('x'),
      ).then<void>((_) {}, onError: (Object _) {});
    }, skip: skip);

    test('a regular file is replaced as it always was', () async {
      final file = File(p.join(dir.path, 'plain.md'))..writeAsStringSync('old');
      await writeFileAtomically(file, utf8.encode('new'));
      expect(file.readAsStringSync(), 'new');
      expect(isLink(file.path), isFalse);
      expect(names(dir), ['plain.md']);
    });
  });

  group('the streaming writer through a symbolic link', () {
    test('keeps the link and writes its target in another folder', () async {
      final target = File(p.join(elsewhere.path, 'real.md'))
        ..writeAsStringSync('old');
      final link = p.join(dir.path, 'note.md');
      Link(link).createSync(target.path);

      await saveNoteStream(
        root: dir.path,
        rel: 'note.md',
        produce: (index) async => index == 0
            ? Uint8List.fromList(utf8.encode('streamed text'))
            : null,
      );

      expect(isLink(link), isTrue);
      expect(target.readAsStringSync(), 'streamed text');
      expect(names(dir), ['note.md']);
      expect(names(elsewhere), ['real.md']);
    }, skip: skip);
  });
}
