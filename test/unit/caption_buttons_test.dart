// #169: the caption buttons' rectangles on their way to the Windows
// runner — the payload it reads to answer `WM_NCHITTEST`, and the hosts
// that have nothing listening on the other end.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/caption_buttons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(CaptionButtonsChannel.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // The three buttons as the title bar draws them, in physical pixels.
  const minimize = Rect.fromLTWH(0, 0, 44, 38);
  const maximize = Rect.fromLTWH(800, 0, 44, 38);
  const close = Rect.fromLTWH(844, 0, 44, 38);

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('the runner gets all three buttons, in whole pixels', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    CaptionButtonsChannel(windows: true)
        .report(minimize: minimize, maximize: maximize, close: close);
    await Future<void>.delayed(Duration.zero);

    expect(calls, hasLength(1));
    expect(calls.single.method, CaptionButtonsChannel.method);
    expect(calls.single.arguments, {
      'minimize': {'left': 0, 'top': 0, 'right': 44, 'bottom': 38},
      'maximize': {'left': 800, 'top': 0, 'right': 844, 'bottom': 38},
      'close': {'left': 844, 'top': 0, 'right': 888, 'bottom': 38},
    });
  });

  test('a fraction of a pixel is rounded, not dropped', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    CaptionButtonsChannel(windows: true).report(
      minimize: minimize,
      maximize: maximize,
      close: const Rect.fromLTWH(843.6, 0, 44.2, 38),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      calls.single.arguments,
      containsPair('close', {
        'left': 844,
        'top': 0,
        'right': 888,
        'bottom': 38,
      }),
    );
  });

  test('nothing is sent where no runner is listening', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    CaptionButtonsChannel(windows: false)
        .report(minimize: minimize, maximize: maximize, close: close);
    await Future<void>.delayed(Duration.zero);

    expect(calls, isEmpty);
  });

  test('a channel nobody answers is not an error', () async {
    // No handler at all: the plugin-missing exception the report raises
    // must stay inside it. An escaping one fails this test.
    CaptionButtonsChannel(windows: true)
        .report(minimize: minimize, maximize: maximize, close: close);
    await Future<void>.delayed(Duration.zero);
  });
}
