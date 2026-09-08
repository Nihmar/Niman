// The log survives the process only if it reaches disk: an export after
// a kill, a reboot or a reminder that fired with the app closed reads the
// mirror, not the in-memory buffer.
import 'dart:io';

import 'package:copist/src/core/log_file.dart';
import 'package:copist/src/core/logging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  late LogFile log;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('copist_log_');
    log = LogFile(path: p.join(dir.path, 'copist-log.txt'));
  });

  tearDown(() async {
    AppLog.file = null;
    AppLog.clear();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  test('buffered lines reach disk on flush', () async {
    log
      ..add('one')
      ..add('two');
    expect(File(log.path).existsSync(), isFalse);
    await log.flush();
    expect(await log.read(), 'one\ntwo\n');
  });

  test('read returns the previous generation before the current', () async {
    final small = LogFile(path: p.join(dir.path, 'small.txt'), maxBytes: 8)
      ..add('first line');
    await small.flush();
    small.add('second line');
    await small.flush();
    expect(File('${small.path}.1').existsSync(), isTrue);
    final text = await small.read();
    expect(text.indexOf('first'), lessThan(text.indexOf('second')));
  });

  test('rotation keeps at most two generations', () async {
    final small = LogFile(path: p.join(dir.path, 'small.txt'), maxBytes: 8);
    for (var i = 0; i < 6; i++) {
      small.add('line $i');
      await small.flush();
    }
    final names = dir
        .listSync()
        .map((e) => p.basename(e.path))
        .where((n) => n.startsWith('small.txt'))
        .toList();
    expect(names, unorderedEquals(<String>['small.txt', 'small.txt.1']));
  });

  test('AppLog mirrors every recorded line', () async {
    AppLog.file = log;
    const AppLogger(name: 'todo').info('reminder scheduled');
    await log.flush();
    expect(await log.read(), contains('[todo] reminder scheduled'));
  });

  test('clear drops both generations', () async {
    log.add('gone');
    await log.flush();
    await log.clear();
    expect(await log.read(), isEmpty);
  });
}
