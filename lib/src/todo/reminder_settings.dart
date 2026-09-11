/// The system settings that decide whether a reminder can fire (T-TD-07).
///
/// Two of them, both outside the app's control and both silent when
/// wrong:
///
/// * **Notifications.** Denied or turned off, the alarm still fires and
///   nothing is shown.
/// * **Battery optimization.** Reminders are `AlarmManager` alarms: the
///   system holds them and fires them with Niman's process dead, which
///   is the whole point. An app left optimized can still be put to sleep
///   by an OEM battery manager, and several ROMs (MIUI/HyperOS, EMUI,
///   ColorOS, Funtouch) drop its pending alarms outright when it is
///   swiped away from recents — so a reminder set for tomorrow never
///   arrives.
///
/// Neither is a runtime permission, so both are reached by opening the
/// system screen. The battery one is deliberately not requested through
/// `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: that one-tap dialog
/// needs `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, which app stores
/// restrict to a narrow set of categories. The plain list needs nothing.
library;

import 'dart:io';

import 'package:flutter/services.dart';

/// What the reminder UI needs from the platform's system settings.
///
/// An interface so widget tests inject a fake instead of a method channel
/// that never answers under `testWidgets`.
abstract interface class ReminderSettings {
  /// Whether Niman is exempt from battery optimization right now.
  Future<bool> isBatteryExempt();

  /// Opens the system list where the exemption is granted.
  ///
  /// Returns false when no activity handles it.
  Future<bool> openBatterySettings();

  /// Opens Niman's page in the system notification settings.
  ///
  /// Returns false when no activity handles it.
  Future<bool> openNotificationSettings();
}

/// The real gate: a method channel on Android, inert elsewhere.
final class PlatformReminderSettings implements ReminderSettings {
  /// Creates the platform gate.
  const new();

  static const MethodChannel _channel = MethodChannel('niman/reminders');

  @override
  Future<bool> isBatteryExempt() async {
    // Nothing throttles a desktop process the way Doze throttles an app,
    // so there is nothing to warn about off Android.
    if (!Platform.isAndroid) return true;
    return await _invoke('isIgnoringBatteryOptimizations') ?? true;
  }

  @override
  Future<bool> openBatterySettings() async {
    if (!Platform.isAndroid) return false;
    return await _invoke('openBatterySettings') ?? false;
  }

  @override
  Future<bool> openNotificationSettings() async {
    if (!Platform.isAndroid) return false;
    return await _invoke('openNotificationSettings') ?? false;
  }

  /// [method] over the channel, or null when it fails.
  ///
  /// An unanswered channel must not become a false warning, so every
  /// caller supplies the benign default.
  Future<bool?> _invoke(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method);
    } on Object {
      return null;
    }
  }
}
