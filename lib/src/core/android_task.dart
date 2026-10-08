/// The app's task on Android (#531): Save on a page shared from the
/// browser sends the user back to it while the capture goes on, the
/// activity — and the engine the capture runs in — kept rather than
/// finished, as `SystemNavigator.pop` would.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';

const MethodChannel _channel = MethodChannel('niman/task');

/// Moves the app behind the one the user came from; elsewhere than
/// Android, nothing.
Future<void> moveTaskToBack() async {
  if (!Platform.isAndroid) return;
  try {
    await _channel.invokeMethod<bool>('moveToBack');
  } on PlatformException catch (error) {
    const AppLogger(name: 'capture').warning('task not moved back: $error');
  } on MissingPluginException {
    // An engine without the activity's channels: there is nothing to move.
  }
}
