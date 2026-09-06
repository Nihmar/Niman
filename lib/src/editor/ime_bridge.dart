import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/line_buffer.dart';
import 'package:flutter/services.dart';

/// The IME value bridge over a [ComposingInput] (M2a E8a) — windowed since
/// the M2a fix P2.
///
/// The platform IME no longer holds the full buffer (the 931 KB Geometria
/// push blocked the Android main thread): it holds an [ImeWindow], a
/// KB-sized view around the caret, clamped to line boundaries. Offsets are
/// window-local (0-based inside [ImeWindow.windowText]); the full-text
/// offset is `windowStart + local`. [ImeWindow.around] computes a window
/// from a [ComposingInput]; [ComposingInput.apply] (with its `anchor`
/// argument) and the client translate back.

/// A KB-sized window of a [ComposingInput] — what the platform IME holds
/// instead of the full buffer (M2a fix P2).
///
/// [windowText] is the text the platform sees; [windowSelection] and
/// [windowComposing] are the buffer's selection/composing translated into
/// window-local offsets. The full-text start of the window is
/// [windowStart].
final class ImeWindow {
  /// Creates a window at [windowStart] holding [windowText] with the
  /// window-local [windowSelection] and [windowComposing].
  const ImeWindow({
    required this.windowStart,
    required this.windowText,
    required this.windowSelection,
    required this.windowComposing,
  });

  /// The window around the caret (or the current selection) of [input]:
  /// the caret's line plus one margin line above and below (so a backspace
  /// at a line start and a Delete at a line end stay expressible in the
  /// platform copy), then expanded outward to at least [budget] chars, all
  /// clamped to whole lines. O(window), never the full buffer.
  ///
  /// A selection wider than [budget] (select-all on a novel) cannot live in
  /// a KB window — the window falls back to the full buffer so the platform
  /// can express an edit on the whole selection (rare; the one-time cost
  /// the fix exists to avoid is never paid on the typing path).
  factory ImeWindow.around(
    ComposingInput input, {
    int budget = 2048,
  }) {
    final buffer = input.buffer;
    if (buffer.lineCount == 0) {
      return const ImeWindow(
        windowStart: 0,
        windowText: '',
        windowSelection: TextSelection.collapsed(offset: 0),
        windowComposing: TextRange.empty,
      );
    }
    final selection = input.selection;
    var rangeStart = 0;
    var rangeEnd = 0;
    if (selection.isValid && !selection.isCollapsed) {
      rangeStart = selection.start;
      rangeEnd = selection.end;
    } else {
      final caret = selection.isValid ? selection.baseOffset : 0;
      rangeStart = caret;
      rangeEnd = caret;
    }
    if (rangeEnd - rangeStart > budget) {
      return ImeWindow(
        windowStart: 0,
        windowText: buffer.text,
        windowSelection: selection,
        windowComposing: input.composing,
      );
    }
    final lastLine = buffer.lineCount - 1;
    final firstLine = buffer.locationOf(rangeStart).$1;
    final selLastLine =
        rangeEnd == 0 ? firstLine : buffer.locationOf(rangeEnd - 1).$1;
    // The margin lines: one above the range's first line and one below its
    // last (clamped to the buffer).
    var a = (firstLine - 1).clamp(0, lastLine);
    var b = (selLastLine + 1).clamp(0, lastLine);
    // Expand outward (alternating, keeping the caret's side balanced) until
    // the window holds at least [budget] chars or the buffer is exhausted.
    while (_charCount(buffer, a, b) < budget) {
      final canUp = a > 0;
      final canDown = b < lastLine;
      if (!canUp && !canDown) break;
      if (canUp) a--;
      if (canDown) b++;
    }
    final start = buffer.offsetOf(a, 0);
    final end = buffer.offsetOf(b, 0) + buffer.lineLength(b);
    return ImeWindow(
      windowStart: start,
      windowText: buffer.substring(start, end),
      windowSelection: translateSelection(selection, -start),
      windowComposing: translateRange(input.composing, -start),
    );
  }

  /// The buffer offset the window starts at.
  final int windowStart;

  /// The text the platform IME holds (KB, not the full buffer).
  final String windowText;

  /// The selection, in window-local offsets.
  final TextSelection windowSelection;

  /// The composing region, in window-local offsets.
  final TextRange windowComposing;

  /// The window as the [TextEditingValue] to push to the platform.
  TextEditingValue asValue() => TextEditingValue(
    text: windowText,
    selection: windowSelection,
    composing: windowComposing,
  );

  /// The char count of whole lines [a]..[b] inclusive (content + the line
  /// breaks between them) — O(lines), no join.
  static int _charCount(LineBuffer buffer, int a, int b) {
    var count = 0;
    for (var line = a; line <= b; line++) {
      count += buffer.lineLength(line);
    }
    return count + (b - a);
  }
}

/// The IME value bridge over a [ComposingInput] (M2a E8a): computes the
/// [ImeWindow] to push to the platform IME and forwards its
/// [TextEditingDelta] stream to [ComposingInput.apply].
///
/// Pure (no widgets, no TextInputConnection) — the platform IME client
/// (the on-device half) uses this.
final class ImeBridge {
  /// Creates a bridge over [input].
  ImeBridge(this.input);

  /// The input model the bridge drives.
  final ComposingInput input;

  /// The windowed value to push to the IME: the caret's [ImeWindow] (KB),
  /// not the full buffer (M2a fix P2).
  TextEditingValue get value => ImeWindow.around(input).asValue();

  /// Forwards [delta] to the input, translating the platform's
  /// window-local offsets into buffer offsets by [windowStart]. Returns
  /// true when the delta was unrecognized (the client must push a window to
  /// re-sync the IME); a direct edit (reset / cut / paste) is re-anchored
  /// inside [ComposingInput.apply] and does not affect this return.
  bool applyDelta(TextEditingDelta delta, {required int windowStart}) =>
      input.apply(delta, anchor: windowStart);
}
