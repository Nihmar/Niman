// Issue #162: a failing clipboard read must not take the app down.
// The seam under test is experimental upstream; see the class's own note.
// ignore_for_file: experimental_member_use

import 'dart:typed_data';

import 'package:flutter_quill/internal.dart'
    show ClipboardService, ClipboardServiceProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/wysiwyg/guarded_clipboard_service.dart';

/// Stands in for `quill_native_bridge_windows`: [throws] reproduces the
/// crash (a `toDartString()` on a null pointer surfaces as an
/// `UnsupportedError`), the default answers normally.
final class _FakeClipboard extends ClipboardService {
  new({this.throws = false});

  final bool throws;
  int copies = 0;

  Future<T> _answer<T>(T value) async {
    if (throws) {
      throw UnsupportedError(
        "Operation 'toDartString' not allowed on a 'nullptr'.",
      );
    }
    return value;
  }

  @override
  Future<String?> getHtmlText() => _answer('<p>hello</p>');

  @override
  Future<String?> getHtmlFile() => _answer('<p>file</p>');

  @override
  Future<String?> getMarkdownFile() => _answer('# file');

  @override
  Future<Uint8List?> getImageFile() => _answer(Uint8List(1));

  @override
  Future<Uint8List?> getGifFile() => _answer(Uint8List(2));

  @override
  Future<void> copyImage(Uint8List imageBytes) {
    copies++;
    return _answer(null);
  }

  @override
  Future<bool> get hasClipboardContent => _answer(true);
}

void main() {
  tearDown(ClipboardServiceProvider.setInstanceToDefault);

  test('a read that throws comes back as null, not as a crash', () async {
    final service = GuardedClipboardService(_FakeClipboard(throws: true));

    // The #162 path: Quill asks for HTML before pasting, gets nothing,
    // and `pasteHTML` falls through to plain text instead of throwing.
    await expectLater(service.getHtmlText(), completion(isNull));
    await expectLater(service.getHtmlFile(), completion(isNull));
    await expectLater(service.getMarkdownFile(), completion(isNull));
    await expectLater(service.getImageFile(), completion(isNull));
    await expectLater(service.getGifFile(), completion(isNull));
  });

  test('a failing image copy does not throw either', () async {
    final delegate = _FakeClipboard(throws: true);

    await expectLater(
      GuardedClipboardService(delegate).copyImage(Uint8List(3)),
      completes,
    );
    expect(delegate.copies, 1);
  });

  test('a working read is passed straight through', () async {
    final service = GuardedClipboardService(_FakeClipboard());

    expect(await service.getHtmlText(), '<p>hello</p>');
    expect(await service.getMarkdownFile(), '# file');
    expect(await service.getImageFile(), hasLength(1));
    expect(await service.getGifFile(), hasLength(2));
    expect(await service.hasClipboardContent, isTrue);
  });

  test('install wraps the service in place, once', () {
    final original = ClipboardServiceProvider.instance;

    GuardedClipboardService.install();
    final installed = ClipboardServiceProvider.instance;
    expect(installed, isA<GuardedClipboardService>());
    expect((installed as GuardedClipboardService).delegate, same(original));

    GuardedClipboardService.install();
    expect(ClipboardServiceProvider.instance, same(installed));
  });
}
