import 'dart:io';

import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/core/settings/library_config_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory lib;
  late LibraryConfigStore store;
  late LibraryConfigRepo repo;

  setUp(() async {
    lib = await Directory.current.createTemp('copist_config_repo_');
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
}
