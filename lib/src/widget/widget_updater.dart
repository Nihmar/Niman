/// Pushes home-screen widget snapshots to the launcher (issue 6).
///
/// The native provider only reads `SharedPreferences`: pushing saves the
/// instance payload and asks the launcher to refresh that provider.
/// Pushes for one instance serialize — a second push landing mid-flight
/// replaces the pending one instead of racing it — and each instance
/// carries its own key, so two widgets for two libraries update
/// independently.
library;

import 'package:home_widget/home_widget.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_payload.dart';

/// Saves [data] under [id] in the widget storage.
typedef SaveWidgetData = Future<bool?> Function(String id, String? data);

/// Asks the launcher to refresh [androidName]'s widgets.
typedef UpdateWidgets = Future<bool?> Function({
  required String androidName,
  required String qualifiedAndroidName,
});

/// The launcher-facing widget pusher (issue 6).
///
/// The platform callbacks default to the `home_widget` plugin; tests
/// inject fakes.
final class WidgetUpdater {
  /// Creates the updater; [saveData]/[updateWidgets] are injected in
  /// tests.
  new({SaveWidgetData? saveData, UpdateWidgets? updateWidgets})
    : _saveData = saveData ?? _pluginSave,
      _updateWidgets = updateWidgets ?? _pluginUpdate;

  final SaveWidgetData _saveData;
  final UpdateWidgets _updateWidgets;

  /// Instances with a push in flight.
  final Set<String> _busy = <String>{};

  /// The latest payload waiting per busy instance (a newer push replaces
  /// an older one: the launcher only ever shows the newest; null clears).
  final Map<String, String?> _pending = <String, String?>{};

  /// Pushes [payload] to [androidWidgetId]'s widget of [provider] and
  /// refreshes it.
  Future<void> push({
    required WidgetProvider provider,
    required int androidWidgetId,
    required String payload,
  }) {
    return _pushKeyed(
      widgetPayloadKey(provider, androidWidgetId),
      provider,
      payload,
    );
  }

  /// Clears [androidWidgetId]'s widget of [provider] (called when its
  /// configuration is removed) and refreshes it.
  Future<void> clear({
    required WidgetProvider provider,
    required int androidWidgetId,
  }) {
    return _pushKeyed(
      widgetPayloadKey(provider, androidWidgetId),
      provider,
      null,
    );
  }

  /// Saves [payload] (null clears) under [key] and refreshes [provider],
  /// serializing concurrent pushes for the same key.
  Future<void> _pushKeyed(
    String key,
    WidgetProvider provider,
    String? payload,
  ) async {
    if (_busy.contains(key)) {
      _pending[key] = payload;
      return;
    }
    _busy.add(key);
    try {
      var current = payload;
      while (true) {
        await _saveData(key, current);
        await _updateWidgets(
          androidName: widgetProviderAndroidName(provider),
          qualifiedAndroidName: widgetProviderQualifiedName(provider),
        );
        if (!_pending.containsKey(key)) return;
        current = _pending.remove(key);
      }
    } finally {
      _busy.remove(key);
    }
  }

  /// Saves through the `home_widget` plugin.
  static Future<bool?> _pluginSave(String id, String? data) {
    return HomeWidget.saveWidgetData<String>(id, data);
  }

  /// Refreshes through the `home_widget` plugin.
  static Future<bool?> _pluginUpdate({
    required String androidName,
    required String qualifiedAndroidName,
  }) {
    return HomeWidget.updateWidget(
      androidName: androidName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }
}
