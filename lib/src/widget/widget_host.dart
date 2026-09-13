// Placed widget instances (issue 6): the launcher owns the ids, so
// Dart asks the host instead of tracking them.
//
// Invoke-only over the `niman/widgets` channel: unlike
// [WidgetTargetService] this never sets a method-call handler, so it
// cannot steal the tap deliveries (one handler slot per channel name).
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/widget/widget_payload.dart';

/// What the shell needs from the widget host.
abstract interface class WidgetHostService {
  /// The placed todo widget ids (empty off-Android, or when none).
  Future<List<int>> todoWidgetIds();

  /// The placed note widget ids (empty off-Android, or when none).
  Future<List<int>> noteWidgetIds();

  /// Releases resources.
  Future<void> dispose();
}

/// Creates the host service: the launcher on Android, a no-op elsewhere.
///
/// [isAndroid] overrides the host platform so a plain test can cover the
/// branch that does not run here.
WidgetHostService createWidgetHostService({bool? isAndroid}) {
  if (isAndroid ?? Platform.isAndroid) return PlatformWidgetHostService();
  return const NoopWidgetHostService();
}

/// The single widget host service for the app session.
final widgetHostServiceProvider = Provider<WidgetHostService>((ref) {
  final service = createWidgetHostService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Android widget ids over the `niman/widgets` method channel.
final class PlatformWidgetHostService implements WidgetHostService {
  /// Creates the service; [channel] is injected in tests.
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('niman/widgets');

  final MethodChannel _channel;

  @override
  Future<List<int>> todoWidgetIds() {
    return _widgetIds(todoWidgetAndroidName);
  }

  @override
  Future<List<int>> noteWidgetIds() {
    return _widgetIds(noteWidgetAndroidName);
  }

  /// The placed instances of the provider class [androidName].
  Future<List<int>> _widgetIds(String androidName) async {
    try {
      final ids = await _channel.invokeListMethod<Object?>('getWidgetIds', {
        'provider': androidName,
      });
      if (ids == null) return [];
      return [
        for (final id in ids)
          if (id is int) id,
      ];
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  @override
  Future<void> dispose() async {}
}

/// The off-Android host: no widgets, so no ids.
final class NoopWidgetHostService implements WidgetHostService {
  /// Creates the no-op host.
  const new();

  @override
  Future<List<int>> todoWidgetIds() async => [];

  @override
  Future<List<int>> noteWidgetIds() async => [];

  @override
  Future<void> dispose() async {}
}
