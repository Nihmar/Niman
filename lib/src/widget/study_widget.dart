/// The Niman Study home-screen widget (#533, mockup P8): the decks with
/// cards to study today, grouped by their `deck:`.
///
/// Android only, like the other widgets. Dart counts the decks and pushes
/// the rows; the native provider renders them and a tap comes back as a
/// target: a deck row opens its note, the header opens Study.
library;

import 'dart:convert';

import 'package:niman/src/flashcards/deck_summary.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_host.dart';
import 'package:niman/src/widget/widget_placement.dart';
import 'package:niman/src/widget/widget_reconcile.dart';
import 'package:niman/src/widget/widget_theme.dart';
import 'package:niman/src/widget/widget_updater.dart';

/// The Study rows as JSON: `{"library": path, "total": cards today,
/// "rows": [...]}`, a row being a group — `{"kind": "group", "text":
/// "Lingue › Inglese"}`, the text empty for **No category**, which the
/// provider names in the phone's language — or a deck — `{"kind": "deck",
/// "name", "path", "due", "new"}`.
///
/// Only the decks with cards today, grouped by category, the groups and
/// the decks in each alphabetically, **No category** last.
String studyWidgetPayload(
  List<DeckSummary> decks, {
  required String libraryPath,
  WidgetTheme? theme,
}) {
  final groups = <String, List<DeckSummary>>{};
  for (final deck in decks) {
    if (deck.toStudy == 0) continue;
    (groups[deck.category.join(' › ')] ??= []).add(deck);
  }
  final names = groups.keys.toList()
    ..sort((a, b) {
      if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
  var total = 0;
  final rows = <Map<String, Object?>>[];
  for (final name in names) {
    rows.add({'kind': 'group', 'text': name});
    final inGroup = groups[name]!
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final deck in inGroup) {
      total += deck.toStudy;
      rows.add({
        'kind': 'deck',
        'name': deck.name,
        'path': deck.path,
        'due': deck.due,
        'new': deck.newAvailable,
      });
    }
  }
  return jsonEncode({
    'library': libraryPath,
    'total': total,
    'rows': rows,
    if (theme != null) 'theme': widgetThemeToMap(theme),
  });
}

/// Pushes the decks to every Study widget configured for the session's
/// library; a placed instance it does not know yet is adopted, as the
/// task list's widgets are (`refreshTodoWidgets`).
///
/// [decks] is asked only when a Study widget is there to show them, so a
/// library without one never counts its decks for it; null while they are
/// not counted yet, which pushes nothing.
Future<void> refreshStudyWidgets({
  required LibrarySession session,
  required Future<List<DeckSummary>?> Function() decks,
  WidgetUpdater? updater,
  WidgetHostService? host,
  WidgetPlacementStore? placement,
}) async {
  final root = session.root;
  if (root == null) return;
  final ids = await reconcilePlacedWidgets(
    session: session,
    root: root,
    provider: WidgetProvider.study,
    placed: host?.studyWidgetIds,
    chosenLibrary: (id) async =>
        (await placement?.consumeStudyConfig(id))?.library,
    adopt: session.adoptStudyWidget,
  );
  if (ids.isEmpty) return;
  final counted = await decks();
  if (counted == null) return;
  final payload = studyWidgetPayload(
    counted,
    libraryPath: root,
    theme: resolveWidgetTheme(),
  );
  await pushToWidgets(
    provider: WidgetProvider.study,
    ids: ids,
    payload: payload,
    updater: updater,
  );
}
