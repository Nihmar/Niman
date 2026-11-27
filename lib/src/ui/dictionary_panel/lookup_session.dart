import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/dictionary/dictionary_entry_group.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';

/// Looks [selection] up in [language]: what the panel asks, and a test
/// answers.
typedef DictionaryLookUp = Future<DictionaryResult> Function(
  String selection,
  String language,
);

/// One look-up of the panel and the ones before it, which *Back* returns to.
///
/// The panel is one object for as long as it is open: the selection first,
/// then every nearby entry a reader follows, each a look-up in the same
/// language and a step back. Changing the language looks the same text up
/// again. A look-up that is overtaken by another is dropped when it
/// answers.
final class DictionaryLookupSession extends ChangeNotifier {
  /// A session that looks up through `lookUp`, starting on `selection` in
  /// `language`. `progress` reports how far a pack's index is built, which
  /// the first look-up in a big pack waits for; [onLanguage] hears the
  /// language the reader chose.
  new({
    required this._lookUp,
    required this._selection,
    required this._language,
    this._progress,
    this.onLanguage,
  }) {
    unawaited(_run());
  }

  static const AppLogger _log = AppLogger(name: 'dictionary');

  final DictionaryLookUp _lookUp;
  final Stream<IndexProgress>? _progress;
  final List<({String selection, String language})> _trail = [];
  StreamSubscription<IndexProgress>? _following;
  String _selection;
  String _language;
  DictionaryResult? _result;
  double? _indexed;
  int _serial = 0;
  bool _disposed = false;

  /// Told the language the reader chose, to keep it for the file. Set anew
  /// when the panel is chosen again on another surface.
  ValueChanged<String>? onLanguage;

  /// What is being looked up: the selection, or the entry followed.
  String get selection => _selection;

  /// The language it is looked up in.
  String get language => _language;

  /// How the look-up ended, or null while it is going.
  DictionaryResult? get result => _result;

  /// Whether the answer is awaited.
  bool get loading => _result == null;

  /// How far the index the look-up waits for is built, 0 to 1; null when it
  /// waits for none.
  double? get indexed => _indexed;

  /// The entries of the answer, an entry per lemma, the same spelling in
  /// two scripts as one.
  List<DictionaryEntryGroup> get groups =>
      DictionaryEntryGroup.of(_result?.entries ?? const []);

  /// Whether there is an earlier look-up to return to.
  bool get canGoBack => _trail.isNotEmpty;

  /// Starts over on [selection] in [language]: the selection of a surface,
  /// chosen again while the panel is open. What was followed is forgotten.
  Future<void> restart(String selection, String language) {
    _trail.clear();
    _selection = selection;
    _language = language;
    return _run();
  }

  /// Looks up [word], an entry of the answer or a suggestion, in the same
  /// language; *Back* returns to the look-up it left.
  Future<void> follow(String word) {
    _trail.add((selection: _selection, language: _language));
    _selection = word;
    return _run();
  }

  /// Returns to the look-up before this one.
  Future<void> back() {
    if (_trail.isEmpty) return Future<void>.value();
    final before = _trail.removeLast();
    _selection = before.selection;
    _language = before.language;
    return _run();
  }

  /// Looks the same text up in [language]: the reader's choice, which is
  /// reported to [onLanguage].
  Future<void> changeLanguage(String language) {
    if (language == _language) return Future<void>.value();
    _language = language;
    onLanguage?.call(language);
    return _run();
  }

  /// Looks the same text up again: a dictionary was downloaded since.
  Future<void> refresh() => _run();

  Future<void> _run() async {
    final serial = ++_serial;
    _result = null;
    _indexed = null;
    notifyListeners();
    await _following?.cancel();
    _following = _progress?.listen((report) {
      if (serial != _serial) return;
      _indexed = report.fraction;
      notifyListeners();
    });
    final selection = _selection;
    final language = _language;
    DictionaryResult result;
    try {
      result = await _lookUp(selection, language);
    } on Object catch (error) {
      // The service does not throw for a pack; a folder that cannot be
      // read at all does, and the panel says so rather than stay blank.
      _log.warning('look-up of "$selection" failed: $error');
      result = DictionaryResult(
        outcome: DictionaryOutcome.unavailable,
        selection: selection,
        language: language,
        reason: '$error',
      );
    }
    if (_disposed || serial != _serial) return;
    await _following?.cancel();
    _following = null;
    _result = result;
    _indexed = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_following?.cancel());
    super.dispose();
  }
}
