import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/search/query.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree.dart' show displayNameOf;

/// The Search tab/screen (T-M3-05/T-M3-08 toggle, T-M3-10 replace).
///
/// Query box (debounced ~150 ms) with the Words/Contains mode toggle over
/// ranked FTS results — path + snippet with `<mark>` highlighting, paged
/// (50 at a time, "Show more") — and click-to-open. Results of a superseded
/// query are dropped by the source's invocation id; an empty (or too
/// short) query shows a hint instead of results.
///
/// Words mode also offers the optional Replace action: an exact
/// whole-word replace of the query term across every matching note (or, by
/// long-press, in one result's note). Contains mode never replaces. In
/// replace mode an inline panel appears under the query box with the
/// replacement text and a live per-note preview of the matches; the
/// confirm button rewrites the notes.
final class SearchScreen extends StatefulWidget {
  /// Creates the search screen.
  const new({
    required this.controller,
    required this.onOpenNote,
    this.onOpenTags,
    this.source,
    this.replaceSource,
    this.fieldSource,
    super.key,
  });

  /// The open library session (for the search source).
  final LibrarySession controller;

  /// Called with the note's library-relative path when a result is tapped.
  final void Function(String path) onOpenNote;

  /// Opens the Tags screen (shell-provided; the tags button shows only
  /// when set).
  final VoidCallback? onOpenTags;

  /// Optional source override (widget tests inject a fake); when null the
  /// screen resolves it from [controller].
  final SearchSource? source;

  /// Optional replace-source override (widget tests inject a fake); when
  /// null the screen resolves it from [controller].
  final ReplaceSource? replaceSource;

  /// Optional frontmatter-field source override (widget tests inject a
  /// fake); when null the screen resolves it from [controller].
  final FieldSource? fieldSource;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

final class _SearchScreenState extends State<SearchScreen> {
  static const int _pageSize = 50;
  static const Duration _debounce = Duration(milliseconds: 150);

  final TextEditingController _query = TextEditingController();

  /// Replace mode (T-M3-10): the panel under the query box and the match
  /// preview replace the results list while active.
  final TextEditingController _replacement = TextEditingController();
  bool _replaceMode = false;
  bool _replaceCase = false;
  String? _replaceOnly;
  bool _previewBusy = false;
  List<ReplaceMatchNote> _replacePreview = const [];

  SearchSource? _source;
  FieldSource? _fields;
  Timer? _debounceTimer;
  Timer? _replaceRefresh;
  bool _contains = false;
  bool _searched = false;
  List<SearchHit> _hits = const [];
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    // Timed because entering this tab is reported as stuttering, and the
    // two suspects leave different traces: acquiring the source (the
    // background isolate and a second SQLite connection) shows up here as
    // milliseconds, while the cost of building and painting the screen
    // shows up as slow frames after a mount that took no time at all.
    final started = DateTime.now();
    _query.addListener(_onQueryChanged);
    _replacement.addListener(_onReplacementChanged);
    if (widget.source == null) unawaited(_loadSource(since: started));
    const AppLogger(name: 'search.ui')
        .debug('mount: ${DateTime.now().difference(started).inMilliseconds}ms');
  }

  @override
  void dispose() {
    const AppLogger(name: 'search.ui').debug('dispose');
    _debounceTimer?.cancel();
    _replaceRefresh?.cancel();
    _query.removeListener(_onQueryChanged);
    _replacement.removeListener(_onReplacementChanged);
    _query.dispose();
    _replacement.dispose();
    super.dispose();
  }

  /// Resolves the search source once; a failed load leaves [_source] null
  /// and [_runSearch] retries on the next query — a transient startup
  /// failure must not wedge the box into issuing queries that go nowhere.
  Future<void> _loadSource({DateTime? since}) async {
    final source = await _acquireSource();
    if (since != null) {
      // Near zero means the session had it already (the shell warms it
      // after a library opens); anything larger is this tab paying for
      // the background connection on the frame that animates it in.
      const AppLogger(name: 'search.ui').info(
        'source ready ${DateTime.now().difference(since).inMilliseconds}ms '
        'after mount',
      );
    }
    // Applied straight away, even mid-fade. An earlier round deferred the
    // apply 200 ms so the fade would finish first; the frame log proved
    // the rebuild it guarded costs nothing (0 ms build, a few ms to the
    // first frame) while the wait was itself the whole perceived lag of
    // the first search visit, so the defer went.
    if (!mounted || source == null) return;
    setState(() => _source = source);
    if (since != null) {
      const AppLogger(name: 'search.ui').debug(
        'source applied ${DateTime.now().difference(since).inMilliseconds}ms '
        'after mount',
      );
    }
    logNextFrame('search.ui', 'source applied first frame');
    if (_query.text.trim().isNotEmpty) unawaited(_runSearch());
  }

  /// The frontmatter-field source, resolved on first use.
  ///
  /// Unlike the search source it needs no warming: it runs on the UI
  /// connection, and a `key = value` filter is an indexed lookup, not a
  /// MATCH over every body in the library.
  Future<FieldSource?> _acquireFields() async {
    final own = widget.fieldSource;
    if (own != null) return own;
    final cached = _fields;
    if (cached != null) return cached;
    try {
      return _fields = await widget.controller.fieldSource;
    } on Object catch (e) {
      const AppLogger(name: 'search.ui').warning('field source failed: $e');
      return null;
    }
  }

  Future<SearchSource?> _acquireSource() async {
    final own = widget.source;
    if (own != null) return own;
    final cached = _source;
    if (cached != null) return cached;
    try {
      return await widget.controller.searchSource;
    } on Object catch (e) {
      // The session owns one cached background connection, so a failure
      // here is a real (rare) startup problem; the next query retries.
      const AppLogger(name: 'search.ui')
          .warning('search source unavailable: $e');
      return null;
    }
  }

  void _onQueryChanged() {
    _debounceTimer?.cancel();
    final text = _query.text.trim();
    if (text.isEmpty || !_canSearch(text)) {
      // Nothing will be (re)searched: clear the results and supersede any
      // in-flight query, so its results cannot land on the hint state.
      _source?.begin();
      setState(() {
        _searched = false;
        _hits = const [];
        _shown = 0;
      });
      return;
    }
    // Editing the term invalidates the replace preview: leave the mode.
    _leaveReplaceMode();
    const AppLogger(name: 'search.ui')
        .debug('debouncing "$text" (${_debounce.inMilliseconds}ms)');
    _debounceTimer = Timer(_debounce, () => unawaited(_runSearch()));
  }

  void _onReplacementChanged() {
    // The preview samples re-render with the new replacement text.
    if (_replaceMode && mounted) setState(() {});
  }

  void _setContains(bool value) {
    if (_contains == value) return;
    _leaveReplaceMode();
    setState(() => _contains = value);
    final text = _query.text.trim();
    if (text.isEmpty) return;
    if (!_canSearch(text)) {
      _source?.begin();
      setState(() {
        _searched = false;
        _hits = const [];
        _shown = 0;
      });
      return;
    }
    unawaited(_runSearch());
  }

  void _clearQuery() {
    _query.clear();
    setState(() {
      _searched = false;
      _hits = const [];
      _shown = 0;
    });
  }

  Future<void> _runSearch() async {
    final text = _query.text.trim();
    if (text.isEmpty || !_canSearch(text)) return;
    var source = _source;
    if (source == null) {
      source = await _acquireSource();
      if (source == null || !mounted) return;
      setState(() => _source = source);
    }
    final id = source.begin();
    final contains = _contains;
    final field = _fieldFilter(text);
    final mode = field != null
        ? 'field'
        : contains
        ? 'contains'
        : 'words';
    const AppLogger(name: 'search.ui').debug('issue id $id ($mode) "$text"');
    final clock = Stopwatch()..start();
    // The field filter borrows the search source's invocation id: the two
    // are driven by the same box, so a text query typed over a filter (or
    // the other way round) still supersedes what came before it.
    final results = field != null
        ? await _runFieldFilter(field)
        : contains
        ? await source.searchContains(text, id: id)
        : await source.search(buildFtsQuery(text), id: id);
    if (!source.isCurrent(id)) return; // a newer query superseded this one
    if (!mounted) return;
    // The repo already logs the SQL time; this is issue → results landed,
    // i.e. what a keystroke waits for on the UI side (debounce included
    // in the gap back to the 'debouncing' line).
    const AppLogger(name: 'search.ui').debug(
      'id $id landed in ${clock.elapsedMilliseconds}ms '
      '(${results.length} hits)',
    );
    setState(() {
      _searched = true;
      _hits = results;
      _shown = _pageSize < results.length ? _pageSize : results.length;
    });
    logNextFrame('search.ui', 'results first frame (id $id)');
  }

  /// The `key = value` filter [text] asks for, or null when it is a text
  /// search.
  ///
  /// Only in Words mode: Contains is a literal scan of the note bodies,
  /// and someone who typed `x = y` there meant to find that string.
  ({String key, String value})? _fieldFilter(String text) =>
      _contains ? null : fieldQuery(text);

  /// Whether the box currently holds a `key = value` filter.
  bool get _inFieldMode => _fieldFilter(_query.text.trim()) != null;

  /// Runs a `key = value` filter and shapes its notes like search hits, so
  /// the results list stays one list. There is no snippet: the match is
  /// the field, not a place in the text.
  Future<List<SearchHit>> _runFieldFilter(
    ({String key, String value}) f,
  ) async {
    final fields = await _acquireFields();
    if (fields == null) return const [];
    final notes = await fields.notesWithField(f.key, f.value);
    return [
      for (final note in notes)
        SearchHit(
          noteId: note.id,
          path: note.path,
          title: displayNameOf(note),
          snippet: '',
        ),
    ];
  }

  void _loadMore() {
    setState(() {
      final next = _shown + _pageSize;
      _shown = next < _hits.length ? next : _hits.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final started = DateTime.now();
    final theme = Theme.of(context);
    final child = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            children: [
              TextField(
                key: const Key('search-query'),
                controller: _query,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint,
                  // The icon says which of the two the box is doing, so a
                  // filter that matched is visible before the results are.
                  prefixIcon: Icon(
                    _inFieldMode ? Icons.filter_alt_outlined : Icons.search,
                  ),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('search-clear'),
                          icon: const Icon(Icons.close),
                          onPressed: _clearQuery,
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SegmentedButton<bool>(
                    key: const Key('search-mode'),
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(AppStrings.searchModeWords),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(AppStrings.searchModeContains),
                      ),
                    ],
                    selected: {_contains},
                    onSelectionChanged: (selection) =>
                        _setContains(selection.single),
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Spacer(),
                  // Replace rewrites the query term inside the notes; a
                  // filter has no term, so it has nothing to offer.
                  if (!_contains && !_inFieldMode && _hits.isNotEmpty)
                    IconButton(
                      key: const Key('search-replace'),
                      tooltip: AppStrings.replaceTooltip,
                      icon: const Icon(Icons.find_replace),
                      onPressed: _openReplaceAll,
                    ),
                  if (widget.onOpenTags != null)
                    IconButton(
                      key: const Key('open-tags'),
                      tooltip: AppStrings.openTagsTooltip,
                      icon: const Icon(Icons.sell_outlined),
                      onPressed: widget.onOpenTags,
                    ),
                ],
              ),
              if (_replaceMode) _replacePanel(theme),
            ],
          ),
        ),
        Expanded(
          child: _replaceMode ? _replacePreviewList(theme) : _results(theme),
        ),
      ],
    );
    const AppLogger(name: 'search.ui')
        .debug('build: ${DateTime.now().difference(started).inMilliseconds}ms');
    return child;
  }

  Widget _results(ThemeData theme) {
    if (!_searched) return _hint(theme);
    if (_hits.isEmpty) {
      return Center(
        child: Text(
          AppStrings.searchNoMatches,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      key: const Key('search-results'),
      itemCount: _shown + (_shown < _hits.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _shown) {
          return ListTile(
            key: const Key('search-load-more'),
            leading: const Icon(Icons.expand_more),
            title: Text(AppStrings.searchLoadMore),
            onTap: _loadMore,
          );
        }
        final hit = _hits[index];
        return ListTile(
          key: Key('search-hit-${hit.path}'),
          title: Text(hit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hit.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (hit.snippet.isNotEmpty)
                Text.rich(
                  _highlight(theme, hit.snippet),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          onTap: () => widget.onOpenNote(hit.path),
          onLongPress: () => _showNoteActions(hit),
        );
      },
    );
  }

  /// The result-row long-press menu (T-M3-10): the single-note replace.
  Future<void> _showNoteActions(SearchHit hit) async {
    if (!mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const Key('replace-note-action'),
              leading: const Icon(Icons.find_replace),
              title: Text(AppStrings.replaceInNoteAction),
              onTap: () => Navigator.pop(context, 'replace'),
            ),
          ],
        ),
      ),
    );
    if (action == 'replace' && mounted) {
      await _enterReplaceMode(onlyPath: hit.path);
    }
  }

  /// The header Replace action: replace across every matching note.
  Future<void> _openReplaceAll() => _enterReplaceMode();

  /// Enters replace mode: the inline panel under the query box plus the
  /// match preview replace the results list until confirmed or closed.
  Future<void> _enterReplaceMode({String? onlyPath}) async {
    final source = await _acquireReplace();
    if (!mounted) return;
    if (source == null) {
      _snack(AppStrings.replaceUnavailable);
      return;
    }
    setState(() {
      _replaceMode = true;
      _replaceOnly = onlyPath;
      _replaceCase = false;
      _replacement.clear();
      _replacePreview = const [];
      _previewBusy = true;
    });
    await _refreshPreview();
  }

  /// Leaves replace mode and restores the results list.
  void _leaveReplaceMode() {
    if (!_replaceMode) return;
    setState(() {
      _replaceMode = false;
      _replaceOnly = null;
      _replacePreview = const [];
      _previewBusy = false;
    });
  }

  /// (Re)scans the candidate notes for whole-word matches and fills the
  /// preview list.
  Future<void> _refreshPreview() async {
    if (!_replaceMode) return;
    final source = await _acquireReplace();
    if (!mounted || !_replaceMode || source == null) return;
    final term = _query.text.trim();
    final caseSensitive = _replaceCase;
    final only = _replaceOnly;
    setState(() => _previewBusy = true);
    final notes = await source.previewMatches(
      term,
      caseSensitive: caseSensitive,
      onlyPath: only,
    );
    if (!mounted || !_replaceMode) return;
    if (term != _query.text.trim() ||
        caseSensitive != _replaceCase ||
        only != _replaceOnly) {
      return; // The mode moved on; a newer scan owns the preview.
    }
    setState(() {
      _replacePreview = notes;
      _previewBusy = false;
    });
  }

  /// Runs the confirmed replace, reports it, and leaves replace mode.
  Future<void> _runReplace() async {
    final source = await _acquireReplace();
    if (!mounted || source == null) return;
    final term = _query.text.trim();
    final only = _replaceOnly;
    setState(() => _previewBusy = true);
    final report = await source.replaceAll(
      term: term,
      replacement: _replacement.text,
      caseSensitive: _replaceCase,
      only: only == null ? null : {only},
    );
    if (!mounted) return;
    final message = report.occurrences == 0
        ? AppStrings.replaceNoMatch(term)
        : AppStrings.replaceDone(report.occurrences, term, report.notesChanged);
    _snack(
      report.skipped.isEmpty
          ? message
          : '$message${AppStrings.replaceSkipped(report.skipped.length)}',
    );
    _leaveReplaceMode();
    // The watcher re-indexes the rewritten files: once it has, re-run the
    // query so the results reflect the new content.
    _replaceRefresh?.cancel();
    _replaceRefresh = Timer(const Duration(milliseconds: 900), () {
      if (mounted && _query.text.trim() == term && !_contains) {
        unawaited(_runSearch());
      }
    });
  }

  /// Resolves the replace source (seam first, then the session).
  Future<ReplaceSource?> _acquireReplace() async {
    final own = widget.replaceSource;
    if (own != null) return own;
    try {
      return await widget.controller.replaceSource;
    } on Object catch (e) {
      const AppLogger(name: 'search.ui')
          .warning('replace source unavailable: $e');
      return null;
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// The inline replace panel under the query box: replacement text, the
  /// case toggle, the scope/occurrence summary, and the confirm action.
  Widget _replacePanel(ThemeData theme) {
    final only = _replaceOnly;
    final term = _query.text.trim();
    final notes = _replacePreview;
    final occurrences = notes.fold<int>(
      0,
      (sum, note) => sum + note.occurrences,
    );
    final hasMatches = notes.isNotEmpty;
    final noteCount = notes.length;
    final String scope;
    if (only != null) {
      scope = 'in $only';
    } else if (noteCount == 0) {
      scope = 'whole library';
    } else {
      scope = 'in $noteCount note${noteCount == 1 ? '' : 's'}';
    }
    final confirmLabel = only != null
        ? AppStrings.replaceInThisNote
        : '${AppStrings.replaceConfirm} '
              '(${hasMatches ? '$occurrences' : '…'})';
    return Container(
      key: const Key('replace-panel'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.find_replace,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('replace-with'),
                  controller: _replacement,
                  decoration: InputDecoration(
                    labelText: AppStrings.replaceWithLabel,
                    hintText: term,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                key: const Key('replace-close'),
                tooltip: AppStrings.replaceCancel,
                icon: const Icon(Icons.close),
                onPressed: _leaveReplaceMode,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                AppStrings.replaceCaseSensitive,
                style: theme.textTheme.bodySmall,
              ),
              Switch(
                key: const Key('replace-case'),
                value: _replaceCase,
                onChanged: (value) async {
                  setState(() => _replaceCase = value);
                  await _refreshPreview();
                },
              ),
              const Spacer(),
              if (_previewBusy)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              FilledButton(
                key: const Key('replace-confirm'),
                onPressed: _previewBusy || !hasMatches ? null : _runReplace,
                child: Text(confirmLabel),
              ),
            ],
          ),
          Text(
            '$scope — ${AppStrings.replaceWholeWordsHint}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// The preview list shown in replace mode: one row per matching note
  /// with its occurrence count and the before → after samples.
  Widget _replacePreviewList(ThemeData theme) {
    if (_previewBusy && _replacePreview.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final notes = _replacePreview;
    if (notes.isEmpty) {
      return Center(
        child: Text(
          AppStrings.replacePreviewEmpty(_query.text.trim(), _replaceOnly),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      key: const Key('replace-preview'),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          key: Key('replace-note-${note.path}'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '${note.occurrences} '
                    'occurrence${note.occurrences == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              for (final sample in note.samples) _samplePreview(theme, sample),
            ],
          ),
        );
      },
    );
  }

  /// One sample's before → after lines: the context with the matched term
  /// highlighted, then the same context with the replacement text.
  Widget _samplePreview(ThemeData theme, ReplaceSample sample) {
    final body = theme.textTheme.bodySmall ?? const TextStyle();
    final matchStyle = body.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    TextSpan context(String matchText) => TextSpan(
      style: body,
      children: [
        TextSpan(text: sample.before),
        TextSpan(text: matchText, style: matchStyle),
        TextSpan(text: sample.after),
      ],
    );
    final replacement = _replacement.text;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            context(sample.match),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '→ ', style: matchStyle),
                context(replacement.isEmpty ? ' ' : replacement),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// The pre-search hint: the empty state, the too-short state (the box
  /// holds text that cannot be searched yet), or nothing while a runnable
  /// query waits out the debounce.
  Widget _hint(ThemeData theme) {
    final text = _query.text.trim();
    final String message;
    if (text.isEmpty) {
      message = AppStrings.searchEmptyHint;
    } else if (!_canSearch(text)) {
      message = AppStrings.searchTooShortHint;
    } else {
      return const SizedBox.shrink();
    }
    // Padded and centered, and width-capped: a bare Text under a Center
    // still takes the full width, so the hint wrapped ragged-right against
    // both screen edges (device report, 2026-09-11). The cap keeps the two
    // lines a readable measure instead of one edge-to-edge line on a wide
    // window.
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// Whether [text] is a search worth running. A one-character FTS prefix
  /// (words mode) expands to every term starting with that letter — a
  /// multi-second MATCH on a real library, with every query typed after it
  /// queueing behind it (T-M3-09 device report: `"e"*`/`"p"*` took 9–18 s
  /// and the follow-up queries "returned nothing"). Two characters is the
  /// floor for both modes; in words mode the last (growing) token must be
  /// two characters too, whatever came before it.
  bool _canSearch(String text) {
    if (text.length < 2) return false;
    // A `key = value` filter is an indexed lookup, so the prefix-expansion
    // problem the floor exists for does not apply: `x = 1` runs.
    if (_fieldFilter(text) != null) return true;
    if (_contains) return true;
    final last = text.split(RegExp(r'\s+')).last;
    return last.length >= 2;
  }

  /// Renders a `snippet()`/excerpt string: `<mark>…</mark>` spans get the
  /// accent color + bold, everything else is plain body text.
  TextSpan _highlight(ThemeData theme, String snippet) {
    final style = theme.textTheme.bodyMedium ?? const TextStyle();
    final markStyle = style.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    final spans = <TextSpan>[];
    var pos = 0;
    const open = '<mark>';
    const close = '</mark>';
    while (pos < snippet.length) {
      final start = snippet.indexOf(open, pos);
      if (start < 0) {
        spans.add(TextSpan(text: snippet.substring(pos), style: style));
        break;
      }
      if (start > pos) {
        spans.add(TextSpan(text: snippet.substring(pos, start), style: style));
      }
      final end = snippet.indexOf(close, start + open.length);
      if (end < 0) {
        spans.add(
          TextSpan(
            text: snippet.substring(start + open.length),
            style: markStyle,
          ),
        );
        break;
      }
      spans.add(
        TextSpan(
          text: snippet.substring(start + open.length, end),
          style: markStyle,
        ),
      );
      pos = end + close.length;
    }
    return TextSpan(children: spans);
  }
}
