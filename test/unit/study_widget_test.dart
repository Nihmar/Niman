// #533: the Niman Study widget — the decks with cards today, grouped by
// deck:, pushed only to the Study widgets of the open library, and the
// decks counted only when one is there.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/deck_summary.dart';
import 'package:niman/src/widget/study_widget.dart';
import 'package:niman/src/widget/widget_target.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_widget_host_service.dart';
import '../fakes/fake_widget_placement_store.dart';

DeckSummary _deck(
  String path,
  List<String> category, {
  int due = 0,
  int fresh = 0,
}) => DeckSummary(
  path: path,
  name: p.posix.basenameWithoutExtension(path),
  category: category,
  tags: const [],
  total: due + fresh,
  due: due,
  fresh: fresh,
  newAvailable: fresh,
);

void main() {
  test('the payload: decks with cards today, by category, none last', () {
    final payload = jsonDecode(
      studyWidgetPayload([
        _deck('Loose.md', [], due: 1),
        _deck('Nouns.md', ['Lingue', 'Tedesco'], fresh: 2),
        _deck('Done.md', ['Lingue', 'Tedesco']),
        _deck('Verbs.md', ['Lingue', 'Inglese'], due: 3, fresh: 1),
      ], libraryPath: '/lib'),
    ) as Map<String, Object?>;
    expect(payload['library'], '/lib');
    expect(payload['total'], 7);
    expect(payload['rows'], [
      {'kind': 'group', 'text': 'Lingue › Inglese'},
      {'kind': 'deck', 'name': 'Verbs', 'path': 'Verbs.md', 'due': 3, 'new': 1},
      {'kind': 'group', 'text': 'Lingue › Tedesco'},
      {'kind': 'deck', 'name': 'Nouns', 'path': 'Nouns.md', 'due': 0, 'new': 2},
      {'kind': 'group', 'text': ''},
      {'kind': 'deck', 'name': 'Loose', 'path': 'Loose.md', 'due': 1, 'new': 0},
    ]);
  });

  group('refresh', () {
    late FakeLibrarySession session;
    late List<(String, String?)> saves;
    late int asked;
    final root = p.join('/fake', 'Work');

    WidgetUpdater recorder() => WidgetUpdater(
      saveData: (id, data) async {
        saves.add((id, data));
        return true;
      },
      updateWidgets: ({
        required androidName,
        required qualifiedAndroidName,
      }) async => true,
    );

    Future<List<DeckSummary>?> decks() async {
      asked++;
      return [_deck('Verbs.md', [], due: 2)];
    }

    setUp(() async {
      session = FakeLibrarySession();
      saves = [];
      asked = 0;
      await session.open(root, create: false);
    });

    test('without a Study widget the decks are not even counted', () async {
      session.seedWidgetConfig(
        androidWidgetId: 7,
        provider: 'todo',
        libraryPath: root,
      );
      await refreshStudyWidgets(
        session: session,
        decks: decks,
        updater: recorder(),
        host: FakeWidgetHostService(),
      );
      expect(asked, 0);
      expect(saves, isEmpty);
    });

    test('a placed Study widget is adopted and gets the decks', () async {
      final host = FakeWidgetHostService()..studyIds = [9];
      await refreshStudyWidgets(
        session: session,
        decks: decks,
        updater: recorder(),
        host: host,
        placement: FakeWidgetPlacementStore(),
      );
      expect(asked, 1);
      expect(saves.single.$1, 'study_9');
      final payload = jsonDecode(saves.single.$2!) as Map<String, Object?>;
      expect(payload['total'], 2);
    });

    test('decks not counted yet push nothing', () async {
      session.seedWidgetConfig(
        androidWidgetId: 9,
        provider: 'study',
        libraryPath: root,
      );
      await refreshStudyWidgets(
        session: session,
        decks: () async => null,
        updater: recorder(),
      );
      expect(saves, isEmpty);
    });
  });

  test('a tap on the header is a Study target', () {
    final target = WidgetTarget.fromMap({
      'kind': 'study',
      'libraryPath': '/lib',
    });
    expect(target?.kind, WidgetTargetKind.study);
  });
}
