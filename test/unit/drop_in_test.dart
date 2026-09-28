// #224: the drop channel — the payloads the platform runners send, and
// what reaches the app: a drag over the window, a drag leaving it, and the
// paths a drop was made of.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/drop_in.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('niman/drop');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// What a runner reports, as the host sends it.
  Future<void> fromHost(String method, [Object? args]) async {
    await messenger.handlePlatformMessage(
      'niman/drop',
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
      (_) {},
    );
    await Future<void>.delayed(Duration.zero);
  }

  group('the payload', () {
    test('a drop carries the paths the desktop handed over', () {
      expect(dropPathsFrom(['/home/me/Notes/a.md', '/home/me/Drafts']), [
        '/home/me/Notes/a.md',
        '/home/me/Drafts',
      ]);
    });

    test('nothing unusable gets through', () {
      expect(dropPathsFrom(null), isEmpty);
      expect(dropPathsFrom('/home/me/a.md'), isEmpty);
      expect(dropPathsFrom(7), isEmpty);
      expect(dropPathsFrom([null, 7, '', '   ']), isEmpty);
      // One good path is enough; the rest of the list is not lost with it.
      expect(dropPathsFrom(['/a.md', 7, '  ', '/Drafts']), [
        '/a.md',
        '/Drafts',
      ]);
    });
  });

  group('the channel service', () {
    test('a drop reaches the app as the paths it holds', () async {
      final service = PlatformDropTargetService();
      final seen = <WindowDrop>[];
      final subscription = service.events.listen(seen.add);

      await fromHost('drop', ['/home/me/a.md']);

      expect(seen, hasLength(1));
      expect((seen.single as Dropped).paths, ['/home/me/a.md']);
      await subscription.cancel();
      await service.dispose();
    });

    test('a drop with no paths is still a drop', () async {
      final service = PlatformDropTargetService();
      final seen = <WindowDrop>[];
      final subscription = service.events.listen(seen.add);

      await fromHost('drop', const <String>[]);

      expect(seen, hasLength(1));
      expect((seen.single as Dropped).paths, isEmpty);
      await subscription.cancel();
      await service.dispose();
    });

    test('a drag over the window and one that leaves come in order', () async {
      final service = PlatformDropTargetService();
      final seen = <WindowDrop>[];
      final subscription = service.events.listen(seen.add);

      await fromHost('dragEntered');
      await fromHost('dragExited');
      await fromHost('drop', ['/home/me/a.md']);

      expect(seen[0], isA<DragEntered>());
      expect(seen[1], isA<DragExited>());
      expect((seen[2] as Dropped).paths, ['/home/me/a.md']);
      await subscription.cancel();
      await service.dispose();
    });

    test('a call this app does not know is left alone', () async {
      final service = PlatformDropTargetService();
      final seen = <WindowDrop>[];
      final subscription = service.events.listen(seen.add);

      await fromHost('somethingElse', 1);

      expect(seen, isEmpty);
      await subscription.cancel();
      await service.dispose();
    });

    test('a second dispose completes and closes the stream once', () async {
      final service = PlatformDropTargetService();
      await service.dispose();
      // Completes rather than waiting on a stream that is closed already.
      await service.dispose();

      await expectLater(service.events, emitsDone);
    });
  });

  group('the service factory', () {
    test('a desktop gets the platform service, elsewhere the no-op', () async {
      final desktop = createDropTargetService(isDesktop: true);
      expect(desktop, isA<PlatformDropTargetService>());
      await desktop.dispose();

      final phone = createDropTargetService(isDesktop: false);
      expect(phone, isA<NoopDropTargetService>());
      final seen = <WindowDrop>[];
      final subscription = phone.events.listen(seen.add);
      await Future<void>.delayed(Duration.zero);
      expect(seen, isEmpty);
      await subscription.cancel();
      await phone.dispose();
    });
  });
}
