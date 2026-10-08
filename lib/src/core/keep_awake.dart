/// The screen kept on while slides are presented (#534): no blanking, no
/// lock, no sleep until the talk ends.
///
/// Android sets `FLAG_KEEP_SCREEN_ON` on the window and Linux takes GTK's
/// idle inhibit, both over `niman/screen`; Windows asks
/// `SetThreadExecutionState` directly.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';

const MethodChannel _channel = MethodChannel('niman/screen');

typedef _SetStateC = Uint32 Function(Uint32 flags);
typedef _SetStateDart = int Function(int flags);

const int _esContinuous = 0x80000000;
const int _esSystemRequired = 0x00000001;
const int _esDisplayRequired = 0x00000002;

/// Keeps the screen on, or lets it go back to its own timeout.
///
/// A platform that cannot answers nothing: the slides are still shown, the
/// screen only blanks on its usual timeout.
Future<void> keepScreenOn({required bool on}) async {
  try {
    if (Platform.isWindows) {
      DynamicLibrary.open('kernel32.dll')
          .lookupFunction<_SetStateC, _SetStateDart>('SetThreadExecutionState')(
        on
            ? _esContinuous | _esDisplayRequired | _esSystemRequired
            : _esContinuous,
      );
    } else if (Platform.isAndroid || Platform.isLinux) {
      await _channel.invokeMethod<void>('keepOn', on);
    }
  } on Exception catch (error) {
    const AppLogger(name: 'slides').warning('keep the screen on: $error');
  }
}
