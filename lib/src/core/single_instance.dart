/// One Niman per desktop session (#41).
///
/// A second launch — a double-clicked `.md`, a desktop action, the
/// command line — must not become a second process: two processes on one
/// library would each hold an index and write the same files. So the
/// first launch claims the session, and every later one hands its
/// arguments over and exits.
///
/// The claim is an exclusive lock on a file in the app's support
/// folder. The OS drops it with the process however that ends, so a
/// crash never leaves a stale claim behind. Beside it the first instance
/// listens on a loopback port and writes that port and a random token to
/// a second file. A later launch reads both, connects, and sends its
/// arguments with the token. Only a process that can read the user's
/// own files can send one.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// The session's first Niman, and what later launches hand it.
final class SingleInstance {
  new _(this._lock, this._server, this._token) {
    _server?.listen(_serve);
  }

  /// A session that could not be claimed (an unwritable support folder):
  /// the app runs as it did before there was a claim, and no later launch
  /// ever reaches it.
  factory unguarded() => SingleInstance._(null, null, '');

  static const AppLogger _log = AppLogger(name: 'instance');

  /// The instance this process claimed, held for as long as the process
  /// lives.
  ///
  /// Nothing else refers to it once `main` has run: the claim is made,
  /// `runApp` is called and `main` returns, leaving the object reachable
  /// only through itself (its server socket's listener is one of its own
  /// methods). Collected, it finalizes the lock file — and a closed file
  /// is an unlocked file, so the next launch found the lock free, called
  /// itself the first instance and opened a second window (0.0.8 test
  /// round). The `.md` handed to it went there, and the running Niman
  /// never heard about it.
  static SingleInstance? _claimed;

  /// The instance this process claimed, if it is the first one.
  static SingleInstance? get claimed => _claimed;

  /// How long a later launch waits for the first to be listening: it
  /// may itself still be starting.
  static const Duration _patience = Duration(seconds: 5);

  final RandomAccessFile? _lock;
  final ServerSocket? _server;
  final String _token;
  final StreamController<Map<String, Object?>> _launches =
      StreamController.broadcast();

  /// What each later launch handed over, as it sent it.
  Stream<Map<String, Object?>> get launches => _launches.stream;

  /// Claims the session in [dir] for this process, or hands [launch] to
  /// the process that holds it.
  ///
  /// Answers the instance when this process is the first, and null when
  /// the launch was handed over: the caller then exits. [lockHeld] stands
  /// in for the lock in tests, where the process cannot lock against
  /// itself.
  static Future<SingleInstance?> claim(
    Directory dir,
    Map<String, Object?> launch, {
    bool Function(RandomAccessFile lock)? lockHeld,
  }) async {
    await dir.create(recursive: true);
    // Ask the session itself, before anything else: a Niman that answers
    // on the port it left in the address file is the session, whatever
    // the lock file says. The lock is a guard against two launches racing
    // each other, not the test for "is one already running" — it was
    // that, and a released lock (a file the VM finalizes when nothing
    // refers to it any more) made every launch call itself the first,
    // open a window of its own and keep the file it was given (0.0.8
    // test round).
    if (await _handOverIfListening(dir, launch)) return null;
    final lock = await File(p.join(dir.path, 'niman.lock'))
        .open(mode: FileMode.append);
    final held = lockHeld?.call(lock) ?? await _lockedElsewhere(lock);
    if (held) {
      // A launch that started at the same moment as the first one, whose
      // listener is not up yet: wait for it and hand over.
      await lock.close();
      await _handOver(dir, launch);
      return null;
    }
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final token = _newToken();
    await _writeAddress(dir, server.port, token);
    _log.info('first instance, listening on ${server.port}');
    return _claimed = SingleInstance._(lock, server, token);
  }

  /// Hands [launch] to a session that is listening right now; false when
  /// there is none (no address file, nobody on the port, a stale port
  /// another program answers, a refused token).
  static Future<bool> _handOverIfListening(
    Directory dir,
    Map<String, Object?> launch,
  ) async {
    final file = _addressFile(dir);
    if (!file.existsSync()) return false;
    try {
      final handed = await _send(await file.readAsString(), launch);
      if (handed) _log.info('handed the launch to the running Niman');
      return handed;
    } on Object catch (error) {
      _log.info('no session answering ($error)');
      return false;
    }
  }

  /// Sends [launch] to the address in [addressJson]; true when the
  /// session took it.
  static Future<bool> _send(
    String addressJson,
    Map<String, Object?> launch,
  ) async {
    final address = jsonDecode(addressJson) as Map<String, Object?>;
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      address['port']! as int,
      timeout: const Duration(seconds: 1),
    );
    try {
      socket.writeln(jsonEncode({'token': address['token'], ...launch}));
      await socket.flush();
      final reply = await utf8.decoder
          .bind(socket)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 2));
      return reply == 'ok';
    } finally {
      await socket.close();
    }
  }

  static Future<bool> _lockedElsewhere(RandomAccessFile lock) async {
    try {
      await lock.lock();
      return false;
    } on FileSystemException {
      return true;
    }
  }

  static String _newToken() {
    final random = Random.secure();
    return base64Url.encode([for (var i = 0; i < 24; i++) random.nextInt(256)]);
  }

  static File _addressFile(Directory dir) =>
      File(p.join(dir.path, 'niman.instance'));

  static Future<void> _writeAddress(
    Directory dir,
    int port,
    String token,
  ) async {
    final file = _addressFile(dir);
    await file.writeAsString(jsonEncode({'port': port, 'token': token}));
    // Best effort: the token is only as private as this file.
    if (Platform.isLinux) {
      try {
        await Process.run('chmod', ['600', file.path]);
      } on Object catch (error) {
        _log.warning('address file left readable ($error)');
      }
    }
  }

  /// Sends [launch] to the first instance, retrying while it starts.
  static Future<void> _handOver(
    Directory dir,
    Map<String, Object?> launch,
  ) async {
    final deadline = DateTime.now().add(_patience);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        if (await _send(await _addressFile(dir).readAsString(), launch)) {
          return;
        }
        lastError = 'the session refused the launch';
      } on Object catch (error) {
        lastError = error;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    // The first instance holds the session and is not answering. A second
    // process on its library would be worse than this launch doing
    // nothing, so it does nothing, and says why.
    _log.warning('could not hand the launch over ($lastError)');
    stderr.writeln('Niman is already running and did not answer: $lastError');
  }

  Future<void> _serve(Socket socket) async {
    try {
      final line = await utf8.decoder
          .bind(socket)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 2));
      final message = jsonDecode(line);
      if (message is! Map<String, Object?> || message['token'] != _token) {
        socket.writeln('denied');
        _log.warning('a launch with the wrong token was turned away');
      } else {
        socket.writeln('ok');
        _launches.add({...message}..remove('token'));
      }
      await socket.flush();
    } on Object catch (error) {
      _log.warning('a launch could not be read ($error)');
    } finally {
      await socket.close();
    }
  }

  /// Gives the session up (tests; the OS does it when the process ends).
  Future<void> close() async {
    await _server?.close();
    await _launches.close();
    await _lock?.close();
  }
}
