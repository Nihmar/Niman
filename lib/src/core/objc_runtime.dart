/// The Objective-C runtime, called through FFI with no plugin: what the
/// Apple platforms' system services take from Dart directly — the spell
/// checkers (`NSSpellChecker`, `UITextChecker`) — as Windows' go through
/// COM vtables. The Dart UI isolate runs on the main thread there, so the
/// calls are synchronous ones.
///
/// Each caller casts [ObjCRuntime.msgSend] to the signature its selector
/// takes; this holds what they all need: classes, selectors, `NSString`,
/// `NSArray`, and the object's lifetime.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// An Objective-C object, or a class or a selector.
typedef ObjCId = Pointer<Void>;

/// `NSRange`, as selectors take and answer it by value.
final class NSRange extends Struct {
  /// Where the range starts, in UTF-16 units.
  @UnsignedLong()
  external int location;

  /// How many UTF-16 units it spans.
  @UnsignedLong()
  external int length;
}

/// The runtime's calls.
final class ObjCRuntime {
  new _(DynamicLibrary lib)
    : _getClass = lib
          .lookupFunction<
            ObjCId Function(Pointer<Utf8>),
            ObjCId Function(Pointer<Utf8>)
          >('objc_getClass'),
      _selector = lib
          .lookupFunction<
            ObjCId Function(Pointer<Utf8>),
            ObjCId Function(Pointer<Utf8>)
          >('sel_registerName'),
      msgSend = lib.lookup<Void>('objc_msgSend');

  /// The runtime, on macOS and iOS; null elsewhere.
  static final ObjCRuntime? instance = Platform.isMacOS || Platform.isIOS
      ? ObjCRuntime._(DynamicLibrary.process())
      : null;

  final ObjCId Function(Pointer<Utf8>) _getClass;
  final ObjCId Function(Pointer<Utf8>) _selector;

  /// `objc_msgSend`, for a caller to cast to its selector's signature.
  final Pointer<Void> msgSend;

  final Map<String, ObjCId> _selectors = {};
  final Map<String, ObjCId> _classes = {};

  /// The selector [name].
  ObjCId sel(String name) => _selectors[name] ??= using(
    (arena) => _selector(name.toNativeUtf8(allocator: arena)),
  );

  /// The class [name], or null when the process has none by that name.
  ObjCId? classNamed(String name) {
    final known = _classes[name] ??= using(
      (arena) => _getClass(name.toNativeUtf8(allocator: arena)),
    );
    return known == nullptr ? null : known;
  }

  late final ObjCId Function(ObjCId, ObjCId) _send0 = msgSend
      .cast<NativeFunction<ObjCId Function(ObjCId, ObjCId)>>()
      .asFunction();

  late final ObjCId Function(ObjCId, ObjCId, Pointer<Utf8>) _sendUtf8 = msgSend
      .cast<NativeFunction<ObjCId Function(ObjCId, ObjCId, Pointer<Utf8>)>>()
      .asFunction();

  late final Pointer<Utf8> Function(ObjCId, ObjCId) _sendToUtf8 = msgSend
      .cast<NativeFunction<Pointer<Utf8> Function(ObjCId, ObjCId)>>()
      .asFunction();

  late final int Function(ObjCId, ObjCId) _sendToCount = msgSend
      .cast<NativeFunction<UnsignedLong Function(ObjCId, ObjCId)>>()
      .asFunction();

  late final ObjCId Function(ObjCId, ObjCId, int) _sendIndex = msgSend
      .cast<NativeFunction<ObjCId Function(ObjCId, ObjCId, UnsignedLong)>>()
      .asFunction();

  /// `[target name]`, for a selector that takes nothing and answers an
  /// object.
  ObjCId send(ObjCId target, String name) => _send0(target, sel(name));

  /// [text] as an autoreleased `NSString`.
  ObjCId string(String text) => using(
    (arena) => _sendUtf8(
      classNamed('NSString')!,
      sel('stringWithUTF8String:'),
      text.toNativeUtf8(allocator: arena),
    ),
  );

  /// [text] as an `NSString` this side owns, until [release].
  ObjCId retained(String text) => send(string(text), 'retain');

  /// Lets go of an object this side owns.
  void release(ObjCId object) => send(object, 'release');

  /// The strings of an `NSArray` of `NSString`s; empty for none.
  List<String> strings(ObjCId array) {
    if (array == nullptr) return const <String>[];
    final count = _sendToCount(array, sel('count'));
    return [
      for (var i = 0; i < count; i++)
        _sendToUtf8(
          _sendIndex(array, sel('objectAtIndex:'), i),
          sel('UTF8String'),
        ).toDartString(),
    ];
  }
}
