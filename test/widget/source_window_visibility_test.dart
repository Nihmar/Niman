// A window hidden to the tray must draw nothing (#512): the caret's own blink
// kept laying out, painting and rasterizing at ~1.8 Hz. The editor stops the
// blink while the window is off screen and starts it again when it is back.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/ui/window_visibility.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

void main() {
  tearDown(WindowVisibility.show);

  testWidgets('the caret stops blinking while the window is hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(
            buffer: SourceBuffer.fromText('una riga di testo\n'),
            theme: _theme,
            showLineNumbers: false,
          ),
        ),
      ),
    );
    await tester.pump();
    final state = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );

    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    expect(state.caretBlinking, isTrue, reason: 'focused, the caret blinks');

    WindowVisibility.hide();
    await tester.pump();
    expect(
      state.caretBlinking,
      isFalse,
      reason: 'a window in the tray is nobody’s to see',
    );

    WindowVisibility.show();
    await tester.pump();
    expect(state.caretBlinking, isTrue, reason: 'back on screen, it blinks');
  });

  test(
    'minimizing marks the window hidden, so the timers stop (#512)',
    () async {
      final controller = WindowManagerController();
      WindowVisibility.show();
      // The platform call is inert here; what is asserted is the flag it sets
      // before the call, which is what the caret blink reads.
      await controller.minimize().catchError((Object _) {});
      expect(WindowVisibility.shown.value, isFalse);
    },
  );
}
