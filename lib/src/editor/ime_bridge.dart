import 'package:copist/src/editor/composing_input.dart';
import 'package:flutter/services.dart';

/// The IME value bridge over a [ComposingInput] (M2a E8a): computes the
/// [TextEditingValue] to push to the platform IME and forwards its
/// [TextEditingDelta] stream to [ComposingInput.apply].
///
/// Pure (no widgets, no TextInputConnection) — the platform IME client
/// (the on-device half) uses this.
final class ImeBridge {
  /// Creates a bridge over [input].
  ImeBridge(this.input);

  /// The input model the bridge drives.
  final ComposingInput input;

  /// The value to push to the IME: the composed text + selection + composing
  /// region.
  TextEditingValue get value => TextEditingValue(
    text: input.text,
    selection: input.selection,
    composing: input.composing,
  );

  /// Forwards [delta] to the input. Returns true when the delta was
  /// unrecognized (the client must push a full [value] to re-sync the IME);
  /// a direct edit (reset / cut / paste) is re-anchored inside
  /// [ComposingInput.apply] and does not affect this return.
  bool applyDelta(TextEditingDelta delta) => input.apply(delta);
}
