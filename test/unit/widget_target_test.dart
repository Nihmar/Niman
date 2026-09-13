// Widget taps (issue 6): the wire format and the platform service over a
// mocked host channel.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/widget/widget_target.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('niman/widgets');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Map<Object?, Object?>? launchMap;

  setUp(() {
    launchMap = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      return call.method == 'consumeLaunchTarget' ? launchMap : null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('wire format', () {
    test('a todo target round-trips', () {
      const target = WidgetTarget(
        kind: WidgetTargetKind.todo,
        libraryPath: '/lib/Work',
      );
      final back = WidgetTarget.fromMap(target.toMap())!;
      expect(back.kind, WidgetTargetKind.todo);
      expect(back.libraryPath, '/lib/Work');
      expect(back.notePath, isNull);
      expect(back.anchor, isNull);
    });

    test('a note target with anchor round-trips', () {
      const target = WidgetTarget(
        kind: WidgetTargetKind.note,
        libraryPath: '/lib/Work',
        notePath: 'Todo.md',
        anchor: 'Shopping',
      );
      final back = WidgetTarget.fromMap(target.toMap())!;
      expect(back.kind, WidgetTargetKind.note);
      expect(back.notePath, 'Todo.md');
      expect(back.anchor, 'Shopping');
    });

    test('a note target with focusAdd round-trips', () {
      const target = WidgetTarget(
        kind: WidgetTargetKind.note,
        libraryPath: '/lib/Work',
        notePath: 'List.md',
        focusAdd: true,
      );
      final map = target.toMap();
      expect(map['focusAdd'], 'true');
      final back = WidgetTarget.fromMap(map)!;
      expect(back.focusAdd, isTrue);
      // Absent or garbage focusAdd parses to false.
      expect(
        WidgetTarget.fromMap(const {
          'kind': 'note',
          'libraryPath': '/lib',
          'notePath': 'List.md',
        })!.focusAdd,
        isFalse,
      );
      expect(
        WidgetTarget.fromMap(const {
          'kind': 'note',
          'libraryPath': '/lib',
          'notePath': 'List.md',
          'focusAdd': 'maybe',
        })!.focusAdd,
        isFalse,
      );
    });

    test('nothing openable parses to null', () {
      expect(WidgetTarget.fromMap(const {}), isNull);
      expect(
        WidgetTarget.fromMap(const {'kind': 'todo', 'libraryPath': ''}),
        isNull,
      );
      expect(
        WidgetTarget.fromMap(const {
          'kind': 'spaceship',
          'libraryPath': '/lib',
        }),
        isNull,
      );
      // A note without a path cannot open anywhere.
      expect(
        WidgetTarget.fromMap(const {'kind': 'note', 'libraryPath': '/lib'}),
        isNull,
      );
    });
  });

  group('service', () {
    test('is Android-only', () {
      expect(
        createWidgetTargetService(isAndroid: true),
        isA<PlatformWidgetTargetService>(),
      );
      expect(
        createWidgetTargetService(isAndroid: false),
        isA<NoopWidgetTargetService>(),
      );
    });

    test('the no-op is inert', () async {
      const service = NoopWidgetTargetService();
      expect(service.targets, emitsDone);
      expect(await service.consumeLaunchTarget(), isNull);
      await service.dispose();
    });

    test('the launch target comes once', () async {
      launchMap = const WidgetTarget(
        kind: WidgetTargetKind.todo,
        libraryPath: '/lib/Work',
      ).toMap();
      final service = PlatformWidgetTargetService();
      final first = await service.consumeLaunchTarget();
      expect(first!.kind, WidgetTargetKind.todo);

      // The host clears it after the first read.
      launchMap = null;
      expect(await service.consumeLaunchTarget(), isNull);
      await service.dispose();
    });

    test('a tap from the host reaches the target stream', () async {
      final service = PlatformWidgetTargetService();
      final seen = service.targets.take(1).toList();

      await messenger.handlePlatformMessage(
        'niman/widgets',
        codec.encodeMethodCall(
          const MethodCall('target', {
            'kind': 'note',
            'libraryPath': '/lib/Work',
            'notePath': 'Todo.md',
          }),
        ),
        (_) {},
      );

      final target = (await seen).single;
      expect(target.kind, WidgetTargetKind.note);
      expect(target.notePath, 'Todo.md');
      await service.dispose();
    });

    test('an unreadable tap is dropped, not thrown', () async {
      final service = PlatformWidgetTargetService();
      var seen = 0;
      final sub = service.targets.listen((_) => seen++);

      await messenger.handlePlatformMessage(
        'niman/widgets',
        codec.encodeMethodCall(
          const MethodCall('target', {'kind': 'spaceship'}),
        ),
        (_) {},
      );

      expect(seen, 0);
      await sub.cancel();
      await service.dispose();
    });
  });
}
