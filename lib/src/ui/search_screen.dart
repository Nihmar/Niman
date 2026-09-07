import 'dart:async';

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
/// query are dropped by the source's invocation id; an empty query shows
/// the hint instead of results.
final class SearchScreen extends StatefulWidget {
  /// Creates the search screen.
  const SearchScreen({
    required this.controller,
    required this.onOpenNote,
    this.source,
    super.key,
  });

  /// The open library session (for the search source).
  final LibrarySession controller;

  /// Called with the note's library-relative path when a result is tapped.
  final void Function(String path) onOpenNote;

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
    unawaited(_loadSource());
    _query.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _query.removeListener(_onQueryChanged);
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadSource() async {
    final source = widget.source ?? await widget.controller.searchSource;
    if (!mounted) return;
    setState(() => _source = source);
    if (_query.text.trim().isNotEmpty) unawaited(_runSearch());
  }

  void _onQueryChanged() {
    _debounceTimer?.cancel();
    if (_query.text.trim().isEmpty) {
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
    if (_query.text.trim().isNotEmpty) unawaited(_runSearch());
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
    final source = _source;
    final text = _query.text.trim();
    if (source == null || text.isEmpty) return;
    final id = source.begin();
    final results = _contains
        ? await source.searchContains(text, id: id)
        : await source.search(buildFtsQuery(text), id: id);
    if (!source.isCurrent(id) || !mounted) return;
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
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
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                key: const Key('search-mode'),
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text(AppStrings.searchModeWords),
                    icon: Icon(Icons.text_fields),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(AppStrings.searchModeContains),
                    icon: Icon(Icons.find_in_page),
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
            ],
          ),
        ),
        Expanded(child: _results(theme)),
      ],
    );
  }

  Widget _results(ThemeData theme) {
    if (!_searched) {
      return Center(
        child: Text(
          AppStrings.searchEmptyHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
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
