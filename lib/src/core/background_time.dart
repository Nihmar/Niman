/// The time the system gives work under way once the app leaves the
/// screen: on iOS a background task over `niman/background`, without which
/// the app is suspended within seconds, a sync or a capture halfway
/// through. iOS ends it after about half a minute, which is what a quick
/// sync and most captures need.
///
/// Android keeps a capture alive with its short foreground service
/// (plugin_capture_notifier.dart) and a sync with the process; the
/// desktops do not suspend. Everywhere but iOS the work just runs.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';

const MethodChannel _channel = MethodChannel('niman/background');

const AppLogger _log = AppLogger(name: 'background');

/// Runs [work], asking for background time named [name] while it does.
Future<T> withBackgroundTime<T>(String name, Future<T> Function() work) async {
  final id = await beginBackgroundTime(name);
  try {
    return await work();
  } finally {
    await endBackgroundTime(id);
  }
}

/// Asks for background time named [name]; the id to end it with, or null
/// where there is none to ask for (or it was refused).
Future<int?> beginBackgroundTime(String name) async {
  if (!Platform.isIOS) return null;
  try {
    return await _channel.invokeMethod<int>('begin', name);
  } on Exception catch (error) {
    _log.warning('background time for $name not given: $error');
    return null;
  }
}

/// Lets the background time [id] go.
Future<void> endBackgroundTime(int? id) async {
  if (id == null) return;
  try {
    await _channel.invokeMethod<void>('end', id);
  } on Exception catch (error) {
    _log.warning('background time not ended: $error');
  }
}
