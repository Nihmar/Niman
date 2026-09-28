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
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/spellcheck/windows_spell_checker.dart';
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

/// Every `<name>.aff`/`.dic` pair found in [dirs], keyed by dictionary name.
///
/// The first directory wins per name, so a per-user dictionary overrides a
/// system one with the same tag. Callers that only need one should use
/// [discoverDictionary].
Map<String, ({String aff, String dic})> discoverDictionaries({
  List<String>? dirs,
}) {
  final found = <String, ({String aff, String dic})>{};
  for (final dir in dirs ?? defaultDictionaryDirs()) {
    final directory = Directory(dir);
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync()) {
      if (entity is! File || !entity.path.endsWith('.aff')) continue;
      final name = p.basenameWithoutExtension(entity.path);
      if (found.containsKey(name)) continue;
      final dic = File(
        '${entity.path.substring(0, entity.path.length - 4)}.dic',
      );
      if (dic.existsSync()) found[name] = (aff: entity.path, dic: dic.path);
    }
  }
  return found;
}

/// The first usable dictionary pair for [locale] in [dirs].
///
/// Candidate names are the locale tag (`en_GB`), its hyphenated form, its
/// language alone (`en`), then the two defaults. When no candidate matches,
/// the first pair found wins, so an unusual locale still gets a dictionary
/// rather than nothing.
({String aff, String dic})? discoverDictionary({
  String? locale,
  List<String>? dirs,
}) {
  final found = discoverDictionaries(dirs: dirs);
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
    final pair = found[name];
    if (pair != null) return pair;
  }
  return found.isEmpty ? null : found.values.first;
}

/// The `xx_YY` tag of a locale like `en_GB.UTF-8`, or null for `C`.
String? _normalizeLocale(String locale) {
  final base = locale.split('.').first.replaceAll('-', '_');
  if (base.isEmpty || base == 'C' || base == 'POSIX') return null;
  return base;
}

/// One engine, opened but not yet wrapped: the library it will call into,
/// the handle `Hunspell_create` answered, and the dictionary it read.
typedef _Opened = ({
  DynamicLibrary lib,
  Pointer<Void> handle,
  String dictionary,
});

/// A handle on its way from the isolate that opened it to the one that will
/// use it (#453).
///
/// `Hunspell_create` parses the dictionary into memory and answers a handle
/// into it; a `Pointer` cannot cross an isolate, and the address can
/// ([HunspellSpellChecker.adopt]).
typedef HunspellHandle = ({int address, String dictionary, int ms});

/// [SpellChecker] over the system hunspell.
final class HunspellSpellChecker implements SpellChecker {
  new _({
    required this._handle,
    required this._spell,
    required this._suggest,
    required this._freeList,
    required this._destroy,
  });

  /// Wraps an opened handle with the library's own entry points.
  new _bind(_Opened opened)
    : this._(
        handle: opened.handle,
        spell: opened.lib
            .lookupFunction<
              Int32 Function(Pointer<Void>, Pointer<Utf8>),
              int Function(Pointer<Void>, Pointer<Utf8>)
            >('Hunspell_spell'),
        suggest: opened.lib
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
        freeList: opened.lib
            .lookupFunction<
              Void Function(
                Pointer<Void>,
                Pointer<Pointer<Pointer<Utf8>>>,
                Int32,
              ),
              void Function(Pointer<Void>, Pointer<Pointer<Pointer<Utf8>>>, int)
            >('Hunspell_free_list'),
        destroy: opened.lib
            .lookupFunction<
              Void Function(Pointer<Void>),
              void Function(Pointer<Void>)
            >('Hunspell_destroy'),
      );

  /// Opens the library and a dictionary, or null when either is missing.
  ///
  /// [dictionary] picks a named `<name>.aff`/`.dic` pair (the user's
  /// choice); when null or gone, the locale's dictionary is used. The
  /// other arguments are test seams; the defaults are the system ones.
  ///
  /// This is the whole load on the calling isolate — the dictionary's read
  /// and `Hunspell_create` over it, tens of milliseconds for a real
  /// dictionary (#453) — so callers that own a frame want
  /// [loadSpellCheckers] instead.
  static HunspellSpellChecker? open({
    DynamicLibrary? library,
    String? locale,
    List<String>? dirs,
    String? dictionary,
  }) {
    // Timed for #315: a launch opens these engines more than once, and the
    // frame that first asks for a verdict used to be where the dictionary's
    // own read of its `.aff`/`.dic` landed.
    final clock = Stopwatch()..start();
    final opened = _create(
      library: library,
      locale: locale,
      dirs: dirs,
      dictionary: dictionary,
    );
    if (opened == null) return null;
    final checker = HunspellSpellChecker._bind(opened);
    const AppLogger(name: 'spellcheck').info(
      'hunspell ready: ${opened.dictionary} in ${clock.elapsedMilliseconds} ms',
    );
    return checker;
  }

  /// Adopts a handle [openHunspellHandles] opened on another isolate (#453).
  ///
  /// The library is looked up again here, and `dart:ffi` resolves the same
  /// already-loaded one. The handle itself is the same too: its memory is the
  /// process heap, and the isolate that allocated it stopped touching it the
  /// moment it answered the address, so this isolate is the only one that
  /// calls into it from here on. A handle that cannot be wrapped — no
  /// library on this isolate, which the load would have failed on — is
  /// destroyed rather than leaked.
  static HunspellSpellChecker? adopt(HunspellHandle handle) {
    final lib = _openLibrary();
    if (lib == null) {
      destroyHunspellHandles(<HunspellHandle>[handle]);
      return null;
    }
    try {
      return HunspellSpellChecker._bind((
        lib: lib,
        handle: Pointer<Void>.fromAddress(handle.address),
        dictionary: handle.dictionary,
      ));
    } on Object catch (error) {
      const AppLogger(name: 'spellcheck')
          .warning('hunspell adopt failed: $error');
      destroyHunspellHandles(<HunspellHandle>[handle]);
      return null;
    }
  }

  /// The library and a live handle over a dictionary, or null when either is
  /// missing. The dictionary is parsed here; nothing is logged and nothing is
  /// wrapped, so a caller can hand the handle on ([loadSpellCheckers]).
  static _Opened? _create({
    DynamicLibrary? library,
    String? locale,
    List<String>? dirs,
    String? dictionary,
  }) {
    final lib = library ?? _openLibrary();
    if (lib == null) return null;
    final dict = dictionary == null
        ? discoverDictionary(locale: locale, dirs: dirs)
        : discoverDictionaries(dirs: dirs)[dictionary] ??
              discoverDictionary(locale: locale, dirs: dirs);
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
      return (lib: lib, handle: handle, dictionary: dict.dic);
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

/// Opens one engine per name in [dictionaries] — the locale's when the list
/// is empty — and answers their handles instead of wrappers (#453).
///
/// This is the load, and all of it: the directory scan, the library, and
/// libhunspell's own `Hunspell_create` over the `.aff`/`.dic` it found. It
/// runs on the isolate that calls it, and that isolate then stops touching
/// what it opened: the handles stay alive on the process heap with the
/// dictionary they parsed, for [HunspellSpellChecker.adopt] to wrap where
/// they are used. A name that opens nothing is skipped, as [createSpellChecker]
/// skips it; nothing opened answers an empty list, not an error.
///
/// Each handle carries how long its own load took, so the isolate that
/// adopts it — the one whose log a user can export — says the number.
List<HunspellHandle> openHunspellHandles({
  List<String> dictionaries = const <String>[],
}) {
  final names = <String?>[if (dictionaries.isEmpty) null else ...dictionaries];
  final handles = <HunspellHandle>[];
  for (final name in names) {
    final clock = Stopwatch()..start();
    final opened = HunspellSpellChecker._create(dictionary: name);
    if (opened == null) continue;
    handles.add((
      address: opened.handle.address,
      dictionary: opened.dictionary,
      ms: clock.elapsedMilliseconds,
    ));
  }
  return handles;
}

/// Destroys handles nobody adopted — a load whose dictionary choice was
/// replaced, or whose state was disposed, while it ran (#453).
void destroyHunspellHandles(List<HunspellHandle> handles) {
  if (handles.isEmpty) return;
  final lib = HunspellSpellChecker._openLibrary();
  if (lib == null) return;
  final destroy = lib
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('Hunspell_destroy');
  for (final handle in handles) {
    destroy(Pointer<Void>.fromAddress(handle.address));
  }
}

/// The engines [dictionaries] name, loaded off the isolate that owns the
/// frame wherever the engine's load is a dictionary's (#453).
///
/// A dictionary is megabytes of text and libhunspell parses it inside
/// `Hunspell_create`: the frame that first asks a note for its ranges is a
/// stall of tens of milliseconds, worst on the first open, and nothing about
/// the vocabulary — a word's verdict costs microseconds — explains it. So
/// the load runs on an [Isolate.run] of its own and only its handles come
/// back, and what the caller awaits is every bit of the load except the
/// native call itself, which is the point.
///
/// It is a plain [Isolate.run] rather than `IsolateGauge`: the load starts
/// in the state's constructor, which every widget test that mounts the shell
/// reaches, and the gauge's overdue timers would then be created inside the
/// test's fake clock and never cancelled — a pending timer in two hundred
/// tests. The cost that matters is the load, and the number it prints is
/// already in the log.
///
/// Nothing installed is not an error: the answer is [NoopSpellChecker]s, as
/// [createSpellChecker]'s is. Windows' own checker is the exception — a COM
/// object of the system's, asked for where it is used — and it is built on
/// the calling isolate as it always was.
Future<List<SpellChecker>> loadSpellCheckers(List<String> dictionaries) async {
  if (Platform.isWindows) return _checkersHere(dictionaries);
  final handles = await Isolate.run(
    () => openHunspellHandles(dictionaries: dictionaries),
  );
  final checkers = <SpellChecker>[];
  for (final handle in handles) {
    final checker = HunspellSpellChecker.adopt(handle);
    if (checker == null) continue;
    const AppLogger(name: 'spellcheck')
        .info('hunspell ready: ${handle.dictionary} in ${handle.ms} ms');
    checkers.add(checker);
  }
  return checkers.isEmpty ? const <SpellChecker>[NoopSpellChecker()] : checkers;
}

/// The engines built where they are asked for: the machine's own on Windows,
/// the no-op where nothing loads.
List<SpellChecker> _checkersHere(List<String> dictionaries) => <SpellChecker>[
  if (dictionaries.isEmpty) createSpellChecker(),
  for (final name in dictionaries) createSpellChecker(dictionary: name),
];

/// The best checker this machine can offer: on Windows the system's own,
/// then hunspell wherever it is installed.
///
/// [dictionary] names the user's chosen dictionary (null = the locale's).
/// This loads where it is called — see [loadSpellCheckers] for the path that
/// does not — and is what the seeds, the tests and the dictionary list use.
SpellChecker createSpellChecker({String? dictionary}) =>
    (Platform.isWindows
        ? WindowsSpellChecker.open(language: dictionary)
        : null) ??
    HunspellSpellChecker.open(dictionary: dictionary) ??
    const NoopSpellChecker();

/// The dictionaries the settings offer: the languages Windows spellchecks,
/// or every hunspell pair found on the machine.
List<String> availableSpellDictionaries() {
  final names = Platform.isWindows
      ? windowsSpellLanguages()
      : discoverDictionaries().keys.toList();
  return names..sort();
}
