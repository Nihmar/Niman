// Issue #41: one Niman per session. The first launch claims it and
// listens; a later one hands its arguments over and is told to exit, and
// a message without the session's token is turned away.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/single_instance.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('niman-instance'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('the first launch claims; a later one hands over and exits', () async {
    final first = await SingleInstance.claim(dir, const {});
    expect(first, isNotNull);
    final received = first!.launches.first;

    // One process cannot lock against itself, so the later launch is
    // told the lock is held — what a second process would find.
    final later = await SingleInstance.claim(dir, {
      'open': '/home/u/a.md',
    }, lockHeld: (_) => true);
    expect(later, isNull);
    expect(await received, {'open': '/home/u/a.md'});
    await first.close();
  });

  // 0.0.8 test round: every launch called itself the first and opened a
  // window of its own, and the .md it was given went there instead of to
  // the running Niman. The lock file was the whole test for "is one
  // already running", and a lock can be gone while the session is not.
  // A session that answers on its port is the session, lock or no lock —
  // which is what this asks, since one process cannot lock against
  // itself either.
  test('a launch hands over to a session that answers, lock or not', () async {
    final first = await SingleInstance.claim(dir, const {});
    expect(first, isNotNull);
    final received = first!.launches.first;

    final later = await SingleInstance.claim(dir, {'open': '/home/u/a.md'});
    expect(later, isNull, reason: 'it hands over and exits');
    expect(await received, {'open': '/home/u/a.md'});
    await first.close();
  });

  test('with nobody answering, the launch claims the session', () async {
    // A stale address file: the port nobody is on any more.
    final gone = await SingleInstance.claim(dir, const {});
    await gone!.close();
    final next = await SingleInstance.claim(dir, const {});
    expect(next, isNotNull);
    expect(SingleInstance.claimed, same(next));
    await next!.close();
  });

  test('a message without the token is turned away', () async {
    final first = (await SingleInstance.claim(dir, const {}))!;
    var launches = 0;
    final sub = first.launches.listen((_) => launches++);
    final address = jsonDecode(
      File(p.join(dir.path, 'niman.instance')).readAsStringSync(),
    ) as Map<String, Object?>;
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      address['port']! as int,
    );
    socket.writeln(jsonEncode({'token': 'guess', 'open': '/etc/passwd'}));
    await socket.flush();
    final reply = await utf8.decoder
        .bind(socket)
        .transform(const LineSplitter())
        .first;
    await socket.close();
    expect(reply, 'denied');
    expect(launches, 0);
    await sub.cancel();
    await first.close();
  });
}
