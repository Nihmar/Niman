// The prints are the repro timeline: which step lands when is the result.
// ignore_for_file: avoid_print
// Reproduction: creating a note from a template that wants a backlink
// (`[[{{parent}}]]`, like Personaggio.md) when no note is specified for
// it — the app stopped responding (user, 2026-09-12).
//
// Runs the real app (real LibraryController, real disk and sqlite)
// against a copy of a real library seeded with the template. Two
// scenarios:
//   A. no note on screen: the backlink stays empty;
//   B. a note on screen: the backlink keeps the suggested (hint) note.
//
// Setup (once):
//   cp -r "<a real library>" /tmp/niman/repro_lib
//   cp Personaggio.md /tmp/niman/repro_lib/Templates/
// then:
//   flutter test integration_test/template_backlink_freeze_test.dart -d linux
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/tree.dart';

const String libraryPath = '/tmp/niman/repro_lib';

/// The path of the ~931k char note in the copied library.
const String bigNote =
    'Projects/learning/math/Geometria/Geometria 1/Geometria 1.md';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('A: no note on screen, backlink left empty', (tester) async {
    await runScenario(tester, openBigNote: false, noteName: 'GandalfA');
  });

  testWidgets('B: big note on screen, backlink keeps the suggestion',
      (tester) async {
    await runScenario(tester, openBigNote: true, noteName: 'GandalfB');
  });
}

Future<void> runScenario(
  WidgetTester tester, {
  required bool openBigNote,
  required String noteName,
}) async {
  final lib = Directory(libraryPath);
  if (!lib.existsSync()) {
    fail('scratch library missing at $libraryPath (see setup above)');
  }
  final scratch = Directory.systemTemp.createTempSync('niman_it_');
  addTearDown(() => scratch.deleteSync(recursive: true));
  final appDb = AppDatabase(NativeDatabase(File('${scratch.path}/app.db')));
  await AppSettingsRepo(appDb).setLastLibraryPath(libraryPath);
  final controller = LibraryController(
    () async => appDb,
    indexDbFactory: (path) async => IndexDatabase(
      NativeDatabase(File('${scratch.path}/index.db')),
    ),
  );
  addTearDown(() async {
    await controller.close();
    await appDb.close();
  });

  final started = DateTime.now();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [librarySessionProvider.overrideWithValue(controller)],
      child: const NimanApp(),
    ),
  );

  await waitUntil(
    () async => find.byType(NoteTree).evaluate().isNotEmpty,
    tester,
    'the tree of the resumed library',
  );
  print('>> tree up after ${sec(started)}s');

  // The rows arrive with the (background) scan, not with the widget.
  await waitUntil(
    () async => find.text('Projects').evaluate().isNotEmpty,
    tester,
    'the top-level tree rows',
  );
  print('>> top rows up after ${sec(started)}s');

  if (openBigNote) {
    // Drill the tree down to the big note and open it.
    for (final part in ['Projects', 'learning', 'math', 'Geometria']) {
      await tester.tap(find.text(part).first);
      await tester.pump(const Duration(milliseconds: 300));
    }
    // The folder "Geometria 1" and its note share a name: the note row
    // is the last one.
    await tester.tap(find.text('Geometria 1').last);
    await waitUntil(
      () async => find.byType(NoteView).evaluate().isNotEmpty,
      tester,
      'the big note to open',
    );
    print('>> big note open after ${sec(started)}s');
  }

  // FAB (or the tree footer's "+ New" on wide layouts) → template.
  final fab = find.byKey(const Key('new-note-fab'));
  if (fab.evaluate().isNotEmpty) {
    await tester.tap(fab);
  } else {
    await tester.tap(find.byKey(const Key('new-item-menu')));
  }
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.byKey(const Key('new-from-template-action')));
  await waitUntil(
    () async => find.byKey(const Key('template-picker')).evaluate().isNotEmpty,
    tester,
    'the template picker dialog',
  );
  print('>> picker up after ${sec(started)}s');
  await tester.tap(find.byKey(const Key('template-Templates/Personaggio.md')));
  await waitUntil(
    () async => find.byKey(const Key('template-form')).evaluate().isNotEmpty,
    tester,
    'the template form',
  );
  print('>> form up after ${sec(started)}s');

  // Answer the template's own question; the backlink is left exactly as
  // the form offers it — the repro condition.
  await tester.enterText(
    find.byKey(const Key('template-field-Nome')),
    noteName,
  );
  final formOk = DateTime.now();
  await tester.tap(find.byKey(const Key('template-form-ok')));

  final relPath = 'Mondo/Personaggi/$noteName.md';
  await waitUntil(
    () => noteExists(controller, relPath),
    tester,
    'the note to be created at $relPath',
  );
  print(
    '>> note created ${sec(started)}s after start, '
    '${sec(formOk)}s after the form OK',
  );

  final onDisk = File('$libraryPath/$relPath').readAsStringSync();
  final bigName = bigNote.split('/').last.replaceAll('.md', '');
  print(
    '>> note on disk: [[]] present: ${onDisk.contains('[[]]')}, '
    'link to the big note: ${onDisk.contains('[[$bigName]]')}',
  );
}

String sec(DateTime start) =>
    (DateTime.now().difference(start).inMilliseconds / 1000).toStringAsFixed(1);

Future<bool> noteExists(LibrarySession controller, String relPath) async {
  final ops = controller.ops;
  if (ops == null) return false;
  return await ops.find(relPath) != null;
}

/// Pumps real frames until [probe] holds or two minutes elapse.
Future<void> waitUntil(
  Future<bool> Function() probe,
  WidgetTester tester,
  String what,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 120));
  while (DateTime.now().isBefore(deadline)) {
    if (await probe()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  final texts = find.byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .where((t) => t.trim().isNotEmpty)
      .take(30)
      .join(' | ');
  fail('timed out waiting for: $what — on screen: $texts');
}
