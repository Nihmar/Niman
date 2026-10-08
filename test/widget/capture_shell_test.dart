// The ways to a capture on the desktop (#531): Ctrl+Alt+W opens the dialog,
// on the clipboard's address when it holds one, and a link pasted where
// nothing else takes a paste opens it on that link — while a paste into a
// text field stays a paste.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/capture/background_capture.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/capture/capture_services.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late String? clipboard;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    clipboard = null;
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? <String, Object?>{'text': clipboard}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          // No browser and no network: the dialog's reading never ends,
          // which is all these tests need of it.
          captureServicesProvider.overrideWithValue(
            CaptureServices(
              background: BackgroundCapture(
                notifier: const SilentCaptureNotifier(),
              ),
              browser: () async => null,
              read: (url, {browser, onProgress}) =>
                  Completer<WebReading>().future,
            ),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  Future<void> close() async {
    await controller.close();
    await controller.dispose();
  }

  Future<void> keys(WidgetTester tester, List<LogicalKeyboardKey> held) async {
    for (final key in held.take(held.length - 1)) {
      await tester.sendKeyDownEvent(key);
    }
    await tester.sendKeyEvent(held.last);
    for (final key in held.take(held.length - 1).toList().reversed) {
      await tester.sendKeyUpEvent(key);
    }
    await settle(tester);
  }

  String address(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(const Key('capture-address')))
      .controller!
      .text;

  testWidgets('Ctrl+Alt+W opens the dialog, empty without an address', (
    tester,
  ) async {
    clipboard = 'just some words';
    await pumpShell(tester);
    await keys(tester, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.keyW,
    ]);
    expect(find.byKey(const Key('capture-dialog')), findsOne);
    expect(address(tester), isEmpty);
    // A paste into the address field is the field's: no second dialog.
    clipboard = 'https://example.com/garden';
    await tester.tap(find.byKey(const Key('capture-address')));
    await keys(tester, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.keyV,
    ]);
    expect(address(tester), 'https://example.com/garden');
    expect(find.byKey(const Key('capture-dialog')), findsOne);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    await close();
  });

  testWidgets('a link pasted outside the editor opens the dialog on it', (
    tester,
  ) async {
    clipboard = 'https://example.com/garden';
    await pumpShell(tester);
    await keys(tester, [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.keyV,
    ]);
    expect(find.byKey(const Key('capture-dialog')), findsOne);
    await close();
  });

  test('only one web address is a page to capture', () {
    expect(webAddressIn(' https://example.com/a?b=1 '), isNotNull);
    expect(webAddressIn('http://example.com'), isNotNull);
    expect(webAddressIn('see https://example.com'), isNull);
    expect(webAddressIn('ftp://example.com'), isNull);
    expect(webAddressIn('https://'), isNull);
    expect(webAddressIn(null), isNull);
  });
}
