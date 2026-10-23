// A [WikilinkSuggester] a widget test drives by hand (#475): the rows the
// panel lists, in the order the library would rank them, and the headings a
// named note answers with.
import 'dart:async';

import 'package:niman/src/links/suggester.dart';
import 'package:path/path.dart' as p;

/// A canned [WikilinkSuggester] for the panel's widget tests.
final class FakeWikilinkSuggester implements WikilinkSuggester {
  /// Creates a suggester over canned rows.
  new({
    List<NoteSuggestion>? notes,
    Map<String, List<HeadingSuggestion>>? headings,
    Map<String, List<BlockIdSuggestion>>? blocks,
    this.acrossHeadings = const <HeadingSuggestion>[],
    this.acrossBlocks = const <BlockIdSuggestion>[],
    this.places = const <BookSuggestion>[],
    this.attachments = const <NoteSuggestion>[],
  }) : _notes = notes ?? const <NoteSuggestion>[],
       _headings = headings ?? const <String, List<HeadingSuggestion>>{},
       _blocks = blocks ?? const <String, List<BlockIdSuggestion>>{};

  final List<NoteSuggestion> _notes;
  final Map<String, List<HeadingSuggestion>> _headings;
  final Map<String, List<BlockIdSuggestion>> _blocks;

  /// The rows a `[[##` search answers with (each says which note it is in).
  final List<HeadingSuggestion> acrossHeadings;

  /// The rows a `[[^^` search answers with.
  final List<BlockIdSuggestion> acrossBlocks;

  /// Every block target the panel asked for, in order.
  final List<String> blockTargets = <String>[];

  /// Every `[[##` query the panel asked for, in order.
  final List<String> headingSearches = <String>[];

  /// Every `[[^^` query the panel asked for, in order.
  final List<String> blockSearches = <String>[];

  /// The book forms a `#` on a PDF/EPUB answers with.
  final List<BookSuggestion> places;

  /// Every note query the panel asked for, in order.
  final List<String> noteQueries = <String>[];

  /// Every heading target the panel asked for, in order.
  final List<String> headingTargets = <String>[];

  /// While true, every answer waits for [release]: a test can press a key
  /// while a query is still on its way, as a slow index or a slow read of a
  /// note has it.
  bool holding = false;

  final List<Completer<void>> _held = <Completer<void>>[];

  /// Lets every answer held so far through, and holds no more.
  void release() {
    holding = false;
    for (final answer in _held) {
      answer.complete();
    }
    _held.clear();
  }

  /// Returns at once, or — while [holding] — once [release] is called.
  Future<void> _answer() {
    if (!holding) return Future<void>.value();
    final answer = Completer<void>();
    _held.add(answer);
    return answer.future;
  }

  @override
  Future<List<NoteSuggestion>> notes(String query) async {
    noteQueries.add(query);
    await _answer();
    // A word the fake does not know matches nothing, so a test can ask for
    // the empty state without an empty library.
    if (query.isNotEmpty && query.toLowerCase().contains('zzz')) {
      return const <NoteSuggestion>[];
    }
    if (query.isEmpty) return _notes;
    final q = query.toLowerCase();
    final prefix = <NoteSuggestion>[];
    final within = <NoteSuggestion>[];
    for (final note in _notes) {
      if (note.name.toLowerCase().startsWith(q)) {
        prefix.add(note);
      } else if (note.name.toLowerCase().contains(q) ||
          (note.alias?.toLowerCase().startsWith(q) ?? false)) {
        within.add(note);
      }
    }
    return <NoteSuggestion>[...prefix, ...within];
  }

  /// The rows an `![[` embed lists (#705), before the notes.
  final List<NoteSuggestion> attachments;

  /// Every embed query the panel asked for, in order.
  final List<String> embedQueries = <String>[];

  @override
  Future<List<NoteSuggestion>> embeds(String query) async {
    embedQueries.add(query);
    await _answer();
    final q = query.toLowerCase();
    return <NoteSuggestion>[
      for (final file in attachments)
        if (file.name.toLowerCase().contains(q)) file,
      ...await notes(query),
    ];
  }

  @override
  Future<String> targetOf(String path) async {
    // A target is made from the library-relative path, as the real one is.
    if (p.isAbsolute(path)) throw ArgumentError.value(path, 'path');
    final name = path.split('/').last;
    return name.toLowerCase().endsWith('.md')
        ? name.substring(0, name.length - 3)
        : name;
  }

  @override
  Future<List<HeadingSuggestion>> headings(String target) async {
    headingTargets.add(target);
    await _answer();
    return _headings[target] ?? const <HeadingSuggestion>[];
  }

  @override
  Future<List<BlockIdSuggestion>> blocks(String target) async {
    blockTargets.add(target);
    await _answer();
    return _blocks[target] ?? const <BlockIdSuggestion>[];
  }

  @override
  Future<List<HeadingSuggestion>> headingsAcross(String query) async {
    headingSearches.add(query);
    await _answer();
    final q = query.toLowerCase();
    return <HeadingSuggestion>[
      for (final row in acrossHeadings)
        if (row.heading.toLowerCase().contains(q)) row,
    ];
  }

  @override
  Future<List<BlockIdSuggestion>> blocksAcross(String query) async {
    blockSearches.add(query);
    await _answer();
    final q = query.toLowerCase();
    return <BlockIdSuggestion>[
      for (final row in acrossBlocks)
        if ('${row.id} ${row.excerpt}'.toLowerCase().contains(q)) row,
    ];
  }

  @override
  Future<List<BookSuggestion>> bookPlaces(String target) async {
    await _answer();
    return places;
  }
}
