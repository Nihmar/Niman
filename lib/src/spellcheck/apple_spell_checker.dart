/// The Apple platforms' spell checkers (T-PP-09, docs/records/apple-platforms.md):
/// the system's own, as Windows uses its own — `NSSpellChecker` on a Mac,
/// the one TextEdit and Mail use, and `UITextChecker` on iOS.
///
/// The languages the system has, the words the user taught it, nothing
/// bundled. Niman's personal dictionary is applied on top, as elsewhere.
///
/// The calls go through the Objective-C runtime directly
/// (`core/objc_runtime.dart`), each selector at its signature. Both checkers
/// want the main thread, and the Dart UI isolate runs there on both
/// systems, so the calls are plain synchronous ones, as the editor makes
/// them.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/objc_runtime.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';

const AppLogger _log = AppLogger(name: 'spell');

/// The languages the system can spellcheck (`en`, `en_GB` on a Mac;
/// `en_US`, `it_IT` on iOS): the dictionaries the settings offer. Empty
/// off the Apple platforms.
List<String> appleSpellLanguages() => _Engine.instance?.languages() ?? const [];

/// A [SpellChecker] over one language of the system's checker.
final class AppleSpellChecker implements SpellChecker {
  new _(this._engine, this._language);

  /// The checker for [language] (`it`, `en_GB`, or a hunspell-style
  /// `it_IT`), or for the device's locale when null — or null when the
  /// system has no checker for it.
  static AppleSpellChecker? open({String? language}) {
    final engine = _Engine.instance;
    if (engine == null) return null;
    final available = engine.languages();
    final name = (language ?? Platform.localeName.split('.').first).replaceAll(
      '-',
      '_',
    );
    final base = name.split('_').first;
    // Most specific first: the name as asked, the bare language, then the
    // first region of it the system has (iOS lists only `it_IT`).
    final chosen = [
      name,
      base,
      ...available.where((l) => l.startsWith('${base}_')),
    ].where(available.contains).firstOrNull;
    if (chosen == null) {
      _log.info('apple spell checker: no language for $name');
      return null;
    }
    _log.info('apple spell checker: $chosen');
    return AppleSpellChecker._(engine, engine.runtime.retained(chosen));
  }

  final _Engine _engine;

  /// The language, as the `NSString` every call names; retained until
  /// [dispose].
  ObjCId _language;

  @override
  bool get available => _language != nullptr;

  @override
  bool isCorrect(String word) {
    if (!available || word.isEmpty) return true;
    return _engine.isCorrect(
      _engine.runtime.string(word),
      word.length,
      _language,
    );
  }

  @override
  List<String> suggest(String word) {
    if (!available || word.isEmpty) return const <String>[];
    return _engine.runtime.strings(
      _engine.guesses(_engine.runtime.string(word), word.length, _language),
    );
  }

  @override
  void dispose() {
    if (!available) return;
    _engine.runtime.release(_language);
    _language = nullptr;
  }
}

/// `NSNotFound`, where `UITextChecker` finds no misspelling.
const int _notFound = 0x7FFFFFFFFFFFFFFF;

/// The system checker's few calls, the same on both systems.
abstract base class _Engine {
  new(this.runtime);

  /// The engine of this system: `NSSpellChecker` on a Mac, `UITextChecker`
  /// on iOS; null elsewhere.
  static final _Engine? instance = switch (ObjCRuntime.instance) {
    final runtime? when Platform.isMacOS => _NSSpellCheckerEngine(runtime),
    final runtime? when Platform.isIOS => _UITextCheckerEngine(runtime),
    _ => null,
  };

  final ObjCRuntime runtime;

  /// The languages it has.
  List<String> languages();

  /// Whether the [length] UTF-16 units of [text] are a word of [language].
  bool isCorrect(ObjCId text, int length, ObjCId language);

  /// The guesses for the [length] UTF-16 units of [text], an `NSArray`.
  ObjCId guesses(ObjCId text, int length, ObjCId language);

  /// A range from 0 over [length] units, by value, while [use] runs.
  T withRange<T>(int length, T Function(NSRange range) use) {
    final range = calloc<NSRange>();
    try {
      range.ref
        ..location = 0
        ..length = length;
      return use(range.ref);
    } finally {
      calloc.free(range);
    }
  }
}

/// A Mac's `[NSSpellChecker sharedSpellChecker]`.
final class _NSSpellCheckerEngine extends _Engine {
  new(super.runtime);

  late final ObjCId _checker = runtime.send(
    runtime.classNamed('NSSpellChecker')!,
    'sharedSpellChecker',
  );

  // checkSpellingOfString:startingAt:language:wrap:inSpellDocumentWithTag:
  // wordCount: — a BOOL is one byte on both architectures.
  late final NSRange Function(
    ObjCId,
    ObjCId,
    ObjCId,
    int,
    ObjCId,
    int,
    int,
    Pointer<Long>,
  )
  _check = runtime.msgSend
      .cast<
        NativeFunction<
          NSRange Function(
            ObjCId,
            ObjCId,
            ObjCId,
            Long,
            ObjCId,
            Int8,
            Long,
            Pointer<Long>,
          )
        >
      >()
      .asFunction();

  // guessesForWordRange:inString:language:inSpellDocumentWithTag:
  late final ObjCId Function(ObjCId, ObjCId, NSRange, ObjCId, ObjCId, int)
  _guesses = runtime.msgSend
      .cast<
        NativeFunction<
          ObjCId Function(ObjCId, ObjCId, NSRange, ObjCId, ObjCId, Long)
        >
      >()
      .asFunction();

  @override
  List<String> languages() =>
      runtime.strings(runtime.send(_checker, 'availableLanguages'));

  @override
  bool isCorrect(ObjCId text, int length, ObjCId language) =>
      _check(
        _checker,
        runtime.sel(
          'checkSpellingOfString:startingAt:language:wrap:'
          'inSpellDocumentWithTag:wordCount:',
        ),
        text,
        0,
        language,
        0,
        0,
        nullptr,
      ).length ==
      0;

  @override
  ObjCId guesses(ObjCId text, int length, ObjCId language) => withRange(
    length,
    (range) => _guesses(
      _checker,
      runtime.sel(
        'guessesForWordRange:inString:language:inSpellDocumentWithTag:',
      ),
      range,
      text,
      language,
      0,
    ),
  );
}

/// iOS's `UITextChecker`, one for the app's life.
final class _UITextCheckerEngine extends _Engine {
  new(super.runtime);

  late final ObjCId _class = runtime.classNamed('UITextChecker')!;

  late final ObjCId _checker = runtime.send(
    runtime.send(_class, 'alloc'),
    'init',
  );

  // rangeOfMisspelledWordInString:range:startingAt:wrap:language:
  late final NSRange Function(ObjCId, ObjCId, ObjCId, NSRange, int, int, ObjCId)
  _misspelled = runtime.msgSend
      .cast<
        NativeFunction<
          NSRange Function(ObjCId, ObjCId, ObjCId, NSRange, Long, Int8, ObjCId)
        >
      >()
      .asFunction();

  // guessesForWordRange:inString:language:
  late final ObjCId Function(ObjCId, ObjCId, NSRange, ObjCId, ObjCId)
  _guesses = runtime.msgSend
      .cast<
        NativeFunction<ObjCId Function(ObjCId, ObjCId, NSRange, ObjCId, ObjCId)>
      >()
      .asFunction();

  @override
  List<String> languages() =>
      runtime.strings(runtime.send(_class, 'availableLanguages'));

  @override
  bool isCorrect(ObjCId text, int length, ObjCId language) => withRange(
    length,
    (range) =>
        _misspelled(
          _checker,
          runtime.sel(
            'rangeOfMisspelledWordInString:range:startingAt:wrap:language:',
          ),
          text,
          range,
          0,
          0,
          language,
        ).location ==
        _notFound,
  );

  @override
  ObjCId guesses(ObjCId text, int length, ObjCId language) => withRange(
    length,
    (range) => _guesses(
      _checker,
      runtime.sel('guessesForWordRange:inString:language:'),
      range,
      text,
      language,
    ),
  );
}
