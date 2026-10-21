/// The Mac's side of the screen kept on while slides are presented (#534):
/// a power assertion, `PreventUserIdleDisplaySleep`, taken through IOKit
/// with no plugin, as Windows asks `SetThreadExecutionState` directly.
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

typedef _CreateC = Int32 Function(
  Pointer<Void> type,
  Uint32 level,
  Pointer<Void> name,
  Pointer<Uint32> id,
);
typedef _CreateDart = int Function(
  Pointer<Void> type,
  int level,
  Pointer<Void> name,
  Pointer<Uint32> id,
);
typedef _ReleaseC = Int32 Function(Uint32 id);
typedef _ReleaseDart = int Function(int id);
typedef _StringC = Pointer<Void> Function(
  Pointer<Void> allocator,
  Pointer<Utf8> text,
  Uint32 encoding,
);
typedef _StringDart = Pointer<Void> Function(
  Pointer<Void> allocator,
  Pointer<Utf8> text,
  int encoding,
);
typedef _CFReleaseC = Void Function(Pointer<Void> object);
typedef _CFReleaseDart = void Function(Pointer<Void> object);

const int _kIOPMAssertionLevelOn = 255;
const int _kCFStringEncodingUTF8 = 0x08000100;

/// The assertion held, or null: one for as long as slides are presented.
int? _assertion;

/// Takes the assertion ([on]) or releases it; answers whether the system
/// took or let go of it. Taking it twice keeps the one already held.
bool macKeepScreenOn({required bool on}) {
  final iokit = DynamicLibrary.open(
    '/System/Library/Frameworks/IOKit.framework/IOKit',
  );
  if (!on) {
    final held = _assertion;
    if (held == null) return true;
    _assertion = null;
    return iokit.lookupFunction<_ReleaseC, _ReleaseDart>(
          'IOPMAssertionRelease',
        )(held) ==
        0;
  }
  if (_assertion != null) return true;
  final cf = DynamicLibrary.open(
    '/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation',
  );
  final string = cf.lookupFunction<_StringC, _StringDart>(
    'CFStringCreateWithCString',
  );
  final release = cf.lookupFunction<_CFReleaseC, _CFReleaseDart>('CFRelease');
  return using((arena) {
    final type = string(
      nullptr,
      'PreventUserIdleDisplaySleep'.toNativeUtf8(allocator: arena),
      _kCFStringEncodingUTF8,
    );
    final name = string(
      nullptr,
      'Niman is presenting slides'.toNativeUtf8(allocator: arena),
      _kCFStringEncodingUTF8,
    );
    final id = arena<Uint32>();
    try {
      final result = iokit.lookupFunction<_CreateC, _CreateDart>(
        'IOPMAssertionCreateWithName',
      )(type, _kIOPMAssertionLevelOn, name, id);
      if (result != 0) return false;
      _assertion = id.value;
      return true;
    } finally {
      release(type);
      release(name);
    }
  });
}
