import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/search/query.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/search/search_excerpt.dart' show wordTermsOf;
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/search/task_events.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/app_switch.dart';
import 'package:niman/src/ui/indexing_notice.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/search_field_pager.dart';
import 'package:niman/src/ui/search_request.dart';
import 'package:niman/src/ui/search_task_events.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// The other ways a hit opens, where the shell has them (#712): in a new
/// tab, in the other pane, and as a row of the tree.
typedef SearchHitOpens = ({
  void Function(String path) newTab,
  void Function(String path) beside,
  void Function(String path) reveal,
});

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
///
/// A lone `+project` or `@context` (#730) asks the tasks and events the
/// library already holds, above the notes and in a group of its own: the
/// index has the notes' words and nothing else, so the two files are read
/// from the snapshots in memory ([taskEvents]).
final class SearchScreen extends StatefulWidget {
  /// Creates the search screen.
  const new({
    required this.controller,
    required this.onOpenNote,
    this.onOpenHit,
    this.onOpenTags,
    this.requests,
    this.commands,
    this.source,
    this.replaceSource,
    this.fieldSource,
    this.taskEvents,
    this.onOpenTaskEvent,
    this.eventTimesClock = false,
    this.hitOpens,
    this.unsavedTracker,
    super.key,
  });

  /// The open library session (for the search source).
  final LibrarySession controller;

  /// Called with the note's library-relative path when a result is tapped.
  final void Function(String path) onOpenNote;

  /// Called instead of [onOpenNote] when a hit is opened for words it
  /// matched (#1045): the note opens with the first of them found and
  /// shown. Null opens every hit as [onOpenNote] does.
  final void Function(String path, List<String> terms)? onOpenHit;

  /// Opens the Tags screen (shell-provided; the tags button shows only
  /// when set).
  final VoidCallback? onOpenTags;

  /// What another part of the app asks Search to show (#535): a query is
  /// typed into the box, as if by hand.
  final ValueListenable<SearchRequest?>? requests;

  /// What the shell asks the screen to do besides showing a request
  /// (#712): focus the field, step through the hits.
  final SearchCommands? commands;

  /// Optional source override (widget tests inject a fake); when null the
  /// screen resolves it from [controller].
  final SearchSource? source;

  /// Optional replace-source override (widget tests inject a fake); when
  /// null the screen resolves it from [controller].
  final ReplaceSource? replaceSource;

  /// Optional frontmatter-field source override (widget tests inject a
  /// fake); when null the screen resolves it from [controller].
  final FieldSource? fieldSource;

  /// The tasks and events already in memory (#730): a lone `+project` or
  /// `@context` in the box answers with them, in a group above the notes.
  /// Null — a host that holds neither file — draws the notes alone.
  final TaskEvents? taskEvents;

  /// Opens a row of the tasks-and-events group: a task (the task list), an
  /// event or a goal (its line in `calendar.txt`).
  final void Function(TaskEventHit hit)? onOpenTaskEvent;

  /// Whether an event's time is read as a clock rather than as written
  /// (#730), the journal's own setting.
  final bool eventTimesClock;

  /// The other ways a hit opens, offered in its menu (#712); null — a
  /// phone, with one screen at a time — offers the hit's own open alone.
  final SearchHitOpens? hitOpens;

  /// The open notes' unsaved edits (#1042): a Replace all saves them first,
  /// so the run rewrites what is on screen, and tells the editors afterwards
  /// to adopt the rewritten files. Null — a test — runs the replace alone.
  final UnsavedTracker? unsavedTracker;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

final class _SearchScreenState extends State<SearchScreen> {
  static const int _pageSize = 50;
  static const Duration _debounce = Duration(milliseconds: 150);
  static const Duration _stepScroll = Duration(milliseconds: 150);

  final TextEditingController _query = TextEditingController();

  /// The query field's focus, for `Ctrl+Shift+F` (#712); its keys step
  /// through the hits.
  late final FocusNode _queryFocus = FocusNode(onKeyEvent: _queryKey);

  /// The hit last opened, from a tap or `F4`/`Shift+F4` (#712): the row
  /// stays highlighted and the steps continue from it.
  String? _currentHit;

  /// The key of that row, to bring it back into view when the steps run.
  final GlobalKey _currentHitKey = GlobalKey();

  /// The results list's scroll, to bring a row that is not built yet into
  /// range by its index (#768).
  final ScrollController _resultsScroll = ScrollController();

  /// The text and mode the list now showing was searched for: a result
  /// set for another one starts at the top (#1044), while a re-run of the
  /// same query (after a replace) keeps its place.
  String? _resultsFor;

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

  /// The pages of the `key = value` filter [_hits] came from (#1037), or
  /// null for a text search: the notes past the page read are in the index
  /// and not in [_hits].
  FieldPager? _fieldPager;

  /// How far a contains scan has got, while it runs (#1038); null when no
  /// scan is running.
  ContainsProgress? _scan;

  /// The words the hits on screen matched: what a hit opens at (#1045).
  List<String> _hitTerms = const [];

  /// Whether the next page of the filter is being read.
  bool _readingMore = false;

  /// True from the moment a runnable query is typed until its results land
  /// (#1038): the list on screen is the previous query's, and is shown as
  /// such; Enter waits for the new one instead of opening a row of the old.
  bool _stale = false;

  /// Enter was pressed while [_stale]: the first hit of the fresh results
  /// opens when they land.
  bool _openWhenFresh = false;

  /// The lone `+project`/`@context` the results were searched for, when
  /// the box held one (#730): the Tasks and events group answers it, and
  /// null whenever the results are notes only.
  String? _taskEventToken;

  /// The words [_hits] were searched for, when they came from a word
  /// search: its excerpts are read from the notes as their rows are built
  /// ([SearchSource.excerpt]), and null for results that carry their own.
  String? _excerptWords;

  /// The excerpts asked for so far, by path, for [_hits].
  final Map<String, Future<String>> _excerpts = {};

  @override
  void initState() {
    super.initState();
    // Timed because entering this tab is reported as stuttering, and the
    // two suspects leave different traces: acquiring the source (the
    // background isolate and a second SQLite connection) shows up here as
    // milliseconds, while the cost of building and painting the screen
    // shows up as slow frames after a mount that took no time at all.
    final started = DateTime.now();
    // A request made before the first visit mounted this screen: typed in
    // before the box listens, and searched once the source is ready.
    if (widget.requests?.value case SearchRequest(tag: null, :final text)) {
      _query.text = text;
    }
    widget.requests?.addListener(_requested);
    widget.commands?.addListener(_commanded);
    // Asked before this screen mounted (Ctrl+Shift+F as the sidebar built
    // it): take the focus once there is a frame to give it in. The ask is
    // taken, so a later remount does not answer it again (#768); a step
    // asked of no screen has no hits to step and is dropped.
    if (widget.commands case final commands?) {
      commands.takeStep();
      if (commands.takeFocus()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _queryFocus.requestFocus();
        });
      }
    }
    _query.addListener(_onQueryChanged);
    _replacement.addListener(_onReplacementChanged);
    if (widget.source == null) unawaited(_loadSource(since: started));
    const AppLogger(name: 'search.ui')
        .debug('mount: ${DateTime.now().difference(started).inMilliseconds}ms');
  }

  @override
  void dispose() {
    const AppLogger(name: 'search.ui').debug('dispose');
    widget.commands?.removeListener(_commanded);
    _queryFocus.dispose();
    _resultsScroll.dispose();
    _debounceTimer?.cancel();
    _replaceRefresh?.cancel();
    widget.requests?.removeListener(_requested);
    _query.removeListener(_onQueryChanged);
    _replacement.removeListener(_onReplacementChanged);
    _query.dispose();
    _replacement.dispose();
    super.dispose();
  }

  /// Types a requested query into the box; a tag is the Tags screen's.
  void _requested() {
    if (widget.requests?.value case SearchRequest(tag: null, :final text)) {
      _query.text = text;
    }
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
    _openWhenFresh = false;
    final text = _query.text.trim();
    if (text.isEmpty || !_canSearch(text)) {
      // Nothing will be (re)searched: clear the results and supersede any
      // in-flight query, so its results cannot land on the hint state.
      _source?.begin();
      setState(() {
        _stale = false;
        _scan = null;
        _searched = false;
        _hits = const [];
        _shown = 0;
        _taskEventToken = null;
      });
      return;
    }
    // Editing the term invalidates the replace preview: leave the mode.
    _leaveReplaceMode();
    const AppLogger(name: 'search.ui')
        .debug('debouncing "$text" (${_debounce.inMilliseconds}ms)');
    _debounceTimer = Timer(_debounce, () => unawaited(_runSearch()));
    if (!_stale) setState(() => _stale = true);
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
        _taskEventToken = null;
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
      _taskEventToken = null;
    });
  }

  Future<void> _runSearch() async {
    final text = _query.text.trim();
    if (text.isEmpty || !_canSearch(text)) return;
    if (!_stale) setState(() => _stale = true);
    var source = _source;
    if (source == null) {
      source = await _acquireSource();
      if (source == null || !mounted) {
        if (mounted) setState(() => _stale = false);
        return;
      }
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
    if (field == null && contains) {
      // A scan of the notes themselves: hits and progress are shown as the
      // batches come in, and Stop ends it with what it has (#1038).
      await for (final progress in source.searchContainsStream(text, id: id)) {
        if (!source.isCurrent(id) || !mounted) return;
        _land(
          id: id,
          mode: mode,
          text: text,
          results: progress.hits,
          scan: progress.done ? null : progress,
          clock: clock,
        );
      }
      return;
    }
    final pager = field == null ? null : await _openFieldPager(field);
    final results = pager != null
        ? await pager.first()
        : field != null
        ? const <SearchHit>[]
        : await source.search(buildFtsQuery(text), id: id);
    if (!source.isCurrent(id)) return; // a newer query superseded this one
    if (!mounted) return;
    _land(
      id: id,
      mode: mode,
      text: text,
      results: results,
      pager: pager,
      clock: clock,
    );
  }

  /// Puts [results] on screen for the query [text] issued as [id]; with
  /// [scan] set, more are still to come (#1038).
  void _land({
    required int id,
    required String mode,
    required String text,
    required List<SearchHit> results,
    required Stopwatch clock,
    FieldPager? pager,
    ContainsProgress? scan,
  }) {
    final contains = mode == 'contains';
    final field = mode == 'field';
    // The repo already logs the SQL time; this is issue → results landed,
    // i.e. what a keystroke waits for on the UI side (debounce included
    // in the gap back to the 'debouncing' line).
    const AppLogger(name: 'search.ui').debug(
      'id $id landed in ${clock.elapsedMilliseconds}ms '
      '(${results.length} hits)',
    );
    final resultsFor = '$mode:$text';
    final fresh = resultsFor != _resultsFor;
    _resultsFor = resultsFor;
    // Enter pressed while the results were out opens the first of them, once
    // there is one.
    final open = _openWhenFresh && (scan == null || results.isNotEmpty);
    if (open) _openWhenFresh = false;
    setState(() {
      _stale = false;
      _scan = scan;
      // A new result set starts at its top, with nothing marked: the old
      // offset and mark belong to rows that are gone (#1044).
      if (fresh) {
        _currentHit = null;
        if (_resultsScroll.hasClients) _resultsScroll.jumpTo(0);
      }
      _searched = true;
      _hitTerms = field
          ? const []
          : contains
          ? [text]
          : wordTermsOf(text);
      _fieldPager = pager;
      _hits = results;
      final page = _pageSize < results.length ? _pageSize : results.length;
      // A scan adding hits keeps the pages the reader has opened.
      final kept = _shown < results.length ? _shown : results.length;
      _shown = fresh || kept < page ? page : kept;
      if (fresh) _excerpts.clear();
      _excerptWords = !field && !contains ? text : null;
      _taskEventToken = mode == 'words' ? taskEventQuery(text) : null;
    });
    logNextFrame('search.ui', 'results first frame (id $id)');
    if (open) _openMarkedOrFirst();
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

  /// The pages of the `key = value` filter [f], or null where there is no
  /// field source. Its notes are shaped like search hits, so the results
  /// list stays one list; there is no snippet: the match is the field, not
  /// a place in the text.
  Future<FieldPager?> _openFieldPager(({String key, String value}) f) async {
    final fields = await _acquireFields();
    return fields == null ? null : FieldPager(fields, f.key, f.value);
  }

  /// The shell's `F4`/`Shift+F4` and `Ctrl+Shift+F` land here (#712): the
  /// screen owns the hits and the field, so it acts on the ask.
  void _commanded() {
    final commands = widget.commands;
    if (commands == null) return;
    if (commands.takeFocus()) _queryFocus.requestFocus();
    final step = commands.takeStep();
    if (step != 0) _stepHit(step);
  }

  /// Opens the hit at [index] in the shell (#712) and makes it the
  /// current one: the list keeps it highlighted, and the steps continue
  /// from it. A hit under the page's cut is listed first.
  void _openHit(int index) {
    _markHit(index);
    _open(_hits[index].path);
  }

  /// Opens the note at [path] — at the words the hits matched, where the
  /// shell can show them (#1045).
  void _open(String path) {
    final open = widget.onOpenHit;
    if (open != null && _hitTerms.isNotEmpty) {
      open(path, _hitTerms);
    } else {
      widget.onOpenNote(path);
    }
  }

  /// Makes the hit at [index] the current one, highlighted and in view,
  /// without opening it.
  void _markHit(int index) {
    setState(() {
      _currentHit = _hits[index].path;
      if (index >= _shown) _shown = index + 1;
    });
    unawaited(_revealHit(index));
  }

  /// Opens the next ([direction] 1) or previous (-1) hit, wrapping at
  /// either end; with no current hit the first (`F4`) or the last
  /// (`Shift+F4`) is the one. With [open] false the hit is only marked:
  /// the arrows in the field move, `Enter` opens.
  void _stepHit(int direction, {bool open = true}) {
    if (_hits.isEmpty) return;
    final current = _hits.indexWhere((hit) => hit.path == _currentHit);
    final next = current < 0
        ? (direction > 0 ? 0 : _hits.length - 1)
        : (current + direction) % _hits.length;
    open ? _openHit(next) : _markHit(next);
  }

  /// `↓`/`↑` in the query field move through the hits and `Enter` opens
  /// the one marked (#712); the field keeps the cursor.
  KeyEventResult _queryKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _replaceMode || (_hits.isEmpty && !_stale)) {
      return KeyEventResult.ignored;
    }
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isAltPressed || keys.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      // The arrows do not walk the rows of a list about to be replaced.
      case LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.arrowUp
          when _stale:
        break;
      case LogicalKeyboardKey.arrowDown:
        _stepHit(1, open: false);
      case LogicalKeyboardKey.arrowUp:
        _stepHit(-1, open: false);
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter
          when event is KeyDownEvent:
        _openMarkedOrFirst();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Opens the hit marked, or the first when none is (#1044): Enter after
  /// typing opens the top result, as the palette's does.
  void _openMarkedOrFirst() {
    if (_replaceMode) return;
    // The results on screen are the last query's: the open waits for the
    // ones being searched (#1038).
    if (_stale) {
      _openWhenFresh = true;
      return;
    }
    if (_hits.isEmpty) return;
    final at = _hits.indexWhere((hit) => hit.path == _currentHit);
    _openHit(at < 0 ? 0 : at);
  }

  /// Brings the hit at [index] into view (#768). A row outside the
  /// list's built range has no context to reveal, so the list first jumps
  /// to where the index is estimated to sit — the list's own estimate of
  /// its length, shared out by row — and the row, built there or near it,
  /// is then scrolled to. Each jump lays out real rows around the target,
  /// which sharpens the estimate, so the target is built within a few.
  Future<void> _revealHit(int index) async {
    for (var jump = 0; jump < _revealJumps; jump++) {
      await WidgetsBinding.instance.endOfFrame;
      // Another step or a new search since: that one reveals its own.
      if (!mounted ||
          index >= _hits.length ||
          _currentHit != _hits[index].path) {
        return;
      }
      if (_currentHitKey.currentContext case final row?) {
        if (!row.mounted) return;
        await Scrollable.ensureVisible(
          row,
          alignment: 0.5,
          duration: _stepScroll,
        );
        return;
      }
      if (!_resultsScroll.hasClients) return;
      final position = _resultsScroll.position;
      // The group's rows sit above the notes: the estimate counts them,
      // or a step would land short by exactly their number.
      final lead = _groupLead(_taskEventRows());
      final rows = lead + _shown + (_hasMoreRows ? 1 : 0);
      final length = position.maxScrollExtent + position.viewportDimension;
      final offset =
          length * (index + lead) / rows - position.viewportDimension / 2;
      position.jumpTo(
        offset.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    }
  }

  /// How many jumps [_revealHit] makes at most: the estimate converges
  /// in one or two, and a bound keeps a list that keeps changing under it
  /// from holding the reveal open.
  static const int _revealJumps = 8;

  void _loadMore() {
    final next = _shown + _pageSize;
    if (next >= _hits.length && (_fieldPager?.hasMore ?? false)) {
      unawaited(_loadMoreFromFilter());
    }
    setState(() => _shown = next < _hits.length ? next : _hits.length);
  }

  /// Reads the filter's next page and lists it after the notes shown
  /// (#1037); a page that lands for a filter since replaced is dropped.
  Future<void> _loadMoreFromFilter() async {
    final pager = _fieldPager;
    if (pager == null || _readingMore) return;
    setState(() => _readingMore = true);
    final more = await pager.next();
    if (!mounted || !identical(pager, _fieldPager)) return;
    setState(() {
      _readingMore = false;
      _hits = [..._hits, ...more];
      _shown = _shown + _pageSize < _hits.length
          ? _shown + _pageSize
          : _hits.length;
    });
  }

  /// Whether the list ends in its Show more row: notes held and not shown,
  /// or a filter with pages left to read.
  bool get _hasMoreRows =>
      _shown < _hits.length || (_fieldPager?.hasMore ?? false);

  @override
  Widget build(BuildContext context) {
    final started = DateTime.now();
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // The field toggles where the platform is a pointer, and where
        // the pane is too narrow for the segmented row — the sidebar
        // island is, at around 300 px (#712).
        final dense = pointerDense(theme) || constraints.maxWidth < 360;
        final child = Column(
          children: [
            const IndexingNotice(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                children: [
                  TextField(
                    key: const Key('search-query'),
                    controller: _query,
                    focusNode: _queryFocus,
                    textInputAction: TextInputAction.search,
                    // The search action of a touch keyboard (a hardware
                    // Enter is [_queryKey]'s).
                    onSubmitted: (_) => _openMarkedOrFirst(),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchHint,
                      // The icon says which of the two the box is doing, so a
                      // filter that matched is visible before the results are.
                      prefixIcon: Icon(
                        _inFieldMode ? Icons.filter_alt_outlined : Icons.search,
                      ),
                      suffixIcon: dense || _query.text.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              // The row is anchored at the field's end and
                              // grows leftwards: Clear, which comes and
                              // goes, sits on that side, so the toggle at
                              // the end never moves under a pointer on it
                              // (#782). Beside the toggle it is as compact
                              // as the toggle, or the field would grow
                              // taller and shift the toggle down.
                              children: [
                                if (_query.text.isNotEmpty)
                                  IconButton(
                                    key: const Key('search-clear'),
                                    icon: const Icon(Icons.close),
                                    visualDensity: dense
                                        ? VisualDensity.compact
                                        : null,
                                    onPressed: _clearQuery,
                                  ),
                                if (dense) _modeToggle(),
                              ],
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Words or contains is a toggle inside the field where a
                      // pointer aims (#712); a phone keeps the segmented row.
                      if (!dense)
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
                      // Compact so the row stays inside a phone's width with
                      // the replace button showing: at standard density it
                      // overflows by a few pixels at 390 px.
                      if (!_contains && !_inFieldMode && _hits.isNotEmpty)
                        IconButton(
                          key: const Key('search-replace'),
                          tooltip: AppStrings.replaceTooltip,
                          icon: const Icon(Icons.find_replace),
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _openReplaceAll,
                        ),
                      if (widget.onOpenTags != null)
                        IconButton(
                          key: const Key('open-tags'),
                          tooltip: AppStrings.openTagsTooltip,
                          icon: const Icon(Icons.sell_outlined),
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: widget.onOpenTags,
                        ),
                    ],
                  ),
                  if (_replaceMode) _replacePanel(theme),
                ],
              ),
            ),
            if (_scan case final scan? when !_replaceMode)
              _scanBar(Theme.of(context), scan),
            if (_stale && !_replaceMode)
              const LinearProgressIndicator(
                key: Key('search-busy'),
                minHeight: 2,
              ),
            Expanded(
              child: _replaceMode
                  ? _replacePreviewList(theme)
                  : Opacity(
                      opacity: _stale && _hits.isNotEmpty ? 0.5 : 1,
                      child: _resultsWithEvents(theme),
                    ),
            ),
          ],
        );
        const AppLogger(name: 'search.ui').debug(
          'build: ${DateTime.now().difference(started).inMilliseconds}ms',
        );
        return child;
      },
    );
  }

  /// The results, re-read whenever the tasks or the calendar move: the
  /// group is what is in memory, not what a query landed with (#730).
  Widget _resultsWithEvents(ThemeData theme) {
    final events = widget.taskEvents;
    if (events == null) return _results(theme);
    return ListenableBuilder(
      listenable: events.changes,
      builder: (context, _) => _results(theme),
    );
  }

  /// The Tasks and events rows for the query the results were searched
  /// for, or empty: a lone `+project`/`@context` in Words mode, read from
  /// the files in memory.
  List<TaskEventHit> _taskEventRows() {
    final events = widget.taskEvents;
    final token = _taskEventToken;
    if (events == null || token == null) return const [];
    return events.hits(token);
  }

  /// How many rows the group takes in the list before the notes: its
  /// heading, its own rows, and the Notes heading when both sections show.
  int _groupLead(List<TaskEventHit> group) =>
      group.isEmpty ? 0 : 1 + group.length + (_hits.isEmpty ? 0 : 1);

  /// The progress of a contains scan and the way to end it (#1038).
  Widget _scanBar(ThemeData theme, ContainsProgress scan) => Column(
    key: const Key('search-scan'),
    children: [
      LinearProgressIndicator(
        value: scan.total > 0 ? scan.scanned / scan.total : null,
        minHeight: 2,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.searchScanning(scan.scanned, scan.total),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              key: const Key('search-stop'),
              onPressed: _stopScan,
              child: Text(AppStrings.searchStop),
            ),
          ],
        ),
      ),
    ],
  );

  /// Ends the contains scan with the hits it has found so far (#1038): the
  /// source is told the query is over, and its stream ends.
  void _stopScan() {
    _source?.begin();
    setState(() => _scan = null);
  }

  Widget _results(ThemeData theme) {
    if (!_searched) return _hint(theme);
    final group = _taskEventRows();
    // No match is only known once the scan is done (#1038).
    if (_hits.isEmpty && group.isEmpty && _scan != null) {
      return const SizedBox.shrink();
    }
    if (_hits.isEmpty && group.isEmpty) {
      return Center(
        child: Text(
          AppStrings.searchNoMatches,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final lead = _groupLead(group);
    return ListView.builder(
      key: const Key('search-results'),
      controller: _resultsScroll,
      itemCount: lead + _shown + (_hasMoreRows ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < lead) {
          if (index == 0) {
            return searchSectionHeader(
              context,
              AppStrings.searchTasksAndEvents(group.length),
              key: const Key('search-group-tasks-events'),
            );
          }
          if (index <= group.length) {
            final hit = group[index - 1];
            return searchTaskEventRow(
              context,
              hit,
              today: DateTime.now(),
              asClock: widget.eventTimesClock,
              onTap: widget.onOpenTaskEvent == null
                  ? null
                  : () => widget.onOpenTaskEvent!(hit),
            );
          }
          return searchSectionHeader(
            context,
            AppStrings.searchNotes(_hits.length),
            key: const Key('search-group-notes'),
          );
        }
        final at = index - lead;
        if (at >= _shown) {
          return ListTile(
            key: const Key('search-load-more'),
            leading: const Icon(Icons.expand_more),
            title: Text(AppStrings.searchLoadMore),
            // A filter that holds more notes than it lists says how many.
            subtitle: switch (_fieldPager) {
              final pager? when pager.hasMore || _shown >= _hits.length => Text(
                AppStrings.searchShowingFirst(_hits.length, pager.total),
              ),
              _ => null,
            },
            onTap: _loadMore,
          );
        }
        final hit = _hits[at];
        final current = hit.path == _currentHit;
        return KeyedSubtree(
          key: current ? _currentHitKey : null,
          child: _hitGestures(
            at,
            ListTile(
              key: Key('search-hit-${hit.path}'),
              selected: current,
              selectedTileColor: theme.colorScheme.secondaryContainer,
              title: Text(
                hit.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
                    _snippet(theme, hit.snippet)
                  else if ((_excerptWords, _source) case (
                    final words?,
                    final source?,
                  ))
                    FutureBuilder<String>(
                      future: _excerpts.putIfAbsent(
                        hit.path,
                        () => source.excerpt(hit, words),
                      ),
                      builder: (context, excerpt) => _excerptSlot(
                        theme,
                        excerpt.data ?? '',
                        loading:
                            excerpt.connectionState != ConnectionState.done,
                      ),
                    ),
                ],
              ),
              onTap: () => _tapHit(at),
              onLongPress: () => _showNoteActions(at),
            ),
          ),
        );
      },
    );
  }

  /// A hit's pointer ways in (#712): a right click opens its menu at the
  /// pointer, a middle click opens it in a new tab.
  Widget _hitGestures(int at, Widget row) => GestureDetector(
    onSecondaryTapUp: (details) =>
        _showNoteActions(at, anchor: menuAnchorAt(details.globalPosition)),
    onTertiaryTapUp: (_) => _newTabHit(at),
    child: row,
  );

  /// A tap on a hit opens it; with `Ctrl` held, in a new tab (#712).
  void _tapHit(int at) {
    if (HardwareKeyboard.instance.isControlPressed && _newTabHit(at)) return;
    _openHit(at);
  }

  /// Opens the hit at [at] in a new tab, where there are tabs; false when
  /// there are none.
  bool _newTabHit(int at) {
    final opens = widget.hitOpens;
    if (opens == null) return false;
    _markHit(at);
    opens.newTab(_hits[at].path);
    return true;
  }

  /// The room for a word hit's excerpt, two lines whether it has arrived
  /// or not (#1044): the row is its final height from the first frame, so
  /// nothing slides under the pointer while the excerpts load. While it is
  /// on its way a faint bar holds the line.
  Widget _excerptSlot(
    ThemeData theme,
    String excerpt, {
    required bool loading,
  }) => Stack(
    children: [
      // Two lines of the snippet's own style, drawn as nothing.
      const Opacity(opacity: 0, child: Text('\n', maxLines: 2)),
      if (excerpt.isNotEmpty)
        _snippet(theme, excerpt)
      else if (loading)
        Positioned(
          left: 0,
          top: 5,
          width: 140,
          height: 8,
          child: DecoratedBox(
            key: const Key('search-excerpt-skeleton'),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
    ],
  );

  Widget _snippet(ThemeData theme, String snippet) => Text.rich(
    _highlight(theme, snippet),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );

  /// Words/contains as a toggle in the query field, where a pointer aims
  /// (#712): selected means contains, unselected means whole words.
  Widget _modeToggle() => IconButton(
    key: const Key('search-mode-toggle'),
    tooltip: _contains
        ? AppStrings.searchModeContains
        : AppStrings.searchModeWords,
    isSelected: _contains,
    visualDensity: VisualDensity.compact,
    icon: const Icon(Icons.abc),
    onPressed: () => _setContains(!_contains),
  );

  /// A result row's menu: the single-note replace (T-M3-10) and, where
  /// the shell has them, the other ways to open it (#712). A long press
  /// on a phone; a right click, at [anchor], where a pointer aims.
  Future<void> _showNoteActions(int at, {Rect? anchor}) async {
    if (!mounted) return;
    final hit = _hits[at];
    final opens = widget.hitOpens;
    Widget row(String value, IconData icon, String label) => ListTile(
      key: Key('search-hit-action-$value'),
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
    final action = await showActionSheet<String>(
      context,
      anchor: anchor,
      items: (context) => [
        if (opens != null) ...[
          row('open', Icons.open_in_browser_outlined, AppStrings.actionOpen),
          row('newtab', Icons.tab_outlined, AppStrings.openInNewTab),
          row('beside', Icons.vertical_split_outlined, AppStrings.openBeside),
          row('reveal', Icons.account_tree_outlined, AppStrings.revealInTree),
        ],
        ListTile(
          key: const Key('replace-note-action'),
          leading: const Icon(Icons.find_replace),
          title: Text(AppStrings.replaceInNoteAction),
          onTap: () => Navigator.pop(context, 'replace'),
        ),
      ],
    );
    if (!mounted || action == null) return;
    // The list may have changed under the menu: the hit is found again.
    final now = _hits.indexWhere((h) => h.path == hit.path);
    if (now >= 0 && action != 'reveal' && action != 'replace') _markHit(now);
    switch (action) {
      case 'open':
        _open(hit.path);
      case 'newtab':
        opens?.newTab(hit.path);
      case 'beside':
        opens?.beside(hit.path);
      case 'reveal':
        opens?.reveal(hit.path);
      case 'replace':
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
      if (mounted && _replaceMode) setState(() => _previewBusy = false);
      const AppLogger(name: 'search.ui').warning('replace preview failed: $e');
      return;
    }
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
    // The notes open with edits the disk does not have are saved first: the
    // run rewrites the files, and an editor that still held the old words
    // would save them over the replacement (#1042). A save that fails stops
    // the run before it touches anything.
    final tracker = widget.unsavedTracker;
    if (tracker != null) {
      try {
        await tracker.saveAll();
      } on Object catch (error) {
        const AppLogger(name: 'search.ui').warning('replace aborted: $error');
        if (!mounted) return;
        setState(() => _previewBusy = false);
        _snack(AppStrings.noteSaveFailedSnack);
        return;
      }
      if (!mounted) return;
    }
    final report = await source.replaceAll(
      term: term,
      replacement: _replacement.text,
      caseSensitive: _replaceCase,
      only: only == null ? null : {only},
    );
    // The open notes the run rewrote adopt their new text (they were saved
    // before it ran, so none of them holds anything the file does not).
    tracker?.notifyDiskChanged(const {});
    if (!mounted) return;
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
    _snack('$message$skipped$failures');
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
      scope = AppStrings.replaceScopeNote(only);
    } else if (noteCount == 0) {
      scope = AppStrings.replaceScopeWholeLibrary;
    } else {
      scope = AppStrings.replaceScopeNotes(noteCount);
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
              AppSwitch(
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
