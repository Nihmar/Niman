import 'dart:async';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/search/query.dart';
import 'package:copist/src/search/search_repo.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The Search tab/screen (T-M3-05/T-M3-08 toggle).
///
/// Query box (debounced ~150 ms) with the Words/Contains mode toggle over
/// ranked FTS results — path + snippet with `<mark>` highlighting, paged
/// (50 at a time, "Show more") — and click-to-open. Results of a superseded
/// query are dropped by the source's invocation id; an empty (or too
/// short) query shows a hint instead of results.
final class SearchScreen extends StatefulWidget {
  /// Creates the search screen.
  const SearchScreen({
    required this.controller,
    required this.onOpenNote,
    this.onOpenTags,
    this.source,
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

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

final class _SearchScreenState extends State<SearchScreen> {
  static const int _pageSize = 50;
  static const Duration _debounce = Duration(milliseconds: 150);

  final TextEditingController _query = TextEditingController();

  SearchSource? _source;
  Timer? _debounceTimer;
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
        );
      },
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
