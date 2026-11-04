import 'package:flutter/widgets.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// Replace mode of the Search screen (T-M3-10): the panel under the query
/// box and the match preview replace the results list while [active].
///
/// It owns the mode's state — the replacement text, the case toggle, the
/// one-note scope and the preview — and the runs over the replace source;
/// the screen draws it and rebuilds when it notifies.
final class SearchReplaceFlow extends ChangeNotifier {
  /// Creates the flow over the screen's query [term].
  ///
  /// [replaceSource] is the screen's override (widget tests inject a fake)
  /// and [session] the library it resolves the source from otherwise;
  /// [unsavedTracker] the open notes' unsaved edits; [snack] shows a
  /// message; [onReplaced] is told the term a run rewrote.
  new({
    required this.term,
    required this.replaceSource,
    required this.session,
    required this.unsavedTracker,
    required this.snack,
    required this.onReplaced,
  }) {
    replacement.addListener(_onReplacementChanged);
  }

  /// The term being replaced: the query box's text, trimmed.
  final String Function() term;

  /// The replace-source override, or null to resolve it from [session].
  final ReplaceSource? Function() replaceSource;

  /// The open library session.
  final LibrarySession Function() session;

  /// The open notes' unsaved edits, or null to run the replace alone.
  final UnsavedTracker? Function() unsavedTracker;

  /// Shows a message to the reader.
  final void Function(String message) snack;

  /// Called after a run rewrote the notes for the term given.
  final void Function(String term) onReplaced;

  /// The replacement text's field.
  final TextEditingController replacement = TextEditingController();

  bool _active = false;
  bool _caseSensitive = false;
  String? _onlyPath;
  bool _busy = false;
  List<ReplaceMatchNote> _preview = const [];
  bool _disposed = false;

  /// Whether replace mode is on.
  bool get active => _active;

  /// Whether the replace matches case.
  bool get caseSensitive => _caseSensitive;

  /// The one note the replace is limited to, or null for every match.
  String? get onlyPath => _onlyPath;

  /// Whether a scan or the replace itself is running.
  bool get busy => _busy;

  /// The notes the last scan found matches in.
  List<ReplaceMatchNote> get preview => _preview;

  void _onReplacementChanged() {
    // The preview samples re-render with the new replacement text.
    if (_active && !_disposed) notifyListeners();
  }

  /// Enters replace mode: the inline panel under the query box plus the
  /// match preview replace the results list until confirmed or closed.
  Future<void> enter({String? onlyPath}) async {
    final source = await _acquire();
    if (_disposed) return;
    if (source == null) {
      snack(AppStrings.replaceUnavailable);
      return;
    }
    _active = true;
    _onlyPath = onlyPath;
    _caseSensitive = false;
    replacement.clear();
    _preview = const [];
    _busy = true;
    notifyListeners();
    await refresh();
  }

  /// Leaves replace mode and restores the results list.
  void leave() {
    if (!_active) return;
    _active = false;
    _onlyPath = null;
    _preview = const [];
    _busy = false;
    notifyListeners();
  }

  /// Sets the case toggle to [value] and scans again.
  Future<void> setCaseSensitive({required bool value}) async {
    _caseSensitive = value;
    notifyListeners();
    await refresh();
  }

  /// (Re)scans the candidate notes for whole-word matches and fills the
  /// preview list.
  Future<void> refresh() async {
    if (!_active) return;
    final source = await _acquire();
    if (_disposed || !_active || source == null) return;
    final term = this.term();
    final caseSensitive = _caseSensitive;
    final only = _onlyPath;
    _busy = true;
    notifyListeners();
    final List<ReplaceMatchNote> notes;
    try {
      notes = await source.previewMatches(
        term,
        caseSensitive: caseSensitive,
        onlyPath: only,
      );
    } on Object catch (e) {
      // A failed scan must not leave the panel spinning over an empty list:
      // clear the busy flag and show the empty preview.
      if (!_disposed && _active) {
        _busy = false;
        notifyListeners();
      }
      const AppLogger(name: 'search.ui').warning('replace preview failed: $e');
      return;
    }
    if (_disposed || !_active) return;
    if (term != this.term() ||
        caseSensitive != _caseSensitive ||
        only != _onlyPath) {
      return; // The mode moved on; a newer scan owns the preview.
    }
    _preview = notes;
    _busy = false;
    notifyListeners();
  }

  /// Runs the confirmed replace, reports it, and leaves replace mode.
  Future<void> run() async {
    final source = await _acquire();
    if (_disposed || source == null) return;
    final term = this.term();
    final only = _onlyPath;
    _busy = true;
    notifyListeners();
    // The notes open with edits the disk does not have are saved first: the
    // run rewrites the files, and an editor that still held the old words
    // would save them over the replacement (#1042). A save that fails stops
    // the run before it touches anything.
    final tracker = unsavedTracker();
    if (tracker != null) {
      try {
        await tracker.saveAll();
      } on Object catch (error) {
        const AppLogger(name: 'search.ui').warning('replace aborted: $error');
        if (_disposed) return;
        _busy = false;
        notifyListeners();
        snack(AppStrings.noteSaveFailedSnack);
        return;
      }
      if (_disposed) return;
    }
    final report = await source.replaceAll(
      term: term,
      replacement: replacement.text,
      caseSensitive: _caseSensitive,
      only: only == null ? null : {only},
    );
    // The open notes the run rewrote adopt their new text (they were saved
    // before it ran, so none of them holds anything the file does not).
    tracker?.notifyDiskChanged(const {});
    if (_disposed) return;
    // A run that wrote nothing because it could not is not a "no match":
    // the failed notes make the run report itself instead.
    final failed = report.failed;
    final message = report.occurrences == 0 && failed.isEmpty
        ? AppStrings.replaceNoMatch(term)
        : AppStrings.replaceDone(report.occurrences, term, report.notesChanged);
    final skipped = report.skipped.isEmpty
        ? ''
        : AppStrings.replaceSkipped(report.skipped.length);
    final failures = failed.isEmpty
        ? ''
        : AppStrings.replaceWriteFailed(failed.length);
    snack('$message$skipped$failures');
    leave();
    onReplaced(term);
  }

  /// Resolves the replace source (seam first, then the session).
  Future<ReplaceSource?> _acquire() async {
    final own = replaceSource();
    if (own != null) return own;
    try {
      return await session().replaceSource;
    } on Object catch (e) {
      const AppLogger(name: 'search.ui')
          .warning('replace source unavailable: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    replacement
      ..removeListener(_onReplacementChanged)
      ..dispose();
    super.dispose();
  }
}
