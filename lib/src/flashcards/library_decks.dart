/// The decks of the open library (#533): the catalog controller wired to a
/// library session, the way the Study screens get it.
library;

import 'package:niman/src/flashcards/deck_catalog.dart';
import 'package:niman/src/flashcards/deck_catalog_controller.dart';
import 'package:niman/src/library/session.dart';

/// A controller over the decks of the library [session] has open, listening
/// to its index and to what a sync writes locally; null while it is closed.
/// The caller owns it and disposes it. It reads nothing until
/// [DeckCatalogController.refresh].
DeckCatalogController? deckCatalogOf(LibrarySession session) {
  final root = session.root;
  if (root == null) return null;
  return DeckCatalogController(
    catalog: DeckCatalog(
      root: root,
      find: () async {
        final fields = await session.fieldSource;
        return fields == null ? const <String>[] : await findDeckPaths(fields);
      },
    ),
    settings: () async => (
      newPerDay: await session.newCardsPerDay,
      dayStartHour: (await session.ops?.journal)?.dayStartHour ?? 0,
    ),
    indexEvents: session.events,
    syncChanges: session.sync?.localChanges,
  );
}
