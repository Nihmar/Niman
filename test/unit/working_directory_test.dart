// #319: a save must not depend on the process's working directory.
//
// The app was started from the folder a release bundle lives in, a build
// replaced that folder, and every write after it failed with
// `PathNotFoundException: Getting current working directory failed`: the
// platform style of `package:path` is resolved once per isolate, by asking
// for the working directory, and the write isolates had not asked yet.
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';

void main() {
  test(
    'a write names its temp file without the working directory',
    () async {
      // The deletion happens *inside* the isolate: the one the write runs in
      // is already spawned (its spawn is what the app does before the launch
      // directory can be replaced under it), and the next call that resolves
      // the platform style is the one that must not need it. The isolate puts
      // the directory back before it answers, so the run around it is whole.
      final temp = await Isolate.run(() async {
        final original = Directory.current.path;
        final gone = await Directory.systemTemp.createTemp('niman_gone_');
        Directory.current = gone.path;
        await gone.delete(recursive: true);
        try {
          return atomicTempPath(File('/lib/note.md'), 7).path;
        } finally {
          Directory.current = original;
        }
      });
      expect(temp, '/lib/.note.md.niman-tmp-7');
    },
    // Windows refuses to delete a process's working directory (it is in
    // use), so the directory cannot vanish under the app there: the
    // failure this guards against is a Linux and Android one.
    skip: Platform.isWindows
        ? 'Windows never lets the working directory be deleted'
        : false,
  );

  test('pinning hands the app a working directory it owns', () async {
    final original = Directory.current.path;
    final own = await Directory.systemTemp.createTemp('niman_own_');
    try {
      pinWorkingDirectory(own);
      expect(
        Directory.current.resolveSymbolicLinksSync(),
        Directory(own.path).resolveSymbolicLinksSync(),
      );
    } finally {
      Directory.current = original;
      await own.delete(recursive: true);
    }
  });
}
