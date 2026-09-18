// `ClipboardService` and its provider live in `flutter_quill/internal.dart`
// and are marked experimental. They are still the only seam the package
// offers for replacing a clipboard read, and the alternative — turning off
// `enableExternalRichPaste` — gives up HTML paste everywhere to work around
// one platform's bug.
// ignore_for_file: experimental_member_use

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_quill/internal.dart'
    show ClipboardService, ClipboardServiceProvider;
import 'package:niman/src/core/logging.dart';

/// Quill's clipboard service, wrapped so a failing clipboard operation
/// cannot take the app down (issue #162).
///
/// `Ctrl+V` in the WYSIWYG editor crashed on Windows. Before pasting,
/// Quill asks the platform whether the clipboard holds an HTML flavour,
/// and `quill_native_bridge_windows` 0.1.0 guards the wrong pointer on
/// that path:
///
/// ```dart
/// final lockedMemoryPointer = GlobalLock(HGLOBAL(clipboardDataPointer));
/// if (lockedMemoryPointer == nullptr) { … return null; }
/// final windowsHtmlWithMetadata =
///     lockedMemoryPointer.value.cast<Utf8>().toDartString();
/// ```
///
/// `GlobalLock` returns a `Win32Result`, not a pointer, so that guard can
/// never be true — it is dead code. The locked address is `.value`, and
/// when *that* is null `toDartString()` throws `Unsupported operation:
/// … not allowed on a 'nullptr'`. The `assert` the package leans on is
/// compiled out of a release build, so only the builds people actually
/// run are affected. 0.1.0 is the newest version that resolves and it
/// arrives transitively through `flutter_quill`, so the fix is ours.
///
/// This does not give up HTML paste. A read that works is passed straight
/// through; only a failing one degrades, and it degrades to a path Quill
/// already takes — `pasteHTML` returning false, then plain text. The
/// wrapper is installed on every platform: the bug is Windows', but "a
/// clipboard read cannot crash the editor" is not a Windows guarantee,
/// and where nothing throws the wrapper is invisible.
final class GuardedClipboardService extends ClipboardService {
  /// Wraps [delegate], the service that would otherwise answer.
  new(this.delegate);

  /// Installs the wrapper over whatever service Quill currently uses.
  ///
  /// Idempotent, and it wraps rather than replaces: the platform reads
  /// still come from the package's own service.
  static void install() {
    final current = ClipboardServiceProvider.instance;
    if (current is GuardedClipboardService) return;
    ClipboardServiceProvider.setInstance(GuardedClipboardService(current));
  }

  /// The service doing the real work.
  final ClipboardService delegate;

  static const AppLogger _log = AppLogger(name: 'clipboard');

  @override
  Future<String?> getHtmlText() => _guard('HTML', delegate.getHtmlText);

  @override
  Future<String?> getHtmlFile() => _guard('HTML file', delegate.getHtmlFile);

  @override
  Future<String?> getMarkdownFile() =>
      _guard('Markdown file', delegate.getMarkdownFile);

  @override
  Future<Uint8List?> getImageFile() => _guard('image', delegate.getImageFile);

  @override
  Future<Uint8List?> getGifFile() => _guard('GIF', delegate.getGifFile);

  @override
  Future<void> copyImage(Uint8List imageBytes) async {
    await _guard('image copy', () async {
      await delegate.copyImage(imageBytes);
      return null;
    });
  }

  /// Forwarded so the wrapper stays transparent: the base class answers
  /// this one from `Clipboard` itself, without going near the native
  /// bridge, so there is nothing here to guard.
  @override
  Future<bool> get hasClipboardContent => delegate.hasClipboardContent;

  /// Runs a clipboard operation, turning a failure into "nothing there".
  ///
  /// Null is already what every read returns when the platform has no
  /// such flavour, so a swallowed failure puts Quill on a path it knows,
  /// not a new one. The line in the log is the difference between "the
  /// clipboard had no HTML" and "asking for it went wrong".
  Future<T?> _guard<T>(String what, Future<T?> Function() operation) async {
    try {
      return await operation();
    } on Object catch (error) {
      _log.warning('$what unavailable ($error)');
      return null;
    }
  }
}
