// The clipboard's HTML as the runners hand it over (#531): GTK's bytes,
// in whatever encoding the browser wrote them, and Android's string with
// no page — read over one channel.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/paste/channel_clipboard_html.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(clipboardChannelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call) reply) =>
      messenger.setMockMethodCallHandler(channel, (call) async => reply(call));

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test("GTK's bytes: the HTML in UTF-8, the page in UTF-16", () async {
    const page = 'https://example.com/a';
    answer(
      (call) => call.method == 'readHtml'
          ? {
              'html': Uint8List.fromList(
                utf8.encode('<meta charset="utf-8"><p>café</p>'),
              ),
              'source': Uint8List.fromList([
                for (final unit in page.codeUnits) ...[unit, 0],
              ]),
            }
          : null,
    );
    final clip = await const ChannelClipboardHtml().read();
    expect(clip!.html, '<meta charset="utf-8"><p>café</p>');
    expect(clip.source, Uri.parse(page));
  });

  test("Android's string, with no page", () async {
    answer((call) => {'html': '<p>words</p>'});
    final clip = await const ChannelClipboardHtml().read();
    expect(clip!.html, '<p>words</p>');
    expect(clip.source, isNull);
  });

  test('no HTML, or no runner, is none', () async {
    answer((call) => null);
    expect(await const ChannelClipboardHtml().read(), isNull);
    answer((call) => {'html': '  '});
    expect(await const ChannelClipboardHtml().read(), isNull);
    messenger.setMockMethodCallHandler(channel, null);
    expect(await const ChannelClipboardHtml().read(), isNull);
  });
}
