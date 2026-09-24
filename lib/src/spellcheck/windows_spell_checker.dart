/// The Windows spell checker (T-PP-09 on Windows): the system's own, through
/// its COM API (`ISpellCheckerFactory`, Windows 8 and later).
///
/// Hunspell is how the desktop spellchecks on Linux, and on Windows it found
/// nothing: no `hunspell.dll` ships with Windows, and its dictionary folders
/// are Linux paths, so the underline and the settings never appeared. The
/// system checker is the one Edge and Word use — the languages installed in
/// Windows, nothing bundled, no dictionary licences to carry — so the
/// Windows build uses that instead.
///
/// The calls go through the interfaces' vtables directly, as the tray menu's
/// do (`core/windows_tray_menu.dart`): four interfaces, a handful of slots
/// each, and no binding layer to keep in step with.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';

const AppLogger _log = AppLogger(name: 'spell');

/// The languages Windows can spellcheck, as BCP 47 tags (`it-IT`, `en-US`):
/// the dictionaries the settings offer. Empty when the API is not there.
List<String> windowsSpellLanguages() {
  final factory = _Factory.open();
  if (factory == null) return const <String>[];
  try {
    return factory.supportedLanguages();
  } finally {
    factory.release();
  }
}

/// A [SpellChecker] over one language of the system's checker.
final class WindowsSpellChecker implements SpellChecker {
  new _(this._checker);

  /// The checker for [language] (a BCP 47 tag, or a hunspell-style `it_IT`),
  /// or for the machine's locale when null — or null when Windows has no
  /// checker for it.
  static WindowsSpellChecker? open({String? language}) {
    if (!Platform.isWindows) return null;
    final factory = _Factory.open();
    if (factory == null) return null;
    try {
      for (final tag in _candidates(language)) {
        if (!factory.isSupported(tag)) continue;
        final checker = factory.create(tag);
        if (checker != null) {
          _log.info('windows spell checker: $tag');
          return WindowsSpellChecker._(checker);
        }
      }
      _log.info(
        'windows spell checker: no language for ${language ?? 'the locale'}',
      );
      return null;
    } finally {
      factory.release();
    }
  }

  /// The tags to try for [language]: as given, with `-` for `_`, then its
  /// base language — and for the locale, the machine's, then English.
  static List<String> _candidates(String? language) {
    final raw = language ?? Platform.localeName.split('.').first;
    final tag = raw.replaceAll('_', '-');
    return <String>{
      tag,
      tag.split('-').first,
      if (language == null) ...<String>['en-US', 'en-GB'],
    }.toList();
  }

  Pointer<_Com>? _checker;

  @override
  bool get available => _checker != null;

  @override
  bool isCorrect(String word) {
    final checker = _checker;
    if (checker == null || word.isEmpty) return true;
    return using((arena) {
      final errors = arena<Pointer<_Com>>();
      final text = word.toNativeUtf16(allocator: arena);
      // ISpellChecker::Check: an enumerator of the errors in the text.
      final hr = _slot(checker, 4)
          .cast<NativeFunction<_CheckC>>()
          .asFunction<_CheckDart>()(checker, text, errors);
      if (hr < 0 || errors.value == nullptr) return true;
      final enumerator = errors.value;
      try {
        final error = arena<Pointer<_Com>>();
        // IEnumSpellingError::Next: S_OK with an error, S_FALSE without.
        final next = _slot(enumerator, 3)
            .cast<NativeFunction<_NextErrorC>>()
            .asFunction<_NextErrorDart>()(enumerator, error);
        if (next != 0 || error.value == nullptr) return true;
        _release(error.value);
        return false;
      } finally {
        _release(enumerator);
      }
    });
  }

  @override
  List<String> suggest(String word) {
    final checker = _checker;
    if (checker == null || word.isEmpty) return const <String>[];
    return using((arena) {
      final list = arena<Pointer<_Com>>();
      final text = word.toNativeUtf16(allocator: arena);
      // ISpellChecker::Suggest: an IEnumString of the suggestions.
      final hr = _slot(checker, 5)
          .cast<NativeFunction<_CheckC>>()
          .asFunction<_CheckDart>()(checker, text, list);
      if (hr < 0 || list.value == nullptr) return const <String>[];
      try {
        return _strings(list.value, arena);
      } finally {
        _release(list.value);
      }
    });
  }

  @override
  void dispose() {
    final checker = _checker;
    if (checker == null) return;
    _checker = null;
    _release(checker);
  }
}

/// The factory, created once per question: it is cheap, and holding it
/// would tie a COM object to whichever thread asked first.
final class _Factory {
  new _(this._ptr);

  final Pointer<_Com> _ptr;

  static _Factory? open() {
    if (!Platform.isWindows) return null;
    try {
      final ole = DynamicLibrary.open('ole32.dll');
      final init = ole.lookupFunction<_CoInitC, _CoInitDart>('CoInitializeEx');
      // The runner initialised the platform thread already; a second call
      // answers S_FALSE, or RPC_E_CHANGED_MODE for another apartment — both
      // leave COM usable here.
      init(nullptr, _coinitApartmentThreaded);
      final create = ole.lookupFunction<_CoCreateC, _CoCreateDart>(
        'CoCreateInstance',
      );
      return using((arena) {
        final out = arena<Pointer<_Com>>();
        final hr = create(
          _guid(arena, _clsidSpellCheckerFactory),
          nullptr,
          _clsctxInprocServer,
          _guid(arena, _iidSpellCheckerFactory),
          out,
        );
        if (hr < 0 || out.value == nullptr) {
          final code = hr.toUnsigned(32).toRadixString(16);
          _log.info('no windows spell checker (0x$code)');
          return null;
        }
        return _Factory._(out.value);
      });
    } on Object catch (error) {
      _log.warning('windows spell checker unavailable ($error)');
      return null;
    }
  }

  /// ISpellCheckerFactory::get_SupportedLanguages.
  List<String> supportedLanguages() => using((arena) {
    final list = arena<Pointer<_Com>>();
    final hr = _slot(
      _ptr,
      3,
    ).cast<NativeFunction<_GetC>>().asFunction<_GetDart>()(_ptr, list);
    if (hr < 0 || list.value == nullptr) return const <String>[];
    try {
      return _strings(list.value, arena);
    } finally {
      _release(list.value);
    }
  });

  /// ISpellCheckerFactory::IsSupported.
  bool isSupported(String tag) => using((arena) {
    final supported = arena<Int32>();
    final hr =
        _slot(
          _ptr,
          4,
        ).cast<NativeFunction<_IsSupportedC>>().asFunction<_IsSupportedDart>()(
          _ptr,
          tag.toNativeUtf16(allocator: arena),
          supported,
        );
    return hr >= 0 && supported.value != 0;
  });

  /// ISpellCheckerFactory::CreateSpellChecker.
  Pointer<_Com>? create(String tag) => using((arena) {
    final out = arena<Pointer<_Com>>();
    final hr =
        _slot(_ptr, 5).cast<NativeFunction<_CheckC>>().asFunction<_CheckDart>()(
          _ptr,
          tag.toNativeUtf16(allocator: arena),
          out,
        );
    return hr < 0 || out.value == nullptr ? null : out.value;
  });

  void release() => _release(_ptr);
}

/// Every string an `IEnumString` holds, each freed as it is read.
List<String> _strings(Pointer<_Com> list, Arena arena) {
  final free = DynamicLibrary.open('ole32.dll')
      .lookupFunction<_TaskFreeC, _TaskFreeDart>('CoTaskMemFree');
  final item = arena<Pointer<Utf16>>();
  final fetched = arena<Uint32>();
  final next = _slot(
    list,
    3,
  ).cast<NativeFunction<_NextStringC>>().asFunction<_NextStringDart>();
  final out = <String>[];
  while (next(list, 1, item, fetched) == 0 && fetched.value == 1) {
    out.add(item.value.toDartString());
    free(item.value.cast());
  }
  return out;
}

/// A COM object: its first field is the vtable.
final class _Com extends Opaque;

/// Slot [index] of [object]'s vtable.
Pointer<Void> _slot(Pointer<_Com> object, int index) =>
    object.cast<Pointer<Pointer<Void>>>().value[index];

/// IUnknown::Release.
void _release(Pointer<_Com> object) => _slot(
  object,
  2,
).cast<NativeFunction<_ReleaseC>>().asFunction<_ReleaseDart>()(object);

/// A GUID in [arena] from its canonical `{…}` form.
Pointer<Uint8> _guid(Arena arena, String text) {
  final hex = text.replaceAll(RegExp('[{}-]'), '');
  final bytes = arena<Uint8>(16);
  // Data1, Data2 and Data3 are little-endian; Data4 is bytes in order.
  final data1 = int.parse(hex.substring(0, 8), radix: 16);
  final data2 = int.parse(hex.substring(8, 12), radix: 16);
  final data3 = int.parse(hex.substring(12, 16), radix: 16);
  for (var at = 0; at < 4; at++) {
    bytes[at] = (data1 >> (8 * at)) & 0xFF;
  }
  bytes[4] = data2 & 0xFF;
  bytes[5] = data2 >> 8;
  bytes[6] = data3 & 0xFF;
  bytes[7] = data3 >> 8;
  for (var at = 0; at < 8; at++) {
    bytes[8 + at] = int.parse(
      hex.substring(16 + 2 * at, 18 + 2 * at),
      radix: 16,
    );
  }
  return bytes;
}

const String _clsidSpellCheckerFactory =
    '{7AB36653-1796-484B-BDFA-E74F1DB7C1DC}';
const String _iidSpellCheckerFactory = '{8E018A9D-2415-4677-BF08-794EA61F94BB}';
const int _coinitApartmentThreaded = 0x2;
const int _clsctxInprocServer = 0x1;

typedef _CoInitC = Int32 Function(Pointer<Void> reserved, Uint32 mode);
typedef _CoInitDart = int Function(Pointer<Void> reserved, int mode);
typedef _CoCreateC = Int32 Function(
  Pointer<Uint8> clsid,
  Pointer<Void> outer,
  Uint32 context,
  Pointer<Uint8> iid,
  Pointer<Pointer<_Com>> out,
);
typedef _CoCreateDart = int Function(
  Pointer<Uint8> clsid,
  Pointer<Void> outer,
  int context,
  Pointer<Uint8> iid,
  Pointer<Pointer<_Com>> out,
);
typedef _TaskFreeC = Void Function(Pointer<Void> memory);
typedef _TaskFreeDart = void Function(Pointer<Void> memory);
typedef _ReleaseC = Uint32 Function(Pointer<_Com> self);
typedef _ReleaseDart = int Function(Pointer<_Com> self);
typedef _GetC = Int32 Function(Pointer<_Com> self, Pointer<Pointer<_Com>> out);
typedef _GetDart = int Function(Pointer<_Com> self, Pointer<Pointer<_Com>> out);
typedef _IsSupportedC = Int32 Function(
  Pointer<_Com> self,
  Pointer<Utf16> tag,
  Pointer<Int32> supported,
);
typedef _IsSupportedDart = int Function(
  Pointer<_Com> self,
  Pointer<Utf16> tag,
  Pointer<Int32> supported,
);
typedef _CheckC = Int32 Function(
  Pointer<_Com> self,
  Pointer<Utf16> text,
  Pointer<Pointer<_Com>> out,
);
typedef _CheckDart = int Function(
  Pointer<_Com> self,
  Pointer<Utf16> text,
  Pointer<Pointer<_Com>> out,
);
typedef _NextErrorC = Int32 Function(
  Pointer<_Com> self,
  Pointer<Pointer<_Com>> error,
);
typedef _NextErrorDart = int Function(
  Pointer<_Com> self,
  Pointer<Pointer<_Com>> error,
);
typedef _NextStringC = Int32 Function(
  Pointer<_Com> self,
  Uint32 count,
  Pointer<Pointer<Utf16>> items,
  Pointer<Uint32> fetched,
);
typedef _NextStringDart = int Function(
  Pointer<_Com> self,
  int count,
  Pointer<Pointer<Utf16>> items,
  Pointer<Uint32> fetched,
);
