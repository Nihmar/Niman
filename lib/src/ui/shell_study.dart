import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/deck_catalog_controller.dart';
import 'package:niman/src/flashcards/library_decks.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_study.dart';
import 'package:niman/src/ui/kinds/flashcards/review_run.dart';
import 'package:niman/src/ui/kinds/flashcards/review_tab.dart';
import 'package:niman/src/ui/kinds/flashcards/review_view.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/study/study_view.dart';
import 'package:path/path.dart' as p;

/// The shell's Study (#533): the library's decks, counted; the Study tree;
/// and the study beside the deck, its chip and its page.
final class ShellStudy {
  /// Study over [controller]'s library, its tab in [reviewTab].
  new({
    required this.controller,
    required this.reviewTab,
    required this.workspace,
    required this.read,
    required this.onCounted,
    required this.showNote,
    required this.openDeck,
    required this.newDeck,
    required this.mounted,
  });

  /// The open library.
  final LibrarySession controller;

  /// The study beside the deck (decision 9).
  final ReviewTab reviewTab;

  /// The panes the study and its deck sit in.
  final ShellWorkspace workspace;

  /// How the study reads its providers.
  final ProviderRead read;

  /// Every count of the decks: the Study widgets on the home screen follow.
  final VoidCallback onCounted;

  /// Opens a note (library-relative) in the focused pane.
  final void Function(String path) showNote;

  /// Opens a deck from the Study tree, as a note of the tree opens.
  final void Function(String path) openDeck;

  /// Makes a new deck.
  final VoidCallback newDeck;

  /// Whether the shell is still up.
  final bool Function() mounted;

  DeckCatalogController? _catalog;

  /// The decks of the library, counted: read on Study's first visit, kept
  /// while the shell lives.
  DeckCatalogController? get decks {
    if (_catalog case final catalog?) return catalog;
    final catalog = deckCatalogOf(controller);
    if (catalog != null) {
      // Every count reaches the Study widgets, the first one included.
      catalog.addListener(onCounted);
      unawaited(catalog.refresh());
    }
    return _catalog = catalog;
  }

  /// The decks' due counts again, when they have been read at all: the day
  /// may have turned while the app was away.
  void refreshStates() => unawaited(_catalog?.refreshStates());

  /// Lets go of the decks.
  void dispose() => _catalog?.dispose();

  /// The study's chip at the end of [pane]'s row.
  Widget chip(int pane, {required bool selected}) {
    final w = workspace.value;
    return ReviewTabChip(
      title: reviewTab.run!.title,
      selected: selected,
      focused: !w.isSplit || w.focused == pane,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        reviewTab.show();
      },
      onClose: reviewTab.close,
    );
  }

  /// The study's page, in its pane, over the notes.
  Widget page() {
    final run = reviewTab.run!;
    return ReviewView(
      key: ObjectKey(run),
      run: run,
      onClose: reviewTab.close,
      onNextDeck: (path) => unawaited(_nextDeck(path)),
    );
  }

  /// **Next deck**: the deck at library-relative [path] opens where the
  /// last one was, and its study takes the last one's place.
  Future<void> _nextDeck(String path) async {
    final root = controller.root;
    if (root == null) return;
    final run = await loadReviewRun(
      session: controller,
      reviews: read(deckReviewSourceProvider),
      paths: [p.join(root, path)],
    );
    if (!mounted() || run == null) return;
    final pane = reviewTab.pane;
    final w = workspace.value;
    // Beside the study, the deck shows; over it, it would cover the study.
    if (w.isSplit && pane != null) {
      workspace.focus(1 - pane);
      showNote(path);
    }
    reviewTab.open(run, pane: pane);
  }

  /// Studies the decks at [paths], library-relative, under [title].
  void studyPaths(BuildContext context, List<String> paths, String title) {
    final root = controller.root;
    if (root == null) return;
    unawaited(
      studyDecks(context, read, [
        for (final path in paths) p.join(root, path),
      ], title: title),
    );
  }

  /// The Study tree: the left island's on a wide window, the destination's
  /// body on a phone. One view, built where it shows.
  Widget view(BuildContext context) {
    final catalog = decks;
    if (catalog == null) return const SizedBox.shrink();
    return StudyView(
      key: const Key('study-view'),
      controller: catalog,
      // A deck opens as a note of the tree does: in place of the tab's,
      // in a tab of its own on a double click.
      onOpenDeck: openDeck,
      onStudy: (paths, title) => studyPaths(context, paths, title),
      onNewDeck: newDeck,
    );
  }
}
