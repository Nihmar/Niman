// Issue #383: a crash report is diagnostics — the whole AppLog buffer, with
// the note and library paths and the WebDAV host in it — so it goes to the
// app's private support folder and never to the open library, which the sync
// walks and uploads, nor to a user-visible folder. The oldest are pruned as
// new ones land.
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/crash_reporter.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Registered once for the whole file: install is idempotent, and the
  // handler it leaves behind is the one every test here fires.
  CrashReporter.install();

  /// A temp folder the test owns and removes.
  Future<Directory> tempDir(String prefix) async {
    final dir = await Directory.current.createTemp(prefix);
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    return dir;
  }

  /// The folders path_provider hands out, redirected to folders the test
  /// owns: the private support folder a report belongs in, and the
  /// user-visible documents folder it used to fall back to.
  Future<({Directory support, Directory documents})>
  mockPlatformFolders() async {
    final support = await tempDir('niman_crash_support_');
    final documents = await tempDir('niman_crash_documents_');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => switch (call.method) {
        'getApplicationSupportDirectory' => support.path,
        'getApplicationDocumentsDirectory' => documents.path,
        _ => null,
      },
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    return (support: support, documents: documents);
  }

  /// Fires the installed uncaught-error handler and lets the fire-and-forget
  /// write land.
  Future<void> crash() async {
    final handler = PlatformDispatcher.instance.onError;
    expect(handler, isNotNull, reason: 'install() registers the handler');
    expect(
      handler!(Exception('boom'), StackTrace.fromString('at here')),
      isTrue, // the app stays alive behind the log
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  test('an uncaught error is recorded in the log buffer', () async {
    await crash();
    expect(AppLog.lines(), isNotEmpty);
    expect(
      AppLog.lines().join('\n'),
      contains('uncaught error: Exception: boom'),
    );
  });

  test(
    'the report lands in the support folder, never in the library',
    () async {
      final folders = await mockPlatformFolders();
      final library = await tempDir('niman_crash_library_');
      final previous = LibraryController.currentRootPath;
      LibraryController.currentRootPath = library.path;
      addTearDown(() => LibraryController.currentRootPath = previous);

      await crash();

      expect(
        library.listSync(),
        isEmpty,
        reason: 'the open library is walked and uploaded by the sync',
      );
      expect(
        folders.documents.listSync(),
        isEmpty,
        reason: 'a user-visible folder is no better',
      );
      final reports = folders.support.listSync().whereType<File>().toList();
      expect(reports, hasLength(1));
      final name = p.basename(reports.single.path);
      expect(name, startsWith('niman-crash-'));
      expect(name, endsWith('.txt'));
      // The sync refuses the name wherever a report turns up (#383).
      expect(isSyncablePath(name), isFalse, reason: name);
      final report = reports.single.readAsStringSync();
      expect(report, contains('Exception: boom'));
      expect(report, contains('at here'));
      expect(report, contains('AppLog buffer'));
    },
  );

  test('the oldest reports are pruned, the newest kept', () async {
    final folders = await mockPlatformFolders();
    // Five is the reporter's own cap (_keptReports).
    const kept = 5;
    for (var i = 0; i < kept + 1; i++) {
      File(p.join(folders.support.path, 'niman-crash-20000101-00000$i.txt'))
          .writeAsStringSync('old $i');
    }
    // The support folder holds the app's other files too: none of them is a
    // report, and none is touched.
    for (final name in ['niman-log.txt', 'niman.db', 'settings.json']) {
      File(p.join(folders.support.path, name)).writeAsStringSync(name);
    }

    await crash();

    final names = folders.support
        .listSync()
        .whereType<File>()
        .map((file) => p.basename(file.path))
        .toList();
    expect(
      names.where((name) => name.startsWith('niman-crash-')),
      hasLength(kept),
      reason: 'a report per failure is enough; the pile is weight',
    );
    expect(
      names,
      isNot(contains('niman-crash-20000101-000000.txt')),
      reason: 'the oldest goes',
    );
    expect(names, isNot(contains('niman-crash-20000101-000001.txt')));
    expect(
      names,
      contains('niman-crash-20000101-000005.txt'),
      reason: 'the newest old report stays',
    );
    expect(names, containsAll(['niman-log.txt', 'niman.db', 'settings.json']));
  });
}
