/// Share-in: what another Android app hands Niman (#40).
///
/// Android delivers `ACTION_SEND`/`ACTION_VIEW` to the activity; the
/// platform bridge turns the intent into one of the [ShareRequest]s here
/// and this channel carries it to the shell. Text goes to the quick note,
/// a file is imported into the library — see `_handleShare` in the shell.
///
/// The file half needs a copy: Android hands a `content://` URI, which no
/// file API can read or keep, so the platform side reads the bytes and
/// writes them to its own cache; Dart imports that copy and deletes it.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';

/// One thing another app shared into Niman.
sealed class ShareRequest {
  /// Creates a share request.
  const new();
}

/// Plain text shared into Niman: inserted into the quick note.
final class SharedText extends ShareRequest {
  /// Creates a text share.
  const new(this.text);

  /// The shared text, as the sender wrote it.
  final String text;
}

/// A file shared into Niman, to import into the library.
final class SharedFile extends ShareRequest {
  /// Creates a file share.
  const new({required this.path, required this.name});

  /// Absolute path of the copy the platform made in its own cache.
  final String path;

  /// The display name the sender gave the file, extension included.
  final String name;
}

/// Reads a share payload off the channel, or null when it is not one this
/// app knows (an older platform side, a share kind not routed yet).
ShareRequest? shareRequestFrom(Object? payload) {
  if (payload is! Map) return null;
  switch (payload['type']) {
    case 'text':
      final text = payload['text'];
      if (text is! String || text.trim().isEmpty) return null;
      return SharedText(text);
    case 'file':
      final path = payload['path'];
      if (path is! String || path.isEmpty) return null;
      final name = payload['name'];
      return SharedFile(
        path: path,
        name: name is String && name.trim().isNotEmpty ? name : 'Shared.md',
      );
    default:
      return null;
  }
}

/// What the shell needs from the platform share layer.
///
/// Implemented by [PlatformShareInService] (Android) and
/// [NoopShareInService] (elsewhere), plus a fake in widget tests.
abstract interface class ShareInService {
  /// Shares arriving while the app runs.
  Stream<ShareRequest> get requests;

  /// The share a cold start was launched with (once, then null).
  Future<ShareRequest?> consumeLaunchRequest();

  /// Releases resources.
  Future<void> dispose();
}

/// Creates the platform service: the Android share bridge, a no-op
/// elsewhere (no desktop has a system share sheet; files arrive there
/// through the association and the drop, #41/#75).
///
/// [isAndroid] overrides the host platform so a plain test can cover the
/// branch that does not run here.
ShareInService createShareInService({bool? isAndroid}) {
  if (isAndroid ?? Platform.isAndroid) return PlatformShareInService();
  return const NoopShareInService();
}

/// The app's share-in service.
final shareInServiceProvider = Provider<ShareInService>((ref) {
  final service = createShareInService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Android share-in over the `niman/share` method channel.
final class PlatformShareInService implements ShareInService {
  /// Creates the service; [channel] is injected in tests.
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('niman/share') {
    _channel.setMethodCallHandler(_onCall);
  }

  static const AppLogger _log = AppLogger(name: 'share');

  final MethodChannel _channel;

  /// Shares that arrived before anyone listened — a share that lands while
  /// the library picker is up has no shell to take it yet, and dropping it
  /// would lose the user's text or file.
  final List<ShareRequest> _waiting = <ShareRequest>[];

  late final StreamController<ShareRequest> _requests =
      StreamController<ShareRequest>.broadcast(onListen: _flush);

  @override
  Stream<ShareRequest> get requests => _requests.stream;

  void _flush() {
    if (_waiting.isEmpty) return;
    final queued = List<ShareRequest>.of(_waiting);
    _waiting.clear();
    queued.forEach(_requests.add);
  }

  @override
  Future<ShareRequest?> consumeLaunchRequest() async {
    try {
      final payload = await _channel.invokeMethod<Object?>(
        'consumeLaunchRequest',
      );
      return shareRequestFrom(payload);
    } on PlatformException catch (error) {
      _log.warning('launch share unavailable ($error)');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// The host forwards a share that reached an already-running app.
  Future<void> _onCall(MethodCall call) async {
    if (call.method != 'share') return;
    final request = shareRequestFrom(call.arguments);
    if (request == null) {
      _log.warning('unusable share ${call.arguments}');
      return;
    }
    _log.debug('shared in: ${request.runtimeType}');
    if (_requests.hasListener) {
      _requests.add(request);
    } else {
      _waiting.add(request);
    }
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _requests.close();
  }
}

/// The off-Android service: nothing is ever shared in.
final class NoopShareInService implements ShareInService {
  /// Creates the no-op service.
  const new();

  @override
  Stream<ShareRequest> get requests => const Stream<ShareRequest>.empty();

  @override
  Future<ShareRequest?> consumeLaunchRequest() async => null;

  @override
  Future<void> dispose() async {}
}
