// Per-instance placement choices (round 2, R1): which library (and
// note) a freshly placed widget was configured for.
//
// Written by the native config activity, consumed once by the Dart
// adopt flow. Transient by design — SharedPreferences, not the
// database — and Android-only, like the widgets themselves.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_payload.dart';

/// What the adopt flow needs from the placement layer.
abstract interface class WidgetPlacementStore {
  /// The library chosen for [androidWidgetId]'s todo widget, cleared on
  /// read (once, then null).
  Future<({String library})?> consumeTodoConfig(int androidWidgetId);

  /// The library + note chosen for [androidWidgetId]'s note widget,
  /// cleared on read (once, then null).
  Future<({String library, String note})?> consumeNoteConfig(
    int androidWidgetId,
  );
}

/// Reads a per-instance config key, cleared on read.
Future<Map<String, Object?>?> _consume(String key) async {
  try {
    final raw = await HomeWidget.getWidgetData<String>(key);
    if (raw == null || raw.isEmpty) return null;
    await HomeWidget.saveWidgetData<String>(key, null);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) return null;
    return decoded;
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  } on FormatException {
    return null;
  }
}

/// The plugin-backed placement store (Android only; inert elsewhere).
final class PlatformWidgetPlacementStore implements WidgetPlacementStore {
  /// Creates the store.
  const new();

  @override
  Future<({String library})?> consumeTodoConfig(int androidWidgetId) async {
    final map = await _consume(
      '${widgetPayloadKey(WidgetProvider.todo, androidWidgetId)}_config',
    );
    final library = map?['library'];
    if (library is! String || library.isEmpty) return null;
    return (library: library);
  }

  @override
  Future<({String library, String note})?> consumeNoteConfig(
    int androidWidgetId,
  ) async {
    final map = await _consume(
      '${widgetPayloadKey(WidgetProvider.note, androidWidgetId)}_config',
    );
    final library = map?['library'];
    final note = map?['note'];
    if (library is! String ||
        library.isEmpty ||
        note is! String ||
        note.isEmpty) {
      return null;
    }
    return (library: library, note: note);
  }
}

/// Saves a placement choice (used by tests and a future in-app path;
/// the config activity writes the same keys natively).
///
/// False off-Android or when the plugin is unavailable.
Future<bool> saveWidgetPlacement({
  required WidgetProvider provider,
  required int androidWidgetId,
  required String library,
  String? note,
}) async {
  if (!Platform.isAndroid) return false;
  try {
    await HomeWidget.saveWidgetData<String>(
      '${widgetPayloadKey(provider, androidWidgetId)}_config',
      jsonEncode({'library': library, 'note': ?note}),
    );
    return true;
  } on PlatformException catch (error) {
    const AppLogger(name: 'widgets').warning('placement save failed ($error)');
    return false;
  } on MissingPluginException {
    return false;
  }
}
