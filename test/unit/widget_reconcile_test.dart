// What every provider's widget refresh shares (#952): adopt the placed
// instances the library does not know, prune the removed ones, push one
// payload to those left. Run for the task list's provider and the Study's.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_reconcile.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  for (final provider in [WidgetProvider.todo, WidgetProvider.study]) {
    group('reconcile ${provider.name} widgets', () {
      late FakeLibrarySession session;
      final root = p.join('/fake', 'Work');
      final other = p.join('/fake', 'Other');
      late Map<int, String?> chosen;

      setUp(() async {
        session = FakeLibrarySession();
        chosen = {};
        await session.open(root, create: false);
      });

      Future<List<int>> reconcile(List<int>? placed) => reconcilePlacedWidgets(
        session: session,
        root: root,
        provider: provider,
        placed: placed == null ? null : () async => placed,
        chosenLibrary: (id) async => chosen.remove(id),
        adopt: provider == WidgetProvider.todo
            ? session.adoptTodoWidget
            : session.adoptStudyWidget,
      );

      void seed(int id, {WidgetProvider? of}) => session.seedWidgetConfig(
        androidWidgetId: id,
        provider: (of ?? provider).name,
        libraryPath: root,
      );

      test('without a host it adopts and prunes nothing', () async {
        seed(3);
        expect(await reconcile(null), [3]);
        expect(await session.widgetConfigsFor(root), hasLength(1));
      });

      test('adopts a placed instance into the open library', () async {
        expect(await reconcile([9]), [9]);
        final config = (await session.widgetConfigsFor(root)).single;
        expect(config.provider, provider.name);
        expect(config.libraryPath, root);
      });

      test('adopts into the library its config screen chose', () async {
        chosen[9] = other;
        await reconcile([9]);
        expect(await session.widgetConfigsFor(root), isEmpty);
        expect(
          (await session.widgetConfigsFor(other)).single.androidWidgetId,
          9,
        );
      });

      test('an empty choice is the open library', () async {
        chosen[9] = '';
        expect(await reconcile([9]), [9]);
      });

      test('does not ask the choice of an instance it knows', () async {
        seed(4);
        chosen[4] = other;
        expect(await reconcile([4]), [4]);
        expect(chosen, {4: other});
      });

      test('prunes the instances the launcher no longer has', () async {
        seed(1);
        seed(2);
        expect(await reconcile([2]), [2]);
        expect(
          (await session.widgetConfigsFor(root)).map((c) => c.androidWidgetId),
          [2],
        );
      });

      test('prunes only its own provider', () async {
        final mine = provider;
        final theirs = mine == WidgetProvider.todo
            ? WidgetProvider.study
            : WidgetProvider.todo;
        seed(1);
        seed(8, of: theirs);
        expect(await reconcile([1]), [1]);
        expect(
          (await session.widgetConfigsFor(root)).map((c) => c.provider),
          containsAll([mine.name, theirs.name]),
        );
      });

      test('pushes the payload to each instance', () async {
        final saves = <(String, String?)>[];
        await pushToWidgets(
          provider: provider,
          ids: [5, 6],
          payload: '{"x":1}',
          updater: WidgetUpdater(
            saveData: (id, data) async {
              saves.add((id, data));
              return true;
            },
            updateWidgets: ({
              required androidName,
              required qualifiedAndroidName,
            }) async => true,
          ),
        );
        expect(saves, [
          ('${provider.name}_5', '{"x":1}'),
          ('${provider.name}_6', '{"x":1}'),
        ]);
      });
    });
  }
}
