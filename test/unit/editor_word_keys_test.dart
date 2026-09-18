// The editor's word-wise keys: re_editor 0.10.0 puts word jump on
// Alt+Arrow on every non-mac platform and spends Ctrl+Arrow on line
// start/end, so Ctrl+Shift+Arrow — the way you select a word on Windows
// and Linux — is bound to nothing (user, 2026-09-18).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/find_panel.dart';
import 'package:re_editor/re_editor.dart';

/// SingleActivator has no equality, so assert on the parts.
void _expectKey(
  List<ShortcutActivator>? activators, {
  required LogicalKeyboardKey trigger,
  required bool control,
  required bool shift,
}) {
  expect(activators, hasLength(1));
  final activator = activators!.single as SingleActivator;
  expect(activator.trigger, trigger);
  expect(activator.control, control);
  expect(activator.shift, shift);
  expect(activator.alt, isFalse);
}

void main() {
  // The mac bindings are the package's and stay its own; the test host is
  // never macOS.
  const builder = NimanShortcutsActivatorsBuilder();

  test('Ctrl+Arrow jumps a word', () {
    _expectKey(
      builder.build(CodeShortcutType.cursorMoveWordBoundaryBackward),
      trigger: LogicalKeyboardKey.arrowLeft,
      control: true,
      shift: false,
    );
    _expectKey(
      builder.build(CodeShortcutType.cursorMoveWordBoundaryForward),
      trigger: LogicalKeyboardKey.arrowRight,
      control: true,
      shift: false,
    );
  });

  test('Ctrl+Shift+Arrow selects a word', () {
    // The package's forward/backward names are inverted in both the map
    // and the controller and cancel out: "forward" walks the extent left.
    _expectKey(
      builder.build(CodeShortcutType.selectionExtendWordBoundaryForward),
      trigger: LogicalKeyboardKey.arrowLeft,
      control: true,
      shift: true,
    );
    _expectKey(
      builder.build(CodeShortcutType.selectionExtendWordBoundaryBackward),
      trigger: LogicalKeyboardKey.arrowRight,
      control: true,
      shift: true,
    );
  });

  test(
    'Ctrl+Arrow is free to mean it: line start and end are Home and End',
    () {
      // Left over, Ctrl+Arrow on line start/end would shadow the word jump:
      // SingleActivator has no value equality, so both would sit in the map
      // and the one registered first — line start — would answer the key.
      _expectKey(
        builder.build(CodeShortcutType.cursorMoveLineStart),
        trigger: LogicalKeyboardKey.home,
        control: false,
        shift: false,
      );
      _expectKey(
        builder.build(CodeShortcutType.cursorMoveLineEnd),
        trigger: LogicalKeyboardKey.end,
        control: false,
        shift: false,
      );
    },
  );

  test('the rest of the package bindings are untouched', () {
    // Shift+Arrow still extends by a character, and the document edges
    // keep Ctrl+Home / Ctrl+End.
    _expectKey(
      builder.build(CodeShortcutType.selectionExtendBackward),
      trigger: LogicalKeyboardKey.arrowLeft,
      control: false,
      shift: true,
    );
    expect(builder.build(CodeShortcutType.cursorMovePageStart), hasLength(2));
    expect(builder.build(CodeShortcutType.copy), hasLength(1));
  });
}
