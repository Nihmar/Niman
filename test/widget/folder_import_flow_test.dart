// Importing a folder from outside the library (#75, #1295), in the app: the
// offer says what it will make — the Markdown copied, the pages converted —
// a folder past the limits is refused before anything is offered, an import
// ends by showing the folder it made, and Settings → Maintenance has a row
// that picks one.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/import/folder/folder_import.dart';
import 'package:niman/src/ui/folder_import_flow.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_maintenance.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

const FolderImported _made = (
  folder: 'Site',
  notes: 5,
  pages: 3,
  pictures: 2,
  skipped: 0,
);

void main() {
  late Directory tmp;
  late String library;
  late String site;
  late FakeLibrarySession session;
  late List<String> revealed;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niman_folder_flow_');
    library = p.join(tmp.path, 'library');
    site = p.join(tmp.path, 'Site');
    Directory(library).createSync();
    Directory(site).createSync();
    revealed = [];
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  void put(String relative, String text) =>
      File(p.joinAll([site, ...relative.split('/')]))
        ..createSync(recursive: true)
        ..writeAsStringSync(text);

  late BuildContext context;

  /// A screen with a snack bar to say things on, over a library at [library].
  Future<FolderImportFlow> pumpFlow(
    WidgetTester tester, {
    FolderLimits limits = folderImportLimits,
  }) async {
    session = FakeLibrarySession();
    await session.open(library, create: false);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return FolderImportFlow(
      session: session,
      reveal: revealed.add,
      limits: limits,
    );
  }

  /// Runs [action], letting what it awaits on a real isolate go on between
  /// the frames, until [until] holds.
  Future<void> letRun(
    WidgetTester tester,
    bool Function() until, {
    int turns = 200,
  }) async {
    for (var i = 0; i < turns && !until(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  group('what it says when it ends', () {
    Future<void> ends(
      WidgetTester tester, {
      FolderImported? result,
      Object? error,
      String? root,
    }) async {
      final flow = await pumpFlow(tester);
      final done = Completer<FolderImported?>();
      final settling = flow.settle(
        context,
        done: done.future,
        name: 'Site',
        root: root ?? library,
        messenger: ScaffoldMessenger.of(context),
      );
      if (error != null) {
        done.completeError(error);
      } else {
        done.complete(result);
      }
      await settling;
      await tester.pump();
    }

    testWidgets('shows the folder it made and says where it is', (
      tester,
    ) async {
      await ends(tester, result: _made);
      expect(revealed, ['Site']);
      expect(find.text(AppStrings.importFolderDone('Site')), findsOne);
    });

    testWidgets('says what it left out', (tester) async {
      await ends(
        tester,
        result: (folder: 'Site 2', notes: 4, pages: 2, pictures: 0, skipped: 3),
      );
      expect(revealed, ['Site 2']);
      expect(find.text(AppStrings.importFolderSkipped('Site 2', 3)), findsOne);
    });

    testWidgets('says there was nothing to import', (tester) async {
      await ends(tester);
      expect(revealed, isEmpty);
      expect(find.text(AppStrings.importFolderEmpty('Site')), findsOne);
    });

    testWidgets('says nothing of a cancel', (tester) async {
      await ends(tester, error: const HtmlConvertCancelled());
      expect(revealed, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('says it failed, in the language and not the error', (
      tester,
    ) async {
      await ends(tester, error: const HtmlConvertFailed('disk full'));
      expect(revealed, isEmpty);
      expect(find.text(AppStrings.importFolderFailed), findsOne);
      expect(find.textContaining('disk full'), findsNothing);
    });

    testWidgets('does not show a folder of a library that is no longer '
        'the one open', (tester) async {
      await ends(tester, result: _made, root: p.join(tmp.path, 'other'));
      expect(revealed, isEmpty);
      expect(find.text(AppStrings.importFolderDone('Site')), findsOne);
    });
  });

  group('the offer', () {
    testWidgets('says the Markdown copied and the pages converted', (
      tester,
    ) async {
      put('a.md', '# A');
      put('sub/b.html', '<title>B</title><p>b</p>');
      put('c.htm', '<title>C</title><p>c</p>');
      final flow = await pumpFlow(tester);
      unawaited(flow.run(context, site));
      await letRun(
        tester,
        () => find.byKey(const Key('import-folder')).evaluate().isNotEmpty,
      );
      expect(find.byKey(const Key('import-folder')), findsOne);
      expect(find.text(AppStrings.importFolderBodyPages(1, 2)), findsOne);
      // Nothing is made before it is accepted.
      await tester.tap(find.text(AppStrings.actionCancel));
      await tester.pumpAndSettle();
      expect(Directory(p.join(library, 'Site')).existsSync(), isFalse);
      expect(revealed, isEmpty);
    });

    testWidgets('says only the Markdown copied for a folder without pages', (
      tester,
    ) async {
      put('a.md', '# A');
      put('b.md', '# B');
      final flow = await pumpFlow(tester);
      unawaited(flow.run(context, site));
      await letRun(
        tester,
        () => find.byKey(const Key('import-folder')).evaluate().isNotEmpty,
      );
      expect(find.text(AppStrings.importFolderBody(2)), findsOne);
    });

    testWidgets('is not made for a folder with nothing to import', (
      tester,
    ) async {
      put('pic.png', 'png');
      final flow = await pumpFlow(tester);
      unawaited(flow.run(context, site));
      await letRun(tester, () => find.byType(SnackBar).evaluate().isNotEmpty);
      expect(find.byKey(const Key('import-folder')), findsNothing);
      expect(find.text(AppStrings.importFolderEmpty('Site')), findsOne);
    });

    testWidgets('is not made for a folder past the limits', (tester) async {
      for (var i = 0; i < 4; i++) {
        put('n$i.md', '#');
      }
      final flow = await pumpFlow(
        tester,
        limits: (files: 3, bytes: 1 << 20, visited: 100),
      );
      unawaited(flow.run(context, site));
      await letRun(tester, () => find.byType(SnackBar).evaluate().isNotEmpty);
      expect(find.byKey(const Key('import-folder')), findsNothing);
      expect(find.text(AppStrings.importFolderTooLarge), findsOne);
      expect(Directory(p.join(library, 'Site')).existsSync(), isFalse);
    });

    testWidgets('shows a folder of the library instead of importing it', (
      tester,
    ) async {
      final inside = Directory(p.join(library, 'Work', 'Plans'))
        ..createSync(recursive: true);
      final flow = await pumpFlow(tester);
      await flow.run(context, inside.path);
      expect(revealed, ['Work/Plans']);
      expect(find.byKey(const Key('import-folder')), findsNothing);
    });
  });

  group('the import', () {
    testWidgets('converts the pages, copies the Markdown and shows the '
        'folder it made', (tester) async {
      put('index.html', '<title>Home</title><p><a href="a.html">a</a></p>');
      put('a.html', '<title>A</title><p>Here.</p>');
      put('notes.md', '[a](a.html)\n');
      final flow = await pumpFlow(tester);
      unawaited(flow.run(context, site));
      await letRun(
        tester,
        () => find.byKey(const Key('import-folder')).evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(const Key('import-folder-yes')));
      final notice = find.text(AppStrings.importFolderDone('Site'));
      await letRun(tester, () => notice.evaluate().isNotEmpty);
      await tester.pump();
      expect(notice, findsOne);
      expect(revealed, ['Site']);
      expect(
        File(p.join(library, 'Site', 'index.md')).readAsStringSync(),
        contains('[a](a.md)'),
      );
      expect(
        File(p.join(library, 'Site', 'notes.md')).readAsStringSync(),
        '[a](a.md)\n',
      );
      // The progress dialog closed itself.
      expect(find.byKey(const Key('import-folder-progress')), findsNothing);
    });

    testWidgets('a cancel from the progress dialog leaves the library as it '
        'was', (tester) async {
      for (var i = 0; i < 200; i++) {
        put('n/$i.html', '<title>N$i</title><p>Page $i.</p>');
      }
      final flow = await pumpFlow(tester);
      unawaited(flow.run(context, site));
      await letRun(
        tester,
        () => find.byKey(const Key('import-folder')).evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(const Key('import-folder-yes')));
      final cancel = find.byKey(const Key('import-folder-cancel-progress'));
      await letRun(tester, () => cancel.evaluate().isNotEmpty);
      expect(cancel, findsOne);
      await tester.tap(cancel);
      await letRun(
        tester,
        () =>
            find.byKey(const Key('import-folder-progress')).evaluate().isEmpty,
      );
      await tester.pumpAndSettle();
      expect(revealed, isEmpty);
      expect(
        Directory(library).listSync(),
        isEmpty,
        reason: 'neither the folder nor its hidden staging is left',
      );
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('Settings → Maintenance', () {
    late FakeFilePicker picker;

    setUp(() => picker = useFakeFilePicker());

    Future<void> pumpGroup(WidgetTester tester) async {
      session = FakeLibrarySession();
      await session.open(library, create: false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SettingsMaintenanceGroup(controller: session),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('has a row that picks a folder and offers it', (tester) async {
      put('a.md', '# A');
      put('b.html', '<title>B</title><p>b</p>');
      picker.directory = site;
      await pumpGroup(tester);
      final row = find.byKey(SettingsKeys.importFolder);
      expect(row, findsOne);
      expect(
        find.descendant(
          of: row,
          matching: find.text(AppStrings.importFolderSettingsTitle),
        ),
        findsOne,
      );
      await tester.ensureVisible(row);
      await tester.tap(
        find.descendant(of: row, matching: find.byType(ListTile)),
      );
      await letRun(
        tester,
        () => find.byKey(const Key('import-folder')).evaluate().isNotEmpty,
      );
      expect(find.byKey(const Key('import-folder')), findsOne);
      expect(find.text(AppStrings.importFolderBodyPages(1, 1)), findsOne);
    });

    testWidgets('a cancelled pick does nothing', (tester) async {
      picker.directory = null;
      await pumpGroup(tester);
      final row = find.byKey(SettingsKeys.importFolder);
      await tester.ensureVisible(row);
      await tester.tap(
        find.descendant(of: row, matching: find.byType(ListTile)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('import-folder')), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
