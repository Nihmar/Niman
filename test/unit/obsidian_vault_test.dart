// #25, the Obsidian half: a vault is not imported, it is opened — the
// folder becomes the library, and what an Obsidian user wrote in it has
// to read the same way once the index has walked it: wikilinks resolve,
// aliased links too, embeds find their attachment by bare name, and the
// vault's own hidden folders stay out of the tree.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteDao dao;

  setUp(() async {
    root = await Directory.current.createTemp('niman_vault_');
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    indexer = Indexer(db);
    dao = indexer.dao;
  });

  tearDown(() => root.delete(recursive: true));

  Future<void> write(String rel, String text) async {
    final file = File(p.joinAll([root.path, ...rel.split('/')]));
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
  }

  test('a vault opens as a library: links, aliases, embeds, hidden', () async {
    await write(
      'Welcome.md',
      '---\ntags: [start]\n---\n'
          '# Welcome\n\n'
          'See [[Ideas]] and [[Notes/Deep note|the deep one]].\n\n'
          '![[attachments/pic.png]]\n',
    );
    await write('Ideas.md', '# Ideas\n\nBack to [[Welcome]].\n');
    await write('Notes/Deep note.md', '# Deep\n');
    await write('attachments/pic.png', 'png');
    await write('.obsidian/workspace.json', '{}');
    await write('.obsidian/notes.md', 'never a note');
    await write('.trash/old.md', 'never either');

    await indexer.fullScan(root.path);

    // The vault's notes and its attachment, nothing hidden.
    expect(await dao.find('Welcome.md'), isNotNull);
    expect(await dao.find('Ideas.md'), isNotNull);
    expect(await dao.find('Notes/Deep note.md'), isNotNull);
    expect(await dao.find('attachments/pic.png'), isNotNull);
    expect(await dao.find('.obsidian/workspace.json'), isNull);
    expect(await dao.find('.obsidian/notes.md'), isNull);
    expect(await dao.find('.trash/old.md'), isNull);

    // Wikilinks, an aliased one included, and the embed — a reference a
    // move must carry (#507) — became edges.
    final welcome = (await dao.find('Welcome.md'))!;
    final ideas = (await dao.find('Ideas.md'))!;
    final deep = (await dao.find('Notes/Deep note.md'))!;
    final pic = (await dao.find('attachments/pic.png'))!;
    final links = await (db.select(
      db.noteLinks,
    )..where((l) => l.fromNote.equals(welcome.id))).get();
    expect(links.map((l) => l.kind), everyElement('wiki'));
    expect(links.map((l) => l.toNote).toSet(), {ideas.id, deep.id, pic.id});

    // The frontmatter tags are indexed, and the embed resolves by bare
    // name the way Obsidian's does.
    final tags = await (db.select(
      db.noteTags,
    )..where((t) => t.noteId.equals(welcome.id))).get();
    expect(tags.map((t) => t.tag), ['start']);
    final resolved = await LinkResolver(db).resolveWiki('pic.png');
    expect(resolved, isA<ResolvedNote>());
    expect((resolved as ResolvedNote).note.path, 'attachments/pic.png');
  });
}
