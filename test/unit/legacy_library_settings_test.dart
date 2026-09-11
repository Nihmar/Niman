import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/legacy_library_settings.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late Directory lib;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.current.createTemp('niman_legacy_');
    lib = await tempDir.createTemp('lib_');
    db = AppDatabase(NativeDatabase(File(p.join(tempDir.path, 'test.sqlite'))));
    addTearDown(db.close);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  /// Puts [parked] in `app_settings.legacy_library_settings`, the way the
  /// v14 migration does.
  Future<void> park(Map<String, Object?> parked) async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: const Value(1),
            legacyLibrarySettings: Value(jsonEncode(parked)),
          ),
        );
  }

  Future<String> parkedNow() async {
    final rows = await db.select(db.appSettings).get();
    return rows.isEmpty ? '' : rows.first.legacyLibrarySettings;
  }

  test('a parked library gets its settings file on open', () async {
    await park({
      lib.path: {
        'trashEnabled': false,
        'historyVersions': 3,
        'quickNotePath': 'Inbox/Scratch.md',
        'listNoteFolder': 'Checklists',
      },
    });

    await LegacyLibrarySettings(db).seed(lib.path);

    final config = await LibraryConfigStore(lib.path).read();
    expect(config.trashEnabled, isFalse);
    expect(config.historyVersions, 3);
    expect(config.quickNotePath, 'Inbox/Scratch.md');
    expect(config.listNoteFolder, 'Checklists');
    // Delivered, so no longer parked.
    expect(await parkedNow(), '');
  });

  test('only the opened library is drained', () async {
    await park({
      lib.path: {'trashEnabled': false, 'historyVersions': 3},
      '/elsewhere': {'trashEnabled': true, 'historyVersions': 7},
    });

    await LegacyLibrarySettings(db).seed(lib.path);

    final left = jsonDecode(await parkedNow()) as Map<String, Object?>;
    expect(left.keys, ['/elsewhere']);
  });

  test('nothing parked, nothing written', () async {
    await park({'/elsewhere': <String, Object?>{}});
    await LegacyLibrarySettings(db).seed(lib.path);
    expect(LibraryConfigStore(lib.path).file.existsSync(), isFalse);
  });

  test('an empty payload is not an error', () async {
    await LegacyLibrarySettings(db).seed(lib.path);
    expect(LibraryConfigStore(lib.path).file.existsSync(), isFalse);
  });

  test('an existing settings file wins where the two overlap', () async {
    final store = LibraryConfigStore(lib.path);
    await store.write(LibraryConfig.defaults.copyWith(historyVersions: 42));
    await park({
      lib.path: {'trashEnabled': false, 'historyVersions': 3},
    });

    await LegacyLibrarySettings(db).seed(lib.path);

    // The file is the newer of the two; the parked value does not
    // overwrite what it already answers.
    expect((await store.read()).historyVersions, 42);
    expect(await parkedNow(), '');
  });

  test('a key the file lacks is taken from the parked entry', () async {
    // T-ML-10: an existing library already has the four T-ML-02 settings
    // and none of the seven, so the merge is what carries the user's
    // editor configuration into it.
    final store = LibraryConfigStore(lib.path);
    await store.file.create(recursive: true);
    store.file.writeAsStringSync('{"trashEnabled": false}');
    await park({
      lib.path: {
        'trashEnabled': true,
        'indentWidth': 6,
        'linkType': 'markdown',
      },
    });

    await LegacyLibrarySettings(db).seed(lib.path);

    final config = await store.read();
    expect(config.trashEnabled, isFalse);
    expect(config.indentWidth, 6);
    expect(config.linkType, LinkType.markdown);
    expect(await parkedNow(), '');
  });

  test(
    'an unwritable library keeps its entry parked for the next open',
    () async {
      // A directory where the settings file belongs: the write throws, and
      // losing the settings because a drive was busy would be worse than
      // trying again later.
      final store = LibraryConfigStore(lib.path);
      await Directory(store.file.path).create(recursive: true);
      await park({
        lib.path: {'trashEnabled': false, 'historyVersions': 3},
      });

      await LegacyLibrarySettings(db).seed(lib.path);

      final left = jsonDecode(await parkedNow()) as Map<String, Object?>;
      expect(left.keys, [lib.path]);
    },
  );

  test('a malformed payload is ignored rather than thrown', () async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: const Value(1),
            legacyLibrarySettings: const Value('[1, 2, 3]'),
          ),
        );
    await LegacyLibrarySettings(db).seed(lib.path);
    expect(LibraryConfigStore(lib.path).file.existsSync(), isFalse);
  });

  test('the written file is the real settings file, hand-editable', () async {
    await park({
      lib.path: {'trashEnabled': false, 'historyVersions': 3},
    });
    await LegacyLibrarySettings(db).seed(lib.path);
    final file = File(p.join(lib.path, '.niman', 'settings.json'));
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), contains('"trashEnabled": false'));
  });
}
