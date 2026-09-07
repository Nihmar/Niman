import 'dart:async';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/search/query.dart';
import 'package:copist/src/search/replace.dart';
import 'package:copist/src/search/search_repo.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

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
/// long-press, in one result's note). Contains mode never replaces.
final class SearchScreen extends StatefulWidget {
  /// Creates the search screen.
  const SearchScreen({
    required this.controller,
    required this.onOpenNote,
    this.onOpenTags,
    this.source,
    this.replaceSource,
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

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

final class _SearchScreenState extends State<SearchScreen> {
  static const int _pageSize = 50;
  static const Duration _debounce = Duration(milliseconds: 150);

  final TextEditingController _query = TextEditingController();

  SearchSource? _source;
  Timer? _debounceTimer;
  Timer? _replaceRefresh;
  bool _contains = false;
  bool _searched = false;
  List<SearchHit> _hits = const [];
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQueryChanged);
    if (widget.source == null) unawaited(_loadSource());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _replaceRefresh?.cancel();
    _query.removeListener(_onQueryChanged);
    _query.dispose();
    super.dispose();
  }

  /// Resolves the search source once; a failed load leaves [_source] null
  /// and [_runSearch] retries on the next query — a transient startup
  /// failure must not wedge the box into issuing queries that go nowhere.
  Future<void> _loadSource() async {
    final source = await _acquireSource();
    if (!mounted || source == null) return;
    setState(() => _source = source);
    if (_query.text.trim().isNotEmpty) unawaited(_runSearch());
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
    _debounceTimer = Timer(
      _debounce,
      () => unawaited(_runSearch()),
    );
  }

  void _setContains(bool value) {
    if (_contains == value) return;
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
    const AppLogger(name: 'search.ui').debug(
      'issue id $id (${contains ? 'contains' : 'words'}) "$text"',
    );
    final results = contains
        ? await source.searchContains(text, id: id)
        : await source.search(buildFtsQuery(text), id: id);
    if (!source.isCurrent(id)) return; // a newer query superseded this one
    if (!mounted) return;
    setState(() {
      _searched = true;
      _hits = results;
      _shown = _pageSize < results.length ? _pageSize : results.length;
    });
  }

  void _loadMore() {
    setState(() {
      final next = _shown + _pageSize;
      _shown = next < _hits.length ? next : _hits.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
                  prefixIcon: const Icon(Icons.search),
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
                    segments: const [
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
                  if (!_contains && _hits.isNotEmpty)
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
            ],
          ),
        ),
        Expanded(child: _results(theme)),
      ],
    );
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
            title: const Text(AppStrings.searchLoadMore),
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
              title: const Text(AppStrings.replaceInNoteAction),
              onTap: () => Navigator.pop(context, 'replace'),
            ),
          ],
        ),
      ),
    );
    if (action == 'replace' && mounted) {
      await _openReplace(onlyPath: hit.path);
    }
  }

  /// The header Replace action: replace across every matching note.
  Future<void> _openReplaceAll() => _openReplace();

  /// Runs the replace flow: resolves the replace source, computes the
  /// affected-note count (whole-library runs), asks for the replacement
  /// text, and reports the outcome.
  Future<void> _openReplace({String? onlyPath}) async {
    final source = await _acquireReplace();
    if (!mounted) return;
    if (source == null) {
      _snack(AppStrings.replaceUnavailable);
      return;
    }
    final term = _query.text.trim();
    int? count;
    if (onlyPath == null) {
      try {
        count = await source.countNotes(term);
      } on Object {
        count = null;
      }
      if (!mounted) return;
    }
    final report = await showDialog<ReplaceReport>(
      context: context,
      builder: (context) => _ReplaceDialog(
        source: source,
        term: term,
        noteCount: count,
        onlyPath: onlyPath,
      ),
    );
    if (report == null || !mounted) return;
    final message = report.occurrences == 0
        ? 'No whole-word match of "$term" was found'
        : 'Replaced ${report.occurrences} occurrence(s) of "$term" in '
            '${report.notesChanged} note(s)';
    _snack(
      report.skipped.isEmpty
          ? message
          : '$message (${report.skipped.length} open note(s) skipped)',
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
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

/// The replace confirmation dialog (T-M3-10): the replacement text, the
/// case toggle, and the exact-word scope note. Runs the replace from the
/// confirm button (busy spinner) and pops with the [ReplaceReport].
final class _ReplaceDialog extends StatefulWidget {
  /// Creates the dialog over [source] for [term]; [noteCount] is the
  /// affected-notes estimate for whole-library runs, [onlyPath] scopes the
  /// run to one note.
  const _ReplaceDialog({
    required this.source,
    required this.term,
    required this.noteCount,
    required this.onlyPath,
  });

  final ReplaceSource source;
  final String term;
  final int? noteCount;
  final String? onlyPath;

  @override
  State<_ReplaceDialog> createState() => _ReplaceDialogState();
}

final class _ReplaceDialogState extends State<_ReplaceDialog> {
  final TextEditingController _replacement = TextEditingController();
  bool _caseSensitive = false;
  bool _busy = false;

  @override
  void dispose() {
    _replacement.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    final report = await widget.source.replaceAll(
      term: widget.term,
      replacement: _replacement.text,
      caseSensitive: _caseSensitive,
      only: widget.onlyPath == null ? null : {widget.onlyPath!},
    );
    if (!mounted) return;
    Navigator.of(context).pop(report);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final only = widget.onlyPath;
    final scope = only == null
        ? (widget.noteCount == null
            ? 'Whole-word matches of "${widget.term}"'
            : '${widget.noteCount} note(s) contain "${widget.term}"')
        : 'Whole-word matches of "${widget.term}" in $only';
    return AlertDialog(
      title: Text(
        only == null
            ? AppStrings.replaceDialogTitle
            : AppStrings.replaceInThisNoteTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('replace-with'),
              controller: _replacement,
              autofocus: true,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: AppStrings.replaceWithLabel,
                hintText: widget.term,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            CheckboxListTile(
              key: const Key('replace-case'),
              value: _caseSensitive,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _caseSensitive = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.replaceCaseSensitive),
            ),
            const SizedBox(height: 4),
            Text(
              '$scope — only exact whole-word matches are replaced.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('replace-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.replaceCancel),
        ),
        FilledButton(
          key: const Key('replace-confirm'),
          onPressed: _busy ? null : _run,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.replaceConfirm),
        ),
      ],
    );
  }
}
