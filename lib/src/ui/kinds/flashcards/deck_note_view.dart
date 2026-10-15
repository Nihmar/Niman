import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/deck_meta.dart';
import 'package:niman/src/flashcards/deck_reading.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/study_day.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_edits.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_phone_view.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_study.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_wide_view.dart';
import 'package:niman/src/ui/kinds/flashcards/review_tab.dart';

/// The flashcard kind's body (#533): the deck the note is — its counts, its
/// cards with when each comes back — in the shape of the surface, and the
/// card edits that rewrite the note.
final class DeckNoteView extends ConsumerStatefulWidget {
  /// Shows the deck of [text], the note [host] holds.
  const new({required this.text, required this.host, super.key});

  /// The full note text.
  final String text;

  /// The note's window: its text, its edits, its path.
  final NoteKindHost host;

  @override
  ConsumerState<DeckNoteView> createState() => _DeckNoteViewState();
}

final class _DeckNoteViewState extends ConsumerState<DeckNoteView> {
  Deck _deck = const Deck(meta: DeckMeta(), cards: []);
  Map<String, ReviewState> _states = const {};
  DateTime _today = studyToday(DateTime.now(), 0);
  int _newPerDay = 20;
  final MathCache _math = MathCache();
  StreamSubscription<String>? _changes;

  /// Bumped by every read: one that lands after a later one is dropped.
  int _reads = 0;

  @override
  void initState() {
    super.initState();
    _read(widget.text);
    unawaited(_readStates());
    unawaited(_readSettings());
    _changes = ref.read(deckReviewSourceProvider).changes.listen((root) {
      if (root == widget.host.libraryRoot) unawaited(_readStates());
    });
  }

  @override
  void didUpdateWidget(covariant DeckNoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _read(widget.text);
    if (oldWidget.host.notePath != widget.host.notePath) {
      unawaited(_readStates());
    }
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    _math.dispose();
    super.dispose();
  }

  void _read(String text) {
    final at = ++_reads;
    final read = Deck.readOffUi(text);
    if (read is Deck) {
      _deck = read;
      return;
    }
    unawaited(
      read.then((deck) {
        if (!mounted || at != _reads) return;
        setState(() => _deck = deck);
      }),
    );
  }

  /// The note's path in the library, or null outside one.
  String? get _path {
    final root = widget.host.libraryRoot;
    return root == null ? null : pathInLibrary(root, widget.host.notePath);
  }

  Future<void> _readStates() async {
    final root = widget.host.libraryRoot;
    final path = _path;
    if (root == null || path == null) return;
    final states = await ref.read(deckReviewSourceProvider).read(root, path);
    if (!mounted) return;
    setState(() => _states = states);
  }

  Future<void> _readSettings() async {
    try {
      final session = ref.read(librarySessionProvider);
      final perDay = await session.newCardsPerDay;
      final dayStart = (await session.ops?.journal)?.dayStartHour ?? 0;
      if (!mounted) return;
      setState(() {
        _newPerDay = perDay;
        _today = studyToday(DateTime.now(), dayStart);
      });
    } on Object {
      // No library session (an isolated view): the defaults stand.
    }
  }

  VoidCallback? _study(BuildContext context) {
    final starter = ref.watch(deckStudyStarterProvider);
    if (starter == null) return null;
    return () => unawaited(starter(context, widget.host.notePath));
  }

  @override
  Widget build(BuildContext context) {
    final reading = DeckReading(
      deck: _deck,
      path: _path ?? widget.host.notePath,
      states: _states,
      today: _today,
      newPerDay: _newPerDay,
    );
    final edits = DeckCardEdits(widget.host);
    final onStudy = _study(context);
    if (!isWideShell(context)) {
      return DeckPhoneView(
        reading: reading,
        edits: edits,
        mathCache: _math,
        onStudy: onStudy,
      );
    }
    final tab = ref.watch(reviewTabProvider);
    // The card the study beside the deck asks is marked in the list.
    return ListenableBuilder(
      listenable: tab,
      builder: (context, _) => ListenableBuilder(
        listenable: tab.run ?? tab,
        builder: (context, _) {
          final run = tab.run;
          final current = run?.session.current;
          return DeckWideView(
            reading: reading,
            edits: edits,
            mathCache: _math,
            onStudy: onStudy,
            studying: current?.deckPath == _path ? current?.card.key : null,
            studied:
                run?.session.decks.any((deck) => deck.path == _path) ?? false,
          );
        },
      ),
    );
  }
}
