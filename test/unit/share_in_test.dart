// #40: the share-in channel — the payloads the Android bridge sends, the
// cold-start request and the ones that arrive while the app runs.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/share_in.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('niman/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('the payload', () {
    test('a text share carries its text', () {
      final request = shareRequestFrom({'type': 'text', 'text': 'hello'});
      expect(request, isA<SharedText>());
      expect((request! as SharedText).text, 'hello');
    });

    test('a file share carries the copy and the name it came with', () {
      final request = shareRequestFrom({
        'type': 'file',
        'path': '/cache/niman-share/Report.md',
        'name': 'Report.md',
      });
      expect(request, isA<SharedFile>());
      final file = request! as SharedFile;
      expect(file.path, '/cache/niman-share/Report.md');
      expect(file.name, 'Report.md');
    });

    test('a file share without a name still imports', () {
      final request = shareRequestFrom({'type': 'file', 'path': '/tmp/x'});
      expect((request! as SharedFile).name, 'Shared.md');
    });

    test('nothing unusable gets through', () {
      expect(shareRequestFrom(null), isNull);
      expect(shareRequestFrom('text'), isNull);
      expect(shareRequestFrom({'type': 'text'}), isNull);
      expect(shareRequestFrom({'type': 'text', 'text': '   '}), isNull);
      expect(shareRequestFrom({'type': 'file'}), isNull);
      expect(shareRequestFrom({'type': 'image', 'path': '/x'}), isNull);
    });
  });

  group('the channel service', () {
    test('the launch request is the host payload, once', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'consumeLaunchRequest') return null;
        return {'type': 'text', 'text': 'from a cold start'};
      });
      final service = PlatformShareInService();
      final request = await service.consumeLaunchRequest();
      expect((request! as SharedText).text, 'from a cold start');

      messenger.setMockMethodCallHandler(channel, (call) async => null);
      expect(await service.consumeLaunchRequest(), isNull);
      await service.dispose();
    });

    test('a share the host pushes reaches the stream', () async {
      final service = PlatformShareInService();
      final seen = <ShareRequest>[];
      final subscription = service.requests.listen(seen.add);

      await messenger.handlePlatformMessage(
        'niman/share',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('share', {'type': 'text', 'text': 'while running'}),
        ),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(1));
      expect((seen.single as SharedText).text, 'while running');
      await subscription.cancel();
      await service.dispose();
    });

    test(
      'a share that arrives before anyone listens is kept, not dropped',
      () async {
        // No shell yet (the library picker is up): the request waits and is
        // delivered to the first listener.
        final service = PlatformShareInService();
        await messenger.handlePlatformMessage(
          'niman/share',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('share', {'type': 'text', 'text': 'early'}),
          ),
          (_) {},
        );
        await Future<void>.delayed(Duration.zero);

        final seen = <ShareRequest>[];
        final subscription = service.requests.listen(seen.add);
        await Future<void>.delayed(Duration.zero);

        expect(seen, hasLength(1));
        expect((seen.single as SharedText).text, 'early');
        await subscription.cancel();
        await service.dispose();
      },
    );

    test('a host without the channel answers nothing', () async {
      messenger.setMockMethodCallHandler(channel, null);
      final service = PlatformShareInService();
      expect(await service.consumeLaunchRequest(), isNull);
      await service.dispose();
    });
  });

  group('the service factory', () {
    test('Android gets the platform service, elsewhere the no-op', () async {
      final android = createShareInService(isAndroid: true);
      expect(android, isA<PlatformShareInService>());
      await android.dispose();
      expect(createShareInService(isAndroid: false), isA<NoopShareInService>());
      expect(
        await createShareInService(isAndroid: false).consumeLaunchRequest(),
        isNull,
      );
    });
  });
}
