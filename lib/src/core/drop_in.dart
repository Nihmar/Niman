/// The drop target the platform runners report on (#224).
///
/// The window's own drag-and-drop is taken by the runner — GDK in
/// `linux/runner`, `WM_DROPFILES` in `windows/runner` — which hands what
/// it sees to Dart over the `niman/drop` method channel as one of the
/// [WindowDrop] events below. The desktop_drop plugin used to take the
/// drag instead; on KDE/Wayland it preferred the portal file-transfer
/// target, which carries a one-time key rather than paths, so a drop
/// resolved to nothing and the window did nothing at all (issue #224).
///
/// `AppDropTarget` listens to [DropTargetService.events] and opens or
/// imports what a drop names, through the same requests a launch makes.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Something the window's drop target reports.
sealed class WindowDrop {
  /// Creates a drop event.
  const new();
}

/// Something is being dragged over the window.
final class DragEntered extends WindowDrop {
  /// Creates the entered event.
  const new();
}

/// The drag left the window, or landed on it.
final class DragExited extends WindowDrop {
  /// Creates the exited event.
  const new();
}

/// A drop landed, naming the paths the desktop handed over.
///
/// [paths] is empty when the desktop reported a drop that carries
/// nothing openable — a portal key that resolved to nothing, say — and
/// the window says so rather than sitting there (#224).
final class Dropped extends WindowDrop {
  /// Creates a drop from the [paths] it names.
  const new(this.paths);

  /// The paths the drop named, in the order the desktop listed them.
  final List<String> paths;
}

/// Reads the paths a drop payload holds, dropping what cannot be one.
///
/// The runners send a list of strings; anything else — a payload shape
/// this app does not know, or an entry that is not a usable path — is
/// left out rather than trusted.
List<String> dropPathsFrom(Object? payload) {
  if (payload is! List) return const <String>[];
  final paths = <String>[];
  for (final value in payload) {
    if (value is String && value.trim().isNotEmpty) paths.add(value);
  }
  return paths;
}

/// What the window's own drop target reports, to whoever draws it.
///
/// Implemented by [PlatformDropTargetService] (Linux, Windows) and
/// [NoopDropTargetService] (elsewhere), plus a fake in widget tests.
abstract interface class DropTargetService {
  /// The drags and drops the window's target sees, in the order they
  /// happened.
  Stream<WindowDrop> get events;

  /// Lets go of the channel it listens on.
  Future<void> dispose();
}

/// Creates the platform service: the runner's channel on the desktop, a
/// no-op elsewhere (the phone has nothing to drag from, and the runner
/// gives it no drop target).
///
/// [isDesktop] overrides the host platform so a plain test can cover the
/// branch that does not run here.
DropTargetService createDropTargetService({bool? isDesktop}) {
  if (isDesktop ?? (Platform.isLinux || Platform.isWindows)) {
    return PlatformDropTargetService();
  }
  return const NoopDropTargetService();
}

/// The app's drop-target service.
final dropTargetServiceProvider = Provider<DropTargetService>((ref) {
  final service = createDropTargetService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// The desktop runners' drop target, over the `niman/drop` channel.
final class PlatformDropTargetService implements DropTargetService {
  /// Creates the service; [channel] is injected in tests.
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('niman/drop') {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;

  bool _disposed = false;

  final StreamController<WindowDrop> _events =
      StreamController<WindowDrop>.broadcast();

  @override
  Stream<WindowDrop> get events => _events.stream;

  /// The runner reports a drag that came in, one that left, or the drop
  /// it ended in. A call this app does not know is left alone.
  Future<void> _onCall(MethodCall call) async {
    if (_disposed) return;
    switch (call.method) {
      case 'dragEntered':
        _events.add(const DragEntered());
      case 'dragExited':
        _events.add(const DragExited());
      case 'drop':
        _events.add(Dropped(dropPathsFrom(call.arguments)));
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _channel.setMethodCallHandler(null);
    await _events.close();
  }
}

/// The off-desktop service: nothing is ever dragged onto the window.
final class NoopDropTargetService implements DropTargetService {
  /// Creates the no-op service.
  const new();

  @override
  Stream<WindowDrop> get events => const Stream<WindowDrop>.empty();

  @override
  Future<void> dispose() async {}
}
