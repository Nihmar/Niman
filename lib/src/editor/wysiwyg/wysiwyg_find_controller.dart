import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Find & replace over the WYSIWYG document (T-WYS-08).
///
/// Quill has no find controller: this walks [quill.Document.search] for the
/// match offsets, keeps the current match selected, and replaces through the
/// normal undoable [quill.QuillController.replaceText] path. The panel edits
/// [findInput] and [replaceInput]; this holds the state and the actions.
final class WysiwygFindController extends ChangeNotifier {
  /// Creates the controller over the open document.
  new(this._controller) {
    _changes = _controller.changes.listen((_) => _onDocumentChanged());
  }

  final quill.QuillController _controller;
  late final StreamSubscription<quill.DocChange> _changes;

  /// The query the panel edits.
  final TextEditingController findInput = TextEditingController();

  /// The replacement the panel edits.
  final TextEditingController replaceInput = TextEditingController();

  bool _visible = false;
  bool _replaceMode = false;
  bool _caseSensitive = false;
  List<int> _matches = const <int>[];
  int _index = -1;

  /// Whether the bar is open.
  bool get visible => _visible;

  /// Whether the bar shows its replace row.
  bool get replaceMode => _replaceMode;

  /// Whether the query is matched case-sensitively.
  bool get caseSensitive => _caseSensitive;

  /// How many matches the query has.
  int get matchCount => _matches.length;

  /// The 0-based index of the selected match, or -1.
  int get matchIndex => _index;

  String get _query => findInput.text;

  /// Opens the bar and searches the current query.
  void open({bool replace = false}) {
    _visible = true;
    _replaceMode = replace;
    _search();
    notifyListeners();
  }

  /// Closes the bar and drops the matches.
  void close() {
    _visible = false;
    _replaceMode = false;
    _matches = const <int>[];
    _index = -1;
    notifyListeners();
  }

  /// Flips the replace row.
  void toggleMode() {
    _replaceMode = !_replaceMode;
    notifyListeners();
  }

  /// Flips case sensitivity and re-searches.
  void toggleCaseSensitive() {
    _caseSensitive = !_caseSensitive;
    _search();
    notifyListeners();
  }

  /// Re-runs the search (the query field changed).
  void search() {
    _search();
    notifyListeners();
  }

  /// Selects the next match, wrapping around.
  void nextMatch() {
    if (_matches.isEmpty) return;
    _index = (_index + 1) % _matches.length;
    _select();
    notifyListeners();
  }

  /// Selects the previous match, wrapping around.
  void previousMatch() {
    if (_matches.isEmpty) return;
    _index = (_index - 1 + _matches.length) % _matches.length;
    _select();
    notifyListeners();
  }

  /// Replaces the selected match and re-searches.
  void replaceMatch() {
    if (_index < 0 || _index >= _matches.length) return;
    final offset = _matches[_index];
    final replacement = replaceInput.text;
    _controller.replaceText(
      offset,
      _query.length,
      replacement,
      TextSelection.collapsed(offset: offset + replacement.length),
    );
    _search();
    notifyListeners();
  }

  /// Replaces every match, from the end so the offsets keep.
  void replaceAllMatches() {
    if (_matches.isEmpty) return;
    final replacement = replaceInput.text;
    final length = _query.length;
    for (final offset in _matches.reversed) {
      _controller.replaceText(offset, length, replacement, null);
    }
    _search();
    notifyListeners();
  }

  void _search() {
    final query = _query;
    if (query.isEmpty) {
      _matches = const <int>[];
      _index = -1;
      return;
    }
    _matches = _controller.document.search(
      query,
      caseSensitive: _caseSensitive,
    );
    _index = _matches.isEmpty ? -1 : 0;
    _select();
  }

  void _select() {
    if (_index < 0 || _index >= _matches.length) return;
    final offset = _matches[_index];
    _controller.updateSelection(
      TextSelection(baseOffset: offset, extentOffset: offset + _query.length),
      quill.ChangeSource.local,
    );
  }

  void _onDocumentChanged() {
    if (!_visible) return;
    _search();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    findInput.dispose();
    replaceInput.dispose();
    super.dispose();
  }
}
