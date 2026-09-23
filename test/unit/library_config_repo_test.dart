import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/device_settings_store.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';

void main() {
  late Directory lib;
  late LibraryConfigStore store;
  late LibraryConfigRepo repo;

  setUp(() async {
    lib = await Directory.current.createTemp('niman_config_repo_');
    store = LibraryConfigStore(lib.path);
    repo = LibraryConfigRepo(lib.path);
  });

  tearDown(() async {
    await lib.delete(recursive: true);
  });

  test('a library with no settings file reads the defaults', () async {
    expect(await repo.config, LibraryConfig.defaults);
  });

  test('an update writes the file and is visible at once', () async {
    await repo.update((c) => c.copyWith(trashEnabled: false));
    expect((await repo.config).trashEnabled, isFalse);
    expect((await store.read()).trashEnabled, isFalse);
  });

  test('the file is read once, not on every call', () async {
    expect((await repo.config).trashEnabled, isTrue);
    // Behind the repo's back: a cached value must not notice.
    await store.write(LibraryConfig.defaults.copyWith(trashEnabled: false));
    expect((await repo.config).trashEnabled, isTrue);
  });

  test('a change that alters nothing writes no file', () async {
    await repo.update((c) => c.copyWith(trashEnabled: true));
    expect(store.file.existsSync(), isFalse);
  });

  test('concurrent updates all land', () async {
    // Read-modify-write over one file: without serialization the later
    // writes would each start from the same original config.
    await Future.wait([
      repo.update((c) => c.copyWith(trashEnabled: false)),
      repo.update((c) => c.copyWith(historyVersions: 3)),
      repo.update((c) => c.copyWith(listNoteFolder: 'Checklists')),
    ]);
    final written = await store.read();
    expect(written.trashEnabled, isFalse);
    expect(written.historyVersions, 3);
    expect(written.listNoteFolder, 'Checklists');
  });

  test('a failed write leaves the cache alone', () async {
    // A directory where the settings file belongs: the write throws.
    await Directory(store.file.path).create(recursive: true);
    await expectLater(
      repo.update((c) => c.copyWith(trashEnabled: false)),
      throwsA(isA<Object>()),
    );
    expect((await repo.config).trashEnabled, isTrue);
  });

  test('unknown keys survive an update', () async {
    await store.file.create(recursive: true);
    store.file.writeAsStringSync('{"futureSetting": {"a": 1}}');
    final fresh = LibraryConfigRepo(lib.path);
    await fresh.update((c) => c.copyWith(historyVersions: 4));
    expect(store.file.readAsStringSync(), contains('"futureSetting"'));
  });

  group('with the device keeping its share', () {
    late MemoryDeviceSettingsStore device;
    late LibraryConfigRepo split;
    var written = 0;

    setUp(() {
      device = MemoryDeviceSettingsStore();
      written = 0;
      split = LibraryConfigRepo(lib.path, device: device)
        ..onWritten = () => written++;
    });

    Map<String, Object?> fileJson() =>
        (jsonDecode(store.file.readAsStringSync()) as Map)
            .cast<String, Object?>();

    test('device keys stay out of the file', () async {
      await split.update(
        (c) => c.copyWith(trashEnabled: false, treeWidth: 320),
      );
      final json = fileJson();
      expect(json['trashEnabled'], isFalse);
      for (final key in LibraryConfig.deviceKeys) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
      expect((await device.read(lib.path))!['treeWidth'], 320.0);
      expect(written, 1);
    });

    test('a device key alone never touches the file', () async {
      await split.update((c) => c.copyWith(trashEnabled: false));
      final before = store.file.statSync().modified;
      await split.update((c) => c.copyWith(treeWidth: 400, lineNumbers: false));
      expect(store.file.statSync().modified, before);
      expect(written, 1, reason: 'the sync hears of the file change only');
      final fresh = LibraryConfigRepo(lib.path, device: device);
      expect((await fresh.config).treeWidth, 400);
      expect((await fresh.config).lineNumbers, isFalse);
    });

    test('the first read takes the device keys from the file', () async {
      await store.file.create(recursive: true);
      store.file.writeAsStringSync(
        '{"trashEnabled": false, "treeWidth": 310, "lineNumbers": false}',
      );
      final config = await split.config;
      expect(config.trashEnabled, isFalse);
      expect(config.treeWidth, 310);
      expect(config.lineNumbers, isFalse);
      expect(await device.read(lib.path), {
        'treeWidth': 310,
        'lineNumbers': false,
      });
    });

    test('after that, the file has no say on device keys', () async {
      await split.update((c) => c.copyWith(treeWidth: 300));
      // An older build on another device writes its own width back.
      store.file.writeAsStringSync('{"treeWidth": 999, "historyVersions": 3}');
      final fresh = LibraryConfigRepo(lib.path, device: device);
      expect((await fresh.config).treeWidth, 300);
      expect((await fresh.config).historyVersions, 3);
    });
  });
}
