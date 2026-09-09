import 'dart:io';

import 'package:copist/src/db/app_database.dart';
import 'package:copist/src/library/library_registry.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late LibraryRegistry registry;

  setUp(() async {
    tempDir = await Directory.current.createTemp('copist_registry_');
    db = AppDatabase(NativeDatabase(File(p.join(tempDir.path, 'copist.db'))));
    addTearDown(db.close);
    registry = LibraryRegistry(db);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  /// An absolute library path under the temp dir, so the spelling is
  /// whatever this platform uses.
  String lib(String name) => p.join(tempDir.path, name);

  test('a fresh install knows no libraries', () async {
    expect(await registry.all(), isEmpty);
  });

  test('opening adds an entry named after the folder', () async {
    await registry.touch(lib('Work'));
    final entry = (await registry.all()).single;
    expect(entry.path, lib('Work'));
    expect(entry.name, 'Work');
  });

  test('opening again touches rather than duplicates', () async {
    final first = DateTime(2026, 9, 1, 10);
    final second = DateTime(2026, 9, 9, 18);
    await registry.touch(lib('Work'), at: first);
    await registry.touch(lib('Work'), at: second);
    final entries = await registry.all();
    expect(entries, hasLength(1));
    expect(entries.single.lastOpened, second);
  });

  test('the list reads most recently opened first', () async {
    await registry.touch(lib('Work'), at: DateTime(2026, 9));
    await registry.touch(lib('Personal'), at: DateTime(2026, 9, 8));
    expect((await registry.all()).map((e) => e.name), ['Personal', 'Work']);

    await registry.touch(lib('Work'), at: DateTime(2026, 9, 9));
    expect((await registry.all()).map((e) => e.name), ['Work', 'Personal']);
  });

  test('a name the user chose survives later opens', () async {
    await registry.touch(lib('Work'));
    await registry.rename(lib('Work'), 'Day job');
    await registry.touch(lib('Work'));
    expect((await registry.all()).single.name, 'Day job');
  });

  test('forget removes that entry and only that entry', () async {
    await registry.touch(lib('Work'));
    await registry.touch(lib('Personal'));
    await registry.forget(lib('Work'));
    expect((await registry.all()).map((e) => e.path), [lib('Personal')]);
  });

  test('forgetting a library the app never knew is not an error', () async {
    await registry.forget(lib('Work'));
    expect(await registry.all(), isEmpty);
  });

  test('a path is matched however it was spelled', () async {
    // The controller normalizes before opening; the registry does too, so
    // a trailing separator or a `.` segment is the same library.
    await registry.touch(lib('Work'));
    expect(await registry.find(p.join(lib('Work'), '.')), isNotNull);
    await registry.forget(p.join(lib('Work'), '.'));
    expect(await registry.all(), isEmpty);
  });
}
