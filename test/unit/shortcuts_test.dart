// T-SC-01/02/09: the shortcut ids, the publish payload and the incoming
// tap, over a mocked host channel.
import 'package:copist/src/core/shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('copist/shortcuts');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late String? launchId;

  setUp(() {
    calls = <MethodCall>[];
    launchId = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'consumeLaunchAction' ? launchId : null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('ids round-trip; an unknown one is not an action', () {
    for (final action in ShortcutAction.values) {
      expect(ShortcutAction.fromId(action.id), action);
    }
    expect(ShortcutAction.fromId('new_planet'), isNull);
    expect(ShortcutAction.fromId(null), isNull);
  });

  test('publish sends id/label pairs in order', () async {
    final service = PlatformShortcutService();
    await service.publish(const {
      ShortcutAction.quickNote: 'Quick note',
      ShortcutAction.newList: 'New list',
    });

    expect(calls.single.method, 'publish');
    expect(calls.single.arguments, [
      {'id': 'quick_note', 'label': 'Quick note'},
      {'id': 'new_list', 'label': 'New list'},
    ]);
    await service.dispose();
  });

  test('the launch action is the host id, and only comes once', () async {
    launchId = 'new_todo';
    final service = PlatformShortcutService();
    expect(await service.consumeLaunchAction(), ShortcutAction.newTodo);

    // The host clears it after the first read.
    launchId = null;
    expect(await service.consumeLaunchAction(), isNull);
    await service.dispose();
  });

  test('a tap from the host reaches the action stream', () async {
    final service = PlatformShortcutService();
    final seen = service.actions.take(1).toList();

    await messenger.handlePlatformMessage(
      'copist/shortcuts',
      codec.encodeMethodCall(const MethodCall('shortcut', 'new_note')),
      (_) {},
    );

    expect(await seen, [ShortcutAction.newNote]);
    await service.dispose();
  });

  test('an unknown tap is dropped, not thrown', () async {
    final service = PlatformShortcutService();
    var seen = 0;
    final sub = service.actions.listen((_) => seen++);

    await messenger.handlePlatformMessage(
      'copist/shortcuts',
      codec.encodeMethodCall(const MethodCall('shortcut', 'new_planet')),
      (_) {},
    );

    expect(seen, 0);
    await sub.cancel();
    await service.dispose();
  });
}
