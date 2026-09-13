// Widget pusher (issue 6): per-instance keys, provider refresh and push
// serialization, over fake platform calls.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_updater.dart';

void main() {
  late List<(String, String?)> saves;
  late List<(String, String)> updates;

  WidgetUpdater updater() {
    return WidgetUpdater(
      saveData: (id, data) async {
        saves.add((id, data));
        return true;
      },
      updateWidgets:
          ({required androidName, required qualifiedAndroidName}) async {
            updates.add((androidName, qualifiedAndroidName));
            return true;
          },
    );
  }

  setUp(() {
    saves = [];
    updates = [];
  });

  test('a push saves under the instance key and refreshes', () async {
    await updater().push(
      provider: WidgetProvider.todo,
      androidWidgetId: 7,
      payload: '{"rows":[]}',
    );
    expect(saves, [('todo_7', '{"rows":[]}')]);
    expect(updates, [
      ('TodoWidgetProvider', 'dev.niman.niman.TodoWidgetProvider'),
    ]);
  });

  test('a clear saves null and refreshes', () async {
    await updater().clear(provider: WidgetProvider.note, androidWidgetId: 8);
    expect(saves, [('note_8', null)]);
    expect(updates.single.$1, 'NoteWidgetProvider');
  });

  test('concurrent pushes serialize with the newest winning', () async {
    final gate = Completer<void>();
    var calls = 0;
    final gated = WidgetUpdater(
      saveData: (id, data) async {
        calls++;
        if (calls == 1) await gate.future;
        saves.add((id, data));
        return true;
      },
      updateWidgets:
          ({required androidName, required qualifiedAndroidName}) async {
            return true;
          },
    );

    final first = gated.push(
      provider: WidgetProvider.todo,
      androidWidgetId: 7,
      payload: 'old',
    );
    // Lands while the first save is gated: replaces rather than races.
    final second = gated.push(
      provider: WidgetProvider.todo,
      androidWidgetId: 7,
      payload: 'new',
    );
    gate.complete();
    await Future.wait([first, second]);

    expect(saves, [('todo_7', 'old'), ('todo_7', 'new')]);
  });
}
