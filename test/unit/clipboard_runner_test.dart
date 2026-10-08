// Paste as Markdown (#531) reads the clipboard's HTML with Niman's own
// native code: the GTK runner on Linux, a bridge in the activity on
// Android, user32 through dart:ffi on Windows. None of it runs on the
// machine the tests run on, so what the halves have to agree on is pinned
// here, as `drop_runner_test.dart` pins the drop: the channel's name, the
// targets asked for, and the calls that must be paired.
//
// Run from the package root, like `flutter test` does.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/paste/channel_clipboard_html.dart';
import 'package:path/path.dart' as p;

/// The source at [parts] of the repo root, its comments taken out: what a
/// file says about the clipboard is not what it does with it.
String code(List<String> parts) =>
    File(p.joinAll(parts))
        .readAsStringSync()
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
        .replaceAll(RegExp(r'//[^\n]*'), '');

void main() {
  group('the Linux runner', () {
    late String source;

    setUpAll(() {
      source = code(['linux', 'runner', 'clipboard_html.cc']);
    });

    test('answers on the channel Dart asks', () {
      expect(source, contains('"$clipboardChannelName"'));
      expect(source, contains('"readHtml"'));
      expect(
        code(['linux', 'runner', 'my_application.cc']),
        contains('clipboard_html_channel_new('),
      );
      expect(
        File(p.join('linux', 'runner', 'CMakeLists.txt')).readAsStringSync(),
        contains('"clipboard_html.cc"'),
        reason: 'a source the build does not list is never compiled',
      );
    });

    test("asks for the HTML and for both browsers' page targets", () {
      expect(source, contains('"text/html"'));
      expect(
        source,
        contains('"chromium/x-source-url"'),
        reason: "Chromium's kMimeTypeSourceUrl on Linux",
      );
      expect(
        source,
        contains('"text/x-moz-url-priv"'),
        reason: 'what Firefox names the page a selection came from',
      );
    });

    test('asks GTK without waiting on it', () {
      expect(source, contains('gtk_clipboard_request_targets'));
      expect(source, contains('gtk_clipboard_request_contents'));
      expect(
        source,
        isNot(contains('gtk_clipboard_wait_for')),
        reason:
            'a wait spins a main loop of its own inside the engine’s '
            'message handler',
      );
    });

    test('hands the bytes over as they came, for Dart to decode', () {
      expect(source, contains('fl_value_new_uint8_list'));
      expect(source, isNot(contains('gtk_selection_data_get_text')));
    });
  });

  group('the Android bridge', () {
    late String source;

    setUpAll(() {
      source = code([
        'android',
        'app',
        'src',
        'main',
        'kotlin',
        'dev',
        'niman',
        'niman',
        'ClipboardBridge.kt',
      ]);
    });

    test('answers on the channel Dart asks, with the clip’s HTML', () {
      expect(source, contains('"$clipboardChannelName"'));
      expect(source, contains('"readHtml"'));
      expect(source, contains('htmlText'));
    });

    test('is attached to the engine, and detached from it', () {
      final activity = code([
        'android',
        'app',
        'src',
        'main',
        'kotlin',
        'dev',
        'niman',
        'niman',
        'MainActivity.kt',
      ]);
      expect(activity, contains('ClipboardBridge(this)'));
      expect(activity, contains('clipboard.attach('));
      expect(activity, contains('clipboard.detach()'));
    });
  });

  group('the Windows reader', () {
    late String source;

    setUpAll(() {
      source = code([
        'lib',
        'src',
        'capture',
        'paste',
        'windows_clipboard_html.dart',
      ]);
    });

    test("reads browsers' HTML Format, and lets the clipboard go", () {
      expect(source, contains("'HTML Format'"));
      expect(source, contains("'OpenClipboard'"));
      expect(source, contains('_closeClipboard()'));
      expect(source, contains("'GlobalLock'"));
      expect(source, contains('_globalUnlock(handle)'));
      expect(
        source,
        contains("'GlobalSize'"),
        reason: 'the block is copied out of the memory it is in, by its size',
      );
    });
  });
}
