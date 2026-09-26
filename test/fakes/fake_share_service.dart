import 'dart:async';

import 'package:niman/src/core/share_in.dart';

/// An in-memory [ShareInService]: the test plays the sharing app.
///
/// [launchRequest] is the cold-start share the shell consumes when it
/// mounts; [emit] is one arriving while it runs.
final class FakeShareInService implements ShareInService {
  final StreamController<ShareRequest> _requests =
      StreamController<ShareRequest>.broadcast();

  /// The share a cold start was launched with, cleared once consumed.
  ShareRequest? launchRequest;

  /// Delivers [request] as a share into the running app.
  void emit(ShareRequest request) => _requests.add(request);

  @override
  Stream<ShareRequest> get requests => _requests.stream;

  @override
  Future<ShareRequest?> consumeLaunchRequest() async {
    final request = launchRequest;
    launchRequest = null;
    return request;
  }

  @override
  Future<void> dispose() async {
    await _requests.close();
  }
}
