// The editor's page keys: re_editor 0.10.0 declares the page-move intents
// and their actions but binds no key to them, and the controller methods
// behind them are empty stubs — Copist binds the keys and moves the page
// itself (user, 2026-09-10).
import 'package:copist/src/editor/find_panel.dart';
import 'package:copist/src/editor/note_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  test('the editor binds PageUp and PageDown to the page moves', () {
    const builder = CopistShortcutsActivatorsBuilder();
    // SingleActivator has no equality, so assert on the trigger keys.
    final down = builder.build(CodeShortcutType.cursorMovePageDown);
    expect(down, hasLength(1));
    expect(
      (down!.single as SingleActivator).trigger,
      LogicalKeyboardKey.pageDown,
    );
    final up = builder.build(CodeShortcutType.cursorMovePageUp);
    expect(up, hasLength(1));
    expect((up!.single as SingleActivator).trigger, LogicalKeyboardKey.pageUp);
    // The default arrow moves stay bound.
    expect(builder.build(CodeShortcutType.cursorMoveDown), isNotNull);
  });

  test('a page is the lines the viewport holds', () {
    // 2600 px of scroll plus a 400 px viewport over 150 lines: 3000 px of
    // content, so the viewport shows 400 * 150 / 3000 = 20 lines.
    expect(pageLineStep(lineCount: 150, extent: 2600, viewport: 400), 20);
    // A page is never zero lines, and never more than the document.
    expect(pageLineStep(lineCount: 150, extent: 1000000, viewport: 400), 1);
    expect(pageLineStep(lineCount: 5, extent: 0, viewport: 400), 4);
    // A one-line document has nothing to page.
    expect(pageLineStep(lineCount: 1, extent: 0, viewport: 400), 0);
  });
}
