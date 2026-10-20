/// What reaches the shell from outside while it is up (split out of
/// `shell.dart` for #710): notification taps, finished recognitions,
/// shortcuts, shares, the tray, launches and the library's own events.
///
/// The shell says what each one does; this keeps the subscriptions, so
/// none of them can be forgotten when the shell goes: `cancel` ends every
/// one at once.
library;

import 'dart:async';

/// The shell's subscriptions to the streams that reach it from outside.
final class ShellInbound {
  /// An inbound set whose [onRequest] hears every event of a stream
  /// subscribed with `request: true`.
  new({this.onRequest});

  /// Called before the handler of a request: something from outside — a
  /// share, a widget, a notification, a launch — asked the shell to open
  /// something (#1109). The Features introduction waits for none of them.
  final void Function()? onRequest;

  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// Runs [onData] for every event of [stream] until [cancel]; a null
  /// [stream] — a service the platform does not have — is no subscription.
  ///
  /// [request] marks a stream whose events are requests from outside: each
  /// is announced to [onRequest] first.
  void listen<T>(
    Stream<T>? stream,
    void Function(T event) onData, {
    bool request = false,
  }) {
    if (stream == null) return;
    _subscriptions.add(
      stream.listen((event) {
        if (request) onRequest?.call();
        onData(event);
      }),
    );
  }

  /// Ends every subscription.
  Future<void> cancel() async {
    final subscriptions = [..._subscriptions];
    _subscriptions.clear();
    await Future.wait([
      for (final subscription in subscriptions) subscription.cancel(),
    ]);
  }
}
