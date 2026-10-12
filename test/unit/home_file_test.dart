// #535: `.niman/home.json` on disk, the device's own Home beside it, and
// both following a rename of what their actions name.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/device_settings_store.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_file.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late IndexDatabase db;
  late NoteOps ops;
  late MemoryDeviceSettingsStore device;

  setUp(() async {
    root = await Directory.current.createTemp('niman_home_file_');
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    device = MemoryDeviceSettingsStore();
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: Indexer(db),
      config: LibraryConfigRepo(root.path, device: device),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  File homeFile() => File(p.join(root.path, '.niman', 'home.json'));

  /// A Home whose one actions tile makes notes from [template] in
  /// [folder].
  HomeLayout meeting({
    String template = 'Templates/Meeting.md',
    String folder = 'Work',
  }) => HomeLayout([
    HomeTile(
      id: 'actions',
      kind: HomeTileKind.actions,
      cell: (x: 0, y: 0, w: 2, h: 1),
      at: 0,
      actions: [
        HomeAction(
          id: 'm',
          label: 'Meeting',
          kind: HomeActionKind.newNote,
          template: template,
          folder: folder,
        ),
      ],
    ),
  ]);

  group('HomeFile', () {
    test('reads nothing where there is no file', () async {
      expect(await HomeFile(root.path).read(), isNull);
    });

    test('reads nothing from a file that is not JSON', () async {
      homeFile()
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{not json');
      expect(await HomeFile(root.path).read(), isNull);
    });

    test(
      'sets a file that does not read aside before a write (#694)',
      () async {
        homeFile()
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('{"actions": {,}}');
        final aside = File(p.join(root.path, HomeFile.asidePath))
          ..writeAsStringSync('older');

        await HomeFile(root.path).write(HomeLayout.defaults);

        expect(aside.readAsStringSync(), '{"actions": {,}}');
        expect(await HomeFile(root.path).read(), HomeLayout.defaults);

        await HomeFile(root.path).write(HomeLayout.defaults.hide('recent'));
        expect(
          aside.readAsStringSync(),
          '{"actions": {,}}',
          reason: 'a file that reads is not set aside',
        );
      },
    );

    test('writes a layout it reads back, indented', () async {
      await HomeFile(root.path).write(HomeLayout.defaults);
      expect(await HomeFile(root.path).read(), HomeLayout.defaults);
      expect(homeFile().readAsStringSync(), contains('\n  "actions": {'));
    });

    test('a read waits for the writes still running (#691)', () async {
      final file = HomeFile(root.path);
      final write = file.write(HomeLayout.defaults);
      expect(await file.read(), HomeLayout.defaults);
      await write;
    });

    test('a move nothing points at writes nothing', () async {
      expect(
        await HomeFile(root.path).moved('a.md', 'b.md', isDir: false),
        isFalse,
      );
      expect(homeFile().existsSync(), isFalse);
    });
  });

  group('the library ops', () {
    test(
      'keep the library Home in the file, and drop the device one',
      () async {
        await ops.setHome(meeting(folder: 'Phone'), onDevice: true);
        expect((await ops.home).device, meeting(folder: 'Phone'));
        expect(homeFile().existsSync(), isFalse);

        await ops.setHome(meeting(), onDevice: false);
        final home = await ops.home;
        expect(home.library, meeting());
        expect(home.device, isNull);
        expect(jsonDecode(homeFile().readAsStringSync()), meeting().toJson());
      },
    );

    test('keep the device Home off the library file', () async {
      await ops.setHome(meeting(), onDevice: true);
      final settings = File(p.join(root.path, '.niman', 'settings.json'));
      expect(
        settings.existsSync() &&
            settings.readAsStringSync().contains('Meeting'),
        isFalse,
      );
      expect((await device.read(root.path))!['deviceHome'], meeting().toJson());
    });

    test(
      'make an edit on the file as it is, past a rename it missed (#691)',
      () async {
        await ops.createFolder(parentPath: '', name: 'Templates');
        await ops.createNote(parentPath: 'Templates', name: 'Meeting');
        final shown = meeting().put(HomeLayout.defaults['recent']!);
        await ops.setHome(shown, onDevice: false);
        await ops.rename('Templates', 'Models');

        // The screen still holds the layout from before the rename.
        final edited = await ops.editHome(
          from: shown,
          to: shown.hide('recent'),
          onDevice: false,
        );

        final file = (await ops.home).library!;
        expect(file, edited);
        expect(file['recent']!.hidden, isTrue);
        expect(
          file['actions']!.actions.single.template,
          'Models/Meeting.md',
          reason: 'the rename stands',
        );
      },
    );

    test('carry the actions past a renamed folder, file and device', () async {
      await ops.createFolder(parentPath: '', name: 'Templates');
      await ops.createNote(parentPath: 'Templates', name: 'Meeting');
      await ops.createFolder(parentPath: '', name: 'Work');
      await ops.setHome(meeting(), onDevice: false);
      await ops.rename('Templates', 'Models');
      expect((await ops.home).library, meeting(template: 'Models/Meeting.md'));

      await ops.setHome(meeting(template: 'Models/Meeting.md'), onDevice: true);
      await ops.move('Work', 'Models');
      final home = await ops.home;
      expect(
        home.device,
        meeting(template: 'Models/Meeting.md', folder: 'Models/Work'),
      );
      expect(
        home.library,
        meeting(template: 'Models/Meeting.md', folder: 'Models/Work'),
      );
    });

    test(
      'a remote move carries the device Home and the widgets (#713)',
      () async {
        await ops.createFolder(parentPath: '', name: 'Work');
        await ops.createNote(parentPath: 'Work', name: 'Meeting');
        await ops.setHome(meeting(template: 'Work/Meeting.md'), onDevice: true);
        final settings = File(p.join(root.path, '.niman', 'settings.json'));
        final settingsBefore = settings.readAsStringSync();
        final carried = <String>[];
        final remote = NoteOps(
          root: root.path,
          db: db,
          indexer: ops.indexer,
          config: ops.config,
          carryOutside: (from, to, {required isDir}) async =>
              carried.add('$from -> $to ${isDir ? 'dir' : 'file'}'),
        );

        await remote.syncMove('Work/Meeting.md', 'Work/Notes/Meeting.md');

        final home = await ops.home;
        expect(home.device, meeting(template: 'Work/Notes/Meeting.md'));
        expect(carried, ['Work/Meeting.md -> Work/Notes/Meeting.md file']);
        expect(homeFile().existsSync(), isFalse);
        expect(settings.readAsStringSync(), settingsBefore);
      },
    );
  });
}
