// A save keeps the note's creation time (#759): every save writes a temp
// file and renames it over the note, and on Windows the rename made the
// note the temp's age — so the tree's "Date created" order put an edited old
// note first. Each writer that renames over a note is saved through here,
// and the creation time read back. Windows is the platform that keeps one.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/creation_time.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/db/index_scan.dart';
import 'package:niman/src/frontmatter/edit_in_file.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:path/path.dart' as p;

/// 2020-01-01 UTC as a Windows `FILETIME`: 100 ns ticks since 1601.
final int _old2020 =
    DateTime.utc(2020).microsecondsSinceEpoch * 10 + 116444736000000000;

void main() {
  final windowsOnly = Platform.isWindows
      ? null
      : 'Windows is the platform that keeps a creation time';

  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('niman_created_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  /// A note at [rel], made in 2020 as far as the file system says.
  String oldNote(String rel, [String text = 'old\n']) {
    final abs = p.join(root.path, rel);
    File(abs).writeAsStringSync(text);
    expect(writeCreationTime(abs, _old2020), isTrue);
    expect(createdOf(FileStat.statSync(abs)).toUtc().year, 2020);
    return abs;
  }

  void expectStillOld(String abs) {
    expect(readCreationTime(abs), _old2020);
    expect(createdOf(FileStat.statSync(abs)).toUtc(), DateTime.utc(2020));
  }

  test('an atomic write keeps the creation time', skip: windowsOnly, () async {
    final abs = oldNote('a.md');
    await writeFileAtomically(File(abs), utf8.encode('new\n'));
    expect(File(abs).readAsStringSync(), 'new\n');
    expectStillOld(abs);
  });

  test('a note save keeps the creation time', skip: windowsOnly, () async {
    final abs = oldNote('a.md');
    await writeNoteFile(abs, 'new\n');
    expectStillOld(abs);
  });

  test('a save in slices keeps the creation time', skip: windowsOnly, () async {
    final abs = oldNote('a.md');
    await saveNoteStream(
      root: root.path,
      rel: 'a.md',
      produce: (index) async =>
          index == 0 ? Uint8List.fromList(utf8.encode('new\n')) : null,
    );
    expect(File(abs).readAsStringSync(), 'new\n');
    expectStillOld(abs);
  });

  test(
    'a frontmatter edit keeps the creation time',
    skip: windowsOnly,
    () async {
      final abs = oldNote('a.md', '---\ntitle: A\n---\n\nbody\n');
      await editFrontmatterKeyInFile(abs, 'title', 'B');
      expect(File(abs).readAsStringSync(), contains('title: B'));
      expectStillOld(abs);
    },
  );

  test('a synced file keeps the creation time', skip: windowsOnly, () async {
    final note = oldNote('a.md');
    final noteTemp = p.join(root.path, '.a.md.tmp');
    File(noteTemp).writeAsStringSync('remote\n');
    await replaceFileFrom(note, noteTemp);
    expectStillOld(note);

    final attachment = oldNote('b.png', 'png');
    final attachmentTemp = p.join(root.path, '.b.png.tmp');
    File(attachmentTemp).writeAsStringSync('png2');
    await swapFileIn(attachment, attachmentTemp);
    expectStillOld(attachment);
  });

  test('a staged copy keeps the creation time', skip: windowsOnly, () async {
    final abs = oldNote('b.png', 'png');
    final temp = p.join(root.path, '.b.png.tmp');
    File(temp).writeAsStringSync('png2');
    await copyFileOver(abs, temp);
    expect(File(abs).readAsStringSync(), 'png2');
    expectStillOld(abs);
  });

  test('a new note is written whole, with its own time', () async {
    final abs = p.join(root.path, 'new.md');
    keepCreationTime(target: abs, replacement: abs);
    await writeFileAtomically(File(abs), utf8.encode('new\n'));
    expect(File(abs).readAsStringSync(), 'new\n');
  });
}
