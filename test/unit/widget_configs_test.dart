// Widget configuration store (issue 6): one row per placed widget
// instance, keyed by the Android widget id.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late WidgetConfigStore store;

  setUp(() async {
    tempDir = await Directory.current.createTemp('niman_widgets_');
    db = AppDatabase(NativeDatabase(File(p.join(tempDir.path, 'niman.db'))));
    addTearDown(db.close);
    store = WidgetConfigStore(db);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  /// An absolute library path under the temp dir, so the spelling is
  /// whatever this platform uses.
  String lib(String name) => p.join(tempDir.path, name);

  test('a fresh install configures no widgets', () async {
    expect(await store.all(), isEmpty);
    expect(await store.find(42), isNull);
  });

  test('a todo widget needs no note', () async {
    await store.upsert(
      androidWidgetId: 7,
      provider: WidgetProvider.todo,
      libraryPath: lib('Work'),
    );
    final row = (await store.find(7))!;
    expect(row.provider, 'todo');
    expect(row.libraryPath, lib('Work'));
    expect(row.notePath, isNull);
  });

  test('a note widget without a note is rejected', () async {
    expect(
      () => store.upsert(
        androidWidgetId: 7,
        provider: WidgetProvider.note,
        libraryPath: lib('Work'),
      ),
      throwsArgumentError,
    );
    expect(await store.find(7), isNull);
  });

  test('reconfiguring replaces the row', () async {
    await store.upsert(
      androidWidgetId: 7,
      provider: WidgetProvider.todo,
      libraryPath: lib('Work'),
      at: DateTime(2026, 9),
    );
    await store.upsert(
      androidWidgetId: 7,
      provider: WidgetProvider.note,
      libraryPath: lib('Personal'),
      notePath: 'todo.md',
      at: DateTime(2026, 9, 9),
    );
    final rows = await store.all();
    expect(rows, hasLength(1));
    expect(rows.single.provider, 'note');
    expect(rows.single.libraryPath, lib('Personal'));
    expect(rows.single.notePath, 'todo.md');
  });

  test('two instances coexist for two libraries', () async {
    await store.upsert(
      androidWidgetId: 7,
      provider: WidgetProvider.todo,
      libraryPath: lib('Work'),
    );
    await store.upsert(
      androidWidgetId: 8,
      provider: WidgetProvider.todo,
      libraryPath: lib('Personal'),
    );
    expect(
      (await store.forLibrary(lib('Work'))).map((r) => r.androidWidgetId),
      [7],
    );
    expect(await store.all(), hasLength(2));
  });

  test('removing drops that instance only', () async {
    await store.upsert(
      androidWidgetId: 7,
      provider: WidgetProvider.todo,
      libraryPath: lib('Work'),
    );
    await store.upsert(
      androidWidgetId: 8,
      provider: WidgetProvider.note,
      libraryPath: lib('Work'),
      notePath: 'todo.md',
    );
    await store.remove(7);
    expect((await store.all()).map((r) => r.androidWidgetId), [8]);
  });

  test('forgetting a library drops its widgets', () async {
    await store.upsert(
      androidWidgetId: 7,
      provider: WidgetProvider.todo,
      libraryPath: lib('Work'),
    );
    await store.upsert(
      androidWidgetId: 8,
      provider: WidgetProvider.note,
      libraryPath: lib('Personal'),
      notePath: 'todo.md',
    );
    await store.removeForLibrary(lib('Work'));
    expect((await store.all()).map((r) => r.androidWidgetId), [8]);
  });
}
