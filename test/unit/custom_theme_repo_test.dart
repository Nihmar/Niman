// Issue #269: custom themes live in the app's own database, by name, and
// a row this build cannot read is skipped rather than fatal.
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/custom_theme_repo.dart';
import 'package:niman/src/core/theme_colors.dart';
import 'package:niman/src/db/app_database.dart';

import '../fakes/sample_themes.dart';

void main() {
  late AppDatabase db;
  late CustomThemeRepo repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CustomThemeRepo(db);
  });

  tearDown(() => db.close());

  test('a fresh install holds no themes of its own', () async {
    expect(await repo.list(), isEmpty);
  });

  test('a saved theme comes back whole', () async {
    final theme = sampleCustomTheme();
    await repo.save(theme);
    expect(await repo.byId('sample'), theme);
    expect(await repo.list(), [theme]);
  });

  test('saving the same id again replaces it', () async {
    await repo.save(sampleCustomTheme(name: 'First'));
    await repo.save(sampleCustomTheme(name: 'Second'));
    expect((await repo.list()).single.name, 'Second');
  });

  test('the list comes back by name, whatever the case', () async {
    await repo.save(sampleCustomTheme(id: 'b', name: 'Zebra'));
    await repo.save(sampleCustomTheme(id: 'a', name: 'apple'));
    await repo.save(sampleCustomTheme(id: 'c', name: 'Mango'));
    expect((await repo.list()).map((theme) => theme.name), [
      'apple',
      'Mango',
      'Zebra',
    ]);
  });

  test('a name is taken without regard to case, and after trimming', () async {
    await repo.save(sampleCustomTheme(name: 'Sea Glass'));
    expect(await repo.nameTaken('sea glass'), isTrue);
    expect(await repo.nameTaken('  Sea Glass  '), isTrue);
    expect(await repo.nameTaken('Sea'), isFalse);
  });

  test('the database refuses a duplicate name outright', () async {
    await repo.save(sampleCustomTheme(id: 'one', name: 'Mine'));
    // The unique index the migration creates, not just a check in Dart:
    // two rows with one name would be two rows the list cannot tell apart.
    await expectLater(
      repo.save(sampleCustomTheme(id: 'two', name: 'mine')),
      throwsA(isA<Exception>()),
    );
  });

  test('a stored name is cleaned, not stored as typed', () async {
    await repo.save(sampleCustomTheme(name: '  Padded  '));
    expect((await repo.list()).single.name, 'Padded');
  });

  test('a row this build cannot read is skipped, not fatal', () async {
    await db.customStatement(
      'INSERT INTO custom_themes (id, name, day_colors, night_colors) '
      "VALUES ('bad', 'Broken', '{\"background\":\"#FFFFFF\"}', '{}')",
    );
    expect(await repo.list(), isEmpty);
    expect(await repo.byId('bad'), isNull);
  });

  test('a row saved before the task-list roles still loads', () async {
    // Written by a build that did not have them: the theme is kept, and a
    // task list wears what it wore then.
    final theme = sampleCustomTheme(id: 'old', name: 'Old');
    String older(ThemeColors colors) => jsonEncode(
      colors.toJson()
        ..removeWhere((role, _) => ThemeColors.taskListRoles.contains(role)),
    );
    await db.customStatement(
      'INSERT INTO custom_themes (id, name, day_colors, night_colors) '
      'VALUES (?, ?, ?, ?)',
      ['old', 'Old', older(theme.day), older(theme.night)],
    );

    final loaded = (await repo.byId('old'))!;
    expect(loaded.day.tokens, theme.day.tokens);
    expect(loaded.day.syntax.todoPriority, theme.day.syntax.task);
    expect(loaded.night.syntax.todoProject, theme.night.syntax.wikilink);
    expect(loaded.night.syntax.todoDone, theme.night.syntax.dim);
    expect(await repo.list(), hasLength(1));
  });

  test('renaming keeps the id, deleting takes the row away', () async {
    await repo.save(sampleCustomTheme(name: 'Mine'));
    await repo.rename('sample', 'Renamed');
    expect((await repo.byId('sample'))!.name, 'Renamed');

    await repo.delete('sample');
    expect(await repo.byId('sample'), isNull);
    expect(await repo.list(), isEmpty);
  });
}
