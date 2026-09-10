/// The hunspell [SpellChecker] (T-PP-09, revised).
///
/// Binds `libhunspell` through `dart:ffi` and opens the first
/// `<locale>.aff`/`.dic` pair found on disk. Nothing is bundled: the system
/// library and the user's dictionaries are the source, exactly like the
/// desktop's other apps. Absence is not an error — `open` returns null and
/// the caller falls back to [NoopSpellChecker].
library;

import 'dart:ffi';
import 'dart:io';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/spellcheck/spell_checker.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

/// The shared libraries to try, in order (Linux, macOS, Windows).
const List<String> _libraryNames = <String>[
  'libhunspell-1.7.so.0',
  'libhunspell-1.7.so',
  'libhunspell.so',
  'libhunspell-1.7.dylib',
  'libhunspell.dylib',
  'libhunspell.dll',
  'hunspell.dll',
];

/// Where dictionaries are looked for, in priority order.
///
/// Hunspell's own search path plus the per-user directories the desktop
/// tools (enchant, LibreOffice, Telegram) install into.
List<String> defaultDictionaryDirs() {
  final home = Platform.environment['HOME'];
  return <String>[
    '/usr/share/hunspell',
    '/usr/share/myspell',
    '/usr/share/myspell/dicts',
    '/usr/local/share/hunspell',
    if (home != null) ...<String>[
      p.join(home, '.local', 'share', 'hunspell'),
      p.join(home, '.local', 'share', 'enchant', 'hunspell'),
      p.join(home, '.local', 'share', 'dictionaries'),
      p.join(home, '.config', 'hunspell'),
    ],
  ];
}

/// Finds the first usable dictionary pair for [locale] in [dirs].
///
/// Candidate names are the locale tag (`en_GB`), its hyphenated form, its
/// language alone (`en`), then the two defaults. When no candidate matches,
/// the first pair in any directory wins, so an unusual locale still gets a
/// dictionary rather than nothing.
({String aff, String dic})? discoverDictionary({
  String? locale,
  List<String>? dirs,
}) {
  final search = dirs ?? defaultDictionaryDirs();
  final candidates = <String>[];
  final tag = _normalizeLocale(locale ?? Platform.localeName);
  if (tag != null) {
    candidates
      ..add(tag)
      ..add(tag.replaceAll('_', '-'))
      ..add(tag.split('_').first);
  }
  candidates.addAll(const <String>['en_US', 'en_GB']);
  for (final name in candidates) {
    for (final dir in search) {
      final aff = File(p.join(dir, '$name.aff'));
      if (!aff.existsSync()) continue;
      final dic = File(p.join(dir, '$name.dic'));
      if (dic.existsSync()) return (aff: aff.path, dic: dic.path);
    }
  }
  for (final dir in search) {
    final directory = Directory(dir);
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync()) {
      if (entity is! File || !entity.path.endsWith('.aff')) continue;
      final dic = File(
        '${entity.path.substring(0, entity.path.length - 4)}.dic',
      );
      if (dic.existsSync()) return (aff: entity.path, dic: dic.path);
    }
  }
  return null;
}

/// The `xx_YY` tag of a locale like `en_GB.UTF-8`, or null for `C`.
String? _normalizeLocale(String locale) {
  final base = locale.split('.').first.replaceAll('-', '_');
  if (base.isEmpty || base == 'C' || base == 'POSIX') return null;
  return base;
}

/// [SpellChecker] over the system hunspell.
final class HunspellSpellChecker implements SpellChecker {
  new _({
    required this._handle,
    required this._spell,
    required this._suggest,
    required this._freeList,
    required this._destroy,
  });

  /// Opens the library and a dictionary, or null when either is missing.
  ///
  /// [library], [locale] and [dirs] are test seams; the defaults are the
  /// system ones.
  static HunspellSpellChecker? open({
    DynamicLibrary? library,
    String? locale,
    List<String>? dirs,
  }) {
    final lib = library ?? _openLibrary();
    if (lib == null) return null;
    final dict = discoverDictionary(locale: locale, dirs: dirs);
    if (dict == null) return null;
    final aff = dict.aff.toNativeUtf8();
    final dic = dict.dic.toNativeUtf8();
    try {
      final create = lib
          .lookupFunction<
            Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>),
            Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>)
          >('Hunspell_create');
      final handle = create(aff, dic);
      if (handle == nullptr) return null;
      return HunspellSpellChecker._(
        handle: handle,
        spell: lib
            .lookupFunction<
              Int32 Function(Pointer<Void>, Pointer<Utf8>),
              int Function(Pointer<Void>, Pointer<Utf8>)
            >('Hunspell_spell'),
        suggest: lib
            .lookupFunction<
              Int32 Function(
                Pointer<Void>,
                Pointer<Pointer<Pointer<Utf8>>>,
                Pointer<Utf8>,
              ),
              int Function(
                Pointer<Void>,
                Pointer<Pointer<Pointer<Utf8>>>,
                Pointer<Utf8>,
              )
            >('Hunspell_suggest'),
        freeList: lib
            .lookupFunction<
              Void Function(
                Pointer<Void>,
                Pointer<Pointer<Pointer<Utf8>>>,
                Int32,
              ),
              void Function(Pointer<Void>, Pointer<Pointer<Pointer<Utf8>>>, int)
            >('Hunspell_free_list'),
        destroy: lib
            .lookupFunction<
              Void Function(Pointer<Void>),
              void Function(Pointer<Void>)
            >('Hunspell_destroy'),
      );
    } on Object catch (error) {
      const AppLogger(name: 'spellcheck')
          .warning('hunspell open failed: $error');
      return null;
    } finally {
      calloc
        ..free(aff)
        ..free(dic);
    }
  }

  final Pointer<Void> _handle;
  final int Function(Pointer<Void>, Pointer<Utf8>) _spell;
  final int Function(
    Pointer<Void>,
    Pointer<Pointer<Pointer<Utf8>>>,
    Pointer<Utf8>,
  )
  _suggest;
  final void Function(Pointer<Void>, Pointer<Pointer<Pointer<Utf8>>>, int)
  _freeList;
  final void Function(Pointer<Void>) _destroy;
  bool _disposed = false;

  @override
  bool get available => !_disposed;

  @override
  bool isCorrect(String word) {
    if (_disposed) return true;
    final ptr = word.toNativeUtf8();
    try {
      return _spell(_handle, ptr) != 0;
    } finally {
      calloc.free(ptr);
    }
  }

  @override
  List<String> suggest(String word) {
    if (_disposed) return const <String>[];
    final ptr = word.toNativeUtf8();
    final slst = calloc<Pointer<Pointer<Utf8>>>();
    try {
      final count = _suggest(_handle, slst, ptr);
      if (count <= 0) return const <String>[];
      final base = slst.value;
      final suggestions = <String>[
        for (var i = 0; i < count; i++) base[i].toDartString(),
      ];
      _freeList(_handle, slst, count);
      return suggestions;
    } finally {
      calloc
        ..free(ptr)
        ..free(slst);
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _destroy(_handle);
  }

  static DynamicLibrary? _openLibrary() {
    for (final name in _libraryNames) {
      try {
        return DynamicLibrary.open(name);
      } on Object {
        continue;
      }
    }
    return null;
  }
}

/// The best checker this machine can offer.
SpellChecker createSpellChecker() =>
    HunspellSpellChecker.open() ?? const NoopSpellChecker();
