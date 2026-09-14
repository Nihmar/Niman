// Home-screen widget taps (issue 6): what a widget asks the app to open.
//
// A widget lives in the launcher, outside the app process, so a tap only
// carries plain data: which library, and which tab or note inside it. The
// shell applies the target once it mounts — switching libraries first when
// the widget points elsewhere — through the same `_openTodo` /
// `_openNoteFromLink` the in-app controls use, so a widget can never open
// something the app itself could not.
//
// The shape mirrors `core/shortcuts.dart`: a platform service on Android,
// a no-op elsewhere, a fake in tests.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';

/// What a widget tap opens.
enum WidgetTargetKind {
  /// The Todo tab of the target library.
  todo,

  /// One note of the target library, in the editor.
  note,
}

/// A widget tap: the library to show, and what to open inside it.
///
/// [libraryPath] is the absolute library root (the widget never assumes
/// the last-opened library); [notePath] the library-relative note path
/// (`note` targets only); [anchor] an optional heading anchor.
final class WidgetTarget {
  /// Creates a target; use [fromMap] for the wire format.
  const new({
    required this.kind,
    required this.libraryPath,
    this.notePath,
    this.anchor,
  });

  /// Which surface to open.
  final WidgetTargetKind kind;

  /// The absolute library root to show first.
  final String libraryPath;

  /// The library-relative note path (`note` targets only).
  final String? notePath;

  /// The heading anchor (`note` targets only, optional).
  final String? anchor;

  /// The channel wire format (string keys and values only).
  Map<String, String> toMap() {
    return {
      'kind': kind.name,
      'libraryPath': libraryPath,
      'notePath': ?notePath,
      'anchor': ?anchor,
    };
  }

  /// Parses the channel wire format, or null when it carries nothing the
  /// shell can open (unknown kind, empty library, note without a path —
  /// e.g. a widget configured by a newer build).
  static WidgetTarget? fromMap(Map<Object?, Object?> map) {
    final kindRaw = map['kind'];
    final libraryRaw = map['libraryPath'];
    if (kindRaw is! String || libraryRaw is! String || libraryRaw.isEmpty) {
      return null;
    }
    WidgetTargetKind? kind;
    for (final value in WidgetTargetKind.values) {
      if (value.name == kindRaw) kind = value;
    }
    if (kind == null) return null;
    final noteRaw = map['notePath'];
    final notePath = noteRaw is String && noteRaw.isNotEmpty ? noteRaw : null;
    if (kind == WidgetTargetKind.note && notePath == null) return null;
    final anchorRaw = map['anchor'];
    return WidgetTarget(
      kind: kind,
      libraryPath: libraryRaw,
      notePath: notePath,
      anchor: anchorRaw is String && anchorRaw.isNotEmpty ? anchorRaw : null,
    );
  }
}

/// What the shell needs from the widget-tap layer.
///
/// Implemented by [PlatformWidgetTargetService] (Android) and
/// [NoopWidgetTargetService] (elsewhere), plus a fake in widget tests.
abstract interface class WidgetTargetService {
  /// Taps arriving while the app runs.
  Stream<WidgetTarget> get targets;

  /// The tap a cold start was launched with (once, then null).
  Future<WidgetTarget?> consumeLaunchTarget();

  /// Releases resources.
  Future<void> dispose();
}

/// Creates the platform service: widget taps on Android, a no-op
/// elsewhere (no other platform hosts these widgets).
///
/// [isAndroid] overrides the host platform so a plain test can cover the
/// branch that does not run here.
WidgetTargetService createWidgetTargetService({bool? isAndroid}) {
  if (isAndroid ?? Platform.isAndroid) return PlatformWidgetTargetService();
  return const NoopWidgetTargetService();
}

/// The single widget-tap service for the app session.
final widgetTargetServiceProvider = Provider<WidgetTargetService>((ref) {
  final service = createWidgetTargetService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Android widget taps over the `niman/widgets` method channel.
final class PlatformWidgetTargetService implements WidgetTargetService {
  /// Creates the service; [channel] is injected in tests.
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('niman/widgets') {
    _channel.setMethodCallHandler(_onCall);
  }

  static const AppLogger _log = AppLogger(name: 'widgets');

  final MethodChannel _channel;
  final StreamController<WidgetTarget> _targets =
      StreamController<WidgetTarget>.broadcast();

  @override
  Stream<WidgetTarget> get targets => _targets.stream;

  @override
  Future<WidgetTarget?> consumeLaunchTarget() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'consumeLaunchTarget',
      );
      if (map == null) return null;
      return WidgetTarget.fromMap(map);
    } on PlatformException catch (error) {
      _log.warning('launch target unavailable ($error)');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// The host forwards a tap that reached an already-running app.
  Future<void> _onCall(MethodCall call) async {
    if (call.method != 'target') return;
    final map = call.arguments;
    if (map is! Map<Object?, Object?>) {
      _log.warning('widget tap without a target');
      return;
    }
    final target = WidgetTarget.fromMap(map);
    if (target == null) {
      _log.warning('widget tap with an unreadable target');
      return;
    }
    _log.debug('widget tap: ${target.kind.name} ${target.libraryPath}');
    _targets.add(target);
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _targets.close();
  }
}

/// The off-Android service: no widgets, so nothing ever arrives.
final class NoopWidgetTargetService implements WidgetTargetService {
  /// Creates the no-op service.
  const new();

  @override
  Stream<WidgetTarget> get targets => const Stream<WidgetTarget>.empty();

  @override
  Future<WidgetTarget?> consumeLaunchTarget() async => null;

  @override
  Future<void> dispose() async {}
}
