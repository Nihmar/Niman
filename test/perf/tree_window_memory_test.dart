// What the note tree holds after a list of a very large folder is scrolled
// from its top to its end: a window of pages, not what was scrolled past
// (#1200, `docs/records/tree-window.md`, phase 5).
//
// One folder of N files is written straight into an in-memory index with one
// recursive INSERT (the numbers are SQLite's, not the filesystem's). A
// `TreePages` is then driven the way `NoteTree` drives it while a list
// scrolls: the rows laid out are a window of `_window` rows, stepped down a
// screen (`_step` rows) at a time; each step reads the pages the window is
// drawn from and keeps only the pages `pagesFor` names. After that the folder
// is jumped into at its middle and at its end, which no neighbour page can
// serve: the OFFSET path.
//
// Same shape as the other benchmarks (AGENTS.md): the numbers are printed;
// what is not a timing — the pages and rows held — gates on any host; the
// timings assert a backstop, and the design's bar only under `NIMAN_PERF=1`.
// The heap gates only where it is read exact, with the VM service: the
// resident set it falls back to read from -62 MB to +46 MB for the same
// scroll, and in a full suite it counts what the other files allocate, so it
// says nothing about this one — the pages and rows held are what show the
// window there. The exact run:
// `NIMAN_PERF=1 flutter test --enable-vmservice
// test/perf/tree_window_memory_test.dart`.
//
// Sizes: 100 000 files in a normal run so it stays a few seconds; a million
// under `NIMAN_PERF=1`, or as many as `NIMAN_SCALE` says.
// ignore_for_file: avoid_print
@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/tree.dart';
import 'package:niman/src/ui/tree_pages.dart';

import 'heap_meter.dart';

/// Whether this run is the one that holds the design's bars.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The bar [ceiling] is held to: the design's under `NIMAN_PERF`, else the
/// backstop, three times as wide.
double _bar(double ceiling) => _referenceHost ? ceiling : ceiling * 3;

/// Files in the folder.
final int _files =
    int.tryParse(Platform.environment['NIMAN_SCALE'] ?? '') ??
    (_referenceHost ? 1000000 : 100000);

/// The rows the list lays out: a screen of 24-px rows and the list's cache
/// extent either side of it.
const int _window = 60;

/// How far one step of the scroll goes: a screen.
const int _step = 40;

/// What a row held in the old design cost, measured in #1193
/// (`test/perf/memory_retention_test.dart`).
const int _bytesPerRow = 697;

/// The most pages the window is held to: the two it can lie across and the
/// page either side of each.
const int _windowPages = 4;

/// The tree's order, as the app opens a library.
const TreeSort _sort = TreeSort.nameAsc;

/// The folder's path, and the id the first row inserted takes.
const String _folder = 'Big';
const int _folderId = 1;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late IndexDatabase db;
  late _IndexSession session;
  late HeapMeter meter;

  setUpAll(() async {
    meter = await HeapMeter.open();
    db = IndexDatabase(NativeDatabase.memory());
    final clock = Stopwatch()..start();
    await db.transaction(() async {
      await db.customStatement(
        'INSERT INTO notes (path, parent, name, is_dir, size, modified, '
        'created, pinned, name_key) '
        "VALUES ('$_folder', 0, '$_folder', 1, 0, 0, 0, 0, 'big')",
      );
      await db.customStatement(
        'WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM s '
        'WHERE i < $_files) '
        'INSERT INTO notes (path, parent, name, is_dir, size, modified, '
        'created, pinned, name_key, sha256) '
        "SELECT '$_folder/note number ' || i || '.md', $_folderId, "
        "'note number ' || i || '.md', 0, 4096 + i, 1790000000 + i, "
        "1780000000 + i, 0, 'note number ' || printf('%09d', i) || '.md', "
        "printf('%064x', i) FROM s",
      );
    });
    session = _IndexSession(db);
    print(
      'seeded $_files files in one folder: '
      '${clock.elapsedMilliseconds} ms',
    );
  });

  tearDownAll(() async {
    await meter.close();
    await db.close();
  });

  test('scrolling a folder to its end keeps a window of pages', () async {
    // The first reads of a connection prepare their statements and compile
    // their code, about a megabyte the heap keeps for good: it is the
    // baseline of the reading, not what the scroll holds.
    await _warmUp(session);
    late _Scroll scroll;
    final held = await meter.held(() async {
      scroll = await _scrollToTheEnd(session);
      return scroll.pages;
    }, runs: 3);

    const pageSize = NoteTree.defaultPageSize;
    final scrolledBytes = _files * _bytesPerRow;
    // A page is `pageSize` rows; the window sits in at most two pages of the
    // folder, with the page either side of each: four, and the root's page
    // while the top of the list is on screen.
    final heldMb = held / (1 << 20);
    const windowBytes = _windowPages * pageSize * _bytesPerRow;
    // The design's bar: the pages the window holds at ~700 B a row, and the
    // model with the folders' facts, a few hundred kilobytes at most.
    final bar = _referenceHost ? windowBytes + (256 << 10) : scrolledBytes ~/ 2;

    print(
      'scrolled $_files rows in ${scroll.steps} steps '
      '(${scroll.totalMs.toStringAsFixed(0)} ms): '
      'peak ${scroll.peakPages} pages / ${scroll.peakRows} rows held; '
      'at the end ${scroll.pages.pageCount} pages / '
      '${scroll.pages.held().values.fold<int>(0, (n, rows) => n + rows.length)}'
      ' rows',
    );
    print(
      'heap retained after the scroll: ${heldMb.toStringAsFixed(2)} MB '
      '(${meter.unit}; held to ${(bar / (1 << 20)).toStringAsFixed(2)} MB)',
    );
    print(
      'the old design would hold: '
      '${(scrolledBytes / (1 << 20)).toStringAsFixed(1)} '
      'MB (computed: $_files rows scrolled x $_bytesPerRow B)',
    );
    print(
      'keyset page of $pageSize rows: median '
      '${_median(scroll.pageMs).toStringAsFixed(2)} ms, max '
      '${scroll.pageMs.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)} ms '
      'over ${scroll.pageMs.length} reads',
    );
    // A keyset read should cost the same however far down the folder it is:
    // the first tenth of the reads against the last tenth (printed, not
    // gated: see the record's phase 5).
    final tenth = scroll.pageMs.length ~/ 10;
    if (tenth > 0) {
      final top = _median(scroll.pageMs.sublist(0, tenth));
      final deep = _median(scroll.pageMs.sublist(scroll.pageMs.length - tenth));
      print(
        'keyset page by depth: first tenth of the folder median '
        '${top.toStringAsFixed(2)} ms, last tenth median '
        '${deep.toStringAsFixed(2)} ms',
      );
    }

    // Not a timing: what is held follows the window on any host.
    expect(scroll.peakPages, lessThanOrEqualTo(_windowPages));
    expect(scroll.peakRows, lessThanOrEqualTo(_windowPages * pageSize));
    expect(scroll.pages.pageCount, lessThanOrEqualTo(3));
    if (meter.exact) expect(held, lessThan(bar));
    expect(_median(scroll.pageMs), lessThan(_bar(200)));
  });

  test('a jump to the middle and the end reads by position', () async {
    const pageSize = NoteTree.defaultPageSize;
    final pages = TreePages(pageSize: pageSize);
    final tree = await pages.visible(session, const {_folder}, _sort);
    final last = (_files - 1) ~/ pageSize;
    final middle = last ~/ 2;

    Future<double> jump(int page) async {
      final clock = Stopwatch()..start();
      final added = await pages.load(session, _folderId, page, _sort);
      expect(added, isTrue);
      final ms = clock.elapsedMicroseconds / 1000;
      // What the widget does after the page lands: only the window stays.
      final at = 1 + page * pageSize;
      pages.keepOnly(pages.pagesFor(tree, at, at + _window - 1));
      return ms;
    }

    // The first read of a connection prepares the statement: not the jump.
    await jump(1);
    final toMiddle = await jump(middle);
    final toEnd = await jump(last);
    final rows = pages.held().values.fold<int>(0, (n, page) => n + page.length);
    print(
      'jump by position in a $_files-file folder: middle (offset '
      '${middle * pageSize}) ${toMiddle.toStringAsFixed(1)} ms, end (offset '
      '${last * pageSize}) ${toEnd.toStringAsFixed(1)} ms; after them '
      '${pages.pageCount} pages / $rows rows held',
    );

    expect(pages.pageCount, lessThanOrEqualTo(3));
    expect(rows, lessThanOrEqualTo(3 * pageSize));
    expect(toMiddle, lessThan(_bar(1000)));
    expect(toEnd, lessThan(_bar(1000)));
  });

  test('the model of the folder costs counts, not rows', () async {
    final pages = TreePages(pageSize: NoteTree.defaultPageSize);
    final clock = Stopwatch()..start();
    final tree = await pages.visible(session, const {_folder}, _sort);
    final coldMs = clock.elapsedMicroseconds / 1000;
    expect(tree.length, _files + 1);

    // A revision of the folder forgets its count: the next model counts again.
    final recount = <double>[];
    for (var run = 0; run < 5; run++) {
      pages.forget(const [_folderId]);
      clock
        ..reset()
        ..start();
      await pages.visible(session, const {_folder}, _sort);
      recount.add(clock.elapsedMicroseconds / 1000);
    }
    clock
      ..reset()
      ..start();
    await pages.visible(session, const {_folder}, _sort);
    final warmMs = clock.elapsedMicroseconds / 1000;
    print(
      'visible() over a $_files-file folder: first '
      '${coldMs.toStringAsFixed(1)} ms, after a revision of the folder '
      '(count again) median ${_median(recount).toStringAsFixed(1)} ms, with '
      'the facts held ${warmMs.toStringAsFixed(2)} ms',
    );

    expect(_median(recount), lessThan(_bar(150)));
    expect(warmMs, lessThan(_bar(20)));
  });
}

/// What a scroll left, and what it took.
typedef _Scroll = ({
  TreePages pages,
  int steps,
  double totalMs,
  int peakPages,
  int peakRows,
  List<double> pageMs,
});

/// Scrolls the list of the open folder from its top to its end, the way
/// `NoteTree` keeps its pages: each step reads the pages the window is drawn
/// from (`drawnPages`), then keeps only what `pagesFor` names.
Future<_Scroll> _scrollToTheEnd(LibrarySession session) async {
  final pages = TreePages(pageSize: NoteTree.defaultPageSize);
  final tree = await pages.visible(session, const {_folder}, _sort);
  final pageMs = <double>[];
  var peakPages = 0;
  var peakRows = 0;
  var steps = 0;
  final clock = Stopwatch()..start();
  final read = Stopwatch();
  for (var first = 0; first < tree.length; first += _step) {
    final end = first + _window - 1;
    for (final (parent, page) in pages.drawnPages(tree, first, end)) {
      read
        ..reset()
        ..start();
      final added = await pages.load(session, parent, page, _sort);
      // Page 0 of a folder is the one read by position (offset 0).
      if (added && page > 0) pageMs.add(read.elapsedMicroseconds / 1000);
    }
    final rows = pages.held().values.fold<int>(0, (n, page) => n + page.length);
    if (pages.pageCount > peakPages) peakPages = pages.pageCount;
    if (rows > peakRows) peakRows = rows;
    pages.keepOnly(pages.pagesFor(tree, first, end));
    steps++;
  }
  final totalMs = clock.elapsedMicroseconds / 1000;
  return (
    pages: pages,
    steps: steps,
    totalMs: totalMs,
    peakPages: peakPages,
    peakRows: peakRows,
    pageMs: pageMs,
  );
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  return sorted[sorted.length ~/ 2];
}

/// The reads `TreePages` makes of a session, answered from the index by the
/// [NoteDao] the library controller uses; anything else is not asked.
final class _IndexSession implements LibrarySession, NoteOperations {
  new(IndexDatabase db) : _dao = NoteDao(db);

  final NoteDao _dao;

  @override
  NoteOperations? get ops => this;

  @override
  Future<Note?> find(String path) => _dao.find(path);

  @override
  Future<int> childCount(int parentId) => _dao.childCount(parentId);

  @override
  Future<int> rankOf(Note note, {TreeSort sort = TreeSort.nameAsc}) =>
      _dao.rankOf(note, sort: sort);

  @override
  Future<List<Note>> childrenPage(
    int parentId, {
    required int limit,
    TreeSort sort = TreeSort.nameAsc,
    Note? after,
    Note? before,
  }) => _dao.childrenPage(
    parentId,
    limit: limit,
    sort: sort,
    after: after,
    before: before,
  );

  @override
  Future<List<Note>> childrenAt(
    int parentId, {
    required int offset,
    required int limit,
    TreeSort sort = TreeSort.nameAsc,
  }) => _dao.childrenAt(parentId, offset: offset, limit: limit, sort: sort);

  @override
  Future<Note?> firstChildStartingWith(
    int parentId,
    String foldedPrefix, {
    TreeSort sort = TreeSort.nameAsc,
    Note? after,
  }) => _dao.firstChildStartingWith(
    parentId,
    foldedPrefix,
    sort: sort,
    after: after,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not answered');
}

/// Reads once every kind of page the scroll and the jumps read, and lets the
/// pages go: the statements and the code they need stay prepared.
Future<void> _warmUp(LibrarySession session) async {
  const size = NoteTree.defaultPageSize;
  final pages = TreePages(pageSize: size);
  await pages.visible(session, const {_folder}, _sort);
  await pages.load(session, _folderId, 1, _sort); // by position
  await pages.load(session, _folderId, 2, _sort); // after a neighbour
  await pages.load(session, _folderId, 4, _sort); // by position again
  pages.keepOnly(const {(_folderId, 4)});
  await pages.load(session, _folderId, 3, _sort); // before a neighbour
}
