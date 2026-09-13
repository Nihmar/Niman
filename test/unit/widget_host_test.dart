// Widget host (issue 6): placed todo ids over a mocked host channel.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/widget/widget_host.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('niman/widgets');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<Object?>? hostIds;

  setUp(() {
    hostIds = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getWidgetIds') return hostIds;
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('is Android-only', () {
    expect(
      createWidgetHostService(isAndroid: true),
      isA<PlatformWidgetHostService>(),
    );
    expect(
      createWidgetHostService(isAndroid: false),
      isA<NoopWidgetHostService>(),
    );
  });

  test('the no-op reports no ids', () async {
    const host = NoopWidgetHostService();
    expect(await host.todoWidgetIds(), isEmpty);
    await host.dispose();
  });

  test('the host ids come through, non-integers dropped', () async {
    hostIds = [7, 'stale', 8];
    final host = PlatformWidgetHostService();
    expect(await host.todoWidgetIds(), [7, 8]);
    expect(await host.noteWidgetIds(), [7, 8]);
    await host.dispose();
  });

  test('an absent host reads as no widgets', () async {
    hostIds = null;
    final host = PlatformWidgetHostService();
    expect(await host.todoWidgetIds(), isEmpty);
    await host.dispose();
  });
}
