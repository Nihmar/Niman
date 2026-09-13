// The pending note pin (issue 6): which note the next placed note
// widget adopts.
//
// A placed widget cannot be configured in place (no native picker yet),
// so pinning runs from the app: the user pins a note, places the widget,
// and the next refresh adopts the pin for the unknown instance and
// consumes it. Transient by design — SharedPreferences, not the database
// — and Android-only, like the widgets themselves.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:niman/src/core/logging.dart';

/// The pin key in the widget storage.
const String widgetPinKey = 'note_widget_pin';

/// What the refresh needs from the pin layer.
abstract interface class WidgetPinStore {
  /// The pending pin, cleared on read (once, then null).
  Future<({String libraryPath, String notePath})?> consumePin();
}

/// Saves a pending pin for [libraryPath]/[notePath] (Android only).
///
/// True when the pin is stored; false off-Android or when the plugin is
/// unavailable.
Future<bool> saveWidgetPin({
  required String libraryPath,
  required String notePath,
}) async {
  if (!Platform.isAndroid) return false;
  try {
    await HomeWidget.saveWidgetData<String>(
      widgetPinKey,
      jsonEncode({'libraryPath': libraryPath, 'notePath': notePath}),
    );
    return true;
  } on PlatformException catch (error) {
    const AppLogger(name: 'widgets').warning('pin unavailable ($error)');
    return false;
  } on MissingPluginException {
    return false;
  }
}

/// The plugin-backed pin store (Android only; inert elsewhere).
final class PlatformWidgetPinStore implements WidgetPinStore {
  /// Creates the store.
  const new();

  @override
  Future<({String libraryPath, String notePath})?> consumePin() async {
    try {
      final raw = await HomeWidget.getWidgetData<String>(widgetPinKey);
      if (raw == null || raw.isEmpty) return null;
      await HomeWidget.saveWidgetData<String>(widgetPinKey, null);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final library = decoded['libraryPath'];
      final note = decoded['notePath'];
      if (library is! String ||
          library.isEmpty ||
          note is! String ||
          note.isEmpty) {
        return null;
      }
      return (libraryPath: library, notePath: note);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
