// Placement choices (round 2, R1): consume-once reads over a mocked
// host channel.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/widget/widget_placement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// The mocked widget storage; the test seeds it directly.
  late Map<String, Object> store;

  setUp(() {
    store = {};
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map<Object?, Object?>;
      final id = args['id']! as String;
      if (call.method == 'saveWidgetData') {
        final data = args['data'];
        if (data == null) {
          store.remove(id);
        } else {
          store[id] = data;
        }
        return true;
      }
      if (call.method == 'getWidgetData') return store[id];
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  const placement = PlatformWidgetPlacementStore();

  test('a todo choice reads once with its library', () async {
    store['todo_7_config'] = jsonEncode({'library': '/lib/Work'});
    expect(await placement.consumeTodoConfig(7), (library: '/lib/Work'));
    expect(await placement.consumeTodoConfig(7), isNull);
  });

  test('a note choice needs library and note', () async {
    store['note_8_config'] = jsonEncode({'note': 'Todo.md'});
    expect(await placement.consumeNoteConfig(8), isNull);

    store['note_8_config'] = jsonEncode({
      'library': '/lib/Work',
      'note': 'Todo.md',
    });
    expect(await placement.consumeNoteConfig(8), (
      library: '/lib/Work',
      note: 'Todo.md',
    ));
    expect(await placement.consumeNoteConfig(8), isNull);
  });

  test('malformed choices read as absent', () async {
    store['todo_9_config'] = 'not json';
    expect(await placement.consumeTodoConfig(9), isNull);
  });
}
