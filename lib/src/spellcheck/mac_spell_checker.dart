/// The Mac spell checker (T-PP-09 on macOS): the system's own,
/// `NSSpellChecker`, as Windows uses its own (docs/records/apple-platforms.md).
///
/// It is the checker TextEdit and Mail use: the languages macOS has, the
/// words the user taught the system, nothing bundled. Niman's personal
/// dictionary is applied on top, as on the other desktops.
///
/// The calls go through the Objective-C runtime directly — `objc_msgSend`
/// with the signature each selector takes — as Windows' go through COM
/// vtables: a handful of selectors and no binding layer to keep in step
/// with. `NSSpellChecker` wants the main thread, and on macOS the Dart UI
/// isolate runs there, so the calls are plain synchronous ones, as the
/// editor makes them.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';

const AppLogger _log = AppLogger(name: 'spell');

/// The languages macOS can spellcheck (`en`, `en_GB`, `it`…): the
/// dictionaries the settings offer. Empty off macOS.
List<String> macSpellLanguages() {
  final objc = _ObjC.instance;
  if (objc == null) return const <String>[];
  return objc.strings(objc.send(objc.checker, 'availableLanguages'));
}

/// A [SpellChecker] over one language of the system's checker.
final class MacSpellChecker implements SpellChecker {
  new _(this._objc, this._language);

  /// The checker for [language] (`it`, `en_GB`, or a hunspell-style
  /// `it_IT`), or for the machine's locale when null — or null when macOS
  /// has no checker for it.
  static MacSpellChecker? open({String? language}) {
    final objc = _ObjC.instance;
    if (objc == null) return null;
    final available = macSpellLanguages();
    for (final candidate in _candidates(language)) {
      if (!available.contains(candidate)) continue;
      _log.info('mac spell checker: $candidate');
      return MacSpellChecker._(objc, objc.retained(candidate));
    }
    _log.info('mac spell checker: no language for ${language ?? 'the locale'}');
    return null;
  }

  /// The names to try for [language], most specific first: `it_IT`, then
  /// `it`; the locale's when null.
  static List<String> _candidates(String? language) {
    final name = (language ?? Platform.localeName.split('.').first).replaceAll(
      '-',
      '_',
    );
    final base = name.split('_').first;
    return [name, if (base != name) base];
  }

  final _ObjC _objc;

  /// The language, as the `NSString` every call names; retained until
  /// [dispose].
  Pointer<Void> _language;

  @override
  bool get available => _language != nullptr;

  @override
  bool isCorrect(String word) {
    if (!available || word.isEmpty) return true;
    final miss = _objc.checkSpelling(_objc.string(word), _language);
    return miss.length == 0;
  }

  @override
  List<String> suggest(String word) {
    if (!available || word.isEmpty) return const <String>[];
    return _objc.strings(
      _objc.guesses(_objc.string(word), word.length, _language),
    );
  }

  @override
  void dispose() {
    if (!available) return;
    _objc.release(_language);
    _language = nullptr;
  }
}

/// `NSRange`, as `checkSpellingOfString:…` answers it.
final class _NSRange extends Struct {
  @UnsignedLong()
  external int location;

  @UnsignedLong()
  external int length;
}

typedef _Id = Pointer<Void>;

/// The runtime calls the checker makes, each selector at its signature.
final class _ObjC {
  new _(DynamicLibrary lib)
    : _getClass = lib
          .lookupFunction<
            _Id Function(Pointer<Utf8>),
            _Id Function(Pointer<Utf8>)
          >('objc_getClass'),
      _selector = lib
          .lookupFunction<
            _Id Function(Pointer<Utf8>),
            _Id Function(Pointer<Utf8>)
          >('sel_registerName'),
      _msgSend = lib.lookup<Void>('objc_msgSend');

  static _ObjC? _instance;

  /// The runtime, on macOS; null elsewhere.
  static _ObjC? get instance {
    if (!Platform.isMacOS) return null;
    return _instance ??= _ObjC._(DynamicLibrary.process());
  }

  final _Id Function(Pointer<Utf8>) _getClass;
  final _Id Function(Pointer<Utf8>) _selector;
  final Pointer<Void> _msgSend;
  final Map<String, _Id> _selectors = {};

  _Id _sel(String name) => _selectors[name] ??= using(
    (arena) => _selector(name.toNativeUtf8(allocator: arena)),
  );

  late final _Id Function(_Id, _Id) _send0 = _msgSend
      .cast<NativeFunction<_Id Function(_Id, _Id)>>()
      .asFunction();

  late final _Id Function(_Id, _Id, Pointer<Utf8>) _sendUtf8 = _msgSend
      .cast<NativeFunction<_Id Function(_Id, _Id, Pointer<Utf8>)>>()
      .asFunction();

  late final Pointer<Utf8> Function(_Id, _Id) _sendToUtf8 = _msgSend
      .cast<NativeFunction<Pointer<Utf8> Function(_Id, _Id)>>()
      .asFunction();

  late final int Function(_Id, _Id) _sendToCount = _msgSend
      .cast<NativeFunction<UnsignedLong Function(_Id, _Id)>>()
      .asFunction();

  late final _Id Function(_Id, _Id, int) _sendIndex = _msgSend
      .cast<NativeFunction<_Id Function(_Id, _Id, UnsignedLong)>>()
      .asFunction();

  // checkSpellingOfString:startingAt:language:wrap:inSpellDocumentWithTag:
  // wordCount:
  late final _NSRange Function(_Id, _Id, _Id, int, _Id, int, int, Pointer<Long>)
  _sendCheck = _msgSend
      .cast<
        NativeFunction<
          _NSRange Function(_Id, _Id, _Id, Long, _Id, Int8, Long, Pointer<Long>)
        >
      >()
      .asFunction();

  // guessesForWordRange:inString:language:inSpellDocumentWithTag:
  late final _Id Function(_Id, _Id, _NSRange, _Id, _Id, int)
  _sendGuesses = _msgSend
      .cast<NativeFunction<_Id Function(_Id, _Id, _NSRange, _Id, _Id, Long)>>()
      .asFunction();

  /// `[NSSpellChecker sharedSpellChecker]`.
  late final _Id checker = _send0(
    using(
      (arena) => _getClass('NSSpellChecker'.toNativeUtf8(allocator: arena)),
    ),
    _sel('sharedSpellChecker'),
  );

  /// `[target name]`, for a selector that takes nothing and answers an
  /// object.
  _Id send(_Id target, String name) => _send0(target, _sel(name));

  /// [text] as an autoreleased `NSString`.
  _Id string(String text) => using(
    (arena) => _sendUtf8(
      using((inner) => _getClass('NSString'.toNativeUtf8(allocator: inner))),
      _sel('stringWithUTF8String:'),
      text.toNativeUtf8(allocator: arena),
    ),
  );

  /// [text] as an `NSString` this side owns, until [release].
  _Id retained(String text) => send(string(text), 'retain');

  void release(_Id object) => send(object, 'release');

  /// The strings of an `NSArray` of `NSString`s.
  List<String> strings(_Id array) {
    if (array == nullptr) return const <String>[];
    final count = _sendToCount(array, _sel('count'));
    return [
      for (var i = 0; i < count; i++)
        _sendToUtf8(
          _sendIndex(array, _sel('objectAtIndex:'), i),
          _sel('UTF8String'),
        ).toDartString(),
    ];
  }

  /// The first misspelt range of [text] in [language]: length 0 for none.
  _NSRange checkSpelling(_Id text, _Id language) => _sendCheck(
    checker,
    _sel(
      'checkSpellingOfString:startingAt:language:wrap:'
      'inSpellDocumentWithTag:wordCount:',
    ),
    text,
    0,
    language,
    0, // wrap: NO (a BOOL, one byte on both architectures)
    0,
    nullptr,
  );

  /// The system's guesses for the [length] UTF-16 units of [text].
  _Id guesses(_Id text, int length, _Id language) {
    final range = calloc<_NSRange>();
    try {
      range.ref
        ..location = 0
        ..length = length;
      return _sendGuesses(
        checker,
        _sel('guessesForWordRange:inString:language:inSpellDocumentWithTag:'),
        range.ref,
        text,
        language,
        0,
      );
    } finally {
      calloc.free(range);
    }
  }
}
