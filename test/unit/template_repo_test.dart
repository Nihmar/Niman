// T-M4-05 AC: the template folder is a library setting, and renaming it
// changes where templates come from.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/templates/repo.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteOps ops;
  late TemplateRepo repo;

  setUp(() async {
    root = await Directory.current.createTemp('niman_templates_');
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    indexer = Indexer(db);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    repo = TemplateRepo(indexer.dao, ops);
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  /// Writes `<rel>` under the library and indexes the lot.
  Future<void> seed(Map<String, String> files) async {
    for (final entry in files.entries) {
      final file = File(p.join(root.path, entry.key));
      await file.parent.create(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    await indexer.fullScan(root.path);
  }

  test('the default folder is Templates', () async {
    expect(await ops.templateFolder, defaultTemplateFolder);
    expect(await repo.folder, 'Templates');
  });

  test('a library with no template folder has no templates', () async {
    await seed({'note.md': 'body'});
    expect(await repo.templates(), isEmpty);
  });

  test('templates are the notes under the folder, by name', () async {
    await seed({
      'Templates/Daily.md': 'daily',
      'Templates/Meeting.md': 'meeting',
      'Templates/notes.txt': 'not a note',
      'Elsewhere/Other.md': 'not a template',
    });

    final templates = await repo.templates();
    expect(templates.map((t) => t.name), ['Daily', 'Meeting']);
    expect(templates.first.path, 'Templates/Daily.md');
  });

  test('a template in a subfolder is named by its path below the root', () {
    return seed({
      'Templates/Work/Meeting.md': 'a',
      'Templates/Personal/Meeting.md': 'b',
    }).then((_) async {
      final templates = await repo.templates();
      expect(templates.map((t) => t.name), [
        'Personal/Meeting',
        'Work/Meeting',
      ]);
    });
  });

  test('renaming the folder in settings changes the source', () async {
    await seed({
      'Templates/Daily.md': 'daily',
      'Modelli/Giornaliero.md': 'giornaliero',
    });
    expect((await repo.templates()).map((t) => t.name), ['Daily']);

    await ops.setTemplateFolder(folder: 'Modelli');

    expect(await repo.folder, 'Modelli');
    expect((await repo.templates()).map((t) => t.name), ['Giornaliero']);
  });

  test('the folder is sanitized and persists in the library', () async {
    await ops.setTemplateFolder(folder: '  /Modelli/Note/  ');
    expect(await ops.templateFolder, 'Modelli/Note');

    // An empty choice means the default, not an empty path.
    await ops.setTemplateFolder(folder: '   ');
    expect(await ops.templateFolder, defaultTemplateFolder);

    // It lives in the library's own settings file, so a fresh ops sees it.
    await ops.setTemplateFolder(folder: 'Modelli');
    final other = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    expect(await other.templateFolder, 'Modelli');
  });

  test('nothing under .trash or .history is ever a template', () async {
    // The plan's open question: a template folder that ends up inside a
    // dot folder must not come back. The indexer skips hidden entries, so
    // the repo never sees them — pinned here so it stays that way.
    await seed({
      'Templates/Daily.md': 'daily',
      '.trash/Templates/Deleted.md': 'deleted',
      '.history/Templates/Old.md': 'old',
    });

    expect((await repo.templates()).map((t) => t.name), ['Daily']);

    // Even pointed straight at one, there is nothing there to list.
    await ops.setTemplateFolder(folder: '.trash/Templates');
    expect(await repo.templates(), isEmpty);
  });

  test('the settings file carries the key, defaulted when absent', () async {
    final store = LibraryConfigStore(root.path);
    await store.write(LibraryConfig.defaults);
    expect(
      (await store.read()).templateFolder,
      defaultTemplateFolder,
      reason: 'a fresh library gets the default',
    );

    await store.write(
      LibraryConfig.defaults.copyWith(templateFolder: 'Modelli'),
    );
    expect((await store.read()).templateFolder, 'Modelli');
  });
}
