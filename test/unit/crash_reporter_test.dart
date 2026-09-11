import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/crash_reporter.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/library_state.dart';

void main() {
  test(
    'an uncaught error is recorded and persisted to the library root',
    () async {
      final dir = await Directory.current.createTemp('niman_crash_');
      final previous = LibraryController.currentRootPath;
      LibraryController.currentRootPath = dir.path;
      addTearDown(() => LibraryController.currentRootPath = previous);
      addTearDown(() => dir.delete(recursive: true));
      CrashReporter.install();
      addTearDown(() => PlatformDispatcher.instance.onError = null);

      final handler = PlatformDispatcher.instance.onError!;
      final handled = handler(
        Exception('boom'),
        StackTrace.fromString('at here'),
      );
      expect(handled, isTrue); // the app stays alive behind the log

      expect(AppLog.lines(), isNotEmpty);
      expect(
        AppLog.lines().join('\n'),
        contains('uncaught error: Exception: boom'),
      );

      // The persist is fire-and-forget; let it land.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final files = dir.listSync().whereType<File>().toList();
      expect(files, hasLength(1));
      expect(files.single.path, contains('niman-crash-'));
      final report = files.single.readAsStringSync();
      expect(report, contains('Exception: boom'));
      expect(report, contains('at here'));
      expect(report, contains('AppLog buffer'));
    },
  );
}
