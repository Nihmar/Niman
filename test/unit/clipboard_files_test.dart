// #1249: the files on the clipboard, as each platform's file manager puts
// them there, read as local paths; and the native halves pinned to what
// the Dart half asks, as `clipboard_runner_test.dart` pins the HTML's.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/capture/paste/clipboard_files.dart';
import 'package:path/path.dart' as p;

/// The source at [parts] of the repo root, its comments taken out.
String code(List<String> parts) =>
    File(p.joinAll(parts))
        .readAsStringSync()
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
        .replaceAll(RegExp(r'//[^\n]*'), '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a URI list', () {
    test("GNOME's copy: the verb, then a URI a line, escapes read", () {
      expect(
        pathsOfUriList(
          'copy\nfile:///home/me/Report%202026.pdf\nfile:///tmp/a.zip',
        ),
        ['/home/me/Report 2026.pdf', '/tmp/a.zip'],
      );
    });

    test("text/uri-list: CRLF, comments, localhost's host", () {
      expect(
        pathsOfUriList(
          '# from Dolphin\r\nfile:///home/me/x.png\r\n'
          'file://localhost/home/me/y.png\r\n',
        ),
        ['/home/me/x.png', '/home/me/y.png'],
      );
    });

    test('a web address is no file, and the list is taken as none', () {
      expect(pathsOfUriList('https://example.com/a.pdf'), isEmpty);
      expect(
        pathsOfUriList('file:///tmp/a.pdf\nhttps://example.com/b.pdf'),
        isEmpty,
      );
      expect(pathsOfUriList('file://server/share/a.pdf'), isEmpty);
      expect(pathsOfUriList(''), isEmpty);
    });
  });

  group("a runner's answer", () {
    test('paths, bytes of a list, or nothing', () {
      expect(clipboardFilesFrom(['/a.pdf', '', 3]), ['/a.pdf']);
      expect(
        clipboardFilesFrom(
          Uint8List.fromList(utf8.encode('copy\nfile:///b.zip\n')),
        ),
        ['/b.zip'],
      );
      expect(clipboardFilesFrom(null), isEmpty);
    });

    test('over the channel; a runner without it answers no files', () async {
      const channel = MethodChannel('niman/clipboard');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'readFiles' ? ['/x.pdf'] : null,
      );
      expect(await const ChannelClipboardFiles().read(), ['/x.pdf']);

      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw MissingPluginException(),
      );
      expect(await const ChannelClipboardFiles().read(), isEmpty);
    });
  });

  group('the native halves', () {
    test('Linux asks GTK for both file targets, without waiting', () {
      final source = code(['linux', 'runner', 'clipboard_html.cc']);
      expect(source, contains('"readFiles"'));
      expect(source, contains('"x-special/gnome-copied-files"'));
      expect(source, contains('"text/uri-list"'));
      expect(source, isNot(contains('gtk_clipboard_wait_for')));
    });

    test('Android copies the content into the cache, off the main thread', () {
      final kotlin = [
        'android',
        'app',
        'src',
        'main',
        'kotlin',
        'dev',
        'niman',
        'niman',
      ];
      final bridge = code([...kotlin, 'ClipboardBridge.kt']);
      expect(bridge, contains('"readFiles"'));
      expect(bridge, contains('ContentFiles.copyToCache('));
      expect(bridge, contains('Thread {'));
      final files = code([...kotlin, 'ContentFiles.kt']);
      expect(files, contains('openInputStream'));
      expect(files, contains('OpenableColumns.DISPLAY_NAME'));
    });

    test('macOS and iOS answer on the same channel', () {
      final sources = [
        'packages',
        'niman_apple',
        'darwin',
        'niman_apple',
        'Sources',
        'niman_apple',
      ];
      expect(
        code([...sources, 'ClipboardBridge.swift']),
        contains('"readFiles"'),
      );
      final files = code([...sources, 'ClipboardFiles.swift']);
      expect(files, contains('urlReadingFileURLsOnly'));
      expect(files, contains('loadFileRepresentation'));
    });

    test('Windows reads CF_HDROP and lets the clipboard go', () {
      final source = code([
        'lib',
        'src',
        'capture',
        'paste',
        'windows_clipboard_files.dart',
      ]);
      expect(source, contains('_cfHdrop = 15'));
      expect(source, contains("'DragQueryFileW'"));
      expect(source, contains('_closeClipboard()'));
      expect(
        source,
        isNot(contains('DragFinish')),
        reason: "the handle is the clipboard's, not ours to free",
      );
    });
  });
}
